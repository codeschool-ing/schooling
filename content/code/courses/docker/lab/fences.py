#!/usr/bin/env python3
"""What the lessons show, read back out of them, so the lab runs it rather than a copy.

The lab is the author's and the student never has it: a file the lab uses has
to be one a lesson shows whole, and the only way the two cannot drift apart is
for the lab to take it from the lesson, or to refuse to start when they differ.

  fences.py block MD FIRSTLINE   print the one fence in MD whose first line is
                                 FIRSTLINE, for the lab to run or to write
  fences.py example MD FILE      print the program the one annotated example in
                                 MD naming FILE adds up to
  fences.py has COURSE           read stdin and fail unless some English lesson
                                 of COURSE shows exactly that text as a fence
  fences.py files DIR COURSE     fail unless every file under DIR (vendor/ and
                                 .git/ aside) is shown whole by some fence, and
                                 an annotated example naming a file names it

An annotated example (```schooling-example) counts as the program its parts
add up to, which is what its copy button hands over.
"""
import glob
import json
import os
import re
import sys

FENCE = re.compile(r"^```([^\n]*)\n(.*?)^```$", re.M | re.S)


def fences(md):
    """(file named, text) for every fence in one .md."""
    out = []
    for m in FENCE.finditer(open(md, encoding="utf-8").read()):
        info, body = m.group(1).strip(), m.group(2)
        if info == "schooling-example":
            ex = json.loads(body)
            out.append((ex.get("file"), "".join(p["code"] for p in ex["parts"])))
        else:
            out.append((None, body))
    return out


def lessons(course):
    return [p for p in sorted(glob.glob(os.path.join(course, "lessons", "*", "*.md")))
            if not p.endswith(".pt.md")]


def die(msg):
    print("fences.py: " + msg, file=sys.stderr)
    sys.exit(1)


def main(argv):
    if len(argv) == 3 and argv[0] == "block":
        found = [t for _, t in fences(argv[1]) if t.split("\n", 1)[0] == argv[2]]
        if len(found) != 1:
            die("%d fences in %s start with %r, want exactly 1" % (len(found), argv[1], argv[2]))
        sys.stdout.write(found[0])
    elif len(argv) == 3 and argv[0] == "example":
        found = [t for name, t in fences(argv[1]) if name == argv[2]]
        if len(found) != 1:
            die("%d annotated examples in %s name %s, want exactly 1" % (len(found), argv[1], argv[2]))
        sys.stdout.write(found[0])
    elif len(argv) == 2 and argv[0] == "has":
        want = sys.stdin.read()
        if not any(t == want for md in lessons(argv[1]) for _, t in fences(md)):
            die("no lesson shows this file whole:\n" + want)
    elif len(argv) == 3 and argv[0] == "files":
        shown = [f for md in lessons(argv[2]) for f in fences(md)]
        bad = 0
        for root, dirs, names in os.walk(argv[1]):
            dirs[:] = [d for d in dirs if d not in ("vendor", ".git")]
            for n in names:
                path = os.path.join(root, n)
                rel = os.path.relpath(path, argv[1])
                text = open(path, encoding="utf-8").read()
                hits = [name for name, t in shown if t == text]
                if not hits:
                    print("fences.py: %s is not shown whole in any lesson" % rel, file=sys.stderr)
                    bad += 1
                elif all(name not in (None, rel) for name in hits):
                    print("fences.py: %s is shown under another name: %s" % (rel, hits), file=sys.stderr)
                    bad += 1
        if bad:
            sys.exit(1)
    else:
        die("usage: block MD FIRSTLINE | example MD FILE | has COURSE | files DIR COURSE")


if __name__ == "__main__":
    main(sys.argv[1:])
