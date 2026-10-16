#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with every tool of the course
# installed; account.py and test_account.py, copied out of "The account
# service" and "Tests that hold a defence" by `shown` rather than pasted into
# nano. The account service runs in the background, where the lesson has the
# student run it in a second terminal, and `log` prints what that terminal
# showed. The copy with one line commented out is made with sed, as the lesson
# shows; the lesson also says it can be made by hand in nano.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l16
shown "$HERE_DIR/the-account-service.md" "$HERE_DIR/tests-for-defences.md" 2>/dev/null

at '~/boxoffice'
PORT=8001 serve 'python3 account.py' account
block acc-curl
run 'curl -s localhost:8001/health'
run "curl -s -X POST localhost:8001/register -d '{\"name\": \"ana\", \"password\": \"correct horse battery\"}'"
run "curl -s -X POST localhost:8001/login -d '{\"name\": \"ana\", \"password\": \"correct horse battery\"}' | jq -r .token > ~/ana.token"
run "curl -s -X POST localhost:8001/bookings -H \"Authorization: Bearer \$(cat ~/ana.token)\" -d '{\"show_id\": 990, \"seat\": 12, \"holder\": \"Ana Lima\"}'"
run 'curl -s localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"'
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/1"

block tests
run 'python3 -m unittest -v test_account'

block unguarded
run 'mkdir -p ~/unguarded && cp test_account.py ~/unguarded/'
run "sed '/# owner check\$/s/^ */&# /' account.py > ~/unguarded/account.py"
run 'diff account.py ~/unguarded/account.py'
run 'cd ~/unguarded'
at '~/unguarded'
run 'python3 -m unittest test_account'
run 'cd ~/boxoffice'
at '~/boxoffice'
run 'rm -r ~/unguarded'

block acc-serve
echo 'ana@nft:~/boxoffice$ python3 account.py'
log account
stop account
