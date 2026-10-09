#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of prompt-reliability, as a script
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
# CPU only (4 cores), temperature 0 and seed 1 unless a command sets them,
# captured on 2026-10-09. The seconds are this machine's wall clock, so they
# are the one thing in this lesson a rerun will not repeat; the prices are
# prices.json's, which the course wrote for the arithmetic.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=16; . "$here/../../lab-capture.sh"

block time
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl'
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
on 'python3 stats.py runs/v2.jsonl runs/v3.jsonl runs/v1.jsonl'

block cost
on 'python3 cost.py runs/v3.jsonl'
on "python3 -c 'print(0.1 + 0.2)'"

block cutting
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'python3 cost.py runs/v4.jsonl'
on 'pl compare runs/v4.jsonl runs/v3.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --set num_predict=20 --out runs/cap.jsonl'
on 'python3 stats.py runs/cap.jsonl'
on 'pl check runs/cap.jsonl --failures | grep -c "cut off at num_predict"'
on 'pl check runs/v3.jsonl | tail -n 1'
on 'pl show runs/cap.jsonl t01'
