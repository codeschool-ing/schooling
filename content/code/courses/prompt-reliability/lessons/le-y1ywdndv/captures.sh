#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file
#
# lab-capture.sh builds ~/triage as a student has it after this lesson, every
# file read out of the lessons' own fences, and prints each command after a
# prompt, ana@lab:~/triage$, followed by what it printed.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only (4 cores), temperature 0 and seed 1, captured on 2026-10-09. The
# milliseconds are Ollama's own report of each call, so they are the part of
# this lesson a rerun will not repeat to the digit.
#
# STAGED: the script restarts Ollama before the first block, so that its
# prompt cache starts empty, as it is the first time a student runs these.
# Nothing else may run on the machine while it does: the timings are the
# subject, and a compiler on the same cores shows up in them.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=17; . "$here/../../lab-capture.sh"
for p in $(pgrep -x ollama); do kill "$p"; done
sleep 2
(HOME=$REAL_HOME nohup ollama serve >/dev/null 2>&1 &)
until curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; do sleep 1; done

block cache
on 'python3 timing.py prompts/v8-guide.txt cases/dev.jsonl 5'

block order
on 'head -n 4 prompts/v17-message-first.txt'
on 'python3 timing.py prompts/v17-message-first.txt cases/dev.jsonl 5'
on 'pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/static.jsonl'
on 'pl run prompts/v17-message-first.txt cases/dev.jsonl --out runs/first.jsonl'
on 'python3 stats.py runs/static.jsonl runs/first.jsonl'

block again
on 'python3 timing.py prompts/v17-message-first.txt cases/dev.jsonl 5'

block invalidation
on 'pl compare runs/static.jsonl runs/first.jsonl'
on 'pl compare runs/static.jsonl runs/first.jsonl --answers'
