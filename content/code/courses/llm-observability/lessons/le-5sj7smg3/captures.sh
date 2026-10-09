#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs, the price list, the evaluation set
# and releases.json that lessons 1 to 15 show, read out of the lessons that
# show them whole (stage, put); version 2 of the set, built by lesson 13's
# buildset.py; and pytest, installed as this lesson says.
#
# The GitHub Actions workflow in the lesson is NOT RUN HERE: this machine is
# not a GitHub runner. It is shown as a file, with its actions pinned to the
# commits their tags named on 2026-10-09 (git ls-remote), and the commands in
# its steps are the ones run below. Every reply is llama3.2:3b's
# (a80c4f17acd5) or llama3.2:1b's (baf6a787fdff) through Ollama 0.40.0, at
# temperature 0, taken on the day this ran.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

L15=$COURSE/lessons/le-5sj7smg3
quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage evalrun.py le-33kcjt4d/exact-and-normalised.md
stage facts.py le-33kcjt4d/exact-and-normalised.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage costs.py le-3s3pd3qk/tokens-to-money.md
stage regress.py le-xcajhvqb/the-release-that-shipped.md
stage docs.py le-6b7d05dk/versioning.md
stage buildset.py le-6b7d05dk/versioning.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-3s3pd3qk/tokens-to-money.md" '{' | put prices.json
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-33kcjt4d/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-6b7d05dk/cases-from-traffic.md" \
  '{"id": "e25", "question": "right of withdrawal days", "gold": ["returns-policy:the-right-of-withdrawal"], "facts": ["seven days", "7 days"], "source": "traffic 2026-09-28 to 10-04, doubted", "added": "2026-10-08"}' \
  | put data/eval-additions.jsonl
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-xcajhvqb/what-changed.md" '{' | put releases.json
quiet lab exec 'python buildset.py'
python3 "$COURSE/lab/fences.py" block "$L15/the-gate-as-tests.md" 'pip install pytest==9.1.1' | quiet lab exec 'bash -e -s'
python3 "$COURSE/lab/fences.py" block "$L15/the-gate-as-tests.md" '{' | put gate.json
stage tests/conftest.py le-5sj7smg3/the-gate-as-tests.md
stage tests/test_set.py le-5sj7smg3/the-gate-as-tests.md
stage tests/test_regression.py le-5sj7smg3/the-gate-as-tests.md

block tree
on 'find tests -name "*.py" | sort'

block history
on 'PRODUCTION=2026.09.4 CANDIDATE=2026.10.1 python -m pytest -q --tb=line -p no:cacheprovider tests'

block fix
on 'CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests'

python3 "$COURSE/lab/fences.py" block "$L15/a-decision-in-a-file.md" '{' | put gate.json

block accepted
on 'CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests'

block both
on 'CANDIDATE=2026.10.4 python -m pytest -q --tb=line -p no:cacheprovider tests'

block missing
on 'python -m pytest -q --tb=line -p no:cacheprovider tests'

block regress
on 'python regress.py production candidate | head -12'
