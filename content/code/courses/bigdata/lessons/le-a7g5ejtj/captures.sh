#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l08.txt
#
# Needs the machine lesson 1 builds, with the cluster running, and the silver
# layer of lesson 5. Every program is taken out of the lesson's .md by
# `lab.sh extract`. skew.py runs first because it writes data/silver/visitors,
# which every later program reads.
#
# aqe_skew.py lowers adaptive execution's skew thresholds, as the lesson shows
# and says why: at the defaults (256 MB, five times the median) nothing in this
# lab's 400 MB of data counts as skewed, and an earlier run left the plan
# without skew=true.
#
# too_big.py fails by design; `grep` keeps the warning and the one line of the
# stack trace that names the failure.
#
# The figure l08-skew is drawn from the per-task shuffle reads of skew.py's
# join stage in the run recorded on the date below, read back from the history
# server of lesson 7 (applications?limit, then stages/N/0/taskList?length=200).
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
lab exec 'rm -rf data/tmp data/silver/visitors' >/dev/null 2>&1
put what-skew-looks-like.md spread.py
put what-skew-looks-like.md skew.py
put finding-the-hot-key.md hot_key.py
put broadcast-join.md join_times.py
put when-broadcast-hurts.md too_big.py
put salting.md salting.py
put aqe-skew-join.md aqe_skew.py
put repartition-and-coalesce.md repartition.py
put partitioning-on-write.md write_files.py

block skew
on 'spark-submit skew.py'
block hot-key
on 'spark-submit hot_key.py'
block join-times
on 'spark-submit join_times.py'
block too-big
on "spark-submit too_big.py 2>&1 | grep -E 'WARN|SparkException'"
block salting
on 'spark-submit salting.py'
block aqe-skew
on 'spark-submit aqe_skew.py'
block repartition
on 'spark-submit repartition.py'
block write-files
on 'spark-submit write_files.py'
