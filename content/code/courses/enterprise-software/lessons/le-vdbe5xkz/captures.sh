#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of enterprise-software, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# reconciliation.md (and the same fences in reconciliation.pt.md) was copied
# from running it:
#
#   bash captures.sh
#
# Nothing is installed and nothing comes from outside the lesson. The two
# files the student saves are TAKEN FROM reconciliation.md itself, so they
# cannot drift from what the lesson shows:
#
#   make-extracts.sh  the `sh` fence whose first line is "# make-extracts.sh"
#   reconcile.py      the `schooling-example` whose file is reconcile.py,
#                     its parts joined with a newline, as the copy button does
#
# Both run in a fresh temporary directory, which the prompt shows as a bare
# "$ ". A line after "$ " is what the student typed; the lines below it are
# what it printed.
#
# Nothing is staged: the faulty target is one of the three files the
# student's own make-extracts.sh writes, so every command below is one the
# student can type, in this order.
#
# The output is deterministic: fixed data, no clock, no randomness.
#
# Recorded 2026-10-23 on Linux with Python 3.13.16, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - "$HERE/reconciliation.md" "$WORK" <<'PY'
import json, pathlib, re, sys
md, work = pathlib.Path(sys.argv[1]).read_text(), pathlib.Path(sys.argv[2])
fences = re.findall(r"^```([^\n]*)\n(.*?)^```$", md, flags=re.S | re.M)
script = [body for label, body in fences
          if label == "sh" and body.startswith("# make-extracts.sh")]
examples = [json.loads(body) for label, body in fences if label == "schooling-example"]
program = [e for e in examples if e.get("file") == "reconcile.py"]
assert len(script) == 1 and len(program) == 1, "the lesson must show each file once"
(work / "make-extracts.sh").write_text(script[0])
(work / "reconcile.py").write_text(
    "\n".join(part["code"] for part in program[0]["parts"]) + "\n")
PY

cd "$WORK"
# what the student typed at a bare prompt, and everything it printed
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }
status() {
  printf '$ %s\n' "$1"
  local s=0; bash -c "$1" 2>&1 || s=$?
  printf '$ %s\n%s\n' 'echo $?' "$s"
}

block files
run 'sh make-extracts.sh'
run 'head -3 coleta.csv target.csv'

block clean
status 'python3 reconcile.py coleta.csv target.csv'

block faulty
status 'python3 reconcile.py coleta.csv target-faulty.csv'
