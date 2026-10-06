#!/usr/bin/env bash
# The machine every transcript in llm-observability was recorded on.
#
# IT IS rag's MACHINE, WITH THE ASSISTANT IN PRODUCTION. ana is still a
# developer at Marginalia, the online bookshop that does not exist. rag left
# her with a retrieval pipeline over the shop's documents; this course puts it
# in front of customers as a help assistant and then watches it: spans on
# every step, tokens and money, latency, feedback, and the evaluations that
# say whether the answers are any good. `up` runs ../rag/lab.sh up first
# (which runs ../embeddings-vectors/lab.sh up), and everything below is what
# observing and evaluating needs that retrieval did not.
#
#   /home/ana/obs           the working directory, rebuilt by `reset`
#     data/docs/*.md        rag's thirteen documents, copied as they are
#     data/eval.jsonl       rag's 30 questions with their facts
#     data/traffic.jsonl    a week of requests, 28 September to 4 October
#                           2026, drawn by lab/traffic.py (lessons 3 to 5, 9,
#                           16), and data/topics.json, its topics and facts
#     prices.json           what a token costs, WRITTEN BY THE COURSE
#     releases.json         which settings the assistant ran with, and from
#                           when: a release on 2 October raised the floor
#   lab/code/*.py           the programs the lessons build and later ones
#                           reuse (telemetry, redact, assistant, replay, tree),
#                           copied into ~/obs by each lesson's captures.sh
#   /opt/llmobs             Python 3.11 in a virtual environment with the
#                           libraries in OBSLIBS, labgen and minilm from the
#                           courses before this one, and labobs from here
#   /run/emb-pg             embeddings-vectors' PostgreSQL 16 with pgvector;
#                           this course uses its own database, `obs`, filled
#                           by rag's chunking.py and ingest.py
#   127.0.0.1:8500          labembed, embeddings-vectors' stand-in provider
#   127.0.0.1:8600          labobs (lab/labobs.py), which REPLACES rag's labgen
#                           here: the same extract-1, plus a clock, failures
#                           on request, a second version and a judge
#   127.0.0.1:6006          Arize Phoenix, started by `phoenix` (lesson 7)
#   127.0.0.1:3000          Langfuse, self-hosted, started by `langfuse`
#                           (lesson 6): six containers, lab/langfuse/
#   127.0.0.1:8700          a recorder that answers like LangSmith's ingest
#                           endpoint and keeps what it receives (lesson 6)
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real       OpenTelemetry's SDK and exporters; Arize Phoenix; Langfuse,
#              server and SDK; the LangSmith SDK; DeepEval; RAGAS; pytest;
#              PostgreSQL with pgvector; all-MiniLM-L6-v2. Every number a
#              lesson prints from them was computed on this machine.
#   the lab's  labobs. NO LANGUAGE MODEL WAS REACHABLE from this machine, and
#              an API key is a bill a course cannot hand out. extract-1 and
#              extract-2 copy sentences out of their sources by rules, and
#              judge-1 grades by embedding similarity, by rules; its
#              latencies follow rules too. All of them are written at the
#              top of lab/labobs.py, and every lesson that shows a reply, a
#              timing or a verdict from them says it came from there.
#   written    the traffic and the simulated customers' reactions to the
#              replies (lab/traffic.py, lab/code/replay.py), the prices, the
#              human ratings in lesson 10, and every person, address and
#              order number, all invented.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: any provider's real API; LangSmith's
# service, which is not offered to install (its SDK is run, against the
# recorder); Helicone's and Arize's hosted services. The lessons that show
# their code or settings say they were not run.
#
#   sudo bash lab.sh up               build it (idempotent)
#   sudo bash lab.sh reset            rebuild ~/obs, empty its database, restart labobs
#   sudo bash lab.sh phoenix|phoenix-down
#   sudo bash lab.sh langfuse|langfuse-down
#   sudo bash lab.sh recorder|recorder-down
#   sudo bash lab.sh down
#   sudo bash lab.sh exec 'COMMAND'   run COMMAND as ana, in ~/obs
#
# Langfuse needs Docker with Compose; everything else runs as processes.
# Recorded on Ubuntu 24.04 with Python 3.11, PostgreSQL 16 with pgvector,
# Docker 29.8 and Compose 5.6, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The daemons started
# here must not inherit it, or they hold it for as long as they live.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RAG_LAB=$HERE/../rag/lab.sh
EMB_SHARE=/opt/emb/share
VENV=/opt/llmobs
OBS=/home/ana/obs
PGSOCK=/run/emb-pg
LOGDIR=/var/log/labgen
OBSLIBS="numpy==2.4.6 onnxruntime==1.30.0 tokenizers==0.23.2 tiktoken==0.14.0
  psycopg[binary]==3.3.6 pgvector==0.3.6 openai==3.24.0 opentelemetry-sdk==1.45.0
  opentelemetry-exporter-otlp-proto-http==1.45.0 openinference-instrumentation-openai==0.1.63
  arize-phoenix==20.18.0 langfuse==4.17.0 langsmith==0.14.4 deepeval==4.2.8 ragas==0.3.1
  langchain-openai==1.6.7 pytest==9.1.1 prometheus-client==0.26.0"

# The environment every command of ana's runs in. The keys are the lab's and
# open nothing anywhere else.
ENVFILE=/etc/llmobs.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
TIKTOKEN_CACHE_DIR=$EMB_SHARE/tiktoken
MINILM_DIR=$EMB_SHARE/all-MiniLM-L6-v2
OPENAI_BASE_URL=http://127.0.0.1:8600/v1
OPENAI_API_KEY=lab-openai-key-0001
PGHOST=$PGSOCK
PGDATABASE=obs
PSEUDONYM_KEY=lab-pseudonym-key-0001
NO_PROXY=127.0.0.1,localhost
DEEPEVAL_TELEMETRY_OPT_OUT=YES
RAGAS_DO_NOT_TRACK=true
PHOENIX_TELEMETRY_ENABLED=false
EOF
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $OBSLIBS
  install_lab
}

install_lab() {
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/../embeddings-vectors/lab/minilm.py" "$HERE/../rag/lab/labgen.py" \
    "$HERE/lab/labobs.py" "$site/"
  install -d $VENV/share
  install -m 0644 "$HERE/../rag/lab/memory.json" $VENV/share/
}

# labobs takes rag's port: stop rag's labgen first, then start this one in
# its place, as the same user and with the same log.
start_labobs() {
  stop_labobs
  if [ -f /run/labgen.pid ]; then
    kill "$(cat /run/labgen.pid)" 2>/dev/null || true
    rm -f /run/labgen.pid
    sleep 0.3
  fi
  : > $LOGDIR/requests.jsonl; chown labgen:labgen $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  setsid runuser -u labgen -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=America/Sao_Paulo HOME=/tmp \
    MINILM_DIR=$EMB_SHARE/all-MiniLM-L6-v2 TIKTOKEN_CACHE_DIR=$EMB_SHARE/tiktoken \
    LABGEN_LOG=$LOGDIR LABGEN_MEMORY=$VENV/share/memory.json \
    $VENV/bin/python -m labobs > /run/labobs.out 2>&1 < /dev/null &
  echo $! > /run/labobs.pid
  for _ in $(seq 100); do
    curl -s http://127.0.0.1:8600/ 2>/dev/null | grep -q labobs && return 0
    sleep 0.2
  done
  echo "labobs did not start; see /run/labobs.out" >&2; return 1
}

stop_labobs() {
  if [ -f /run/labobs.pid ]; then
    kill "$(cat /run/labobs.pid)" 2>/dev/null || true
    rm -f /run/labobs.pid
    sleep 0.3
  fi
}

# ~/obs as it stands before lesson 1: the data, the prices and the releases.
build_obs() {
  rm -rf $OBS
  install -d -o ana -g ana $OBS $OBS/data $OBS/data/docs
  install -o ana -g ana -m 0644 "$HERE"/../rag/lab/data/docs/*.md $OBS/data/docs/
  install -o ana -g ana -m 0644 "$HERE"/../rag/lab/data/eval.jsonl $OBS/data/
  install -o ana -g ana -m 0644 "$HERE"/lab/prices.json "$HERE"/lab/releases.json $OBS/
  runuser -u ana -- python3 "$HERE/lab/traffic.py" $OBS/data/traffic.jsonl
}

# The `obs` database, with the documents chunked and embedded by rag's own
# programs, which then leave ~/obs: they are rag's lessons, not this course's.
reset_db() {
  runuser -u ana -- psql -h $PGSOCK -d postgres -qX -c 'SET client_min_messages = warning' \
    -c 'DROP DATABASE IF EXISTS obs' -c 'CREATE DATABASE obs'
  runuser -u ana -- psql -h $PGSOCK -d obs -qX -c 'CREATE EXTENSION vector'
  install -o ana -g ana -m 0644 "$HERE"/../rag/lab/code/chunking.py "$HERE"/../rag/lab/code/ingest.py $OBS/
  exec_as 'python ingest.py >/dev/null && rm -f chunking.py ingest.py'
}

start_phoenix() {
  stop_phoenix
  install -d -o ana -g ana /var/lib/phoenix
  setsid runuser -u ana -- env -i PATH=$VENV/bin:/usr/bin:/bin HOME=/home/ana TZ=America/Sao_Paulo \
    PHOENIX_WORKING_DIR=/var/lib/phoenix PHOENIX_HOST=127.0.0.1 PHOENIX_PORT=6006 \
    PHOENIX_TELEMETRY_ENABLED=false $VENV/bin/phoenix serve > /run/phoenix.out 2>&1 < /dev/null &
  echo $! > /run/phoenix.pid
  for _ in $(seq 150); do
    curl -s -o /dev/null http://127.0.0.1:6006/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "phoenix did not start; see /run/phoenix.out" >&2; return 1
}

stop_phoenix() {
  if [ -f /run/phoenix.pid ]; then
    kill "$(cat /run/phoenix.pid)" 2>/dev/null || true
    rm -f /run/phoenix.pid
    sleep 0.5
  fi
  rm -rf /var/lib/phoenix
}

# Langfuse, self-hosted: its web server and worker, and the four things they
# keep their state in. Started empty every time, with one project and its
# keys created at start-up from LANGFUSE_INIT_*, so no screen is clicked.
start_langfuse() {
  docker compose -p llmobs -f "$HERE/lab/langfuse/docker-compose.yml" down -v >/dev/null 2>&1 || true
  docker compose -p llmobs -f "$HERE/lab/langfuse/docker-compose.yml" up -d --quiet-pull >/dev/null 2>&1
  for _ in $(seq 180); do
    curl -s http://127.0.0.1:3000/api/public/health 2>/dev/null | grep -q OK && return 0
    sleep 1
  done
  echo "langfuse did not start: docker compose -p llmobs logs web" >&2; return 1
}

stop_langfuse() {
  docker compose -p llmobs -f "$HERE/lab/langfuse/docker-compose.yml" down -v >/dev/null 2>&1 || true
}

start_recorder() {
  stop_recorder
  install -d -o ana -g ana /var/lib/recorder
  setsid runuser -u ana -- env -i PATH=$VENV/bin:/usr/bin:/bin RECORDER_DIR=/var/lib/recorder \
    $VENV/bin/python "$HERE/lab/recorder.py" > /run/recorder.out 2>&1 < /dev/null &
  echo $! > /run/recorder.pid
  for _ in $(seq 50); do
    curl -s -o /dev/null http://127.0.0.1:8700/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "the recorder did not start; see /run/recorder.out" >&2; return 1
}

stop_recorder() {
  if [ -f /run/recorder.pid ]; then
    kill "$(cat /run/recorder.pid)" 2>/dev/null || true
    rm -f /run/recorder.pid
    sleep 0.3
  fi
}

exec_as() {  # exec_as COMMAND: as ana, in ~/obs, with the lab's environment and nothing else
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $OBS || exit 1; $*"
}

case ${1:-} in
  up)
    bash "$RAG_LAB" up
    write_env; build_venv; build_obs; start_labobs; reset_db ;;
  reset)
    bash "$RAG_LAB" reset >/dev/null
    write_env; install_lab; build_obs; start_labobs; reset_db ;;
  phoenix) start_phoenix ;;
  phoenix-down) stop_phoenix ;;
  langfuse) start_langfuse ;;
  langfuse-down) stop_langfuse ;;
  recorder) start_recorder ;;
  recorder-down) stop_recorder ;;
  down)
    stop_recorder; stop_phoenix; stop_langfuse; stop_labobs; bash "$RAG_LAB" down ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|phoenix|langfuse|recorder|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
