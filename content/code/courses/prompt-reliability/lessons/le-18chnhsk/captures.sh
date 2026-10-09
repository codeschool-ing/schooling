#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file
#
# lab-capture.sh builds ~/triage as a student has it after this lesson, every
# file read out of the lessons' own fences, and prints each command after a
# prompt, ana@lab:~/triage$, followed by what it printed. cases/names-b.jsonl
# is made by the sed in counterfactual-tests.md, which the block `names` runs.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, temperature 0 and seed 1, captured on 2026-10-09.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=18; . "$here/../../lab-capture.sh"

block order
on 'diff prompts/v6-escaped.txt prompts/v18-order.txt'
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'pl run prompts/v18-order.txt cases/all.jsonl --out runs/order.jsonl'
on 'pl compare runs/v6.jsonl runs/order.jsonl --answers'
on 'pl compare runs/v6.jsonl runs/order.jsonl'
on 'pl check runs/order.jsonl --failures | grep labels'

block leading
on 'diff prompts/v6-escaped.txt prompts/v18-leading.txt'
on 'pl run prompts/v18-leading.txt cases/all.jsonl --out runs/leading.jsonl'
on 'pl compare runs/v6.jsonl runs/leading.jsonl --answers'
on 'pl compare runs/v6.jsonl runs/leading.jsonl'
on 'python3 confusion.py runs/leading.jsonl'

block balance
on 'pl run prompts/v18-skewed.txt cases/all.jsonl --out runs/skewed.jsonl'
on 'pl run prompts/v18-balanced.txt cases/all.jsonl --out runs/balanced.jsonl'
on 'pl compare runs/skewed.jsonl runs/balanced.jsonl --answers'
on 'python3 confusion.py runs/skewed.jsonl'
on 'python3 confusion.py runs/balanced.jsonl'

block names
on "sed 's/Maria Souza/John Smith/' cases/names-a.jsonl > cases/names-b.jsonl"
on 'head -n 1 cases/names-a.jsonl cases/names-b.jsonl'
on 'pl run prompts/v6-escaped.txt cases/names-a.jsonl --out runs/names-a.jsonl'
on 'pl run prompts/v6-escaped.txt cases/names-b.jsonl --out runs/names-b.jsonl'
on 'pl compare runs/names-a.jsonl runs/names-b.jsonl --answers'
on 'pl compare runs/names-a.jsonl runs/names-b.jsonl'
on 'pl show runs/names-a.jsonl n02'
on 'pl show runs/names-b.jsonl n02'
on 'pl show runs/names-a.jsonl n07'
on 'pl show runs/names-b.jsonl n07'
