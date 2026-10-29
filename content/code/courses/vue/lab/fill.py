"""fill.py MD CAPTURES: paste each captured block into the fence it belongs to.

CAPTURES is what a captures.sh printed: blocks headed "##### NAME". A block
named "SLUG/NAME" is offered only to SLUG.md, so two sections that type the
same command each get their own run. A fence
in MD belongs to the first block not yet taken whose typed lines (those after
a prompt) begin with the fence's own, so a draft fence may hold only its first
command; its whole body is then replaced by the block. A
fence nobody captured, and a block no fence takes, are both reported, and
the file is written only when every transcript fence found its block.

    python3 fill.py lesson.md out.txt [--check]
"""
import re, sys

PROMPT = re.compile(r"^ana@dev:[^$]*\$ ")

def typed(body):
    return [l for l in body.split("\n") if PROMPT.match(l)]

md, cap = sys.argv[1], sys.argv[2]
check = "--check" in sys.argv
blocks = {}
name = None
for line in open(cap, encoding="utf-8").read().split("\n"):
    if line.startswith("##### "):
        name = line[6:].strip(); blocks[name] = []
    elif name is not None:
        blocks[name].append(line)
import os
slug = os.path.basename(md).split(".")[0]
bodies = {k: "\n".join(v).rstrip("\n") + "\n" for k, v in blocks.items()
          if "/" not in k or k.split("/", 1)[0] == slug}

text = open(md, encoding="utf-8").read()
used, missing, changed = set(), [], 0
def repl(m):
    global changed
    if m.group(1) != "```\n":
        return m.group(0)
    body = m.group(2)
    if not PROMPT.match(body.split("\n", 1)[0]):
        return m.group(0)
    key = typed(body)
    names = [k for k, b in bodies.items() if k not in used and typed(b)[:len(key)] == key]
    # a block named for this section wins over one that is not
    names.sort(key=lambda k: "/" not in k)
    if not names:
        missing.append(body.split("\n", 1)[0]); return m.group(0)
    k = names[0]
    used.add(k)
    if body != bodies[k]:
        changed += 1
    return m.group(1) + bodies[k] + "```"
out = re.sub(r"^(```[a-z-]*\n)(.*?)^```$", repl, text, flags=re.S | re.M)
for f in missing:
    print(f"{md}: no capture for the fence starting {f!r}")
if missing:
    sys.exit(1)
if check:
    print(f"{md}: {changed} fence(s) differ from the capture")
    sys.exit(1 if changed else 0)
open(md, "w", encoding="utf-8").write(out)
print(f"{md}: {changed} fence(s) updated")
