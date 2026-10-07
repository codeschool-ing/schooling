#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh           # needs uv, Python 3.11, 3.12 and 3.13 through
#                              # uv, and the network the first time
#
# THE CI IN THIS LESSON IS THE LAB'S OWN, a git post-receive hook written by
# `lab.sh ci`, shown whole in the section "what-ci-is" with the commands that
# make its bare repository; `../../lab.sh shown` fails this script before its
# first block if the hook shown is not the hook written. The test files of
# "untracked" and "flaky" are written from their sections' own blocks. It runs on the
# same machine as Ana's clone, which a hosted CI does not; lesson 6 reads a
# hosted one.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the project, rebuilt by ../../lab.sh at step 7 in /home/ana/shipquote,
#     with its virtual environment, and ~/ci rebuilt empty by `lab.sh ci`;
#   - the commits pushed in "untracked", "matrix-fail" and "matrix-fix" are
#     made here with fixed dates, from the edits each section shows;
#   - in "cache-cold", uv's cache pointed at an empty directory;
#   - in "flaky", the test file shown in that section, written and deleted.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.11.15, 3.12.13 and
# 3.13.16 from uv, pytest 9.1.1, TZ=America/Sao_Paulo. Run as root with
# HOME=/home/ana and USER=ana, so the paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
bash "$LAB" stage 7 >/dev/null && bash "$LAB" venv "$HOME/shipquote" >/dev/null 2>&1
bash "$LAB" ci "$HOME/ci"
bash "$LAB" shown "$HERE" - -clean-checkout -flaky || exit 1
cd "$HOME/shipquote" || exit 1
export PATH="$HOME/shipquote/.venv/bin:/root/.local/bin:$PATH"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
commit() { GIT_AUTHOR_DATE=$1 GIT_COMMITTER_DATE=$1 git commit -q -m "$2"; }

block first-push
run 'git remote add origin ~/ci/shipquote.git'
run 'git push -u origin main'

block untracked
bash "$LAB" fence "$HERE/clean-checkout.md" tests/test_carriers.py > tests/test_carriers.py || exit 1
printf 'name,base_cents\nCorreios,1290\nJadlog,1450\n' > tests/data/carriers.csv
git add tests/test_carriers.py
commit 2026-10-01T10:15:00-03:00 'Check every carrier has a positive base price'
run 'python -m pytest -q tests/test_carriers.py'
run 'git status --short'
run 'git push'
rm tests/data/carriers.csv
git rm -q tests/test_carriers.py
commit 2026-10-01T10:30:00-03:00 'Remove the carrier test until its data is committed'
git push -q 2>/dev/null

block branch
run 'git switch -q -c try-new-rounding && git push -u origin try-new-rounding 2>&1 | grep -E "^remote: ci|->"'
git switch -q main

block matrix-fail
python3 - <<'PY'
p = "shipquote/dispatch.py"
s = open(p).read()
s = s.replace("from zoneinfo import ZoneInfo\n\nWAREHOUSE = ZoneInfo(\"America/Sao_Paulo\")\n", "")
s = s.replace("datetime.fromtimestamp(ordered_at, WAREHOUSE)", "datetime.fromtimestamp(ordered_at)")
open(p, "w").write(s)
PY
run 'git diff'
run 'python -m pytest -q tests/test_dispatch.py'
git add -A
commit 2026-10-02T09:00:00-03:00 'Read the order time in local time, no zone table needed'
run 'git push'

block artifacts
run 'ls ~/ci/runs/'
run 'ls ~/ci/runs/4/'
run 'grep -E "^(E |FAILED)" ~/ci/runs/4/py3.13-UTC.log'

block matrix-fix
GIT_AUTHOR_DATE=2026-10-02T09:20:00-03:00 GIT_COMMITTER_DATE=2026-10-02T09:20:00-03:00 git revert --no-edit HEAD >/dev/null
run 'git log --oneline -3'
run 'time git push'

block pipe
run 'python -m pytest -q -m smoke | tee run.log; echo "exit status $?"'
run 'set -o pipefail; python -m pytest -q -m smoke | tee run.log; echo "exit status $?"'
rm -f run.log

block cache-cold
export UV_CACHE_DIR=/tmp/uv-cold
rm -rf /tmp/uv-cold
run 'time (uv venv -q -p 3.13 /tmp/v1 && VIRTUAL_ENV=/tmp/v1 uv pip install -q -r requirements-dev.txt)'
run 'time (uv venv -q -p 3.13 /tmp/v2 && VIRTUAL_ENV=/tmp/v2 uv pip install -q -r requirements-dev.txt)'
run 'du -sh /tmp/uv-cold'
rm -rf /tmp/v1 /tmp/v2 /tmp/uv-cold
unset UV_CACHE_DIR

block flaky
bash "$LAB" fence "$HERE/flaky.md" tests/test_zones_seen.py > tests/test_zones_seen.py || exit 1
run 'for i in 1 2 3 4 5 6 7 8 9 10; do python -m pytest -q tests/test_zones_seen.py | tail -1; done | sed "s/ in .*//" | sort | uniq -c'
run 'for i in 1 2 3 4 5 6 7 8 9 10; do PYTHONHASHSEED=0 python -m pytest -q tests/test_zones_seen.py | tail -1; done | sed "s/ in .*//" | sort | uniq -c'
rm tests/test_zones_seen.py

block timing
run 'for f in ~/ci/runs/5/*.xml; do grep -o "<testsuite [^>]*>" $f | grep -oE "(tests|time)=\"[0-9.]+\"" | tr "\n" " "; echo "$(basename $f .xml)"; done'
