#!/usr/bin/env bash
# The computer every transcript in delivery-metrics was recorded on.
#
# THE STUDENT NEVER SEES THIS FILE. Lesson 1 tells them to install Python 3,
# make a folder called `delivery` and save the program `billing.py` from the
# page into it; every later lesson prints the programs it runs, whole. This
# script builds the same thing for a user called ana, and the capture scripts
# beside each lesson read the programs OUT OF THE LESSON'S OWN PROSE (with
# lab/extract.py), so the program the course ran is the program the student
# saves.
#
# ONE PERSON AND ONE FOLDER. ana is a tech lead in training who is handed the
# Billing team's history: a team that does not exist, at a company that does
# not exist, simulated by billing.py with a fixed seed.
#
#   ~/delivery     the working folder; empty after `reset`
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      Python 3.13 and its standard library, which run every program
#             in the course. Nothing is installed with pip.
#   written   every row of data: items.csv and deploys.csv come from
#             billing.py; the smaller data sets of lessons 12 to 19 are
#             printed in the lessons themselves or made by a program they show.
#
#   sudo bash lab.sh up              create ana and ~/delivery (idempotent)
#   sudo bash lab.sh reset           empty ~/delivery
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/delivery
#   sudo bash lab.sh down            remove ana and her home
#
# Recorded on Linux with Python 3.13, TZ=America/Sao_Paulo.
set -euo pipefail

WORK=/home/ana/delivery
as_ana() {
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PATH=/usr/local/bin:/usr/bin:/bin \
    bash -c "cd $WORK && $1"
}

case "${1:-}" in
  up)
    id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
    install -d -o ana -g ana "$WORK"
    ;;
  reset)
    install -d -o ana -g ana "$WORK"
    find "$WORK" -mindepth 1 -delete
    ;;
  exec)
    as_ana "$2"
    ;;
  down)
    id ana >/dev/null 2>&1 && userdel -r ana 2>/dev/null || true
    ;;
  *)
    echo "usage: lab.sh up | reset | exec 'COMMAND' | down" >&2
    exit 2
    ;;
esac
