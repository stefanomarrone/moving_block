#!/bin/sh
# Full campaign: the three experiments, five repetitions each.
set -e
echo "=== RQ1 ==="; python3 -u rq1.py 300
echo "=== RQ2 ==="; python3 -u rq2.py 300
echo "=== RQ3 ==="; python3 -u rq3.py
