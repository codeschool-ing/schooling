#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of manual-testing (decision tables
# and state transition), as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: boxoffice.py 1.0 is shown
# whole in lesson 1 section `the-app`, and ../../lab.sh app extracts it from
# there. Every command below is one the lesson shows. What is STAGED rather
# than typed:
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, TZ=America/Sao_Paulo, so the dates are the same on
#     every run;
#   - it is restarted (a fresh state, as the lesson tells the student to do)
#     before "discount-setup" and before "states-valid", so order numbers start
#     at 1001 each time.
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
U=http://127.0.0.1:8000

block discount-setup
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'name=Caio Lima&email=caio@example.org&password=12345678' $U/signup | grep msg"

block discount-rules
M=member@example.org; C=caio@example.org
run "curl -s -d 'email=$M&show=S2&quantity=5&student=on' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$M&show=S2&quantity=2&student=on' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$C&show=S2&quantity=5&student=on' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$C&show=S2&quantity=2&student=on' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$M&show=S2&quantity=5' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$M&show=S2&quantity=2' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$C&show=S2&quantity=5' $U/book | grep -A1 'off:'"
run "curl -s -d 'email=$C&show=S2&quantity=2' $U/book | grep -A1 'off:'"

block states-valid
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1001&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1001&action=use' $U/order | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1002&action=cancel' $U/order | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1003&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1003&action=refund' $U/order | grep msg"

block states-invalid
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1004&action=refund' $U/order | grep msg"
run "curl -s -d 'id=1002&action=cancel' $U/order | grep msg"
run "curl -s -d 'id=1003&action=cancel' $U/order | grep msg"

block used-refund
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'id=1001&action=pay' $U/order | grep msg"
run "curl -s -d 'id=1001&action=use' $U/order | grep msg"
run "curl -s $U/ | grep -o '<td>Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'"
run "curl -s -d 'id=1001&action=refund' $U/order | grep msg"
run "curl -s $U/ | grep -o '<td>Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'"
