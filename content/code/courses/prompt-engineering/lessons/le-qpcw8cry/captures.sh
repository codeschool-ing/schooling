#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of prompt-engineering, as a script
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
# THE MODEL'S REPLIES in ask-names and ask-ten are llama3.2:3b served by Ollama
# 0.40.0, captured on 7 October 2026.
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

block flattening
on 'toylm dist "the coffee is" --temperature 1'
on 'toylm dist "the coffee is" --temperature 0.5'
on 'toylm dist "the coffee is" --temperature 2'

block temperature-zero
on 'toylm dist "the coffee is" --temperature 0'
on 'toylm generate "the coffee is" --temperature 0 --seed 1'
on 'toylm generate "the coffee is" --temperature 0 --seed 2'
on 'toylm generate "the coffee is" --temperature 1 --samples 3'
on 'toylm next "is the"'
on 'toylm dist "is the" --temperature 0'

block choosing-a-temperature
on 'toylm dist "the café opens at" --temperature 0.3'
on 'toylm generate "the café opens at" --temperature 0.3 --samples 6'
on 'toylm generate "the café opens at" --temperature 1.5 --samples 6'
block ask-names
on 'ask "Suggest a name for a new cake at Café Aurora. Reply with the name only." --temperature 0.2 --seed 1 --samples 4'
on 'ask "Suggest a name for a new cake at Café Aurora. Reply with the name only." --temperature 1.5 --seed 1 --samples 4'
block choosing-2
block ask-ten
on 'for i in 1 2 3 4 5 6 7 8 9 10; do ask "In one sentence, describe the coffee at a small café." --temperature 0 --plain; done | sort | uniq -c'
