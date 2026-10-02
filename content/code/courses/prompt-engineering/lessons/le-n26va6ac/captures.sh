#!/usr/bin/env bash
# The terminal sessions quoted in lesson 27 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged: chains/s1.txt to s5.txt and holiday/h1.txt to h5.txt. Every one
# of them is a chain of thought WRITTEN BY THE COURSE as an illustration
# of what sampling a model several times can return; the lesson
# shows them and says so. No model wrote them. The vote over them is real:
# bin/vote is printed in lab.sh. The toylm samples are real too.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/pe, and what it printed.
on() { printf 'ana@lab:~/pe$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/pe, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/pe from nothing.
exec 9>/var/tmp/pe-capture.lock; flock 9
lab reset >/dev/null

put chains/s1.txt <<'P'
The card has 9 stamps, so the first flat white is the tenth coffee and free. Two are paid: 2 x 12 = 24. Cake: 2 x 15 = 30. 24 + 30 = 54, so the answer is 54.
P
put chains/s2.txt <<'P'
Coffees: 3 x 12 = 36. One of them is the tenth stamp, so take off 12: 24. Add the cake, 30. The answer is 54.
P
put chains/s3.txt <<'P'
Three flat whites at 12 is 36 and two slices at 15 is 30. 36 + 30 = 66. The answer is 66.
P
put chains/s4.txt <<'P'
Nine stamps plus this order: the next coffee completes the card and is free. Paid: two coffees (24) and two cakes (30). The answer is 54.
P
put chains/s5.txt <<'P'
The ninth stamp means the next coffee is free, and the one after starts a new free card. One coffee paid, 12, plus cake 30. The answer is 42.
P
put holiday/h1.txt <<'P'
It is Wednesday, and on weekdays the café closes at 18:00, so the kitchen takes hot food until 17:30. 11:45 is before that. The answer is yes.
P
put holiday/h2.txt <<'P'
Wednesday hours are 07:00 to 18:00. The kitchen stops 30 minutes before closing, at 17:30. The answer is yes.
P
put holiday/h3.txt <<'P'
A public holiday follows the Sunday hours: closing at 12:00, so hot food stops at 11:30. 11:45 is too late. The answer is no.
P
put holiday/h4.txt <<'P'
The café is open on Wednesdays until 18:00 and the order is at 11:45, well inside the hours. The answer is yes.
P
put holiday/h5.txt <<'P'
Holidays use Sunday hours, so the café closes at noon and the last hot food order is 11:30. The answer is no.
P

block sample-and-vote
on 'toylm generate "the café closes at" --temperature 0 --samples 5'
on 'toylm generate "the café closes at" --samples 7'
on 'head chains/*.txt'
on 'vote chains/*.txt'

block limits
on 'tok count chains/*.txt'
on 'vote chains/s1.txt chains/s3.txt chains/s5.txt'
on 'head holiday/*.txt'
on 'vote holiday/*.txt'
