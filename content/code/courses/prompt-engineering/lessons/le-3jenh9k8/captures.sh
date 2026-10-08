#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds: five prompt files, prompts/v1.txt
# to prompts/v3.txt, vague.txt and specific.txt, written with put below and
# shown in the lesson with cat.
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

block the-start-of-a-text
on 'toylm next "the café closes at"'
on 'toylm next "question : when does the café open ? answer :"'
on 'toylm generate "question : when does the café open ? answer :" --temperature 0'
block ask-sunday
on 'ask "When do you open on Sunday?" --temperature 0 --system "You answer questions from Café Aurora'"'"'s customers. Keep replies to two sentences."'

block engineering
put prompts/v1.txt <<'EOF'
question : when does the café open ? answer :
EOF
put prompts/v2.txt <<'EOF'
question : when does the café open ? answer : at
EOF
put prompts/v3.txt <<'EOF'
the café opens at
EOF
on 'cat prompts/v1.txt prompts/v2.txt prompts/v3.txt'
on 'toylm generate "$(cat prompts/v2.txt)" --samples 4'
on 'for v in v1 v2 v3; do echo "$v $(toylm generate "$(cat prompts/$v.txt)" --samples 20 | grep -c seven)/20"; done'
put prompts/vague.txt <<'EOF'
Write something about our opening hours.
EOF
put prompts/specific.txt <<'EOF'
You are writing the notice for the door of Café Aurora.
Opening hours: Monday to Saturday 07:00 to 18:00; Sunday 08:00 to 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
Write the notice in English, at most four lines, one line per rule.
Do not add any information that is not in these hours.
EOF
block vague
on 'cat prompts/vague.txt'
on 'ask - --temperature 0 < prompts/vague.txt'
block specific
on 'cat prompts/specific.txt'
on 'ask - --temperature 0 < prompts/specific.txt'
