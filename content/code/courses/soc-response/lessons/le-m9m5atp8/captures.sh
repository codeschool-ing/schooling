#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds.
#
# STAGED, NOT TYPED: context.sh, beside this script, is the file the lesson
# prints and tells the student to write; it is copied into ~/week. week.py and
# load.py are run again first, so siem.db holds exactly lesson 4's rows.
#
# Recorded on Ubuntu 24.04 with sqlite3 3.45.1.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

install -o ana -g ana -m 644 "$HERE/context.sh" /home/ana/week/context.sh
runuser -u ana -- bash -c 'cd ~/week && python3 week.py && python3 load.py' >/dev/null

block helena
ana 'bash context.sh 203.0.113.41'

block visitor
ana 'bash context.sh 203.0.113.66'

block bruno
ana "sqlite3 -header -column siem.db \"SELECT datetime(timestamp, '-3 hours') AS local, host, method, src_ip FROM logs WHERE user = 'bruno' AND action = 'success'\""

block night
ana "sqlite3 -header -column siem.db \"SELECT datetime(timestamp, '-3 hours') AS local, product, src_ip, dst_ip, dst_port, bytes FROM logs WHERE timestamp BETWEEN '2026-09-17 05:30' AND '2026-09-17 06:30' AND product IN ('firewall', 'flow') ORDER BY timestamp\""
