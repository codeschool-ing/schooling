#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of soc-response, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana in ~/week, the folder lesson 4 builds.
#
# STAGED, NOT TYPED: intel.json and match.py, beside this script, are the files
# the lesson prints in full and tells the student to write; they are copied
# into ~/week. intel.json is an example written for the course, in STIX 2.1,
# about the course's own documentation addresses; no sharing group sent it.
# week.py and load.py are run again first, so siem.db holds lesson 4's rows.
#
# Recorded on Ubuntu 24.04 with jq 1.7 and sqlite3 3.45.1.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~/week$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd ~/week; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

for f in intel.json match.py; do install -o ana -g ana -m 644 "$HERE/$f" /home/ana/week/$f; done
runuser -u ana -- bash -c 'cd ~/week && python3 week.py && python3 load.py' >/dev/null

block types
ana "jq -r '.objects[] | [.type, .name] | @tsv' intel.json"

block indicators
ana "jq '.objects[] | select(.type == \"indicator\") | {name, pattern, valid_until, confidence}' intel.json"

block match
ana 'python3 match.py intel.json'
