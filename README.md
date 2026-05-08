# Controllo Avanzato, Ottimizzazione e Analisi di Processi

Repository del progetto realizzato per il corso di **Controllo Avanzato, Ottimizzazione e Analisi di Processi** dell'Universita' Politecnica delle Marche. Il progetto si compone di due blocchi principali e tra loro indipendenti: un'analisi di prestazione di un sistema produttivo modellato con Reti di Petri Stocastiche, e una raccolta di esercizi sul Model Predictive Control (MPC) sviluppati durante le sessioni di laboratorio.

## Descrizione del progetto

Il lavoro nasce con l'obiettivo di applicare le tecniche di analisi e controllo viste nel corso a casi di studio realistici. La prima parte si concentra sul lato \emph{analitico-stocastico}: viene preso un sistema produttivo industriale e tradotto in un modello formale di Rete di Petri Generalizzata Stocastica (GSPN), su cui si calcolano gli indici classici della teoria dei sistemi di manifattura (velocita' di produzione, work-in-process, tempo di attraversamento, fattore di utilizzazione delle macchine, individuazione del collo di bottiglia). La seconda parte e' dedicata al lato \emph{progettuale-deterministico}: si studia il comportamento del Model Predictive Control su una serie di sistemi dinamici a complessita' crescente, mettendo a confronto orizzonti di predizione, pesi del costo, vincoli e disturbi.

## La rete Samsung

Il sistema produttivo modellato e' la linea di produzione di smartphone dello stabilimento Samsung di Gumi, in Corea del Sud. Il processo reale comprende quattro macro-fasi: la lavorazione meccanica dell'alluminio (taglio, laminatura, fresatura e lucidatura per ottenere chassis, carrellini SIM e tasti laterali), la preparazione della scheda elettronica (PCB), l'assemblaggio dello smartphone (montaggio di batteria, fotocamera, display) e infine la fase di test qualita'.

Della linea reale e' stata costruita una versione completa della rete e successivamente una rete semplificata, ottenuta aggregando le fasi a monte e chiudendo il sistema con una transizione di riciclo. Quest'ultima versione mantiene gli elementi piu' interessanti dal punto di vista del controllo (saturazione dei macchinari, mutua esclusione sulla giostra di lucidatura, vincolo del lotto da due pezzi, presenza di un collo di bottiglia ben individuabile) ma ha uno spazio degli stati finito e calcolabile in tempi ragionevoli. Sulla rete semplificata sono state poi analizzate quattro configurazioni: la rete base, una variante con guasto sull'operatore di separazione, una variante con buffer pre-test e disaccoppiamento della stazione di collaudo (pipelining), e una configurazione ibrida che combina le due ultime modifiche.

## Esercizi MPC

La parte di Model Predictive Control raccoglie diciannove esercitazioni sviluppate durante il corso. L'idea del MPC e' quella di calcolare ad ogni passo l'azione di controllo risolvendo un problema di ottimizzazione su un orizzonte futuro, tenendo esplicitamente conto di vincoli su ingressi, uscite e stato. Il vantaggio rispetto ai controllori classici e' la possibilita' di gestire in modo nativo i vincoli e di anticipare gli effetti delle decisioni odierne.

Gli esercizi partono da sistemi semplici (gestiti via codice MATLAB con simulazioni manuali) e progrediscono verso casi piu' realistici (CSTR, sistemi di livello di serbatoi, sistemi multi-input multi-output) impiegando il MPC Designer Toolbox di MATLAB e salvando le configurazioni come sessioni MPC. Ogni esercizio confronta scenari diversi al variare delle scelte di progetto: orizzonti di predizione e controllo, pesi del costo sulle uscite e sugli incrementi di ingresso, vincoli stringenti o rilassati, presenza di disturbi misurati e non misurati. L'obiettivo non e' tanto quello di trovare il "controllore migliore" quanto di costruire l'intuizione su come ciascun parametro influenzi la risposta del sistema.

## Struttura della repository

```
.
|-- Reti_di_Petri/                  # modelli PIPE in formato XML
|-- Matlab_GSPN/                    # script MATLAB di analisi GSPN
|-- Codici_Sessioni_Matlab_MPC/     # esercizi e sessioni MPC
|-- README.md
```

### Reti_di_Petri

Contiene i modelli della rete in formato PNML (esportati da PIPE 4.3.0), pronti per essere importati nello stesso software o letti dagli script di analisi:

- `Produzione_samsung.xml` -- rete completa, ricalca fedelmente l'architettura dell'impianto reale.
- `Produzione_samsung_SEMPLIFICATA.xml` -- rete semplificata, ottenuta dalla precedente con aggregazione delle fasi a monte e introduzione del riciclo. E' la versione utilizzata per le analisi quantitative.
- `Produzione_samsung_SEMPLIFICATA_Guasto_Operatore.xml` -- variante con ciclo guasto/riparazione sull'operatore di separazione (single point of failure).
- `Produzione_samsung_SEMPLIFICATA_buffer_test.xml` -- variante con buffer pre-test e disaccoppiamento della stazione di collaudo.
- `Produzione_samsung_SEMPLIFICATA_buffer_test_+_guasto_operatore.xml` -- combinazione delle due varianti precedenti.

Una sotto-cartella `Matrici_Incidenza` raccoglie le matrici Pre, di incidenza e di inibizione esportate per essere consumate dagli script MATLAB.

### Matlab_GSPN

Contiene la pipeline di analisi della rete:

- `GSPN_main.m` -- script principale che orchestra il calcolo. Carica le matrici, costruisce il grafo di raggiungibilita' tramite una visita in ampiezza iterativa, calcola la matrice di transizione del processo di Markov in formato sparso e la partiziona nelle quattro sottomatrici tipiche dell'analisi GSPN.
- `Calcola_Marc_Ragg.m` -- funzione di reachability che, data una marcatura iniziale, esplora tutti gli stati raggiungibili. Implementata con preallocazione della memoria e indicizzazione tramite hash map per gestire reti con centinaia di migliaia di stati.
- `Crea_Struttura.m` -- funzione ausiliaria che, per ogni marcatura, calcola le transizioni abilitate (tenendo conto di archi inibitori e priorita' immediate-su-temporizzate) e gli stati raggiungibili in un passo.
- `Calcola_Indici_Prestazione.m` -- script che, ricevuto in input il workspace prodotto da GSPN_main, riduce gli stati vanishing tramite la Reduced Embedded Markov Chain, calcola la distribuzione stazionaria e da essa ricava throughput, WIP, lead time, efficienze e tempi medi di attesa per ogni risorsa.
- `matrici_pre_I.m` -- funzione di lettura delle matrici dal file Excel di descrizione della rete.

### Codici_Sessioni_Matlab_MPC

Contiene gli esercizi sul Model Predictive Control sviluppati durante il corso. Comprende sia script MATLAB autonomi (per gli esercizi piu' semplici, in cui il controllore e' implementato a mano) sia sessioni del MPC Designer Toolbox (per gli esercizi piu' avanzati, in cui il controllore e' progettato graficamente e poi simulato). Gli esercizi sono numerati progressivamente da uno a diciannove, e affiancano sistemi sintetici a casi di studio classici come il reattore CSTR e i sistemi di gestione di serbatoi.

## Strumenti utilizzati

- **PIPE 4.3.0** per la modellazione grafica delle reti di Petri.
- **MATLAB R2023a** (con MPC Toolbox) per le analisi GSPN e gli esercizi MPC.
- **LaTeX** per la stesura della relazione finale.
