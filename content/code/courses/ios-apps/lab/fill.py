"""Paste a lesson's captures into its prose. THE STUDENT NEVER SEES THIS (C-40).

    sudo bash lessons/<id>/captures.sh > /tmp/<id>.out
    python3 lab/fill.py <id> /tmp/<id>.out

captures.sh prints blocks headed `##### <name>`. A fence in a section whose
whole body is `@@capture <name>@@` is replaced by that block, in the .md and
in the .pt.md, so the two are byte-identical. What went where is recorded in
lab/fences/<id>.json, so that running the captures again and filling again
replaces the old transcript with the new one instead of needing the
placeholder back.
"""
import json, os, re, sys

lid, out = sys.argv[1], sys.argv[2]
here = os.path.dirname(os.path.abspath(__file__))
ldir = os.path.join(here, "..", "lessons", lid)
blocks, name = {}, None
for line in open(out, encoding="utf-8").read().split("\n"):
    m = re.fullmatch(r"##### (\S+)", line)
    if m:
        name = m.group(1); blocks[name] = []; continue
    if name: blocks[name].append(line)
blocks = {k: "\n".join(v).rstrip("\n") for k, v in blocks.items()}
rec_f = os.path.join(here, "fences", lid + ".json")
rec = json.load(open(rec_f)) if os.path.exists(rec_f) else {}
used = set()
for fn in sorted(os.listdir(ldir)):
    if not fn.endswith(".md"): continue
    p = os.path.join(ldir, fn); t = open(p, encoding="utf-8").read(); orig = t
    def ph(m):
        n = m.group(1)
        if n not in blocks: sys.exit(f"{fn}: no capture block {n}")
        used.add(n); rec[n] = blocks[n]
        return "```\n" + blocks[n] + "\n```"
    t = re.sub(r"```\n@@capture (\S+)@@\n```", ph, t)
    for n, old in list(rec.items()):
        if n in blocks and blocks[n] != old and ("```\n" + old + "\n```") in t:
            t = t.replace("```\n" + old + "\n```", "```\n" + blocks[n] + "\n```"); used.add(n)
        elif ("```\n" + old + "\n```") in t: used.add(n)
    for n in list(rec):
        if n in blocks: rec[n] = blocks[n]
    if t != orig:
        open(p, "w", encoding="utf-8").write(t); print("filled", fn)
json.dump(rec, open(rec_f, "w"), indent=1, ensure_ascii=False)
left = set(blocks) - used
if left: print("captured but not quoted:", " ".join(sorted(left)))
