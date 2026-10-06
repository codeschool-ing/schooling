#!/usr/bin/env bash
# The machine every transcript in agents-mcp was recorded on.
#
# ONE LINUX COMPUTER, ONE PERSON AND ONE SMALL NETWORK. ana is a developer at
# Marginalia, the online bookshop embeddings-vectors searched by meaning, and
# this course is her building its support agent: the tools it calls, the loop
# that runs them, the agent SDKs, and the MCP servers that hand the tools over.
#
#   /home/ana/agents        the working directory, rebuilt by `reset`
#     data/help.jsonl       Marginalia's 40 help-centre articles, and
#     data/books.jsonl      its 60 books: both are embeddings-vectors' files,
#                           copied from ../embeddings-vectors/lab/data
#     data/shop.db          the orders the agent looks up and refunds, in
#                           SQLite, built from lab/data/shop.sql
#     shop.py               those three files as plain Python functions
#                           (lab/work/shop.py), which every lesson's tools wrap
#   /opt/agents             Python 3.11 in a virtual environment, with every
#                           library the lessons import, pinned in PYLIBS
#   /opt/agents/share       the o200k_base encoding, all-MiniLM-L6-v2, and
#                           the stand-in model's rules (lab/scripted/*.json)
#   127.0.0.1:8600          labllm, the stand-in model provider (lab/labllm.py)
#   /var/log/labllm         every request labllm received, one JSON line each
#   203.0.113.10            "remote", a network namespace that plays a second
#                           machine for the remote MCP server of lesson 16
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real       the providers' SDKs (anthropic, openai, google-genai), the three
#              agent SDKs (openai-agents, claude-agent-sdk with the Claude Code
#              CLI it bundles, google-adk), the MCP SDK (mcp), jsonschema and
#              pytest; all-MiniLM-L6-v2, the embedding model embeddings-vectors
#              runs, behind the help-centre search; SQLite.
#   the lab's  labllm, which speaks the wire format of the Anthropic, OpenAI
#              and Gemini APIs, tool calls included, closely enough that every
#              SDK above talks to it unmodified. It has no model in it: what
#              its two models say, including which tool they call and with
#              which arguments, is chosen by rules WRITTEN BY THE COURSE in
#              lab/scripted/. Every lesson that shows such a reply says so.
#   written    data/shop.sql, and the help articles and books, which
#              embeddings-vectors wrote. Marginalia does not exist.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: every provider's real API, and the
# hosted products (OpenAI's Agent Builder and ChatKit, Vertex AI Agent Builder
# and Agent Engine). The lessons that show their code say it was not run.
#
# Two things are REBUILT rather than downloaded, because their usual source
# was out of reach. o200k_base, the encoding labllm counts tokens with, is
# rebuilt from the npm package js-tiktoken exactly as ai-dev's lab does it, and
# tiktoken refuses the file unless its SHA-256 is the one tiktoken ships with.
# all-MiniLM-L6-v2 is fetched from Chroma's bucket, as embeddings-vectors does,
# and checked against the same SHA-256.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/agents and restart labllm
#   sudo bash lab.sh remote          deploy ~/agents/remote_mcp.py to "remote"
#                                    and start it there (lesson 16)
#   sudo bash lab.sh down
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/agents
#
# The lab's calendar stops on 6 October 2026: LAB_TODAY, which shop.py reads,
# so an order's age and a return window come out the same on every run.
#
# Recorded on Ubuntu 24.04 with Python 3.11 and Node.js 22, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The daemons started
# here must not inherit it, or they hold it for as long as they live.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EMBLAB=$HERE/../embeddings-vectors/lab
VENV=/opt/agents
SHARE=$VENV/share
WORK=/home/ana/agents
LOGDIR=/var/log/labllm
REMOTE=/srv/mcp                 # the second machine's files, owned by mcpd
REMOTE_TLS=/etc/agents-remote   # the lab's certificate authority and the server's key
PYLIBS="anthropic==1.11.0 openai==3.24.0 google-genai==2.28.0 mcp==2.3.0
  openai-agents==0.23.1 claude-agent-sdk==0.2.163 google-adk==2.11.0
  jsonschema==4.26.0 tiktoken==0.14.0 numpy==2.4.6 onnxruntime==1.30.0
  tokenizers==0.23.2 pytest==9.1.1 uvicorn==0.54.0"
MINILM_URL=https://chroma-onnx-models.s3.amazonaws.com/all-MiniLM-L6-v2/onnx.tar.gz
MINILM_SHA256=913d7300ceae3b2dbc2c50d1de4baacab4be7b9380491c27fab7418616a16ec3

# The environment every command of ana's runs in. The keys are the lab's and
# open nothing anywhere else; the base URLs are what point each SDK at labllm.
ENVFILE=/etc/agents.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
LAB_TODAY=2026-10-06
TIKTOKEN_CACHE_DIR=$SHARE/tiktoken
MINILM_DIR=$SHARE/all-MiniLM-L6-v2
ANTHROPIC_BASE_URL=http://127.0.0.1:8600
ANTHROPIC_API_KEY=lab-anthropic-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8600/v1
OPENAI_API_KEY=lab-openai-key-0001
GEMINI_API_KEY=lab-google-key-0001
EOF
}

need() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  command -v npm >/dev/null || { echo "npm is required (Node.js 22)" >&2; exit 1; }
  command -v ip >/dev/null || { echo "ip is required: apt-get install iproute2" >&2; exit 1; }
  command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }
  [ -f "$EMBLAB/minilm.py" ] || { echo "embeddings-vectors' lab is required beside this course" >&2; exit 1; }
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  id labllm >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin labllm
  id mcpd >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d $REMOTE mcpd
  mkdir -p $LOGDIR && chown labllm:labllm $LOGDIR && chmod 0755 $LOGDIR
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $PYLIBS
  mkdir -p $SHARE
  install_lab
}

# The lab's own programs: labllm and its rules, and the embedding model's runner.
install_lab() {
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/lab/labllm.py" "$EMBLAB/minilm.py" "$site/"
  rm -rf $SHARE/scripted && mkdir -p $SHARE/scripted
  install -m 0644 "$HERE"/lab/scripted/*.json $SHARE/scripted/
}

build_tokenizer() {
  local node=$SHARE/node
  mkdir -p $node $SHARE/tiktoken
  ( cd $node && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent js-tiktoken@1.0.21 )
  ( cd $node && node -e '
    const fs = require("fs"), crypto = require("crypto");
    for (const n of ["o200k_base"]) {
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
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $VENV/bin/python -c 'import tiktoken; tiktoken.get_encoding("o200k_base")'
}

build_model() {
  [ -f $SHARE/all-MiniLM-L6-v2/model.onnx ] && return 0
  local t
  t=$(mktemp -d)
  curl -sSf -o "$t/onnx.tar.gz" $MINILM_URL
  echo "$MINILM_SHA256  $t/onnx.tar.gz" | sha256sum -c --quiet
  tar -xzf "$t/onnx.tar.gz" -C "$t"
  rm -rf $SHARE/all-MiniLM-L6-v2
  mv "$t/onnx" $SHARE/all-MiniLM-L6-v2
  chmod -R a+rX $SHARE/all-MiniLM-L6-v2
  rm -rf "$t"
}

# ~/agents as it stands before lesson 1: the data and nothing else.
build_work() {
  rm -rf $WORK
  install -d -o ana -g ana $WORK $WORK/data
  install -o ana -g ana -m 0644 "$EMBLAB/data/help.jsonl" "$EMBLAB/data/books.jsonl" $WORK/data/
  install -o ana -g ana -m 0644 "$HERE/lab/work/shop.py" $WORK/
  runuser -u ana -- $VENV/bin/python -c "
import sqlite3, sys
db = sqlite3.connect('$WORK/data/shop.db')
db.executescript(open(sys.argv[1]).read())
db.commit()" "$HERE/lab/data/shop.sql"
}

start_llm() {
  stop_llm
  : > $LOGDIR/requests.jsonl; chown labllm:labllm $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  setsid runuser -u labllm -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=America/Sao_Paulo \
    TIKTOKEN_CACHE_DIR=$SHARE/tiktoken LABLLM_SHARE=$SHARE LABLLM_LOG=$LOGDIR \
    $VENV/bin/python -m labllm > /run/labllm.out 2>&1 < /dev/null &
  echo $! > /run/labllm.pid
  for _ in $(seq 50); do
    curl -s -o /dev/null http://127.0.0.1:8600/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "labllm did not start; see /run/labllm.out" >&2; return 1
}

stop_llm() {
  if [ -f /run/labllm.pid ]; then
    kill "$(cat /run/labllm.pid)" 2>/dev/null || true
    rm -f /run/labllm.pid
    sleep 0.3
  fi
}

# "remote": a network namespace standing in for a second machine, reached at
# 203.0.113.10 (a documentation address, RFC 5737) under two names, with a
# certificate authority of the lab's own. ana's machine trusts that CA through
# one file, $SHARE/marginalia-ca.crt, which the lesson passes to its client:
# nothing here turns TLS verification off.
build_remote() {
  ip netns list | grep -qw remote || ip netns add remote
  ip link show mcp0 >/dev/null 2>&1 || { ip link add mcp0 type veth peer name mcp1; ip link set mcp1 netns remote; }
  ip addr show mcp0 | grep -q 203.0.113.1/24 || ip addr add 203.0.113.1/24 dev mcp0
  ip link set mcp0 up
  ip netns exec remote sh -c 'ip addr show mcp1 | grep -q 203.0.113.10/24 || ip addr add 203.0.113.10/24 dev mcp1
    ip link set mcp1 up; ip link set lo up'
  grep -q "mcp.marginalia.test" /etc/hosts || echo "203.0.113.10 mcp.marginalia.test auth.marginalia.test" >> /etc/hosts
  mkdir -p $REMOTE_TLS && chmod 0700 $REMOTE_TLS
  if [ ! -f $REMOTE_TLS/server.crt ]; then
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=Marginalia lab CA" \
      -keyout $REMOTE_TLS/ca.key -out $REMOTE_TLS/ca.crt 2>/dev/null
    openssl req -newkey rsa:2048 -nodes -subj "/CN=mcp.marginalia.test" \
      -keyout $REMOTE_TLS/server.key -out $REMOTE_TLS/server.csr 2>/dev/null
    printf 'subjectAltName=DNS:mcp.marginalia.test,DNS:auth.marginalia.test\n' > $REMOTE_TLS/san.ext
    openssl x509 -req -in $REMOTE_TLS/server.csr -CA $REMOTE_TLS/ca.crt -CAkey $REMOTE_TLS/ca.key \
      -CAcreateserial -days 825 -extfile $REMOTE_TLS/san.ext -out $REMOTE_TLS/server.crt 2>/dev/null
  fi
  install -m 0644 $REMOTE_TLS/ca.crt $SHARE/marginalia-ca.crt
}

# The tokens the authorization server would have issued, written by the lab:
# each value goes to ana's ~/agents/tokens/NAME (readable by her only), and its
# SHA-256 with what it grants goes to the remote server's table. The values are
# new on every deploy, and no lesson prints one.
write_tokens() {
  local name client scopes resource expires value table=$REMOTE/tokens.json
  install -d -o ana -g ana -m 0700 $WORK/tokens
  printf '{' > $table
  while read -r name client scopes resource expires; do
    value=lab-$(openssl rand -hex 24)
    printf '%s' "$value" > $WORK/tokens/$name; chown ana:ana $WORK/tokens/$name; chmod 0600 $WORK/tokens/$name
    printf '%s"%s": {"client_id": "%s", "scopes": %s, "resource": "%s", "expires_at": %s}' \
      "$([ "$(wc -c < $table)" -gt 1 ] && echo ,)" "$(printf '%s' "$value" | sha256sum | cut -d' ' -f1)" \
      "$client" "$scopes" "$resource" "$(date -d "$expires" +%s)" >> $table
  done <<'TOKENS'
support support-agent ["orders:read"] https://mcp.marginalia.test:8443/mcp 2026-12-31
refunds refunds-desk ["orders:read","orders:refund"] https://mcp.marginalia.test:8443/mcp 2026-12-31
billing billing-agent ["orders:read"] https://billing.marginalia.test/mcp 2026-12-31
expired old-agent ["orders:read"] https://mcp.marginalia.test:8443/mcp 2026-10-01
TOKENS
  printf '}\n' >> $table
  chown mcpd:mcpd $table; chmod 0600 $table
}

# Deploy what ana wrote to the second machine and start it there, as mcpd, with
# its own copy of the shop: the remote server reads nothing in /home/ana.
start_remote() {
  [ -f $WORK/remote_mcp.py ] || { echo "write ~/agents/remote_mcp.py first" >&2; return 1; }
  stop_remote
  rm -rf $REMOTE
  install -d -o mcpd -g mcpd -m 0700 $REMOTE
  install -d -o mcpd -g mcpd $REMOTE/data $REMOTE/tls
  install -o mcpd -g mcpd -m 0644 $WORK/remote_mcp.py "$HERE/lab/work/shop.py" "$HERE/lab/remote/auth_metadata.py" $REMOTE/
  install -o mcpd -g mcpd -m 0644 "$EMBLAB/data/help.jsonl" $REMOTE/data/
  install -o mcpd -g mcpd -m 0600 $REMOTE_TLS/server.crt $REMOTE_TLS/server.key $REMOTE/tls/
  runuser -u mcpd -- $VENV/bin/python -c "
import sqlite3, sys
db = sqlite3.connect('$REMOTE/data/shop.db')
db.executescript(open(sys.argv[1]).read())
db.commit()" "$HERE/lab/data/shop.sql"
  write_tokens
  local p
  for p in auth_metadata remote_mcp; do
    ip netns exec remote setsid runuser -u mcpd -- env -i PATH=$VENV/bin:/usr/bin:/bin HOME=$REMOTE \
      TZ=America/Sao_Paulo LAB_TODAY=2026-10-06 MINILM_DIR=$SHARE/all-MiniLM-L6-v2 \
      bash -c "cd $REMOTE && exec python $p.py" > /run/remote-$p.out 2>&1 < /dev/null &
    echo $! > /run/remote-$p.pid
  done
  for _ in $(seq 50); do
    curl -s -m 2 --noproxy "*" -o /dev/null --cacert $SHARE/marginalia-ca.crt https://mcp.marginalia.test:8443/mcp 2>/dev/null && return 0
    sleep 0.2
  done
  echo "the remote server did not start; see /run/remote-remote_mcp.out" >&2; return 1
}

stop_remote() {
  local p
  for p in auth_metadata remote_mcp; do
    if [ -f /run/remote-$p.pid ]; then
      pkill -P "$(cat /run/remote-$p.pid)" 2>/dev/null || true
      kill "$(cat /run/remote-$p.pid)" 2>/dev/null || true
      rm -f /run/remote-$p.pid
    fi
  done
  ip netns pids remote 2>/dev/null | xargs -r kill 2>/dev/null || true
  sleep 0.3
}

exec_as() {  # exec_as COMMAND: as ana, in ~/agents, with the lab's environment and nothing else
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $WORK || exit 1; $*"
}

case ${1:-} in
  up)
    need; build_user; write_env; build_venv; build_tokenizer; build_model
    build_remote; build_work; start_llm ;;
  reset)
    write_env; install_lab; stop_remote; build_work; start_llm ;;
  remote)
    build_user; build_remote; start_remote ;;
  down)
    stop_remote; stop_llm ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|remote|down|exec 'COMMAND'" >&2; exit 2 ;;
esac
