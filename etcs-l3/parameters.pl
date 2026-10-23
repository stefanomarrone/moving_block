% General parameters: reference configuration of the EDCC 2027 paper.
%
% Distances are expressed in track units, speeds in track units per time unit;
% one train length is the unit of distance.

delta_speed(0.25).               % speed variation per position report
track_start(0).                  % first coordinate of the track
track_end(20).                   % last coordinate of the track
ispeed(0.5).                     % initial speed of every train
min_speed(0.5).                  % cruise speed floor
max_speed(0.75).                 % top speed a train can accelerate to
ilength(1).                      % length of every train
time_start(0).                   % initial simulation time
safe_margin(5).                  % fixed margin added to every reservation
tpr_interval(4).                 % period of the Train Position Report (TPR)
safety_speed(0.0001).            % speed enforced when the movement authority is insufficient
march_interval(2).               % duration of one simulation step
reservation_speed_factor(1.2).   % speed weight in the reservation size formula
max_time(200).                   % horizon of the bounded verification

% Below min_speed a train may only accelerate: the ramp-up phase has a
% branching factor of one. It is the width of the [min_speed, max_speed] band
% that drives the cost of the exhaustive search, because every report inside
% the band offers three alternatives. The values above are chosen so that the
% reachable speeds (0.5 and 0.75) are exact in binary floating point.
%
% max_time bounds the search: a train whose movement authority collapses falls
% back to safety_speed and would otherwise creep along the track forever.

% Initial position (max safe front end) of each train.
iposition(t1, 5).
iposition(t2, 12).
iposition(t3, 19).
iposition(t4, 70).

% True when Time falls on a Train Position Report tick.
tpr_tick(Time) :-
	tpr_interval(TPR),
	Time mod TPR =:= 0.
