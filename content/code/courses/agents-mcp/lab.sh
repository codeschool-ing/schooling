#!/usr/bin/env bash
# The machine every transcript in agents-mcp was recorded on, built the way
# lesson 1 tells the student to build theirs.
#
# THIS FILE IS THE AUTHOR'S, AND THE STUDENT NEVER SEES IT. It does in one
# command what lesson 1's sections "Your own lab" and "The shop" ask the
# student to type, and nothing more: a user, ~/agents with a virtual
# environment and the pinned libraries, the models pulled into Ollama, and the
# shop's files. Every file it installs into ~/agents is checked first against
# the lessons by lab/shown.py, so what a capture runs is what a lesson shows.
#
#   /home/ana/agents          the working directory, rebuilt by `reset`
#     .venv/                  Python 3.12 and every library the lessons import
#                             (PYLIBS); kept across resets, because it is slow
#     ollama.env              the SDKs' base URLs, appended to .venv/bin/activate
#     make_shop.py, shop.py   the shop: run make_shop.py and data/ appears
#     recorder.py             the request log the "what it sends" sections read
#   127.0.0.1:11434           Ollama, with MODELS pulled
#
# WHAT IS REAL. Everything: the models are Ollama's, and every reply a lesson
# shows is what that model said on the day it was captured. Each captures.sh
# names the model, its tag and the date in its header.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: every provider's paid API, and the
# hosted products (OpenAI's Agent Builder and ChatKit, Vertex AI Agent Builder
# and Agent Engine). The lessons that show their code say it was not run.
#
# Ollama itself is installed by hand, before `up`, as lesson 1 says; it has to
# answer on 127.0.0.1:11434 and run with OLLAMA_CONTEXT_LENGTH=8192.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/agents, keeping .venv
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/agents, venv active
#
# Recorded on Ubuntu 24.04 with Python 3.12 and Ollama 0.40.0, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. Nothing started from
# here may inherit it.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORK=/home/ana/agents
PYTHON=python3.12
PYLIBS="anthropic==1.11.0 openai==3.24.0 mcp==2.3.0
  openai-agents==0.23.1 claude-agent-sdk==0.2.163 google-adk==2.11.0 litellm==1.83.0
  jsonschema==4.26.0 pytest==9.1.1 uvicorn==0.54.0"
MODELS="llama3.2:3b llama3.2:1b qwen2.5:3b all-minilm"
# The files lesson 1 shows, installed into ~/agents.
FILES="make_shop.py shop.py recorder.py ollama.env"

need() {
  command -v $PYTHON >/dev/null || { echo "$PYTHON is required: apt-get install python3-venv" >&2; exit 1; }
  command -v ollama >/dev/null || { echo "ollama is required: install it as lesson 1 says" >&2; exit 1; }
  curl -s -o /dev/null http://127.0.0.1:11434/ || { echo "ollama is not answering on 11434" >&2; exit 1; }
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
}

build_venv() {
  install -d -o ana -g ana $WORK
  [ -x $WORK/.venv/bin/python ] || runuser -u ana -- $PYTHON -m venv $WORK/.venv
  # shellcheck disable=SC2086
  runuser -u ana -- $WORK/.venv/bin/pip install -q $PYLIBS
}

pull_models() {
  local m
  for m in $MODELS; do ollama pull "$m" >/dev/null; done
}

# ~/agents as it stands once lesson 1's setup is done: the shop and nothing else.
build_work() {
  local f
  for f in $FILES; do $PYTHON "$HERE/lab/shown.py" "$HERE/lab/work/$f"; done
  find $WORK -mindepth 1 -maxdepth 1 ! -name .venv -exec rm -rf {} +
  for f in $FILES; do install -o ana -g ana -m 0644 "$HERE/lab/work/$f" $WORK/; done
  # The venv's activate script is rebuilt with ollama.env on its end, as the lesson does it.
  sed -i '/^# ollama.env/,$d' $WORK/.venv/bin/activate
  cat $WORK/ollama.env >> $WORK/.venv/bin/activate
  exec_as 'python make_shop.py' >/dev/null
}

exec_as() {  # exec_as COMMAND: as ana, in ~/agents, with the venv active and nothing else inherited
  runuser -u ana -- env -i HOME=/home/ana USER=ana PATH=/usr/local/bin:/usr/bin:/bin \
    TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1 \
    bash -c "cd $WORK || exit 1; . .venv/bin/activate; $*"
}

case ${1:-} in
  up)
    need; build_user; build_venv; pull_models; build_work ;;
  reset)
    need; build_work ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: sudo bash lab.sh up|reset|exec 'COMMAND'" >&2; exit 2 ;;
esac
