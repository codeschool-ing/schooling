#!/usr/bin/env bash
# The machine every transcript in rag was recorded on. THE AUTHOR'S, NOT THE
# STUDENT'S: the student never receives this file. Lesson 1 teaches them to
# build the same machine with the same commands, and everything this script
# installs or writes is either one of those commands or a file a lesson shows.
#
# WHAT IT IS. An Ubuntu 24.04 machine with:
#   Ollama, serving llama3.2:3b (the generator) and all-minilm (the embedding
#     model, all-MiniLM-L6-v2) on 127.0.0.1:11434, which speaks OpenAI's and
#     Anthropic's wire formats as well as its own
#   PostgreSQL 16 with pgvector 0.6.0, from Ubuntu's own packages, and a
#     database called rag
#   ~/rag, the student's working directory: a Python 3.12 virtual environment
#     in ~/rag/.venv with the libraries of lesson 1's requirements.txt, and
#     env.sh, which lesson 1 shows
#
# THE STUDENT IS ana, on a machine called vm, and the prompt every capture
# prints says so. This script runs as root and runs ana's commands as root
# with HOME=/home/ana: the capture machine had no account to give her.
#
# NOTHING THE LESSONS USE IS COPIED IN FROM HERE. lab/shown.py prints a file
# exactly as the lessons show it, and both `reset` and every captures.sh take
# their programs and their data from it. If a lesson changes a program, the
# next capture runs the changed one.
#
# TIKTOKEN. tiktoken downloads cl100k_base on first use from
# openaipublic.blob.core.windows.net, which the capture machine's network
# refused. The npm package js-tiktoken ships the same table; build_tokenizer
# writes it back out and tiktoken checks it against the SHA-256 it ships with,
# so the file is the one a student's machine downloads.
#
#   sudo bash lab.sh up                 build it (idempotent)
#   sudo bash lab.sh reset LESSON_ID    ~/rag as it stands before that lesson
#   sudo bash lab.sh exec 'COMMAND'     run COMMAND as ana, in ~/rag
#
# Recorded on Ubuntu 24.04 with Python 3.12, PostgreSQL 16, Ollama 0.40.0,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The daemon started
# here must not inherit it, or it holds it for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SHOWN="python3 $HERE/lab/shown.py $HERE"
RAG=/home/ana/rag
SHARE=/opt/rag-share
# Data a lesson gives the student as a script, in the order the lessons give it.
DATA="docs.sh help.sh questions.sh chats.sh listings.sh querylog.py"

ollama_up() {
  curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
  # No systemd on the capture machine, so nothing started the service the
  # installer created. On the student's machine systemd does.
  setsid nohup ollama serve > /var/log/ollama.log 2>&1 < /dev/null &
  for _ in $(seq 100); do
    curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
    sleep 0.2
  done
  echo "ollama did not start; see /var/log/ollama.log" >&2; return 1
}

pg_up() {
  pg_lsclusters -h | grep -q '^16 main .* online' || pg_ctlcluster 16 main start
  # ana has no account on the capture machine, so peer authentication cannot
  # recognise her; the student's own login is her role, and peer works.
  local hba=/etc/postgresql/16/main/pg_hba.conf
  grep -q '^local all ana trust' $hba || { sed -i '1i local all ana trust' $hba; pg_ctlcluster 16 main reload; }
}

build_tokenizer() {
  local node=$SHARE/node
  mkdir -p $node $SHARE/tiktoken
  ( cd $node && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent js-tiktoken@1.0.21 )
  ( cd $node && node -e '
    const fs = require("fs"), crypto = require("crypto");
    const r = require("js-tiktoken/ranks/cl100k_base"), rows = [];
    for (const line of r.bpe_ranks.split("\n").filter(Boolean)) {
      const [, offset, ...tokens] = line.split(" ");
      tokens.forEach((t, i) => rows.push([parseInt(offset, 10) + i, t]));
    }
    rows.sort((a, b) => a[0] - b[0]);
    const url = "https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken";
    const name = crypto.createHash("sha1").update(url).digest("hex");
    fs.writeFileSync(process.argv[1] + "/" + name, rows.map(([k, t]) => t + " " + k).join("\n") + "\n");
    ' $SHARE/tiktoken )
  # tiktoken refuses a file whose hash is not the one it ships with, so this
  # line is the check that the reconstruction is exact.
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $RAG/.venv/bin/python -c 'import tiktoken; tiktoken.get_encoding("cl100k_base")'
}

up() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q zstd python3-venv postgresql-16 postgresql-16-pgvector >/dev/null
  command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
  ollama_up
  ollama pull llama3.2:3b >/dev/null
  ollama pull all-minilm >/dev/null
  pg_up
  su postgres -c "psql -qXtc \"SELECT 1 FROM pg_roles WHERE rolname = 'ana'\"" | grep -q 1 \
    || su postgres -c 'createuser --superuser ana'
  mkdir -p $RAG
  [ -x $RAG/.venv/bin/python ] || python3.12 -m venv $RAG/.venv
  $SHOWN requirements.txt > $RAG/requirements.txt
  $RAG/.venv/bin/pip install -q -r $RAG/requirements.txt
  $SHOWN env.sh > $RAG/env.sh
  build_tokenizer
}

# ~/rag before LESSON: the setup of lesson 1, and the data every earlier lesson
# gave the student. The lesson that gives a data script runs it in its own
# captures, where the student sees it run.
reset() {
  local lesson=$1 l name
  ollama_up; pg_up
  find $RAG -mindepth 1 -maxdepth 1 ! -name .venv ! -name env.sh ! -name requirements.txt -exec rm -rf {} +
  psql -U ana -d postgres -qX -c 'SET client_min_messages = warning' -c 'DROP DATABASE IF EXISTS rag' -c 'CREATE DATABASE rag'
  psql -U ana -d rag -qX -c 'CREATE EXTENSION vector'
  for l in $(python3 -c "import json; print(' '.join(json.load(open('$HERE/course.json'))['lessons']))"); do
    [ "$l" = "$lesson" ] && break
    for name in $DATA; do
      $SHOWN "$name" "$l" > /tmp/rag-data.$$ 2>/dev/null || continue
      install -m 0644 /tmp/rag-data.$$ "$RAG/$name"
      exec_as "$( [ "${name##*.}" = py ] && echo python || echo sh ) $name" >/dev/null
    done
  done
  rm -f /tmp/rag-data.$$
}

exec_as() {  # exec_as COMMAND: as ana, in ~/rag, with env.sh and nothing else
  env -i HOME=/home/ana USER=ana LOGNAME=ana PATH=/usr/local/bin:/usr/bin:/bin \
    TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1 \
    TIKTOKEN_CACHE_DIR=$SHARE/tiktoken PGUSER=ana HAYSTACK_TELEMETRY_ENABLED=False \
    bash -c "cd $RAG || exit 1; . ./env.sh; $*"
}

case ${1:-} in
  up) up ;;
  reset) reset "${2:?which lesson}" ;;
  exec) shift; exec_as "$@" ;;
  *) echo "usage: sudo bash lab.sh up|reset LESSON_ID|exec 'COMMAND'" >&2; exit 2 ;;
esac
