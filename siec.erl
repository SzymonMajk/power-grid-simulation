%  siec.erl
-module(siec).
-export([init/0,init/1,start/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA FORMATS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(timestamp, 1000).
%powerhouse -> {id,power}
%distributive -> {id,type}
%electricalNode -> {id,[powerhouse],[distributive]}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    API    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init() ->
    not_implemented.
    %Zahardkodowana wersja

init(filename) ->
    not_implemented.
    %Czyta z pliku w formacie np. linijka po linijce elektrownie, rozdzielnie
    %i wezly sieci, tworzy z nich odpowiednie mapy, które zwraca

%Funkcje init mają zwrócić krotkę, w której będzie mapa z elektrowniami, mapa z rozdzielniami i lista wezlow

start(data) ->
    not_implemented.
    %Otrzymuje na wejsciu krotke, gdzie jest mapa elektrowni, mapa rozdzielni i lista wezlow, do kazdego procesu wysyla wiadomosc, ze nadszedl czas, aby ten proces przelaczyl sie w tryb symulacji

%Optional add stop(data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prepareProcesses() ->
    not_implemented.

startPowerhouse() ->
    not_implemented.

startDistributive() ->
    not_implemented.

startElectricalNode() ->
    not_implemented.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

runPowerhouse(Energy,initialPower) ->
    receive
    Need -> runPowerhouse(energyNeed,initialPower)
    after
    timestamp -> 
        saveEnergyBalance(enerhyNeed,self()),
        runPowerhouse(initialPower,initialPower)
    end.

runDistributive(Need,initialNeed) ->
    receive
    nodePID -> 
        nodePID ! Need,
        runDistributive(0,initialNeed)
    after
    timestamp -> runDistributive(initialNeed,initialNeed)
    end.

runElectricalNode(powerhouses,distributives,[]) ->
    runElectricalNode(powerhouse,distributives,distributives);
runElectricalNode(powerhouses,distributives,[H,T]) ->
    getDitributivePID(H) ! self(),
    receive
        Need -> randomPowerhouse(powerhouses) ! Need
    end,
    runElectricalNode(powerhouses,distributives,T).
    


randomPowerhouse([{_,PID},T]) -> 
    PID;
randomPowerhouse(powerhouses) ->
    not_implemented. %TODO random

getDitributivePID({_,PID}) ->
    PID.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STATISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

saveEnergyBalance(Energy,filename) ->
    not_implemented.






