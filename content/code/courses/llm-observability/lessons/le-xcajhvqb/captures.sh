#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs, the price list and the evaluation
# set lessons 1 to 14 show, read out of the lessons that show them whole
# (stage, put); and version 2 of the set, built by lesson 13's buildset.py.
#
# The three candidates are releases the course wrote, each a line of
# releases.json that a team could have proposed. Every reply is
# llama3.2:3b's (a80c4f17acd5) or llama3.2:1b's (baf6a787fdff) through
# Ollama 0.40.0, at temperature 0, taken on the day this ran. The runs are made
# now, so every reply is priced at today's prices, whatever release produced
# it.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

L14=$COURSE/lessons/le-xcajhvqb
quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage evalrun.py le-33kcjt4d/exact-and-normalised.md
stage facts.py le-33kcjt4d/exact-and-normalised.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage costs.py le-3s3pd3qk/tokens-to-money.md
stage docs.py le-6b7d05dk/versioning.md
stage buildset.py le-6b7d05dk/versioning.md
stage regress.py le-xcajhvqb/the-release-that-shipped.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-3s3pd3qk/tokens-to-money.md" '{' | put prices.json
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-33kcjt4d/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-6b7d05dk/cases-from-traffic.md" \
  '{"id": "e25", "question": "right of withdrawal days", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}' \
  | put data/eval-additions.jsonl
quiet lab exec 'python buildset.py'
python3 "$COURSE/lab/fences.py" block "$L14/what-changed.md" '{' | put releases.json

block runs
on 'for r in 2026.09.4 2026.10.1 2026.10.2 2026.10.3 2026.10.4; do python evalrun.py $r --set data/eval-v2.jsonl --release $r; done'

block history
on 'python regress.py 2026.09.4 2026.10.1'

block model
on 'python regress.py 2026.10.1 2026.10.2'

block floor
on 'python regress.py 2026.10.1 2026.10.3'

block both
on 'python regress.py 2026.10.1 2026.10.4'

block refuse
on 'python evalrun.py v1 --release 2026.10.1 && python regress.py 2026.10.1 v1'
