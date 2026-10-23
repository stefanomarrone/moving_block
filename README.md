# ETCS moving block: Prolog model of the trackside track and reserved status areas

Modelling and verification of the trackside management of track status and reserved
status areas in ETCS moving block signalling.

## Model

The model is in `etcs-l3/`. It is standard ISO Prolog and runs on GNU Prolog 1.4.5.
Load `system.pl`, which includes every other file:

```
cd etcs-l3
gprolog --consult-file system.pl
```

Three system-level queries are available, for up to four trains:

- `safe_run(Trains, Log)` — existential: returns a witness of a mission completed
  by every train without violating any safety property;
- `reach_hazard(Trains, Log)` — reachability: succeeds iff a state in which two
  reserved areas overlap is reachable, and returns the trace leading to it;
- `reach_accident(Trains, Log)` — reachability: the same, for overlapping
  occupied areas.

For example:

```
| ?- safe_run([t1, t2], L), print_log(L).
| ?- reach_hazard([t1, t2, t3], L), print_log(L).
```

Non-interactively:

```
gprolog --consult-file system.pl \
  --query-goal "reset_counters, ( reach_hazard([t1,t2],L) -> print_log(L) ; write(unsat) ), nl, report_counters, halt"
```

`reset_counters/0` and `report_counters/0` instrument the search: they report the
number of visited states, of completed runs, of runs cut by a safety violation and
of runs truncated by the `max_time` horizon. A verdict of `unsat` is only
meaningful together with the number of states explored to reach it.

## Configuration

All the parameters are in `etcs-l3/parameters.pl`, which holds the reference
configuration of the paper. The cost of the exhaustive queries is driven by the
width of the `[min_speed, max_speed]` band and by the length of the track, not by
the number of trains.

## Replication

`replication/` reproduces the three experiments of the paper:

```
cd replication
python3 rq1.py   # safety over a grid of configurations
python3 rq2.py   # fault injection
python3 rq3.py   # cost of the verification
```

Each script writes its raw results to `rq*_results.json`. `fixes.py` documents the
two defects that the verification exposed in the first version of the model (a
direction test performed on a possibly stale board, and a movement authority
checked over one march step instead of a whole report period); `rq2.py` re-injects
both as faults F5 and F3.

`etcs-l3.backup-pre-edcc27/` is the model as it was before those corrections.
