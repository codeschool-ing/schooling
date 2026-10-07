#!/usr/bin/env bash
# The terminal sessions quoted in lesson 28 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# tot is read out of search-not-a-line.md. prompts/judge.txt is staged with
# put and shown with cat; judge-dead.txt is made from it by the sed shown.
#
# THE MODEL'S REPLIES in judge and judge-dead are llama3.2:3b served by Ollama
# 0.40.0, at temperature 0, captured on 7 October 2026. The 2,962-token run
# without --max-tokens that the lesson mentions was the same prompt, that day.
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

block search-not-a-line
on 'tot 4 9 10 13'
on 'tot 4 9 10 13 --breadth 1'
on 'tot 1 1 1 1'

put prompts/judge.txt <<'P'
Numbers left: 4 13 19
Goal: make 24 using each number exactly once, with + - * /.
Try a few combinations, then give your verdict on the last line:
sure (you found a way), likely (it looks reachable), or impossible (every attempt is far off).
P
block judge
on 'cat prompts/judge.txt'
on 'ask - --temperature 0 < prompts/judge.txt'
block judge-dead
on 'sed "s/4 13 19/1 1 2/" prompts/judge.txt > prompts/judge-dead.txt'
on 'ask - --temperature 0 --max-tokens 150 < prompts/judge-dead.txt'
