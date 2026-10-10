#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of prompt-reliability, as a script
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
# THE MODEL IS REAL, and here it is the judge: llama3.2:3b (Q4_K_M, id
# a80c4f17acd5) on Ollama 0.40.0, CPU only, temperature 0 and seed 1,
# captured on 2026-10-08. The sixteen pairs and their verdicts were written
# by the course.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
here=$(cd "$(dirname "$0")" && pwd)
LESSON=13; . "$here/../../lab-capture.sh"

block measure
on 'python3 judge.py cases/pairs.jsonl'
on "grep -c '\"human\": \"a\"' cases/pairs.jsonl"

block biases
on 'python3 judge.py cases/pairs.jsonl --swap'
on "python3 -c 'import json; [print(p[\"id\"], p[\"human\"], len(p[\"a\"]), len(p[\"b\"])) for p in map(json.loads, open(\"cases/pairs.jsonl\"))]'"
on "grep '\"j16\"' cases/pairs.jsonl"
