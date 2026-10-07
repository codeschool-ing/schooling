#!/usr/bin/env python3
"""The attack surface of a pytm model: every flow that enters or leaves what Vereda runs."""
import json
import sys

OURS = {"Vereda cloud", "Private network"}

model = json.load(open(sys.argv[1]))
where = {e["name"]: e["inBoundary"] for e in model["elements"]}
inside = lambda name: where[name] in OURS

entries = [f for f in model["flows"] if not inside(f["source"]) and inside(f["sink"])]
exits = [f for f in model["flows"] if inside(f["source"]) and not inside(f["sink"])]

for title, flows in (("entry points", entries), ("exit points", exits)):
    print(f"{len(flows)} {title}")
    for f in flows:
        print(f"  {f['name']:26} {f['source']} -> {f['sink']}")
