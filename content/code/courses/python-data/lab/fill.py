#!/usr/bin/env python3
"""Put a capture script's output into a lesson, and hold the lesson to it afterwards.

THE STUDENT NEVER SEES THIS FILE.

A lesson's captures.sh prints blocks, each one opened by a line `##### NAME`. While a section is
being written, the place a block goes is marked `@@capture:NAME@@` on a line of its own, and

    fill.py LESSON_DIR OUTPUT            replaces each marker, in the .md and the .pt.md, with the
                                         block as an unlabelled fence
    fill.py --check LESSON_DIR OUTPUT    fails unless every block is the body of a fence in some
                                         section of the lesson, byte for byte

so a capture rerun after a change to the lab says which transcript in the prose no longer matches
it. A block whose name ends in `~` varies by nature, a server's token and its clock: it is
compared with every digit and every hexadecimal run masked.
"""
import glob, os, re, sys

def blocks(path):
    out, name = {}, None
    for line in open(path, encoding="utf-8").read().splitlines(keepends=True):
        m = re.match(r"^##### (\S+)\n$", line)
        if m:
            name = m.group(1); out[name] = ""
        elif name:
            out[name] += line
    return out

def mask(s):
    return re.sub(r"\d+", "0", re.sub(r"[0-9a-f]{8,}", "X", s))

def main():
    args = sys.argv[1:]
    check = args[0] == "--check"
    if check:
        args = args[1:]
    lesson, output = args
    found = blocks(output)
    files = sorted(glob.glob(os.path.join(lesson, "*.md")))
    if check:
        bodies = []
        for f in files:
            for m in re.finditer(r"^```([^\n]*)\n(.*?)^```[ \t]*$", open(f, encoding="utf-8").read(),
                                 re.S | re.M):
                if not m.group(1).strip():
                    bodies.append(m.group(2))
        bad = 0
        for name, body in found.items():
            varies = name.endswith("~")
            if not any(b == body or (varies and mask(b) == mask(body)) for b in bodies):
                bad += 1
                print(f"{name}: no fence in {lesson} holds\n{body}")
        sys.exit(1 if bad else 0)
    for f in files:
        text = open(f, encoding="utf-8").read()
        new = re.sub(r"^@@capture:(\S+?)@@\n",
                     lambda m: "```\n" + found[m.group(1)] + "```\n", text, flags=re.M)
        if new != text:
            open(f, "w", encoding="utf-8").write(new)
            print("filled", f)

main()
