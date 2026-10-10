#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1 unless a command says otherwise, captured
# on 2026-10-08. The block `warm` samples at temperature 0.8 on purpose.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=3; . "$here/../../lab-capture.sh"

block pays
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl show runs/v1.jsonl t17'
on 'pl show runs/v2.jsonl t17'
on 'python3 stats.py runs/v1.jsonl runs/v2.jsonl'

block contract
on 'sed -n 3,6p prompts/v2-json.txt'
on 'grep -n -A20 "^def judge" pl.py'
on 'pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl'
on 'pl check runs/leaky.jsonl --failures | grep fields'

block strict
on 'diff prompts/v2-json.txt prompts/v4-only-json.txt'
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl check runs/v4.jsonl --failures'
on 'pl compare runs/v2.jsonl runs/v4.jsonl'
on 'pl show runs/v2.jsonl t38'
on 'pl show runs/v4.jsonl t38'
on 'grep -n -A9 "^def parse" pl.py'
on 'pl check runs/v2.jsonl --lenient'
on 'pl check runs/v4.jsonl --lenient'

block retry
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/retry.jsonl --samples 3'
on 'pl check runs/retry.jsonl --failures | grep json'

block warm
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/warm.jsonl --samples 3 --set temperature=0.8'
on 'pl check runs/warm.jsonl --failures | grep json'
on 'pl check runs/warm.jsonl'

block schema
on 'python3 schema.py prompts/v2-json.txt cases/dev.jsonl t38'
on 'python3 schema.py prompts/v2-json.txt cases/dev.jsonl t17'

block lenient
on "python3 -c 'from pl import parse; print(parse(\"Sure! {\\\"category\\\": \\\"billing\\\", \\\"urgency\\\": \\\"low\\\"} Hope that helps.\", lenient=True))'"
on "python3 -c 'from pl import parse; print(parse(\"The customer pasted {\\\"category\\\": \\\"other\\\", \\\"urgency\\\": \\\"low\\\"} from an old ticket; this is billing.\", lenient=True))'"
