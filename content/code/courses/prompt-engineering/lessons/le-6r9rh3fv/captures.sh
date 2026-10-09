#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds: two short files, hours.en.txt and
# hours.pt.txt, the café's opening hours in English and in Portuguese, written
# with put below and shown in the lesson with cat. tok is the real tokenizer
# this lesson prints in full, in pieces.md.
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

put hours.en.txt <<'EOF'
Café Aurora opens at seven and closes at six from Monday to Saturday.
On Sundays and public holidays it opens at eight and closes at noon.
The kitchen stops taking hot food orders thirty minutes before closing.
EOF
put hours.pt.txt <<'EOF'
O Café Aurora abre às sete e fecha às seis, de segunda a sábado.
Aos domingos e feriados, abre às oito e fecha ao meio-dia.
A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar.
EOF

block pieces
on 'tok show "The kitchen stops taking hot food orders thirty minutes before closing."'
on 'tok show "A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar."'
on 'tok show "sourdough"'
on 'tok show "https://example.com/menu?day=sunday"'
on 'tok show "if price > 100: approve()"'
on 'tok show "seven"; tok show "SEVEN"'
on 'tok show " strawberry"; tok show "strawberry"'
on 'tok show "A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar." -e cl100k_base'
on 'tok show "The kitchen stops taking hot food orders thirty minutes before closing." -e cl100k_base'

block counting-and-cost
on 'cat hours.en.txt hours.pt.txt'
on 'tok count hours.en.txt hours.pt.txt'
on 'tok count hours.en.txt hours.pt.txt -e cl100k_base'
on 'tok cost hours.pt.txt -o 300 -i 2 -p 8'
on 'tok cost hours.pt.txt -o 30 -i 2 -p 8'

block quirks
on 'tok show "How many r are in strawberry?"'
block ask-strawberry
on 'ask "How many times does the letter r appear in strawberry? Answer with a number." --temperature 0'
block quirks-2
on 'tok show "yrrebwarts"'
block ask-kitchen
on 'ask "Write kitchen backwards." --temperature 0'
on 'python3 -c "print(\"kitchen\"[::-1])"'
block quirks-3
on 'tok show "1234567"; tok show "1,234,567"'
block ask-spelt
on 'ask "Spell strawberry one letter per line, then count the lines that are the letter r." --temperature 0'
