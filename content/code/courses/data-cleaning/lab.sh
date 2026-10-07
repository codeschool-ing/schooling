#!/usr/bin/env bash
# The machine every transcript in data-cleaning was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Quitanda Verde, an
# organic grocer that does not exist: five shops, in São Paulo, Campinas, Rio
# de Janeiro, Belo Horizonte and Curitiba, and a website and an app that
# deliver. In the first week of January 2026 she is handed what the company's
# systems export, and asked whether 2025 can be trusted. ~/clean is where she
# works, and the course cleans what is in it.
#
#   /var/lib/clean-data  the files, made once by lab/generate.py: raw/ is what
#                        the systems exported, ref/ is reference data from
#                        outside the company, truth/ says where every planted
#                        defect is, so a lesson can measure a technique
#   /var/lib/clean-pg    PostgreSQL 16, socket in /run/clean-pg, database
#                        `quitanda`, owned by ana; `reset` loads every raw file
#                        into the schema `raw`, every column as text
#                        (lab/raw.sql)
#   /opt/clean           Python 3 in a virtual environment with pandas,
#                        RapidFuzz and Matplotlib, pinned in PYLIBS
#   R 4.3 with dplyr, tidyr and readr, from Ubuntu's own packages, for the one
#                        lesson (16) that compares the tools
#   /home/ana/clean      the working directory, rebuilt by `reset`: raw/ and
#                        ref/ are copied in and raw/ is made read-only
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16, pandas 3.0, RapidFuzz, Matplotlib, R and dplyr,
#             which every command in the course runs on; the IBGE codes of the
#             27 federative units and of the five cities; the national
#             holidays and optional days of the federal calendar for 2025.
#   written   every person, order, product, price, sale, survey answer,
#             invoice, target and exchange rate. lab/generate.py draws them
#             from random.Random with fixed seeds, and plants the defects the
#             lessons find: duplicates exact and near, homonyms, NFD and
#             mangled accents, three date formats, a decimal comma, lost
#             leading zeros, a column where blank means zero, a timer that
#             stops at two hours, three repriced products listed twice, seven
#             totals typed with a zero too many, the corporate orders of
#             December, an account that cycles refunds, and the customers the
#             export is too old to know. The e-mail addresses are under the
#             domains reserved for examples.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: Microsoft Excel and Power Query.
# Lesson 16 shows what they do and says it was not run here.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/clean and reload `raw`
#   sudo bash lab.sh down            stop PostgreSQL
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/clean
#
# Recorded on Ubuntu 24.04 with Python 3.13, PostgreSQL 16 and R 4.3.3,
# 4 cores, TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=/opt/clean
DATA=/var/lib/clean-data
PGDATA=/var/lib/clean-pg
PGSOCK=/run/clean-pg
WORK=/home/ana/clean
PGBIN=/usr/lib/postgresql/16/bin
PYLIBS="pandas==3.0.6 numpy==2.5.3 rapidfuzz==3.14.6 matplotlib==3.11.2"
RPKGS="r-base-core r-cran-dplyr r-cran-tidyr r-cran-readr"

ENVFILE=/etc/clean.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:$PGBIN:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
PGHOST=$PGSOCK
PGDATABASE=quitanda
PAGER=cat
COLUMNS=100
EOF
}

as_ana() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat "$ENVFILE") bash -c "$1"
}

need() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  [ -x $PGBIN/initdb ] || {
    echo "PostgreSQL 16 is required: apt-get install postgresql-16" >&2; exit 1; }
  command -v Rscript >/dev/null || {
    echo "R is required for lesson 16: apt-get install $RPKGS" >&2; exit 1; }
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
}

build_venv() {
  [ -x $VENV/bin/python ] || python3 -m venv $VENV
  # shellcheck disable=SC2086
  $VENV/bin/pip install -q $PYLIBS
}

build_data() {
  if [ ! -f $DATA/.done ]; then
    rm -rf $DATA && mkdir -p $DATA
    python3 "$HERE/lab/generate.py" $DATA
    touch $DATA/.done
  fi
  chmod -R a+rX $DATA
}

pg_up() {
  mkdir -p $PGSOCK && chown ana $PGSOCK
  if [ ! -f $PGDATA/PG_VERSION ]; then
    mkdir -p $PGDATA && chown ana $PGDATA
    as_ana "initdb -D $PGDATA -U ana -A trust --encoding=UTF8 --locale=C.UTF-8 >/dev/null"
    cat >> $PGDATA/postgresql.conf <<EOF
listen_addresses = ''
unix_socket_directories = '$PGSOCK'
timezone = 'America/Sao_Paulo'
datestyle = 'iso, dmy'
jit = off
EOF
  fi
  as_ana "pg_ctl -D $PGDATA status >/dev/null 2>&1 || pg_ctl -D $PGDATA -l $PGDATA/server.log -w start >/dev/null"
}

reset() {
  rm -rf $WORK
  mkdir -p $WORK
  cp -r $DATA/raw $DATA/ref $WORK/
  chown -R ana:ana $WORK
  chmod -R a-w $WORK/raw
  as_ana "dropdb --maintenance-db=postgres --if-exists quitanda && createdb quitanda"
  as_ana "cd $WORK && psql -q -v ON_ERROR_STOP=1 -f '$HERE/lab/raw.sql'"
}

case "${1:-}" in
  up)
    need; build_user; write_env; build_venv; build_data; pg_up; reset ;;
  reset)
    pg_up; reset ;;
  down)
    as_ana "pg_ctl -D $PGDATA -m fast stop" || true ;;
  exec)
    as_ana "cd $WORK && $2" ;;
  *)
    echo "usage: lab.sh up | reset | down | exec 'COMMAND'" >&2; exit 2 ;;
esac
