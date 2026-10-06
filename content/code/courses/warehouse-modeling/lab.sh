#!/usr/bin/env bash
# The machine every transcript in warehouse-modeling was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Ponto Final, a
# chain of bookshops that does not exist: six shops in five Brazilian cities
# and a website. ~/wh is her working directory, and the course builds a data
# warehouse in it out of the shop's operational database.
#
#   /var/lib/wh-pg     PostgreSQL 16, socket in /run/wh-pg, database `shop`,
#                      owned by ana: the operational database the tills and
#                      the website write to (lab/oltp.sql), loaded from the
#                      generated files
#   /var/lib/wh-data   those files, one CSV per table, made once by
#                      lab/generate.py, plus three monthly customer extracts
#   /opt/wh            Python 3 in a virtual environment with the DuckDB
#                      command-line shell and library, and the deltalake
#                      library (delta-rs), pinned in PYLIBS
#   /home/ana/wh       the working directory, rebuilt by `reset`; the
#                      extracts are copied into ~/wh/extracts
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16 and DuckDB 1.5.6, which every query in the course
#             runs on; delta-rs, which writes and reads the Delta tables of
#             lesson 10; Apache Parquet, written by DuckDB.
#   written   every row of data. lab/generate.py draws two years of trade,
#             2024-01-01 to 2025-12-31, from random.Random with fixed seeds:
#             3,000 books by 1,800 authors, 40,000 customers, about 577,000
#             orders and 895,000 order lines, month-end stock counts and 120
#             author events. The names come from word lists, the ISBNs are
#             made with a valid check digit and looked up nowhere, and the
#             e-mail addresses are under the domains reserved for examples.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: BigQuery, Snowflake, Redshift and
# Databricks. Lessons 9 and 10 show their SQL and say that it was not run;
# what they run instead runs here, on DuckDB, and says so.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/wh and the database `shop`
#   sudo bash lab.sh warehouse       build ~/wh/wh.duckdb from lab/warehouse/
#   sudo bash lab.sh down            stop PostgreSQL
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/wh
#
# Recorded on Ubuntu 24.04 with Python 3.13 and PostgreSQL 16, 4 cores,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=/opt/wh
DATA=/var/lib/wh-data
PGDATA=/var/lib/wh-pg
PGSOCK=/run/wh-pg
WH=/home/ana/wh
PGBIN=/usr/lib/postgresql/16/bin
PYLIBS="duckdb==1.5.6 duckdb-cli==1.5.6 deltalake==1.6.6 pyarrow==25.0.1"
TABLES="shops categories publishers authors books book_authors customers
  customer_changes promotions orders order_lines payments stock_counts events
  event_attendance"

ENVFILE=/etc/wh.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:$PGBIN:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
PGHOST=$PGSOCK
PGDATABASE=shop
PAGER=cat
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
shared_buffers = 512MB
max_parallel_workers_per_gather = 0
jit = off
EOF
  fi
  as_ana "pg_ctl -D $PGDATA status >/dev/null 2>&1 || pg_ctl -D $PGDATA -l $PGDATA/server.log -w start >/dev/null"
}

load_shop() {
  as_ana "dropdb --if-exists shop 2>/dev/null; createdb shop && psql -q -v ON_ERROR_STOP=1 -f '$HERE/lab/oltp.sql'"
  local t
  for t in $TABLES; do
    as_ana "psql -q -v ON_ERROR_STOP=1 -c \"\\copy $t FROM '$DATA/$t.csv' WITH (FORMAT csv, HEADER true)\""
  done
  as_ana "psql -q -c 'VACUUM ANALYZE'"
}

reset() {
  rm -rf $WH
  mkdir -p $WH/extracts
  cp $DATA/customers_2025-*.csv $WH/extracts/
  chown -R ana:ana $WH
  load_shop
}

# The warehouse lessons 2 to 5 build, ready-made for the lessons after them:
# the extract of lesson 2, then every file in lab/warehouse in order.
warehouse() {
  as_ana "cd $WH && rm -rf extract wh.duckdb wh.duckdb.wal && sh '$HERE/lab/extract.sh'"
  local f
  for f in "$HERE"/lab/warehouse/*.sql; do
    as_ana "cd $WH && duckdb wh.duckdb < '$f' >/dev/null"
  done
}

case "${1:-}" in
  up)
    need; build_user; write_env; build_venv; build_data; pg_up; reset ;;
  reset)
    pg_up; reset ;;
  warehouse)
    warehouse ;;
  down)
    as_ana "pg_ctl -D $PGDATA -m fast stop" || true ;;
  exec)
    as_ana "cd $WH && $2" ;;
  *)
    echo "usage: lab.sh up | reset | warehouse | down | exec 'COMMAND'" >&2; exit 2 ;;
esac
