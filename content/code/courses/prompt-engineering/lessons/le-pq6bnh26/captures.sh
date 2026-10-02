#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds, all shown in full in the lesson:
# train.jsonl (three training examples in the shape fine-tuning services
# commonly take), few-shot.txt (a classification prompt carrying its
# instruction and eight examples) and short.txt (the same request as a
# fine-tuned model would need it). No model is called and nothing is trained:
# tok counts tokens with a real tokenizer, and the prices passed to tok cost
# are illustrative, given on the command line, not any provider's.
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

block what-each-changes
put train.jsonl <<'TXT'
{"messages": [{"role": "user", "content": "Are you open on Sunday afternoon?"}, {"role": "assistant", "content": "hours"}]}
{"messages": [{"role": "user", "content": "Does the carrot cake have nuts in it?"}, {"role": "assistant", "content": "allergens"}]}
{"messages": [{"role": "user", "content": "My latte was cold and I want my money back."}, {"role": "assistant", "content": "refunds"}]}
TXT
on 'wc -l train.jsonl'
on 'head -1 train.jsonl'

block the-cost
put few-shot.txt <<'TXT'
Sort each message from a Café Aurora customer into one category:
hours, allergens, refunds, loyalty, wifi, deliveries or other.
Reply with the category only.

Message: Are you open on Sunday afternoon?
Category: hours

Message: Does the carrot cake have nuts in it?
Category: allergens

Message: My latte was cold and I want my money back.
Category: refunds

Message: I lost my stamp card, can I get a new one?
Category: loyalty

Message: The guest network keeps logging me out.
Category: wifi

Message: Nobody signed for the milk this morning.
Category: deliveries

Message: Do you sell gift vouchers?
Category: other

Message: Is the kitchen still serving at half past five?
Category: hours

Message: Is there oat milk for the flat white?
Category:
TXT
put short.txt <<'TXT'
Message: Is there oat milk for the flat white?
Category:
TXT
on 'tok count few-shot.txt short.txt'
on 'tok cost few-shot.txt -o 2 -i 2.50 -p 10.00'
on 'tok cost short.txt -o 2 -i 2.50 -p 10.00'
on "awk 'BEGIN { print (4.33 - 0.53) * 1000 }'"
