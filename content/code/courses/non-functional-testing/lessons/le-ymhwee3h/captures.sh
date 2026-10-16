#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh build`
# with the base packages of "The base packages" already installed; the two
# files of "The box office", copied out of that section by `shown` rather than
# pasted into nano. The server runs in the background, where the lesson has
# the student run it in a second terminal, and `log` prints what that terminal
# showed. Timings in the Server-Timing header and the Date header differ on
# every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l1
shown "$HERE_DIR/the-boxoffice.md" 2>/dev/null

block packages
run 'grep PRETTY /etc/os-release; python3 --version'
run 'java -version 2>&1 | head -1; sqlite3 --version | cut -d" " -f1; git --version'

at '~/boxoffice'
block seed
run 'python3 seed.py'
run 'ls -l data'
serve 'python3 app.py'
block serve
run 'curl -s localhost:8000/health'
run 'curl -s localhost:8000/shows | jq -c ".[:3][]"'
run 'curl -si localhost:8000/shows/990'
block book
run "curl -si -X POST localhost:8000/bookings -d '{\"show_id\": 990, \"seat\": 12, \"customer\": \"ana\"}'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/bookings -d '{\"show_id\": 990, \"seat\": 12, \"customer\": \"bia\"}'"
run "curl -s -w '%{http_code}\n' -X POST localhost:8000/bookings -d '{\"show_id\": 990}'"
block timing
run 'for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{time_total}\n" localhost:8000/shows/990; done'

block fails-serve
run 'python3 app.py'
stop
block fails-curl
run 'curl -s localhost:8000/health; echo "exit $?"'
run 'curl -sS localhost:8000/health'

block serve-start
echo 'ana@nft:~/boxoffice$ python3 app.py'
log
