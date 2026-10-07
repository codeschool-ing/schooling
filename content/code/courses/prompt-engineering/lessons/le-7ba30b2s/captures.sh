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
# Staged with put, and shown in the lesson: three prompts for one café order,
# asking for the amount only, for the steps first, and with one worked example.
# direct.txt, chain.txt and few.txt are the model's replies, kept by tee.
#
# THE MODEL'S REPLIES (every ask below) are llama3.2:3b served by Ollama 0.40.0,
# at temperature 0, captured on 7 October 2026.
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

put order-direct.txt <<'P'
A table at Café Aurora orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. They pay with a loyalty card that already has 9 stamps, and the tenth coffee is free. How much do they pay? Reply with the amount only.
P
put order-chain.txt <<'P'
A table at Café Aurora orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. They pay with a loyalty card that already has 9 stamps, and the tenth coffee is free. How much do they pay? Work it out step by step, then write the result on a last line that starts with Answer:
P
put order-few.txt <<'P'
Q: A customer orders 2 espressos at R$ 9 each and 1 cinnamon bun at R$ 11. Their loyalty card has 3 stamps; the tenth coffee is free. How much do they pay?
A: The card has 3 stamps, so these espressos are the 4th and 5th coffees. Neither is the tenth, so both are paid: 2 x 9 = 18. The bun is 11. Total: 18 + 11 = 29.
Answer: 29

Q: A table orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. Their loyalty card has 9 stamps; the tenth coffee is free. How much do they pay?
A:
P

block direct
on 'cat order-direct.txt'
on 'ask - --temperature 0 --plain < order-direct.txt | tee direct.txt'
block chain
on 'tail -c 80 order-chain.txt'
on 'ask - --temperature 0 --plain < order-chain.txt | tee chain.txt'
block python
on 'python3 -c "print(3 * 12 + 2 * 15, 2 * 12 + 2 * 15, 2 * 9 + 11)"'
block few
on 'cat order-few.txt'
on 'ask - --temperature 0 --plain < order-few.txt | tee few.txt'

block using-it
on 'grep "^Answer:" chain.txt few.txt || echo "no Answer: line"'
on 'tok count direct.txt chain.txt few.txt'
