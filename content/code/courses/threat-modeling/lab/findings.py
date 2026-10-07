#!/usr/bin/env python3
"""Summarise what pytm found: where the findings landed, or the list for one element."""
import collections
import json
import sys

findings = json.load(open(sys.argv[1]))["findings"]

if len(sys.argv) == 2:
    print(f"{len(findings)} findings on {len({f['target'] for f in findings})} elements")
    for target, n in collections.Counter(f["target"] for f in findings).most_common():
        print(f"  {n:3}  {target}")
else:
    mine = [f for f in findings if f["target"] == sys.argv[2]]
    show = int(sys.argv[3]) if len(sys.argv) > 3 else len(mine)
    for f in mine[:show]:
        print(f"  {f['threat_id']:6} {f['severity']:9} {f['description']}")
    if show < len(mine):
        print(f"  ... and {len(mine) - show} more")
