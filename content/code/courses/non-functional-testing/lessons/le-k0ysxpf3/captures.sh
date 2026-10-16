#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built by `lab.sh build` with
# Node.js v24.21.0 unpacked into /usr/local and Artillery 2.0.34 installed
# globally by the lines "Node.js, then Artillery" prints (with Artillery's
# optional browser download skipped, which this course never uses), and with
# Vegeta built from the v12.13.0 source, because the recording computer cannot
# reach GitHub, so the install lines in "Vegeta, one program" were not run;
# lesson 1's box office and this lesson's scenario, copied out of the sections
# that show them by `shown`; a fresh database from seed.py. The server runs in
# the background, where the lesson has the student run it in a first terminal.
# Every timing differs on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l07
shown "$L1/the-boxoffice.md" "$HERE_DIR/artillery.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

at '~'
block node
run 'node --version; npm --version; artillery --version'

block vegeta-version
run 'vegeta -version'

at '~/artillery'
block artillery-run
run 'artillery run boxoffice.yml > run.log; echo "exit $?"'
run "sed -n '/Summary report/,\$p' run.log"

block artillery-fail
run "artillery run boxoffice.yml --overrides '{\"config\": {\"ensure\": {\"thresholds\": [{\"http.response_time.p95\": 5}]}}}' > fail.log; echo \"exit \$?\""
run "sed -n '/^Checks/,\$p' fail.log"

at '~'
block vegeta-run
run 'echo "GET http://127.0.0.1:8000/shows/990" | vegeta attack -rate=50 -duration=10s | tee results.bin | vegeta report'

block vegeta-hist
run "vegeta report -type='hist[0,20ms,40ms,60ms,100ms,200ms]' results.bin"

block vegeta-over
run 'echo "GET http://127.0.0.1:8000/shows/990" | vegeta attack -rate=300 -duration=5s -timeout=5s | vegeta report'

stop
