#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds.
#
# STAGED, NOT TYPED: timeline.sql, beside this script, is the file the lesson
# prints and tells the student to write; it is copied into ~/week. week.py and
# load.py are run again first, so siem.db holds lesson 4's rows.
#
# Recorded on Ubuntu 24.04 with sqlite3 3.45.1.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

install -o ana -g ana -m 644 "$HERE/timeline.sql" /home/ana/week/timeline.sql
runuser -u ana -- bash -c 'cd ~/week && python3 week.py && python3 load.py' >/dev/null

block accounts
ana "sqlite3 -header -column siem.db \"SELECT DISTINCT user FROM logs WHERE src_ip = '203.0.113.66' AND action = 'success'\""

block hosts
ana "sqlite3 -header -column siem.db \"SELECT host, src_ip, count(*) AS logins FROM logs WHERE user = 'bruno' AND action = 'success' AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30' GROUP BY host, src_ip\""

block outbound
ana "sqlite3 -header -column siem.db \"SELECT dst_ip, dst_port, count(*) AS n FROM logs WHERE src_ip = '192.168.20.10' AND product = 'firewall' AND timestamp BETWEEN '2026-09-17 05:00' AND '2026-09-17 06:30' GROUP BY 1, 2\""

block timeline
ana 'sqlite3 siem.db < timeline.sql'
