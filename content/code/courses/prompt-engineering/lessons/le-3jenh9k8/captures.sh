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
# Staged beyond the workbench lab.sh builds: three one-line prompt files,
# prompts/v1.txt to prompts/v3.txt, written with put below and shown in the
# lesson with cat. toylm and its corpus are printed in full in lab.sh; no
# other model is involved.
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
