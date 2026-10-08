#!/usr/bin/env bash
# The terminal session quoted in lesson 15 of soc-response, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds.
#
# STAGED, NOT TYPED: milestones.sql, beside this script, is the file the lesson
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

install -o ana -g ana -m 644 "$HERE/milestones.sql" /home/ana/week/milestones.sql
runuser -u ana -- bash -c 'cd ~/week && python3 week.py && python3 load.py' >/dev/null

block intervals
ana 'sqlite3 siem.db < milestones.sql'
