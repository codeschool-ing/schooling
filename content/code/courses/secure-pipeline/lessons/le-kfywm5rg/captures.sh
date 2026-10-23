#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: ~/linkbox and ~/ci as they stand at the end of lesson 3
# (three commits with fixed dates, and a CI server with no runs yet). Every
# file the lesson changes is copied out of the lesson's own fences (`place`),
# so what runs here is what the student saves. The image ids, the container
# and network ids, the Date header and the stage timings differ on every run.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-kfywm5rg
lab project 4 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }

block build
run 'cd linkbox'
run 'bash ci/build.sh'

block staging
run 'docker network create linkbox-staging'
run 'docker run -d --rm --name linkbox-app --network linkbox-staging linkbox:dev'
quiet 'sleep 2'
run 'docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -sI http://linkbox-app:8000/'
run 'curl -sS http://127.0.0.1:8000/'

block baseline
run 'docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 zap-baseline.py -t http://linkbox-app:8000 -z -silent > /tmp/baseline.log; echo "exit status $?"'
run 'grep -v ^PASS /tmp/baseline.log'

block staging-down
run 'docker rm -f linkbox-app && docker network rm linkbox-staging'

block rules
place "$MD/the-rules.md" ci/zap-rules.conf
place "$MD/the-rules.md" ci/dast.sh
run 'bash ci/dast.sh > /tmp/dast.log; echo "exit status $?"'
run 'grep -v ^PASS /tmp/dast.log'

block test-fails
place "$MD/headers.md" tests/test_app.py
run 'uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt'
run '.venv/bin/python -m pytest -q --tb=short'

block test-passes
place "$MD/headers.md" app.py
run '.venv/bin/python -m pytest -q'

block rescan
run 'bash ci/build.sh'
run 'bash ci/dast.sh > /tmp/dast.log; echo "exit status $?"'
run 'grep -v ^PASS /tmp/dast.log'

block attribute
quiet 'docker network create linkbox-staging >/dev/null && docker run -d --rm --name linkbox-app --network linkbox-staging linkbox:dev >/dev/null && sleep 2'
run 'docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -sI http://linkbox-app:8000/nothing-here'
run 'docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -s "http://linkbox-app:8000/search?q=ZAP"'
run 'docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -s "http://linkbox-app:8000/search?q=a%22b"'
quiet 'docker rm -f linkbox-app >/dev/null; docker network rm linkbox-staging >/dev/null'

block commit
place "$MD/nightly.md" ci/nightly
run 'git add -A'
run 'git status --short'
run 'git commit -q -m "the security headers the baseline scan asked for, and the scan in the nightly run"'
run 'git push ci main'

block nightly
run 'ci/pipeline.sh ci/nightly'
run 'grep -v ^PASS ci-logs/dast.log'

block end
quiet 'rm -f /tmp/dast.log /tmp/baseline.log'
docker rm -f linkbox-app >/dev/null 2>&1
docker network rm linkbox-staging >/dev/null 2>&1
docker rmi -f $(docker images -q linkbox) >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1
exit 0
