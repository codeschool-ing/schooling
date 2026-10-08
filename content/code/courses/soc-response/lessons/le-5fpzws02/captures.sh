#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds, with lesson 4's
# sigma-cli in ~/sigma.
#
# STAGED, NOT TYPED: big-upload.yml, beside this script, is the rule the lesson
# prints and tells the student to write; it is copied into ~/week. week.py and
# load.py are run again first, so siem.db holds lesson 4's rows.
#
# Recorded on Ubuntu 24.04 with sqlite3 3.45.1 and sigma-cli 3.1.0.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

install -o ana -g ana -m 644 "$HERE/big-upload.yml" /home/ana/week/big-upload.yml
runuser -u ana -- bash -c 'cd ~/week && python3 week.py && python3 load.py' >/dev/null

block stack
ana "sqlite3 -header -column siem.db \"SELECT user, src_ip, count(*) AS logins FROM logs WHERE action = 'success' GROUP BY user, src_ip ORDER BY logins\""

block files
ana "sqlite3 -header -column siem.db \"SELECT src_ip, count(*) AS n FROM logs WHERE host = 'files' GROUP BY src_ip\""

block hours
ana "sqlite3 -header -column siem.db \"SELECT strftime('%H', timestamp, '-3 hours') AS hour_local, count(*) AS logins FROM logs WHERE action = 'success' GROUP BY hour_local\""

block rule
ana '~/sigma/bin/sigma convert -t sqlite big-upload.yml'
ana '~/sigma/bin/sigma convert -t sqlite big-upload.yml -o big.sql'
ana "sqlite3 -header -column siem.db \"SELECT timestamp, src_ip, dst_ip, bytes FROM (\$(cat big.sql))\""
