#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file
#
# lab-capture.sh builds ~/triage as a student has it after this lesson, every
# file read out of the lessons' own fences. prompts/v5-backticks.txt is the
# one file made by a command, the sed in backticks.md, and the block
# `backticks` runs that sed itself before it reads the file.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, temperature 0 and seed 1, captured on 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=9; . "$here/../../lab-capture.sh"

block why
on 'tail -n 3 prompts/v4-only-json.txt'
on 'pl render prompts/v4-only-json.txt --cases cases/pasted.jsonl --case p04 | tail -n 7 | cat -n'
on 'pl run prompts/v4-only-json.txt cases/pasted.jsonl --out runs/pasted-v4.jsonl'
on 'pl check runs/pasted-v4.jsonl --failures'
on 'pl show runs/pasted-v4.jsonl p01'
on 'pl show runs/pasted-v4.jsonl p04'

block backticks
on "sed -e 's/between <message> tags/between triple backticks/' -e 's|^</\\?message>\$|\`\`\`|' prompts/v5-tagged.txt > prompts/v5-backticks.txt"
on 'cat -n prompts/v5-backticks.txt'
on 'pl run prompts/v5-backticks.txt cases/pasted.jsonl --out runs/backticks.jsonl'
on 'pl check runs/backticks.jsonl --failures'
on 'pl render prompts/v5-backticks.txt --cases cases/pasted.jsonl --case p04 | tail -n 8 | cat -n'
on 'pl show runs/backticks.jsonl p04'

block tagged
on 'diff prompts/v5-backticks.txt prompts/v5-tagged.txt'
on 'pl run prompts/v5-tagged.txt cases/pasted.jsonl --out runs/tagged.jsonl'
on 'pl check runs/tagged.jsonl --failures'
on 'pl compare runs/backticks.jsonl runs/tagged.jsonl'
on 'pl compare runs/backticks.jsonl runs/tagged.jsonl --answers'
on 'pl compare runs/pasted-v4.jsonl runs/tagged.jsonl --answers'
on 'pl show runs/tagged.jsonl p05'

block escaped
on 'pl run prompts/v6-escaped.txt cases/pasted.jsonl --out runs/escaped.jsonl'
on 'pl check runs/escaped.jsonl --failures'
on 'pl render prompts/v5-tagged.txt --cases cases/pasted.jsonl --case p05 | tail -n 3'
on 'pl render prompts/v6-escaped.txt --cases cases/pasted.jsonl --case p05 | tail -n 3'
on 'pl show runs/escaped.jsonl p05'
on 'pl run prompts/v5-tagged.txt cases/attacks.jsonl --out runs/attacks-v5.jsonl'
on 'pl run prompts/v6-escaped.txt cases/attacks.jsonl --out runs/attacks-v6.jsonl'
on 'pl compare runs/attacks-v5.jsonl runs/attacks-v6.jsonl'
on 'pl compare runs/attacks-v5.jsonl runs/attacks-v6.jsonl --answers'
on 'pl check runs/attacks-v6.jsonl --failures'
