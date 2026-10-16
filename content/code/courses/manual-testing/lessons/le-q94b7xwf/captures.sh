#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# The triage of this lesson checks two new reports before deciding them: one
# that turns out to be a duplicate and one that turns out to be the
# requirement working; and it retests the fix of lesson 4's six-ticket defect.
# It runs on boxoffice 1.1, the program of lesson 1 with the edits of lesson
# 9, both extracted from those lessons by ../../lab.sh. What is STAGED rather
# than typed: the server is started by lab.sh with
# BOXOFFICE_NOW=2026-10-10T14:00:00-03:00 and BOXOFFICE_SEED=lab, and
# TZ=America/Sao_Paulo; it is fresh at the start, so the first order is 1001.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16 and curl 8.5.0,
# TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so the paths read as
# Ana's.

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" || exit 1
bash "$LAB" release "$APP" || exit 1
bash "$LAB" serve "$APP" || exit 1
cd "$APP" || exit 1

block retest
run "curl -s -d 'email=member@example.org&show=S2&quantity=6' http://127.0.0.1:8000/book | grep msg"

block duplicate
run "curl -s -d 'email=member@example.org&show=S2&quantity=2' http://127.0.0.1:8000/book | grep msg"
run "curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg"
run "curl -s -d 'id=1002&action=pay' http://127.0.0.1:8000/order | grep msg"
run "curl -s -d 'id=1002&action=use' http://127.0.0.1:8000/order | grep msg"
run "curl -s -d 'id=1002&action=use' http://127.0.0.1:8000/order | grep msg"

block as-designed
run "curl -s -d 'email=member@example.org&show=S3&quantity=5' http://127.0.0.1:8000/book | grep -A1 'ticket(s)'"
