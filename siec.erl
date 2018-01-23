% siec.erl authors Paweł Dzień and Szymon Majkut
-module(siec).
-compile(export_all).
-export([main/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  USER INTERFACE  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main() ->
    io:format("Type 1 to start~n"),
    io:format("Type 0 to exit~n"),
    startSimulation(input()).

startSimulation(0) -> io:format("Thanks, have a good day!~n");
startSimulation(1) ->
    io:format("Clear output file:~n~n"),
    file:write_file("OutputFile",""),
    io:format("Start prepareation:~n~n"),
    S = initStructure("InputFile"),
    I = createElectricalNodesProcesses(S),
    PStop = getPidListEN(I),
    PStart = getPidListENToStart(I),
    start(PStart,PStop);
startSimulation(_) ->
    io:format("Please follow instruction...~n"),
    main().
startSimulation(_,_) ->
    io:format("Please follow instruction...~n"),
    main().

input()->
    try io:fread("==sim==>","~d") of
        {ok, [N]} -> N
    catch
        _:_ -> 5 %TODO why doeas not catch string input?
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    API    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



start(StartPidList,StopPidList) ->
    io:fwrite("RUN!~n"),
    startThemAll(StartPidList),
    stop(input,StopPidList).

stop(0,Pids) ->
    io:format("It is time to stop!:~n~n"),
    stopThemAll(Pids),
    main();
stop(_,Pids) ->
    io:format("Type 0 to stop!~n"),
    stop(input(),Pids).
stop(_,_,Pids) ->
    io:format("Type 0 to stop!~n"),
    stop(input(),Pids).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

initStructure(Filename) ->
    {ok, X} = file:consult(Filename),X.
    %TODO try catch for exeptions

createElectricalNodesProcesses([{Id,P,D}]) ->
    [{Id,createPowerhouseProcesses(P),
    createDistributiveProcesses(D),
    prepareElectricalNodeProcess()}];
createElectricalNodesProcesses([{Id,P,D}|T]) ->
    [{Id,createPowerhouseProcesses(P),
    createDistributiveProcesses(D),
    prepareElectricalNodeProcess()}|
        createElectricalNodesProcesses(T)].

createPowerhouseProcesses([{Id,Power}]) ->
    [{Id,Power,preparePowerhouseProcess(Id,Power)}];
createPowerhouseProcesses([{Id,Power}|T]) ->
    [{Id,Power,preparePowerhouseProcess(Id,Power)}|
        createPowerhouseProcesses(T)].

createDistributiveProcesses([{Id,Type}]) ->
    [{Id,Type,prepareDistributiveProcess(Type)}];
createDistributiveProcesses([{Id,Type}|T]) ->
    [{Id,Type,prepareDistributiveProcess(Type)}|
    createDistributiveProcesses(T)].

getPidListEN([{_,P,D,Pidek}]) ->
    PowerPids = getPidListP(P),
    DistrPids = getPidListD(D),
    PowerPids ++ DistrPids ++ [Pidek];
getPidListEN([{_,P,D,Pidek}|T]) ->
    PowerPids = getPidListP(P),
    DistrPids = getPidListD(D),
    OtherPids = getPidListEN(T),
    PowerPids ++ DistrPids ++ OtherPids ++ [Pidek].

getPidListENToStart([{_,P,D,Pidek}]) ->
    PowerPids = getPidListP(P),
    DistrPids = getPidListD(D),
    [{Pidek,PowerPids,DistrPids}];
getPidListENToStart([{_,P,D,Pidek}|T]) ->
    PowerPids = getPidListP(P),
    DistrPids = getPidListD(D),
    [{Pidek,PowerPids,DistrPids}|getPidListENToStart(T)].

getPidListP([{_,_,Pidek}]) ->
    [Pidek];
getPidListP([{_,_,Pidek}|T]) ->
    [Pidek|getPidListP(T)].

getPidListD([{_,_,Pidek}]) ->
    [Pidek];
getPidListD([{_,_,Pidek}|T]) ->
    [Pidek|getPidListD(T)].

prepareElectricalNodeProcess() ->
    spawn(siec,startElectricalNode,[]).

preparePowerhouseProcess(Id,Power) ->
    spawn(siec,startPowerhouse,[Id,Power]).

prepareDistributiveProcess(Type) ->
    spawn(siec,startDistributive,[Type]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIMULATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

startElectricalNode() ->
    receive
        {start,Plist,Dlist}-> io:fwrite("Electrical Node started~n"),
                runElectricalNode(Plist,Dlist,Dlist)
    end.

startPowerhouse(Id,Power) ->
    receive
        start -> io:fwrite("Power House started~n"),
                runPowerhouse(Id,Power,Power,[]) 
    end.

startDistributive(normal) ->
    receive
        start -> io:fwrite("Distributive started~n"),
                runDistributive(12,12)
    end;
startDistributive(reverse) ->
    receive
        start -> io:fwrite("Distributive started~n"),
                runDistributive(-2,-2)
    end;
startDistributive(random) ->
    R = rand:uniform(20),
    receive
        start -> io:fwrite("Distributive started~n"),
                runDistributive(R,R)
    end.

stopThemAll([P]) ->
    P ! stop;
stopThemAll([H|T]) ->
    H ! stop,
    stopThemAll(T).

startThemAll([{Pidek,P,D}]) ->
    startPow(P),
    startDis(D),
    Pidek ! {start,P,D};
startThemAll([{Pidek,P,D}|T]) ->
    startPow(P),
    startDis(D),
    Pidek ! {start,P,D},
    startThemAll(T).

startPow([P]) ->
    P ! start;
startPow([P|T]) ->
    P ! start,
    startPow(T).

startDis([P]) ->
    P ! start;
startDis([P|T]) ->
    P ! start,
    startDis(T).

runElectricalNode(P,D,[DistrPID]) ->
    DistrPID ! {toDist,self()},
    io:fwrite("N:Asking another dist... ~n"),
    receive
        stop -> io:fwrite("N: Stopped ~n");
		{fromDist,DISTPID,noNeed} -> timer:sleep(500),
			runElectricalNode(P,D,[DistrPID]++DISTPID);
        {fromDist,DISTPID,Need} -> randomPowerhouse(P) ! {toPH,DISTPID,Need},
        	io:fwrite("N:Powerhouse choosen... ~n"),
			lists:foreach(fun(Pid) -> Pid ! allDist end, P),
        	timer:sleep(500),
        	runElectricalNode(P,D,D)
    end;
runElectricalNode(P,D,[DistrPID|T]) ->
    DistrPID ! {toDist,self()},
    io:fwrite("N:Asking another dist... ~n"),
    receive
        stop -> io:fwrite("N: Stopped ~n");
		{fromDist,DISTPID,noNeed} -> runElectricalNode(P,D,[DistrPID|T] ++ DISTPID);
        {fromDist,DISTPID,Need} -> randomPowerhouse(P) ! {toPH,DISTPID,Need},
        	io:fwrite("N:Powerhouse choosen... ~n")
    end,
    runElectricalNode(P,D,T).

runPowerhouse(Id,Energy,InitialPower,AlreadyServed) ->
    receive
    stop -> io:fwrite("N: Stopped ~n");
    {toPH,DISTPID,Need} -> io:fwrite("P:Use my energy!~n"),
            runPowerhouse(Id,Energy-Need,InitialPower,[DISTPID|AlreadyServed]);
    allDist ->
        saveEnergyBalance(Id,Energy),
        io:fwrite("P:Saved Balance!~n"),
	lists:foreach(fun(Pid) -> Pid ! served end, AlreadyServed),
        runPowerhouse(Id,InitialPower,InitialPower,[])
    end.

runDistributive(Need,InitialNeed) ->
    receive
    stop -> io:fwrite("N: Stopped ~n");
    {toDist,ENPID} when Need /= 0 -> 
        ENPID ! {fromDist,self(),Need},
        runDistributive(0,InitialNeed);
	{toDist,ENPID} when Need == 0 ->
		ENPID ! {fromDist,self(),noNeed},
		runDistributive(Need,InitialNeed);
    served -> io:fwrite("D:Need more energy!~n"),
        runDistributive(InitialNeed,InitialNeed)
    end.

randomPowerhouse([PID|_]) -> 
    PID;
randomPowerhouse(powerhouses) ->
    not_implemented. %TODO

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STATISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

saveEnergyBalance(FilenameId,Energy) ->
    Data = integer_to_list(FilenameId) ++ " used " 
		++ integer_to_list(Energy) ++ " [kW/s]",
    LineSep = io_lib:nl(),
    file:write_file("OutputFile",Data,[append]),
    file:write_file("OutputFile",LineSep,[append]).

