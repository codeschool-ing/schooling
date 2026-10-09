#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); and the programs, the evaluation set, the two
# rubrics and the labels lessons 1 to 10 show, read out of the lessons that
# show them whole (stage, put, and the rubrics' own heredocs).
#
# THE RUBRICS AND EVERY HUMAN LABEL ARE WRITTEN BY THE COURSE: Ana and Bruno
# are people at a shop that does not exist, and their labels are teaching
# data, not a study. They were written by reading the 48 replies of runs/old
# and runs/new as this script produced them on 2026-10-08; a model's replies
# can change from one run to the next, and a reply that changes is no longer
# the one its label describes.
#
# The replies and the judge's verdicts are llama3.2:3b's (a80c4f17acd5),
# through Ollama 0.40.0, at temperature 0, taken 2026-10-08 on 4 cores and
# 15 GB with no GPU.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

L10=$COURSE/lessons/le-0swnwfwg
quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage evalrun.py le-33kcjt4d/exact-and-normalised.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage judge.py le-c6f8t6d7/a-judge-in-code.md
stage agree.py le-0swnwfwg/measuring-agreement.md
stage judge_runs.py le-0swnwfwg/judge-against-people.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-33kcjt4d/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
python3 "$COURSE/lab/fences.py" block "$L10/a-rubric.md" \
  '{"case": "e01", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}' \
  | put data/labels.jsonl
python3 "$COURSE/lab/fences.py" block "$L10/a-rubric.md" 'mkdir -p data/rubrics' | quiet lab exec 'bash -e -s'
python3 "$COURSE/lab/fences.py" block "$L10/better-rubric.md" "cat > data/rubrics/relevance-v2.md <<'EOF'" \
  | quiet lab exec 'bash -e -s'
quiet lab exec 'SPANS=/dev/null python assistant.py "How long is a gift card valid?" >/dev/null; rm -f spans.jsonl'

block runs
on 'python evalrun.py old --release 2026.09.4'
on 'python evalrun.py new --release 2026.10.1'

block v1
on 'python agree.py relevance-v1/ana relevance-v1/bruno'

block v2
on 'python agree.py relevance-v2/ana relevance-v2/bruno'

block judge
on 'python judge_runs.py'
on 'python agree.py relevance-v2/agreed judge'

block rule
on 'python judge_runs.py --refusals-by-key'
on 'python agree.py relevance-v2/agreed judge'

block rubric
on 'python judge_runs.py --refusals-by-key --rubric data/rubrics/relevance-v2.md'
on 'python agree.py relevance-v2/agreed judge'
