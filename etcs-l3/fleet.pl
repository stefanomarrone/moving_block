% Fleet
% Moves the whole fleet step by step until every train has completed its
% mission (nominal), or a hazard/accident state is reached.

init_fleet([], []).

init_fleet([Id | Ids], [train(Id, Speed, Msfe, Length) | Fleet]) :-
	init_train(train(Id, Speed, Msfe, Length)),
	init_fleet(Ids, Fleet).

fleet_move(Fleet, NoAccident, NoHazard, LogIn, LogOut) :-
	init_trackside(TrackIn),
	time_start(InitTime),
	fleet_move(Fleet, InitTime, TrackIn, _TrackOut, NoAccident, NoHazard, LogIn, LogOut).

fleet_move([], _Time, Track, Track, true, true, Log, Log) :-
	count(runs).

fleet_move([Train | Fleet], Time, TrackIn, TrackOut, NoAccident, NoHazard, LogIn, LogOut) :-
	count(states),
	fleet_step(Time, [Train | Fleet], TempFleet, TrackIn, TempTrack),
	trackside_ext_debug(Time, TempTrack, LogIn, TempLog),
	trackside_ext_safety(Time, TempTrack, StepNoAccident, StepNoHazard),
	( StepNoAccident == false ->
		count(cuts),
		NoAccident = false,
		NoHazard = false,
		TrackOut = TempTrack,
		LogOut = TempLog
	; StepNoHazard == false ->
		count(cuts),
		NoAccident = true,
		NoHazard = false,
		TrackOut = TempTrack,
		LogOut = TempLog
	;	march_interval(DeltaTime),
		NewTime is DeltaTime + Time,
		max_time(MaxTime),
		% Bounded verification: an evolution that does not complete within the
		% horizon is not explored further. It is counted, so that the share of
		% truncated evolutions can be reported together with the verdict.
		( NewTime > MaxTime ->
			count(horizon),
			fail
		;	fleet_move(TempFleet, NewTime, TempTrack, TrackOut, NoAccident, NoHazard, TempLog, LogOut)
		)
	).

% One step of every train; trains whose mission ended (id reset to 0)
% are dropped from the fleet.
fleet_step(_, [], [], Track, Track).

fleet_step(Time, [Train | Fleet], FleetOut, TrackIn, TrackOut) :-
	train_step(Train, Time, train(NewId, NewSpeed, NewMsfe, Length), TrackIn, TempTrack),
	( NewId == 0 ->
		fleet_step(Time, Fleet, FleetOut, TempTrack, TrackOut)
	;	FleetOut = [train(NewId, NewSpeed, NewMsfe, Length) | RestFleet],
		fleet_step(Time, Fleet, RestFleet, TempTrack, TrackOut)
	).
