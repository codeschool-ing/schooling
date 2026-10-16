#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, with every tool of the course
# installed; boxoffice from lesson 1, account.py and test_account.py from
# lesson 16 and test_vectors.py from this lesson, copied out of the lessons by
# `shown` rather than pasted into nano. Both services run in the background,
# where the lessons have the student run each in a terminal of its own. Every
# probe is benign and is sent to the student's own services on 127.0.0.1.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L16="$HERE_DIR/../le-eyhjtrtz"

machine l20
shown "$L1/the-boxoffice.md" "$L16/the-account-service.md" "$L16/tests-for-defences.md" \
  "$HERE_DIR/the-vector-tests.md" 2>/dev/null

at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'
PORT=8001 serve 'python3 account.py' account
quiet "curl -s -X POST localhost:8001/register -d '{\"name\": \"ana\", \"password\": \"correct horse battery\"}'"
quiet "curl -s -X POST localhost:8001/register -d '{\"name\": \"bia\", \"password\": \"correct horse battery\"}'"

block inj-box
run "curl -s 'localhost:8000/search?q=Hamlet' | jq length"
run "curl -s -w ' %{http_code}\n' \"localhost:8000/search?q='\""
run "curl -s 'localhost:8000/search?q=%25' | jq length"

block inj-acc
run "curl -s -c ~/ana.jar -X POST localhost:8001/login -d '{\"name\": \"ana\", \"password\": \"correct horse battery\"}' | jq -r .token > ~/ana.token"
run "curl -s -X POST localhost:8001/bookings -H \"Authorization: Bearer \$(cat ~/ana.token)\" -d '{\"show_id\": 990, \"seat\": 12, \"holder\": \"Ana O'\\''Brien\"}'"
run "curl -s localhost:8001/bookings/1 -H \"Authorization: Bearer \$(cat ~/ana.token)\""
run "curl -s -b ~/ana.jar -o /dev/null -w '%{http_code}\n' \"localhost:8001/account?q='\""
run "curl -s -b ~/ana.jar \"localhost:8001/account?q='\" | grep '<li>'"

block xss
run "curl -s -X POST localhost:8001/bookings -H \"Authorization: Bearer \$(cat ~/ana.token)\" -d '{\"show_id\": 991, \"seat\": 3, \"holder\": \"<em>nft-probe</em>\"}'"
run "curl -s -b ~/ana.jar localhost:8001/account | grep 'nft-probe'"
run "curl -s -b ~/ana.jar 'localhost:8001/account?q=nft%22probe' | grep 'name=\"q\"'"
run "curl -s -b ~/ana.jar -o /dev/null -D - localhost:8001/account | grep -i 'content-security\\|nosniff'"

block csrf
run "curl -s -b ~/ana.jar -w '%{http_code}\n' -X POST localhost:8001/account/cancel -d 'booking=1'"
run "curl -s -b ~/ana.jar localhost:8001/account | grep -o 'name=\"csrf\" value=\"[^\"]*\"' | head -1 | cut -d'\"' -f4 > ~/ana.csrf"
run "curl -s -b ~/ana.jar -o /dev/null -w '%{http_code}\n' -X POST localhost:8001/account/cancel -d \"booking=1&csrf=\$(cat ~/ana.csrf)\""
run "curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H \"Authorization: Bearer \$(cat ~/ana.token)\""

block uploads
run "printf 'name,seat\nana,12\n' > notes.png"
run "curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H \"Authorization: Bearer \$(cat ~/ana.token)\" --data-binary @notes.png"
run "head -c 300000 /dev/zero > big.png"
run "curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H \"Authorization: Bearer \$(cat ~/ana.token)\" --data-binary @big.png"
run "python3 -c 'import sys, zlib, struct; c = lambda t, d: struct.pack(\">I\", len(d)) + t + d + struct.pack(\">I\", zlib.crc32(t + d)); sys.stdout.buffer.write(b\"\\x89PNG\\r\\n\\x1a\\n\" + c(b\"IHDR\", struct.pack(\">IIBBBBB\", 1, 1, 8, 0, 0, 0, 0)) + c(b\"IDAT\", zlib.compress(b\"\\x00\\x00\")) + c(b\"IEND\", b\"\"))' > dot.png"
run "curl -s -w ' %{http_code}\n' -X POST localhost:8001/avatar -H \"Authorization: Bearer \$(cat ~/ana.token)\" --data-binary @dot.png"
run 'ls data/uploads'
run "curl -s -w ' %{http_code}\n' localhost:8001/data/uploads/ -H \"Authorization: Bearer \$(cat ~/ana.token)\""

block vec-tests
run 'python3 -m unittest -v test_vectors'
block all-tests
run 'python3 -m unittest test_account test_vectors'

block unguarded
run 'mkdir -p ~/unguarded && cp test_account.py test_vectors.py ~/unguarded/'
run "sed '/# CSRF check\$/s/^ */&# /' account.py > ~/unguarded/account.py"
run 'cd ~/unguarded'
at '~/unguarded'
run 'python3 -m unittest test_account test_vectors'
run 'cd ~/boxoffice'
at '~/boxoffice'
run 'rm -r ~/unguarded'

block log
echo 'ana@nft:~/boxoffice$ python3 account.py'
log account
stop account
stop
