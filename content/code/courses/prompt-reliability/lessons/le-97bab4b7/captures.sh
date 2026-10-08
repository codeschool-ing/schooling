#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1, captured on 2026-10-08. The attack
# messages are lesson 4's cases/attacks.jsonl: each asks for something
# harmless (a label, a word, a poem, the prompt), and nothing here is aimed at
# anything but this lesson's own prompts.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=10; . "$here/../../lab-capture.sh"

block problem
on 'cat prompts/v4-only-json.txt'
on 'head -n 3 cases/attacks.jsonl'
on 'pl run prompts/v4-only-json.txt cases/attacks.jsonl --out runs/v4-attacks.jsonl'
on 'pl check runs/v4-attacks.jsonl --failures'
on 'pl show runs/v4-attacks.jsonl a04'
on 'pl show runs/v4-attacks.jsonl a06'
on 'pl show runs/v4-attacks.jsonl a10'

block layers
on 'diff prompts/v4-only-json.txt prompts/v5-tagged.txt'
on 'pl run prompts/v5-tagged.txt cases/attacks.jsonl --out runs/v5-attacks.jsonl'
on 'pl check runs/v5-attacks.jsonl --failures'
on 'pl run prompts/v6-escaped.txt cases/attacks.jsonl --out runs/v6-attacks.jsonl'
on 'pl check runs/v6-attacks.jsonl --failures'
on 'pl compare runs/v4-attacks.jsonl runs/v6-attacks.jsonl'
on 'pl compare runs/v4-attacks.jsonl runs/v6-attacks.jsonl --answers'
on 'pl show runs/v6-attacks.jsonl a04'
on 'pl show runs/v6-attacks.jsonl a06'
on 'pl show runs/v6-attacks.jsonl a05'
on 'pl check runs/v4-attacks.jsonl --lenient'

block scan
on 'python3 scan.py cases/attacks.jsonl'
on 'python3 scan.py cases/dev.jsonl | grep -e FLAG -e flagged'

block canary
on 'diff prompts/v6-escaped.txt prompts/v7-canary.txt'
on 'pl run prompts/v7-canary.txt cases/attacks.jsonl --out runs/v7-attacks.jsonl'
on 'pl check runs/v7-attacks.jsonl --failures'
on 'grep -c FOLIO-7Q2X runs/v7-attacks.jsonl'
on 'pl run prompts/reply-canary.txt cases/attacks.jsonl --out runs/reply-attacks.jsonl --var shop=Folio --var language=English'
on 'grep -c FOLIO-7Q2X runs/reply-attacks.jsonl'
on 'pl show runs/reply-attacks.jsonl a04'
on 'pl show runs/reply-attacks.jsonl a10'
on 'pl show runs/reply-attacks.jsonl a09'
on 'pl show runs/reply-attacks.jsonl a02'
