#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of llm-observability, as a script
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
# lessons 1 to 12 show, read out of the lessons that show them whole (stage,
# put); the install lesson 12 shows, run from its own fence; the two runs of
# the evaluation set, which lesson 10 shows; and starting and stopping
# flaky.py in the background.
#
# DeepEval 4.2.8 and RAGAS 0.3.1 run here for real, with their telemetry
# turned off by the two variables the lesson adds. Their model-graded metrics
# use llama3.2:3b (a80c4f17acd5) through Ollama 0.40.0 as their judge, at
# temperature 0, taken 2026-10-08 on 4 cores and 15 GB with no GPU; so do the
# replies they grade.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

quiet lab reset
if ! lab exec 'grep -q RAGAS_DO_NOT_TRACK ~/llmobs/bin/activate'; then
  python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-11ghrmmn/two-frameworks.md" \
    "cat >> ~/llmobs/bin/activate <<'EOF'" | IN_HOME=1 quiet lab exec 'bash -e -s'
fi
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage flaky.py le-9gey5ayh/failures.md
stage evalrun.py le-33kcjt4d/exact-and-normalised.md
stage facts.py le-33kcjt4d/exact-and-normalised.md
stage checks.py le-33kcjt4d/rules-for-the-form.md
stage judge.py le-c6f8t6d7/a-judge-in-code.md
stage builtin.py le-11ghrmmn/what-a-metric-asks.md
stage deepeval_run.py le-11ghrmmn/a-metric-of-your-own.md
stage ragas_run.py le-11ghrmmn/ragas.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-33kcjt4d/exact-and-normalised.md" \
  '{"id": "e01", "question": "How many days do I have to return a printed book?", "gold": ["returns-policy:the-return-window"], "facts": ["30 days"]}' \
  | put data/eval.jsonl
quiet lab exec 'python evalrun.py old --release 2026.09.4 && python evalrun.py new --release 2026.10.1'

quiet lab exec 'rm -f flaky.log; (setsid python flaky.py > /dev/null 2>&1 < /dev/null &); sleep 2'
block builtin
on 'python builtin.py'
quiet lab exec 'pkill -f "^python [f]laky.py" || true; rm -f flaky.log'

block deepeval
on 'python deepeval_run.py | grep -E "faithfulness failed|^2026"'
block ls
on 'ls -a .deepeval'

block ragas
on 'python ragas_run.py 2>/dev/null'
