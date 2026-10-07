#!/usr/bin/env bash
# The computer every transcript in visualization was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON, built the way lesson 1 tells a student to
# build theirs. ana is an analyst at Horta, an online grocer that does not
# exist. ~/viz is her working directory:
#
#   ~/viz/horta.py   the course's data, copied from beside this file; the
#                    lesson prints the same file for the student to save
#   ~/viz/.venv      Python's own virtual environment, with matplotlib pinned
#                    in PYLIBS (numpy comes with it)
#   ~/viz/*.csv      what `python3 horta.py` writes
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      Python 3.13, matplotlib 3.11.2 and numpy 2.5.3, which run every
#             script in the course; LibreOffice Calc 24.2, which lesson 20
#             opens headless to convert a file.
#   written   every row of data. horta.py draws it from random.Random with
#             fixed seeds, so it is the same on every computer.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: Excel, Power BI and Tableau, which are
# not made for Linux and need an account. Lesson 20 describes them and says
# that nothing it shows of them was run here.
#
#   sudo bash lab.sh up              create ana and ~/viz with horta.py only
#   sudo bash lab.sh ready           up, then the virtual environment and data
#                                    (what lesson 1 has the student do)
#   sudo bash lab.sh reset           remove everything in ~/viz except .venv
#                                    and horta.py, then rewrite the data
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/viz
#   sudo bash lab.sh down            remove ana and her home
#
# Recorded on Ubuntu 24.04 with Python 3.13, 4 cores, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VIZ=/home/ana/viz
PYLIBS="matplotlib==3.11.2"

# The rest of the caller's environment goes through on purpose: a machine
# that reaches the internet through a proxy needs pip to see it. A proxy that
# inspects TLS hands pip its certificate in PIP_CERT, and when that file sits
# somewhere ana cannot read, a readable copy is made and named instead.
if [ -n "${PIP_CERT:-}" ] && [ -f "$PIP_CERT" ]; then
  install -m 644 "$PIP_CERT" /usr/local/share/lab-ca.pem
  export PIP_CERT=/usr/local/share/lab-ca.pem SSL_CERT_FILE=/usr/local/share/lab-ca.pem \
    REQUESTS_CA_BUNDLE=/usr/local/share/lab-ca.pem
  unset PIP_CONFIG_FILE
fi
as_ana() {
  runuser -u ana -- env HOME=/home/ana USER=ana LOGNAME=ana TZ=America/Sao_Paulo \
    LC_ALL=C.UTF-8 MPLBACKEND=Agg bash -c "cd $VIZ && $1"
}

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  install -d -o ana -g ana "$VIZ"
  install -o ana -g ana -m 644 "$HERE/horta.py" "$VIZ/horta.py"
}

ready() {
  up
  if [ ! -x "$VIZ/.venv/bin/python" ]; then
    as_ana "python3 -m venv .venv && .venv/bin/pip install --quiet $PYLIBS"
  fi
  as_ana ".venv/bin/python horta.py" >/dev/null
}

reset() {
  ready
  find "$VIZ" -mindepth 1 -maxdepth 1 ! -name .venv ! -name horta.py -exec rm -rf {} +
  # matplotlib caches the fonts it found; a fresh cache would print a line
  # about building it into whichever transcript happened to come first.
  as_ana ".venv/bin/python -c 'import matplotlib.pyplot'"
  as_ana ".venv/bin/python horta.py" >/dev/null
}

case "${1:-}" in
  up) up ;;
  ready) ready ;;
  reset) reset ;;
  exec) shift; as_ana "$*" ;;
  down) id ana >/dev/null 2>&1 && userdel -r ana 2>/dev/null || true ;;
  *) echo "usage: lab.sh up|ready|reset|exec COMMAND|down" >&2; exit 2 ;;
esac
