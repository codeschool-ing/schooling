#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l07.txt
#
# Needs the machine lesson 1 builds, with the cluster running, and the silver
# layer of lesson 5. Every program is taken out of the lesson's .md by
# `lab.sh extract`.
#
# THE HISTORY SERVER of section 11 is set up by the lesson's own two lines,
# taken out of history-server.md, after any earlier copy of the line in
# spark-defaults.conf has been removed and any running history server stopped.
#
# collect_all.py is run with spark.driver.maxResultSize lowered to 100m, as the
# lesson shows and says why. An earlier run with the default 1g did not trip
# the guard: it lost task results from the executors' block managers four times
# and aborted with TaskResultLost, a less instructive failure; the lesson does
# not quote it.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.13, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
lab exec 'stop-history-server.sh; sed -i "/spark.history.fs.logDirectory/d" ~/spark/conf/spark-defaults.conf; rm -rf data/tmp' >/dev/null 2>&1
put jobs-stages-tasks.md stages.py
put jobs-stages-tasks.md jobs_stages.py
put shuffle-files.md shuffle_files.py
put executor-memory.md memory.py
put spilling.md spill.py
put the-driver.md collect_all.py

block jobs-stages
on 'spark-submit jobs_stages.py'
block shuffle-files
on 'spark-submit shuffle_files.py'
block memory
on 'spark-submit memory.py'
block spill
on 'spark-submit spill.py'
block collect
on "spark-submit --conf spark.driver.maxResultSize=100m collect_all.py 2>&1 | grep -m 1 ERROR"
lab exec "$(lab fence "$HERE/history-server.md" 1)" >/dev/null 2>&1
sleep 10
block history
on "curl -s 'localhost:18080/api/v1/applications?limit=6' | jq -c '.[] | {id, name, duration: .attempts[0].duration}'"
