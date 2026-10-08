"""fence.py FILE PATTERN: print the fenced block of FILE whose first line matches PATTERN.

The programs and data a student types are shown in the lessons, and the lab
takes them from there rather than keeping copies of its own: a copy is a
second file that can drift from the one the student reads. Exactly one block
must match, or this fails, so a lesson edited out from under the lab stops
the build instead of quietly running something else.
"""
import re
import sys

path, pattern = sys.argv[1], re.compile(sys.argv[2])
blocks, cur = [], None
for line in open(path, encoding="utf-8").read().split("\n"):
    if cur is None:
        if line.startswith("```"):
            cur = []
    elif line == "```":
        blocks.append(cur)
        cur = None
    else:
        cur.append(line)
hits = [b for b in blocks if b and pattern.search(b[0])]
if len(hits) != 1:
    sys.exit(f"fence.py: {len(hits)} blocks in {path} open with /{pattern.pattern}/, wanted 1")
sys.stdout.write("\n".join(hits[0]) + "\n")
