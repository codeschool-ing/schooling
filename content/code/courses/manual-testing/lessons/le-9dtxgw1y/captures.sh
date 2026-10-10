#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM LESSON 1: boxoffice.py is the block of
# lesson 1 section `the-app`, which ../../lab.sh app extracts. What is STAGED
# rather than typed:
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, TZ=America/Sao_Paulo, and restarted before the
#     "family" block, which is the restart section 03 asks the student for;
#   - HOME is a fresh temporary directory standing for /home/ana, so the
#     prompt reads as Ana's and two captures never share a boxoffice.py.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
HOME=$(mktemp -d); export HOME
APP=$HOME/boxoffice
bash "$LAB" app "$APP" || exit 1
bash "$LAB" serve "$APP" || exit 1
cd "$APP" || exit 1

block verify-member
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep -A2 msg"

block family
bash "$LAB" serve "$APP" || exit 1
run "curl -s -d 'email=member@example.org&show=S2&quantity=3&student=on' http://127.0.0.1:8000/book | grep -A2 msg"

run "curl -s -d 'email=member@example.org&show=S2&quantity=3' http://127.0.0.1:8000/book | grep -A2 msg"

block school-group
run "curl -s -d 'email=member@example.org&show=S3&quantity=30' http://127.0.0.1:8000/book | grep msg"
