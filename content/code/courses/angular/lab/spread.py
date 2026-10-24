"""spread.py SOURCE: move each quiz's right option so the positions cycle 1, 3, 2, 4.

check-exercises refuses a lesson where the right option sits at one position
too often, because then the place is the answer. Options are written in the
order they come to mind, which is not random, so this reorders them in the
source: each option keeps its Portuguese line and its reason, and only quizzes
(one right answer) move. Run it before q.py, and look at the diff.
"""
import re, sys

path = sys.argv[1]
lines = open(path, encoding="utf-8").read().split("\n")
out, i, n = [], 0, 0
cycle = [0, 2, 1, 3]
while i < len(lines):
    line = lines[i]
    m = re.match(r"^@ \S+ (\S+) ", line)
    if not m:
        out.append(line); i += 1; continue
    kind = m.group(1)
    out.append(line); i += 1
    head, opts, tail = [], [], []
    while i < len(lines) and not lines[i].startswith("@ "):
        l = lines[i]
        if re.match(r"^[+-] ", l):
            opts.append([l])
        elif re.match(r"^(\+\+|--) ", l) and opts:
            opts[-1].append(l)
        elif opts:
            tail.append(l)
        else:
            head.append(l)
        i += 1
    if kind == "quiz" and opts:
        right = [o for o in opts if o[0].startswith("+ ")]
        wrong = [o for o in opts if o[0].startswith("- ")]
        if len(right) == 1:
            k = min(cycle[n % 4], len(opts) - 1)
            n += 1
            opts = wrong[:k] + right + wrong[k:]
    out += head + [l for o in opts for l in o] + tail
open(path, "w", encoding="utf-8").write("\n".join(out))
