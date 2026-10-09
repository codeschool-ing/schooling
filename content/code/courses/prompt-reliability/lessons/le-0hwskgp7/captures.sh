#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of prompt-reliability, as a script
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
# CPU only, temperature 0 and seed 1 unless a command sets them, captured on
# 2026-10-09.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=19; . "$here/../../lab-capture.sh"

block three
on 'pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3.jsonl'
on 'pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4.jsonl'
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'python3 vote.py runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl'
on "for r in v3 v4 v6; do pl check runs/\$r.jsonl --failures | awk '\$2 == \"json\" || \$2 == \"category\" {print \$1}'; done | sort | uniq -c | sort -rn"

block against
on "for r in v3 v4 v6; do pl check runs/\$r.jsonl --failures | awk '\$2 == \"json\" || \$2 == \"category\" {print \$1}' | sort > runs/\$r.wrong; done"
on 'comm -12 runs/v4.wrong runs/v6.wrong | comm -23 - runs/v3.wrong | paste -sd " "'
on 'comm -23 runs/v3.wrong <(sort -m runs/v4.wrong runs/v6.wrong) | paste -sd " "'

block sampling
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl'
on 'python3 vote.py runs/s5.jsonl'
on "pl check runs/s5.jsonl --failures | awk '\$2 == \"json\" || \$2 == \"category\" {print substr(\$1, 1, 3)}' | sort | uniq -c | awk '\$1 < 5'"
on 'pl show runs/v6.jsonl t38'
on "pl check runs/s5.jsonl --failures | grep '^t38'"

block cost
on 'python3 cost.py runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl runs/s5.jsonl'
on 'python3 stats.py runs/v6.jsonl runs/s5.jsonl'
