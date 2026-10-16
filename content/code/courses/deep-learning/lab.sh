#!/usr/bin/env bash
# The machine every transcript in deep-learning was recorded on. THE AUTHOR'S,
# NOT THE STUDENT'S: the student never receives this file. Lesson 1 teaches them
# to build the same machine with the same commands, and everything this script
# installs or writes is either one of those commands or a file a lesson shows.
#
# WHAT IT IS. An Ubuntu 24.04 machine with four processors, no graphics card,
# and ~/dl: a Python 3.12 virtual environment in ~/dl/.venv holding the
# libraries of lesson 1's requirements.txt.
#
# THE STUDENT IS ana, on a machine called vm, and the prompt every capture
# prints says so. This script runs as root and runs ana's commands as root with
# HOME=/home/ana: the capture machine had no account to give her.
#
# NOTHING THE LESSONS USE IS COPIED IN FROM HERE. lab/shown.py prints a file
# exactly as the lessons show it, and every captures.sh writes its programs
# from it. If a lesson changes a program, the next capture runs the changed one.
#
#   sudo bash lab.sh up                 build it (idempotent)
#   sudo bash lab.sh reset              empty ~/dl, keeping the environment
#   sudo bash lab.sh exec 'COMMAND'     run COMMAND as ana, in ~/dl
#
# Recorded on Ubuntu 24.04 with Python 3.12.3, TZ=America/Sao_Paulo.
set -euo pipefail
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SHOWN="python3 $HERE/lab/shown.py $HERE"
DL=/home/ana/dl

up() {
  # Lesson 1 installs python3-venv; this machine already had it.
  python3.12 -c 'import ensurepip' 2>/dev/null \
    || DEBIAN_FRONTEND=noninteractive apt-get install -y -q python3-venv >/dev/null
  # This machine's python3 is 3.13, and Ubuntu 24.04's is 3.12. A terminal that
  # never activated the environment finds 3.12 under its usual name through
  # this directory, as it would on the student's machine.
  mkdir -p /opt/dl-share/bin $DL
  ln -sf /usr/bin/python3.12 /opt/dl-share/bin/python3
  [ -x $DL/.venv/bin/python ] || python3.12 -m venv $DL/.venv
  $SHOWN requirements.txt > $DL/requirements.txt
  $DL/.venv/bin/pip install -q -r $DL/requirements.txt
}

reset() {
  find $DL -mindepth 1 -maxdepth 1 ! -name .venv ! -name requirements.txt -exec rm -rf {} +
}

run() {
  cd $DL
  env -i HOME=/home/ana USER=ana LANG=C.UTF-8 TZ=America/Sao_Paulo TERM=dumb \
    PATH=$DL/.venv/bin:/usr/local/bin:/usr/bin:/bin VIRTUAL_ENV=$DL/.venv \
    PYTHONHASHSEED=0 bash -c "$1"
}

case "${1:-}" in
  up) up ;;
  reset) reset ;;
  exec) run "$2" ;;
  *) echo "usage: lab.sh up | reset | exec 'COMMAND'" >&2; exit 2 ;;
esac
