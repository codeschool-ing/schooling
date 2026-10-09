#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file
#
# lab-capture.sh builds ~/triage as a student has it after this lesson, every
# file read out of the lessons' own fences, and cases/all.jsonl made by the
# command measuring-it.md shows. It prints each command after a prompt,
# ana@lab:~/triage$, followed by what it printed.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, temperature 0 and seed 1, captured on 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=5; . "$here/../../lab-capture.sh"

block pile
on 'cat -n prompts/v8-rules.txt'
on 'python3 lint.py prompts/v8-rules.txt'
on 'grep t22 cases/dev.jsonl'

block guide
on 'python3 lint.py prompts/v8-guide.txt'

block measure
on 'cat cases/dev.jsonl cases/holdout.jsonl > cases/all.jsonl'
on 'wc -l cases/all.jsonl'
on 'pl run prompts/v8-rules.txt cases/all.jsonl --out runs/rules.jsonl'
on 'pl run prompts/v8-guide.txt cases/all.jsonl --out runs/guide.jsonl'
on 'pl check runs/rules.jsonl'
on 'pl check runs/guide.jsonl'
on 'pl compare runs/rules.jsonl runs/guide.jsonl'
on 'pl compare runs/rules.jsonl runs/guide.jsonl --answers'
on 'python3 stats.py runs/rules.jsonl runs/guide.jsonl'
on 'pl check runs/rules.jsonl --failures'
on 'pl check runs/guide.jsonl --failures'

block t22
on 'pl show runs/rules.jsonl t22'
on 'pl show runs/guide.jsonl t22'

block reader
on 'grep h01 cases/all.jsonl'
on 'grep -n refund prompts/v8-rules.txt'
on 'grep -n "goes to" prompts/v8-guide.txt'
on 'pl show runs/rules.jsonl h01'
on 'pl show runs/guide.jsonl h01'
