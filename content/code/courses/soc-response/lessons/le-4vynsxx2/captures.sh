#!/usr/bin/env bash
# The terminal session quoted in lesson 21 of soc-response, as a script that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash captures.sh OUTDIR
#
# Everything runs as ana, in the home folder of that account.
#
# STAGED, NOT TYPED: prazo.py, beside this script, is the program the lesson
# prints and tells the student to write; it is copied into ana's home folder.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
OUT=${1:?outdir}; mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
ENV='HOME=/home/ana PATH=/usr/local/bin:/usr/bin:/bin TZ=America/Sao_Paulo LANG=C.UTF-8 COLUMNS=100'
ana() { printf 'ana@soc:~$ %s\n' "$*"; runuser -u ana -- env -i $ENV bash -c "cd; $*" 2>&1; }
block() { exec >"$OUT/$1.txt"; }

install -o ana -g ana -m 644 "$HERE/prazo.py" /home/ana/prazo.py

block deadlines
ana 'python3 prazo.py 2026-09-17 3'
ana 'python3 prazo.py 2026-09-17 6'
ana 'python3 prazo.py 2026-09-22 20'
