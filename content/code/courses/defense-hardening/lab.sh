#!/usr/bin/env bash
# The lab every transcript in defense-hardening was recorded on, and how it is
# built: by the very file the student builds theirs with.
#
# THIS FILE BUILDS NOTHING ITSELF. The student never receives it (C-38, C-40).
# Lesson 1, section "The script that builds the lab", shows hostlab.sh whole,
# as an example the student copies. On every call this file extracts that
# script from the lesson's Markdown, byte for byte as the copy button hands it
# over, into /var/tmp/hostlab/hostlab.sh, and runs it. A capture therefore
# cannot be made with a lab the student was not shown, and an edit to the
# lesson is an edit to the lab.
#
#   sudo useradd -m -s /bin/bash ana          # once: the user in the transcripts
#   sudo bash lab.sh build                    # once: the two images
#   sudo bash lab.sh up [MACHINE...] | down
#   sudo bash lab.sh exec MACHINE USER 'command'
#   sudo bash lab.sh path                     # where the extracted script is
#
# The student runs hostlab.sh with sudo from their own account, which becomes
# their account on every machine. The transcripts were recorded as ana, so
# this file says SUDO_USER=ana whoever runs it.
#
# WHAT DIFFERS FROM A STUDENT'S COMPUTER, and is said in lesson 1:
#   - the recording computer is itself a virtual machine with no IPv6, so no
#     listener in any transcript has a [::] line. On a computer with IPv6 each
#     one appears twice.
#   - its /run is not a tmpfs, so systemd-nspawn prints "Attempted to remove
#     disk file system under /run/systemd/nspawn/propagate/..." on every call
#     of in_image. A student's Ubuntu does not. No transcript shows it.
#   - the archive moves: a package version in a transcript is the one the
#     archive served on the day the capture ran (October 2026).
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
out=/var/tmp/hostlab

id ana >/dev/null 2>&1 || { echo "create the user first: useradd -m -s /bin/bash ana" >&2; exit 1; }
mkdir -p "$out"
python3 - "$here/lessons" "$out" <<'PY'
import glob, json, os, re, sys
lessons, out = sys.argv[1], sys.argv[2]
want = {"hostlab.sh"}
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

export SUDO_USER=ana TZ=America/Sao_Paulo
case "${1:-}" in
  path) echo "$out/hostlab.sh" ;;
  *) exec bash "$out/hostlab.sh" "$@" ;;
esac
