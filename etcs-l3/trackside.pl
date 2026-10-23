% Trackside
% The trackside state is a list of board/4 terms, one per reporting train:
%   board(train(Id,Speed,Msfe,Length),
%         track_status_area(TStart,TEnd,Status),
%         reserved_status_area(RStart,REnd),
%         Time)

% Interface
init_trackside([]).

update_trackside(train(Id, Speed, Msfe, Length), Time, TrackIn, TrackOut, MA) :-
	( board_in_trackside(Id, TrackIn) ->
		upd_ts(train(Id, Speed, Msfe, Length), Time, TrackIn, TrackOut, MA)
	;	add_ts(train(Id, Speed, Msfe, Length), Time, TrackIn, TrackOut, MA)
	).

remove_from_trackside(train(Id, _, _, _), _Time, TrackIn, TrackOut) :-
	del_ts(Id, TrackIn, TrackOut).

% A train reports for the first time: its board is appended and the
% reservations of the whole trackside are recomputed.
add_ts(train(Id, Speed, Msfe, Length), Time, OldTrackside, NewTrackside, MA) :-
	update_board(board(train(Id, Speed, Msfe, Length), TrackStatusArea, ReservedStatusArea, _)),
	append(OldTrackside, [board(train(Id, Speed, Msfe, Length), TrackStatusArea, ReservedStatusArea, Time)], TempTrackside),
	update_all_trains(TempTrackside, TempTrackside, NewTrackside),
	get_board(Id, NewTrackside, board(_, _, reserved_status_area(_, ActualREnd), _)),
	MA is ActualREnd - Msfe.

% A known train reports: its board is rebuilt, its reservation is clamped
% against the other trains and the board is re-appended at the end.
upd_ts(train(Id, Speed, Msfe, Length), Time, OldTrackside, NewTrackside, MA) :-
	update_board(board(train(Id, Speed, Msfe, Length), TrackStatusArea, reserved_status_area(RStart, REnd), _)),
	get_closest_train(Id, Msfe, REnd, OldTrackside, ActualREnd),
	del_ts(Id, OldTrackside, TempTrackside),
	append(TempTrackside, [board(train(Id, Speed, Msfe, Length), TrackStatusArea, reserved_status_area(RStart, ActualREnd), Time)], NewTrackside),
	MA is ActualREnd - Msfe.

update_all_trains([], _, []).

update_all_trains(
	[board(train(Id, Speed, Msfe, Length), TrackStatusArea, reserved_status_area(RStart, REnd), Time) | Boards],
	Trackside,
	[board(train(Id, Speed, Msfe, Length), TrackStatusArea, reserved_status_area(RStart, NewREnd), Time) | OutBoards]) :-
	get_closest_train(Id, Msfe, REnd, Trackside, NewREnd),
	update_all_trains(Boards, Trackside, OutBoards).

% Removes the board of Id, preserving the order of the others.
% If Id is not present the trackside is left unchanged.
del_ts(_, [], []).

del_ts(Id, [board(train(OtherId, Speed, Msfe, Length), TrackStatusArea, ReservedStatusArea, Time) | Boards], TracksideOut) :-
	( Id == OtherId ->
		TracksideOut = Boards
	;	TracksideOut = [board(train(OtherId, Speed, Msfe, Length), TrackStatusArea, ReservedStatusArea, Time) | OtherBoards],
		del_ts(Id, Boards, OtherBoards)
	).

% True when a board for Id is already on the trackside.
board_in_trackside(Id, [board(train(OtherId, _, _, _), _, _, _) | Boards]) :-
	( Id == OtherId ->
		true
	;	board_in_trackside(Id, Boards)
	).

% Clamps the requested reserved end of Id against the closest train ahead:
% the reservation cannot go past the rear (TStart) of another train.
%
% Directionality is decided on the far end (OTEnd) of the OCCUPIED area of
% the other train, and two values must NOT be used in its place.
%
% The reserved area (OREnd) must not: within the same report round a
% not-yet-clamped train can carry an inflated OREnd that overshoots Front
% even though that train is physically behind Id, which lets a following
% train be mistaken for a leading one and silently corrupts its reservation.
%
% The rear end (OTStart) must not either, and this is subtler: a board is up
% to one report period old, so a train that braked hard barely moves while
% its follower advances. The follower's current Front can therefore pass the
% RECORDED rear of the leader, which would then be classified as a train
% behind and would stop constraining the reservation -- granting an EoA that
% runs straight through it. Comparing against OTEnd is the conservative
% choice: the other train counts as behind only when even its recorded front
% end has been passed.
%
% The specification constrains the result (REQ-Reserved-5: an area is
% reserved for a single train) but not this mechanism, and states no
% assumption on the age of the data it is decided upon.
get_closest_train(_, _, ReservedEnd, [], ReservedEnd).

get_closest_train(Id, Front, ReservedEnd,
	[board(train(OId, _, _, _), track_status_area(OTStart, OTEnd, _), reserved_status_area(_, _), _) | Boards],
	MinReserved) :-
	( OId == Id ->				% skip the train itself
		get_closest_train(Id, Front, ReservedEnd, Boards, MinReserved)
	; OTEnd < Front ->			% the other train is behind me: even its
						% recorded front end is already passed
		get_closest_train(Id, Front, ReservedEnd, Boards, MinReserved)
	; ReservedEnd =< OTStart ->		% the reservation stops before the other train
		get_closest_train(Id, Front, ReservedEnd, Boards, MinReserved)
	;	% the other train limits the reservation: clamp to its rear end
		get_closest_train(Id, Front, OTStart, Boards, MinReserved)
	).

% Retrieves the board of Id; fails if absent.
get_board(Id, [board(train(OtherId, Speed, Msfe, Length), TrackStatusArea, ReservedStatusArea, Time) | Boards], Board) :-
	( Id == OtherId ->
		Board = board(train(OtherId, Speed, Msfe, Length), TrackStatusArea, ReservedStatusArea, Time)
	;	get_board(Id, Boards, Board)
	).
