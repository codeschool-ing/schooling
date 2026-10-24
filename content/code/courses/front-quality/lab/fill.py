#!/usr/bin/env python3
"""fill.py LESSON_DIR CAPTURE_OUTPUT [--check]

Pastes the blocks a captures.sh printed (each opened by `##### name`) into the
lesson's .md and .pt.md files:

  - a fence whose whole body is `@@name@@` becomes that block;
  - a fence that already holds a transcript is matched to the block whose
    FIRST LINE is the fence's first line, and is replaced by it if they differ.

With --check nothing is written: it reports every transcript fence that does
not equal a block byte for byte, and exits 1 if there is one. A transcript
fence is a fence with no info string whose first line is a prompt."""
import re, sys, pathlib

lesson, out = pathlib.Path(sys.argv[1]), sys.argv[2]
check = "--check" in sys.argv
blocks, name = {}, None
for line in open(out, encoding="utf-8").read().split("\n"):
    m = re.match(r"^##### (.+)$", line)
    if m:
        name = m.group(1).strip(); blocks[name] = []
    elif name is not None:
        blocks[name].append(line)
blocks = {k: "\n".join(v).rstrip("\n") + "\n" for k, v in blocks.items()}
by_first = {}
for k, v in blocks.items():
    by_first.setdefault(v.split("\n", 1)[0], []).append(k)

PROMPT = re.compile(r"^ana@dev:[^$]*\$ ")
FENCE = re.compile(r"^```([^\n]*)\n(.*?)^```[ \t]*$", re.S | re.M)
bad = 0
for md in sorted(lesson.glob("*.md")):
    src = md.read_text(encoding="utf-8")
    def sub(m):
        global bad
        info, body = m.group(1), m.group(2)
        ph = re.fullmatch(r"@@(.+?)@@\n", body)
        if ph:
            k = ph.group(1)
            if k not in blocks:
                print(f"{md.name}: no block {k}"); bad += 1; return m.group(0)
            if check:
                print(f"{md.name}: placeholder {k} not filled"); bad += 1; return m.group(0)
            return "```" + info + "\n" + blocks[k] + "```"
        if info.strip() == "" and PROMPT.match(body):
            first = body.split("\n", 1)[0]
            ks = by_first.get(first, [])
            if body in (blocks[k] for k in ks):
                return m.group(0)
            if len(ks) > 1:   # several blocks open the same way: take the one closest to what is there
                import difflib
                ks = [max(ks, key=lambda k: difflib.SequenceMatcher(None, body, blocks[k]).ratio())]
            if len(ks) != 1:
                print(f"{md.name}: transcript starting {first!r} matches {len(ks)} blocks"); bad += 1
                return m.group(0)
            print(f"{md.name}: transcript {ks[0]} differs from the capture" + ("" if check else ", replaced"))
            if check:
                bad += 1; return m.group(0)
            return "```" + info + "\n" + blocks[ks[0]] + "```"
        return m.group(0)
    new = FENCE.sub(sub, src)
    if new != src and not check:
        md.write_text(new, encoding="utf-8")
sys.exit(1 if bad else 0)
