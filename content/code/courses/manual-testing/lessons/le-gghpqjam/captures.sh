#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: boxoffice.py is the block of
# lesson 1 section `the-app`, which ../../lab.sh app extracts, and smoke.sh is
# the block of section `running-smoke` under the sentence "Save it as
# `smoke.sh`", extracted below the same way, so the script that runs here is
# the one the student copies. What is STAGED rather than typed:
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, TZ=America/Sao_Paulo, and stopped by lab.sh before
#     "smoke-fail", which stands for a build that did not come up;
#   - HOME is a fresh temporary directory standing for /home/ana, so the
#     prompt reads as Ana's and two captures never share a boxoffice.py.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16, curl 8.5.0 and
# dash as sh.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
MD=$HERE/running-smoke.md
source "$LAB" lib
HOME=$(mktemp -d); export HOME
APP=$HOME/boxoffice
bash "$LAB" app "$APP" || exit 1
python3 - "$MD" "$APP/smoke.sh" <<'PY' || { echo "no smoke.sh in running-smoke.md" >&2; exit 1; }
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r"Save it as `smoke\.sh`[^\n]*\n+```sh\n(.*?)^```$", text, re.S | re.M)
if not m:
    sys.exit(1)
pathlib.Path(sys.argv[2]).write_text(m.group(1))
PY
bash "$LAB" serve "$APP" || exit 1
cd "$APP" || exit 1

block smoke-pass
run 'sh smoke.sh; echo $?'

block left-behind
run "curl -s http://127.0.0.1:8000/ | grep -o 'Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*'"

block smoke-fail
bash "$LAB" stop
run 'sh smoke.sh; echo $?'
run 'curl http://127.0.0.1:8000/health'
