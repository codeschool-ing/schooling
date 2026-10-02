#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing is staged beyond the workbench lab.sh builds. toylm and its corpus
# are printed in full in lab.sh; no other model is involved.
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
lab reset >/dev/null

block next-word
on 'toylm next "the coffee is"'
on 'toylm next "the café opens at"'

block one-at-a-time
on 'toylm generate "the café opens at" --temperature 0'
on 'toylm next "the café opens at seven"'
on 'toylm next "the cat sat on the"'
on 'toylm generate "the cat sat on the" --temperature 0'
on 'toylm generate "the coffee is" --samples 5'

block the-workbench
on 'ls'
on 'head -4 corpus.txt'
on 'toylm info'
on 'tok show "The café opens at seven."'
on 'python3 --version; node --version'
