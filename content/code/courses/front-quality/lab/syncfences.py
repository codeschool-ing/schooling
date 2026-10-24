#!/usr/bin/env python3
"""syncfences.py LESSON_DIR: copy every fence of SECTION.md into SECTION.pt.md.

A translation translates the prose and never the program, so the Kth fence of
a .pt.md is the Kth fence of the .md, byte for byte. This writes them so; a
figure or an annotated example is left alone, because blocks.py writes those
in each language. A translation with a different number of fences is
reported and not touched."""
import pathlib, re, sys

FENCE = re.compile(r"^```([^\n]*)\n(.*?)^```[ \t]*$", re.S | re.M)
SKIP = ("schooling-figure", "schooling-example")
bad = 0
for pt in sorted(pathlib.Path(sys.argv[1]).glob("*.pt.md")):
    en = pt.with_name(pt.name[: -len(".pt.md")] + ".md")
    ef = list(FENCE.finditer(en.read_text(encoding="utf-8")))
    text = pt.read_text(encoding="utf-8")
    pf = list(FENCE.finditer(text))
    if len(ef) != len(pf):
        print(f"{pt.name}: {len(pf)} fences, {en.name} has {len(ef)}"); bad += 1; continue
    out, last = [], 0
    for e, p in zip(ef, pf):
        out.append(text[last:p.start()])
        if e.group(1).strip() in SKIP:
            out.append(p.group(0))
        else:
            out.append(e.group(0))
        last = p.end()
    out.append(text[last:])
    new = "".join(out)
    if new != text:
        pt.write_text(new, encoding="utf-8")
sys.exit(1 if bad else 0)
