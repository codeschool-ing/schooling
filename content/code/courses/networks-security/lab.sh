#!/usr/bin/env bash
# The network every transcript in this course was recorded on, and how it is
# built: by the very files the student builds it with.
#
# THIS FILE BUILDS NOTHING ITSELF. The student never receives it (C-38, C-40).
# Lesson 1 shows nslab.sh whole, as an example the student copies, and three
# later lessons add one file each: dnssec.sh (lesson 8), inline.sh (lesson 14)
# and nac.sh (lesson 22). On every call this file extracts those four from the
# lessons' Markdown, byte for byte as the copy button hands them over, into
# /var/tmp/nslab/, and runs them. A capture therefore cannot be made with a lab
# the student was not shown, and an edit to the lesson is an edit to the lab.
#
#   sudo useradd -m -s /bin/bash ana       # once: the user in the transcripts
#   sudo ln -sf "$PWD/lab.sh" /var/tmp/nslab.sh
#   sudo bash /var/tmp/nslab.sh reset | down
#   sudo bash /var/tmp/nslab.sh exec HOST USER 'command'
#   sudo bash /var/tmp/nslab.sh plug HOST SEGMENT ADDRESS/PREFIX MAC
#   sudo bash /var/tmp/nslab.sh dnssec | inline | nac
#
# The student runs nslab.sh with sudo from their own account, which is the
# user on every machine. The transcripts were recorded as ana, so this file
# says SUDO_USER=ana whoever runs it.
#
# Recorded on Ubuntu 24.04. Its python3 is 3.12, and a capture made with any
# other would print what a student's machine does not; this file refuses one.
set -euo pipefail

here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
out=/var/tmp/nslab

python3 -c 'import sys; sys.exit(sys.version_info[:2] != (3, 12))' || {
  echo "python3 is $(python3 -V 2>&1); the course was recorded with Ubuntu 24.04's 3.12" >&2; exit 1; }
id ana >/dev/null 2>&1 || { echo "create the user first: useradd -m -s /bin/bash ana" >&2; exit 1; }

mkdir -p "$out"
python3 - "$here/lessons" "$out" <<'PY'
import glob, json, os, re, sys
lessons, out = sys.argv[1], sys.argv[2]
want = {"nslab.sh", "dnssec.sh", "inline.sh", "nac.sh"}
found = {}
for md in sorted(glob.glob(os.path.join(lessons, "*", "*.md"))):
    if md.endswith(".pt.md"):
        continue
    for block in re.findall(r"^```schooling-example\n(.*?)\n```$", open(md).read(), re.S | re.M):
        ex = json.loads(block)
        name = ex.get("file")
        if name not in want:
            continue
        if name in found:
            sys.exit(f"{name} is shown twice: {found[name]} and {md}")
        found[name] = md
        with open(os.path.join(out, name), "w") as f:
            f.write("\n".join(p["code"] for p in ex["parts"]) + "\n")
missing = want - found.keys()
if missing:
    sys.exit("no lesson shows " + ", ".join(sorted(missing)))
PY

export SUDO_USER=ana
case "${1:-}" in
  dnssec|inline|nac) exec bash "$out/$1.sh" ;;
  *) exec bash "$out/nslab.sh" "$@" ;;
esac
