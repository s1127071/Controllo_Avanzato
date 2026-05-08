clear all;
clc;

A = [ -5 -0.3427;
47.68 2.785];
B = [ 0 1
0.3 0];
C = flipud(eye(2));
D = zeros(2);

% Aggiunta del nuovo ingresso con le stesse caratteristiche del disturbo
B_new = [B, B(:, 2)]; 
D_new = [D, D(:, 2)];

% Creazione del modello
CSTR = ss(A, B_new, C, D_new);
% Definizione dei nomi e unità
CSTR.InputName = {'T_c', 'C_A_f', 'C_A_f'}; 
CSTR.InputUnit = {'K', 'kmol/m3', 'kmol/m3'};
CSTR.OutputName = {'T', 'C_A'};
CSTR.OutputUnit = {'K', 'kmol/m3'};
CSTR.StateName = {'C_A', 'T'};
CSTR.StateUnit = {'kmol/m3', 'K'};

% Configurazione dei segnali MPC
CSTR = setmpcsignals(CSTR, 'MV', 1, 'UD', 2, 'MD', 3, 'MO', 1, 'UO', 2);

% Salvataggio file .mat
save('Esercizio4_CSTR.mat', 'CSTR');