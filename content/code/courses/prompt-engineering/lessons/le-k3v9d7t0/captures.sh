#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is staged: no model was called. prompts/system-v3.txt is a system
# prompt for Café Aurora's website assistant, written by the course and shown
# in the lesson with cat; tok counts it, with the tokenizer lab.sh installs.
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

put prompts/system-v3.txt <<'EOF'
You are the assistant on the website of Café Aurora, a café. You answer
questions from its customers.

Scope: opening hours, the menu, allergens, the loyalty card, guest Wi-Fi
and how to make a complaint. For anything else, say it is outside what
you can help with and give the café's address, hello@example.com.

Facts: use only the handbook text supplied with each question. If the
answer is not in it, say you do not know and give the address. Never
guess about allergens.

Style: friendly and plain, in the customer's language, at most three
sentences, no Markdown.

Refunds and anything about staff go to a person: say so, and promise
nothing.
EOF

block what-belongs-there
on 'cat prompts/system-v3.txt'
on 'tok count prompts/system-v3.txt'
