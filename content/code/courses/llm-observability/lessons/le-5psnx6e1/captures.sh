#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs, the evaluation set and the labels
# lessons 1 to 11 show, read out of the lessons that show them whole (stage,
# put); and the two runs of the evaluation set, which lesson 10 shows.
#
# The agreed labels are lesson 10's, WRITTEN BY THE COURSE by reading the
# replies of those runs. The replies and every score are llama3.2:3b's
# (a80c4f17acd5), through Ollama 0.40.0, at temperature 0, taken 2026-10-08 on
# 4 cores and 15 GB with no GPU.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage evalrun.py le-33kcjt4d/exact-and-normalised.md
stage facts.py le-33kcjt4d/exact-and-normalised.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage judge.py le-c6f8t6d7/a-judge-in-code.md
stage sweep.py le-5psnx6e1/a-threshold-is-a-trade.md
stage metrics.py le-5psnx6e1/five-metrics.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-33kcjt4d/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-0swnwfwg/a-rubric.md" \
  '{"case": "e01", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}' \
  | put data/labels.jsonl
quiet lab exec 'python evalrun.py old --release 2026.09.4 && python evalrun.py new --release 2026.10.1'

block sweep
on 'python sweep.py'

block metrics
on 'python metrics.py old new'
