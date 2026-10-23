% Euroradio messages
% Radio exchanges between a train and the trackside: thin wrappers over
% the trackside update predicates, kept separate to name the protocol
% step each one represents.

% Train reports its position at a TPR tick and gets back a movement
% authority (MA).
position_report(train(Id,Speed,Msfe,Length),Time,TrackIn,TrackOut,MA) :-
	update_trackside(train(Id,Speed,Msfe,Length),Time,TrackIn,TrackOut,MA).

% Train leaves the track: its board is dropped from the trackside.
end_of_mission(train(Id,Speed,Msfe,Length),Time,TrackIn,TrackOut) :-
	remove_from_trackside(train(Id,Speed,Msfe,Length),Time,TrackIn,TrackOut).

