#!/usr/bin/env python3
"""List the decisions in decisions/, and which ones are due or overdue for review.

    python3 acceptances.py              against today's date
    python3 acceptances.py 2026-10-07   against another date
"""
import datetime
import pathlib
import sys

today = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()


def front_matter(path):
    lines = path.read_text().split("\n")
    end = lines.index("---", 1)
    return dict(line.split(": ", 1) for line in lines[1:end])


print(f"{'':7} {'threat':6} {'decision':9} {'owner':7} {'review by':10}  status")
for path in sorted(pathlib.Path("decisions").glob("*.md")):
    d = front_matter(path)
    days = (datetime.date.fromisoformat(d["review by"]) - today).days
    status = f"OVERDUE by {-days} days" if days < 0 else f"due in {days} days" if days <= 30 else "ok"
    print(f"{d['id']:7} {d['threat']:6} {d['decision']:9} {d['owner']:7} {d['review by']:10}  {status}")
