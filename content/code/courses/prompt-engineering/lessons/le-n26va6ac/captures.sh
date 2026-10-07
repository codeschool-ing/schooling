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
# Staged with put, and shown in the lesson with cat: two prompts, lesson 26's
# café order and lesson 25's holiday question, each asking for a fixed answer
# line. The samples in chains/ and holiday/ are the model's, drawn by the loops
# the lesson shows; vote is read out of sample-and-vote.md.
#
# THE MODEL'S REPLIES are llama3.2:3b served by Ollama 0.40.0, at temperature
# 0.7 and 0.8 with seeds 1 to 7 and 1 to 5, captured on 7 October 2026.
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

put prompts/order-chain.txt <<'P'
A table at Café Aurora orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. They pay with a loyalty card that already has 9 stamps, and the tenth coffee is free. How much do they pay? Work it out step by step, then write the result on a last line that starts with Answer:
P
put prompts/holiday-vote.txt <<'P'
Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday. On Sundays it opens at 08:00 and closes at 12:00. The kitchen stops taking hot food orders 30 minutes before closing. On public holidays the café follows the Sunday hours.

Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Think it through, then end with one line: The answer is yes, or The answer is no.
P

block sample-and-vote
on 'toylm generate "the café closes at" --temperature 0 --samples 5'
on 'toylm generate "the café closes at" --samples 7'
block sample
on 'mkdir -p chains; for i in 1 2 3 4 5 6 7; do ask - --temperature 0.7 --seed $i --plain < prompts/order-chain.txt > chains/s$i.txt; done'
on 'cat chains/s2.txt'
on 'cat chains/s3.txt'
block vote
on 'vote chains/*.txt'

block limits
on 'tok count chains/*.txt'
block tie
on 'vote chains/s1.txt chains/s2.txt chains/s6.txt'
block holiday
on 'cat prompts/holiday-vote.txt'
on 'mkdir -p holiday; for i in 1 2 3 4 5; do ask - --temperature 0.8 --seed $i --plain < prompts/holiday-vote.txt > holiday/h$i.txt; done'
on 'vote holiday/*.txt'
on 'tail -1 holiday/h5.txt'
