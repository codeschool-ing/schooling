#!/usr/bin/env bash
# The machine every transcript in ai-models was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana runs the support desk of Lantern Books,
# a small online bookshop that does not exist, and has to choose the model that
# will sort the shop's e-mail. ~/desk is her project, and the lessons are what
# she types at it.
#
#   /home/ana/desk        cases/ (forty e-mails, each labelled by a person),
#                         prompts/, and the programs the lessons write
#   /opt/aimodels         Python 3.11 with every provider SDK the course
#                         names, at the versions in PYLIBS
#   /opt/aimodels-cohere  Cohere's SDK on its own: it pins an older
#                         huggingface_hub than the one lesson 19 uses
#   /opt/aimodels/node    Node.js packages: Transformers.js for lesson 13,
#                         js-tiktoken for the token counter, and Playwright,
#                         which drives the headless Chromium `browse` opens
#                         (lab/browse.mjs) in place of ana clicking
#   127.0.0.1:8500        standin, which answers in place of eight providers
#   127.0.0.1:11434       standin again, where Ollama listens
#   127.0.0.1:1234        and again, where LM Studio's server listens
#   /var/log/standin      every request standin received, one JSON line each,
#                         which `wire` prints back (lab/wire.py)
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE. No model API is reachable
# from the machine this was recorded on, and an API key is a bill a course
# cannot hand out. So:
#
#   real       the SDKs (anthropic, openai, google-genai, huggingface_hub,
#              mistralai, ollama, cohere), what each of them puts on the wire,
#              the o200k_base tokenizer, and everything the lessons' own
#              programs compute: counts, rates, intervals, costs, timings.
#   real, and  sheet.py: LiteLLM's model_prices_and_context_window.json, a
#   dated      list every provider's models, windows, prices and features
#              that an open-source project keeps, read at ONE PINNED COMMIT.
#              It is a third party's copy of the providers' pages, which this
#              machine could not reach, and the lessons say so beside every
#              number they take from it.
#   real, and  sources.py: licences and documents the lessons quote, fetched
#   dated      from the projects' own repositories at pinned commits.
#   the lab's  standin (lab/standin.py). It speaks the APIs and is not a
#              model. Its three models answer from tables the course wrote
#              (lab/answers.json, lab/replies.json), and every lesson that
#              shows one of their replies says so.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/desk and restart standin
#   sudo bash lab.sh down
#   sudo bash lab.sh exec USER 'command'
#
# Recorded on Ubuntu 24.04 with Python 3.11 and Node.js 22, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=/opt/aimodels
COHERE=/opt/aimodels-cohere
SHARE=$VENV/share
NODEDIR=$VENV/node
LOGDIR=/var/log/standin
TZ_LAB=America/Sao_Paulo
PYLIBS="anthropic==1.11.0 openai==3.24.0 google-genai==2.28.0 huggingface_hub==2.1.1
  mistralai==3.0.0 ollama==0.6.3 tiktoken==0.14.0 numpy==2.4.6 jsonschema==4.26.0 onnx==1.23.1"
COHERELIBS="cohere==7.2.0"
JSLIBS="js-tiktoken@1.0.21 @huggingface/transformers@4.3.0 playwright@1.56.0"

# The environment every command of ana's runs in. The keys are the lab's and
# open nothing anywhere else; the base URLs are what point each SDK at standin.
ENVFILE=/etc/aimodels.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=$TZ_LAB
LANG=C.UTF-8
LC_ALL=C.UTF-8
TIKTOKEN_CACHE_DIR=$SHARE/tiktoken
ANTHROPIC_BASE_URL=http://127.0.0.1:8500
ANTHROPIC_API_KEY=lab-anthropic-key-0001
OPENAI_BASE_URL=http://127.0.0.1:8500/v1
OPENAI_API_KEY=lab-openai-key-0001
GEMINI_BASE_URL=http://127.0.0.1:8500
GEMINI_API_KEY=lab-google-key-0001
MISTRAL_SERVER_URL=http://127.0.0.1:8500
MISTRAL_API_KEY=lab-mistral-key-0001
CO_API_URL=http://127.0.0.1:8500
CO_API_KEY=lab-cohere-key-0001
HF_BASE_URL=http://127.0.0.1:8500/hf
HF_TOKEN=hf_lab_token_0001
OPENROUTER_BASE_URL=http://127.0.0.1:8500/openrouter/api/v1
OPENROUTER_API_KEY=sk-or-lab-key-0001
OLLAMA_HOST=http://127.0.0.1:11434
PYTHONDONTWRITEBYTECODE=1
EOF
  # Where Playwright finds its Chromium, when the machine says (lab/browse.mjs).
  [ -z "${PLAYWRIGHT_BROWSERS_PATH:-}" ] || echo "PLAYWRIGHT_BROWSERS_PATH=$PLAYWRIGHT_BROWSERS_PATH" >> "$ENVFILE"
}

need() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  command -v npm >/dev/null || { echo "npm is required (Node.js 22)" >&2; exit 1; }
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $PYLIBS
  [ -x $COHERE/bin/python ] || python3 -m venv $COHERE
  # shellcheck disable=SC2086
  $COHERE/bin/pip install -q $COHERELIBS
  printf '#!/bin/sh\nexec %s "$@"\n' $COHERE/bin/python > $VENV/bin/python-cohere
  chmod 0755 $VENV/bin/python-cohere
  mkdir -p $SHARE
  install_lab
}

install_lab() {
  local site
  site=$($VENV/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
  install -m 0644 "$HERE/lab/standin.py" "$site/"
  install -m 0644 "$HERE/lab/cases.jsonl" "$HERE/lab/answers.json" "$HERE/lab/replies.json" $SHARE/
  install -m 0755 "$HERE/lab/sheet.py" $VENV/bin/sheet
  install -m 0755 "$HERE/lab/sources.py" $VENV/bin/sources
  install -m 0755 "$HERE/lab/wire.py" $VENV/bin/wire
  install -m 0755 "$HERE/lab/train_sorter.py" $VENV/bin/train-sorter
  mkdir -p $NODEDIR
  install -m 0644 "$HERE/lab/browse.mjs" $NODEDIR/browse.mjs
  printf '#!/bin/sh\nexec node %s "$@"\n' $NODEDIR/browse.mjs > $VENV/bin/browse
  chmod 0755 $VENV/bin/browse
}

# The two things fetched from the network, once, so that every command in the
# lessons runs without it: the model sheet and the quoted documents.
build_data() {
  $VENV/bin/sheet count >/dev/null
  $VENV/bin/sources fetch
}

# tiktoken downloads its encoding on first use, from a host this machine cannot
# reach. js-tiktoken ships the same table, so it is written back out in
# tiktoken's format; tiktoken checks the file against the SHA-256 it ships
# with, so a reconstruction off by one byte would be refused rather than used.
build_node() {
  mkdir -p $NODEDIR $SHARE/tiktoken
  # --ignore-scripts: onnxruntime-node's install script fetches GPU libraries
  # from a host this machine cannot reach. The CPU runtime is inside the
  # package itself, and the CPU is all lesson 13 uses. Playwright's own
  # script would download a Chromium; the machine already has one.
  ( cd $NODEDIR && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent --ignore-scripts $JSLIBS )
  ( cd $NODEDIR && node -e '
    const fs = require("fs"), crypto = require("crypto");
    const r = require("js-tiktoken/ranks/o200k_base"), rows = [];
    for (const line of r.bpe_ranks.split("\n").filter(Boolean)) {
      const [, offset, ...tokens] = line.split(" ");
      tokens.forEach((t, i) => rows.push([parseInt(offset, 10) + i, t]));
    }
    rows.sort((a, b) => a[0] - b[0]);
    const url = "https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken";
    const name = crypto.createHash("sha1").update(url).digest("hex");
    fs.writeFileSync(process.argv[1] + "/" + name, rows.map(([k, t]) => t + " " + k).join("\n") + "\n");
    ' $SHARE/tiktoken )
  TIKTOKEN_CACHE_DIR=$SHARE/tiktoken $VENV/bin/python -c 'import tiktoken; tiktoken.get_encoding("o200k_base")'
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  id standin >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin standin
  mkdir -p $LOGDIR && chown standin:standin $LOGDIR && chmod 0755 $LOGDIR
}

# The project, as it stands before lesson 1.
build_desk() {
  rm -rf /home/ana/desk
  runuser -u ana -- mkdir -p /home/ana/desk/cases /home/ana/desk/prompts /home/ana/desk/lab
  install -o ana -m 0644 "$HERE/lab/cases.jsonl" /home/ana/desk/cases/triage.jsonl
  # A project's own node_modules, as `npm install` would leave it: Node's
  # `import` looks for packages beside the program, not in NODE_PATH.
  runuser -u ana -- ln -s $NODEDIR/node_modules /home/ana/desk/node_modules
  runuser -u ana -- tee /home/ana/desk/prompts/triage.txt >/dev/null <<'EOF'
You sort the e-mail of Lantern Books, an online bookshop.
Answer with exactly one label and nothing else:
order-status, refund, address-change, product-question, other.
EOF
  runuser -u ana -- tee /home/ana/desk/prompts/extract.txt >/dev/null <<'EOF'
Read the customer's e-mail and answer with JSON only, in this shape:
{"order": "LB-12345"}
Use null for "order" when the e-mail names no order.
EOF
}

start_standin() {
  stop_standin
  : > $LOGDIR/requests.jsonl; chown standin:standin $LOGDIR/requests.jsonl; chmod 0644 $LOGDIR/requests.jsonl
  install_lab
  setsid runuser -u standin -- env -i PATH=$VENV/bin:/usr/bin:/bin TZ=$TZ_LAB \
    TIKTOKEN_CACHE_DIR=$SHARE/tiktoken STANDIN_SHARE=$SHARE STANDIN_LOG=$LOGDIR \
    $VENV/bin/python -m standin > /run/standin.out 2>&1 < /dev/null &
  echo $! > /run/standin.pid
  for _ in $(seq 50); do
    curl -s -o /dev/null http://127.0.0.1:11434/ 2>/dev/null && return 0
    sleep 0.2
  done
  echo "standin did not start; see /run/standin.out" >&2; return 1
}

stop_standin() {
  if [ -f /run/standin.pid ]; then
    kill "$(cat /run/standin.pid)" 2>/dev/null || true
    rm -f /run/standin.pid
    sleep 0.3
  fi
}

exec_as() {  # exec_as USER COMMAND: in ~/desk, with the lab's environment and nothing else
  local u=$1; shift
  local dir=/home/$u/desk
  [ -d "$dir" ] || dir=/home/$u
  # shellcheck disable=SC2046
  runuser -u "$u" -- env -i HOME=/home/$u USER="$u" $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $dir || exit 1; $*"
}

case ${1:-} in
  up)
    need; build_user; write_env; build_venv; build_node; build_data; build_desk; start_standin ;;
  reset)
    write_env; build_desk; start_standin ;;
  down)
    stop_standin ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: $0 up|reset|down|exec USER COMMAND" >&2; exit 2 ;;
esac
