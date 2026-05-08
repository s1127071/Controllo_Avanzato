clear all;
clc;

num = 1.8;
den = [1, -0.65]; 
Ts = 2.0;         
G = tf(num, den, Ts);

% Parametri MPC
Hp = 3;           
Hu = 3;           
c = 3;
P = [1, 2, 3];   
set_point = 2.8;  
Tref = 6.0;

% Condizioni iniziali
u_precedente = 0.35; 
y_attuale = 1.8;     
y_precedente = 1.8;
epsilon_attuale = set_point - y_attuale;

epsilon_P = zeros(1, c); 
ref_P = zeros(1, c);  
for i = 1:c
    epsilon_P(i) = epsilon_attuale * exp(-(P(i)*Ts)/Tref);
    ref_P(i) = set_point - epsilon_P(i);
end
T = ref_P'; 
fprintf('Vettore riferimento T:\n'); disp(T);

% Calcolo della risposta libera
y_libera_predetta = zeros(c, 1);
y_libera_temp = y_attuale;
for i = 1:Hp

    y_libera_temp = 0.65 * y_libera_temp + 1.8 * u_precedente;
    y_libera_predetta(i) = y_libera_temp;
end
fprintf('Vettore risposta libera:\n'); disp(y_libera_predetta);

% Calcolo della risposta forzata al gradino
y_step = zeros(1, Hp);
s_temp = 0;
for j = 1:Hp
    s_temp = 0.65 * s_temp + 1.8; % y(k) = 0.65*y(k-1) + 1.8*u(k-1) con u=1
    y_step(j) = s_temp;
end
y_step_finale = y_step(Hp); % S(Hp)
fprintf('Coefficienti risposta al gradino S:\n'); disp(y_step');

% Costruzione della matrice Theta
Theta = [ y_step(1)   0           0;
          y_step(2)   y_step(1)   0;
          y_step(3)   y_step(2)   y_step(1) ];
fprintf('Matrice Theta:\n'); disp(Theta);

% Calcolo dell'ingresso ottimo con risoluzione del sistema
Delta_U_vettore = Theta \ (T - y_libera_predetta);
delta_u_hat = Delta_U_vettore(1); 
u_hat = u_precedente + delta_u_hat; 

fprintf("\nRisultato all'istante k: \n");
fprintf('delta_u_hat(k|k) = %.4f\n', delta_u_hat);
fprintf('u_hat(k|k) = %.4f\n', u_hat);

% Calcolo dell'uscita predetta
y_k1 = 0.65 * y_attuale + 1.8 * u_hat;
fprintf('y_predetta(k+1) = %.4f\n\n', y_k1);

% Simulazione per i grafici
time_sim = -2:Ts:20; 
y_simulata = zeros(1, length(time_sim));
u_simulata = zeros(1, length(time_sim));

% Condizioni iniziali per la simulazione
y_simulata(1) = y_precedente;
y_simulata(2) = y_attuale;
u_simulata(1) = u_precedente;
u_simulata(2) = u_hat;

% Simulazione MPC
lambda = exp(-Ts/Tref); 
for k = 3:length(time_sim)
    eps_loop = set_point - y_simulata(k-1);
    T_loop = zeros(c, 1);
    for i = 1:c
        T_loop(i) = set_point - eps_loop * (lambda^P(i));
    end
    
    Yf_loop = zeros(c, 1);
    yl_temp = y_simulata(k-1);
    for i = 1:Hp
        yl_temp = 0.65 * yl_temp + 1.8 * u_simulata(k-1);
        Yf_loop(i) = yl_temp;
    end
    
    DU_loop = Theta \ (T_loop - Yf_loop);
    u_simulata(k) = u_simulata(k-1) + DU_loop(1);
    
    y_simulata(k) = 0.65 * y_simulata(k-1) + 1.8 * u_simulata(k);
end

% Creazione dei grafici
figure;
subplot(2,1,1)
plot(time_sim, y_simulata, '-o', 'LineWidth', 1.5); hold on;
plot(time_sim, set_point * ones(1, length(time_sim)), '--r', 'LineWidth', 1.2);
xlabel('Tempo (s)'); ylabel('Uscita y(k)');
title('Simulazione MPC: Hu=3, c=3, Tref=6s');
legend('y(k) simulata', 'Set-point');
grid on;

subplot(2,1,2)
stairs(time_sim, u_simulata, '-*', 'LineWidth', 1.5);
xlabel('Tempo (s)'); ylabel('Ingresso u(k)');
title('Andamento del segnale di controllo');
grid on;