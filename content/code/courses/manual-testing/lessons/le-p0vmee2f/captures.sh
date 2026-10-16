#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE TEST FILES ARE EXTRACTED FROM THE LESSON, never kept here: each of
# test_discount.py (a-unit-test), test_booking.py (integration) and
# test_signup.py (test-doubles) is the `schooling-example` whose "file" names
# it, and the program is its parts joined by a newline, which is what the copy
# button on the block hands the student. So what runs here is what the student
# copies, byte for byte.
#
# What is STAGED rather than typed:
#   - boxoffice.py is 1.0 from lesson 1 with the 1.1 edits of lesson 9 applied
#     (../../lab.sh app, then release), which is the student's file by now;
#   - in "integration-up", "mock" and the two "clock" blocks the server is
#     started by lab.sh with BOXOFFICE_SEED=lab and, unless the block sets its
#     own, BOXOFFICE_NOW=2026-10-10T14:00:00-03:00;
#   - in "clock-start" the server runs with PYTHONUNBUFFERED=1 and is stopped by
#     `timeout` after two seconds, so its first line reaches the transcript.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

LESSON=$(cd "$(dirname "$0")" && pwd)
LAB=$LESSON/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" && bash "$LAB" release "$APP" || exit 1

# extract FILE: write the program of the example named FILE into $APP/FILE
extract() {
  python3 - "$LESSON" "$1" "$APP/$1" <<'PY' || { echo "no example named $1 in the lesson" >&2; exit 1; }
import glob, json, pathlib, re, sys
here, name, out = sys.argv[1:]
for md in sorted(glob.glob(here + '/*.md')):
    if md.endswith('.pt.md'):
        continue
    for m in re.finditer(r'^```schooling-example\n(.*?)^```$', pathlib.Path(md).read_text(), re.S | re.M):
        ex = json.loads(m.group(1))
        if ex.get('file') == name:
            pathlib.Path(out).write_text('\n'.join(p['code'] for p in ex['parts']) + '\n')
            sys.exit(0)
sys.exit(1)
PY
}

cd "$APP" || exit 1

block unit
extract test_discount.py
run 'python3 -m unittest -v'

block integration-down
extract test_booking.py
run "python3 -m unittest test_booking 2>&1 | grep -E 'ERROR|URLError|FAILED'"

block integration-up
bash "$LAB" serve "$APP" || exit 1
run 'python3 -m unittest -v test_booking'

block mock
extract test_signup.py
run 'python3 -m unittest -v test_signup'
bash "$LAB" stop

block clock-start
printf 'ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T19:30:00-03:00 python3 boxoffice.py\n'
PYTHONUNBUFFERED=1 BOXOFFICE_NOW=2026-10-10T19:30:00-03:00 timeout 2 python3 boxoffice.py 2>&1

block clock-1930
bash "$LAB" serve "$APP" BOXOFFICE_NOW=2026-10-10T19:30:00-03:00 || exit 1
cd "$HOME"
run "curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg"

block clock-1830
bash "$LAB" serve "$APP" BOXOFFICE_NOW=2026-10-10T18:30:00-03:00 || exit 1
run "curl -s -d 'email=member@example.org&show=S1&quantity=2' http://127.0.0.1:8000/book | grep msg"
