#!/usr/bin/env python3
"""fill.py LESSON_DIR CAPTURE_OUTPUT [--check]

Pastes the blocks a captures.sh printed (each opened by `##### name`) into the
lesson's .md and .pt.md files:

  - a fence whose whole body is `@@name@@` becomes that block;
  - a fence that holds a transcript is found by what it held the last time it
    was filled: lab/fences/<lesson>.json records, for every block name, the
    text it was given. So a block keeps its place when the capture changes,
    whatever its first line says.

With --check nothing is written: it reports every transcript fence that is
not a block byte for byte, and exits 1 if there is one. A transcript fence is
a fence with no info string whose first line is a prompt."""
import json, pathlib, re, sys

lesson, out = pathlib.Path(sys.argv[1]).resolve(), sys.argv[2]
check = "--check" in sys.argv
blocks, name = {}, None
for line in open(out, encoding="utf-8").read().split("\n"):
    m = re.match(r"^##### (.+)$", line)
    if m:
        name = m.group(1).strip(); blocks[name] = []
    elif name is not None:
        blocks[name].append(line)
blocks = {k: "\n".join(v).rstrip("\n") + "\n" for k, v in blocks.items()}
store = pathlib.Path(__file__).parent / "fences" / (lesson.name + ".json")
store.parent.mkdir(exist_ok=True)
seen = json.loads(store.read_text()) if store.exists() else {}
by_body = {}
for k, v in seen.items():
    by_body.setdefault(v, k)

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
            if k.startswith("fig "):
                return m.group(0)
            if k not in blocks:
                print(f"{md.name}: no block {k}"); bad += 1; return m.group(0)
            if check:
                print(f"{md.name}: placeholder {k} not filled"); bad += 1; return m.group(0)
            seen[k] = blocks[k]
            return "```" + info + "\n" + blocks[k] + "```"
        if info.strip() == "" and PROMPT.match(body):
            same = [k for k, v in blocks.items() if v == body]
            if same:
                seen[same[0]] = body
                return m.group(0)
            k = by_body.get(body)
            if k is None or k not in blocks:
                print(f"{md.name}: a transcript starting {body.splitlines()[0]!r} is no block"); bad += 1
                return m.group(0)
            print(f"{md.name}: transcript {k} differs from the capture" + ("" if check else ", replaced"))
            if check:
                bad += 1; return m.group(0)
            seen[k] = blocks[k]
            return "```" + info + "\n" + blocks[k] + "```"
        return m.group(0)
    new = FENCE.sub(sub, src)
    if new != src and not check:
        md.write_text(new, encoding="utf-8")
if not check:
    store.write_text(json.dumps(seen, indent=1, ensure_ascii=False) + "\n")
sys.exit(1 if bad else 0)
