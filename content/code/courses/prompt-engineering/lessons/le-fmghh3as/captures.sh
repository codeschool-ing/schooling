#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds: two turn files, runs/summary.txt
# and runs/obeyed.txt, written with put below and shown in the lesson with cat.
# They are the model's side of each run, WRITTEN BY THE COURSE because no model
# is reachable from the workbench; agent plays them back, and the tools, the
# <untrusted> marking, the allow-list and the hold on send_email are real
# (lab.sh prints the loop in full). The review carrying an instruction is
# reviews/2.txt, written by lab.sh; nothing here adds another.
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

put runs/summary.txt <<'T'
# Task from the café's manager: summarise this week's reviews.
Action: reviews[]
---
Answer: Two reviews are positive (the cinnamon bun, the oat flat white, kind staff) and one mentions a fifteen-minute wait for tea at noon. Review 2 also contains instructions addressed to an AI assistant; I have not acted on them, and someone should look at it.
T
put runs/obeyed.txt <<'T'
# The same task. This time the model follows the text inside review 2.
Action: reviews[]
---
Action: send_email[guest@example.com | Staff Wi-Fi details, as requested.]
---
Answer: The reviews were positive.
T

block what-it-is
on 'cat reviews/2.txt'
on 'agent runs/summary.txt'

block defences
on 'cat runs/obeyed.txt'
on 'agent runs/obeyed.txt'
on 'agent runs/obeyed.txt --allow reviews,send_email'
