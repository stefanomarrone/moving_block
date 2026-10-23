% Train
% Behaviour of a single train: at every march step the train advances;
% at every TPR tick it reports its position and receives a movement
% authority (MA) that constrains its next speed.
%
% Train term: train(Id, Speed, Msfe, Length)
%   Msfe = max safe front end (position of the head of the train).

init_train(train(Id, Speed, Msfe, Length)) :-
	ilength(Length),
	ispeed(Speed),
	iposition(Id, Msfe).

% Nondeterministic choice of the next candidate speed: this is the search
% space explored by the verifier (accelerate / keep / decelerate).
% Below min_speed only accelerate is available (mandatory ramp-up); keep
% and decelerate never take the speed below min_speed, and accelerate
% never takes it above max_speed (see parameters.pl for the rationale).
new_speed(train(_, Speed, _, _), NewSpeed) :-	% accelerate, capped at max_speed
	delta_speed(Delta),
	max_speed(MaxSpeed),
	NewSpeed is Speed + Delta,
	NewSpeed =< MaxSpeed.

new_speed(train(_, Speed, _, _), Speed) :-	% keep the current speed, only once cruising
	min_speed(MinSpeed),
	Speed >= MinSpeed.

new_speed(train(_, Speed, _, _), NewSpeed) :-	% decelerate, floored at min_speed
	delta_speed(Delta),
	min_speed(MinSpeed),
	NewSpeed is Speed - Delta,
	NewSpeed >= MinSpeed.

% The chosen speed must be compatible with the movement authority,
% otherwise the train brakes down to the safety speed (one solution only).
update_speed(Train, MA, NewSpeed) :-
	tpr_interval(DeltaTime),
	new_speed(Train, NewSpeed),
	NewSpeed * DeltaTime =< MA.

update_speed(Train, MA, SafetySpeed) :-
	tpr_interval(DeltaTime),
	( new_speed(Train, Candidate),
	  Candidate * DeltaTime > MA ->
		safety_speed(SafetySpeed)
	).

% True when the train is still (at least partially) inside the track.
within_track(train(_, _, Msfe, Length)) :-
	track_start(TrackStart),
	track_end(TrackEnd),
	Msfe >= TrackStart,
	Msre is Msfe - Length,
	Msre =< TrackEnd.

update_position(train(_, Speed, Msfe, _), NewMsfe) :-
	march_interval(Delta),
	NewMsfe is Msfe + Speed * Delta.

% One march step of a train. On end of mission the train id is set to 0
% so that the fleet can drop it.
train_step(train(Id, Speed, Msfe, Length), Time, TrainOut, TrackIn, TrackOut) :-
	update_position(train(Id, Speed, Msfe, Length), NewMsfe),
	( within_track(train(Id, Speed, NewMsfe, Length)) ->
		( tpr_tick(Time) ->
			position_report(train(Id, Speed, NewMsfe, Length), Time, TrackIn, TrackOut, MA),
			update_speed(train(Id, Speed, Msfe, Length), MA, NewSpeed)
		;	% between two reports there is no updated MA: keep the speed
			TrackOut = TrackIn,
			NewSpeed = Speed
		),
		TrainOut = train(Id, NewSpeed, NewMsfe, Length)
	;	end_of_mission(train(Id, Speed, NewMsfe, Length), Time, TrackIn, TrackOut),
		TrainOut = train(0, Speed, Msfe, Length)
	).
