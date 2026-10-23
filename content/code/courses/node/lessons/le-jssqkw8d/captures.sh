#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l2.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l2.txt; done
#
# Needs lesson 1's captures to have run (Node in ana's home). Every program is
# taken out of the lesson's .md by lab/shown.py. Timings are this computer's,
# which has four processors: they move from run to run, and the prose quotes
# them only as "about".
#
# STAGED: busy.js is started in a second terminal and stopped afterwards, and
# so is motd.js; their output is shown where the lesson shows that terminal.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
W='~/server/loop'
quiet '~/server' 'rm -rf loop && mkdir loop'
for f in inside-io.js race.js; do shown phases.md $f $W/$f; done
shown next-tick.md ticks.js $W/ticks.js
shown next-tick.md starve.js $W/starve.js
shown thread-pool.md pool.js $W/pool.js
shown network-io.md threads.js $W/threads.js
shown blocking-the-loop.md busy.js $W/busy.js
shown sync-apis.md motd.js $W/motd.js
shown staying-alive.md alive.js $W/alive.js
shown crashing.md reject.js $W/reject.js
shown crashing.md last-resort.js $W/last-resort.js

block versions
session $W 'node -p process.versions'
block inside-io
session $W "for i in \$(seq 20); do node inside-io.js | paste -sd' '; done | sort | uniq -c"
block race
session $W "for i in \$(seq 20); do node race.js | paste -sd' '; done | sort | uniq -c" \
  "for i in \$(seq 20); do node race.js slow | paste -sd' '; done | sort | uniq -c"
block ticks
session $W 'node ticks.js'
block starve
session $W 'node starve.js'
block pool
session $W 'node pool.js 1' 'node pool.js 4' 'node pool.js 6'
block pool-size
session $W 'UV_THREADPOOL_SIZE=6 node pool.js 6'
block threads
session $W 'node threads.js'

bg busy $W 'node busy.js'
wait_port 3000
block busy
session $W "curl -s -o /dev/null -w 'fast alone: %{time_total} s\n' http://127.0.0.1:3000/fast" \
  'curl -s http://127.0.0.1:3000/delay' \
  "curl -s -o /dev/null -w 'slow: %{time_total} s\n' http://127.0.0.1:3000/slow &" \
  "sleep 0.2; curl -s -o /dev/null -w 'fast behind slow: %{time_total} s\n' http://127.0.0.1:3000/fast" \
  'sleep 0.5; curl -s http://127.0.0.1:3000/delay'
bg_stop busy INT

block motd
quiet $W 'echo "hello" > motd.txt'
bg motd $W 'node --trace-sync-io motd.js'
wait_port 3000
session $W 'curl -s http://127.0.0.1:3000/'
sleep 0.3
bg_stop motd INT
block motd-server
bg_show motd
printf '^C\n'
block motd-utf8
session $W "sed 's/(\"motd.txt\").toString()/(\"motd.txt\", \"utf8\")/' motd.js > motd-utf8.js" \
  'grep -c utf8 motd-utf8.js'
bg motd2 $W 'node --trace-sync-io motd-utf8.js'
wait_port 3000
session $W 'curl -s http://127.0.0.1:3000/'
sleep 0.3
bg_stop motd2 INT
block motd-utf8-server
bg_show motd2
printf '^C\n'

block alive
session $W 'timeout 3.5 node alive.js; echo "exit code $?"'
block unref
session $W 'node alive.js unref'
block reject
session $W 'node reject.js; echo "exit code $?"'
block last-resort
session $W 'node last-resort.js; echo "exit code $?"'
