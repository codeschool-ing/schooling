#!/usr/bin/env bash
# The machine every transcript in ml-mlops was recorded on. AUTHORING ONLY:
# the student never receives this file, and no lesson names it.
#
# IT IS THE STUDENT'S OWN SETUP, RUN BY A SCRIPT. ana is the data engineer of
# Ponto Final, the chain of bookshops that does not exist from
# warehouse-modeling and pipelines-etl, and ~/ml is where she puts the shop's
# first model into production. What she installed is what lesson 1 tells the
# student to install, and this file keeps no copy of it: the steps are read
# out of lesson 1's fences with lab/fences.py and run as written, so the
# lesson and the lab cannot drift apart. ~/ml starts with generate.py, read
# out of lesson 1 the same way, and every program a later lesson needs is
# read out of the lesson that shows it (lab/capture.sh, stage).
#
#   /home/ana/mlenv     Python 3.12 in a virtual environment, with the
#                       libraries lesson 1 installs; later lessons add their
#                       own with the pip lines they show
#   /home/ana/ml        the project, as the lessons build it
#
# WHAT THIS MACHINE HAS THAT A STUDENT'S DOES NOT, AND THE OTHER WAY ROUND.
#
#   No systemd and no display. Nothing in the course needs either: the
#   servers it starts (MLflow's page, the model's web service) are started in
#   a terminal, and their pages are read with curl or photographed headless.
#
#   No GPU, and none is needed: every model in the course trains on a
#   processor in seconds. Timings are a 4-core machine's.
#
#   sudo bash lab.sh up              build it from nothing
#   sudo bash lab.sh purge           remove ana and everything of hers
#   sudo bash lab.sh STEP            one step of up, for lesson 1's capture:
#                                    user, system, venv, project
#   sudo bash lab.sh exec 'command'  as ana, in ~/ml with the environment
#                                    active; IN_HOME=1 runs it in ~, BARE=1
#                                    without the environment, as a new
#                                    terminal would
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. A server started
# here must not inherit it, or it holds it for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
L1=$HERE/lessons/le-xpaf8cg8
FENCES="python3 $HERE/lab/fences.py"
TZ_LAB=America/Sao_Paulo
# The recording machine's python3 is 3.13 and Ubuntu 24.04's is 3.12, so ana
# finds a python3 that is 3.12 before the system's.
SHIM=/opt/mlops-capture/bin
ANA_PATH=$SHIM:/usr/local/bin:/usr/bin:/bin
# The recording network re-signs TLS with its own authority, whose bundle sits
# in root's home; ana gets a copy she can read. A student's machine has none.
CA=/opt/mlops-capture/ca-bundle.crt

build_user() {
  mkdir -p $SHIM && ln -sf /usr/bin/python3.12 $SHIM/python3
  # and Ubuntu 24.04's pip, which is 3.12's; the recording machine's own pip
  # belongs to its 3.13, which is not marked as the system's
  printf '#!/bin/sh\nexec /usr/bin/python3.12 -m pip "$@"\n' > $SHIM/pip
  chmod 0755 $SHIM/pip
  if [ -n "${SSL_CERT_FILE:-}" ]; then cp "$SSL_CERT_FILE" $CA; chmod 0644 $CA; fi
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # The proxy variables survive sudo because the recording network needs them;
  # a student's machine has nothing to keep.
  printf '%s\n' 'ana ALL=(ALL) NOPASSWD: ALL' \
    'Defaults:ana env_keep += "https_proxy HTTPS_PROXY no_proxy NO_PROXY SSL_CERT_FILE REQUESTS_CA_BUNDLE PIP_CERT"' \
    > /etc/sudoers.d/ana
  chmod 0440 /etc/sudoers.d/ana
}

exec_as() {  # exec_as COMMAND: as ana, in ~/ml (or ~), with the environment unless BARE
  local dir=/home/ana/ml pre='[ -f ~/mlenv/bin/activate ] && source ~/mlenv/bin/activate; '
  [ -n "${IN_HOME:-}" ] && dir=/home/ana
  [ -n "${BARE:-}" ] && pre=
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana TZ=$TZ_LAB \
    LANG=C.UTF-8 LC_ALL=C.UTF-8 PATH=$ANA_PATH TERM=dumb COLUMNS=100 \
    HTTPS_PROXY="${HTTPS_PROXY:-}" https_proxy="${https_proxy:-}" \
    NO_PROXY="${NO_PROXY:-}" no_proxy="${no_proxy:-}" \
    SSL_CERT_FILE="${SSL_CERT_FILE:+$CA}" REQUESTS_CA_BUNDLE="${REQUESTS_CA_BUNDLE:+$CA}" \
    PIP_CERT="${SSL_CERT_FILE:+$CA}" PIP_DISABLE_PIP_VERSION_CHECK=1 \
    MLFLOW_DISABLE_AGENT_HINT=1 PYTHONDONTWRITEBYTECODE=1 \
    bash -c "cd $dir && $pre$*"
}

# Lesson 1's steps, as the student types them.
install_system() {
  $FENCES block "$L1/installing.md" 'sudo apt update' | IN_HOME=1 BARE=1 exec_as 'bash -e -s'
}
build_venv() {
  rm -rf /home/ana/mlenv
  $FENCES block "$L1/installing.md" 'python3 -m venv ~/mlenv' | IN_HOME=1 BARE=1 exec_as 'bash -e -s'
}
build_project() {
  rm -rf /home/ana/ml
  install -d -o ana -g ana /home/ana/ml
  $FENCES example "$L1/the-shop.md" generate.py > /home/ana/ml/generate.py
  chown ana:ana /home/ana/ml/generate.py
  exec_as 'python generate.py > /dev/null'
}

purge() {
  pkill -u ana 2>/dev/null || true
  userdel -r ana 2>/dev/null || true
  rm -f /etc/sudoers.d/ana
}

case ${1:-} in
  up) build_user; install_system; build_venv; build_project ;;
  purge) purge ;;
  user) build_user ;;
  system) install_system ;;
  venv) build_venv ;;
  project) build_project ;;
  exec) shift; exec_as "$@" ;;
  *) echo "usage: sudo bash lab.sh up|purge|user|system|venv|project|exec 'COMMAND'" >&2; exit 2 ;;
esac
