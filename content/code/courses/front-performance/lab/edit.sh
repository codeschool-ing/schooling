# edit.sh: the edits a lesson shows as a fragment, made with the fragment taken
# out of the lesson itself, so the change that runs is the change it shows.
# Sourced by a captures.sh after lib.sh.

# fence MD START: the body of the first fence in MD whose first line starts with START.
fence() { python3 - "$1" "$2" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
for m in re.finditer(r"^```[a-z]*\n(.*?)^```$", text, re.S | re.M):
    if m.group(1).lstrip("\n").lstrip().startswith(sys.argv[2]):
        sys.stdout.write(m.group(1)); break
else:
    sys.exit("no fence starting " + sys.argv[2])
PY
}

# edit FILE MODE ANCHOR TEXT: MODE is "replace" (the one line starting with
# ANCHOR becomes TEXT), "replace-to" (from the line starting with ANCHOR up to
# and including the next line starting with the second anchor, given as
# "FIRST|LAST"), "before" or "after" (TEXT goes before or after that line), or
# "append" (TEXT goes at the end; ANCHOR is ignored). The line must be found
# exactly once.
edit() { python3 - "$@" <<'PY'
import sys
path, mode, anchor, text = sys.argv[1:]
lines = open(path).read().split("\n")
new = text.rstrip("\n").split("\n")
if mode == "append":
    if lines and lines[-1] == "": lines.pop()
    lines += new + [""]
else:
    first = anchor.split("|")[0].strip("\n")
    hits = [i for i, l in enumerate(lines) if l.startswith(first)]
    if len(hits) != 1: sys.exit(f"{path}: {len(hits)} lines start with {first!r}")
    i = hits[0]
    if mode == "replace": lines[i:i + 1] = new
    elif mode == "replace-to":
        last = anchor.split("|")[1]
        j = next(k for k in range(i, len(lines)) if lines[k].startswith(last))
        lines[i:j + 1] = new
    elif mode == "before": lines[i:i] = new
    elif mode == "after": lines[i + 1:i + 1] = new
    else: sys.exit("unknown mode " + mode)
open(path, "w").write("\n".join(lines))
PY
chown ana:ana "$1"
}
