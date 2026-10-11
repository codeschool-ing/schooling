#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of apis, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine itself, built by `lab.sh up`
# with every package of lesson 1's "The packages" already installed; lesson 1's
# `db.py` and `rest.py`, and this lesson's `limits.py`, `burst.py` and
# `polite.py`, copied out of the lessons by `shown` rather than pasted into
# nano. Each server runs in the background, where the lesson has the student
# run it in a second terminal, and is stopped and started again between blocks
# so that every block begins with full buckets, as the prose says; `log`
# prints what that terminal showed. The second server of the section "More
# than one server" runs the same way on port 8001.
#
# What differs per run: dates, the Date header, the server's log times, every
# timing burst.py and polite.py print, the jitter polite.py draws, and the
# daily window's `t`, which counts the seconds to midnight UTC. Where a
# request lands relative to a refill or a window boundary can move a 200 or a
# 429 by one request at the edges; the lesson quotes one run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)

machine l12

shown "$HERE_DIR/../le-f6652c1w/the-shelf.md" "$HERE_DIR/the-limiter.md" \
  "$HERE_DIR/a-burst.md" "$HERE_DIR/backoff.md"
at '~/shelf'

serve 'python3 rest.py'
block unlimited
run "time (for i in \$(seq 100); do curl -s -o /dev/null -w '%{http_code}\\n' localhost:8000/v1/books; done | sort | uniq -c)"

block forwarded
run "curl -sv -H 'X-Forwarded-For: 203.0.113.7' localhost:8000/v1/books/1 2>&1 | grep -E '^[<>] (GET|X-Forwarded|HTTP)'"
block forwarded-log
log
stop

block limiter
serve 'python3 limits.py'
run 'curl -s localhost:8000/books'
run "curl -s -H 'X-API-Key: demo-bia' localhost:8000/books"
run "curl -si -H 'X-API-Key: demo-bia' localhost:8000/books/3"
stop

block burst
serve 'python3 limits.py'
run 'python3 burst.py demo-bia /books 15'
run "curl -si -H 'X-API-Key: demo-bia' localhost:8000/books/1"
run "curl -s -o /dev/null -w '%{http_code}\n' -H 'X-API-Key: demo-caio' localhost:8000/books"
run 'sleep 3; python3 burst.py demo-bia /books 5'
block burst-log
log
stop

block steady
serve 'python3 limits.py'
run 'python3 burst.py demo-bia /books 24 0.25'
stop

block edge-window
serve 'python3 limits.py window'
run 'python3 burst.py --edge demo-bia /books 30 0.1'
stop

block edge-bucket
serve 'python3 limits.py'
run 'python3 burst.py --edge demo-bia /books 30 0.1'
stop

block polite
serve 'python3 limits.py'
run 'python3 polite.py demo-bia 14'
stop
block polite-down
run 'python3 polite.py demo-bia 3'

block costs
serve 'python3 limits.py'
run "curl -s -H 'X-API-Key: demo-bia' 'localhost:8000/search?q=Cora'"
run "python3 burst.py demo-bia '/search?q=a' 3"
block quota
run "python3 burst.py demo-ana '/search?q=a' 5 5"
run "curl -si -H 'X-API-Key: demo-ana' localhost:8000/books/1"
stop

block two
serve 'python3 limits.py'
PORT=8001 serve 'python3 limits.py bucket 8001' second
run "for i in \$(seq 20); do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: demo-bia' localhost:8000/books; done; echo"
run "sleep 10; for i in \$(seq 20); do curl -s -o /dev/null -w '%{http_code} ' -H 'X-API-Key: demo-bia' localhost:\$((8000 + i % 2))/books; done; echo"
stop second
stop
