#!/usr/bin/env bash
# The network every transcript in this course was recorded on, built from the
# very files lesson 1 shows the student.
#
# THE LAB IS IN THE LESSON, NOT HERE. Lesson 1 prints four files whole, one
# `bash` fence each, every one opening with a comment that names it:
# ~/netlab/netlab, dns.sh, web.sh and services.sh. This script copies those
# fences out of the lesson's .md files into a folder and runs netlab from it,
# so the network a capture ran on is the network a student types in. A file
# missing from the lesson, or shown twice, stops it before anything is built.
#
#   sudo bash lab.sh up | reset | down
#   sudo bash lab.sh exec HOST USER 'command'
#   sudo bash lab.sh shell HOST [USER]
#   sudo bash lab.sh plug HOST SEGMENT ADDRESS/PREFIX MAC
#
# Recorded on Ubuntu 24.04, with the packages lesson 1 installs.
set -euo pipefail

HERE=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
LESSON1=$HERE/lessons/le-cj7pxg3p
OUT=${NETLAB_DIR:-/var/tmp/netlab}

mkdir -p "$OUT"
python3 - "$LESSON1" "$OUT" <<'PY'
import glob, os, re, sys
lesson, out = sys.argv[1], sys.argv[2]
want = {"netlab", "dns.sh", "web.sh", "services.sh"}
found = {}
for md in sorted(glob.glob(os.path.join(lesson, "*.md"))):
    if md.endswith(".pt.md"):
        continue
    text = open(md, encoding="utf-8").read()
    for body in re.findall(r"^```bash\n(.*?)^```$", text, re.S | re.M):
        m = re.search(r"^# ~/netlab/([\w.]+):", "\n".join(body.split("\n")[:2]), re.M)
        if not m:
            continue
        name = m.group(1)
        if name in found:
            sys.exit(f"~/netlab/{name} is shown twice in lesson 1 ({found[name][0]} and {md})")
        found[name] = (md, body)
missing = want - set(found)
if missing:
    sys.exit("lesson 1 does not show " + ", ".join(sorted(missing)))
for name, (_, body) in found.items():
    with open(os.path.join(out, name), "w", encoding="utf-8") as f:
        f.write(body)
PY
exec bash "$OUT/netlab" "$@"
