#!/usr/bin/env bash
# The machine every transcript in rag was recorded on.
#
# IT IS embeddings-vectors' MACHINE WITH ONE MORE ROOM. ana is still a developer
# at Marginalia, the online bookshop that does not exist, and that course left
# her with an embedding model, a stand-in provider and PostgreSQL with
# pgvector. This course builds on top of all three rather than beside them:
# `up` runs ../embeddings-vectors/lab.sh up first, and everything below it is
# what retrieval-augmented generation needs that embeddings did not.
#
#   /home/ana/rag          the working directory, rebuilt by `reset`
#   /home/ana/rag/data     what the lessons retrieve from and test against:
#     docs/*.md            thirteen of Marginalia's documents, 6,843 words:
#                          policies, terms, an API reference, and three that
#                          only some staff may read (lessons 1 to 17)
#     help.jsonl           embeddings-vectors' 40 help-centre articles,
#                          copied as they are
#     eval.jsonl           30 questions with the passages that answer them and
#                          the words a right answer contains, 4 of them with
#                          no answer in the documents (lessons 4 to 8)
#     chat-a.jsonl         twelve messages from one customer, and
#     chat-b.jsonl         four from another (lessons 13, 15 and 16)
#     listings.jsonl       six marketplace listings written by sellers, one of
#                          them carrying an instruction (lesson 16)
#     querylog.jsonl       500 questions over a week, drawn by lab/querylog.py
#                          (lesson 17)
#   /opt/rag               Python 3.11 in a virtual environment with the
#                          frameworks and SDKs the lessons import, pinned in
#                          RAGLIBS, and minilm.py from embeddings-vectors
#   /run/emb-pg            embeddings-vectors' PostgreSQL 16 with pgvector
#                          0.6.0; this course uses its own database, `rag`
#   127.0.0.1:8500         labembed, embeddings-vectors' stand-in provider
#   127.0.0.1:8600         labgen, this course's stand-in generator
#                          (lab/labgen.py), which also passes embedding
#                          requests on to labembed
#   /var/log/labgen        every request labgen received, one JSON line each
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real       all-MiniLM-L6-v2, the embedding model, run on this machine;
#              pgvector; tiktoken's cl100k_base encoding; and every library
#              the lessons import: the openai and anthropic SDKs, LangChain,
#              LlamaIndex, Haystack and rank-bm25, at the versions in RAGLIBS.
#              Every number a lesson prints from them was computed here.
#   the lab's  labgen. NO LANGUAGE MODEL WAS REACHABLE from this machine, and
#              an API key is a bill a course cannot hand out, so the SDKs talk
#              to labgen instead. It speaks OpenAI's and Anthropic's wire
#              formats, and the model behind it, extract-1, is not a language
#              model: it copies whole sentences out of the sources it is given,
#              chosen by their embedding similarity to the question, by rules
#              written at the top of lab/labgen.py. Every lesson that shows a
#              reply says it came from extract-1.
#   written    every file in data/, and lab/memory.json, the sentences
#              extract-1 answers from when it is given no sources. Marginalia
#              does not exist; marginalia.example is under the domain reserved
#              for examples, and every person and order number is invented.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: any provider's real API, Hugging Face
# (so no cross-encoder reranker: lesson 6 builds its reranker from the
# embedding model's own token vectors and says so), and RAGFlow, which is a
# server application of its own that lesson 11 describes and does not run.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/rag, empty the database, restart
#   sudo bash lab.sh down
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/rag
#
# Recorded on Ubuntu 24.04 with Python 3.11 and PostgreSQL 16,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The daemon started
# here must not inherit it, or it holds it for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EMB_LAB=$HERE/../embeddings-vectors/lab.sh
EMB_SHARE=/opt/emb/share
VENV=/opt/rag
RAG=/home/ana/rag
PGSOCK=/run/emb-pg
LOGDIR=/var/log/labgen
RAGLIBS="numpy==2.4.6 onnxruntime==1.30.0 tokenizers==0.23.2 tiktoken==0.14.0
  psycopg[binary]==3.3.6 pgvector==0.3.6 openai==2.54.0 anthropic==1.11.0 rank-bm25==0.2.2
  langchain-core==1.6.6 langchain-text-splitters==1.1.3 langchain-openai==1.6.7
  langchain-postgres==0.0.18 llama-index-core==0.14.25 llama-index-embeddings-openai==0.7.0
  llama-index-llms-openai==0.8.2 llama-index-llms-openai-like==0.8.1 haystack-ai==3.3.0"

# The environment every command of ana's runs in. The keys are the lab's and
# open nothing anywhere else; both base URLs point at labgen.
ENVFILE=/etc/rag.env
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
ANTHROPIC_BASE_URL=http://127.0.0.1:8600
ANTHROPIC_API_KEY=lab-anthropic-key-0001
HAYSTACK_TELEMETRY_ENABLED=False
ANONYMIZED_TELEMETRY=False
PGHOST=$PGSOCK
PGDATABASE=rag
EOF
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $RAGLIBS
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/../embeddings-vectors/lab/minilm.py" "$HERE/lab/labgen.py" "$site/"
  install -d $VENV/share
  install -m 0644 "$HERE/lab/memory.json" $VENV/share/
  id labgen >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin labgen
  mkdir -p $LOGDIR && chown labgen:labgen $LOGDIR && chmod 0755 $LOGDIR
}

start_labgen() {
  stop_labgen
  : > $LOGDIR/requests.jsonl; chown labgen:labgen $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  setsid runuser -u labgen -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=America/Sao_Paulo HOME=/tmp \
    MINILM_DIR=$EMB_SHARE/all-MiniLM-L6-v2 TIKTOKEN_CACHE_DIR=$EMB_SHARE/tiktoken \
    LABGEN_LOG=$LOGDIR LABGEN_MEMORY=$VENV/share/memory.json \
    $VENV/bin/python -m labgen > /run/labgen.out 2>&1 < /dev/null &
  echo $! > /run/labgen.pid
  for _ in $(seq 100); do
    curl -s -o /dev/null http://127.0.0.1:8600/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "labgen did not start; see /run/labgen.out" >&2; return 1
}

stop_labgen() {
  if [ -f /run/labgen.pid ]; then
    kill "$(cat /run/labgen.pid)" 2>/dev/null || true
    rm -f /run/labgen.pid
    sleep 0.3
  fi
}

# ~/rag as it stands before lesson 1: the data and nothing else.
build_rag() {
  rm -rf $RAG
  install -d -o ana -g ana $RAG $RAG/data $RAG/data/docs
  install -o ana -g ana -m 0644 "$HERE"/lab/data/docs/*.md $RAG/data/docs/
  install -o ana -g ana -m 0644 "$HERE"/lab/data/*.jsonl $RAG/data/
  install -o ana -g ana -m 0644 "$HERE"/../embeddings-vectors/lab/data/help.jsonl $RAG/data/
  runuser -u ana -- python3 "$HERE/lab/querylog.py" $RAG/data/querylog.jsonl
}

reset_db() {
  runuser -u ana -- psql -h $PGSOCK -d postgres -qX -c 'SET client_min_messages = warning' -c 'DROP DATABASE IF EXISTS rag' -c 'CREATE DATABASE rag'
  runuser -u ana -- psql -h $PGSOCK -d rag -qX -c 'CREATE EXTENSION vector'
}

exec_as() {  # exec_as COMMAND: as ana, in ~/rag, with the lab's environment and nothing else
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $RAG || exit 1; $*"
}

case ${1:-} in
  up)
    bash "$EMB_LAB" up
    write_env; build_venv; build_rag; reset_db; start_labgen ;;
  reset)
    bash "$EMB_LAB" reset >/dev/null
    build_rag; reset_db; start_labgen ;;
  down)
    stop_labgen; bash "$EMB_LAB" down ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
