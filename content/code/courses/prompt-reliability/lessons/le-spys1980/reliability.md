---
title: The reliability diagram
version: 2
---

Save it as `calibrate.py`:

```python
"""calibrate: does the confidence a reply states match how often its category
is right? Replies are grouped by what they stated, and each group is counted."""
import sys

from pl import parse, read_jsonl

rows = read_jsonl(sys.argv[1])
expect = {c["id"]: c["expect"] for c in read_jsonl(rows[0]["cases"])}
pairs, missing = [], 0
for r in rows:
    obj = parse(r["text"]) or {}
    conf = obj.get("confidence")
    if isinstance(conf, bool) or not isinstance(conf, (int, float)) or not 0 <= conf <= 1:
        missing += 1
        continue
    pairs.append((float(conf), obj.get("category") == expect[r["case"]]["category"]))

edges = [0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
print("stated         n  mean said  accuracy")
ece = 0.0
for lo, hi in zip(edges, edges[1:]):
    group = [(c, ok) for c, ok in pairs if lo <= c < hi or (hi == 1.0 and c == 1.0)]
    if not group:
        print("%.2f-%.2f %5d %10s %9s" % (lo, hi, 0, "-", "-"))
        continue
    said = sum(c for c, _ in group) / len(group)
    right = sum(ok for _, ok in group) / len(group)
    ece += len(group) / len(pairs) * abs(said - right)
    print("%.2f-%.2f %5d %10.2f %9.2f" % (lo, hi, len(group), said, right))
brier = sum((c - ok) ** 2 for c, ok in pairs) / len(pairs)
print("\nreplies %d, %d with no usable confidence; right %d of %d, mean stated %.2f"
      % (len(rows), missing, sum(ok for _, ok in pairs), len(pairs),
         sum(c for c, _ in pairs) / len(pairs)))
print("ECE %.3f   Brier %.3f" % (ece, brier))
if "--thresholds" in sys.argv:
    print("\nanswer if      answered  accuracy")
    for t in (0.0, 0.8, 0.85, 0.9, 0.95):
        kept = [ok for c, ok in pairs if c >= t]
        acc = "%.2f" % (sum(kept) / len(kept)) if kept else "-"
        print("conf >= %.2f %8d %9s" % (t, len(kept), acc))
```
