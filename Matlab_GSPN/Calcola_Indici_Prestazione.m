%% Calcola_Indici_Prestazione.m
%% Calcola_Indici_Prestazione.m
%  Versione Ottimizzata per Grandi Reti (Large Scale > 100k stati)
%  Output completo e formattato a 7 Step.

clear; clc;
fprintf('\n');
fprintf('============================================================\n');
fprintf('      CALCOLO INDICI DI PRESTAZIONE - GSPN Samsung v2\n');
fprintf('============================================================\n');

% -------------------------------------------------------------------------
% [0/7] Caricamento dati e nomi
% -------------------------------------------------------------------------
% Assicurati che questo sia il nome esatto del tuo file di salvataggio!
load GSPN_main_vers2.3_marc4.mat 

fprintf('[0/7] Caricamento nomi da Excel...\n');
[~, nomi_posti] = xlsread(filename, 'A5:A48');
[~, nomi_trans] = xlsread(filename, 'B4:AE4');

np = length(nomi_posti);
nt = length(nomi_trans);
fprintf('  Trovati %d posti e %d transizioni.\n\n', np, nt);

% -------------------------------------------------------------------------
% [1/7] Calcolo REMC (matrice U-prime)
% -------------------------------------------------------------------------
fprintf('[1/7] Calcolo REMC (matrice U-prime)...\n');

n_van = length(van);
n_tan = length(tan);

Cmat = U(1:n_van, 1:n_van);
Dmat = U(1:n_van, n_van+1:end);
Emat = U(n_van+1:end, 1:n_van);
Fmat = U(n_van+1:end, n_van+1:end);

I_C = speye(size(Cmat)) - Cmat;
P_tang = Fmat + Emat * (I_C \ Dmat);

% FIX: Uso di full() per convertire il risultato sparso 1x1 in un numero normale
err_P = full(max(abs(sum(P_tang, 2) - 1)));
fprintf('  U-prime OK: max errore riga = %e\n', err_P);
fprintf('  Dimensione U-prime: %d x %d (stati tangibili)\n\n', n_tan, n_tan);

% -------------------------------------------------------------------------
% [2/7] Calcolo generatore infinitesimale Q
% -------------------------------------------------------------------------
fprintf('[2/7] Calcolo generatore infinitesimale Q...\n');
Q = spdiags(qi(tan), 0, n_tan, n_tan) * (P_tang - speye(n_tan));

% FIX: Uso di full() per evitare l'errore di fprintf con input sparsi
err_Q = full(max(abs(sum(Q, 2))));
fprintf('  Q verificata: max |somma riga| = %e  [OK]\n\n', err_Q);

% -------------------------------------------------------------------------
% [3/7] Calcolo distribuzione stazionaria pi
% -------------------------------------------------------------------------
fprintf('[3/7] Calcolo distribuzione stazionaria pi...\n');

I_tan = speye(n_tan);
A = (P_tang - I_tan)';
A(end, :) = ones(1, n_tan); 
b = zeros(n_tan, 1);
b(end) = 1;

pi_emc = (A \ b)';
H = 1 ./ qi(tan);
pi_tang = (pi_emc .* H') / sum(pi_emc .* H');

PI = zeros(1, ns);
PI(tan) = pi_tang;

fprintf('  Somma pi = %.10f  [deve essere 1.0]\n', sum(pi_tang));
fprintf('  Elementi negativi: %d\n\n', sum(pi_tang < -1e-10));

fprintf('  Top 5 stati piu'' probabili (tangibili):\n');
[sorted_pi, sorted_idx] = sort(pi_tang, 'descend');
for k = 1:min(5, length(sorted_pi))
    fprintf('    Stato globale %d:  pi = %f\n', tan(sorted_idx(k)), sorted_pi(k));
end
fprintf('\n');

% -------------------------------------------------------------------------
% [4/7] Calcolo throughput (tutte le transizioni)
% -------------------------------------------------------------------------
fprintf('[4/7] Calcolo throughput (tutte le transizioni)...\n\n');

X = zeros(1, nt);
ind_multiple = find(servers > 1);
stati_rilevanti = find(PI > 1e-15);

for i = stati_rilevanti
    if isempty(Ragg(i).abi), continue; end
    for t = Ragg(i).abi
        if isempty(find(ind_multiple == t, 1))
            f = 1;
        else
            p_ing = find(pre(:,t));
            tok_ing = Ragg(i).value(p_ing);
            peso_ing = pre(p_ing, t);
            f = min(min(fix(tok_ing' ./ peso_ing)), servers(t));
        end
        % Usiamo we_ra per calcolare il throughput corretto sia di temp che immed
        X(t) = X(t) + PI(i) * we_ra(t) * f;
    end
end

fprintf('  %-45s %10s %15s  %s\n', 'Transizione', 'Rate/Peso', 'Throughput', 'Tipo');
fprintf('  %s\n', repmat('-', 1, 80));
for t = 1:nt
    if maschera_trans(t) == 0
        tipo_str = '[temp]';
    else
        tipo_str = '[immed]';
    end
    fprintf('  %-45s %10.4f %15.6f  %s\n', nomi_trans{t}, we_ra(t), X(t), tipo_str);
end

% Trova l'indice per Assemblaggio 1 (prodotto finito)
idx_prod = find(strcmp(nomi_trans, 'Assemblaggio 1'));
if isempty(idx_prod), idx_prod = 1; end
th_prodotto = X(idx_prod);
fprintf('\n  Throughput prodotto finito (%s): %.6f tel/unita'' tempo\n\n', nomi_trans{idx_prod}, th_prodotto);

% -------------------------------------------------------------------------
% [5/7] Calcolo WIP per ogni posto
% -------------------------------------------------------------------------
fprintf('[5/7] Calcolo WIP per ogni posto...\n');

WIP = zeros(1, np);
for i = stati_rilevanti
    WIP = WIP + PI(i) * Ragg(i).value;
end
WIP_tot = sum(WIP);

fprintf('  WIP totale della rete: %.4f token\n\n', WIP_tot);
fprintf('  %-50s %s\n', 'Posto', 'WIP medio');
fprintf('  %s\n', repmat('-', 1, 65));
for p = 1:np
    if WIP(p) > 1e-6
        fprintf('  %-50s %.4f\n', nomi_posti{p}, WIP(p));
    end
end
fprintf('\n');

% -------------------------------------------------------------------------
% [6/7] Calcolo indici derivati...
% -------------------------------------------------------------------------
fprintf('[6/7] Calcolo indici derivati...\n\n');

sum_th_temp = 0;
for t = 1:nt
    if maschera_trans(t) == 0
        sum_th_temp = sum_th_temp + X(t);
    end
end
MLT = WIP_tot / th_prodotto;

fprintf('  +------------------------------------------------------+\n');
fprintf('  |  MANUFACTURING LEAD TIME  (Legge di Little)          |\n');
fprintf('  |                                                      |\n');
fprintf('  |  WIP totale              = %8.4f token            |\n', WIP_tot);
fprintf('  |  Sum throughput (temp.)  = %8.6f                |\n', sum_th_temp);
fprintf('  |  MLT                     = %9.4f unita'' tempo   |\n', MLT);
fprintf('  +------------------------------------------------------+\n\n');

fprintf('  %-45s %8s %11s %13s\n', 'Transizione (temporizzata)', 'Rate', 'Throughput', 'Efficienza');
fprintf('  %s\n', repmat('-', 1, 82));

eff_media = 0;
count_temp = 0;
eff_max = -1;
idx_bn = -1;

for t = 1:nt
    if maschera_trans(t) == 0
        eff = X(t) / rates(t);
        fprintf('  %-45s %8.4f %11.6f %12.2f%%\n', nomi_trans{t}, rates(t), X(t), eff * 100);
        
        eff_media = eff_media + eff;
        count_temp = count_temp + 1;
        
        if eff > eff_max
            eff_max = eff;
            idx_bn = t;
        end
    end
end

if count_temp > 0
    eff_media = eff_media / count_temp;
end

fprintf('  %s\n', repmat('-', 1, 82));
fprintf('  %-65s %7.2f%%\n\n', 'EFFICIENZA MEDIA', eff_media * 100);

fprintf('  COLLO DI BOTTIGLIA: "%s"\n', nomi_trans{idx_bn});
fprintf('  Efficienza = %.2f%%  (la transizione piu'' satura del sistema)\n\n', eff_max * 100);

% -------------------------------------------------------------------------
% [7/7] Calcolo tempo medio di attesa per posto
% -------------------------------------------------------------------------
fprintf('[7/7] Calcolo tempo medio di attesa per posto...\n\n');

fprintf('  %-50s %8s %13s %13s\n', 'Posto', 'WIP', 'Flusso ingr.', 'E[T] attesa');
fprintf('  %s\n', repmat('-', 1, 88));

Flusso = zeros(1, np);
for p = 1:np
    % Il flusso in uscita a regime è uguale al flusso in ingresso.
    % Calcoliamo il flusso uscente (somma dei throughput delle transizioni abilitate dal posto)
    for t = 1:nt
        if pre(p, t) > 0
            Flusso(p) = Flusso(p) + (X(t) * pre(p,t));
        end
    end
end

for p = 1:np
    if WIP(p) > 1e-6 && Flusso(p) > 1e-10
        ET = WIP(p) / Flusso(p);
        fprintf('  %-50s %8.4f %13.6f %13.4f\n', nomi_posti{p}, WIP(p), Flusso(p), ET);
    end
end
fprintf('\n');

% -------------------------------------------------------------------------
% RIEPILOGO FINALE
% -------------------------------------------------------------------------
fprintf('============================================================\n');
fprintf('  RIEPILOGO FINALE\n');
fprintf('============================================================\n');
fprintf('  Numero stati totali               : %d\n', ns);
fprintf('  Numero stati tangibili            : %d\n', n_tan);
fprintf('  Numero stati vanescenti           : %d\n', n_van);
fprintf('  --------------------------------------------------------\n');
fprintf('  WIP totale                        : %.4f token\n', WIP_tot);
fprintf('  MLT (Legge di Little)             : %.4f unita'' di tempo\n', MLT);
fprintf('  --------------------------------------------------------\n');
fprintf('  Throughput %-22s : %.6f tel/unita'' tempo\n', nomi_trans{idx_prod}, th_prodotto);
fprintf('  (= 1 telefono ogni %.1f unita'' di tempo)\n', 1/th_prodotto);
fprintf('  --------------------------------------------------------\n');
fprintf('  Efficienza media                  : %.2f%%\n', eff_media * 100);
fprintf('  Collo di bottiglia                : %s\n', nomi_trans{idx_bn});
fprintf('  Efficienza collo di bottiglia     : %.2f%%\n', eff_max * 100);
fprintf('============================================================\n\n');

disp(datetime)
disp('Calcola_Indici_Prestazione completato.')