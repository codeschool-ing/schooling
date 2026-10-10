#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs lessons 1 to 7 show, read out of the
# lessons that show them whole (stage); stopping any Phoenix left from an
# earlier run and removing its data, so that every capture starts from an
# empty one; starting Phoenix and flaky.py in the background with the
# commands the lesson shows, waiting for Phoenix to answer, and five seconds
# after the replay for it to receive the last batch.
#
# ARIZE PHOENIX IS REAL, version 20.18.0, installed with the pip line the
# lesson shows. Arize AX, the hosted product, is not run. HELICONE IS NOT RUN:
# its self-hosted image is a 3.5 GB download, measured from its registry
# manifest at the digest helicone/helicone-all-in-one@sha256:4da15718dd49...;
# the gateway in this lesson's transcript is lesson 4's flaky.py, which is not
# Helicone. Every reply comes from llama3.2:3b (a80c4f17acd5) through Ollama
# 0.40.0, at temperature 0, taken 2026-10-08 on 4 cores and 15 GB with no GPU;
# the week and its customers are simulated, as lessons 2 and 3 say.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

quiet lab reset
quiet lab exec 'pkill -f "bin/[p]hoenix serve" || true; pkill -f "^python [f]laky.py" || true; rm -rf ~/.phoenix ~/phoenix.log; sleep 1'
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage tree.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage flaky.py le-9gey5ayh/failures.md
stage px_spans.py le-8njh6jys/phoenix.md
stage px_thumbs.py le-8njh6jys/annotations.md
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab exec 'SPANS=/dev/null python assistant.py "How long is a gift card valid?" >/dev/null; rm -f spans.jsonl feedback.jsonl'

block gateway
quiet lab exec 'rm -f flaky.log; (setsid python flaky.py > /dev/null 2>&1 < /dev/null &); sleep 2'
on 'OPENAI_BASE_URL=http://127.0.0.1:11435/v1 python assistant.py "How long is a gift card valid?"'
on 'cat flaky.log'
T=$(lab exec 'python -c "import json; print(json.loads(open(\"spans.jsonl\").readlines()[-1])[\"trace\"][:8])"')
on "python tree.py $T"
quiet lab exec 'pkill -f "^python [f]laky.py" || true; rm -f spans.jsonl flaky.log'

block pip
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-8njh6jys/phoenix.md" 'pip install arize-phoenix==20.18.0' \
  | quiet lab exec 'bash -e -s'
on 'du -sh ~/llmobs'
on 'pip list 2>/dev/null | grep -E "^opentelemetry-sdk "'

python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-8njh6jys/phoenix.md" \
  'PHOENIX_HOST=127.0.0.1 PHOENIX_TELEMETRY_ENABLED=false phoenix serve > ~/phoenix.log 2>&1 &' \
  | quiet lab exec 'bash -s'
for _ in $(seq 120); do
  lab exec 'curl -sf -o /dev/null http://127.0.0.1:6006/' >/dev/null 2>&1 && break
  sleep 2
done
block health
on 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:6006/'
on 'curl -s -o /dev/null -w "%{http_code}\n" http://$(hostname -I | cut -d" " -f1):6006/'

block replay
on 'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:6006/v1/traces python replay.py --from 2026-10-04 --to 2026-10-05'
sleep 5
block spans
on 'python px_spans.py'

block annotations
on 'python px_thumbs.py'
quiet lab exec 'pkill -f "bin/[p]hoenix serve" || true'
