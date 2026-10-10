#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of manual-testing (equivalence
# partitioning and boundary values), as a script that produces them.
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
#     before "name-bounds" and before "quantity", so order numbers start at 1001.
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

block name-bounds
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'name=&email=n0@example.org&password=12345678' $U/signup | grep msg"
run "curl -s -d 'name=A&email=n1@example.org&password=12345678' $U/signup | grep msg"
run "curl -s -d 'name=1234567890123456789012345678901234567890&email=n40@example.org&password=12345678' $U/signup | grep msg"
run "curl -s -d 'name=12345678901234567890123456789012345678901&email=n41@example.org&password=12345678' $U/signup | grep msg"

block password-bounds
run "curl -s -d 'name=Ana&email=p7@example.org&password=1234567' $U/signup | grep msg"
run "curl -s -d 'name=Ana&email=p8@example.org&password=12345678' $U/signup | grep msg"
run "curl -s -d 'name=Ana&email=p64@example.org&password=1234567890123456789012345678901234567890123456789012345678901234' $U/signup | grep msg"
run "curl -s -d 'name=Ana&email=p65@example.org&password=12345678901234567890123456789012345678901234567890123456789012345' $U/signup | grep msg"

block quantity
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'email=member@example.org&show=S2&quantity=0' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=1' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=3' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=6' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=7' $U/book | grep msg"

block quantity-five
run "curl -s -d 'email=member@example.org&show=S2&quantity=5' $U/book | grep msg"

block not-a-number
run "curl -s -w '\n%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' $U/book"

block not-a-number-more
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=' $U/book"
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=2.5' $U/book"
run "curl -s -d 'email=member@example.org&show=S2&quantity=-1' $U/book | grep msg"

block masked
run "curl -s -d 'email=nobody@example.org&show=S2&quantity=two' $U/book | grep msg"
