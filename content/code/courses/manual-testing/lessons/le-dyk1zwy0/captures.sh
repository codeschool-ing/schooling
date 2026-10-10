#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of manual-testing (regression
# testing), as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: boxoffice.py is lesson 1's,
# lesson 9 section `release-1-1` asks for a copy of 1.0 as boxoffice-1.0.py and
# then shows the three edits that make 1.1. ../../lab.sh app and release
# extract both from those sections, so what runs here is what the student has.
# What is STAGED rather than typed:
#   - the 1.1 server is started by lab.sh with
#     BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab;
#   - in "compare", the 1.0 copy is started in the background with the same
#     two variables and BOXOFFICE_PORT=8001, as the lesson has the student do
#     in a third terminal, and its first line is printed from its log.
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
OFF="grep -o '[0-9]*% off'"

bash "$LAB" serve "$APP" || exit 1

block account
run "curl -s -d 'name=Caio+Lima&email=caio@example.org&password=ticket-1234' $U/signup | grep msg"
run "curl -s $U/outbox | grep -o 'To: [a-z@.]*'"

block prices
run "curl -s -d 'email=caio@example.org&show=S2&quantity=2' $U/book | $OFF"
run "curl -s -d 'email=caio@example.org&show=S2&quantity=5' $U/book | $OFF"
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | $OFF"
run "curl -s -d 'email=member@example.org&show=S2&quantity=5' $U/book | $OFF"
run "curl -s -d 'email=caio@example.org&show=S2&quantity=2&student=on' $U/book | $OFF"
run "curl -s -d 'email=caio@example.org&show=S2&quantity=5&student=on' $U/book | $OFF"
run "curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' $U/book | $OFF"
run "curl -s -d 'email=member@example.org&show=S2&quantity=5&student=on' $U/book | $OFF"

block quantity
run "curl -s -d 'email=member@example.org&show=S3&quantity=0' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S3&quantity=1' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S3&quantity=6' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S3&quantity=7' $U/book | grep msg"
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S3&quantity=two' $U/book"

block seats
SEATS="grep -o '[0-9]*</td><td><a href=\"/book?show=S3'"
run "curl -s $U/ | $SEATS"
run "curl -s -d 'id=1010&action=cancel' $U/order | grep msg"
run "curl -s $U/ | $SEATS"

block states
run "curl -s -d 'id=1009&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1009&action=use' $U/order | grep msg"
run "curl -s -d 'id=1009&action=refund' $U/order | grep msg"

block compare-start
( env BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 BOXOFFICE_SEED=lab BOXOFFICE_PORT=8001 \
    PYTHONUNBUFFERED=1 python3 boxoffice-1.0.py ) </dev/null >old.log 2>&1 &
OLD=$!
for _ in $(seq 50); do curl -sf http://127.0.0.1:8001/health >/dev/null && break; sleep 0.1; done
printf 'ana@laptop:~/boxoffice$ BOXOFFICE_PORT=8001 python3 boxoffice-1.0.py\n'
head -n 1 old.log

block compare
run "curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' http://127.0.0.1:8001/book | $OFF"
run "curl -s -d 'email=member@example.org&show=S2&quantity=2&student=on' $U/book | $OFF"

# not quoted in the lesson: the 1.0 column of the grid in keeping-it-alive
block old-grid
run "curl -s -d 'email=member@example.org&show=S2&quantity=5' http://127.0.0.1:8001/book | $OFF"
run "curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8001/book | grep msg"
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S3&quantity=two' http://127.0.0.1:8001/book"
kill $OLD
bash "$LAB" stop
