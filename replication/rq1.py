#!/usr/bin/env python3
"""RQ1: run the three queries over a grid of configurations."""
import json
import sys

from driver import DEFAULTS, evaluate

REF = dict(DEFAULTS)

GRID = [
    # name, overrides, trains
    ("reference, 2 trains", {}, ("t1", "t2")),
    ("short headway", {"positions": {"t1": 5, "t2": 9, "t3": 19, "t4": 70}}, ("t1", "t2")),
    ("long TPR period", {"tpr_interval": 8}, ("t1", "t2")),
    ("small safety margin", {"safe_margin": 1}, ("t1", "t2")),
    ("no safety margin", {"safe_margin": 0}, ("t1", "t2")),
    ("long TPR, small margin", {"tpr_interval": 12, "safe_margin": 1, "max_time": 400}, ("t1", "t2")),
    ("reference, 3 trains", {}, ("t1", "t2", "t3")),
    ("dense fleet, 4 trains", {"positions": {"t1": 5, "t2": 9, "t3": 13, "t4": 17},
                               "max_time": 600}, ("t1", "t2", "t3", "t4")),
]


REPS = 5


def main():
    timeout = int(sys.argv[1]) if len(sys.argv) > 1 else 300
    results = []
    for name, over, trains in GRID:
        cfg = dict(REF)
        cfg.update(over)
        cfg["name"] = name
        res = evaluate(cfg, trains=trains, timeout=timeout, tag="rq1", reps=REPS)
        res["name"] = name
        results.append(res)
        line = " | ".join(
            "{}: {} ({}s, {} states)".format(
                q.replace("reach_", "").replace("safe_run", "safe"),
                res[q]["verdict"], res[q]["time"], res[q].get("states", "-"))
            for q in ("safe_run", "reach_hazard", "reach_accident"))
        print("{:22} {} trains | {}".format(name, len(trains), line), flush=True)
    with open("rq1_results.json", "w") as fh:
        json.dump(results, fh, indent=1)


if __name__ == "__main__":
    main()
