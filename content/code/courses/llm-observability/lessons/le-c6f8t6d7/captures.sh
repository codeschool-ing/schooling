#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs lessons 1 to 9 show, read out of the
# lessons that show them whole (stage); and the week lesson 3 replays (lab.sh
# week), kept from that lesson's capture or replayed again if anything that
# decides it has changed.
#
# EVERY VERDICT IN THIS LESSON IS llama3.2:3b's (a80c4f17acd5), through Ollama
# 0.40.0, at temperature 0, the same model that wrote the replies it grades;
# taken 2026-10-08 on 4 cores and 15 GB with no GPU, which is what the minutes
# the lesson quotes were measured on. Its price is the course's, from
# prices.json, as lesson 3 says.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

L9=le-c6f8t6d7
quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage costs.py le-3s3pd3qk/tokens-to-money.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-3s3pd3qk/tokens-to-money.md" '{' | put prices.json
stage judge.py $L9/a-judge-in-code.md
stage week.py $L9/a-judge-in-code.md
stage one.py $L9/a-judge-in-code.md
stage sample.py $L9/three-ways-to-sample.md
stage grade_sample.py $L9/three-ways-to-sample.md
stage judge_cost.py $L9/the-cost-of-grading.md
stage sizes.py $L9/how-sure.md
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab exec 'SPANS=/dev/null python assistant.py "How long is a gift card valid?" >/dev/null; rm -f spans.jsonl feedback.jsonl'
quiet lab week
quiet lab exec 'rm -f judge-spans.jsonl verdicts.jsonl'

block one
on 'python one.py'

block all
on 'python grade_sample.py uniform --share 1.0'

block uniform
on 'python grade_sample.py uniform --share 0.1'

block stratified
on 'python grade_sample.py stratified --per-group 30'

block targeted
on 'python grade_sample.py targeted'

block cost
on 'python judge_cost.py'

block sizes
on 'python sizes.py'
