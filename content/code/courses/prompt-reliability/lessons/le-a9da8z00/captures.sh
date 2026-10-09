#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1, captured on 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=4; . "$here/../../lab-capture.sh"

block holes
on 'pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio; echo "exit status $?"'
on 'pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English'
on 'head -n 3 cases/dev.jsonl > cases/three.jsonl'
on 'pl run prompts/reply.txt cases/three.jsonl --out runs/reply-en.jsonl --var shop=Folio --var language=English'
on 'pl run prompts/reply.txt cases/three.jsonl --out runs/reply-pt.jsonl --var shop=Folio --var language=Portuguese'
on 'pl show runs/reply-en.jsonl t01'
on 'pl show runs/reply-pt.jsonl t01'

block unused
on 'pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English --var tone=warm > /dev/null'
on 'pl run prompts/reply.txt cases/three.jsonl --out runs/reply-warm.jsonl --var shop=Folio --var language=English --var tone=warm'

block data
on 'grep a08 cases/attacks.jsonl'
on 'pl render prompts/v5-tagged.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'
on 'diff prompts/v5-tagged.txt prompts/v6-escaped.txt'
on 'pl render prompts/v6-escaped.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'
on 'grep a08 cases/attacks.jsonl > cases/a08.jsonl'
on 'pl run prompts/v5-tagged.txt cases/a08.jsonl --out runs/a08-tagged.jsonl'
on 'pl run prompts/v6-escaped.txt cases/a08.jsonl --out runs/a08-escaped.jsonl'
on 'pl show runs/a08-tagged.jsonl a08'
on 'pl show runs/a08-escaped.jsonl a08'

block ids
on 'head -n 3 prompts/v6-header.txt'
on 'pl run prompts/v6-header.txt cases/three.jsonl --out runs/header.jsonl'
on 'sha256sum prompts/v6-header.txt | cut -c1-8'
on 'pl run prompts/v6-escaped.txt cases/three.jsonl --out runs/plain.jsonl'
on 'pl run prompts/v6-escaped.txt cases/three.jsonl --out runs/plain-60.jsonl --set num_predict=60'
