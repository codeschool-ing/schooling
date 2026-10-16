#!/usr/bin/env bash
# The computer every transcript in bi-techniques was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON, built the way lesson 1 tells a student to
# build theirs. ana is an analyst at Panela, a meal-kit company that does not
# exist. ~/bi is her working directory:
#
#   ~/bi/panela.py   the course's data. It is read out of lesson 1's own page
#                    (the-data.md), so the file the student saves and the file
#                    every capture ran on cannot differ
#   ~/bi/.venv       Python's virtual environment, with the packages pinned in
#                    PYLIBS (numpy and scipy come with them)
#   ~/bi/*.csv       what `python3 panela.py` writes
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      Python 3.13, pandas 3.0.6, statsmodels 0.15.0, scikit-learn
#             1.9.1, numpy 2.5.3 and scipy 1.18.1, which run every program in
#             the course.
#   written   every row of data. panela.py draws it from random.Random with
#             fixed seeds, so it is the same on every computer.
#
# NOT RUN HERE: Prophet, which lesson 3 describes and does not install (it
# fits with a separate engine, Stan), and R. The lessons say so where they
# name them.
#
#   sudo bash lab.sh up              create ana and ~/bi with panela.py only
#   sudo bash lab.sh ready           up, then the virtual environment and data
#                                    (what lesson 1 has the student do)
#   sudo bash lab.sh reset           remove everything in ~/bi except .venv
#                                    and panela.py, then rewrite the data
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/bi
#   sudo bash lab.sh down            remove ana and her home
#
# Recorded on Ubuntu 24.04 with Python 3.13, 4 cores, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BI=/home/ana/bi
PYLIBS="pandas==3.0.6 statsmodels==0.15.0 scikit-learn==1.9.1"
PAGE="$HERE/lessons/le-xsswhk80/the-data.md"

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
    LC_ALL=C.UTF-8 PYTHONHASHSEED=0 bash -c "cd $BI && $1"
}

# The first ```python fence of the-data.md is panela.py.
panela() {
  awk '/^```python$/ && !done {f=1; next} /^```$/ && f {f=0; done=1} f' "$PAGE"
}

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  install -d -o ana -g ana "$BI"
  panela > "$BI/panela.py"
  chown ana:ana "$BI/panela.py"
}

ready() {
  up
  if [ ! -x "$BI/.venv/bin/python" ]; then
    as_ana "python3 -m venv .venv && .venv/bin/pip install --quiet $PYLIBS"
  fi
  as_ana "python3 panela.py" >/dev/null
}

reset() {
  ready
  find "$BI" -mindepth 1 -maxdepth 1 ! -name .venv ! -name panela.py -exec rm -rf {} +
  as_ana "python3 panela.py" >/dev/null
}

case "${1:-}" in
  up) up ;;
  ready) ready ;;
  reset) reset ;;
  exec) shift; as_ana "$*" ;;
  down) id ana >/dev/null 2>&1 && userdel -r ana 2>/dev/null || true ;;
  *) echo "usage: lab.sh up|ready|reset|exec COMMAND|down" >&2; exit 2 ;;
esac
