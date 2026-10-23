% Board
% Builds the trackside view of a train: the occupied track area
% [TStart, TEnd] and the reserved area [RStart, REnd] ahead of it.

update_board(
	board(
		train(_, Speed, Msfe, Length),
		track_status_area(TStart, TEnd, Status),
		reserved_status_area(RStart, REnd),
		_)
	) :-
	TStart is Msfe - Length,
	TEnd = Msfe,
	set_occupied(track_status_area(TStart, TEnd, Status)),
	RStart = Msfe,
	reserved_size(RStart, Speed, REnd).

reserved_size(Start, Speed, End) :-
	tpr_interval(Time),
	safe_margin(Margin),
	reservation_speed_factor(Factor),
	End is Start + Factor * Speed * Time + Margin.
