%  siec.erl
-module(siec).
-compile(export_all).
%-export([init/0,init/1,start/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA FORMATS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(timestamp, 1000).
%powerhouse -> {id,power}
%distributive -> {id,type}
%electricalNode -> {id,[powerhouse],[distributive]}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    API    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init() ->
    {prepareElectricalNodeProcess(),
    [{1,preparePowerhouseProcess()}],
    [prepareDistributiveProcess()]}.
    %Zahardkodowana wersja
    %TODO 1 przypadek prosty

init(filename) ->
    not_implemented.
    %Czyta z pliku w formacie np. linijka po linijce elektrownie, rozdzielnie
    %i wezly sieci, tworzy z nich odpowiednie mapy, które zwraca

%Funkcje init mają zwrócić krotkę, w której będzie mapa z elektrowniami, mapa z rozdzielniami i lista wezlow

%start(data) ->
%start({ElectricalNode,Powerhouses,Distributives}) ->
start({PID1,[{1,PID2}],[PID3]}) ->
    PID1,
    PID2 ! startPowerhouse.
    %Otrzymuje na wejsciu krotke, gdzie jest mapa elektrowni, mapa rozdzielni i lista wezlow, do kazdego procesu wysyla wiadomosc, ze nadszedl czas, aby ten proces przelaczyl sie w tryb symulacji

%Optional add stop(data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

preparePowerhouseProcess() ->
    spawn(siec,startPowerhouse,[]).

prepareDistributiveProcess() ->
    not_implemented.

prepareElectricalNodeProcess() ->
    not_implemented.

startPowerhouse() ->
    receive
        startPowerhouse -> io:fwrite("ok~n")
    end.

startDistributive() ->
    not_implemented.

startElectricalNode() ->
    not_implemented.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

runPowerhouse(Id,Energy,InitialPower) ->
    receive
    Need -> runPowerhouse(Id,Energy-Need,InitialPower)
    after
    timestamp -> 
        saveEnergyBalance(Id,Energy),
        runPowerhouse(Id,InitialPower,InitialPower)
    end.

runDistributive(Need,InitialNeed) ->
    receive
    nodePID -> 
        nodePID ! Need,
        runDistributive(0,InitialNeed)
    after
    timestamp -> runDistributive(InitialNeed,InitialNeed)
    end.

%powerhouses and distr are litst of {id,PID} or lists of PIDS
runElectricalNode(Powerhouses,Distributives,[]) ->
    runElectricalNode(Powerhouses,Distributives,Distributives);
runElectricalNode(Powerhouses,Distributives,[H,T]) ->
    getDitributivePID(H) ! self(),
    receive
        Need -> randomPowerhouse(Powerhouses) ! Need
    end,
    runElectricalNode(Powerhouses,Distributives,T).
    


randomPowerhouse([{_,PID},_]) -> 
    PID;
randomPowerhouse(powerhouses) ->
    not_implemented. %TODO random

getDitributivePID({_,PID}) ->
    PID.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STATISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

saveEnergyBalance(FilenameId,Energy) ->
    not_implemented.






