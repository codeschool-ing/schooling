#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: `the-lab` says how to get
# Python and curl, and `the-app` shows boxoffice.py whole. ../../lab.sh app
# extracts the program from that section, so what runs here is the block the
# student copies. What is STAGED rather than typed:
#   - the server in "start" runs with PYTHONUNBUFFERED=1 and is stopped by
#     `timeout` after two seconds, so its first line reaches the transcript;
#   - "health" and the failures run against a server started by lab.sh with
#     BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab;
#   - in "fail-indent", one line of boxoffice.py re-indented with sed, and the
#     file written again from the lesson straight after.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
cd "$APP" || exit 1

block setup-tools
run 'python3 --version'
run 'curl --version | head -n 1'

block start
printf 'ana@laptop:~/boxoffice$ python3 boxoffice.py\n'
PYTHONUNBUFFERED=1 BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 timeout 2 python3 boxoffice.py 2>&1

block health
bash "$LAB" serve "$APP" || exit 1
cd "$HOME"
run 'curl http://127.0.0.1:8000/health'

block fail-port
cd "$APP"
printf 'ana@laptop:~/boxoffice$ python3 boxoffice.py\n'
python3 boxoffice.py 2>&1
bash "$LAB" stop

block fail-refused
run 'curl http://127.0.0.1:8000/health'

block fail-where
cd "$HOME"
run 'python3 boxoffice.py'

block fail-indent
cd "$APP"
sed -i 's/^    reais = f"{cents/  reais = f"{cents/' boxoffice.py
printf 'ana@laptop:~/boxoffice$ python3 boxoffice.py\n'
python3 boxoffice.py 2>&1
bash "$LAB" app "$APP"
