#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh
#
# THE ENVIRONMENTS ARE DIRECTORIES ON ONE MACHINE, as in lesson 7: dev on
# port 8100, staging on 8200, production on 8300. THE TWO CARRIERS ARE THE
# LAB'S STAND-IN (`lab.sh carrier`), started twice: a "sandbox" on 9091 and a
# "live" one on 9092, each accepting its own token. Both tokens are values the
# lab made up and open nothing; the sections print the configuration with the
# token lines filtered out, and lesson 9 is about why.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the project at step 10 (tag v1.5.0) in /home/ana/shipquote, by
#     ../../lab.sh; ~/envs emptied; the three config.env files, whose
#     non-secret lines the section "three-configs" prints;
#   - in "drift", one line of the deployed staging copy edited with sed, as
#     somebody fixing it by hand would; the section shows the edit's effect;
#   - in "preview", the environment's directory and config.
#   Every process started is stopped at the end.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16, TZ=America/Sao_Paulo,
# as root with HOME=/home/ana so paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
stop_all() {
  for p in "$HOME"/envs/*/pid; do [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; done
  [ -n "${C1:-}" ] && kill "$C1" 2>/dev/null; [ -n "${C2:-}" ] && kill "$C2" 2>/dev/null
  true
}
stop_all
rm -rf "$HOME/envs"
bash "$LAB" stage 10 >/dev/null
bash "$LAB" carrier "$HOME/carrier"
CARRIER_TOKEN=lab-sandbox-token CARRIER_PORT=9091 setsid python3 "$HOME/carrier/server.py" </dev/null >/dev/null 2>&1 & C1=$!
CARRIER_TOKEN=lab-live-token CARRIER_PORT=9092 setsid python3 "$HOME/carrier/server.py" </dev/null >/dev/null 2>&1 & C2=$!
mkdir -p "$HOME/envs/dev" "$HOME/envs/staging" "$HOME/envs/production"
printf 'SHIPQUOTE_PORT=8100\n' > "$HOME/envs/dev/config.env"
printf 'SHIPQUOTE_PORT=8200\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9091\nSHIPQUOTE_CARRIER_TOKEN=lab-sandbox-token\n' > "$HOME/envs/staging/config.env"
printf 'SHIPQUOTE_PORT=8300\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092\nSHIPQUOTE_CARRIER_TOKEN=lab-live-token\n' > "$HOME/envs/production/config.env"
cd "$HOME/shipquote" || exit 1
ops/build.sh > /dev/null
sleep 1
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block three-configs
run 'grep -v TOKEN ~/envs/*/config.env'

block three-deploys
run 'for env in dev staging production; do ops/deploy.sh $env dist/shipquote-1.5.0.tar.gz; done'
run 'for port in 8100 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done'

block same-question
run 'for port in 8100 8200 8300; do curl -s "http://127.0.0.1:$port/quote?cep=01310-100&weight=1200&subtotal=5000"; echo; done'

block process-env
run "tr '\\0' '\\n' < /proc/\$(cat ~/envs/production/pid)/environ | grep ^SHIPQUOTE_ | grep -v TOKEN"

block drift
sed -i 's/FREE_FROM = 19900 /FREE_FROM = 19000 /' "$HOME/envs/staging/current/shipquote/quote.py"
bash ops/restart.sh staging
run 'for port in 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done'
run 'for port in 8200 8300; do curl -s "http://127.0.0.1:$port/quote?cep=69005-010&weight=5000&subtotal=19800"; echo; done'
run 'diff -r -x __pycache__ ~/envs/staging/current ~/envs/production/current'
run 'ops/deploy.sh staging dist/shipquote-1.5.0.tar.gz && diff -r -x __pycache__ ~/envs/staging/current ~/envs/production/current && echo "no differences"'

block preview
mkdir -p "$HOME/envs/pr-42"
printf 'SHIPQUOTE_PORT=8442\n' > "$HOME/envs/pr-42/config.env"
run 'cat ~/envs/pr-42/config.env'
run 'time ops/deploy.sh pr-42 dist/shipquote-1.5.0.tar.gz'
run 'kill $(cat ~/envs/pr-42/pid) && rm -rf ~/envs/pr-42 && ls ~/envs'

stop_all
