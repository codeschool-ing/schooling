#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of bigdata, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh > /tmp/l14.txt
#
# Needs the machine lesson 1 builds, with the cluster running, the silver and
# raw layers, and lesson 7's history server running on port 18080. Every
# program is taken out of the lesson's .md by `lab.sh extract`.
#
# The DuckDB environment is made by the lesson's own two lines, taken out of
# duckdb.md, after any earlier ~/duck-env has been removed; pip's output is
# not quoted, and pip needs the sandbox's proxy, which ana's clean
# environment does not carry.
#
# history.py reads the newest finished application named "report", so it is
# run straight after the run it describes; the history server needs a few
# seconds to see an application has ended, hence the pause before it.
#
# Timings are one run each, on a machine shared with other work.
# Recorded on Ubuntu 24.04, OpenJDK 17, Spark 4.1.3, Python 3.13, DuckDB
# 1.5.6, 4 cores, TZ=America/Sao_Paulo, on 2026-10-16.
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAB="$HERE/../../lab.sh"
lab() { bash "$LAB" "$@"; }
on() { printf 'ana@lab:~/big$ %s\n' "$*"; printf '%s\n' "$*" > /tmp/cmd.sh; chmod 644 /tmp/cmd.sh; lab exec 'bash /tmp/cmd.sh' 2>&1; }
block() { printf '##### %s\n' "$1"; }
put() { lab extract "$HERE/$1" "$2" | lab exec "cat > $2"; }

lab start >/dev/null 2>&1
lab exec 'rm -rf ~/duck-env' >/dev/null 2>&1
runuser -u ana -- env -i HOME=/home/ana PATH=/usr/bin:/bin HTTPS_PROXY="$HTTPS_PROXY" \
  PIP_CERT=/etc/ssl/certs/ca-certificates.crt bash -c "cd ~ && $(lab fence "$HERE/duckdb.md" 1)" >/dev/null 2>&1
put the-slow-report.md report.py
put reading-a-finished-job.md history.py
put duckdb.md report_duckdb.py

block slow
on 'spark-submit report.py --csv --udf --partitions 2000 --no-broadcast 2>/dev/null'
sleep 15
block history-slow
on 'python3 history.py report'
block fixes
on 'spark-submit report.py --udf --partitions 2000 --no-broadcast 2>/dev/null'
on 'spark-submit report.py --partitions 2000 --no-broadcast 2>/dev/null'
on 'spark-submit report.py --no-broadcast 2>/dev/null'
on 'spark-submit report.py 2>/dev/null'
sleep 15
block history-fast
on 'python3 history.py report'
block duckdb
on '~/duck-env/bin/python report_duckdb.py'
