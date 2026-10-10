#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: boxoffice.py from lesson 1
# with lesson 9's 1.1 edits, make_accounts.py from section `generating-data`
# and pseudonymise.py from section `anonymising` of this lesson. Both programs
# are EXTRACTED from those sections here, under the sentences "Save it as
# `make_accounts.py`" and "Save it as `pseudonymise.py`", so what runs is the
# block the student copies. What is STAGED rather than typed:
#   - boxoffice 1.1 runs in the background, started by lab.sh with
#     BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab;
#   - in "restart", the student's Ctrl-C and `python3 boxoffice.py` in the
#     other terminal are lab.sh stop and serve.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

ME=$(cd "$(dirname "$0")" && pwd)
LAB=$ME/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
bash "$LAB" release "$APP" || exit 1

# extract FILE.md NAME: the fence under "Save it as `NAME`", into $APP/NAME
extract() {
  python3 - "$1" "$2" "$APP/$2" <<'PY' || { echo "no $2 in $1" >&2; exit 1; }
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
m = re.search(r"Save it as `" + re.escape(sys.argv[2]) + r"`[^`]*?:\n+```[a-z]*\n(.*?)^```$", text, re.S | re.M)
if not m:
    sys.exit(1)
pathlib.Path(sys.argv[3]).write_text(m.group(1))
PY
}
extract "$ME/generating-data.md" make_accounts.py
extract "$ME/anonymising.md" pseudonymise.py
bash "$LAB" serve "$APP" || exit 1
cd "$APP" || exit 1

block generate
run 'python3 make_accounts.py 5'

block csv
run 'cat accounts.csv'

block outbox
run "curl -s http://127.0.0.1:8000/outbox | grep -c '<h2>Confirm your account</h2>'"

block again
run 'python3 make_accounts.py 5'

block restart
bash "$LAB" serve "$APP" || exit 1
run 'python3 make_accounts.py 5'

block pseudo
run 'PSEUDONYM_KEY=vila-test-key python3 pseudonymise.py accounts.csv'

block pseudo-key
run 'PSEUDONYM_KEY=vila-test-key python3 pseudonymise.py accounts.csv'
run 'PSEUDONYM_KEY=another-key python3 pseudonymise.py accounts.csv'

block pseudo-nokey
run 'python3 pseudonymise.py accounts.csv'
