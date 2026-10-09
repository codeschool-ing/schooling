#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs and the evaluation set lessons 1 to
# 13 show, read out of the lessons that show them whole (stage, put); and the
# week lesson 3 replays (lab.sh week), kept from that lesson's capture or
# replayed again if anything that decides it has changed.
#
# THE EIGHT NEW CASES ARE WRITTEN BY THE COURSE, from the questions harvest.py
# lists: their wording is the customers', with every name, address, number and
# order replaced by values invented for the test and declared as such, and
# their facts and gold chunks were written from the documents, as a person
# maintaining the set would. What the customers typed was itself written by
# the course (lesson 2's traffic.py). The replies that decided which questions
# were doubted are llama3.2:3b's (a80c4f17acd5) through Ollama 0.40.0, at
# temperature 0, taken 2026-10-08.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

L13=$COURSE/lessons/le-6b7d05dk
quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage harvest.py le-6b7d05dk/cases-from-traffic.md
stage docs.py le-6b7d05dk/versioning.md
stage buildset.py le-6b7d05dk/versioning.md
stage check_set.py le-6b7d05dk/keeping-it-true.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-33kcjt4d/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
python3 "$COURSE/lab/fences.py" block "$L13/cases-from-traffic.md" \
  '{"id": "e25", "question": "right of withdrawal days", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}' \
  | put data/eval-additions.jsonl
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab week

block harvest
on 'python harvest.py'

block additions
on 'wc -l data/eval.jsonl data/eval-additions.jsonl'
on 'grep e31 data/eval-additions.jsonl'

block build
on 'python buildset.py'

block check
on 'python check_set.py data/eval-v2.jsonl'

block pasted
on "cp data/eval-v2.jsonl draft.jsonl && echo '{\"id\": \"e33\", \"question\": \"This is Marta Seixas, order [order]: can I still return a book I got 3 weeks ago? My email is [email].\", \"gold\": [\"returns-policy:the-return-window\"], \"facts\": [\"30 days\"]}' >> draft.jsonl"
on 'python check_set.py draft.jsonl'

block stale
on "cp -r data/docs docs-next && sed -i -e 's/over R\\\$ 40/over R\$ 50/' -e 's/^updated: .*/updated: 2026-10-08/' docs-next/shipping-and-delivery.md"
on 'python check_set.py data/eval-v2.jsonl --docs docs-next'
