function [m0, m1] = Crea_Struttura(m, C, pre, H, t_pr)
    %Tale funzione viene utilizzata per calcolare le marcature raggiunte da
    %uno stato creando un elemento avente la seguente struttura:
    %
    %m0.value   = marcatura dello stato
    %m0.abi     = transizioni abilitate (vettore indici, vuoto se stato assorbente)
    %m0.out.num = numero di stati raggiungibili ad un passo
    %m0.out.value = stati raggiungibili (matrice righe, vuota se assorbente)
    %
    % Parametri in ingresso:
    %   m     : marcatura corrente (vettore riga 1 x np)
    %   C     : matrice di incidenza (np x nt)
    %   pre   : matrice pre (np x nt)
    %   H     : matrice di inibizione (np x nt)
    %   t_pr  : vettore priorita' transizioni (1 x nt)
    %
    % Parametri in uscita:
    %   m0 : struttura dello stato
    %   m1 : marcature uscenti (matrice righe, [] se assorbente)

    %% Inizializzazione
    m0.value     = m;
    m0.abi       = [];          % default: nessuna transizione abilitata
    m0.out.num   = 0;           % default: nessun successore
    m0.out.value = [];          % FIX BUG 1 -- era non inizializzato, causava errore
                                % quando sum(m0Abi)==0 e si accedeva a m0.out.value

    [np, nt] = size(pre);
    m0Abi = zeros(1, nt);

    %% Controlla se ogni transizione e' abilitata (verifica pre e inibitori)
    for i = 1:nt
        % --- verifica archi inibitori ---
        inib_ok = 1;
        if ~isequal(H(:,i), zeros(np,1))
            posti_inibiti = find(H(:,i));
            for j = posti_inibiti'          % riga: compatibile con scalare e vettore
                if m0.value(j) ~= 0
                    inib_ok = 0;
                    break;                  % ottimizzazione: basta un posto non-zero
                end
            end
        end
        % --- verifica pre (nessun posto va negativo) ---
        if inib_ok && isempty(find(m0.value' - pre(:,i) < 0, 1))
            m0Abi(i) = 1;
        end
    end

    %% Applicazione delle priorita'
    a1 = find(m0Abi > 0);

    if isempty(a1)
        % FIX BUG 2 -- era: max_pri = max(t_pr(a1)) che con a1=[] restituisce []
        % poi t_pr(i) < [] causava errore nel for. Ora usciamo subito.
        m1 = [];
        return;
    end

    max_pri = max(t_pr(a1));
    for i = a1
        if t_pr(i) < max_pri
            m0Abi(i) = 0;
        end
    end
    a2 = find(m0Abi > 0);

    %% Calcolo marcature uscenti
    m0.out.num = length(a2);
    for i = 1:m0.out.num
        m0.out.value(i,:) = m0.value + C(:, a2(i))';
    end

    %% Assegnazione finale
    m0.abi = a2;
    m1     = m0.out.value;
end
