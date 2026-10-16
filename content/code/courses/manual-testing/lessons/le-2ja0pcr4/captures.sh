#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of manual-testing (exploratory
# testing), as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh            # every block
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
#   - "evening" needs a clock that MOVES with orders in hand, which boxoffice
#     cannot do: BOXOFFICE_NOW is fixed for a process and a restart empties it.
#     So its server is boxoffice.py, unchanged, run inside a small wrapper that
#     starts the clock at 2026-10-10T18:50:00-03:00 and moves it to
#     2026-10-10T20:01:00-03:00 between the payment and the refund, in the same
#     process. The lesson says so beside the transcript: on the student's own
#     machine that hour is a real one.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana,
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
# The application's clock is moved INSIDE one running process: the wrapper runs
# boxoffice.py unchanged as __main__ in a thread, and sets BOXOFFICE_NOW in that
# process's environment whenever $CLOCK is written. now() reads the variable on
# every call, so the orders stay and the time moves. boxoffice offers no such
# control; it stands in for the hour a student waits on the real clock.
CLOCK=$APP/clock
cat > "$APP/../moving-clock.py" <<'PY'
import os, runpy, sys, threading, time
os.environ["BOXOFFICE_NOW"] = sys.argv[2]
threading.Thread(target=runpy.run_path, args=(sys.argv[1],), kwargs={"run_name": "__main__"},
                 daemon=True).start()
while True:
    if os.path.exists(sys.argv[3]):
        os.environ["BOXOFFICE_NOW"] = open(sys.argv[3]).read().strip()
        os.remove(sys.argv[3])
    time.sleep(0.05)
PY
( BOXOFFICE_SEED=lab PYTHONUNBUFFERED=1 python3 "$APP/../moving-clock.py" "$APP/boxoffice.py" \
    2026-10-10T18:50:00-03:00 "$CLOCK" ) </dev/null >"$APP/evening.log" 2>&1 &
MOVER=$!
for _ in $(seq 50); do curl -sf $U/health >/dev/null && break; sleep 0.1; done
printf 'ana@laptop:~/boxoffice$ python3 boxoffice.py\n'
head -n 1 "$APP/evening.log"
block evening-book
run "curl -s -d 'email=member@example.org&show=S1&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1001&action=pay' $U/order | grep msg"
echo 2026-10-10T20:01:00-03:00 > "$CLOCK"
while [ -e "$CLOCK" ]; do sleep 0.05; done
block evening-refund
run "curl -s -d 'id=1001&action=refund' $U/order | grep msg"
kill $MOVER

fi
