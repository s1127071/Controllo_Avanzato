function [list, Ragg] = Calcola_Marc_Ragg(a, list, Ragg, I, pre, H, t_pr)
    %% VERSIONE OTTIMIZZATA PER GRANDI RETI (Preallocazione + Hash Map)
    
    [m0, ~] = Crea_Struttura(a, I, pre, H, t_pr);

    % Preallocazione della memoria (evita array continui ri-allocamenti)
    alloc_size = 200000; % Impostato per contenere agilmente 180k+ stati
    list = zeros(alloc_size, length(a));
    list(1, :) = m0.value;
    
    Ragg = repmat(m0, alloc_size, 1);

    % Hash Map per ricerca stato in O(1) invece che O(N)
    visitati = containers.Map('KeyType', 'char', 'ValueType', 'logical');
    visitati(mat2str(m0.value)) = true;

    head = 1;
    tail = 1;

    while head <= tail
        current = Ragg(head);
        head = head + 1;

        if isempty(current.abi)
            continue;
        end

        [n_successori, ~] = size(current.out.value);

        for i = 1:n_successori
            next_m = current.out.value(i, :);
            str_m = mat2str(next_m);

            % Controllo istantaneo tramite Mappa
            if ~isKey(visitati, str_m)
                visitati(str_m) = true;
                tail = tail + 1;

                % Espansione dinamica se superiamo i 200k stati
                if tail > size(list, 1)
                    list = [list; zeros(alloc_size, length(a))]; %#ok<AGROW>
                    Ragg = [Ragg; repmat(m0, alloc_size, 1)];    %#ok<AGROW>
                end

                list(tail, :) = next_m;
                [m_next, ~] = Crea_Struttura(next_m, I, pre, H, t_pr);
                Ragg(tail) = m_next;
            end
        end
    end

    % Tronca la memoria non utilizzata
    list = list(1:tail, :);
    Ragg = Ragg(1:tail);
end