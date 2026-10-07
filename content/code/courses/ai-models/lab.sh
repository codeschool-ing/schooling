#!/usr/bin/env bash
# The machine every transcript in ai-models was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana runs the support desk of Lantern Books,
# a small online bookshop that does not exist, and has to choose the model that
# will sort the shop's e-mail. ~/desk is her project, and the lessons are what
# she types at it.
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS, and gets none of this file
# (C-38, C-40). Lesson 1 installs Ollama, pulls the model and builds ~/desk: the
# virtual environment, desk.env, the prompts and the forty cases. Every file in
# ~/desk below is extracted from the lesson that shows it (lab/extract.py), so a
# capture runs what the student was given and the two cannot drift.
#
#   ollama           installed by ollama.com's own install.sh, as lesson 1 shows;
#                    on a machine with no systemd the server is `ollama serve`,
#                    started here in the background
#   llama3.2:3b      the course's model, the same in every AI course
#   llama3.2:1b      the smaller one lesson 1 names for a weaker computer
#   /home/ana/desk   cases/, prompts/, desk.env, .venv, and the programs the
#                    lessons write
#
# WHAT IS NOT THE STUDENT'S, and is only how the captures are made:
#   lab/extract.py   reads a file out of the lesson that shows it
#   lab/screen.py    renders what a terminal showed (ollama pull/run draw)
#   lab/sources.py   the documents the lessons QUOTE, at pinned commits; a
#                    quotation is printed with its repository, commit, path and
#                    line numbers, and the student is never asked to run it
#   /opt/aimodels-author   a Python for the three above, and the documents' cache
#
# No model API is reachable from this machine, and an API key is a bill a course
# cannot hand out. Every model answer in the course is llama3.2 through Ollama,
# and the lessons say so; openrouter.ai, huggingface.co and lmstudio.ai were
# refused by this machine's network, and the lessons quote their documentation.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/desk from the lessons
#   sudo bash lab.sh exec USER 'command'
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1=$HERE/lessons/le-gwptbb4h
AUTHOR=/opt/aimodels-author
SHARE=/opt/aimodels-author/share
TZ_LAB=America/Sao_Paulo
MODELS="llama3.2:3b llama3.2:1b"
DESK=/home/ana/desk

need() {
  for c in python3 curl npm; do command -v $c >/dev/null || { echo "$c is required" >&2; exit 1; }; done
  python3 -c 'import ensurepip' 2>/dev/null || { echo "python3-venv is required" >&2; exit 1; }
}

x() { "$AUTHOR/bin/python" "$HERE/lab/extract.py" "$@"; }

build_author() {
  [ -x $AUTHOR/bin/python ] || python3 -m venv $AUTHOR
  mkdir -p $SHARE
  SOURCES_CACHE=$SHARE/sources $AUTHOR/bin/python "$HERE/lab/sources.py" fetch
}

ollama_up() {
  command -v ollama >/dev/null || curl -fsSL https://ollama.com/install.sh | sh
  if ! curl -s -o /dev/null http://127.0.0.1:11434/; then
    setsid ollama serve > /run/ollama-lab.out 2>&1 < /dev/null &
    for _ in $(seq 50); do curl -s -o /dev/null http://127.0.0.1:11434/ && break; sleep 0.2; done
  fi
  for m in $MODELS; do ollama pull "$m" >/dev/null 2>&1; done
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Ollama's install.sh calls sudo for what it writes outside the home directory.
  echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana-lab && chmod 0440 /etc/sudoers.d/ana-lab
}

# ~/desk as lesson 1 leaves it, every file taken from the section that shows it.
build_desk() {
  rm -rf $DESK
  runuser -u ana -- mkdir -p $DESK/cases $DESK/prompts
  x $L1/desk.md after 'prompts/triage.txt`:' | runuser -u ana -- tee $DESK/prompts/triage.txt >/dev/null
  x $L1/desk.md after 'prompts/extract.txt`:' | runuser -u ana -- tee $DESK/prompts/extract.txt >/dev/null
  x $L1/desk.md json 1 | runuser -u ana -- tee $DESK/cases/triage.jsonl >/dev/null
  x $L1/desk.md sh 1 | runuser -u ana -- tee $DESK/desk.env >/dev/null
  x $L1/desk.md after '`check.py` sends' | runuser -u ana -- tee $DESK/check.py >/dev/null
  runuser -u ana -- python3 -m venv $DESK/.venv
  # the pip line, exactly as the section's transcript has ana type it
  local pip; pip=$(grep -m1 '^ana@desk:~/desk\$ pip install ' $L1/desk.md | sed 's/^ana@desk:~\/desk\$ //')
  exec_as ana "$pip"
}

exec_as() {  # exec_as USER COMMAND: in ~/desk, with desk.env and the venv, and nothing else
  local u=$1; shift
  local dir=/home/$u/desk
  [ -d "$dir" ] || dir=/home/$u
  # The proxy is this machine's way out, not the student's; it is passed on so
  # that what ana fetches goes where it would on any other machine.
  runuser -u "$u" -- env -i HOME=/home/$u USER="$u" TZ=$TZ_LAB LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    PATH=/usr/local/bin:/usr/bin:/bin PYTHONDONTWRITEBYTECODE=1 \
    ${HTTPS_PROXY:+HTTPS_PROXY=$HTTPS_PROXY https_proxy=$HTTPS_PROXY NO_PROXY=${NO_PROXY:-} no_proxy=${NO_PROXY:-}} \
    bash -c "cd $dir || exit 1; [ -f desk.env ] && . ./desk.env; [ -f .venv/bin/activate ] && . .venv/bin/activate; $*"
}

case ${1:-} in
  up)
    need; build_author; ollama_up; build_user; build_desk ;;
  reset)
    ollama_up; build_desk ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: $0 up|reset|exec USER COMMAND" >&2; exit 2 ;;
esac
