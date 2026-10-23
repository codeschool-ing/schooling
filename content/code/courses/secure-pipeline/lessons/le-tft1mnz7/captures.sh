#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as lesson 1 leaves them (its two commits'
# files in one commit, the CI server with no runs yet), plus the .venv lesson 1
# made in ~/linkbox, built here without being shown. The three files this
# lesson changes are copied out of its own fences (`place`), so what runs is
# what the student saves. ci/unguarded.sh is a scratch copy the lesson makes
# on screen and deletes.
# The timings differ on every run, and so do the commit hashes, because the
# commit made on screen carries the time it was made. The cached build is
# cached because `lab project` built the same files a moment before.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-tft1mnz7
lab project 2 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }
quiet 'cd linkbox && uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt'
quiet 'docker rmi -f linkbox:nightly linkbox:dev >/dev/null 2>&1; rm -rf /tmp/linkbox-run /tmp/nightly'

block dirty
run 'ci/pipeline.sh'

block clean
run 'rm -rf /tmp/linkbox-run && git clone -q ~/linkbox /tmp/linkbox-run && /tmp/linkbox-run/ci/pipeline.sh'

block pieces
run 'cd /tmp/linkbox-run && rm -rf .venv'
run 'time uv venv -q .venv'
run 'time uv pip install -q -r requirements.txt -r requirements-dev.txt'
run 'time .venv/bin/python -m pytest -q'
run 'time docker build -q -t linkbox:dev .'
run 'cd ~/linkbox && rm -rf /tmp/linkbox-run'

block diff
place "$MD/same-script.md" ci/pipeline.sh
run "git diff ci/pipeline.sh | grep '^[-+]'"

block unguarded
run "grep -v 'no list of stages' ci/pipeline.sh > ci/unguarded.sh"
run 'bash ci/unguarded.sh ci/stagse; echo "exit $?"'
run 'rm ci/unguarded.sh'

block guarded
run 'ci/pipeline.sh ci/stagse; echo "exit $?"'

block nightly-local
place "$MD/nightly.md" ci/nightly
place "$MD/nightly.md" ci/rebuild.sh
run 'ci/pipeline.sh ci/nightly'
run 'docker images linkbox:nightly'

block push
run 'git add ci'
run 'git status --short'
run 'git commit -q -m "the pipeline takes a list: every push, and the nightly run"'
run 'git push ci main'

block nightly-server
run 'rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly && /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly'
run 'rm -rf /tmp/nightly'

block end
quiet 'docker rmi -f linkbox:nightly linkbox:dev linkbox:$(git rev-parse --short HEAD) >/dev/null 2>&1; rm -rf ci-logs'
exit 0
