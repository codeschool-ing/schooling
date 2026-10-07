#!/usr/bin/env python3
"""Rank controls by the expected loss each removes per real spent, or apply a plan.

    python3 prioritise.py              rank every control on its own
    python3 prioritise.py C3 C1 ...    print risks.csv as it would be with those controls
"""
import csv
import sys

risks = {r["id"]: r for r in csv.DictReader(open("risks.csv"))}
controls = {}
for row in csv.DictReader(open("controls.csv")):
    c = controls.setdefault(row["control"], {"name": row["name"], "cost": float(row["cost_per_year"]), "cuts": {}})
    c["cuts"][row["risk"]] = float(row["reduction"])


def expected(r):
    return float(r["per_year"]) * float(r["loss"])


if len(sys.argv) == 1:
    ranked = []
    for cid, c in controls.items():
        saved = sum(expected(risks[rid]) * cut for rid, cut in c["cuts"].items())
        ranked.append((saved / c["cost"], cid, c, saved))
    print(f"{'':4} {'R$ cost':>8} {'R$ saved':>9} {'saved/cost':>11}  control")
    for ratio, cid, c, saved in sorted(ranked, key=lambda x: x[0], reverse=True):
        print(f"{cid:4} {c['cost']:8,.0f} {saved:9,.0f} {ratio:11.1f}  {c['name']}")
else:
    keep = {rid: 1.0 for rid in risks}
    for cid in sys.argv[1:]:
        for rid, cut in controls[cid]["cuts"].items():
            keep[rid] *= 1 - cut
    out = csv.DictWriter(sys.stdout, fieldnames=list(next(iter(risks.values()))), lineterminator="\n")
    out.writeheader()
    for rid, r in risks.items():
        for col in ("per_year", "per_year_low", "per_year_high"):
            r[col] = f"{float(r[col]) * keep[rid]:.4g}"
        out.writerow(r)
