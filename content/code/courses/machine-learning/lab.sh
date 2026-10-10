#!/usr/bin/env bash
# The computer every transcript in machine-learning was recorded on, built the
# way lesson 1 teaches a student to build theirs.
#
# THE STUDENT NEVER SEES THIS FILE. Lesson 1 gives them the commands (section
# `the-lab`) and the program that makes the data (section `your-data`). This
# script runs those same commands, read out of the lesson's own fences by
# lab/extract.py, so the requirements, the lines in ~/.bashrc and make_data.py
# are the bytes the student copies. It adds only what a script needs and a
# person does not: the user `ana`, and a way to run one command as her.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the first data scientist of Feira
# em Casa, a weekly box of fruit and vegetables that does not exist, sold by
# subscription in São Paulo, Campinas, Rio de Janeiro, Belo Horizonte and
# Curitiba. Everything she models comes out of make_data.py, which draws it
# from fixed seeds.
#
#   ~/ml                  the working directory: requirements.txt, make_data.py
#                         and the programs each lesson saves
#   ~/ml/.venv            Python 3.12 with the libraries requirements.txt pins
#   ~/ml/data             what `python make_data.py` writes
#
#   sudo bash lab.sh bare            ana and an empty ~/ml, nothing installed:
#                                    where lesson 1's transcripts start
#   sudo bash lab.sh up              bare, then everything lesson 1 does
#   sudo bash lab.sh reset           ~/ml back to what lesson 1 leaves
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/ml, in the shell
#                                    lesson 1's lines in ~/.bashrc make
#   sudo bash lab.sh put FILE        stdin into ~/ml/FILE, owned by ana
#   sudo bash lab.sh down            remove ana and her home
#
# Recorded on Ubuntu 24.04 with Python 3.12.3, 4 cores, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LESSON1=$HERE/lessons/le-m041efs1
EXTRACT="python3 $HERE/lab/extract.py"

# Ubuntu 24.04's python3 is 3.12. The machine this was recorded on has a 3.13
# installed as the default, so `python3` is pointed back at the stock
# interpreter, which is the one a student's fresh machine has.
STOCK=/usr/local/lib/ml-stock
mkdir -p $STOCK && ln -sfn /usr/bin/python3.12 $STOCK/python3

# pip reaches the Python Package Index. A network that inspects TLS hands pip
# its certificate in PIP_CERT; when that file is somewhere ana cannot read, a
# readable copy is made and named instead. Nothing else of the caller's
# environment reaches ana.
NET=""
if [ -n "${PIP_CERT:-}" ] && [ -f "$PIP_CERT" ]; then
  install -m 644 "$PIP_CERT" /usr/local/share/ml-lab-ca.pem
  NET="PIP_CERT=/usr/local/share/ml-lab-ca.pem"
fi
for v in HTTPS_PROXY https_proxy NO_PROXY no_proxy; do
  [ -n "${!v:-}" ] && NET="$NET $v=${!v}"
done

as_ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    LANG=C.UTF-8 COLUMNS=100 PATH=$STOCK:/usr/local/bin:/usr/bin:/bin $NET \
    bash -c 'eval "$(sed -n "/^# machine-learning$/,\$p" ~/.bashrc)"; cd ~/ml; '"$1"
}

bare() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  runuser -u ana -- mkdir -p /home/ana/ml
}

up() {
  bare
  $EXTRACT "$LESSON1/the-lab.md" requirements.txt | put requirements.txt
  $EXTRACT "$LESSON1/your-data.md" make_data.py | put make_data.py
  if ! grep -q '^# machine-learning$' /home/ana/.bashrc; then
    as_ana "$($EXTRACT "$LESSON1/the-lab.md" --with '# machine-learning')"
  fi
  as_ana '[ -x .venv/bin/python ] || python3 -m venv .venv'
  as_ana 'source .venv/bin/activate && pip install -q -r requirements.txt'
  as_ana '[ -d data ] || python make_data.py'
}

reset() {
  as_ana 'find . -mindepth 1 -maxdepth 1 ! -name .venv ! -name data ! -name requirements.txt ! -name make_data.py -exec rm -rf {} +'
}

put() {
  local f=/home/ana/ml/$1
  runuser -u ana -- mkdir -p "$(dirname "$f")"
  runuser -u ana -- tee "$f" >/dev/null
}

case "${1:-}" in
  bare) bare ;;
  up) up ;;
  reset) reset ;;
  exec) as_ana "$2" ;;
  put) put "$2" ;;
  down) userdel -r ana 2>/dev/null || true ;;
  *) echo "usage: lab.sh bare|up|reset|exec CMD|put FILE|down" >&2; exit 2 ;;
esac
