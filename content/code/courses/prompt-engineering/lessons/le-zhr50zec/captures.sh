#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds: three turn files, runs/order.txt,
# runs/weather.txt and runs/unfinished.txt, written with put below. They are a
# model's side of a run WRITTEN BY THE COURSE, and the lesson says so: agent
# plays them back so that each rule of the loop can be watched on its own.
# order.txt is shown with cat; the other two hold the model> lines
# their runs print. agent and tools.txt are read out of tool-calls.md.
#
# THE MODEL'S TURNS in ask-tools, live-order and live-allow are llama3.2:3b
# served by Ollama 0.40.0, at temperature 0, captured on 7 October 2026.
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

put runs/order.txt <<'T'
# Question: Bruno wants three whole cakes at R$ 42.50 each, to collect
# tomorrow. What day is tomorrow, and what is the total?
Action: today[]
---
Action: calculator[3 * 42.50]
---
Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
T
put runs/weather.txt <<'T'
# Question: should the café put the terrace tables out this afternoon?
Action: weather[São Paulo]
---
Answer: I cannot check the weather from here, so I cannot say.
T
put runs/unfinished.txt <<'T'
Action: today[]
---
Action: calculator[3 * 42.50]
T

block ask-tools
on 'ask "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?" --system "$(cat tools.txt)" --temperature 0'
block live-order
on 'agent --live "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?"'
block playback-order
on 'cat runs/order.txt'
on 'agent runs/order.txt'

block the-loop
on 'agent runs/weather.txt'
on 'agent runs/order.txt --allow calculator'
block live-allow
on 'agent --live "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?" --allow calculator'
block the-loop-2
on 'agent runs/order.txt --max-steps 1'
on 'agent runs/unfinished.txt'
