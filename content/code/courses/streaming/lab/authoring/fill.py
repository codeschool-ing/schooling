#!/usr/bin/env python3
"""fill.py LESSON_DIR CAPTURE_OUTPUT: put each captured block into the bare fence that starts with its first line."""
import glob, re, sys
sys.path.insert(0, "/var/tmp/lab/bin")
import fences
d, out = sys.argv[1], sys.argv[2]
blocks, cur = [], None
for line in open(out, encoding="utf-8").read().split("\n"):
    if line.startswith("##### "):
        cur = [line[6:], []]; blocks.append(cur); continue
    if cur is not None: cur[1].append(line)
blocks = [(n, "\n".join(b).rstrip("\n")) for n, b in blocks]
used, ok = set(), True
takens = {'en': set(), 'pt': set()}
for md in sorted(glob.glob(d + "/*.md")):
    text = open(md, encoding="utf-8").read()
    pieces = fences.split(text)
    taken = takens['pt' if md.endswith('.pt.md') else 'en']
    for k, p in enumerate(pieces):
        if p[0] != "fence" or p[1] != "": continue
        first = p[2].split("\n", 1)[0]
        if not first.startswith("ubuntu@stream:"): continue
        for i, (n, b) in enumerate(blocks):
            if i in taken or not b: continue
            if b.split("\n", 1)[0] == first:
                taken.add(i); used.add(n); pieces[k] = ("fence", "", b); break
        else:
            print(f"{md}: no block starts with {first!r}"); ok = False
    new = fences.join(pieces)
    assert fences.join(fences.split(text)) == text
    if new != text: open(md, "w", encoding="utf-8").write(new)
for n, b in blocks:
    if n not in used: print(f"unused block: {n}")
sys.exit(0 if ok else 1)
