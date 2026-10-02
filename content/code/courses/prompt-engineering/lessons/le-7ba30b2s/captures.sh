#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged: direct.txt and chain.txt, two replies to the café order question
# WRITTEN BY THE COURSE as illustrations (the lesson shows both and says so).
# No model wrote them; tok and grep only measure and read them.
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

put direct.txt <<'P'
R$ 66
P
put chain.txt <<'P'
Three flat whites at R$ 12 each.
The card already has 9 stamps, so the first coffee of this order is the tenth, and it is free.
That leaves 2 coffees to pay for: 2 x 12 = R$ 24.
Two slices of cake at R$ 15 each: 2 x 15 = R$ 30.
Total: 24 + 30 = R$ 54.
Answer: 54
P

block thinking-out-loud
on 'python3 -c "print(3 * 12 + 2 * 15, 2 * 12 + 2 * 15, 2 * 9 + 11)"'

block using-it
on 'grep "^Answer:" chain.txt'
on 'tok count direct.txt chain.txt'
