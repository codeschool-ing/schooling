#!/usr/bin/env bash
# The terminal sessions quoted in lesson 31 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged: candidates.txt (prompt templates), tests.tsv (the examples they are
# chosen on), held.tsv (examples kept back) and best.txt, written with put
# below and shown in the lesson. The model being scored is toylm, the trigram
# model printed in lab.sh; bin/ape is printed there too. No other model runs.
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

put candidates.txt <<'T'
Describe the {x} in one word:
question : what is the {x} like ? answer :
{x}
it is a cold day and the {x} is
the {x} is
T
printf 'coffee\thot\ntea\thot\nbread\tfresh\nterrace\topen\n' | put tests.tsv
printf 'café\tfull\nsoup\ttomato\ncake\tgone\n' | put held.tsv
put best.txt <<'T'
the {x} is
T

block generate-and-score
on 'cat candidates.txt'
on 'cat tests.tsv'
on 'ape candidates.txt tests.tsv'
on 'toylm next "describe the coffee in one word :"'

block keeping-it-honest
on 'cat held.tsv'
on 'ape best.txt held.tsv'
