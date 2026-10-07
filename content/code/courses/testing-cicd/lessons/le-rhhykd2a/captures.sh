#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh           # needs pipx and the network, for uv and PyPI
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. Section `the-lab` installs
# git, curl, jq, pipx and uv; section `the-project` shows every file of the
# project at step 5 whole, and `../../lab.sh shown` fails this script before
# its first block if any of them is not the file ../../lab.sh wrote. What is
# STAGED rather than typed:
#   - the project, rebuilt by ../../lab.sh at step 5 in /home/ana/shipquote and
#     then stripped of its history, so that "first-commit" makes the one
#     commit the lesson asks for, with a fixed date so the hash is the same on
#     every run;
#   - uv, installed with pipx into /home/ana/.local, its cache emptied before
#     "venv", and the blocks of
#     `the-lab` and `the-project` run with only that and /usr/bin on PATH, as
#     a new terminal on a fresh machine would. This machine's own python3 is
#     3.13.16, so `uv venv -p 3.13` finds it rather than downloading one, which
#     the section says;
#   - in "fail-identity", a git with no global configuration (HOME pointed at
#     an empty directory for that one command); in "fail-indent", one line of
#     quote.py re-indented with sed and restored with git checkout; in
#     "fail-port", a first server started in the background and stopped after;
#   - the two deliberate bugs in "first-fail" and "boundary", each written into
#     a file with sed just before the run that shows it and taken out again
#     with `git checkout` right after.
#
# Recorded 2026-10-06 (the setup blocks 2026-10-07) on Ubuntu 24.04 with Python
# 3.13.16, pytest 9.1.1, TZ=America/Sao_Paulo. Run as root with HOME=/home/ana,
# so the paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
bash "$LAB" stage 5 >/dev/null || exit 1
bash "$LAB" shown "$HERE" || exit 1
cd "$HOME/shipquote" || exit 1
rm -rf .git
block() { printf '##### %s\n' "$1"; }
# A new terminal on a fresh machine: /usr/bin, and ~/.local/bin once pipx has
# put uv there. UV_NATIVE_TLS is this sandbox's own setting under its old name.
CLEAN="env -u VIRTUAL_ENV -u UV_NATIVE_TLS UV_SYSTEM_CERTS=1 PATH=/usr/bin:/bin"
[ -x "$HOME/.local/bin/uv" ] || pipx install uv >/dev/null 2>&1 || exit 1
fresh() { printf 'ana@laptop:%s$ %s\n' "$(dirs +0)" "$*"; $CLEAN:$HOME/.local/bin bash -c "$*" 2>&1; }
git config --global user.name "Ana Lima"
git config --global user.email ana@example.org
git config --global init.defaultBranch main

block setup-tools
cd "$HOME"
fresh 'uv --version'
fresh 'git --version'
fresh 'jq --version'
cd "$HOME/shipquote"

block venv
# uv's cache emptied first, so the install downloads what a fresh machine would
export UV_CACHE_DIR=/tmp/uv-cache-l1; rm -rf "$UV_CACHE_DIR"
CLEAN="env -u VIRTUAL_ENV -u UV_NATIVE_TLS UV_SYSTEM_CERTS=1 UV_CACHE_DIR=$UV_CACHE_DIR PATH=/usr/bin:/bin"
fresh 'uv venv -p 3.13'
printf 'ana@laptop:~/shipquote$ source .venv/bin/activate\n'
fresh 'uv pip install -r requirements-dev.txt'
[ -x .venv/bin/pytest ] || { echo "captures: the venv block failed" >&2; exit 1; }
export PATH="$HOME/shipquote/.venv/bin:$PATH" VIRTUAL_ENV="$HOME/shipquote/.venv"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }

block first-suite
run 'python -m pytest -q'

block fail-identity
# git guesses an address from the login name and the host name before it
# refuses, so this one command runs as a real user ana, on a host called
# laptop, in a copy of the project, with no configuration anywhere.
id ana >/dev/null 2>&1 || useradd -M -d /home/ana -s /bin/bash ana
was=$(hostname); hostname laptop
rm -rf /tmp/identity && mkdir -p /tmp/identity/home && cp -r . /tmp/identity/shipquote
chown -R ana /tmp/identity
printf 'ana@laptop:~/shipquote$ %s\n' 'git commit -m "shipquote as the course begins"'
(cd /tmp/identity/shipquote && runuser -u ana -- env -i HOME=/tmp/identity/home PATH=/usr/bin:/bin \
  bash -c 'git init -q && git add . && git commit -q -m "shipquote as the course begins"' 2>&1)
hostname "$was"; rm -rf /tmp/identity

block first-commit
run 'git init'
run 'git add .'
GIT_AUTHOR_DATE=2026-10-07T09:00:00-03:00 GIT_COMMITTER_DATE=2026-10-07T09:00:00-03:00 \
  run 'git commit -q -m "shipquote as the course begins"'
run 'git log --oneline'

block fail-path
cd "$HOME"
printf 'ana@laptop:~$ uv --version\n'; $CLEAN bash -c 'uv --version' 2>&1
cd "$HOME/shipquote"

block fail-pytest
printf 'ana@laptop:~/shipquote$ python -m pytest -q\n'; $CLEAN bash -c 'python -m pytest -q' 2>&1

block fail-indent
sed -i 's/^    zone = zone_of(cep)/  zone = zone_of(cep)/' shipquote/quote.py
run 'python -m pytest -q'
git checkout -q shipquote/quote.py

block fail-port
SHIPQUOTE_PORT=8080 setsid python -m shipquote.app >/tmp/shipquote-l1.log 2>&1 </dev/null &
first=$!
sleep 1
run 'SHIPQUOTE_PORT=8080 python -m shipquote.app'
run 'ss -ltnp | grep 8080'
kill "$first"
sleep 0.5

block first-run
run 'python -m pytest tests/test_money.py -v'

block first-fail
sed -i 's/{centavos:02d}/{centavos}/' shipquote/money.py
run 'python -m pytest tests/test_money.py'
git checkout -q shipquote/money.py

block float
run "python3 -c 'print(0.1 + 0.2 == 0.3, 0.1 + 0.2)'"
run "python3 -c 'print(10 + 20 == 30)'"

block unit
run 'python -m pytest tests/test_quote.py -v'

block integration
run 'python -m pytest -m integration -v'

block functional-by-hand
SHIPQUOTE_PORT=8080 setsid python -m shipquote.app >/tmp/shipquote-l1.log 2>&1 </dev/null &
pid=$!
sleep 1
run "curl -s 'http://127.0.0.1:8080/quote?cep=01310-100&weight=1200&subtotal=5000'; echo"
run "curl -s -i 'http://127.0.0.1:8080/quote?cep=abc&weight=1200'; echo"
kill "$pid"

block functional
run 'python -m pytest -m functional -v'

block acceptance
run 'python -m pytest -m acceptance -v'

block layers
run 'python -m pytest -q -m "not integration and not functional and not acceptance"'
run 'python -m pytest -q -m "integration or functional or acceptance"'
run 'python -m pytest -q --durations=4'

block boundary
sed -i 's/subtotal_cents >= FREE_FROM/subtotal_cents > FREE_FROM/' shipquote/quote.py
run 'python -m pytest tests/test_quote.py -q'
git checkout -q shipquote/quote.py

block select
run 'python -m pytest --collect-only -q -m "not functional and not acceptance" | tail -1'
run 'python -m pytest -q -k free'
run 'python -m pytest -q -m smoke; echo "exit status $?"'
