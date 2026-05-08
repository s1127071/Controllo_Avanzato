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
fprintf("\nRisultati all'istante k: \n");
fprintf('delta_u_hat(k|k) = %.4f\n', delta_u_hat);
fprintf('u_hat(k|k) = %.4f\n', u_hat);

% Calcolo della y all'istante k+1
y_attuale_k1 = 0.65 * y_attuale + 1.8 * u_hat;
u_precedente_k1 = u_hat;

% Calcolo della nuova traiettoria di riferimento per k+1
epsilon_attuale_k1 = set_point - y_attuale_k1;
if Tref == 0
    epsilon_finale_k1 = 0;
else
    epsilon_finale_k1 = epsilon_attuale_k1 * exp(-Hp * Ts / Tref);
end
r_finale_k1 = set_point - epsilon_finale_k1;

% Calcolo della nuova risposta libera 
y_libera_predetta_k1 = zeros(1, Hp);
y_libera_predetta_k1(1) = 0.65 * y_attuale_k1 + 1.8 * u_precedente_k1;
for i = 2:Hp
    y_libera_predetta_k1(i) = 0.65 * y_libera_predetta_k1(i-1) + 1.8 * u_precedente_k1;
end

% Determinazione della mossa ottima
delta_u_hat_k1 = (r_finale_k1 - y_libera_predetta_k1(Hp)) / y_step_finale;
u_hat_k1 = u_precedente_k1 + delta_u_hat_k1;

% Predizione dell'uscita futura y(k+2) usando la mossa appena calcolata
y_k2 = 0.65 * y_attuale_k1 + 1.8 * u_hat_k1;

fprintf("\n Risultati all'istante k+1: \n");
fprintf('delta_u_hat(k+1|k+1) = %.4f\n', delta_u_hat_k1);
fprintf('u_hat(k+1|k+1) = %.4f\n', u_hat_k1);
fprintf('y_predetta(k+2) = %.4f\n', y_k2);