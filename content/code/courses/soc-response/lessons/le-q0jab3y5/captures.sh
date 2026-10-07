#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds, with lesson 4's
# sigma-cli in ~/sigma and its alerts.sh in ~/week.
#
# STAGED, NOT TYPED: dashboard.sql, spray.yml, grouped.sh and sweep.sh, beside
# this script, are the files the lesson prints and tells the student to write;
# they are copied into ~/week. week.py and load.py are run again first, so
# siem.db holds exactly lesson 4's rows.
#
# Recorded on Ubuntu 24.04 with sqlite3 3.45.1 and sigma-cli 3.1.0.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

for f in dashboard.sql spray.yml grouped.sh sweep.sh; do
  install -o ana -g ana -m 644 "$HERE/$f" /home/ana/week/$f
done
runuser -u ana -- bash -c 'cd ~/week && python3 week.py && python3 load.py' >/dev/null

block dashboard
ana 'sqlite3 siem.db < dashboard.sql'

block flood
ana '~/sigma/bin/sigma convert -t sqlite spray.yml -o spray.sql'
ana 'bash alerts.sh spray.sql | head -n 5'
ana 'bash alerts.sh spray.sql | tail -n +3 | wc -l'

block grouped
ana 'bash grouped.sh spray.sql'

block sweep
ana 'bash sweep.sh'
