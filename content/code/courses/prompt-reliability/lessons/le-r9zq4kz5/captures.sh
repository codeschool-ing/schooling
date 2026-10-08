#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of prompt-reliability, as a script
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
# 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=11; . "$here/../../lab-capture.sh"

block testset
on 'head -n 1 cases/dev.jsonl'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl'
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl compare runs/v2.jsonl runs/v3.jsonl'
on 'pl compare runs/v4.jsonl runs/v3.jsonl'

block unit
on 'pl check runs/v3.jsonl --failures'
on 'grep -n "^CHECKS" pl.py'

block easy
on 'head -n 3 cases/holdout.jsonl'
on 'pl run prompts/v3-examples.txt cases/holdout.jsonl --out runs/v3-holdout.jsonl'
on 'pl check runs/v3-holdout.jsonl --failures'
on 'pl run prompts/v4-only-json.txt cases/holdout.jsonl --out runs/v4-holdout.jsonl'
on 'pl compare runs/v4-holdout.jsonl runs/v3-holdout.jsonl'

block contamination
on 'grep -n "Message:" prompts/v11-contaminated.txt'
on 'grep -E "\"t(22|25|26)\"" cases/dev.jsonl'
on 'pl run prompts/v11-contaminated.txt cases/dev.jsonl --out runs/v11.jsonl'
on 'pl compare runs/v3.jsonl runs/v11.jsonl'
on 'pl check runs/v11.jsonl --failures'
on 'pl run prompts/v11-contaminated.txt cases/holdout.jsonl --out runs/v11-holdout.jsonl'
on 'pl compare runs/v3-holdout.jsonl runs/v11-holdout.jsonl'
on 'pl check runs/v11-holdout.jsonl'

block flaky
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --out runs/hot-a.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --set seed=7 --out runs/hot-b.jsonl'
on 'pl compare runs/hot-a.jsonl runs/hot-b.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/hot.jsonl'
on 'pl check runs/hot.jsonl'
on 'pl check runs/hot.jsonl --failures | grep -E "^t(07|22|25|36)[ #]"'
