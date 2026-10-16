#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of manual-testing (sanity testing),
# as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: boxoffice.py is lesson 1's,
# and section `release-1-1` of this lesson shows the three edits that make
# 1.1. ../../lab.sh app and release extract both from those sections, so what
# runs here is what the student has after editing. What is STAGED rather than
# typed:
#   - the edits themselves, which the student makes in an editor, are applied
#     by lab.sh release, after the copy to boxoffice-1.0.py the section asks for;
#   - the server in "start" runs with PYTHONUNBUFFERED=1 and is stopped by
#     `timeout` after two seconds, so its first line reaches the transcript;
#   - every other block runs against a server started by lab.sh with
#     BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab.
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
cp boxoffice.py boxoffice-1.0.py
bash "$LAB" release "$APP" || exit 1
U=http://127.0.0.1:8000

block start
printf 'ana@laptop:~/boxoffice$ python3 boxoffice.py\n'
PYTHONUNBUFFERED=1 BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 timeout 2 python3 boxoffice.py 2>&1

block smoke
bash "$LAB" serve "$APP" || exit 1
run "curl $U/health"

block six
run "curl -s -d 'email=member@example.org&show=S2&quantity=6' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=7' $U/book | grep msg"

block member-five
run "curl -s -d 'email=member@example.org&show=S2&quantity=5' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=member@example.org&show=S2&quantity=4' $U/book | grep -A1 'off:'"
bash "$LAB" stop
