#!/usr/bin/env python3
"""Place each risk on a 5 x 5 matrix, and set its score beside its expected loss."""
import bisect
import csv

# Upper edges of the first four bands; anything above the last edge is band 5.
LIKELIHOOD = [0.1, 0.3, 1, 3]           # events per year
IMPACT = [2_000, 10_000, 50_000, 200_000]  # R$ per event

rows = []
for r in csv.DictReader(open("risks.csv")):
    per_year, loss = float(r["per_year"]), float(r["loss"])
    l = bisect.bisect_left(LIKELIHOOD, per_year) + 1
    i = bisect.bisect_left(IMPACT, loss) + 1
    rows.append((l * i, per_year * loss, r["id"], l, i))

print(f"{'':4} {'L':>2} {'I':>2} {'score':>6} {'R$ per year':>12}")
for score, expected, rid, l, i in sorted(rows, reverse=True):
    print(f"{rid:4} {l:2} {i:2} {score:6} {expected:12,.0f}")
