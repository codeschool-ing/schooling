#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh
#
# THE SAME PRODUCTION AS LESSON 10: production-blue on port 8301,
# production-green on 8302, and ops/router.py on 8300 in front of them. In
# "rollback" and after it, the router is gone and production is one
# environment on 8300 again, as in lesson 7, because rollback.sh works on one
# environment's `current` and `previous` links.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the project at step 12 (tag v1.6.1) in /home/ana/shipquote, by
#     ../../lab.sh, with its virtual environment; the three artifacts of
#     lesson 10, built by checking out each tag in turn and running
#     ops/build.sh; ~/envs emptied;
#   - in "canary-abort", blue deployed with 1.5.0, green with 1.6.0, the
#     weights at 100 and 0, and the router started;
#   - in "rollback", the router and both sides stopped, and production
#     deployed with 1.5.0 and then with 1.6.0, in that order;
#   - in "no-previous", the staging config.env (one line, its port).
#   Every process started is stopped at the end.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16, pytest 9.1.1 and
# curl 8.5.0, TZ=America/Sao_Paulo, as root with HOME=/home/ana so paths read
# as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
stop_all() {
  for p in "$HOME"/envs/*/pid; do [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; done
  [ -n "${R:-}" ] && kill "$R" 2>/dev/null
  true
}
stop_all
rm -rf "$HOME/envs" /tmp/pytest-of-ana
bash "$LAB" stage 12 >/dev/null && bash "$LAB" venv "$HOME/shipquote" >/dev/null 2>&1
export PATH="$HOME/shipquote/.venv/bin:$PATH"
cd "$HOME/shipquote" || exit 1
for t in v1.5.0 v1.6.0 v1.6.1; do git checkout -q "$t" && ops/build.sh > /dev/null; done
git checkout -q main
mkdir -p "$HOME/envs/production-blue" "$HOME/envs/production-green"
printf 'SHIPQUOTE_PORT=8301\n' > "$HOME/envs/production-blue/config.env"
printf 'SHIPQUOTE_PORT=8302\n' > "$HOME/envs/production-green/config.env"
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block canary-abort
ops/deploy.sh production-blue dist/shipquote-1.5.0.tar.gz > /dev/null
ops/deploy.sh production-green dist/shipquote-1.6.0.tar.gz > /dev/null
printf '{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 100, "green": 0}}\n' \
  > "$HOME/envs/routes.json"
ROUTER_CONFIG=$HOME/envs/routes.json ROUTER_PORT=8300 setsid python3 ops/router.py </dev/null >/dev/null 2>&1 & R=$!
python3 -c 'import time; time.sleep(0.5)'
run 'curl -s http://127.0.0.1:8302/version; echo'
run 'python3 ops/canary.py ~/envs/routes.json http://127.0.0.1:8300; echo "exit $?"'
run 'cat ~/envs/routes.json; echo'

block canary-promote
run 'ops/deploy.sh production-green dist/shipquote-1.6.1.tar.gz'
run 'python3 ops/canary.py ~/envs/routes.json http://127.0.0.1:8300; echo "exit $?"'
run 'cat ~/envs/routes.json; echo'

block rollback
stop_all; R=
rm -rf "$HOME/envs"
mkdir -p "$HOME/envs/production"
printf 'SHIPQUOTE_PORT=8300\n' > "$HOME/envs/production/config.env"
ops/deploy.sh production dist/shipquote-1.5.0.tar.gz > /dev/null
ops/deploy.sh production dist/shipquote-1.6.0.tar.gz > /dev/null
run 'readlink ~/envs/production/current ~/envs/production/previous'
run 'curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990"; echo'
run 'time ops/rollback.sh production'
run 'readlink ~/envs/production/current ~/envs/production/previous'
run 'curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990"; echo'

block rollback-twice
run 'ops/rollback.sh production'
run 'readlink ~/envs/production/current ~/envs/production/previous'
run 'ops/rollback.sh production'

block no-previous
mkdir -p "$HOME/envs/staging"
printf 'SHIPQUOTE_PORT=8200\n' > "$HOME/envs/staging/config.env"
run 'ops/deploy.sh staging dist/shipquote-1.6.1.tar.gz'
run 'ops/rollback.sh staging; echo "exit $?"'
run 'ls ~/envs/staging/releases'

block regression
rm -rf /tmp/pytest-of-ana
run 'git diff v1.6.0 v1.6.1 -- shipquote/quote.py'
run 'git checkout -q v1.6.0 -- shipquote/quote.py && python -m pytest tests/test_quote.py -q -k every_state'
run 'git checkout -q HEAD -- shipquote/quote.py && python -m pytest tests/test_quote.py -q -k every_state'

stop_all
