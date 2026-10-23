#!/usr/bin/env python3
"""RQ3: cost of the verification as a function of the scenario size."""
import json
from driver import DEFAULTS, evaluate

SPARSE = {"t1": 5, "t2": 12, "t3": 19, "t4": 26}
DENSE = {"t1": 5, "t2": 9, "t3": 13, "t4": 17}
TIMEOUT = 600


REPS = 5


def case(label, over, trains, positions=SPARSE):
    cfg = dict(DEFAULTS)
    cfg.update(over)
    cfg["positions"] = positions
    cfg["max_time"] = 600
    cfg["name"] = label
    r = evaluate(cfg, trains=trains, timeout=TIMEOUT, tag="rq3", reps=REPS)
    r["label"] = label
    h = r["reach_hazard"]
    print("%-28s safe=%6ss | hazard=%-6s %8ss %9s states %6s MB" % (
        label, r["safe_run"]["time"], h["verdict"], h["time"],
        h.get("states", "-"), round(h.get("maxrss_kb", 0) / 1024)), flush=True)
    return r


def main():
    res = []
    for t in (16, 20, 24, 28):
        res.append(case("track=%d, 2 trains" % t, {"track_end": t}, ("t1", "t2")))
    for n in (2, 3, 4):
        res.append(case("dense, %d trains" % n, {"track_end": 20},
                        tuple("t%d" % (i + 1) for i in range(n)), DENSE))
    res.append(case("3 speeds, 2 trains", {"min_speed": 0.25}, ("t1", "t2")))
    json.dump(res, open("rq3_results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
