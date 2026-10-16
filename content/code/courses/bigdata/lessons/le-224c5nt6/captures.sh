#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l09.txt
#
# Needs the machine lesson 1 builds, with the cluster running, the silver
# layer of lesson 5 and stages.py of lesson 7. Every program is taken out of
# the lesson's .md by `lab.sh extract`.
#
# lost.py kills one of the cluster's executors on purpose. The worker starts
# a new one, so the cluster is whole again when the next program runs.
#
# pagerank.py without a cache takes about ten minutes; that is the point.
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
lab exec 'rm -rf checkpoints' >/dev/null 2>&1
put ../le-k6pp4p8q/jobs-stages-tasks.md stages.py
put computing-twice.md twice.py
put storage-levels.md storage.py
put losing-a-cached-partition.md lost.py
put an-iterative-loop.md pagerank.py
put lineage.md lineage.py

block twice
on 'spark-submit twice.py'
block storage
on 'spark-submit storage.py'
block lost
on 'spark-submit lost.py'
block pagerank
on 'spark-submit pagerank.py'
block pagerank-cache
on 'spark-submit pagerank.py cache'
block lineage
on 'spark-submit lineage.py'
block lineage-checkpoint
on 'spark-submit lineage.py checkpoint'
