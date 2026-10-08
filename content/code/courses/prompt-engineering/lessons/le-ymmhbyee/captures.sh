#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing is staged beyond the workbench lab.sh builds. tok runs the two
# encodings OpenAI publishes; no other provider's tokenizer is in the
# workbench, and the lesson shows no count for one.
#
# license reads the model lesson 1 pulled: llama3.2:3b, Ollama 0.40.0.
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

block choosing
on 'tok show "O café abre às oito aos domingos." -e cl100k_base'
on 'tok show "O café abre às oito aos domingos." -e o200k_base'
on 'tok count handbook/*.md -e cl100k_base'
on 'tok count handbook/*.md -e o200k_base'

block license
on 'ollama show --license llama3.2:3b | head -2; ollama show --license llama3.2:3b | wc -l'
