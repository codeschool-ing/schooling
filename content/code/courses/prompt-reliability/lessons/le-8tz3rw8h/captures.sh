#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file
#
# lab-capture.sh builds ~/triage as a student has it after this lesson, every
# file read out of the lessons' own fences, and prints each command after a
# prompt, ana@lab:~/triage$, followed by what it printed. The git history is
# made by history.sh, which prompts-in-git.md shows whole; its dates and
# author are written in it, so the hashes quoted are the hashes it makes.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, temperature 0 and seed 1 unless a command sets them, captured on
# 2026-10-08.
#
# Recorded on Ubuntu 24.04 with Python 3.12 and git 2.43, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=14; . "$here/../../lab-capture.sh"

block git
on 'sh history.sh'
on 'git diff 5b2d8d0 a0f1d2a -- prompts/triage.txt'

block version
on 'pl run prompts/triage.txt cases/dev.jsonl --out runs/now.jsonl'
on 'git show c8f1927:prompts/triage.txt > runs/triage-c8f1927.txt'
on 'pl run runs/triage-c8f1927.txt cases/dev.jsonl --out runs/c8f1927.jsonl'
on 'git diff c8f1927 85dfa4e -- prompts/triage.txt | wc -l'
on 'pl run prompts/triage.txt cases/dev.jsonl --set temperature=0.8 --out runs/hot.jsonl'
on 'pl check runs/hot.jsonl'

block log
on 'python3 log.py'
on 'git show 86913c0'
on 'pl run runs/triage-86913c0.txt cases/dev.jsonl --out runs/86913c0.jsonl'
on 'pl show runs/86913c0.jsonl t04'
on 'python3 log.py cases/attacks.jsonl'

block regressions
on 'pl compare runs/c8f1927.jsonl runs/86913c0.jsonl'
on 'pl compare runs/86913c0.jsonl runs/now.jsonl'
on 'pl compare runs/now.jsonl runs/hot.jsonl'
