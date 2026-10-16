#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with every tool of the course
# installed; account.py and test_account.py from lesson 16, test_sessions.py
# from lesson 17, test_vectors.py from lesson 20 and test_owasp.py from this
# lesson, copied out of the lessons by `shown` rather than pasted into nano.
# The account service runs in the background, where the lesson has the student
# run it in a second terminal, and `log` prints what that terminal showed; it
# starts with no database. Tokens, dates, timings and the times in the log
# differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L16="$HERE_DIR/../le-eyhjtrtz"
L17="$HERE_DIR/../le-45db7034"
L20="$HERE_DIR/../le-g73rrpak"

machine l19
shown "$L16/the-account-service.md" "$L16/tests-for-defences.md" "$L17/session-tests.md" \
  "$L20/the-vector-tests.md" "$HERE_DIR/checks.md" 2>/dev/null

at '~/boxoffice'
PORT=8001 serve 'python3 account.py' account

block headers
run "curl -s -X POST localhost:8001/register -d '{\"name\": \"ana\", \"password\": \"correct horse battery\"}'"
run "curl -s -X POST localhost:8001/login -d '{\"name\": \"ana\", \"password\": \"correct horse battery\"}' | jq -r .token > ~/ana.token"
run 'curl -s -o /dev/null -D - localhost:8001/account --cookie "session=$(cat ~/ana.token)"'

block error
run "curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H \"Authorization: Bearer \$(cat ~/ana.token)\" -H 'Content-Length: many'"

block acc-log-error
echo 'ana@nft:~/boxoffice$ python3 account.py'
log account

block probes
run "curl -s -X POST localhost:8001/login -d '{\"name\": \"ana\", \"password\": \"not the password\"}'"
run "curl -s -X POST localhost:8001/login -d '{\"name\": \"nft\\nWARNING nft-probe\", \"password\": \"x\"}'"
run "curl -s localhost:8001/staff/bookings -H \"Authorization: Bearer \$(cat ~/ana.token)\""

block acc-log
log account | tail -n 3
stop account

block owasp
run 'python3 -m unittest -v test_owasp'

block suite
run 'python3 -m unittest'
