% Requirements
% Safety assertions checked on the trackside state at every TPR tick:
%   accident: the occupied track areas of two distinct trains overlap;
%   hazard:   the reserved areas of two distinct trains overlap.

trackside_ext_safety(Time, Trackside, NoAccident, NoHazard) :-
	( tpr_tick(Time) ->
		trackside_safety(Trackside, NoAccident, NoHazard)
	;	NoAccident = true,
		NoHazard = true
	).

trackside_safety(Trackside, NoAccident, NoHazard) :-
	( boards_pair(Trackside, B1, B2),
	  boards_collide(B1, B2) ->
		NoAccident = false,
		NoHazard = false
	; boards_pair(Trackside, B1, B2),
	  reservations_conflict(B1, B2) ->
		NoAccident = true,
		NoHazard = false
	;	NoAccident = true,
		NoHazard = true
	).

boards_pair(Trackside, B1, B2) :-
	member(B1, Trackside),
	member(B2, Trackside).

% The occupied areas [TStart, TEnd] of two distinct trains overlap.
boards_collide(
	board(train(IId, _, _, _), track_status_area(ITStart, ITEnd, _), _, _),
	board(train(OId, _, _, _), track_status_area(OTStart, OTEnd, _), _, _)) :-
	IId \== OId,
	ITEnd >= OTStart,
	OTEnd >= ITStart.

% The reserved areas [TEnd, REnd] of two distinct trains overlap.
reservations_conflict(
	board(train(IId, _, _, _), track_status_area(_, ITEnd, _), reserved_status_area(_, IREnd), _),
	board(train(OId, _, _, _), track_status_area(_, OTEnd, _), reserved_status_area(_, OREnd), _)) :-
	IId \== OId,
	IREnd >= OTEnd,
	OREnd >= ITEnd.
