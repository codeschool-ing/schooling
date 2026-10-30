#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of mobile-fundamentals, as a script
# that produces them. The output is not committed: lab/fill.py pastes each
# block into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's planner.ts and package.json, taken out of
#     lesson 1's the-planner.md, as the student has them by now.
#   - api.ts, fetchweek.ts and screen.ts are taken out of this lesson's own
#     sections by lab/extract.py, so the program each transcript ran is the
#     one the lesson prints.
#   - The server runs in the background (`serve`), where the student runs it
#     in a second terminal. "server-log" prints the prompt the student typed
#     there and what the server had printed by then, read from its log.
#     "Ctrl+C in its terminal" in honest-states is `unserve`. The log's
#     one `GET /` is serve's own readiness probe, and is left out.
#   - "default-limit" waits for Node.js's own limit on a request that never
#     answers, which is five minutes: this script takes that long.
#   - screen.ts is given "now" as an argument, so the ages it prints repeat.
#
# Timings (curl's time_total, the "after N s" lines) are measured, and vary from
# run to run; the lesson says so where it quotes them.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md planner.ts $P/planner.ts
put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put a-server-that-misbehaves.md api.ts $P/api.ts
put timeouts.md fetchweek.ts $P/fetchweek.ts
put honest-states.md screen.ts $P/screen.ts

serve $P 8014 'node api.ts'

W='-w "  %{http_code} in %{time_total} s\n"'
block curl
run $P "curl -sS $W http://127.0.0.1:8014/week"
run $P "curl -sS $W http://127.0.0.1:8014/slow"
run $P "curl -sS $W http://127.0.0.1:8014/flaky"
run $P "curl -sS $W http://127.0.0.1:8014/flaky"
run $P "curl -sS $W http://127.0.0.1:8014/flaky"
run $P "curl -sS --max-time 3 $W http://127.0.0.1:8014/hang; echo \"exit \$?\""

block outer
run $P 'timeout 5 node fetchweek.ts /hang; echo "exit $?"'

block default-limit
run $P 'node fetchweek.ts /hang'

block deadline
run $P 'node fetchweek.ts /hang --timeout 2000'
run $P 'node fetchweek.ts /slow --timeout 5000'

block leave
run $P 'node fetchweek.ts /slow --leave 1000'

block retry
run $P 'node fetchweek.ts /flaky --retries 2'
run $P 'node fetchweek.ts /flaky'

block server-log
printf 'ana@dev:~/planner$ node api.ts\n'
grep -vx "GET /" "$H/.serve.log" # the one GET / is serve's probe

block states
run $P 'node screen.ts 2026-10-21T08:30:00-03:00'
run $P 'cat week.json'
unserve
run $P 'node screen.ts 2026-10-21T10:45:00-03:00'
run $P 'rm week.json'
run $P 'node screen.ts 2026-10-21T10:46:00-03:00'
