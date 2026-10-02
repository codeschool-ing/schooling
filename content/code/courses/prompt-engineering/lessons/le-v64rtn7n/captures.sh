#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds, both shown in full in the lesson:
# bench.txt, a three-question "benchmark" whose questions are copied from
# toylm's own corpus, and new.txt, three questions that are not in it. The
# only model involved is toylm.
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

block reading-a-claim
put bench.txt <<'TXT'
is the coffee hot
is the bread fresh
is there cake
TXT
put new.txt <<'TXT'
is the café open at midnight
is the soup free
is the cat a dog
TXT
on 'grep -c "question : is the bread fresh" corpus.txt'
on 'while read q; do echo "$q -> $(toylm generate "question : $q ? answer :" --temperature 0 | head -1)"; done < bench.txt'
on 'while read q; do echo "$q -> $(toylm generate "question : $q ? answer :" --temperature 0 | head -1)"; done < new.txt'
on 'toylm generate "question : when does the café open ? answer :" --samples 10'
