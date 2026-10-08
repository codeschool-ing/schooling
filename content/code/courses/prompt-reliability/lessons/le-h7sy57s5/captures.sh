#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1 except where a command sets temperature
# 0.8 on purpose, captured on 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=7; . "$here/../../lab-capture.sh"

block confound
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'pl run prompts/v7-prose.txt cases/all.jsonl --set temperature=0.8 --out runs/v7-warm.jsonl'
on 'pl compare runs/v6.jsonl runs/v7-warm.jsonl'
on 'head -n 1 runs/v7-warm.jsonl'

block style
on 'diff prompts/v6-escaped.txt prompts/v7-prose.txt'
on 'pl run prompts/v7-prose.txt cases/all.jsonl --out runs/v7.jsonl'
on 'pl check runs/v6.jsonl'
on 'pl check runs/v7.jsonl'
on 'pl compare runs/v6.jsonl runs/v7.jsonl'
on 'pl compare runs/v6.jsonl runs/v7.jsonl --answers'
on 'pl check runs/v6.jsonl --failures'
on 'pl check runs/v7.jsonl --failures'

block sign
on "python3 -c 'from math import comb; [print(n, 2 * comb(n, 0) / 2 ** n) for n in range(1, 9)]'"
on "python3 -c 'from math import comb; [print(n, 1, round(2 * (comb(n, 0) + comb(n, 1)) / 2 ** n, 3)) for n in range(5, 10)]'"

block formats
on "echo 'Order 4471: 2 paperbacks, paid 24.50 on 2026-08-03, sent by courier.' | python3 tokens.py -"
on "echo '{\"order\": \"4471\", \"items\": 2, \"format\": \"paperback\", \"paid\": 24.50, \"date\": \"2026-08-03\", \"sent\": \"courier\"}' | python3 tokens.py -"
on "printf 'order,items,format,paid,date,sent\n4471,2,paperback,24.50,2026-08-03,courier\n' | python3 tokens.py -"
