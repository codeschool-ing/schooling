#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing is staged beyond the workbench lab.sh builds. toylm and its corpus
# are shown whole in lesson 1, and lab.sh takes them from that lesson's
# fences; no other model is involved.
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

block the-loop
on 'toylm generate "the cat" --temperature 0 --max-tokens 20'
on 'toylm next "the cat"'
on 'toylm next "cat sleeps"'
on 'toylm next "sleeps and"'
on 'toylm next "and the"'

block two-penalties
on 'toylm generate "the cat" --temperature 0 --max-tokens 20 --frequency-penalty 0.5'
on 'toylm generate "the cat" --temperature 0 --max-tokens 20 --presence-penalty 1'
on 'toylm generate "the cat" --temperature 0 --max-tokens 20 --frequency-penalty 0.2'
on 'toylm generate "the cat" --temperature 0 --max-tokens 20 --presence-penalty 0.2'
on 'toylm generate "question :" --temperature 0'
on 'toylm generate "question :" --temperature 0 --presence-penalty 5'
on 'toylm next "the bread"'
