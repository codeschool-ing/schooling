#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1, captured on 2026-10-08. The seconds are
# this machine's and will be different on yours.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=2; . "$here/../../lab-capture.sh"

block length
on 'cat -n prompts/v2-long.txt'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl run prompts/v2-long.txt cases/dev.jsonl --out runs/long.jsonl'
on 'python3 stats.py runs/v2.jsonl runs/long.jsonl'

block contradiction
on 'grep -n -e brief -e detail prompts/v2-long.txt'
on 'grep t17 cases/dev.jsonl'
on 'pl show runs/v2.jsonl t17'
on 'pl show runs/long.jsonl t17'
on 'pl show runs/v2.jsonl t23'
on 'pl show runs/long.jsonl t23'

block lint
on 'python3 lint.py prompts/v2-long.txt prompts/v2-json.txt'
on "printf 'Keep the summary to one line.\nLeave nothing out of the summary.\n' > /tmp/two-lines.txt"
on 'python3 lint.py /tmp/two-lines.txt'

block cut
on 'pl check runs/long.jsonl'
on 'pl check runs/v2.jsonl'
on 'pl compare runs/long.jsonl runs/v2.jsonl'
on 'pl compare runs/long.jsonl runs/v2.jsonl --answers'
