#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1 unless a command sets them, captured on
# 2026-10-09.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=21; . "$here/../../lab-capture.sh"

block stated
on 'grep -n confidence prompts/v9-confidence.txt'
on 'pl run prompts/v9-confidence.txt cases/all.jsonl --out runs/v9.jsonl'
on 'pl check runs/v9.jsonl'
on "grep -o 'confidence\\\\\": [0-9.]*' runs/v9.jsonl | sort | uniq -c"
on 'grep h03 cases/all.jsonl'
on 'pl show runs/v9.jsonl h03'
on 'pl show runs/v9.jsonl t35'

block reliability
on 'python3 calibrate.py runs/v9.jsonl'

block thresholds
on 'pl run prompts/v9-confidence.txt cases/dev.jsonl --out runs/v9-dev.jsonl'
on 'pl run prompts/v9-confidence.txt cases/holdout.jsonl --out runs/v9-holdout.jsonl'
on 'python3 calibrate.py runs/v9-dev.jsonl --thresholds'
on 'python3 calibrate.py runs/v9-holdout.jsonl --thresholds'
