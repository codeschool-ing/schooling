#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs and the evaluation set lessons 1 to 8
# show, read out of the lessons that show them whole (stage, put); and the
# week lesson 3 replays (lab.sh week), kept from that lesson's capture or
# replayed again if anything that decides it has changed.
#
# data/eval.jsonl IS WRITTEN BY THE COURSE: its questions, the facts a right
# reply contains and the chunks that hold them, checked against the documents
# lesson 1 builds. The replies in normalise.py and broken.py are WRITTEN BY
# THE COURSE to show what a comparison and a rule do; no model wrote them, and
# the lesson says so. Every other reply comes from llama3.2:3b (a80c4f17acd5)
# through Ollama 0.40.0, at temperature 0, taken 2026-10-08 on 4 cores and
# 15 GB with no GPU.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

L8=le-33kcjt4d
quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage tree.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage evalrun.py $L8/exact-and-normalised.md
stage facts.py $L8/exact-and-normalised.md
stage normalise.py $L8/exact-and-normalised.md
stage checks.py $L8/rules-for-the-form.md
stage broken.py $L8/rules-for-the-form.md
stage check_run.py $L8/on-every-reply.md
stage check_week.py $L8/on-every-reply.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/$L8/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab exec 'SPANS=/dev/null python assistant.py "How long is a gift card valid?" >/dev/null; rm -f spans.jsonl feedback.jsonl'
quiet lab week

block run
on 'python evalrun.py current'
on 'head -c 700 runs/current.jsonl; echo'

block facts
on 'python facts.py current'

block normalise
on 'python normalise.py'

block checks
on 'python check_run.py current'

block broken
on 'python broken.py'

block week
on 'python check_week.py'
