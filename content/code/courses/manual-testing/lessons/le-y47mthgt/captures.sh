#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of manual-testing, as a script that
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
# what runs here is the block the student copied. Each request is the curl
# form of a step the lesson describes in the browser. What is STAGED rather
# than typed:
#   - every block but "closed" runs against a server started by lab.sh with
#     BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab, and a
#     block that says "fresh" restarts it first, which is the student's Ctrl-C
#     and `python3 boxoffice.py`;
#   - "closed" restarts it with BOXOFFICE_NOW=2026-10-10T19:30:00-03:00, the
#     same day at half past seven in the evening, because that is the moment
#     the section talks about and nobody waits five hours for a capture.
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
ROWS="grep -o '<tr><td>[^<]*</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*</td>'"
fresh() { bash "$LAB" serve "$APP" "$@" || exit 1; }

# fresh: the same booking twice, with no restart between the two runs
block twice
fresh
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' $U/book | grep msg"
run "curl -s $U/ | $ROWS"

# same server: the sign-up of lesson 2, run a second time
block signup-twice
run "curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' $U/signup | grep msg"
run "curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' $U/signup | grep msg"

# fresh: an account that exists and was never confirmed
block unconfirmed
fresh
run "curl -s -d 'name=Ana+Lima&email=ana@example.org&password=boxoffice-2026' $U/signup | grep msg"
run "curl -s -d 'email=ana@example.org&show=S2&quantity=2' $U/book | grep -A3 'class=\"msg\"'"

# fresh, with the clock at 19:30: tonight's show
block closed
fresh BOXOFFICE_NOW=2026-10-10T19:30:00-03:00
run "curl -s -d 'email=member@example.org&show=S1&quantity=2' $U/book | grep msg"

# fresh: the rewritten case of section rewriting-a-case, step by step
block rewritten
fresh
run "curl -s -d 'email=member@example.org&show=S3&quantity=3' $U/book | grep -A3 'class=\"msg\"'"
run "curl -s $U/ | $ROWS"
