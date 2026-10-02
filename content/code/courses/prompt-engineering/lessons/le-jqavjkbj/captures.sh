#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing is staged beyond the workbench lab.sh builds. toylm, its corpus,
# retrieve and the handbook are printed in full in lab.sh; no other model is
# involved.
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

block why-it-happens
on 'toylm generate "the soup of the day is" --samples 5'
on 'toylm next "the soup of the day is"'
on 'toylm next "the owner of the café is"'
on 'grep -c owner corpus.txt'

block reducing-it
on 'retrieve "Can I get a refund in cash if I paid by card?" --prompt'
on 'retrieve "Who owns the café?" --prompt'
on 'grep -rF "never in cash for a card payment" handbook/'
on 'grep -rF "cash refunds are available on request" handbook/ || echo "not in the handbook"'
on 'toylm generate "the soup of the day is" --temperature 0 --samples 3'
