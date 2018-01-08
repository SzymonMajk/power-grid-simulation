% siec.erl
-module(siec).
-compile(export_all).
%-export([init/0,init/1,start/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA FORMATS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(timestamp, 1000).
%powerhouse -> {id,power}
%distributive -> {id,type}
%electricalNode -> {id,[powerhouse],[distributive]}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    API    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

init() ->
    {prepareElectricalNodeProcess(),
    [{1,preparePowerhouseProcess()}],
    [prepareDistributiveProcess()]}.

init(Filename) ->
    not_implemented. %TODO
    %Czyta z pliku w formacie np. linijka po linijce elektrownie, rozdzielnie
    %i wezly sieci, tworzy z nich odpowiednie mapy, które zwraca

%Funkcje init mają zwrócić krotkę, w której będzie mapa z elektrowniami, mapa z rozdzielniami i lista wezlow

%start(data) ->
%start({ElectricalNode,Powerhouses,Distributives}) ->
start({PID1,[{1,PID2}],[PID3]}) ->
    io:fwrite("RUN!~n"),
    PID1 ! {start,[PID2],[PID3]},
    PID2 ! start,
    PID3 ! start,
    ok.
    %Otrzymuje na wejsciu krotke, gdzie jest mapa elektrowni, mapa rozdzielni i lista wezlow, do kazdego procesu wysyla wiadomosc, ze nadszedl czas, aby ten proces przelaczyl sie w tryb symulacji

%Optional add stop(data)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prepareElectricalNodeProcess() ->
    spawn(siec,startElectricalNode,[]).

preparePowerhouseProcess() ->
    spawn(siec,startPowerhouse,[]).

prepareDistributiveProcess() ->
    spawn(siec,startDistributive,[]).

startElectricalNode() ->
    receive
        {start,Plist,Dlist}-> io:fwrite("Electrical Node started~n"),
                runElectricalNode(Plist,Dlist,Dlist)
    end.

startPowerhouse() ->
    receive
        start -> io:fwrite("Power House started~n"),
                runPowerhouse(1,100,100)
    end.

startDistributive() ->
    receive
        start -> io:fwrite("Distributive started~n"),
                runDistributive(5,5)
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

runElectricalNode(P,D,[DistrPID]) ->
    DistrPID ! {frEN,self()},
    io:fwrite("N:Asking another dist... ~n"),
    receive
        {frDI,Need} -> randomPowerhouse(P) ! {toPH,Need},
        io:fwrite("N:Powerhouse choosen... ~n"),
        timer:sleep(2000),
        runElectricalNode(P,D,D)
    end;
runElectricalNode(P,D,[DistrPID,T]) ->
    DistrPID ! {frEN,self()},
    io:fwrite("N:Asking another dist... ~n"),
    receive
        {frDI,Need} -> randomPowerhouse(P) ! {toPH,Need},
        io:fwrite("N:Powerhouse choosen... ~n")
    end,
    runElectricalNode(P,D,T).

runPowerhouse(Id,Energy,InitialPower) ->
    receive
    {toPH,Need} -> io:fwrite("P:Use my energy!~n"),
            runPowerhouse(Id,Energy-Need,InitialPower)
    after
    1000 -> 
        saveEnergyBalance(Id,Energy),
        io:fwrite("P:Saved Balance!~n"),
        runPowerhouse(Id,InitialPower,InitialPower)
    end.

runDistributive(Need,InitialNeed) ->
    receive
    {frEN,ENPID} -> 
        ENPID ! {frDI,Need},
        runDistributive(0,InitialNeed),
        io:fwrite("D:Need sent.~n")
    after
    1000 -> io:fwrite("D:Need more energy!~n"),
        runDistributive(InitialNeed,InitialNeed)
    end.

randomPowerhouse([PID|_]) -> 
    PID;
randomPowerhouse(powerhouses) ->
    not_implemented. %TODO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STATISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

saveEnergyBalance(FilenameId,Energy) ->
    not_implemented. %TODO

