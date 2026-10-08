#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of prompt-engineering, as a script
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

block top-k
on 'toylm dist "the coffee is" --top-k 2'
on 'toylm dist "the coffee is" --top-k 1'
on 'toylm generate "the coffee is" --top-k 2 --samples 6'
on 'toylm next "the"'

block top-p
on 'toylm dist "the coffee is" --top-p 0.8'
on 'toylm next "the coffee is hot"'
on 'toylm dist "the coffee is hot" --top-p 0.8'
on 'toylm next "and the"'
on 'toylm dist "and the" --top-p 0.8'
on 'toylm dist "the coffee is hot" --top-k 2'
on 'toylm dist "and the" --top-k 2'

block together
on 'toylm dist "the coffee is" --temperature 2 --top-p 0.8'
on 'toylm dist "the coffee is" --temperature 0.5 --top-p 0.8'
on 'toylm dist "the coffee is" --top-k 3 --top-p 0.8'
