function [pre, I, H, M0, m_trans, rates, weights, priority, servers] = matrici_pre_I(filename,ind)

inizio_pre= ind(1,1); %B14'; %input('Indicare la cella(1,1) della matrice che si vuole leggere(es.C3): ','s');
fine_pre= ind(1,2); %G20'; %('Indicare la cella(n,n) della matrice che si vuole leggere(es.Y25): ','s');
due_punti=':';
range_pre = strcat(inizio_pre,due_punti,fine_pre);
[pre] = xlsread(filename,range_pre);

inizio_I = ind(2,1); %'B23';%input('Indicare la cella(1,1) della matrice che si vuole leggere(es.C3): ','s');
fine_I = ind(2,2); %'G29';%('Indicare la cella(n,n) della matrice che si vuole leggere(es.Y25): ','s');
range_I = strcat(inizio_I,due_punti,fine_I);
[I] = xlsread(filename,range_I);

inizio_H = ind(3,1); %'B32';
fine_H = ind(3,2); %'G38';
range_H = strcat(inizio_H,due_punti,fine_H);
[H] = xlsread(filename,range_H);

inizio_M0 = ind(4,1);
fine_M0 = ind(4,2);
range_M0 = strcat(inizio_M0,due_punti,fine_M0);
[M0] = xlsread(filename,range_M0);

inizio_m_trans = ind(5,1);
fine_m_trans = ind(5,2);
range_m_trans = strcat(inizio_m_trans,due_punti,fine_m_trans);
[m_trans] = xlsread(filename,range_m_trans);

inizio_rates_trans = ind(6,1);
fine_rates_trans = ind(6,2);
range_rates_trans = strcat(inizio_rates_trans,due_punti,fine_rates_trans);
[rates] = xlsread(filename,range_rates_trans);

inizio_pesi_trans = ind(7,1);
fine_pesi_trans = ind(7,2);
range_pesi_trans = strcat(inizio_pesi_trans,due_punti,fine_pesi_trans);
[weights] = xlsread(filename,range_pesi_trans);

inizio_pr_trans = ind(8,1);
fine_pr_trans = ind(8,2);
range_pr_trans = strcat(inizio_pr_trans,due_punti,fine_pr_trans);
[priority] = xlsread(filename,range_pr_trans);

inizio_servers_trans = ind(9,1);
fine_servers_trans = ind(9,2);
range_servers_trans = strcat(inizio_servers_trans,due_punti,fine_servers_trans);
[servers] = xlsread(filename,range_servers_trans);

