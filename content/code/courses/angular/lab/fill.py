"""fill.py MD... CAPTURES: paste each captured block into the fence it belongs to.

CAPTURES is what a captures.sh printed: blocks headed "##### NAME". A fence
belongs to the first block not yet taken whose typed lines (those after a
prompt) begin with the fence's own, so a draft fence may hold only its first
command; its whole body is then replaced by the block. The MDs are the
sections of one lesson IN THE LESSON'S ORDER, and a block taken by one is
taken for the rest: two sections showing the same command get the first and
the second time it was typed, not the first time twice. A fence nobody
captured, and a block no fence takes, are both reported, and no file is
written unless every transcript fence found its block.

    python3 fill.py a.md b.md out.txt [--check]
"""
import re, sys

PROMPT = re.compile(r"^ana@dev:[^$]*\$ ")

# A process id is different on every run too, so `kill -SIGNAL 1234` compares as
# `kill -SIGNAL PID`.
PID = re.compile(r"(kill -[A-Z0-9]+ )(\d+|PID)\b")

def typed(body):
    return [PID.sub(r"\1PID", l) for l in body.split("\n") if PROMPT.match(l)]

args = [a for a in sys.argv[1:] if not a.startswith("--")]
mds, cap = args[:-1], args[-1]
check = "--check" in sys.argv
blocks = {}
name = None
for line in open(cap, encoding="utf-8").read().split("\n"):
    if line.startswith("##### "):
        name = line[6:].strip(); blocks[name] = []
    elif name is not None:
        blocks[name].append(line)
bodies = {k: "\n".join(v).rstrip("\n") + "\n" for k, v in blocks.items()}

used, missing, outs = set(), [], []
for md in mds:
    text = open(md, encoding="utf-8").read()
    changed = 0
    def repl(m):
        global changed
        if m.group(1) != "```\n":
            return m.group(0)
        body = m.group(2)
        if not PROMPT.match(body.split("\n", 1)[0]):
            return m.group(0)
        key = typed(body)
        names = [k for k, b in bodies.items() if k not in used and typed(b)[:len(key)] == key]
        if not names:
            missing.append((md, body.split("\n", 1)[0])); return m.group(0)
        k = names[0]
        used.add(k)
        if body != bodies[k]:
            changed += 1
        return m.group(1) + bodies[k] + "```"
    outs.append((md, re.sub(r"^(```[a-z-]*\n)(.*?)^```$", repl, text, flags=re.S | re.M), changed))
for md, f in missing:
    print(f"{md}: no capture for the fence starting {f!r}")
for k in bodies:
    if k not in used:
        print(f"{cap}: block {k} is in no fence, starting {bodies[k].split(chr(10), 1)[0]!r}")
if missing:
    sys.exit(1)
if check:
    for md, _, changed in outs:
        print(f"{md}: {changed} fence(s) differ from the capture")
    sys.exit(1 if any(c for _, _, c in outs) else 0)
for md, out, changed in outs:
    open(md, "w", encoding="utf-8").write(out)
    print(f"{md}: {changed} fence(s) updated")
