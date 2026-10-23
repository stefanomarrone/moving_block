% ETCS log
% During the search the log is a plain list of board/4 snapshots (cheap to
% build, no atom is created: GNU Prolog has a bounded atom table and atoms
% are never reclaimed). The CSV rendering is done only at the end, on the
% successful trace, by print_log/1.

trackside_ext_debug(Time, Trackside, LogIn, LogOut) :-
	( tpr_tick(Time) ->
		log_boards(Trackside, LogIn, LogOut)
	;	LogOut = LogIn
	).

log_boards([], Log, Log).

log_boards([Board | Boards], LogIn, LogOut) :-
	log_boards(Boards, [Board | LogIn], LogOut).

% CSV output: Id;Time;Msfe;Speed;TStart;TEnd;Status;RStart;REnd;
print_log([]).

print_log([Row | Rows]) :-
	print_row(Row),
	print_log(Rows).

print_row(board(
		train(Id, Speed, Msfe, _Length),
		track_status_area(TStart, TEnd, Status),
		reserved_status_area(RStart, REnd),
		Time)) :-
	format("~w;~w;~w;~w;~w;~w;~w;~w;~w;~n",
		[Id, Time, Msfe, Speed, TStart, TEnd, Status, RStart, REnd]).
