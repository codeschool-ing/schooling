#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh
#
# EVERY SECRET IN THIS LESSON IS A VALUE THE LAB MADE UP. lab-live-token and
# its successor open the lab's carrier stand-in on 127.0.0.1 and nothing
# else. The lesson treats them as real on purpose, and shows how a leak is
# found and contained, never how anybody else's is used.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - the project at step 10 (tag v1.5.0) in /home/ana/shipquote, by
#     ../../lab.sh; ~/envs/production with the config.env the section
#     "permissions" lists, deployed; the carrier stand-in on 127.0.0.1:9092;
#   - in "history", the two commits shown, made here with fixed dates on a
#     throwaway branch that is deleted afterwards;
#   - in "rotation", the stand-in restarted with a new token, then the
#     production config.env edited with sed, as the section says;
#   - in "args", a background Python process whose arguments carry a token;
#     it sleeps for thirty seconds and does nothing else.
#   Every process started is stopped at the end.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16 and git 2.43.0,
# TZ=America/Sao_Paulo, as root with HOME=/home/ana so paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
stop_all() {
  for p in "$HOME"/envs/*/pid; do [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; done
  [ -n "${C2:-}" ] && kill "$C2" 2>/dev/null
  true
}
carrier() {
  [ -n "${C2:-}" ] && kill "$C2" 2>/dev/null && sleep 0.5
  CARRIER_TOKEN=$1 CARRIER_PORT=9092 setsid python3 "$HOME/carrier/server.py" </dev/null >/dev/null 2>&1 &
  C2=$!
  sleep 1
}
stop_all
rm -rf "$HOME/envs"
bash "$LAB" stage 10 >/dev/null
bash "$LAB" carrier "$HOME/carrier"
carrier lab-live-token
mkdir -p "$HOME/envs/production"
printf 'SHIPQUOTE_PORT=8300\nSHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092\nSHIPQUOTE_CARRIER_TOKEN=lab-live-token\n' > "$HOME/envs/production/config.env"
chmod 644 "$HOME/envs/production/config.env"
cd "$HOME/shipquote" || exit 1
ops/build.sh > /dev/null
ops/deploy.sh production dist/shipquote-1.5.0.tar.gz > /dev/null
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }
Q='curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=1200&subtotal=5000"; echo'

block history
git switch -q -c add-deploy-config
mkdir -p deploy
printf 'SHIPQUOTE_CARRIER_URL=http://127.0.0.1:9092\nSHIPQUOTE_CARRIER_TOKEN=lab-live-token\n' > deploy/production.env
git add deploy
GIT_AUTHOR_DATE=2026-09-30T10:00:00-03:00 GIT_COMMITTER_DATE=2026-09-30T10:00:00-03:00 git commit -qm 'Keep the production settings with the code'
git rm -q deploy/production.env
GIT_AUTHOR_DATE=2026-09-30T10:20:00-03:00 GIT_COMMITTER_DATE=2026-09-30T10:20:00-03:00 git commit -qm 'Remove the production settings again'
run 'git log --oneline -3'
run 'ls deploy/production.env'
run 'git log --oneline -S lab-live-token'
run 'git show HEAD~1:deploy/production.env'
git switch -q main
git branch -q -D add-deploy-config

block permissions
run 'stat -c "%A %n" ~/envs/production/config.env'
run 'chmod 600 ~/envs/production/config.env && stat -c "%A %n" ~/envs/production/config.env'

block args
setsid python3 -c 'import time; time.sleep(30)' --carrier-token=lab-live-token </dev/null >/dev/null 2>&1 &
S=$!
run 'ps -o args= -C python3 | grep "[c]arrier-token"'
run 'ps -o args= -C python3 | grep -c "[S]HIPQUOTE_CARRIER_TOKEN"'
kill $S 2>/dev/null

block masking
run "printf 'Authorization: Bearer lab-live-token\n' | sed 's/lab-live-token/***/g'"
run "printf 'Bearer lab-live-token' | base64 | sed 's/lab-live-token/***/g'"
run "printf 'Bearer lab-live-token' | base64 | base64 -d; echo"

block logs
run "$Q"
run 'grep -c lab-live-token ~/envs/production/app.log'
run 'tail -2 ~/envs/production/app.log'

block rotation
carrier lab-live-token-2
run "$Q"
run 'tail -2 ~/envs/production/app.log'
sed -i 's/=lab-live-token$/=lab-live-token-2/' "$HOME/envs/production/config.env"
run 'ops/restart.sh production && '"$Q"

stop_all
