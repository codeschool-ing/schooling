#!/usr/bin/env python3
"""Join threats to requirements: what covers each threat, and what is not covered or not verified."""
import csv

threats = {row["id"]: row for row in csv.DictReader(open("threats.csv"))}
requirements = list(csv.DictReader(open("requirements.csv")))

covered = {tid: [] for tid in threats}
for req in requirements:
    for tid in req["threats"].split():
        covered[tid].append(req)

for tid, reqs in covered.items():
    ids = ", ".join(f"{r['id']} ({r['verified by'] or 'not verified'})" for r in reqs)
    print(f"{tid}  {threats[tid]['stride']}  {ids or '-- no requirement'}")

bare = [tid for tid, reqs in covered.items() if not reqs]
unverified = [r["id"] for r in requirements if not r["verified by"]]
print(f"\n{len(threats)} threats, {len(requirements)} requirements")
print("no requirement:", " ".join(bare) or "none")
print("not verified:  ", " ".join(unverified) or "none")
