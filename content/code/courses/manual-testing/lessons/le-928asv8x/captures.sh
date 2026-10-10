#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE COURSE: boxoffice.py from lesson 1
# section `the-app`, with the three 1.1 edits of lesson 9 section `release-1-1`
# applied (../../lab.sh app and release extract both from those sections). What
# is STAGED rather than typed:
#   - each server is started by lab.sh in the background, with
#     PYTHONUNBUFFERED=1 so its first line reaches server.log, and that line is
#     printed under the command the student types in the first terminal; the
#     student's command starts it in the foreground instead and prints the same
#     line;
#   - BOXOFFICE_SEED=lab, which changes nothing this lesson prints;
#   - TZ and BOXOFFICE_NOW are exactly what each printed command sets;
#   - "record" runs with TZ=America/Sao_Paulo and lab.sh's default
#     BOXOFFICE_NOW=2026-10-10T14:00:00-03:00, and `date` reads the machine's
#     real clock, so it prints the moment the capture was run.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0.
# Run as root with HOME=/home/ana, so the paths read as Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
bash "$LAB" release "$APP" || exit 1
cd "$APP" || exit 1

BOOK="curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg"

# start ZONE MOMENT: print what the student types, start it, print its first line
start() {
  printf 'ana@laptop:~/boxoffice$ TZ=%s BOXOFFICE_NOW=%s python3 boxoffice.py\n' "$1" "$2"
  bash "$LAB" serve "$APP" TZ="$1" BOXOFFICE_NOW="$2" PYTHONUNBUFFERED=1 || exit 1
  head -n 1 "$APP/server.log"
}

block sp-start
start America/Sao_Paulo 2026-10-10T17:30:00-03:00
block sp-book
run "$BOOK"

block utc-start
start UTC 2026-10-10T17:30:00-03:00
block utc-book
run "$BOOK"
block utc-home
run "curl -s http://127.0.0.1:8000/ | grep -o '<td>The Seagull</td><td>[^<]*</td>'"

block edge-1559-start
start UTC 2026-10-10T15:59:00-03:00
block edge-1559-book
run "$BOOK"
block edge-1601-start
start UTC 2026-10-10T16:01:00-03:00
block edge-1601-book
run "$BOOK"

block record
bash "$LAB" serve "$APP" || exit 1
run 'python3 --version'
run 'grep PRETTY_NAME /etc/os-release'
run 'date'
run 'curl -s http://127.0.0.1:8000/health'
