#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of prompt-reliability, as a script
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
LESSON=20; . "$here/../../lab-capture.sh"

block t0
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'python3 selfcheck.py runs/v6.jsonl'

block sampled
on 'pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl'
on 'python3 selfcheck.py runs/s5.jsonl | tail -n 4'

block code
on 'pl check runs/v6.jsonl --failures | grep json'
