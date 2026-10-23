#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of secure-pipeline, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: nothing of the project; the lesson works in a scratch
# directory, ~/supply, which the script deletes first. pip's download cache
# is emptied beforehand, so that pip reports downloading rather than reusing
# what an earlier run fetched, as it does on a student's first try. The two
# files of the internal package are copied out of the lesson (`place`). The
# local index is Python's own web server on 127.0.0.1:8081, started and
# killed off-screen by pid. Nothing is published anywhere: the "internal"
# package exists only on this machine.
# The timings uv prints differ between runs.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-y152g8t2
bash "$COURSE/lab.sh" as sh -c 'rm -rf ~/supply ~/.cache/pip'

block venv
run 'mkdir ~/supply && cd ~/supply'
run 'uv venv --seed -q && . .venv/bin/activate'
run 'pip --version'

block download
run 'pip download -q --no-deps -d wheels blinker==1.9.0'
run 'ls wheels'
run 'pip hash wheels/blinker-1.9.0-py3-none-any.whl'

block pin
run 'echo "blinker==1.9.0 $(pip hash wheels/*.whl | tail -n 1)" > requirements.txt'
run 'cat requirements.txt'
run 'pip install --require-hashes --no-deps -r requirements.txt'
run 'pip uninstall -q -y blinker'

block unhashed
run 'pip install --require-hashes blinker==1.9.0'

block tamper
run 'mkdir -p mirror/simple/blinker'
run 'cp wheels/blinker-1.9.0-py3-none-any.whl mirror/simple/blinker/'
run 'printf "x" >> mirror/simple/blinker/blinker-1.9.0-py3-none-any.whl'
quiet 'setsid python3 -m http.server 8081 --bind 127.0.0.1 --directory mirror >/dev/null 2>&1 </dev/null & echo $! >/tmp/supply-web.pid; sleep 1'
run 'pip install --require-hashes --no-deps --index-url http://127.0.0.1:8081/simple/ -r requirements.txt'
quiet 'kill $(cat /tmp/supply-web.pid); rm -f /tmp/supply-web.pid'

block internal
place "$MD/confusion.md" "~/supply/internal/pyproject.toml"
place "$MD/confusion.md" "~/supply/internal/src/packaging/__init__.py"
run 'uv build -q --wheel -o index/simple/packaging/ internal'
run 'ls index/simple/packaging'
quiet 'setsid python3 -m http.server 8081 --bind 127.0.0.1 --directory index >/dev/null 2>&1 </dev/null & echo $! >/tmp/supply-web.pid; sleep 1'

block only-ours
run 'pip download --no-deps -d got --index-url http://127.0.0.1:8081/simple/ packaging'

block extra
run 'pip download --no-deps -d got --extra-index-url http://127.0.0.1:8081/simple/ packaging'
run 'ls got'

block uv
run 'uv pip install --dry-run --extra-index-url http://127.0.0.1:8081/simple/ packaging'
run 'uv pip install --dry-run --index-strategy unsafe-best-match --extra-index-url http://127.0.0.1:8081/simple/ packaging'
quiet 'kill $(cat /tmp/supply-web.pid); rm -f /tmp/supply-web.pid'

block end
quiet 'deactivate; cd ~ && rm -rf ~/supply'
exit 0
