#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of prompt-reliability, as a script
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
# lesson 14's history.sh, run quietly first, as a student who did lesson 14
# already has it.
#
# THE MODEL IS REAL: llama3.2:3b (Q4_K_M, id a80c4f17acd5) on Ollama 0.40.0,
# CPU only, temperature 0 and seed 1, captured on 2026-10-09.
#
# Recorded on Ubuntu 24.04 with Python 3.12 and git 2.43, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=15; . "$here/../../lab-capture.sh"
quiet 'sh history.sh'

block log
on "git log --format='%h %ad %s' --date=short -- prompts/triage.txt"
on 'git log -1 --format=%B 86913c0'
on 'git log -1 --format=%B 85dfa4e'

block evidence
on 'git show 86913c0:prompts/triage.txt > runs/plain.txt'
on 'pl run runs/plain.txt cases/dev.jsonl --out runs/plain.jsonl'
on 'pl run prompts/triage.txt cases/dev.jsonl --out runs/dev.jsonl'
on 'pl compare runs/plain.jsonl runs/dev.jsonl'
on 'grep t12 cases/dev.jsonl'
on 'pl show runs/plain.jsonl t12'
on 'pl show runs/dev.jsonl t12'


block card
on 'for s in dev holdout attacks pasted; do pl run prompts/triage.txt cases/$s.jsonl --out runs/$s.jsonl > /dev/null; printf "%-8s" $s; pl check runs/$s.jsonl | tail -n 1; done'
on 'pl check runs/dev.jsonl --failures'
on 'python3 stats.py runs/dev.jsonl'

block holdout
on 'pl run runs/plain.txt cases/holdout.jsonl --out runs/plain-holdout.jsonl'
on 'pl compare runs/plain-holdout.jsonl runs/holdout.jsonl'

block apostrophe
on 'grep -E "\"t3[78]\"" cases/dev.jsonl'
on 'pl show runs/dev.jsonl t37'
on 'pl show runs/dev.jsonl t38'
