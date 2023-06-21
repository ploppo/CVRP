% scelta del dataset in base al numero di nodi
% all'intero ci sono: la matrice delle distanze (distance)
%                     il vettore delle richieste (demand)
%                     le coordinate sulla mappa (coord)
%                     la capacita' massima (cmax)

load('dataset80.mat')  % dataset con 80 nodi
% load('dataset32.mat')    % dataset con 32 nodi

nnode = size(distance);
nnode = nnode(1); % numero di nodi sulla mappa
strada = cell(nnode,1); % lista delle strade che verranno create, inizializziamo con il numero massimo di nodi e in seguito capiremo quante ne verranno effettivamente create
assegnamento = zeros(nnode,1); % vettore che indica a quale strada e' stato assegnato il nodo i-esimo 

for i=1:nnode % ciclo che dice che ogni strada inizia con il nodo 1 (deposito)
    strada{i}=1;
end

% implementazione del METODO COSTRUTTIVO dei saving 

saving = zeros(nnode,nnode); % matrice che conterra' i "saving" dei nodi
%... ed essendo simmetrica si puo' fare triangolare
for i=2:nnode
    for j = i+1:nnode
        saving(i,j)=distance(1,i)+distance(1,j)-distance(i,j);
    end
end
nstrada = 0; % inizializzazione
m = 10e5; % indica il saving piu' grande trovato finora

% ciclo while che assegna tutti i nodi a una determinata strada in base a 3 diversi criteri di assegnamento, va avanti finche' tutte le strade non sono state assegnate, controllando la variabile "assegnamento"

while sum(assegnamento~=0)<nnode-1 % -1 perche' il deposito non va assegnato
    M =  max(saving(saving<m)); % trovo il massimo saving minore del precedente
    [i,j]=find(saving == M);    % trovo i nodi che hanno quell' esatto saving
    nconflitti = size(i,1);     % ATTENZIONE: i nodi con lo stesso saving posso essere di piu'! Tengo conto del loro numero con questa variabile 
    for t = 1:nconflitti
        % primo criterio di assegnamento: se nessuno dei due nodi i e j del saving e' stata assegnato e il vincolo di capacita' e' rispettato, allora li assegno entrambi a una nuova strada (nstrada+1)
        if assegnamento(i(t))==0 && assegnamento(j(t))==0 
            if demand(i(t)) + demand(j(t)) <= cmax
                assegnamento(i(t)) = nstrada+1;
                assegnamento(j(t)) = nstrada+1;
                strada{assegnamento(i(t))} = [strada{assegnamento(i(t))},i(t),j(t)];
                capacity(assegnamento(i(t))) = demand(i(t))+demand(j(t)); % aggiornando la capacita' residua della strada 
                nstrada = nstrada+1;
            end
        % secondo criterio: se il nodo di arrivo j non e' stato ancora assegnato, lo inserisco nella strada del nodo i, nel caso in cui il vincolo di capacita' sia rispettato
        elseif  assegnamento(j(t))==0
            if capacity(assegnamento(i(t))) + demand(j(t)) <= cmax
                strada{assegnamento(i(t))} = [strada{assegnamento(i(t))},j(t)];
                capacity(assegnamento(i(t))) = capacity(assegnamento(i(t))) + demand(j(t));
                assegnamento(j(t)) = assegnamento(i(t));
            end
        % terzo criterio: uguale al secondo criterio ma fatto per il nodo di partenza i
        elseif assegnamento(i(t))==0
            if capacity(assegnamento(j(t))) + demand(i(t)) <= cmax
                strada{assegnamento(j(t))} = [strada{assegnamento(j(t))},i(t)];
                capacity(assegnamento(j(t))) = capacity(assegnamento(j(t))) + demand(i(t));
                assegnamento(i(t)) = assegnamento(j(t));
            end
        end
    end
    m = M; % aggiorno il nuovo valore di saving
end
% calcolo il costo finale con il metodo costruttivo dei saving
costo = zeros(nstrada,1);
for i=1:nstrada
    strada{i}=[strada{i},1]; % aggiungo il deposito come strada finale
    for j = 1: size(strada{i},2)-1
        costo(i) = costo(i) + distance(strada{i}(j),strada{i}(j+1)); % sommo i costi di ogni arco
    end
end
costo_tot = sum(costo);

% implementazione del METODO ITERATIVO 2 opt
% controlliamo se nuove coppie di nodi nella stessa strada posso portare a una diminuzione del costo totale

for j = 1:nstrada % per ogni strada creata
minimo_old = 0;
minimo_new = 20;
    while minimo_new ~= 0
        minimo_old = 0;
        minimo_new = 20;
        lunghezza = length(strada{j})-1; % numero di nodi visitati dalla strada j
        % salvo gli archi (coppie di nodi successivi) della strada j
        for i = 1: lunghezza
            arco{j}{i} = [strada{j}(i) strada{j}(i+1)];
        end 
        % inizio confronto di nuovi archi all'interno della strada j
        for i = 1:(lunghezza-2)
            if i == 1
                last_check = lunghezza-1;
            else 
                last_check = lunghezza;
            end
             for k = (i+2):last_check
                % valuto la distanza iniziale, sommando i pesi di due archi non consecutivi, e poi la distanza finale che ottengo facendo uno scambio dei nodi
                distanza_iniziale = distance(arco{j}{i}(1),arco{j}{i}(2)) + distance(arco{j}{k}(1),arco{j}{k}(2));
                distanza_finale = distance(arco{j}{i}(1),arco{j}{k}(1)) + distance(arco{j}{i}(2),arco{j}{k}(2));
                %controllo se ho migliorato la situazione
                minimo_new = min(minimo_old, distanza_finale-distanza_iniziale);
                % se e' migliorata allora aggiorno gli archi 
                if minimo_new ~= minimo_old
                    minimo_old = minimo_new;
                    arco_old1 = [arco{j}{i}(1) arco{j}{i}(2)];
                    arco_old2 = [arco{j}{k}(1) arco{j}{k}(2)];
                    arco_new1 = [arco{j}{i}(1) arco{j}{k}(1)];
                    arco_new2 = [arco{j}{i}(2) arco{j}{k}(2)];            
                end
             end
        end
        % aggiorno la strada con l'arco migliore trovato per ridurre il costo totale 
        begin_flip = find(arco_new1(1) == strada{j})+1;
        end_flip = find(arco_new2(2) == strada{j})-1;
        strada{j}(begin_flip:end_flip) = flip(strada{j}(begin_flip:end_flip));
    end
end

% calcolo il costo finale ottenuto con il metodo iterativo 2 opt
costo_new = zeros(nstrada,1);
for i=1:nstrada
    for j = 1: size(strada{i},2)-1
        costo_new(i) = costo_new(i) + distance(strada{i}(j),strada{i}(j+1));
    end
end
costo_tot_new = sum(costo_new);
