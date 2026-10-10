#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, as lesson 1 left it;
# lesson 1's db.py and rest.py, and this lesson's orders.py and matrix.py,
# copied out of the lessons by `shown` rather than pasted into nano. rest.py is
# never started here, where the student has it running from lesson 1 and stops
# it before starting orders.py. Servers run in the background, where the lesson
# has the student run them in a second terminal, and `log` prints what that
# terminal showed. The dates of the orders are counted back from the day of the
# run, so `placed_on` and the Date header differ on every run; the ages of the
# orders (1, 2, 10 and 45 days) do not.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l11

shown "$(dirname "$HERE_DIR")/le-f6652c1w/the-shelf.md" "$HERE_DIR"/*.md
at '~/shelf'

block start
serve 'python3 orders.py'
run 'curl -si localhost:8000/orders'
run "curl -s -H 'Authorization: Bearer demo-ana' localhost:8000/orders | jq -c '.[]'"
run "sqlite3 shelf.db 'SELECT * FROM people'"

block deny
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-eva' localhost:8000/orders"
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-nobody' localhost:8000/orders"
run "curl -s -w '%{http_code}\n' localhost:8000/no/such/thing"
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-ana' localhost:8000/no/such/thing"

block owner
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3"
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/1/cancel"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' localhost:8000/orders/1/cancel"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' localhost:8000/orders/1/cancel"

block admin
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-carla' localhost:8000/admin/people"
run "curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-dora' localhost:8000/admin/people"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3/refund"
run "curl -si -X DELETE -H 'Authorization: Bearer demo-dora' localhost:8000/orders/3"

block props
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' -H 'Content-Type: application/json' -d '{\"book_id\": 1, \"quantity\": 2, \"status\": \"shipped\", \"total_cents\": 1}' localhost:8000/orders"
run "curl -si -X POST -H 'Authorization: Bearer demo-ana' -H 'Content-Type: application/json' -d '{\"book_id\": 1, \"quantity\": 2}' localhost:8000/orders"
run "curl -s -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3"
run "curl -s -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3"
run "curl -s -H 'Authorization: Bearer demo-carla' localhost:8000/orders/3"

block scopes
run "curl -s -H 'Authorization: Bearer demo-ana-app' localhost:8000/orders | jq -c '.[] | {id, status}'"
run "curl -si -X POST -H 'Authorization: Bearer demo-ana-app' -H 'Content-Type: application/json' -d '{\"book_id\": 1, \"quantity\": 1}' localhost:8000/orders"

block policy
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/2/refund"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/4/refund"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-dora' localhost:8000/orders/4/refund"
run "curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-carla' localhost:8000/orders/2/refund"

block codes
run "curl -si -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3"
run "curl -si -H 'Authorization: Bearer demo-ana' localhost:8000/orders/99"

block log
log

block matrix
run 'python3 matrix.py; echo "exit $?"'
stop
run "sed '/!= me and/,+1d' orders.py > broken.py"
run 'diff orders.py broken.py'
serve 'python3 broken.py' broken
run 'python3 matrix.py; echo "exit $?"'
stop broken
