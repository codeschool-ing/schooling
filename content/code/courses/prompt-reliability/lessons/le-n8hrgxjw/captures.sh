#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of prompt-reliability, as a script
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
# CPU only, captured on 2026-10-08. next.py reads the model's own log
# probabilities for its ten likeliest tokens and draws from them with
# Python's random module seeded at 1; the `pl run` blocks sample the model
# itself at the temperature each command sets.
#
# TWO MACHINES. The blocks scores, temperature, topkp and task were captured on
# one; vary and machine on another, later the same day, after the first was
# gone. That is the point of `machine`, which repeats lesson 1's run of
# v2-json.txt; a rerun of the whole script on one machine prints its own
# numbers, and may differ from the lesson by a reply or two.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=8; . "$here/../../lab-capture.sh"

block scores
on 'grep t22 cases/dev.jsonl'
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22'
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t08'

block temperature
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 0.2'
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 1.5'

block topkp
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --top-k 3'
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --top-p 0.9'
on 'python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 1.5 --top-p 0.9'

block task
on 'pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --out runs/t0.jsonl'
on 'pl check runs/t0.jsonl'
on 'pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/t1.jsonl'
on 'pl check runs/t1.jsonl'
on "pl check runs/t1.jsonl --failures | grep -e '^t22' -e '^t01'"
on 'pl run prompts/v6-escaped.txt cases/dev.jsonl --samples 5 --set temperature=0.2 --out runs/t02.jsonl'
on 'pl check runs/t02.jsonl'

block vary
quiet 'head -n 3 cases/dev.jsonl > cases/three.jsonl'
on 'pl run prompts/reply.txt cases/three.jsonl --samples 3 --out runs/same.jsonl --var shop=Folio --var language=English'
on "python3 -c 'import json, sys; rows = [json.loads(l) for l in open(sys.argv[1])]; print(len(rows), \"replies,\", len({r[\"text\"] for r in rows}), \"different\")' runs/same.jsonl"
on 'pl run prompts/reply-varied.txt cases/three.jsonl --samples 3 --out runs/varied.jsonl --var shop=Folio --var language=English'
on "python3 -c 'import json, sys; rows = [json.loads(l) for l in open(sys.argv[1])]; print(len(rows), \"replies,\", len({r[\"text\"] for r in rows}), \"different\")' runs/varied.jsonl"
on 'pl show runs/varied.jsonl t01'
on 'pl show runs/varied.jsonl t01 --sample 1'
on 'pl show runs/same.jsonl t01'
on 'pl show runs/same.jsonl t01 --sample 1'
on 'pl show runs/same.jsonl t01 --sample 2'

block machine
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl check runs/v2.jsonl --failures'
