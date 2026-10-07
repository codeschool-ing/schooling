#!/usr/bin/env python3
"""Summarise what pytm found: how many findings, and where they landed."""
import collections
import json
import sys

report = json.load(open(sys.argv[1]))
findings = report["findings"]
print(f"{len(findings)} findings on {len({f['target'] for f in findings})} elements")

by_target = collections.Counter(f["target"] for f in findings)
for target, n in by_target.most_common():
    print(f"  {n:3}  {target}")

if len(sys.argv) > 2:
    wanted = sys.argv[2]
    print(f"\non {wanted}:")
    for f in findings:
        if f["target"] == wanted:
            print(f"  {f['threat_id']:6} {f['severity']:9} {f['description']}")
