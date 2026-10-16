#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine of lesson 1 with every tool of
# the course installed; lesson 1's two files of "The box office", lesson 8's
# measure.py and this lesson's app_fixed.py, race.py and keepalive.py, copied
# out of the sections that show them rather than pasted into nano. The server
# runs in the background, where the lesson has the student run it in a second
# terminal; switching between app.py and app_fixed.py is `stop` and `serve`
# here and Ctrl+C and a new command there.
#
# A load test and the tool watching it run as one typed line, the load in the
# background with `&`. vmstat and the %Cpu line of top describe the whole
# recording computer, which was shared with other work and has 16 GB of
# memory; the lesson says so where it quotes them. Every timing differs on
# every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L8="$HERE_DIR/../le-gh2gqkpp"

machine l09
shown "$L1/the-boxoffice.md" "$L8/the-mean.md" "$HERE_DIR/the-lock.md" \
  "$HERE_DIR/network-and-infrastructure.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

block timing
run 'curl -si localhost:8000/shows/990 | grep Server-Timing'
run "curl -si -X POST localhost:8000/bookings -d '{\"show_id\": 990, \"seat\": 12, \"customer\": \"ana\"}' | grep Server-Timing"
run "curl -s -o /dev/null -w 'connect %{time_connect}  first byte %{time_starttransfer}  total %{time_total}\n' localhost:8000/shows/990"

block use
run "python3 measure.py 8 12 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep -E 'Cpu\(s\)|python3 [am]'; wait"
run 'head -4 load.txt'

block plan
run 'sqlite3 data/boxoffice.db "EXPLAIN QUERY PLAN SELECT count(*) FROM bookings WHERE show_id = 990"'
block index
run 'sqlite3 data/boxoffice.db "CREATE INDEX bookings_by_show ON bookings (show_id)"'
run 'sqlite3 data/boxoffice.db "EXPLAIN QUERY PLAN SELECT count(*) FROM bookings WHERE show_id = 990"'
run 'curl -si localhost:8000/shows/990 | grep Server-Timing'
block after
run 'python3 measure.py 8 12 | head -4'

block lock
run 'for w in 1 4 16; do python3 measure.py $w 5 1.0 | sed -n "1,2p;4p"; done'
block lock-top
run 'python3 measure.py 16 8 1.0 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep "python3 [am]"; wait'

stop
block fixed-start
run 'python3 seed.py'
serve 'python3 app_fixed.py'
block race
run 'python3 race.py'
run 'sqlite3 data/boxoffice.db "SELECT customer FROM bookings WHERE show_id = 990 AND seat = 1"'
block fixed-lock
run 'for w in 1 4 16; do python3 measure.py $w 5 1.0 | sed -n "1,2p;4p"; done'
block fixed-disk
run 'python3 measure.py 16 8 1.0 > load.txt & sleep 2; vmstat 1 4; wait'
block generator
run 'python3 measure.py 32 8 > load.txt & sleep 2; top -b -n 2 -d 2 -c -o %CPU | grep "python3 [am]"; wait'
run 'head -1 load.txt'

stop
serve 'python3 app.py'
block keep-old
run 'python3 keepalive.py'
block queue-old
run 'nstat -n; python3 measure.py 32 5 | sed -n "1p;4p"; nstat -z TcpExtListenOverflows'
stop
serve 'python3 app_fixed.py'
block keep-fixed
run 'python3 keepalive.py'
block queue-fixed
run 'nstat -n; python3 measure.py 32 5 | sed -n "1p;4p"; nstat -z TcpExtListenOverflows'
block memory
run 'free -m'
stop
