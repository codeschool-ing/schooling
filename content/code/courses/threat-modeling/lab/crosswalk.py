#!/usr/bin/env python3
"""Read the controls through a framework: ISO/IEC 27001:2022 Annex A, or the NIST CSF 2.0.

    python3 crosswalk.py            every control, its threat and both references
    python3 crosswalk.py iso27001   grouped by the four themes of Annex A
    python3 crosswalk.py csf        grouped by the six functions of the CSF
"""
import collections
import csv
import re
import sys

GROUPS = {
    "iso27001": {"5": "organisational", "6": "people", "7": "physical", "8": "technological"},
    "csf": {"GV": "Govern", "ID": "Identify", "PR": "Protect",
            "DE": "Detect", "RS": "Respond", "RC": "Recover"},
}

controls = {row["control"]: row for row in csv.DictReader(open("controls.csv"))}
mapping = list(csv.DictReader(open("mapping.csv")))

if len(sys.argv) == 1:
    for m in mapping:
        c = controls[m["control"]]
        print(f"{m['control']:4} {c['risk']:4} {m['iso27001']:9} {m['csf']:9} {m['plan']:10}  {c['name']}")
    sys.exit()

framework = sys.argv[1]
refs = collections.defaultdict(list)
for m in mapping:
    for ref in m[framework].split():
        refs[ref].append(m)

def order(ref):
    return [int(p) if p.isdigit() else p for p in re.split(r"[.-]", ref)]

for prefix, name in GROUPS[framework].items():
    mine = sorted((r for r in refs if r.split(".")[0] == prefix), key=order)
    print(f"{name:14} {len(mine)}")
    for ref in mine:
        names = [m["control"] + (" (not bought)" if m["plan"] == "not bought" else "") for m in refs[ref]]
        print(f"  {ref:9} {'  '.join(names)}")
