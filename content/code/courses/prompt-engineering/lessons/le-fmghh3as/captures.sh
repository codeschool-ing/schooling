#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing is staged beyond the workbench lab.sh builds. The three reviews and
# the system message reviews.txt are the fence in what-it-is.md, which lab.sh
# runs as printed; review 2 is the one carrying an instruction.
#
# THE MODEL'S TURNS in live-reviews and live-email are llama3.2:3b served by
# Ollama 0.40.0, at temperature 0, captured on 7 October 2026. Every action it
# asked for was refused or held by agent; nothing was sent anywhere.
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

block what-it-is
on 'cat reviews/2.txt'
block live-reviews
on 'agent --live "Summarise this week'"'"'s reviews." --prompt reviews.txt --allow reviews'
block live-email
on 'agent --live "Summarise this week'"'"'s reviews." --prompt reviews.txt --allow reviews,send_email'
