#!/usr/bin/env python3
"""List the data flows of a pytm model, and mark the ones that cross a trust boundary."""
import json
import sys

model = json.load(open(sys.argv[1]))
where = {e["name"]: e["inBoundary"] or "(none)" for e in model["elements"]}

crossing = 0
for f in model["flows"]:
    a, b = where[f["source"]], where[f["sink"]]
    mark = "x" if a != b else " "
    crossing += a != b
    print(f"{f['order']:2} {mark} {f['name']:26} {a} -> {b}")
print(f"\n{crossing} of {len(model['flows'])} flows cross a trust boundary")
