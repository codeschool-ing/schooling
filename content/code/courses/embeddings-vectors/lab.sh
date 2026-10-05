#!/usr/bin/env bash
# The machine every transcript in embeddings-vectors was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is a developer at Marginalia, an
# online bookshop that does not exist, and ~/emb is her working directory:
# the shop's help centre, its customers' messages and its catalogue, as files,
# and the programs the lessons write to search them by meaning.
#
#   /home/ana/emb          the working directory, rebuilt by `reset`
#   /home/ana/emb/data     what the lessons search, classify and recommend:
#     help.jsonl           40 help-centre articles, 37 in English and 3 in
#                          Portuguese, each with a category, a language and a
#                          date (lessons 3, 9, 11 to 18)
#     queries.jsonl        24 questions a customer might type, each with the
#                          article that answers it, decided by the course
#     tickets.jsonl        150 customer messages labelled with one of five
#                          categories, 100 to learn from and 50 to test on
#                          (lesson 4)
#     inbox.jsonl          one day's 40 messages, 8 of which do not belong
#                          (lesson 6)
#     week2.jsonl          20 messages from the week a subscription launched
#                          (lesson 6)
#     books.jsonl          60 public-domain books with a blurb each
#     readers.jsonl        12 readers and the books they finished (lesson 5)
#   /opt/emb               Python 3.11 in a virtual environment, with every
#                          library the lessons import, pinned in PYLIBS
#   /opt/emb/share         the two embedding models' files
#   /run/emb-pg            PostgreSQL 16 with pgvector 0.6.0: database `shop`,
#                          role ana (lessons 14, 17 and 18)
#   127.0.0.1:8500         labembed, the stand-in provider (lab/labembed.py)
#   /var/log/labembed      every request labembed received, one JSON line each
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real       two embedding models, run on this machine:
#                all-MiniLM-L6-v2, the ONNX export Chroma distributes as its
#                  default embedding function, fetched from Chroma's own bucket
#                  and checked against the SHA-256 chromadb ships with
#                  (913d7300…6ec3); lab/minilm.py runs it
#                WordLlama l2_supercat, whose 256-dimension weights are inside
#                  the wordllama wheel
#              every vector database the lessons run: Chroma, FAISS, LanceDB,
#              hnswlib, Qdrant's Python client in local mode, and pgvector in
#              PostgreSQL; and the providers' SDKs (openai, google-genai,
#              cohere), with tiktoken's cl100k_base encoding.
#   the lab's  labembed, which answers the OpenAI, Gemini, Cohere and Jina
#              embedding endpoints closely enough that the SDKs talk to it
#              unmodified, with vectors from the two real models above. It
#              serves them under its own names, lab-minilm and lab-wordllama,
#              and refuses the providers' model names with a 404.
#   written    every file in data/: the articles, the messages and the readers
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
# tiktoken downloads its encodings on first use from a host that was out of
# reach. The npm package js-tiktoken ships the same table, and build_tokenizer
# writes it back out; tiktoken checks the file against the SHA-256 it ships
# with, so a reconstruction off by one byte would be refused.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/emb, empty the database, restart
#   sudo bash lab.sh down
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/emb
#
# Recorded on Ubuntu 24.04 with Python 3.11, Node.js 22 and PostgreSQL 16,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The daemons started
# here must not inherit it, or they hold it for as long as they live.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=/opt/emb
SHARE=$VENV/share
EMB=/home/ana/emb
PGDATA=/var/lib/emb-pg
PGSOCK=/run/emb-pg
LOGDIR=/var/log/labembed
PYLIBS="numpy==2.4.6 onnxruntime==1.30.0 tokenizers==0.23.2 wordllama==0.4.0.post1
  chromadb==1.5.9 faiss-cpu==1.15.1 lancedb==0.39.0 pyarrow==25.0.1 qdrant-client==1.19.1
  hnswlib==0.8.0 scikit-learn==1.9.1 psycopg[binary]==3.3.6 pgvector==0.5.0
  openai==3.24.0 google-genai==2.28.0 cohere==7.2.0 tiktoken==0.14.0"
MINILM_URL=https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz
MINILM_SHA256=913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3

# The environment every command of ana's runs in. The keys are the lab's and
# open nothing anywhere else; the base URLs point each SDK at labembed.
ENVFILE=/etc/emb.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
TIKTOKEN_CACHE_DIR=$SHARE/tiktoken
MINILM_DIR=$SHARE/all-MiniLM-L6-v2
OPENAI_BASE_URL=http://127.0.0.1:8500/v1
OPENAI_API_KEY=lab-openai-key-0001
GEMINI_BASE_URL=http://127.0.0.1:8500
GEMINI_API_KEY=lab-google-key-0001
CO_API_URL=http://127.0.0.1:8500
CO_API_KEY=lab-cohere-key-0001
JINA_BASE_URL=http://127.0.0.1:8500/v1
JINA_API_KEY=lab-jina-key-0001
PGHOST=$PGSOCK
PGDATABASE=shop
EOF
}

need() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  command -v npm >/dev/null || { echo "npm is required (Node.js 22)" >&2; exit 1; }
  [ -x /usr/lib/postgresql/16/bin/initdb ] && [ -f /usr/share/postgresql/16/extension/vector.control ] || {
    echo "PostgreSQL 16 and pgvector are required: apt-get install postgresql-16 postgresql-16-pgvector" >&2
    exit 1; }
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  id labembed >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin labembed
  mkdir -p $LOGDIR && chown labembed:labembed $LOGDIR && chmod 0755 $LOGDIR
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $PYLIBS
  mkdir -p $SHARE
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/lab/minilm.py" "$HERE/lab/labembed.py" "$site/"
}

build_models() {
  if [ ! -f $SHARE/all-MiniLM-L6-v2/model.onnx ]; then
    local t
    t=$(mktemp -d)
    curl -sSf -o "$t/onnx.tar.gz" $MINILM_URL
    echo "$MINILM_SHA256  $t/onnx.tar.gz" | sha256sum -c --quiet
    tar -xzf "$t/onnx.tar.gz" -C "$t"
    rm -rf $SHARE/all-MiniLM-L6-v2
    mv "$t/onnx" $SHARE/all-MiniLM-L6-v2
    chmod -R a+rX $SHARE/all-MiniLM-L6-v2
    rm -rf "$t"
  fi
  # WordLlama carries its tokenizer in the wheel and then looks for it in a
  # directory it does not install it in. Copy it to where a download would go,
  # for both users who load the model.
  local pkg u
  pkg=$($VENV/bin/python -c 'import wordllama, os; print(os.path.dirname(wordllama.__file__))')
  for u in ana labembed; do
    local home
    home=$(getent passwd $u | cut -d: -f6)
    [ "$u" = labembed ] && home=$SHARE/labembed-home
    mkdir -p "$home/.cache/wordllama/tokenizers"
    install -m 0644 "$pkg/tokenizers/l2_supercat_tokenizer_config.json" "$home/.cache/wordllama/tokenizers/"
    chown -R $u "$home/.cache"
  done
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
  chmod -R a+rX $SHARE/tiktoken
  # tiktoken refuses a file whose hash is not the one it ships with, so this
  # line is the check that the reconstruction is exact.
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $VENV/bin/python -c 'import tiktoken; tiktoken.get_encoding("cl100k_base")'
}

build_pg() {
  if [ ! -f $PGDATA/PG_VERSION ]; then
    mkdir -p $PGDATA && chown ana:ana $PGDATA
    runuser -u ana -- /usr/lib/postgresql/16/bin/initdb -D $PGDATA -U ana --auth=trust \
      --locale=C.UTF-8 --encoding=UTF8 >/dev/null
  fi
  mkdir -p $PGSOCK && chown ana:ana $PGSOCK
}

start_pg() {
  stop_pg
  mkdir -p $PGSOCK && chown ana:ana $PGSOCK
  runuser -u ana -- env TZ=America/Sao_Paulo /usr/lib/postgresql/16/bin/pg_ctl -D $PGDATA -s -w \
    -o "-k $PGSOCK -c listen_addresses='' -c timezone=America/Sao_Paulo" -l $PGDATA/server.log start
  runuser -u ana -- psql -h $PGSOCK -d postgres -qAt -c "SELECT 1 FROM pg_database WHERE datname = 'shop'" | grep -q 1 ||
    runuser -u ana -- createdb -h $PGSOCK shop
}

stop_pg() {
  [ -f $PGDATA/postmaster.pid ] && runuser -u ana -- /usr/lib/postgresql/16/bin/pg_ctl -D $PGDATA -s -m fast stop || true
}

start_labembed() {
  stop_labembed
  : > $LOGDIR/requests.jsonl; chown labembed:labembed $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  setsid runuser -u labembed -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=America/Sao_Paulo \
    HOME=$SHARE/labembed-home MINILM_DIR=$SHARE/all-MiniLM-L6-v2 LABEMBED_LOG=$LOGDIR \
    $VENV/bin/python -m labembed > /run/labembed.out 2>&1 < /dev/null &
  echo $! > /run/labembed.pid
  for _ in $(seq 100); do
    curl -s -o /dev/null http://127.0.0.1:8500/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "labembed did not start; see /run/labembed.out" >&2; return 1
}

stop_labembed() {
  if [ -f /run/labembed.pid ]; then
    kill "$(cat /run/labembed.pid)" 2>/dev/null || true
    rm -f /run/labembed.pid
    sleep 0.3
  fi
}

# ~/emb as it stands before lesson 1: the data and nothing else.
build_emb() {
  rm -rf $EMB
  install -d -o ana -g ana $EMB $EMB/data
  install -o ana -g ana -m 0644 "$HERE"/lab/data/*.jsonl $EMB/data/
}

reset_db() {
  runuser -u ana -- psql -h $PGSOCK -d postgres -qX -c 'DROP DATABASE IF EXISTS shop' -c 'CREATE DATABASE shop'
}

exec_as() {  # exec_as COMMAND: as ana, in ~/emb, with the lab's environment and nothing else
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $EMB || exit 1; $*"
}

case ${1:-} in
  up)
    need; build_user; write_env; build_venv; build_models; build_tokenizer; build_pg
    build_emb; start_pg; start_labembed ;;
  reset)
    build_emb; start_pg; reset_db; start_labembed ;;
  down)
    stop_labembed; stop_pg ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
