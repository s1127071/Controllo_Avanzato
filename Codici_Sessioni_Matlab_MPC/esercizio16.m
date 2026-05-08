% Caricamento del modello
load('Esercizio15_sys_tank.mat'); 

sys_tank = setmpcsignals(sys_tank, 'MV', [1, 2], 'MD', 3, 'MO', 1);

% Apertura del mpcDesigner
mpcDesigner(sys_tank);