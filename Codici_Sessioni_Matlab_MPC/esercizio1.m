clear all;
clc;

num = 1.8;
den = [1 -0.65];
Ts =2.0;
G = tf(num,den, Ts);

% Parametri MPC
Hp = 3;
Hu = 1;
P1 = Hp;
set_point = 2.8;
Tref = 0.0;

u_precedente = 0.35;
y_precedente = 1.8;
y_attuale = 1.8;

epsilon_attuale = set_point - y_attuale;

if Tref == 0
    epsilon_finale = 0; % Risposta immediata desiderata
else
    epsilon_finale = epsilon_attuale * exp(-Hp * Ts / Tref);
end

r_finale = set_point - epsilon_finale;
fprintf('Reference trajectory r(k+%d|k) = %.4f\n', Hp, r_finale);

% Calcolo della risposta libera del sistema
y_libera_predetta = zeros (1,Hp);
y_libera_predetta(1) = 0.65*y_attuale + 1.8*u_precedente;
for i = 2:Hp
    y_libera_predetta(i) = 0.65*y_libera_predetta(i-1) + 1.8*u_precedente;
end

y_predetta_finale = y_libera_predetta(Hp);
fprintf('Risposta libera y_free(k+%d|k) = %.4f\n',Hp,y_predetta_finale);

% Calcolo della risposta forzata al gradino
y_step = zeros (1, Hp+1);
y_step(1) = 0;
for j = 2:Hp+1
    y_step(j) = 0.65*y_step(j-1) + 1.8;
end
y_step_finale = y_step(Hp+1);
fprintf('Risposta forzata S(%d) = %.4f\n',Hp,y_step_finale);

% Calcolo dell'ingresso ottimo
delta_u_hat = (r_finale - y_predetta_finale) / y_step_finale;
u_hat = u_precedente + delta_u_hat;
fprintf("\nRisultato all'istante k: \n");
fprintf('delta_u_hat(k|k) = %.4f\n', delta_u_hat);
fprintf('u_hat(k|k) = %.4f\n', u_hat);

% Calcolo dell'uscita predetta y(k+1)
y_k1 = 0.65*y_attuale + 1.8*u_hat;
fprintf('y_predetta(k+1) = %.4f\n', y_k1);

% Simulazione per i grafici
time_sim = -2:Ts:20; % tempo di simulazione
y_simulata = zeros(1, length(time_sim));
u_simulata = zeros(1, length(time_sim));

% Condizioni iniziali per la simulazione
y_simulata(1) = y_precedente;
y_simulata(2) = y_attuale;
u_simulata(1) = u_precedente;
u_simulata(2) = u_hat;

% Simulazione MPC
for k = 3:length(time_sim)
    % Applicazione MPC ricorsivamente
    eps = set_point - y_simulata(k-1); 
    
    if Tref == 0
        r_k = set_point;
    else
        r_k = set_point - eps*exp(-Hp*Ts/Tref);
    end
    
    % Risposta libera
    y_free = zeros(1, Hp);
    y_free(1) = 0.65*y_simulata(k-1) + 1.8*u_simulata(k-1);
    for i = 2:Hp
        y_free(i) = 0.65*y_free(i-1) + 1.8*u_simulata(k-1);
    end
    
    % Ingresso ottimo
    delta_u = (r_k - y_free(Hp)) / y_step_finale;
    u_simulata(k) = u_simulata(k-1) + delta_u;
    
    % Aggiornamento dell'uscita
    y_simulata(k) = 0.65*y_simulata(k-1) + 1.8*u_simulata(k);
end

% Creazione grafici
figure;

subplot(2,1,1)
plot(time_sim, y_simulata, '-o', 'LineWidth', 1.5);
hold on;
plot(time_sim, set_point * ones(1, length(time_sim)), '--r', 'LineWidth', 1.2);
xlabel('Tempo (s)');
ylabel('Uscita y(k)');
title('Simulazione della risposta del sistema con MPC');
legend('y(k) simulata', 'Reference s(k)');
grid on;

subplot(2,1,2)
stairs(time_sim, u_simulata, '-s', 'LineWidth', 1.5);
xlabel('Tempo (s)');
ylabel('Ingresso di controllo u(k)');
title('Andamento del segnale di controllo');
grid on;