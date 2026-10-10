#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of manual-testing (exploratory
# testing), as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh            # every block, ~75 min
#   bash ../../lab.sh isolated bash captures.sh quick      # all but "evening"
#   bash ../../lab.sh isolated bash captures.sh evening    # only "evening"
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: boxoffice.py is lesson 1's,
# and the 1.1 edits are lesson 9's. ../../lab.sh app and release extract both
# from those sections, so what runs here is what the student has. What is
# STAGED rather than typed:
#   - "orders", "cancelled" and "frozen" run against a server started by
#     lab.sh with BOXOFFICE_SEED=lab and BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     (the first two) or 2026-10-10T20:30 ("frozen"), written with no offset so it
#     reads as the machine's local time; the start line of "frozen-start" is
#     printed by a copy run under `timeout` with PYTHONUNBUFFERED=1;
#   - "evening" needs a clock that MOVES, so its server runs with
#     BOXOFFICE_NOW empty (the machine's real clock) and with TZ set to a
#     fixed offset chosen when the block starts, so that the machine's local
#     time reads 18:50 at that moment. The block then really waits until the
#     local clock passes 20:01 before the refund, about seventy minutes. The
#     times `date +%H:%M` prints are the times the application's clock read.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo apart from "evening". Run as root with HOME=/home/ana,
# so the paths read as Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
MODE=${1:-all}
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" && bash "$LAB" release "$APP" || exit 1
cd "$APP" || exit 1
U=http://127.0.0.1:8000

if [ "$MODE" != evening ]; then

block orders
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1001&action=use' $U/order | grep msg"
run "curl -s -d 'id=1001&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1001&action=use' $U/order | grep msg"
run "curl -s -d 'id=1001&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1001&action=cancel' $U/order | grep msg"
run "curl -s -d 'id=1001&action=refund' $U/order | grep msg"

block cancelled
run "curl -s -d 'email=member@example.org&show=S3&quantity=1' $U/book | grep msg"
run "curl -s -d 'id=1002&action=cancel' $U/order | grep msg"
run "curl -s -d 'id=1002&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1002&action=dance' $U/order | grep msg"
bash "$LAB" stop

block frozen-start
printf 'ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T20:30 python3 boxoffice.py\n'
PYTHONUNBUFFERED=1 BOXOFFICE_NOW=2026-10-10T20:30 timeout 2 python3 boxoffice.py 2>&1

block frozen
bash "$LAB" serve "$APP" BOXOFFICE_NOW=2026-10-10T20:30 || exit 1
run "curl -s -d 'email=member@example.org&show=S1&quantity=2' $U/book | grep msg"
bash "$LAB" stop

fi

if [ "$MODE" != quick ]; then

block evening
# a fixed offset that makes local time 18:50 now; POSIX writes UTC+h as -h
off=$(( (18*60 + 50) - ( $(date -u +%-H)*60 + $(date -u +%-M) ) ))
off=$(( (off + 720 + 1440) % 1440 - 720 ))
sign=-; [ $off -lt 0 ] && { sign=+; off=$(( -off )); }
STAGED_TZ=$(printf '<LAB>%s%d:%02d' "$sign" $((off/60)) $((off%60)))
export TZ=$STAGED_TZ
bash "$LAB" serve "$APP" BOXOFFICE_NOW= TZ="$STAGED_TZ" PYTHONUNBUFFERED=1 || exit 1
printf 'ana@laptop:~/boxoffice$ python3 boxoffice.py\n'
head -n 1 "$APP/server.log"
block evening-book
run 'date +%H:%M'
run "curl -s -d 'email=member@example.org&show=S1&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1001&action=pay' $U/order | grep msg"
until [ "$(date +%H%M)" -ge 2001 ]; do sleep 20; done
block evening-refund
run 'date +%H:%M'
run "curl -s -d 'id=1001&action=refund' $U/order | grep msg"
bash "$LAB" stop

fi
