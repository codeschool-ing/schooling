#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of testing-cicd, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash captures.sh
#
# THE ENVIRONMENTS ARE DIRECTORIES ON ONE MACHINE. ~/envs/staging and
# ~/envs/production each hold a config.env and their own releases, and run
# shipquote as a process on their own port. That is the smallest honest model
# of "two environments"; lesson 8 says what real ones add.
#
# The five scripts of ops/ are shown whole, in "the-artifact", "deploying" and
# "smoke-tests", and `../../lab.sh shown` fails this script before its first
# block if any of them is not the file ../../lab.sh wrote at step 9.
#
# What is STAGED rather than typed:
#   - the project at step 9 (tag v1.4.0) in /home/ana/shipquote, by
#     ../../lab.sh; ~/envs emptied, and the config.env files written with the
#     commands the section "deploying" gives;
#   - in "untagged", a commit on a throwaway branch, deleted afterwards;
#   - in "tampered", a copy of the artifact with one byte appended;
#   - in "bad-config", an environment called preview whose config has the
#     typo the section shows.
#   Every process started is stopped at the end.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Python 3.13.16 and git 2.43.0,
# TZ=America/Sao_Paulo, as root with HOME=/home/ana so paths read as Ana's.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 HOME=/home/ana USER=ana LOGNAME=ana
export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org
LAB=$(cd "$(dirname "$0")/../.." && pwd)/lab.sh
stop_all() { for p in "$HOME"/envs/*/pid; do [ -f "$p" ] && kill "$(cat "$p")" 2>/dev/null; done; true; }
stop_all
rm -rf "$HOME/envs"
bash "$LAB" stage 9 >/dev/null
bash "$LAB" shown "$(dirname "$LAB")/lessons/le-acgw7zvm" || exit 1
mkdir -p "$HOME/envs/staging" "$HOME/envs/production"
echo SHIPQUOTE_PORT=8200 > "$HOME/envs/staging/config.env"
echo SHIPQUOTE_PORT=8300 > "$HOME/envs/production/config.env"
cd "$HOME/shipquote" || exit 1
run() { printf 'ana@laptop:~/shipquote$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block build
run 'git describe --tags'
run 'ops/build.sh'
run 'cat dist/shipquote-1.4.0.tar.gz.sha256'
run 'rm -rf dist && ops/build.sh > /dev/null && cat dist/shipquote-1.4.0.tar.gz.sha256'

block stamp
run 'tar -xzOf dist/shipquote-1.4.0.tar.gz shipquote-1.4.0/shipquote/VERSION; echo'
run "python3 -c 'from shipquote.version import VERSION; print(VERSION)'"

block untagged
git switch -q -c try-a-change
echo >> README.md
GIT_AUTHOR_DATE=2026-09-25T10:00:00-03:00 GIT_COMMITTER_DATE=2026-09-25T10:00:00-03:00 git commit -qam "Try a change"
run 'git describe --tags'
run 'ops/build.sh'
git switch -q main
git branch -q -D try-a-change
rm -f dist/shipquote-dev-*

block deploy-staging
run 'cat ~/envs/staging/config.env'
run 'ops/deploy.sh staging dist/shipquote-1.4.0.tar.gz'
run 'ls -F ~/envs/staging ~/envs/staging/releases'
run 'readlink ~/envs/staging/current'
run 'curl -s http://127.0.0.1:8200/version; echo'

block tampered
cp dist/shipquote-1.4.0.tar.gz* /tmp/
printf x >> /tmp/shipquote-1.4.0.tar.gz
run 'ops/deploy.sh production /tmp/shipquote-1.4.0.tar.gz; echo "exit status $?"'
rm -f /tmp/shipquote-1.4.0.tar.gz /tmp/shipquote-1.4.0.tar.gz.sha256

block deploy-production
run 'ops/deploy.sh production dist/shipquote-1.4.0.tar.gz'
run 'for port in 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done'

block bad-config
mkdir -p "$HOME/envs/preview"
echo SHIPQUOTE_PORT=84OO > "$HOME/envs/preview/config.env"
run 'cat ~/envs/preview/config.env'
run 'ops/deploy.sh preview dist/shipquote-1.4.0.tar.gz; echo "exit status $?"'
run 'tail -1 ~/envs/preview/app.log'

stop_all
