#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds: the conversation chat.json, the
# summarising prompt summarise.txt and the four turns old-turns.txt, written
# with put below and shown in the lesson with cat. chat-noted.json is made by
# the sed the lesson shows, and handbook/ by the fence in strategies.md, which
# lab.sh runs as printed.
#
# THE MODEL'S REPLIES (every `ask` below) are llama3.2:3b served by Ollama
# 0.40.0, at temperature 0, captured on 7 October 2026.
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

put chat.json <<'EOF'
[
  {"role": "system", "content": "You answer questions from Café Aurora's customers in two sentences or fewer. Opening hours: Monday to Saturday 07:00 to 18:00; Sundays and public holidays 08:00 to 12:00. The kitchen uses nuts."},
  {"role": "user", "content": "Hi, I'm Bruno. I'm allergic to nuts, so please keep that in mind."},
  {"role": "assistant", "content": "Thanks, Bruno. I'll keep your nut allergy in mind in everything I suggest."},
  {"role": "user", "content": "Are you open on Sunday morning?"},
  {"role": "assistant", "content": "Yes, on Sundays we open at 08:00 and close at 12:00."},
  {"role": "user", "content": "And on a public holiday?"},
  {"role": "assistant", "content": "Public holidays follow the Sunday hours: 08:00 to 12:00."},
  {"role": "user", "content": "Great. Which cake would you recommend for me?"}
]
EOF
put summarise.txt <<'EOF'
These turns are about to be removed from the conversation. In at most
two sentences, write down anything the customer said about themselves
(name, allergies, preferences) and any promise the assistant made.
Write nothing else.
EOF
put old-turns.txt <<'EOF'
user: Hi, I'm Bruno. I'm allergic to nuts, so please keep that in mind.
assistant: Thanks, Bruno. I'll keep your nut allergy in mind in everything I suggest.
user: Are you open on Sunday morning?
assistant: Yes, on Sundays we open at 08:00 and close at 12:00.
EOF

block the-window
on 'grep "opens at" corpus.txt | sort | uniq -c'
on 'toylm generate "on sunday the café opens at" --temperature 0'
on 'toylm next "on sunday the café opens at"'

block truncation
on 'cat chat.json'
on 'tok fit chat.json -b 200'
on 'tok fit chat.json -b 120 -w sent.json'
block ask-cake
on 'ask --chat chat.json --temperature 0'
on 'ask --chat sent.json --temperature 0'
block truncation-2
on 'tok fit chat.json -b 80'

block strategies
block noted
on 'sed "s/The kitchen uses nuts.\"}/The kitchen uses nuts. Noted earlier in this conversation: the customer is Bruno and he is allergic to nuts.\"}/" chat.json > chat-noted.json'
on 'tok fit chat-noted.json -b 120 -w sent-noted.json'
on 'ask --chat sent-noted.json --temperature 0'
block summarise
on 'cat summarise.txt old-turns.txt'
on 'ask - --system "$(cat summarise.txt)" --temperature 0 < old-turns.txt'
block strategies-2
on 'tok count handbook/*.md'
