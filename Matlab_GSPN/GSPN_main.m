%% GSPN_main.m  -- VERSIONE OTTIMIZZATA PER GRANDI RETI
% Fix Memoria: Matrici Sparse (evita crash da 240GB)
% Fix Velocità: Uso di Hash Maps e Indicizzazione Vettoriale

clear; clc; format short;

%% Raccolta dati strutturali
load('Data_matrici_Funzionante_vers2.3.mat')   % <--- Controlla che il nome sia giusto!
[pre, I, H, m_ini, maschera_trans, rates, weights, t_pr, servers] = matrici_pre_I(filename, indici);

m_ini = m_ini(1,:);
we_ra = weights + rates;

disp(datetime)
disp('Calcolo grafo di raggiungibilita...')

list = m_ini;
Ragg = [];
[list, Ragg] = Calcola_Marc_Ragg_leggero(m_ini, list, Ragg, I, pre, H, t_pr);
[ns, ~] = size(Ragg);
fprintf('Numero di stati: %d\n', ns);

%% CALCOLO DEL VETTORE qi
disp('Calcolo vettore qi...')
qi = zeros(ns, 1);
tan = []; van = [];
ind_multiple = find(servers > 1);

for i = 1:ns
    if isempty(Ragg(i).abi)
        tan(end+1) = i; %#ok<AGROW>
        continue; 
    end

    for t = Ragg(i).abi
        if isempty(find(ind_multiple == t, 1))
            qi(i) = qi(i) + we_ra(t);
        else
            p_ing    = find(pre(:,t));
            tok_ing  = Ragg(i).value(p_ing);
            peso_ing = pre(p_ing, t);
            minimi   = fix(tok_ing' ./ peso_ing);
            ED       = min(minimi);
            K        = servers(t);
            f        = min(ED, K);
            qi(i)    = qi(i) + we_ra(t) * f;
        end
    end

    if maschera_trans(Ragg(i).abi(1)) == 0
        tan(end+1) = i; %#ok<AGROW>
    else
        van(end+1) = i; %#ok<AGROW>
    end
end

SJ = zeros(ns,1);
for i = 1:ns
    if qi(i) ~= 0
        SJ(i) = 1 / qi(i);
    end
end

%% CALCOLO DELLA MATRICE U_g (SPARSA)
disp(datetime)
disp('Calcolo matrice U_g (in formato sparso)...');

% 1. Mappa per ricerca rapida O(1)
state2idx = containers.Map('KeyType', 'char', 'ValueType', 'double');
for i = 1:ns
    state2idx(mat2str(Ragg(i).value)) = i;
end

% 2. Vettori per l'allocazione della matrice sparsa
I_idx = zeros(ns*5, 1); % Preallocazione stima 5 transizioni abilitate per stato
J_idx = zeros(ns*5, 1);
V_val = zeros(ns*5, 1);
count = 0;

for i = 1:ns
    if isempty(Ragg(i).abi), continue; end

    for k = 1:Ragg(i).out.num
        t_k    = Ragg(i).abi(k);
        next_m = Ragg(i).out.value(k, :);
        j = state2idx(mat2str(next_m));

        if isempty(find(ind_multiple == t_k, 1))
            f = 1;
        else
            p_ing    = find(pre(:,t_k));
            tok_ing  = Ragg(i).value(p_ing);
            peso_ing = pre(p_ing, t_k);
            minimi   = fix(tok_ing' ./ peso_ing);
            ED       = min(minimi);
            K        = servers(t_k);
            f        = min(ED, K);
        end

        rate_contrib = we_ra(t_k) * f;
        val = rate_contrib / qi(i);

        count = count + 1;
        % Espansione dinamica array sparsa
        if count > length(I_idx)
            I_idx = [I_idx; zeros(ns*5, 1)]; %#ok<AGROW>
            J_idx = [J_idx; zeros(ns*5, 1)]; %#ok<AGROW>
            V_val = [V_val; zeros(ns*5, 1)]; %#ok<AGROW>
        end
        I_idx(count) = i;
        J_idx(count) = j;
        V_val(count) = val;
    end
end

% Tronca memorie inutilizzate
I_idx = I_idx(1:count);
J_idx = J_idx(1:count);
V_val = V_val(1:count);

% 3. Creazione della matrice sparsa
% MATLAB somma automaticamente le probabilità se più archi portano allo stesso j
U_g = sparse(I_idx, J_idx, V_val, ns, ns);

somme = sum(U_g, 2);
stati_errati = find(abs(somme - 1) > 1e-6 & somme ~= 0);
if isempty(stati_errati)
    disp('Matrice U_g OK (tutte le righe sommano a 1 o 0)');
else
    fprintf('ATTENZIONE: %d stati con somma U anomala\n', length(stati_errati));
end

%% PARTIZIONAMENTO U (VETTORIALIZZATO)
disp(datetime)
disp('Calcolo U partizionata in modo vettorializzato...');

% Invece di doppi cicli FOR infiniti, usiamo gli indici estrapolati prima!
Cmat = U_g(van, van);
Dmat = U_g(van, tan);
Emat = U_g(tan, van);
Fmat = U_g(tan, tan);

U = [Cmat, Dmat; Emat, Fmat];

disp(datetime)
disp('GSPN_main completato.')
fprintf('Dimensione U: %d x %d\n\n', size(U,1), size(U,2));

%% SEZIONE SALVATAGGIO
nome_predefinito = 'GSPN_main_out.mat';
[nome_file, percorso] = uiputfile('*.mat', 'Scegli dove e come salvare il Workspace', nome_predefinito);
if isequal(nome_file, 0) || isequal(percorso, 0)
    disp('Salvataggio annullato.');
else
    percorso_completo = fullfile(percorso, nome_file);
    save(percorso_completo);
    disp(['Workspace salvato in: ', percorso_completo]);
end