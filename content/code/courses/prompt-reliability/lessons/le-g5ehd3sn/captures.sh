#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1, captured on 2026-10-08. The replies
# tone.py reads are the model's, written by lesson 4's reply.txt.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=12; . "$here/../../lab-capture.sh"

block correctness
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6-all.jsonl'
on 'python3 confusion.py runs/v6-all.jsonl'
on 'python3 confusion.py runs/v6-all.jsonl --field urgency'

block format
on 'pl check runs/v6-all.jsonl --failures | grep json'

block tone
on 'pl run prompts/reply.txt cases/dev.jsonl --out runs/replies.jsonl --var shop=Folio --var language=English'
on 'python3 tone.py runs/replies.jsonl'
on 'pl show runs/replies.jsonl t11'
on 'pl show runs/replies.jsonl t33'
on 'pl show runs/replies.jsonl t06'
on 'grep -c "\[Customer\]" runs/replies.jsonl'

block safety
on 'pl show runs/replies.jsonl t01'
on 'pl show runs/replies.jsonl t13'

block many
on 'pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3-all.jsonl'
on 'pl check runs/v3-all.jsonl'
on 'python3 confusion.py runs/v3-all.jsonl'
