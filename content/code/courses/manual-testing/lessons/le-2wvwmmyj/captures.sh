#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# Writers running captures at the same time share /home/ana, and one script's
# `rm -rf ~/boxoffice` pulls the directory from under another. To keep it
# private as well as the network:
#
#   unshare -m --propagation private bash -c \
#     'mount -t tmpfs tmpfs /home/ana && bash ../../lab.sh isolated bash captures.sh'
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS: lesson 1 gives the lab and
# boxoffice.py whole, and ../../lab.sh app extracts the program from there, so
# what runs here is the block the student copied. The requests are the curl
# form of the steps of the cases in section `first-cases`, run in the order
# section `running-cases` runs them, against ONE server that is never
# restarted in between. What is STAGED rather than typed:
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, so the dates and the confirmation link are the
#     same on every run (the lesson says the student's link will differ);
#   - the link in "confirm" is read out of the outbox by this script and then
#     typed in full, the way Ana copies it from the page.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
bash "$LAB" serve "$APP" || exit 1
cd "$APP" || exit 1
U=http://127.0.0.1:8000
ROWS="grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'"

block build
run "curl $U/health"

block signup-ok
run "curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' $U/signup | grep msg"

block signup-taken
run "curl -s -d 'name=Ana+Lima&email=member@example.org&password=boxoffice-2026' $U/signup | grep msg"
run "curl -s $U/outbox | grep -c '<article>'"

block confirm
run "curl -s $U/outbox | grep -E 'h2|token'"
LINK=$(curl -s $U/outbox | grep -o "$U/confirm?token=[a-z0-9]*" | head -n 1)
run "curl -s '$LINK' | grep msg"

block confirm-bad
run "curl -s '$U/confirm?token=nottherealone' | grep msg"

block book-member
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep -A3 'class=\"msg\"'"
run "curl -s $U/ | $ROWS"

block book-nobody
run "curl -s -d 'email=nobody@example.org&show=S2&quantity=2' $U/book | grep msg"

block book-new
run "curl -s -d 'email=ana@example.org&show=S3&quantity=2' $U/book | grep -A3 'class=\"msg\"'"
run "curl -s $U/ | $ROWS"
