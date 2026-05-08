clear all;
clc;

% Matrici del sistema
A = -0.8;
B = [1, 1, -2]; 
C = 1;
D = [0, 0, 0];

% Creazione modello in spazio di stato
sys_tank = ss(A, B, C, D);

sys_tank.TimeUnit = 'minutes';

% Nomi e unità di misura delle variabili
sys_tank.InputName = {'Q1', 'Q2', 'X'};
sys_tank.InputUnit = {'l/min', 'l/min', '%'};
sys_tank.OutputName = {'V'};
sys_tank.OutputUnit = {'l'};
sys_tank.StateName = {'V'};
sys_tank.StateUnit = {'l'};

% Salvataggio del modello .mat
save('Esercizio15_sys_tank.mat', 'sys_tank');