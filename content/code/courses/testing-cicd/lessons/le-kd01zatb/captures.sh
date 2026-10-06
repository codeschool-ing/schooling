#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh
#
# PRODUCTION IS TWO DIRECTORIES AND A ROUTER, all on one machine:
# production-blue on port 8301, production-green on 8302, and ops/router.py on
# 8300 in front of them, sending each request to a side by the weights in
# ~/envs/routes.json. "The customers" are ops/load.py, which sends a fixed mix
# of twenty orders; one of them goes to CEP 57020-050, in Alagoas, which is
# the order v1.6.0 cannot answer. Nothing here asks a carrier: the
# environments name none, so prices come from the shop's table.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the project at step 12 (tag v1.6.1) in /home/ana/shipquote, by
#     ../../lab.sh, and the three artifacts listed in "artifacts", built by
#     checking out each tag in turn and running ops/build.sh;
#   - ~/envs emptied, then the config.env files that "configs" prints;
#   - in "recreate", production deployed with 1.5.0 beforehand, and stopped
#     after the block, so the router can take its port;
#   - in "blue-green", production-blue deployed with 1.5.0 and the router
#     started, before the first command shown.
#   Every process started is stopped at the end.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo, as root with HOME=/home/ana so paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
stop_all() {
  for p in "$HOME"/envs/*/pid; do [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; done
  [ -n "${R:-}" ] && kill "$R" 2>/dev/null
  true
}
stop_all
rm -rf "$HOME/envs"
bash "$LAB" stage 12 >/dev/null
cd "$HOME/shipquote" || exit 1
for t in v1.5.0 v1.6.0 v1.6.1; do git checkout -q "$t" && ops/build.sh > /dev/null; done
git checkout -q main
mkdir -p "$HOME/envs/production" "$HOME/envs/production-blue" "$HOME/envs/production-green"
printf 'SHIPQUOTE_PORT=8300\n' > "$HOME/envs/production/config.env"
for side in blue:8301 green:8302; do
  printf 'SHIPQUOTE_PORT=%s\nSHIPQUOTE_FLAGS=/home/ana/envs/flags.json\n' "${side#*:}" \
    > "$HOME/envs/production-${side%:*}/config.env"
done
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block artifacts
run 'ls dist/*.tar.gz'
run 'git log --oneline v1.5.0..v1.6.1'

block configs
run 'cat ~/envs/production-blue/config.env ~/envs/production-green/config.env'

block recreate
ops/deploy.sh production dist/shipquote-1.5.0.tar.gz > /dev/null
run 'for i in $(seq 60); do curl -s -o /dev/null -w "%{http_code} " --max-time 1 http://127.0.0.1:8300/health; sleep 0.05; done & sleep 0.5; ops/restart.sh production; wait; echo'
kill "$(cat "$HOME/envs/production/pid")"; rm -rf "$HOME/envs/production"

block blue-green
ops/deploy.sh production-blue dist/shipquote-1.5.0.tar.gz > /dev/null
printf '{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 100, "green": 0}}\n' \
  > "$HOME/envs/routes.json"
ROUTER_CONFIG=$HOME/envs/routes.json ROUTER_PORT=8300 setsid python3 ops/router.py </dev/null >/dev/null 2>&1 & R=$!
python3 -c 'import time; time.sleep(0.5)'
run 'cat ~/envs/routes.json'
run 'curl -s http://127.0.0.1:8300/version; echo'
run 'ops/deploy.sh production-green dist/shipquote-1.6.0.tar.gz'
run 'curl -s http://127.0.0.1:8300/version; echo'
run "python3 ops/load.py http://127.0.0.1:8300 2000 & sleep 1; sed -i 's/\"blue\": 100, \"green\": 0/\"blue\": 0, \"green\": 100/' ~/envs/routes.json; wait"
run 'curl -s http://127.0.0.1:8300/version; echo'

block switch-back
run "time sed -i 's/\"blue\": 0, \"green\": 100/\"blue\": 100, \"green\": 0/' ~/envs/routes.json"
run 'curl -s http://127.0.0.1:8300/version; echo'
run 'grep -c "^error" ~/envs/production-green/app.log; grep "^error" ~/envs/production-green/app.log | sort | uniq -c'
run 'curl -s "http://127.0.0.1:8302/quote?cep=57020-050&weight=700&subtotal=8990"; echo'

block canary
run "sed -i 's/\"blue\": 100, \"green\": 0/\"blue\": 90, \"green\": 10/' ~/envs/routes.json && cat ~/envs/routes.json"
run 'python3 ops/load.py http://127.0.0.1:8300 1000'

block canary-small
run 'python3 ops/load.py http://127.0.0.1:8300 100 5001'
run 'python3 ops/load.py http://127.0.0.1:8300 100 6001'
run "sed -i 's/\"blue\": 90, \"green\": 10/\"blue\": 100, \"green\": 0/' ~/envs/routes.json"

block dark-launch
run 'ops/deploy.sh production-green dist/shipquote-1.6.1.tar.gz'
run "sed -i 's/\"blue\": 100, \"green\": 0/\"blue\": 0, \"green\": 100/' ~/envs/routes.json"
run 'python3 ops/load.py http://127.0.0.1:8300 2000'
run 'ls ~/envs/flags.json'
run 'curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=c7"; echo'

block flag-on
run "echo '{\"delivery_estimate\": 10}' > ~/envs/flags.json"
run 'for c in c1 c2 c3 c4 c5 c6 c7 c8; do curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=$c"; echo; done'
run 'for i in $(seq 1000); do curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=800&customer=c$i"; echo; done | grep -c days'

block flag-wider
run "echo '{\"delivery_estimate\": 50}' > ~/envs/flags.json"
run 'for i in $(seq 1000); do curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=800&customer=c$i"; echo; done | grep -c days'
run 'for c in c3 c3 c3; do curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=$c"; echo; done'

block kill-switch
run "echo '{\"delivery_estimate\": 0}' > ~/envs/flags.json"
run 'curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=c3"; echo'
run 'curl -s http://127.0.0.1:8300/version; echo'

stop_all
