#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds. week.py and
# load.py are run again first, so siem.db holds lesson 4's rows, and the two
# small text files of the first block are removed before it starts.
#
# Recorded on Ubuntu 24.04 with sqlite3 3.45.1.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

runuser -u ana -- bash -c 'cd ~/week && rm -f -- a.txt b.txt && python3 week.py && python3 load.py' >/dev/null

block hashes
ana "printf 'quarterly figures, version 1\n' > a.txt"
ana "printf 'quarterly figures, version 2\n' > b.txt"
ana 'sha256sum a.txt b.txt'

block detail
ana "sqlite3 -header -column siem.db \"SELECT src_ip, detail, count(*) AS n FROM logs WHERE src_ip IN ('203.0.113.66', '203.0.113.23') AND action = 'failure' GROUP BY 1, 2\""

block methods
ana "sqlite3 -header -column siem.db \"SELECT user, method, count(*) AS logins, min(datetime(timestamp, '-3 hours')) AS first_local FROM logs WHERE action = 'success' GROUP BY user, method\""

block destinations
ana "sqlite3 -header -column siem.db \"SELECT dst_ip, count(*) AS transfers, min(datetime(timestamp, '-3 hours')) AS first_local, sum(bytes) / 1000000 AS mb FROM logs WHERE product = 'flow' GROUP BY dst_ip\""
