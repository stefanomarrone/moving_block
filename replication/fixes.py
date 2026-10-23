"""The two corrections that the verification campaign motivated.

D1: the direction test of the reservation clamping is performed on the rear end
    of a board that may be one report old, so a train that is physically ahead
    can be mistaken for one that is behind.
D2: the admissibility of a candidate speed is checked over one march interval,
    while the speed is only revised at the next position report, i.e. after a
    whole TPR period. A train can therefore overrun its movement authority.
"""
import os


def _rewrite(path, pairs):
    src = open(path).read()
    for old, new in pairs:
        if old not in src:
            raise SystemExit("pattern not found in %s:\n%s" % (path, old[:120]))
        src = src.replace(old, new)
    tmp = src
    open(path, "w").write(tmp)


def fix_d1(workdir):
    _rewrite(os.path.join(workdir, "trackside.pl"), [
        ("	[board(train(OId, _, _, _), track_status_area(OTStart, _, _), reserved_status_area(_, _), _) | Boards],",
         "	[board(train(OId, _, _, _), track_status_area(OTStart, OTEnd, _), reserved_status_area(_, _), _) | Boards],"),
        ("	; OTStart < Front ->			% the other train is behind (or overlapping) me:\n"
         "						% it can never constrain my reservation",
         "	; OTEnd < Front ->			% the other train is behind me: even its\n"
         "						% recorded front end is already passed"),
    ])


def fix_d2(workdir):
    _rewrite(os.path.join(workdir, "train.pl"), [
        ("update_speed(Train, MA, NewSpeed) :-\n	march_interval(DeltaTime),",
         "update_speed(Train, MA, NewSpeed) :-\n	tpr_interval(DeltaTime),"),
        ("update_speed(Train, MA, SafetySpeed) :-\n	march_interval(DeltaTime),",
         "update_speed(Train, MA, SafetySpeed) :-\n	tpr_interval(DeltaTime),"),
    ])


def fixed(workdir):
    """The corrected baseline used by the final campaign."""
    fix_d1(workdir)
    fix_d2(workdir)
