#!/usr/bin/env python3
"""The checks every change to the model has to pass, and the ones it is known to fail.

    python3 check_model.py              against today's date
    python3 check_model.py 2026-10-12   against another date

A problem listed in baseline.txt is known and reported; any other fails the check. So does a
line in baseline.txt that is no longer a problem, because a stale exception reads as a real one.
"""
import csv
import datetime
import json
import pathlib
import sys

today = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()


def front_matter(path):
    lines = path.read_text().split("\n")
    end = lines.index("---", 1)
    return dict(line.split(": ", 1) for line in lines[1:end])


model = json.load(open("model.json"))
elements = {e["name"] for kind in ("actors", "assets", "flows", "boundaries") for e in model[kind]}
threats = list(csv.DictReader(open("threats.csv")))
requirements = list(csv.DictReader(open("requirements.csv")))
decisions = [front_matter(p) for p in sorted(pathlib.Path("decisions").glob("*.md"))]
superseded = {d["supersedes"] for d in decisions if "supersedes" in d}
current = [d for d in decisions if d["id"] not in superseded]

problems = []
for t in threats:
    if t["element"] not in elements:
        problems.append(f"{t['id']}: names {t['element']!r}, which is not in the model")
covered = {tid for r in requirements for tid in r["threats"].split()}
decided = {d["threat"] for d in current}
for t in threats:
    if t["id"] not in covered | decided:
        problems.append(f"{t['id']}: no requirement and no decision")
for r in requirements:
    if not r["verified by"]:
        problems.append(f"{r['id']}: not verified")
for d in current:
    if datetime.date.fromisoformat(d["review by"]) < today:
        problems.append(f"{d['id']}: review overdue since {d['review by']}")

baseline = [line for line in open("baseline.txt").read().split("\n") if line]
new = [p for p in problems if p not in baseline]
stale = [b for b in baseline if b not in problems]
for p in problems:
    print(("known  " if p in baseline else "NEW    ") + p)
for b in stale:
    print(f"STALE  {b}: fixed, so remove it from baseline.txt")
print(f"{len(threats)} threats, {len(requirements)} requirements, {len(current)} current decisions:"
      f" {len(new)} new, {len(stale)} stale, {len(problems) - len(new)} known")
sys.exit(1 if new or stale else 0)
