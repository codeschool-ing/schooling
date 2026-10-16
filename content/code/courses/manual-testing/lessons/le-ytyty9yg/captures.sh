#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: lesson 18 section
# `a-spreadsheet-first` shows cases.csv whole, and section `junit-xml` of this
# lesson shows to_junit.py whole. Both are EXTRACTED from those sections here,
# under the sentences "Save it as `cases.csv`" and "Save it as `to_junit.py`",
# so what runs is the block the student copies. What is STAGED rather than
# typed: nothing in the quoted blocks needs boxoffice running.
#
# The last block, "check-1.1", is not quoted anywhere. It runs the checkable
# cases of cases.csv against boxoffice 1.1, started by lab.sh with
# BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab, so a reviewer
# can see that the 1.1 column records what 1.1 does.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

ME=$(cd "$(dirname "$0")" && pwd)
LAB=$ME/../../lab.sh
L18=$ME/../le-1t81t6vm/a-spreadsheet-first.md
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1

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
extract "$L18" cases.csv
extract "$ME/junit-xml.md" to_junit.py
cd "$APP" || exit 1

block junit-1-1
run 'python3 to_junit.py cases.csv 1.1 > results-1.1.xml'
run 'cat results-1.1.xml'

block junit-1-0
run 'python3 to_junit.py cases.csv 1.0 > results-1.0.xml'
run 'head -n 2 results-1.0.xml'

block check-1.1
bash "$LAB" release "$APP" || exit 1
bash "$LAB" serve "$APP" || exit 1
U=http://127.0.0.1:8000
msg() { grep -o 'class="msg">[^<]*\|[0-9]*% off:\|<strong>R[^<]*' | tr '\n' ' '; echo; }
echo "TC-05 $(curl -s -d 'email=member@example.org&show=S2&quantity=6' $U/book | msg)"
echo "TC-09 $(curl -s -d 'email=member@example.org&show=S2&quantity=5' $U/book | msg)"
echo "TC-10 $(curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' $U/book | msg)"
curl -s -d 'name=Caio Lima&email=caio@example.org&password=abcd1234' $U/signup >/dev/null
echo "TC-10, a student who is not a member: $(curl -s -d 'email=caio@example.org&show=S2&quantity=2&student=on' $U/book | msg)"
echo "TC-11 $(curl -s -o /dev/null -w '%{http_code}' -d 'email=member@example.org&show=S2&quantity=two' $U/book)"
N=$(curl -s -d 'email=member@example.org&show=S3&quantity=1' $U/book | grep -o 'Order [0-9]*' | head -1 | tr -dc 0-9)
curl -s -d "id=$N&action=pay" $U/order >/dev/null; curl -s -d "id=$N&action=use" $U/order >/dev/null
echo "TC-13 $(curl -s -d "id=$N&action=refund" $U/order | msg)"
M=$(curl -s -d 'email=member@example.org&show=S3&quantity=1' $U/book | grep -o 'Order [0-9]*' | head -1 | tr -dc 0-9)
echo "TC-14 $(curl -s -d "id=$M&action=use" $U/order | msg)"
echo "TC-16 $(curl -s $U/ | grep -o 'width:760px')"
echo "TC-17 $(curl -s $U/book | grep -o '<input name="quantity"[^>]*>')"
