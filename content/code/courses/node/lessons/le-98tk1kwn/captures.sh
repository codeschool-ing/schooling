#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l10.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l10.txt; done
#
# The programs are taken out of the lesson's .md by lab/shown.py. A program
# said to run "in the other terminal" is started with bg; the pid typed into
# kill is the one that program printed, or the one ps showed, as a person
# would read it. The systemd unit is not run (the lesson says so).
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
P='~/server/procs'; L='~/server/links'
quiet '~/server' 'rm -rf procs'
quiet $L 'rm -rf data'

for f in the-process:proc.js the-process:signals.js graceful-shutdown:graceful.js child-processes:run.js child-processes:shell.js \
  child-processes:stream.js talking-to-a-child:primes.js talking-to-a-child:child.js talking-to-a-child:parent.js \
  worker-threads:worker.js worker-threads:threads.js sharing-memory:copy.js sharing-memory:counter.js \
  a-worker-pool:pool.js a-worker-pool:pool-worker.js a-worker-pool:jobs.js a-worker-pool:busy.js \
  cluster:hello-cluster.js cluster:cluster.js; do
  shown ${f%%:*}.md ${f#*:} $P/${f#*:}
done
shown graceful-shutdown.md server.js $L/server.js

block proc
session $P 'node proc.js one two' "node -e 'process.exitCode = 3'; echo \"exit code \$?\""

# Signals: the program in one terminal, kill in the other.
bg sig $P 'node signals.js; echo "exit code $?"'; pid=$(bg_logpid sig)
block kill
session $P "kill -INT $pid" "kill -TERM $pid" "kill -HUP $pid" "kill -KILL $pid"
sleep 0.5
block signals
bg_show sig

# Graceful shutdown.
bg g $P 'node graceful.js; echo "exit code $?"'; wait_port 3000; pid=$(bg_logpid g)
block slow
session $P "curl -s http://127.0.0.1:3000/slow & sleep 0.5; kill -TERM $pid" 'curl -s http://127.0.0.1:3000/fast; echo "curl exit code $?"' 'wait'
sleep 0.5
block graceful
bg_show g
bg l $L 'npm start'; wait_port 3000
bg_stop l INT; sleep 0.3
block links-stop
bg_show l
printf '^C\n'

# Child processes.
block run
session $P 'node run.js'
block shell
session $P 'node shell.js'
quiet $P 'rm -f notes.txt*'
block stream
session $P 'node stream.js'
block parent
session $P 'node parent.js'
block threads
session $P 'node threads.js'
block copy
session $P 'node copy.js'
block counter
session $P 'node counter.js'
block jobs
session $P 'node jobs.js'
FOUR="for i in 1 2 3 4; do curl -s -o /dev/null -w 'primes %{time_total} s\n' http://127.0.0.1:3000/primes & done; sleep 0.2; curl -s -o /dev/null -w 'health %{time_total} s\n' http://127.0.0.1:3000/health; wait"
for mode in nopool pool; do
  bg b $P "node busy.js ${mode/nopool/}"; wait_port 3000
  block busy-$mode
  session $P "$FOUR"
  bg_stop b
done

# cluster.
bg hc $P 'node hello-cluster.js'; wait_port 3000; sleep 0.5
block hello-cluster
session $P 'for i in 1 2 3 4 5 6; do curl -s http://127.0.0.1:3000/; done'
w=$(pgrep -u ana -f '/procs/hello-cluster.js' | sort -n | tail -1)
# appended to the same block: the second terminal carries on
session $P "kill -KILL $w" 'sleep 0.5; ps -o pid,args -C node'
bg_stop hc; sleep 0.3
block hello-cluster-log
bg_show hc
printf '^C\n'
EIGHT="time (for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/primes & done; wait)"
for w in 1 4; do
  bg b $P "WORKERS=$w node cluster.js busy.js"; wait_port 3000; sleep 0.5
  block cluster-$w
  session $P "$EIGHT"
  bg_stop b
done

# The links service in a cluster.
bg lc $L 'rm -f demo/cluster.json && DATA_FILE=demo/cluster.json node --env-file=.env ../procs/cluster.js server.js'; wait_port 3000; sleep 0.8
WARM="for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/nothing-here; done; echo"
NEW="curl -s -H 'content-type: application/json' -d '{\"url\": \"https://nodejs.org/\"}' http://127.0.0.1:3000/links"
block links-cluster
session $L "$WARM" "$NEW"
code=$(python3 -c "import json;print(json.load(open('/home/ana/server/links/demo/cluster.json'))[0]['code'])")
NEW2="curl -s -H 'content-type: application/json' -d '{\"url\": \"https://example.com/\"}' http://127.0.0.1:3000/links"
session $L "for i in 1 2 3 4 5 6 7 8; do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/$code; done; echo" "$NEW2" 'cat demo/cluster.json'
bg_stop lc INT; sleep 0.5
block links-cluster-log
bg_show lc
printf '^C\n'

# npm and SIGTERM.
bg n $L 'npm start'; wait_port 3000; sleep 0.3
npmpid=$(pgrep -u ana -f '^npm start' | head -1)
block npm
session $L "pgrep -a 'npm|node'" "kill -TERM $npmpid" "sleep 1; pgrep -a 'npm|node'"
nodepid=$(pgrep -u ana -f 'node --env-file-if-exists=.env server.js' | grep -v "^$(pgrep -u ana -f '^sh -c' | head -1)$" | tail -1)
session $L "kill -TERM $nodepid"
sleep 0.5
block npm-log
bg_show n
bg_stop n
quiet $L 'rm -rf data'
