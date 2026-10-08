#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file
#
# lab-capture.sh builds ~/triage as a student has it after this lesson, every
# file read out of the lessons' own fences, and pl.py with the one-line edit
# setting-the-cap.md shows. It prints each command after a prompt,
# ana@lab:~/triage$, followed by what it printed.
#
# The caps in the commands, 25, 38 and 76, were chosen from a run of this
# same script's prompts on this machine before it: 38 is the longest reply
# v4-only-json.txt wrote over the seventy cases, which the block `measure`
# prints again.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, temperature 0 and seed 1, captured on 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=6; . "$here/../../lab-capture.sh"

block tokens
on 'python3 tokens.py prompts/v4-only-json.txt'
on "echo 'They were charged twice for order 4471.' | python3 tokens.py -"
on "echo '{\"summary\": \"They were charged twice for order 4471.\"}' | python3 tokens.py -"
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl show runs/v4.jsonl t01'

block cap
on 'pl check runs/v4.jsonl'
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --set num_predict=25 --out runs/cap25.jsonl'
on 'pl check runs/cap25.jsonl'
on "pl check runs/cap25.jsonl --failures | grep -c 'cut off at num_predict'"
on 'pl show runs/cap25.jsonl t01'
on 'python3 stats.py runs/v4.jsonl'

block words
on 'diff prompts/v4-only-json.txt prompts/v4-words.txt'
on 'pl run prompts/v4-words.txt cases/dev.jsonl --out runs/words.jsonl'
on 'pl show runs/v4.jsonl t37'
on 'pl show runs/words.jsonl t37'
on 'python3 stats.py runs/v4.jsonl runs/words.jsonl'
on 'pl check runs/words.jsonl'
on 'pl compare runs/v4.jsonl runs/words.jsonl --answers'
on 'pl run prompts/v4-words.txt cases/dev.jsonl --set num_predict=25 --out runs/words25.jsonl'
on 'pl check runs/words25.jsonl'

block measure
on 'pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4-all.jsonl'
on 'python3 stats.py runs/v4-all.jsonl'

block confidence
on 'pl run prompts/v9-confidence.txt cases/dev.jsonl --set num_predict=38 --out runs/v9-38.jsonl'
on 'pl check runs/v9-38.jsonl --failures'
on 'pl run prompts/v9-confidence.txt cases/dev.jsonl --set num_predict=76 --out runs/v9-76.jsonl'
on 'pl check runs/v9-76.jsonl'
on 'python3 stats.py runs/v9-76.jsonl'
on 'pl compare runs/v9-38.jsonl runs/v9-76.jsonl'
