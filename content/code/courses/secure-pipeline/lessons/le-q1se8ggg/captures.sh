#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as lesson 2 leaves them (stages 1 and 2,
# one commit each, the CI server with no runs yet), plus the .venv lesson 1
# made in ~/linkbox, built here without being shown. Bandit and Semgrep are
# uninstalled first, off screen, so the lesson's `uv tool install` is a real
# install; the end of the script makes sure both are back. Every file of the
# project this lesson changes is copied out of its own fences (`place`).
# counts.py, in /tmp/scratch, is a scratch file the lesson shows with `cat`
# and deletes; its three versions are written here with `put`.
# Bandit prints the time it started, and the commit hashes differ on every
# run, because the commits made on screen carry the time they were made.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-q1se8ggg
REPORT='--format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"'
lab project 3 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
quiet 'cd linkbox && uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt'
quiet 'uv tool uninstall bandit semgrep >/dev/null 2>&1; rm -rf /tmp/scratch'

block install-bandit
run 'uv tool install bandit==1.9.4'
run 'bandit --version'

block venv
run 'bandit -q -r . --format custom --msg-template "{relpath}" | wc -l'
run 'bandit -q -r . --format custom --msg-template "{relpath}" | cut -d/ -f1-2 | sort | uniq -c | sort -rn'

block excluded
run "bandit -q -r . -x ./.venv $REPORT"

block one
run 'bandit -q -r . -x ./.venv -t B608'

block configured
place "$MD/false-positives.md" bandit.yaml
run "bandit -q -r . -c bandit.yaml $REPORT"

block scratch
run 'mkdir -p /tmp/scratch && cd /tmp/scratch'
put counts.py <<'EOF'
import sqlite3

TABLES = ("links",)


def counts(db):
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}
EOF
run 'cat counts.py'
run 'bandit -q counts.py'

block nosec-words
put counts.py <<'EOF'
import sqlite3

TABLES = ("links",)


def counts(db):
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}  # nosec B608: t is one of TABLES
EOF
run 'tail -n 1 counts.py'
run 'bandit -q counts.py; echo "exit $?"'

block nosec-reason
put counts.py <<'EOF'
import sqlite3

TABLES = ("links",)


def counts(db):
    # A table name cannot be a ? parameter, and t only ever comes from TABLES.
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}  # nosec B608
EOF
run 'tail -n 2 counts.py'
run "bandit counts.py 2>/dev/null | grep -i 'issues identified\|skipped'"
run 'cd ~/linkbox && rm -rf /tmp/scratch'

block install-semgrep
run 'uv tool install semgrep==1.182.1 2>&1 | tail -n 3'
run 'semgrep --version'

block scan
place "$MD/own-rules.md" .semgrep.yml
run 'semgrep scan --metrics=off --quiet --emacs --config .semgrep.yml .'

block push-red
place "$MD/the-build-breaks.md" ci/sast.sh
place "$MD/the-build-breaks.md" ci/stages
run 'git add .semgrep.yml bandit.yaml ci'
run 'git commit -q -m "static analysis in the pipeline"'
run 'git push ci main'

block log
run 'cat ~/ci/runs/1/logs/sast.log'

block red
place "$MD/fixing.md" tests/test_app.py
run '.venv/bin/python -m pytest -q --tb=short'

block green
place "$MD/fixing.md" app.py
run '.venv/bin/python -m pytest -q'
run 'bash ci/sast.sh; echo "exit $?"'

block low
run "bandit -q -r . -c bandit.yaml $REPORT"

block push-green
run 'git add app.py tests/test_app.py'
run 'git commit -q -m "the search takes a parameter, writes call require_token(), no debug server"'
run 'git push ci main'

block end
quiet 'command -v bandit >/dev/null || uv tool install -q bandit==1.9.4'
quiet 'command -v semgrep >/dev/null || uv tool install -q semgrep==1.182.1'
quiet 'for c in $(git log --format=%h); do docker rmi -f linkbox:$c >/dev/null 2>&1; done; rm -rf ci-logs'
exit 0
