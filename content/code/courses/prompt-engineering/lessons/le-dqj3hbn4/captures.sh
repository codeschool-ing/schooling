#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is staged: no large model was called. The first block runs toylm, the
# trigram model lab.sh builds, on prompts with and without a pattern. The
# second writes two prompts with put, both shown in the lesson with cat: the
# zero-shot labelling prompt of lesson 20 and the same prompt with four
# labelled examples, and counts and prices them with tok. The prices are
# illustrative, given on the command line; they are not any provider's.
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

put prompt-zero.txt <<'EOF'
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
EOF
put prompt-few.txt <<'EOF'
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>Oh lovely, a cold croissant again. Truly the highlight of my week.</message>
negative

<message>Can I book the terrace for six people on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud to talk.</message>
mixed

<message>Melhor café da rua, e o bolo de laranja é perfeito.</message>
positive

<message>
{message}
</message>
EOF

block examples-as-specification
on 'toylm generate "the bread" --temperature 0'
on 'toylm generate "question : is the bread fresh ? answer :" --temperature 0'
on 'toylm generate "question : when does the café open ? answer :" --temperature 0'
on 'toylm next "question : when does the café open ? answer :"'

block choosing-examples
on 'cat prompt-few.txt'
on 'tok count prompt-zero.txt prompt-few.txt'
on 'tok cost prompt-zero.txt -o 2 -i 2.50 -p 10'
on 'tok cost prompt-few.txt -o 2 -i 2.50 -p 10'
