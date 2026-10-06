"""tree.py: one trace from spans.jsonl, drawn as the tree it is.

    python tree.py [TRACE_ID] [--spans FILE] [--attrs]

With no TRACE_ID, the last trace in the file. Each line is a span: when it
started, counted from the start of the trace, how long it took, and its name,
indented under its parent. --attrs adds each span's attributes.
"""
import argparse
import json

p = argparse.ArgumentParser()
p.add_argument("trace", nargs="?")
p.add_argument("--spans", default="spans.jsonl")
p.add_argument("--attrs", action="store_true")
a = p.parse_args()

spans = [json.loads(line) for line in open(a.spans)]
trace = a.trace or spans[-1]["trace"]
mine = [s for s in spans if s["trace"].startswith(trace)]
if not mine:
    raise SystemExit(f"no trace {trace} in {a.spans}")
t0 = min(s["start"] for s in mine)
children = {}
for s in mine:
    children.setdefault(s["parent"], []).append(s)
ids = {s["span"] for s in mine}


def show(s, depth):
    ms = lambda ns: f"{ns / 1e6:,.0f}"
    flag = "  ERROR " + (s["error"] or "") if s["status"] == "ERROR" else ""
    print(f"{ms(s['start'] - t0):>7} {ms(s['end'] - s['start']):>7} ms  {'  ' * depth}{s['name']}{flag}")
    if a.attrs:
        for k, v in s["attributes"].items():
            print(f"{'':19}{'  ' * depth}  {k} = {json.dumps(v, ensure_ascii=False)}")
    for c in sorted(children.get(s["span"], []), key=lambda c: c["start"]):
        show(c, depth + 1)


print(f"trace {mine[0]['trace']}   start(ms) took(ms)")
for root in sorted((s for s in mine if s["parent"] not in ids), key=lambda s: s["start"]):
    show(root, 0)
