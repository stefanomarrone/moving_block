#!/usr/bin/env python3
"""RQ2: inject design faults into the corrected trackside and re-run the queries.

Every fault is injected on top of the corrected baseline (see fixes.py) and
verified in two configurations: the reference one and a dense fleet.
"""
import json
import os
import sys

from driver import DEFAULTS, evaluate


def patch(path, pairs):
    def _apply(workdir):
        full = os.path.join(workdir, path)
        src = open(full).read()
        for old, new in pairs:
            if old not in src:
                raise SystemExit("pattern not found in %s:\n%s" % (path, old[:160]))
            src = src.replace(old, new)
        open(full, "w").write(src)
    return _apply


# F1: the reservation is never clamped against the train ahead.
F1 = patch("trackside.pl", [
    ("get_closest_train(_, _, ReservedEnd, [], ReservedEnd).",
     "get_closest_train(_, _, ReservedEnd, _, ReservedEnd).\n"
     "unused_get_closest_train(_, _, ReservedEnd, [], ReservedEnd).")])

# F2: the reserved extent ignores the speed term of the reservation formula.
F2 = patch("board.pl", [
    ("\tEnd is Start + Factor * Speed * Time + Margin.",
     "\tEnd is Start + Margin.")])

# F3: the movement authority is checked over a single march interval instead of
# the whole interval until the next position report (defect D2, re-injected).
F3 = patch("train.pl", [
    ("update_speed(Train, MA, NewSpeed) :-\n\ttpr_interval(DeltaTime),",
     "update_speed(Train, MA, NewSpeed) :-\n\tmarch_interval(DeltaTime),"),
    ("update_speed(Train, MA, SafetySpeed) :-\n\ttpr_interval(DeltaTime),",
     "update_speed(Train, MA, SafetySpeed) :-\n\tmarch_interval(DeltaTime),")])

# F4: the board of a train is not removed at end of mission.
F4 = patch("trackside.pl", [
    ("remove_from_trackside(train(Id, _, _, _), _Time, TrackIn, TrackOut) :-\n"
     "\tdel_ts(Id, TrackIn, TrackOut).",
     "remove_from_trackside(train(_, _, _, _), _Time, TrackIn, TrackIn).")])

# F5: the train ahead is identified through the reserved area instead of the
# occupied one (defect D1, re-injected).
F5 = patch("trackside.pl", [
    ("\t[board(train(OId, _, _, _), track_status_area(OTStart, OTEnd, _), reserved_status_area(_, _), _) | Boards],",
     "\t[board(train(OId, _, _, _), track_status_area(OTStart, OTEnd, _), reserved_status_area(_, OREnd), _) | Boards],"),
    ("\t; OTEnd < Front ->", "\t; OREnd < Front ->")])

# F6: the reservation is clamped to the front of the train ahead instead of its
# rear, i.e. an off-by-one on the area boundary.
F6 = patch("trackside.pl", [
    ("\t;\t% the other train limits the reservation: clamp to its rear end\n"
     "\t\tget_closest_train(Id, Front, OTStart, Boards, MinReserved)",
     "\t;\t% the other train limits the reservation: clamp to its rear end\n"
     "\t\tget_closest_train(Id, Front, OTEnd, Boards, MinReserved)")])

FAULTS = [
    ("F1", "reservation never clamped against the train ahead", F1),
    ("F2", "reserved extent ignores the speed term", F2),
    ("F3", "MA checked over one march step, not the report period", F3),
    ("F4", "board not removed at end of mission", F4),
    ("F5", "train ahead identified through the reserved area", F5),
    ("F6", "reservation clamped to the front of the train ahead", F6),
]

SCENARIOS = [
    ("reference", {}, ("t1", "t2")),
    ("dense", {"positions": {"t1": 5, "t2": 9, "t3": 13, "t4": 17},
               "max_time": 600}, ("t1", "t2", "t3", "t4")),
]

REPS = 5

QUERIES = ("safe_run", "reach_hazard", "reach_accident")


def main():
    timeout = int(sys.argv[1]) if len(sys.argv) > 1 else 300
    results = []
    for fid, desc, mutate in FAULTS:
        row = {"fault": fid, "description": desc}
        for sname, over, trains in SCENARIOS:
            cfg = dict(DEFAULTS)
            cfg.update(over)
            cfg["name"] = "%s/%s" % (fid, sname)
            row[sname] = evaluate(cfg, trains=trains, timeout=timeout,
                                  mutate=mutate, tag="rq2", reps=REPS)
        results.append(row)
        summary = " | ".join(
            "%s: %s" % (sname, "/".join(row[sname][q]["verdict"] for q in QUERIES))
            for sname, _, _ in SCENARIOS)
        print("%s %-52s %s" % (fid, desc, summary), flush=True)
    json.dump(results, open("rq2_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
