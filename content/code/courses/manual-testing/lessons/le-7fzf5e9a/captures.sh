#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE COURSE: boxoffice.py from lesson 1
# section `the-app`, with the three 1.1 edits of lesson 9 section `release-1-1`
# applied (../../lab.sh app and release extract both from those sections). What
# is STAGED rather than typed:
#   - every server is started by lab.sh in the background with
#     BOXOFFICE_SEED=lab, so the confirmation tokens are the same on every run
#     (the lesson says the student's differ), and TZ=America/Sao_Paulo;
#   - BOXOFFICE_NOW is lab.sh's default, 2026-10-10T14:00:00-03:00, except
#     where a block prints the command that sets another one; there the server
#     is started by lab.sh with that value and PYTHONUNBUFFERED=1, and its first
#     line is printed under the command;
#   - every block from "signup" to "resend-nobody" talks to the same server,
#     with nothing restarted in between; "expiry-start" and
#     "expiry-control-start" each restart it, as their printed command says;
#   - the tokens in the confirm commands are read from the outbox by the
#     script, where the student copies them from the outbox page.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0.
# Run as root with HOME=/home/ana, so the paths read as Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
bash "$LAB" release "$APP" || exit 1
cd "$APP" || exit 1

LINKS="curl -s http://127.0.0.1:8000/outbox | grep -oE 'To: [^ ]+|http://[^ ]+token=[a-z0-9]+'"

bash "$LAB" serve "$APP" || exit 1

block signup
run "curl -s -d 'name=Caio+Lima&email=caio@example.org&password=ticket-office-9' http://127.0.0.1:8000/signup | grep msg"
block outbox-page
run "curl -s http://127.0.0.1:8000/outbox | grep -A 4 '<article>'"
TOKEN=$(curl -s http://127.0.0.1:8000/outbox | grep -oE 'token=[a-z0-9]+' | head -n 1 | cut -d= -f2)
block confirm-one
run "curl -s 'http://127.0.0.1:8000/confirm?token=$TOKEN' | grep msg"
block confirm-again
run "curl -s 'http://127.0.0.1:8000/confirm?token=$TOKEN' | grep msg"
block bad-token
run "curl -s 'http://127.0.0.1:8000/confirm?token=nosuchtoken' | grep msg"

block resend-signup
run "curl -s -d 'name=Dora+Reis&email=dora@example.org&password=ticket-office-9' http://127.0.0.1:8000/signup | grep msg"
block resend
run "curl -s -d 'email=dora@example.org' http://127.0.0.1:8000/resend | grep msg"
block outbox-two
run "$LINKS"
OLD=$(curl -s http://127.0.0.1:8000/outbox | grep -oE 'token=[a-z0-9]+' | sed -n 2p | cut -d= -f2)
block old-link
run "curl -s 'http://127.0.0.1:8000/confirm?token=$OLD' | grep msg"
block resend-nobody
run "curl -s -d 'email=nobody@example.org' http://127.0.0.1:8000/resend | grep msg"

block expiry-start
printf 'ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-11T15:00:00-03:00 python3 boxoffice.py\n'
bash "$LAB" serve "$APP" BOXOFFICE_NOW=2026-10-11T15:00:00-03:00 PYTHONUNBUFFERED=1 || exit 1
head -n 1 "$APP/server.log"
block expiry-link
run "curl -s 'http://127.0.0.1:8000/confirm?token=$OLD' | grep msg"
block expiry-control-start
printf 'ana@laptop:~/boxoffice$ BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 python3 boxoffice.py\n'
bash "$LAB" serve "$APP" BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 PYTHONUNBUFFERED=1 || exit 1
head -n 1 "$APP/server.log"
block expiry-control-link
run "curl -s 'http://127.0.0.1:8000/confirm?token=$OLD' | grep msg"
