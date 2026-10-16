#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with every tool of the course
# installed; account.py and test_account.py from lesson 16 and test_sessions.py
# from "The session tests", copied out of the lessons by `shown`. The account
# service runs in the background, where the lessons have the student run it in
# a second terminal, and `log` prints what that terminal showed; it starts with
# no database, as it would the first time. Tokens, salts, hashes, timings and
# the times in the log differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L16="$HERE_DIR/../le-eyhjtrtz"

machine l17
shown "$L16/the-account-service.md" "$L16/tests-for-defences.md" "$HERE_DIR/session-tests.md" 2>/dev/null

at '~/boxoffice'
PORT=8001 serve 'python3 account.py' account

block two-users
run 'for n in ana bia sam; do curl -s -X POST localhost:8001/register -d "{\"name\": \"$n\", \"password\": \"correct horse battery\"}"; done'
run "for n in ana bia; do curl -s -X POST localhost:8001/login -d \"{\\\"name\\\": \\\"\$n\\\", \\\"password\\\": \\\"correct horse battery\\\"}\" | jq -r .token > ~/\$n.token; done"
run "curl -s -X POST localhost:8001/bookings -H \"Authorization: Bearer \$(cat ~/ana.token)\" -d '{\"show_id\": 990, \"seat\": 12, \"holder\": \"Ana Lima\"}'"
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H \"Authorization: Bearer \$(cat ~/bia.token)\""
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/2 -H \"Authorization: Bearer \$(cat ~/bia.token)\""

block vertical
run "curl -s -w '%{http_code}\n' localhost:8001/staff/bookings -H \"Authorization: Bearer \$(cat ~/ana.token)\""
run "sqlite3 data/account.db \"UPDATE accounts SET role = 'staff' WHERE name = 'sam'\""
run "curl -s -X POST localhost:8001/login -d '{\"name\": \"sam\", \"password\": \"correct horse battery\"}' | jq -r .token > ~/sam.token"
run "curl -s -w '%{http_code}\n' localhost:8001/staff/bookings -H \"Authorization: Bearer \$(cat ~/sam.token)\""

block cookie
run "curl -si -X POST localhost:8001/login -d '{\"name\": \"bia\", \"password\": \"correct horse battery\"}' | grep -i -e '^HTTP' -e '^set-cookie'"

block url-token
run "curl -s -w '%{http_code}\n' \"localhost:8001/bookings/1?token=\$(cat ~/ana.token)\""
run "curl -s -X POST localhost:8001/logout -H \"Authorization: Bearer \$(cat ~/ana.token)\""
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H \"Authorization: Bearer \$(cat ~/ana.token)\""

block stored
run "sqlite3 data/account.db 'SELECT name, length(salt), substr(hash, 1, 24), role FROM accounts'"
run "sqlite3 data/account.db 'SELECT substr(token, 1, 24), account FROM sessions'"
run 'cut -c1-24 ~/bia.token'

block sign-in
run "curl -s -w ' %{http_code} %{time_total}\n' -X POST localhost:8001/login -d '{\"name\": \"bia\", \"password\": \"wrong password\"}'"
run "curl -s -w ' %{http_code} %{time_total}\n' -X POST localhost:8001/login -d '{\"name\": \"nobody\", \"password\": \"wrong password\"}'"

block rate
run "for i in 1 2 3 4 5; do curl -s -o /dev/null -w '%{http_code} ' -X POST localhost:8001/login -d '{\"name\": \"sam\", \"password\": \"a guess\"}'; done; echo"
run "curl -s -w '%{http_code}\n' -X POST localhost:8001/login -d '{\"name\": \"sam\", \"password\": \"correct horse battery\"}'"

block acc-log
echo 'ana@nft:~/boxoffice$ python3 account.py'
log account
stop account

block expiry
PORT=8001 serve 'env ACCOUNT_SESSION_SECONDS=2 python3 account.py' account
run "curl -s -X POST localhost:8001/login -d '{\"name\": \"bia\", \"password\": \"correct horse battery\"}' | jq -r .token > ~/bia.token"
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H \"Authorization: Bearer \$(cat ~/bia.token)\""
run 'sleep 3'
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H \"Authorization: Bearer \$(cat ~/bia.token)\""
stop account

block tests
run 'python3 -m unittest -v test_sessions'

block unguarded
run 'mkdir -p ~/unguarded && cp test_account.py test_sessions.py ~/unguarded/'
run "sed '/# role check\$/s/^ */&# /' account.py > ~/unguarded/account.py"
run 'cd ~/unguarded'
at '~/unguarded'
run 'python3 -m unittest test_sessions'
run 'cd ~/boxoffice'
at '~/boxoffice'
run 'rm -r ~/unguarded'
