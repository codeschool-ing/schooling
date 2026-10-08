#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset), the programs lessons 1 to 4 show, read out of the
# lessons that show them whole (stage, put), and the week lesson 3 replayed
# (lab.sh week, which replays it again if anything that decides it changed).
# flaky.py runs in the background, as the lesson has the student run it in a
# second terminal, and the lines typed after the lesson's `export` run with it.
#
# EVERY TIMING IS A REAL ONE, from llama3.2:3b (a80c4f17acd5) through Ollama
# 0.40.0, taken 2026-10-08 on 4 cores and 15 GB with no GPU; they move by tens
# of milliseconds from run to run. THE FAILURES ARE ASKED FOR: flaky.py, which
# the lesson shows whole, refuses and cuts requests when told to. The slow
# first call of timeout.py is a real one: the model was unloaded with `ollama
# stop`, as the lesson says.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9
FL='export OPENAI_BASE_URL=http://127.0.0.1:11435/v1; '
onf() { printf 'ana@dev:~/obs$ %s\n' "$*"; run_as "$FL$*" 2>&1 < /dev/null || true; }

quiet lab reset
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage tree.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage stream.py le-9gey5ayh/three-clocks.md
stage latency.py le-9gey5ayh/percentiles.md
stage drivers.py le-9gey5ayh/what-sets-the-time.md
stage flaky.py le-9gey5ayh/failures.md
stage ten.py le-9gey5ayh/failures.md
stage errors.py le-9gey5ayh/failures.md
stage sdk_retry.py le-9gey5ayh/failures.md
stage timeout.py le-9gey5ayh/timeouts.md
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab week
quiet lab exec 'python assistant.py "warm up" >/dev/null'

block three-clocks
on 'python stream.py'

block week
on 'python latency.py'

block drivers
on 'python drivers.py'

quiet lab exec 'rm -f flaky.log; setsid python flaky.py > /dev/null 2>&1 < /dev/null & sleep 1'
block failures
on 'export OPENAI_BASE_URL=http://127.0.0.1:11435/v1'
onf "curl -s -X POST 127.0.0.1:11435/flaky -d '{\"fail_rate\": 0.3}'; echo"
onf 'rm -f spans.jsonl; python ten.py'
onf 'python errors.py'
T=$(lab exec 'python -c "import json; g = [json.loads(l) for l in open(\"spans.jsonl\")]; print(next(s[\"trace\"][:8] for s in g if s[\"name\"] == \"generate\" and s[\"attributes\"][\"app.attempts\"] > 1))"')
onf "python tree.py $T"
onf "python tree.py --attrs $T | grep -E \"ERROR|attempts\""

block sdk-retry
onf "curl -s -X POST 127.0.0.1:11435/flaky -d '{\"fail_rate\": 0, \"fail\": 2}'; echo"
onf 'rm -f spans.jsonl; python sdk_retry.py; python tree.py'
onf 'tail -3 flaky.log'

block cut
onf "curl -s -X POST 127.0.0.1:11435/flaky -d '{\"cut_after\": 6}'; echo"
onf 'rm -f spans.jsonl; python assistant.py "How long is a gift card valid?"'
onf 'python tree.py --attrs | grep -E " ms |ERROR|partial|attempts"'
quiet lab exec 'pkill -f "python flaky.py"'

block timeout
on 'ollama stop llama3.2:3b'
on 'python timeout.py'
