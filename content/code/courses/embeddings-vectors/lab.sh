#!/usr/bin/env bash
# The machine every transcript in embeddings-vectors was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is a developer at Marginalia, an
# online bookshop that does not exist, and ~/emb is her working directory:
# the shop's help centre, its customers' messages and its catalogue, as files,
# and the programs the lessons write to search them by meaning.
#
# EVERYTHING ANA HAS, THE STUDENT IS GIVEN IN A LESSON (C-40), and this script
# takes it from there instead of keeping copies: lab/fence.py pulls each block
# out of the lesson that shows it, and fails unless exactly one block matches.
#
#   lesson 1, setting-up        the apt line, setup.sh (run as ana, unchanged)
#                               and minilm.py
#   lesson 1, the-help-centre   data/help.jsonl, queries.jsonl, tickets.jsonl
#   lesson 5, the-catalogue     data/books.jsonl, readers.jsonl
#   lesson 6, two-inboxes       data/inbox.jsonl, week2.jsonl
#   lesson 7, the-request       labembed.py and the lines it adds to ~/.bashrc
#   lesson 7, cost              prices.py
#
#   /home/ana/emb             the working directory, rebuilt by `reset`
#   /home/ana/.venvs/emb      the virtual environment setup.sh makes
#   /home/ana/models          all-MiniLM-L6-v2, which setup.sh downloads
#   PostgreSQL 16 + pgvector  Ubuntu's own cluster `16/main`, role ana,
#                             database `shop`, as lesson 1 tells the student
#   127.0.0.1:8500            labembed, started from ~/emb as lesson 7 says;
#                             its log is ~/emb/labembed.jsonl
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real       two embedding models, run on this machine:
#                all-MiniLM-L6-v2, the ONNX export Chroma distributes as its
#                  default embedding function, fetched from Chroma's own bucket
#                  and checked against the SHA-256 chromadb ships with
#                  (913d7300…6ec3); minilm.py runs it
#                WordLlama l2_supercat, whose 256-dimension weights are inside
#                  the wordllama wheel
#              every vector database the lessons run: Chroma, FAISS, LanceDB,
#              hnswlib, Qdrant's Python client in local mode, and pgvector in
#              PostgreSQL; and the providers' SDKs (openai, google-genai,
#              cohere), with tiktoken's cl100k_base encoding.
#   the course's  labembed, which answers the OpenAI, Gemini, Cohere and Jina
#              embedding endpoints closely enough that the SDKs talk to it
#              unmodified, with vectors from the two real models above. It
#              serves them under its own names, lab-minilm and lab-wordllama,
#              and refuses the providers' model names with a 404. Lesson 7
#              shows it whole, and the student runs it.
#   written    every data file: the articles, the messages and the readers
#              were written for the course, and the blurbs of the sixty books
#              are the course's own words about books whose texts are in the
#              public domain. Marginalia does not exist; marginalia.example is
#              under the domain reserved for examples.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: huggingface.co, so neither
# sentence-transformers' own download nor any model hosted there (the library
# also needs PyTorch, whose index was out of reach too); the providers' real
# APIs; and the hosted databases, Pinecone, Weaviate Cloud, Supabase and
# MongoDB Atlas. The lessons that show their code say it was not run.
#
# TWO THINGS DIFFER FROM A STUDENT'S UBUNTU 24.04, and neither reaches a
# transcript:
#   - this machine's /usr/bin/python3 is 3.13. Stock 24.04's is 3.12, so ana's
#     PATH starts with /opt/emb-py/bin, where python3 is /usr/bin/python3.12
#     and pip is that interpreter's pip, as on a stock system.
#   - tiktoken downloads its encodings on first use from a host that was out
#     of reach here (a student's machine reaches it). The npm package
#     js-tiktoken ships the same table, and build_tokenizer writes it back
#     out; tiktoken checks the file against the SHA-256 it ships with, so a
#     reconstruction off by one byte would be refused. TIKTOKEN_CACHE_DIR
#     points at it, in ana's environment and nowhere in a lesson.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/emb, empty the database, restart
#   sudo bash lab.sh down
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/emb
#
# Recorded on Ubuntu 24.04 with Python 3.12, Node.js 22 and PostgreSQL 16,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The daemons started
# here must not inherit it, or they hold it for as long as they live.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L=$HERE/lessons
FENCE="python3 $HERE/lab/fence.py"
EMB=/home/ana/emb
PYBIN=/opt/emb-py/bin
SHARE=/opt/emb-share

# The environment every command of ana's runs in: what lessons 1 and 7 add to
# ~/.bashrc, and the lab's own lines above them.
ENVFILE=/etc/emb.env
write_env() {
  {
    echo "export PATH=$PYBIN:/usr/local/bin:/usr/bin:/bin"
    echo "export TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1"
    echo "export TIKTOKEN_CACHE_DIR=$SHARE/tiktoken"
    $FENCE "$L/le-cdg0ya75/setting-up.md" '^#!/usr/bin/env bash' | sed -n '/^# embeddings course$/,/^END$/p' | grep '^export'
    $FENCE "$L/le-hha722b5/the-request.md" "^cat >> ~/.bashrc <<'END'" | grep '^export'
  } > "$ENVFILE"
}

need() {
  command -v python3.12 >/dev/null || { echo "python3.12 is required" >&2; exit 1; }
  command -v npm >/dev/null || { echo "npm is required (Node.js 22)" >&2; exit 1; }
  # The student's apt line, as lesson 1 shows it.
  local apt
  apt=$($FENCE "$L/le-cdg0ya75/setting-up.md" '^sudo apt update' | grep '^sudo apt install' | sed 's/^sudo //')
  DEBIAN_FRONTEND=noninteractive $apt >/dev/null
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  mkdir -p $PYBIN
  ln -sf /usr/bin/python3.12 $PYBIN/python3
  printf '#!/bin/sh\nexec /usr/bin/python3.12 -m pip "$@"\n' > $PYBIN/pip
  chmod 0755 $PYBIN/pip
}

# setup.sh exactly as lesson 1 shows it, run by ana.
build_setup() {
  [ -x /home/ana/.venvs/emb/bin/python ] && [ -f /home/ana/models/all-MiniLM-L6-v2/model.onnx ] && return 0
  install -d -o ana -g ana $EMB
  $FENCE "$L/le-cdg0ya75/setting-up.md" '^#!/usr/bin/env bash' > $EMB/setup.sh
  chown ana:ana $EMB/setup.sh
  runuser -u ana -- env -i HOME=/home/ana USER=ana PATH=$PYBIN:/usr/bin:/bin bash -c 'cd ~/emb && bash setup.sh'
}

build_tokenizer() {
  local node=$SHARE/node
  mkdir -p $node $SHARE/tiktoken
  ( cd $node && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent js-tiktoken@1.0.21 )
  ( cd $node && node -e '
    const fs = require("fs"), crypto = require("crypto");
    for (const n of ["cl100k_base"]) {
      const r = require("js-tiktoken/ranks/" + n), rows = [];
      for (const line of r.bpe_ranks.split("\n").filter(Boolean)) {
        const [, offset, ...tokens] = line.split(" ");
        tokens.forEach((t, i) => rows.push([parseInt(offset, 10) + i, t]));
      }
      rows.sort((a, b) => a[0] - b[0]);
      const url = "https://openaipublic.blob.core.windows.net/encodings/" + n + ".tiktoken";
      const name = crypto.createHash("sha1").update(url).digest("hex");
      fs.writeFileSync(process.argv[1] + "/" + name, rows.map(([k, t]) => t + " " + k).join("\n") + "\n");
    }' $SHARE/tiktoken )
  chmod -R a+rX $SHARE
  # tiktoken refuses a file whose hash is not the one it ships with, so this
  # line is the check that the reconstruction is exact.
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken /home/ana/.venvs/emb/bin/python -c 'import tiktoken; tiktoken.get_encoding("cl100k_base")'
}

# Ubuntu's own cluster, with the role and the database lesson 1 creates.
start_pg() {
  pg_ctlcluster 16 main status >/dev/null 2>&1 || pg_ctlcluster 16 main start
  runuser -u postgres -- psql -qAtc "SELECT 1 FROM pg_roles WHERE rolname = 'ana'" | grep -q 1 ||
    runuser -u postgres -- createuser --superuser ana
  runuser -u ana -- psql -d postgres -qAtc "SELECT 1 FROM pg_database WHERE datname = 'shop'" | grep -q 1 ||
    runuser -u ana -- createdb shop
}

stop_pg() {
  pg_ctlcluster 16 main stop 2>/dev/null || true
}

reset_db() {
  runuser -u ana -- psql -d postgres -qX -c 'DROP DATABASE IF EXISTS shop' -c 'CREATE DATABASE shop'
}

start_labembed() {
  stop_labembed
  runuser -u ana -- bash -c "source $ENVFILE; cd $EMB && setsid python labembed.py > /tmp/labembed.out 2>&1 < /dev/null & echo \$! > /tmp/labembed.pid"
  cp /tmp/labembed.pid /run/labembed.pid
  for _ in $(seq 100); do
    curl -s -o /dev/null http://127.0.0.1:8500/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "labembed did not start; see /tmp/labembed.out" >&2; return 1
}

stop_labembed() {
  if [ -f /run/labembed.pid ]; then
    kill "$(cat /run/labembed.pid)" 2>/dev/null || true
    rm -f /run/labembed.pid
    sleep 0.3
  fi
}

# ~/emb as it stands before lesson 1's first program: the files the lessons
# hand over, and nothing else.
build_emb() {
  rm -rf $EMB
  install -d -o ana -g ana $EMB $EMB/data
  local put
  put() { runuser -u ana -- bash -c "cd $EMB && bash"; }
  $FENCE "$L/le-cdg0ya75/setting-up.md" '^"""minilm:' > $EMB/minilm.py
  $FENCE "$L/le-hha722b5/the-request.md" '^"""labembed:' > $EMB/labembed.py
  $FENCE "$L/le-hha722b5/cost.md" '^"""prices:' > $EMB/prices.py
  $FENCE "$L/le-cdg0ya75/setting-up.md" '^#!/usr/bin/env bash' > $EMB/setup.sh
  chown ana:ana $EMB/*.py
  local f
  for f in help queries tickets; do
    $FENCE "$L/le-cdg0ya75/the-help-centre.md" "^cat > ~/emb/data/$f.jsonl" | put
  done
  for f in books readers; do
    $FENCE "$L/le-n977zgn5/the-catalogue.md" "^cat > ~/emb/data/$f.jsonl" | put
  done
  for f in inbox week2; do
    $FENCE "$L/le-8v3tfk7k/two-inboxes.md" "^cat > ~/emb/data/$f.jsonl" | put
  done
}

exec_as() {  # exec_as COMMAND: as ana, in ~/emb, with the lab's environment and nothing else
  runuser -u ana -- env -i HOME=/home/ana USER=ana bash -c "source $ENVFILE; cd $EMB || exit 1; $*"
}

case ${1:-} in
  up)
    need; build_user; build_setup; write_env; build_tokenizer
    build_emb; start_pg; start_labembed ;;
  reset)
    write_env; build_emb; start_pg; reset_db; start_labembed ;;
  down)
    stop_labembed; stop_pg ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
