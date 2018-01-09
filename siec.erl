% siec.erl
-module(siec).
-compile(export_all).
-export([main/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  USER INTERFACE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main() ->
    io:format("Type 1 to start hardcoded example~n"),
    io:format("Type 0 to exit~n"),
    startSimulation(input()).

startSimulation(0) -> io:format("Thanks you, have a good day!~n");
startSimulation(1) ->
    io:format("Clear output file:~n~n"),
    file:write_file("OutputFile",""),
    io:format("Start prepareation:~n~n"),
    I = initProcesses(),
    %S = initProcesses("InputFile"), %TODO data from file reading
    %I = createProcesses(S),
    start(I);
startSimulation(_) ->
    io:format("Please follow instruction...~n"),
    main().

input()->
    try io:fread("==simulation==>","~d") of
        {ok, [N]} -> N
    catch
        _:_ -> 5 %TODO why doeas not work for string input?
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    API    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

initProcesses() ->
    {prepareElectricalNodeProcess(),
    [{1,preparePowerhouseProcess()}],
    [prepareDistributiveProcess()]}.%Also preapare PidsList

initProcesses(Filename) ->
    {ok, X} = file:consult(Filename),X. 
    %TODO try catch for exeptions

testread() ->
   file:consult("InputFile").

%start(data,PidList) -> TODO change input structure
%start({ElectricalNode,Powerhouses,Distributives}) ->
start({PID1,[{1,PID2}],[PID3]}) ->
    io:fwrite("RUN!~n"),
    PID1 ! {start,[PID2],[PID3]},
    PID2 ! start,
    PID3 ! start,
    %startThemAll([PID1,PID2,PID3]) TODO need to thing about it
    stop(input,[PID1,PID2,PID3]).
    %Otrzymuje na wejsciu krotke, gdzie jest mapa elektrowni, mapa rozdzielni i lista wezlow, do kazdego procesu wysyla wiadomosc, ze nadszedl czas, aby ten proces przelaczyl sie w tryb symulacji

stop(0,Pids) ->
    io:format("It is time to stop!:~n~n"),
    stopThemAll(Pids),
    main();
stop(_,Pids) ->
    io:format("Type s to stop!~n"),
    stop(input(),Pids).

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

stopThemAll([P]) ->
    P ! stop,
    dupa;
stopThemAll([H|T]) ->
    H ! stop,
    stopThemAll(T).

startThemAll([P]) ->
    P ! start,
    dupa;
startThemAll([H|T]) ->
    H ! start,
    stopThemAll(T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

runElectricalNode(P,D,[DistrPID]) ->
    DistrPID ! {frEN,self()},
    io:fwrite("N:Asking another dist... ~n"),
    receive
        stop -> io:fwrite("N: Stopped ~n");
        {frDI,Need} -> randomPowerhouse(P) ! {toPH,Need},
        io:fwrite("N:Powerhouse choosen... ~n"),
        timer:sleep(2000),
        runElectricalNode(P,D,D)
    end;
runElectricalNode(P,D,[DistrPID|T]) ->
    DistrPID ! {frEN,self()},
    io:fwrite("N:Asking another dist... ~n"),
    receive
        stop -> io:fwrite("N: Stopped ~n");
        {frDI,Need} -> randomPowerhouse(P) ! {toPH,Need},
        io:fwrite("N:Powerhouse choosen... ~n")
    end,
    runElectricalNode(P,D,T).

runPowerhouse(Id,Energy,InitialPower) ->
    receive
    stop -> io:fwrite("N: Stopped ~n");
    {toPH,Need} -> io:fwrite("P:Use my energy!~n"),
            runPowerhouse(Id,Energy-Need,InitialPower)
    after
    1000 -> %TODO Replace time based synchronization with broadcast to them
        saveEnergyBalance(Id,Energy),
        io:fwrite("P:Saved Balance!~n"),
        runPowerhouse(Id,InitialPower,InitialPower)
    end.

runDistributive(Need,InitialNeed) ->
    receive
    stop -> io:fwrite("N: Stopped ~n");
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
    Data = integer_to_list(FilenameId) ++ " used " ++ integer_to_list(Energy),
    LineSep = io_lib:nl(),
    file:write_file("OutputFile",Data,[append]),
    file:write_file("OutputFile",LineSep,[append]).

