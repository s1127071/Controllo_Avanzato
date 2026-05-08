load('Esercizio4_CSTR.mat');

CSTR_2 = setmpcsignals(CSTR, 'MV', 1, 'UD', 2, 'MD', 3, 'MO', [1, 2]);
% Apertura del mpcDesigner
mpcDesigner(CSTR_2); 