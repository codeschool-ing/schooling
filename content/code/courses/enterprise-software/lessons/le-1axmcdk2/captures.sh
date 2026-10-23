#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of enterprise-software, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# by-file.md (and the same fences in by-file.pt.md) was copied from running it:
#
#   bash captures.sh
#
# Nothing is installed and nothing comes from outside the lesson. The one file
# the student writes is TAKEN FROM by-file.md itself, so it cannot drift from
# what the lesson shows:
#
#   coleta_file.py   the `schooling-example` whose file is coleta_file.py,
#                    its parts joined with a newline, as the copy button does
#
# It runs in a fresh temporary directory, which the prompt shows as a bare
# "$ ". A line after "$ " is what the student typed; the lines below it are
# what it printed. The program's data is fixed (2026-10-22, six farms), so
# every run prints the same thing.
#
# Nothing is staged out of sight: the damaged copy is made by the `sed '5d'`
# shown in the lesson, which the lesson also tells the student how to do by
# hand in an editor.
#
# Recorded 2026-10-23 on Linux with Python 3.13.16, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - "$HERE/by-file.md" "$WORK" <<'PY'
import json, pathlib, re, sys
md, work = pathlib.Path(sys.argv[1]).read_text(), pathlib.Path(sys.argv[2])
fences = re.findall(r"^```([^\n]*)\n(.*?)^```$", md, flags=re.S | re.M)
examples = [json.loads(body) for label, body in fences if label == "schooling-example"]
program = [e for e in examples if e.get("file") == "coleta_file.py"]
assert len(program) == 1, "the lesson must show the program once"
(work / "coleta_file.py").write_text(
    "\n".join(part["code"] for part in program[0]["parts"]) + "\n")
PY

cd "$WORK"
# what the student typed at a bare prompt, and everything it printed
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
status() { printf '$ %s\n' "$1"; s=0; bash -c "$1" 2>&1 || s=$?; printf '$ %s\n%s\n' 'echo $?' "$s"; }
block() { printf '##### %s\n' "$1"; }

block write
run 'python3 coleta_file.py write'
run 'ls'

block cat
run 'cat coleta-20261022-0001.txt'

block check
status 'python3 coleta_file.py check coleta-20261022-0001.txt'

block damaged
run "sed '5d' coleta-20261022-0001.txt > damaged.txt"
status 'python3 coleta_file.py check damaged.txt'
