% System entry point (GNU Prolog)
% Load the whole knowledge base: consult this file only.
% Example:
%   gprolog --consult-file system.pl --query-goal "nominal([t1,t2],L), print_log(L), halt"
%
% Data dictionary
%   train(Id, Speed, Msfe, Length)
%     Id     : train identifier (0 = mission ended)
%     Msfe   : max safe front end, position of the head of the train
%   board(Train, TrackStatusArea, ReservedStatusArea, Time)
%     trackside view of a train at its last position report
%   track_status_area(TStart, TEnd, Status)
%     track area occupied by the train ([Msfe - Length, Msfe])
%   reserved_status_area(RStart, REnd)
%     track area reserved ahead of the train ([Msfe, Msfe + reservation])

:- include(parameters).
:- include(trackarea).
:- include(board).
:- include(trackside).
:- include(euroradio).
:- include(train).
:- include(safety).
:- include(etcslog).
:- include(fleet).

% Search instrumentation: GNU Prolog global variables are not undone on
% backtracking, so they count what the search actually explores.
count(Key) :- g_read(Key, V), V1 is V + 1, g_assign(Key, V1).

reset_counters :-
	g_assign(states, 0), g_assign(runs, 0),
	g_assign(cuts, 0), g_assign(horizon, 0).

report_counters :-
	g_read(states, S), g_read(runs, R), g_read(cuts, C), g_read(horizon, H),
	format("states=~w;runs=~w;cuts=~w;horizon=~w;~n", [S, R, C, H]).

% Log rows are accumulated in reverse order during the search.
run(Trains, NoAccident, NoHazard, Log) :-
	init_fleet(Trains, Fleet),
	fleet_move(Fleet, NoAccident, NoHazard, [], ReversedLog),
	reverse(ReversedLog, Log).

% safe_run/2 is existential: it returns a witness of a safe mission.
safe_run(Trains, Log) :-
	run(Trains, true, true, Log).

% reach_hazard/2 and reach_accident/2 are reachability queries: they succeed
% iff an unsafe state is reachable, and return the trace leading to it.
reach_hazard(Trains, Log) :-
	run(Trains, true, false, Log).

reach_accident(Trains, Log) :-
	run(Trains, false, false, Log).
