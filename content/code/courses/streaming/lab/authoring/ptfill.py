#!/usr/bin/env python3
"""ptfill.py X.pt.md...: each line '@@fence@@' becomes the next plain fence (not a figure, not an example) of X.md."""
import sys
sys.path.insert(0, "/var/tmp/lab/bin")
import fences
for pt in sys.argv[1:]:
    en = pt[:-6] + ".md"
    src = [p for p in fences.split(open(en, encoding="utf-8").read())
           if p[0] == "fence" and p[1] not in ("schooling-figure", "schooling-example")]
    text = open(pt, encoding="utf-8").read()
    n = text.count("@@fence@@")
    if n == 0: continue
    if n != len(src): sys.exit(f"{pt}: {n} placeholders for {len(src)} fences")
    for p in src:
        text = text.replace("@@fence@@", "```" + p[1] + "\n" + p[2] + "\n```", 1)
    open(pt, "w", encoding="utf-8").write(text); print("filled", pt)
