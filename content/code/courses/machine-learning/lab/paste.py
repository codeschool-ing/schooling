#!/usr/bin/env python3
"""Put a capture into a lesson, and check that every capture is still in it.

    paste.py LESSON_DIR OUTPUT     replace each line `@@cap:NAME@@` in every .md of
                                   the lesson with the block NAME of OUTPUT, as a fence
    paste.py --check LESSON_DIR OUTPUT
                                   every block of OUTPUT must sit, byte for byte, as
                                   the whole of a fence in the .md AND the .pt.md that
                                   use it; a placeholder left anywhere fails

OUTPUT is what the lesson's capture script printed: blocks opened by `##### NAME`.
Running the check after a rerun is what says the lesson still quotes the machine.
"""
import glob
import os
import re
import sys

PLACE = re.compile(r"^@@cap:([a-z0-9-]+)@@$", re.M)
FENCE = re.compile(r"^```([\w-]*)\n(.*?)^```$", re.S | re.M)


def bare_fences(text):
    """The bodies of the fences with no info string, which is what a capture is."""
    return {m.group(2).rstrip("\n") for m in FENCE.finditer(text) if not m.group(1)}


def read_blocks(path):
    out, name, buf = {}, None, []
    for line in open(path, encoding="utf-8").read().split("\n"):
        if line.startswith("##### "):
            if name:
                out[name] = "\n".join(buf).rstrip("\n")
            name, buf = line[6:].strip(), []
        elif name:
            buf.append(line)
    if name:
        out[name] = "\n".join(buf).rstrip("\n")
    return out


def main():
    check = sys.argv[1] == "--check"
    lesson, output = sys.argv[-2], sys.argv[-1]
    caps = read_blocks(output)
    files = sorted(glob.glob(os.path.join(lesson, "*.md")))
    bad = 0
    if not check:
        for f in files:
            text = open(f, encoding="utf-8").read()
            def sub(m):
                if m.group(1) not in caps:
                    sys.exit(f"{f}: no capture called {m.group(1)}")
                return "```\n" + caps[m.group(1)] + "\n```"
            new = PLACE.sub(sub, text)
            if new != text:
                open(f, "w", encoding="utf-8").write(new)
        return
    fenced = {f: bare_fences(open(f, encoding="utf-8").read()) for f in files}
    for f in files:
        for m in PLACE.finditer(open(f, encoding="utf-8").read()):
            print(f"{f}: placeholder {m.group(1)} never pasted"); bad += 1
    for name, body in caps.items():
        where = [f for f in files if body in fenced[f]]
        en = [f for f in where if not f.endswith(".pt.md")]
        pt = [f for f in where if f.endswith(".pt.md")]
        if not en or len(en) != len(pt):
            print(f"{name}: in {len(en)} English and {len(pt)} Portuguese files"); bad += 1
    print(f"{len(caps)} captures, {bad} problems")
    sys.exit(1 if bad else 0)


main()
