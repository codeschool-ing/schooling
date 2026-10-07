#!/usr/bin/env python3
"""Expected loss per year for each risk: how often it happens, times what one event costs."""
import csv

rows = list(csv.DictReader(open("risks.csv")))
for r in rows:
    r["expected"] = float(r["per_year"]) * float(r["loss"])
rows.sort(key=lambda r: r["expected"], reverse=True)
total = sum(r["expected"] for r in rows)

print(f"{'':4} {'per year':>8} {'R$ per event':>13} {'R$ per year':>12} {'share':>6}")
for r in rows:
    print(f"{r['id']:4} {float(r['per_year']):8.3g} {float(r['loss']):13,.0f} "
          f"{r['expected']:12,.0f} {r['expected'] / total:6.1%}")
print(f"{'':4} {'':8} {'':13} {total:12,.0f}")
