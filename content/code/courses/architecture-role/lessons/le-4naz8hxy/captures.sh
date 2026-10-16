#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of architecture-role, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# enforcing.md (and the same fences in enforcing.pt.md) was copied from
# running it:
#
#   bash captures.sh
#
# Nothing is installed and nothing comes from outside the lesson. The two
# files the student writes are TAKEN FROM enforcing.md itself, so they cannot
# drift from what the lesson shows:
#
#   make-carreto.sh   the `sh` fence whose first line is "# make-carreto.sh"
#   check_imports.py  the `schooling-example` whose file is check_imports.py,
#                     its parts joined with a newline, as the copy button does
#
# Both run in a fresh temporary directory, which the prompt shows as a bare
# "$ ". A line after "$ " is what the student typed; the lines below it are
# what it printed.
#
# STAGED rather than typed, and not shown as a command in the lesson: the fix
# between the second and the third block. The lesson shows the corrected
# first line of carreto/payments/payout.py as a Python fence and asks the
# student to edit the file; here the edit is a sed that makes exactly that
# change.
#
# The exception in check_imports.py holds until 2027-03-31, so a run after
# that date prints a second violation instead of the "allowed until" line.
# That is the behaviour the lesson describes, not a fault in the capture.
#
# Recorded 2026-10-10 on Linux with Python 3.13.16, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - "$HERE/enforcing.md" "$WORK" <<'PY'
import json, pathlib, re, sys
md, work = pathlib.Path(sys.argv[1]).read_text(), pathlib.Path(sys.argv[2])
fences = re.findall(r"^```([^\n]*)\n(.*?)^```$", md, flags=re.S | re.M)
script = [body for label, body in fences
          if label == "sh" and body.startswith("# make-carreto.sh")]
examples = [json.loads(body) for label, body in fences if label == "schooling-example"]
program = [e for e in examples if e.get("file") == "check_imports.py"]
assert len(script) == 1 and len(program) == 1, "the lesson must show each file once"
(work / "make-carreto.sh").write_text(script[0])
(work / "check_imports.py").write_text(
    "\n".join(part["code"] for part in program[0]["parts"]) + "\n")
PY

cd "$WORK"
# what the student typed at a bare prompt, and everything it printed
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

block project
run 'sh make-carreto.sh'
run "find carreto -name '*.py' | sort"

block failing
printf '$ %s\n' 'python3 check_imports.py'
status=0; python3 check_imports.py 2>&1 || status=$?
printf '$ %s\n%s\n' 'echo $?' "$status"

# staged: the edit the lesson asks the student to make by hand
sed -i 's/^from carreto\.matching\.offers import/from carreto.matching.api import/' \
  carreto/payments/payout.py

block passing
run 'head -2 carreto/payments/payout.py'
printf '$ %s\n' 'python3 check_imports.py'
status=0; python3 check_imports.py 2>&1 || status=$?
printf '$ %s\n%s\n' 'echo $?' "$status"
