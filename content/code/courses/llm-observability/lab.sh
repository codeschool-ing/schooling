#!/usr/bin/env bash
# The machine every transcript in llm-observability was recorded on.
#
# IT IS THE STUDENT'S OWN SETUP, RUN BY A SCRIPT. ana is a developer at
# Marginalia, an online bookshop that does not exist, and ~/obs is the help
# assistant she is asked to watch in production. What she installed is what
# lesson 1 tells the student to install, and this file keeps no copy of it:
# the steps are read out of lesson 1's fences with lab/fences.py and run as
# written, so the lesson and the lab cannot drift apart. ~/obs is built the
# same way, by the script lesson 1 shows whole, and every program a later
# lesson needs is read out of the lesson that shows it (lab/capture.sh, stage).
#
#   /home/ana/llmobs     Python 3.12 in a virtual environment, with the
#                        libraries lesson 1 installs and the variables it
#                        appends to the activate script; later lessons add
#                        their own libraries with the pip lines they show
#   /home/ana/obs        the project, as lesson 1 builds it
#   127.0.0.1:11434      Ollama, serving llama3.2:3b and all-minilm, the two
#                        models lesson 1 pulls
#
# WHAT THIS MACHINE HAS THAT A STUDENT'S DOES NOT, AND THE OTHER WAY ROUND.
#
#   No systemd. The recording machine is a container, so the Ollama installer
#   cannot register its service, and this file starts `ollama serve` itself.
#   Lesson 1's section on a failing setup shows the message that leaves, and
#   the same fix.
#
#   No GPU. Every timing in the course is a CPU's: 4 cores, 15 GB of memory.
#
#   sudo bash lab.sh up              build it (installs Ollama and pulls the models)
#   sudo bash lab.sh reset           rebuild ~/obs and make sure Ollama answers
#   sudo bash lab.sh purge           remove Ollama, its models, ana and her files
#   sudo bash lab.sh STEP            one step of up, for lesson 1's capture:
#                                    user, system, models, small, venv, project
#   sudo bash lab.sh serve|unserve   start or stop Ollama's server
#   sudo bash lab.sh exec 'command'  as ana, in ~/obs with the environment
#                                    active; IN_HOME=1 runs it in ~, BARE=1
#                                    without the environment, as a new
#                                    terminal would
#
# Recorded on Ubuntu 24.04 with Python 3.12 and Ollama 0.40.0,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The server started
# here must not inherit it, or it holds it for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1=$HERE/lessons/le-6wxafmfh
FENCES="python3 $HERE/lab/fences.py"
TZ_LAB=America/Sao_Paulo
# The recording machine's python3 is 3.13 and Ubuntu 24.04's is 3.12, so ana
# finds a python3 that is 3.12 before the system's.
SHIM=/opt/llmobs-capture/bin
ANA_PATH=$SHIM:/usr/local/bin:/usr/bin:/bin
# The recording network re-signs TLS with its own authority, whose bundle sits
# in root's home; ana gets a copy she can read. A student's machine has none.
CA=/opt/llmobs-capture/ca-bundle.crt

build_user() {
  mkdir -p $SHIM && ln -sf /usr/bin/python3.12 $SHIM/python3
  if [ -n "${SSL_CERT_FILE:-}" ]; then cp "$SSL_CERT_FILE" $CA; fi
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # The proxy variables survive sudo because the recording network needs them;
  # a student's machine has nothing to keep.
  printf '%s\n' 'ana ALL=(ALL) NOPASSWD: ALL' \
    'Defaults:ana env_keep += "https_proxy HTTPS_PROXY no_proxy NO_PROXY SSL_CERT_FILE REQUESTS_CA_BUNDLE"' \
    > /etc/sudoers.d/ana
  chmod 0440 /etc/sudoers.d/ana
}

as_ana() {  # as_ana DIR: run stdin as ana's login-less bash, in DIR
  local dir=$1
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana TZ=$TZ_LAB \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=$ANA_PATH \
    HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${https_proxy:-}" \
    NO_PROXY="${NO_PROXY:-}" no_proxy="${no_proxy:-}" \
    SSL_CERT_FILE="${SSL_CERT_FILE:+$CA}" REQUESTS_CA_BUNDLE="${REQUESTS_CA_BUNDLE:+$CA}" \
    PYTHONDONTWRITEBYTECODE=1 bash -c "cd $dir && exec bash -e -s"
}

# Lesson 1's steps, as the student types them.
install_system() {
  { $FENCES block "$L1/installing.md" 'sudo apt update'
    $FENCES block "$L1/installing.md" 'curl -fsSL https://ollama.com/install.sh -o install-ollama.sh'
  } | as_ana /home/ana
}
install_models() {
  serve
  $FENCES block "$L1/installing.md" 'ollama pull llama3.2:3b' | as_ana /home/ana
}
build_venv() {
  rm -rf /home/ana/llmobs
  { $FENCES block "$L1/installing.md" 'python3 -m venv ~/llmobs'
    $FENCES block "$L1/installing.md" "cat >> ~/llmobs/bin/activate <<EOF"
  } | as_ana /home/ana
}
# ~/obs as lesson 1's project section leaves it: the documents and releases
# from make-obs.sh, and index.py and redact.py, with the index built.
build_project() {
  rm -rf /home/ana/obs /home/ana/make-obs.sh
  $FENCES named "$L1/the-project.md" make-obs.sh > /home/ana/make-obs.sh
  chown ana:ana /home/ana/make-obs.sh
  { echo 'bash ~/make-obs.sh ~/obs'
    for f in index.py redact.py; do
      printf "cat > ~/obs/%s <<'PROGRAM'\n" $f
      $FENCES named "$L1/the-project.md" $f
      echo PROGRAM
    done
    echo 'source ~/llmobs/bin/activate && cd ~/obs && python index.py >/dev/null'
  } | as_ana /home/ana
}

# The smaller model lesson 1 names for a weaker computer, pulled the way it says.
pull_small() {
  serve
  $FENCES block "$L1/your-machine.md" 'ollama pull llama3.2:1b' | as_ana /home/ana
}

# Back to a machine that never had any of it, so that lesson 1's capture
# records a first install: Ollama, its models, its service user, and ana.
purge() {
  unserve
  rm -rf /usr/local/bin/ollama /usr/local/lib/ollama /root/.ollama /usr/share/ollama \
    /etc/systemd/system/ollama.service
  userdel ollama 2>/dev/null || true
  groupdel ollama 2>/dev/null || true
  userdel -r ana 2>/dev/null || true
  rm -f /etc/sudoers.d/ana
}

serve() {
  curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
  setsid ollama serve > /var/log/ollama-lab.log 2>&1 < /dev/null &
  for _ in $(seq 100); do
    curl -s -o /dev/null http://127.0.0.1:11434/ && return 0
    sleep 0.2
  done
  echo "ollama did not start; see /var/log/ollama-lab.log" >&2; return 1
}
unserve() { pkill -f '^ollama serve' 2>/dev/null || true; sleep 1; }

exec_as() {  # exec_as COMMAND: as ana, in ~/obs (or ~), with the environment unless BARE
  local dir=/home/ana/obs pre='[ -f ~/llmobs/bin/activate ] && source ~/llmobs/bin/activate; '
  [ -n "${IN_HOME:-}" ] && dir=/home/ana
  [ -n "${BARE:-}" ] && pre=
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana TZ=$TZ_LAB \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=$ANA_PATH \
    HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${https_proxy:-}" \
    NO_PROXY="${NO_PROXY:-}" no_proxy="${no_proxy:-}" \
    SSL_CERT_FILE="${SSL_CERT_FILE:+$CA}" REQUESTS_CA_BUNDLE="${REQUESTS_CA_BUNDLE:+$CA}" \
    PYTHONDONTWRITEBYTECODE=1 bash -c "cd $dir && $pre$*"
}

case ${1:-} in
  up) build_user; install_system; install_models; pull_small; build_venv; build_project ;;
  purge) purge ;;
  small) pull_small ;;
  reset) serve; build_project ;;
  user) build_user ;;
  system) install_system ;;
  models) install_models ;;
  venv) build_venv ;;
  project) build_project ;;
  serve) serve ;;
  unserve) unserve ;;
  exec) shift; exec_as "$@" ;;
  *) echo "usage: sudo bash lab.sh up|reset|user|system|models|venv|project|serve|unserve|exec 'COMMAND'" >&2; exit 2 ;;
esac
