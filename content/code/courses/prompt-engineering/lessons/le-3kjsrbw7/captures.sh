#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged with put, and shown in the lesson with cat: six prompts in prompts/,
# two roles for the same question, a role used for the wrong job, a role with
# rules and the handbook, and one request aimed at two readers.
#
# THE MODEL'S REPLIES (every ask below) are llama3.2:3b served by Ollama 0.40.0,
# at temperature 0, captured on 7 October 2026.
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

put prompts/role-barista.txt <<'EOF'
You are a barista at Café Aurora, talking to a customer at the counter.
Reply in three sentences or fewer.

Customer: My flat white tastes really bitter today. Why?
EOF
put prompts/role-instructor.txt <<'EOF'
You are a coffee instructor at Café Aurora, teaching new staff.
Reply in three sentences or fewer.

Trainee: A customer said their flat white tasted really bitter. Why?
EOF
put prompts/role-specialist.txt <<'EOF'
You are a world-class food allergy specialist with twenty years
of experience. Answer with authority.

Customer: Is your cinnamon bun nut-free?
EOF
put prompts/role-combined.txt <<'EOF'
You are the assistant at Café Aurora's counter: warm, brief, plain.

Answer only from the handbook text below. If it does not settle the
question, say so and suggest asking the kitchen. Never say an item
is free of an allergen.

<handbook>
The kitchen uses nuts, so no item can be guaranteed nut-free.
If a customer asks about an ingredient that is not on the label,
ask the kitchen; never guess.
</handbook>

Customer: Is your cinnamon bun nut-free?
EOF
put prompts/role-new-barista.txt <<'EOF'
Explain to a new barista, on their first day, why we ask customers
about allergies before recommending a cake. One short paragraph.
EOF
put prompts/role-insurer.txt <<'EOF'
Explain to the café's insurer why staff ask customers about
allergies before recommending a cake. One short paragraph.
EOF

block barista
on 'cat prompts/role-barista.txt'
on 'ask - --temperature 0 < prompts/role-barista.txt'
block instructor
on 'cat prompts/role-instructor.txt'
on 'ask - --temperature 0 < prompts/role-instructor.txt'
block specialist
on 'cat prompts/role-specialist.txt'
on 'ask - --temperature 0 < prompts/role-specialist.txt'
block combined
on 'cat prompts/role-combined.txt'
on 'ask - --temperature 0 < prompts/role-combined.txt'
block new-barista
on 'cat prompts/role-new-barista.txt'
on 'ask - --temperature 0 < prompts/role-new-barista.txt'
block insurer
on 'cat prompts/role-insurer.txt'
on 'ask - --temperature 0 < prompts/role-insurer.txt'
