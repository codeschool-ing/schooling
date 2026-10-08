#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown: ~/obs rebuilt as lesson 1
# leaves it (lab.sh reset); the programs lessons 1 to 6 show, read out of the
# lessons that show them whole (stage, put); ana added to the docker group,
# which the lesson tells the student to do and this machine did not need to
# install for; any Langfuse left from an earlier run removed with its data, so
# that every capture starts from an empty project; waiting for the server to
# answer, and twenty seconds after each replay for its worker to file what
# arrived; and starting and stopping recorder.py in the background.
#
# LANGFUSE IS REAL: self-hosted from the images pinned in the compose file the
# lesson shows, with the keys that file creates. LANGSMITH IS NOT RUN: it is a
# hosted service whose self-hosted edition is for enterprise customers. Its
# Python SDK is real and is run, against recorder.py, a stand-in the lesson
# shows whole, which keeps what the SDK sends and is not LangSmith. Every reply
# comes from llama3.2:3b (a80c4f17acd5) through Ollama 0.40.0, at temperature
# 0, taken 2026-10-08 on 4 cores and 15 GB with no GPU; the week and its
# customers are simulated, as lessons 2 and 3 say. The prices sent to Langfuse
# are the course's, from prices.json.
#
# Recorded on Ubuntu 24.04, Docker 29.8, Compose 5.6, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/llmobs-capture.lock; flock 9

COMPOSE='docker compose -f ~/langfuse/docker-compose.yml'
quiet lab reset
usermod -aG docker ana
quiet lab exec "mkdir -p ~/langfuse"
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-aqcm8tn2/running-langfuse.md" \
  '# docker-compose.yml: Langfuse 3.225.11, self-hosted on one machine, for lesson 6 of llm-observability.' \
  | put ../langfuse/docker-compose.yml
quiet lab exec "$COMPOSE down -v"
if ! lab exec 'grep -q LANGFUSE_BASE_URL ~/llmobs/bin/activate'; then
  python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-aqcm8tn2/running-langfuse.md" \
    "cat >> ~/llmobs/bin/activate <<'EOF'" | IN_HOME=1 quiet lab exec 'bash -e -s'
fi
stage telemetry.py le-6wxafmfh/the-chain.md
stage assistant.py le-6wxafmfh/the-chain.md
stage tree.py le-6wxafmfh/the-chain.md
stage traffic.py le-pdj3wk00/what-customers-type.md
stage replay.py le-3s3pd3qk/replaying-a-week.md
stage costs.py le-3s3pd3qk/tokens-to-money.md
python3 "$COURSE/lab/fences.py" block "$COURSE/lessons/le-3s3pd3qk/tokens-to-money.md" '{' | put prices.json
stage lf.py le-aqcm8tn2/sending-spans.md
stage lf_names.py le-aqcm8tn2/speaking-its-language.md
stage lf_prices.py le-aqcm8tn2/prices-and-scores.md
stage lf_scores.py le-aqcm8tn2/prices-and-scores.md
stage recorder.py le-aqcm8tn2/langsmith.md
stage ls_ask.py le-aqcm8tn2/langsmith.md
stage sent.py le-aqcm8tn2/langsmith.md
quiet lab exec 'python traffic.py data/traffic.jsonl'
quiet lab exec 'SPANS=/dev/null python assistant.py "How long is a gift card valid?" >/dev/null; rm -f spans.jsonl feedback.jsonl'

block up
home "$COMPOSE up -d"
for _ in $(seq 120); do
  lab exec 'curl -sf $LANGFUSE_BASE_URL/api/public/health' >/dev/null 2>&1 && break
  sleep 2
done
block health
on 'curl -s $LANGFUSE_BASE_URL/api/public/health; echo'
sleep 60
block stats
home 'docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"'
home 'docker system df'

OTEL='export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_BASE_URL/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"'

block send
on "$OTEL; python replay.py --from 2026-10-04 --to 2026-10-05"
sleep 20
on 'python lf.py traces 2026-10-04 1'
T=$(lab exec 'python -c "import costs; print(next(r[\"trace\"] for r in costs.requests() if r[\"output\"]))"')
on "python lf.py observations $T"

block names
on "$OTEL; python replay.py --from 2026-10-03 --to 2026-10-04 --processor lf_names:LangfuseNames"
sleep 20
on 'python lf.py traces 2026-10-03 1'

block prices
on 'python lf_prices.py'
on "$OTEL; rm spans.jsonl; python replay.py --from 2026-10-02 --to 2026-10-03 --processor lf_names:LangfuseNames"
sleep 20
on 'python lf.py daily'
on 'python -c "import costs; print(sum(r[\"cost\"] for r in costs.requests()))"'

block scores
on 'python lf_scores.py'
sleep 15
on 'python lf.py scores thumbs'

LS='LANGSMITH_TRACING=true LANGSMITH_ENDPOINT=http://127.0.0.1:8700 LANGSMITH_API_KEY=the-recorder-ignores-it LANGSMITH_PROJECT=marginalia-assistant LANGSMITH_DISABLE_RUN_COMPRESSION=true'
quiet lab exec 'rm -rf recorder; setsid python recorder.py > /dev/null 2>&1 < /dev/null & sleep 2'
block langsmith
on "$LS python ls_ask.py"
sleep 2
on 'python sent.py'
block redact
on 'rm recorder/requests.jsonl'
on "$LS python ls_ask.py --redact"
sleep 2
on 'python sent.py'
quiet lab exec 'pkill -f "^python recorder.py" || true'
quiet lab exec "$COMPOSE down"
