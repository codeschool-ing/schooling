#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Nothing is staged beyond the workbench lab.sh builds: retrieve and the
# café's handbook/ are printed in full in lab.sh. No model is called; the
# replies a model might give to the assembled prompts are illustrations the
# lesson wrote, and it says so where they appear.
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

block retrieve-then-generate
on 'ls handbook'
on 'cat handbook/hours.md'
on 'retrieve "when does the café open on sundays"'

block the-grounded-prompt
on 'retrieve --prompt "when does the café open on sundays"'
on 'retrieve --prompt "can I bring my dog"'

block where-it-fails
on 'retrieve "is there wireless internet for customers"'
on 'retrieve "what is the wifi password"'
on 'retrieve "what time does the café open on public holidays"'
on 'retrieve "can I get a refund for a cold coffee"'
on 'retrieve "my drink was wrong, can I get my money back"'
