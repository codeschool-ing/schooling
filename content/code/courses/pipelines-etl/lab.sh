#!/usr/bin/env bash
# The machine every transcript in pipelines-etl was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Ponto Final,
# the chain of bookshops that does not exist from warehouse-modeling, and in
# this course she stops loading the warehouse by hand. ~/etl is her working
# directory.
#
#   /var/lib/etl-pg    PostgreSQL 16, socket in /run/etl-pg, wal_level=logical,
#                      three databases owned by ana:
#                        shop     the operational database the tills and the
#                                 website write to (lab/shop.sql)
#                        wh       the warehouse, which the course's pipelines
#                                 fill and nothing else writes
#                        airflow  Airflow's own metadata
#   /var/lib/etl-data  what lab/generate.py drew: the shop as of the night of
#                      28 February 2026, and every day of March as the SQL
#                      the tills ran, the website's events and the
#                      distributor's stock file
#   /opt/etl           one virtual environment per tool, because Airflow,
#                      dbt, Prefect and Dagster each pin their own versions of
#                      the same libraries; /opt/etl/bin puts them on PATH
#   /home/ana/etl      the working directory, rebuilt by `reset`:
#                        dags/      Airflow's DAG folder
#                        landing/   files as they arrive, untouched
#                        inbox/     where the distributor drops its stock file
#   /home/ana/airflow  AIRFLOW_HOME: its configuration and its task logs
#
# TIME, WHICH NO SANDBOX PROVIDES. The shop's March has not happened yet when
# the lab is built. `lab.sh day 2026-03-01` plays one day of it: every
# transaction the tills ran that day, in order, the website's event file and
# the stock file. A pipeline then has something new to find. Airflow's own
# clock is the logical date of each run, which the course sets when it runs a
# DAG, so a month of schedule can be lived in a few minutes and the next day
# arrives when the student says so.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16 and its logical decoding, Apache Airflow 3.3.2,
#             dbt-core 1.12.5 with dbt-postgres 1.11.0, Luigi 3.8.1,
#             Prefect 3.8.8 and Dagster 1.13.25, pinned below.
#   written   every row of data, by lab/generate.py, from fixed seeds; and
#             lab/api.py, the publishers' price API, a hundred lines of
#             Python that paginates, limits its rate and can be made to fail.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: Kafka, Debezium, any cloud warehouse
# and any managed Airflow. The lessons that name them show what they would
# do and say that it was not run here.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           the shop back to 28 February, ~/etl and
#                                    the warehouse emptied, Airflow forgotten
#   sudo bash lab.sh day DATE        play one day of March into the shop
#   sudo bash lab.sh until DATE      play every day up to DATE
#   sudo bash lab.sh api | api-down  start or stop the price API
#   sudo bash lab.sh outage on|off   make the price API answer 503, or not
#   sudo bash lab.sh airflow | airflow-down
#                                    start or stop Airflow's four processes
#   sudo bash lab.sh down            stop everything
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/etl
#
# Recorded on Ubuntu 24.04 with Python 3.13 and PostgreSQL 16, 4 cores,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. A server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPT=/opt/etl
DATA=/var/lib/etl-data
PGDATA=/var/lib/etl-pg
PGSOCK=/run/etl-pg
RUN=/var/lib/etl-run
ETL=/home/ana/etl
AFHOME=/home/ana/airflow
PGBIN=/usr/lib/postgresql/16/bin
AIRFLOW=3.3.2
PYV=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
PY_LIBS="psycopg[binary]==3.3.6 requests==2.34.2 pytest==9.1.1 pyarrow==25.0.1"
DBT_LIBS="dbt-core==1.12.5 dbt-postgres==1.11.0"
TABLES="shops books customers orders order_lines payments"

ENVFILE=/etc/etl.env
write_env() {
  # Airflow's processes sign the tokens tasks use to talk to its API with one
  # shared secret. Left unset, each process invents its own and every task
  # fails with "Invalid auth token". It is made once, here, and kept.
  local jwt
  jwt=$(grep -s '^AIRFLOW__API_AUTH__JWT_SECRET=' "$ENVFILE" | cut -d= -f2- || true)
  [ -n "$jwt" ] || jwt=$(python3 -c 'import secrets; print(secrets.token_urlsafe(32))')
  cat > "$ENVFILE" <<EOF
PATH=$OPT/bin:$PGBIN:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
PGHOST=$PGSOCK
PGDATABASE=shop
PAGER=cat
AIRFLOW_HOME=$AFHOME
AIRFLOW__CORE__DAGS_FOLDER=$ETL/dags
AIRFLOW__CORE__LOAD_EXAMPLES=False
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW__CORE__DEFAULT_TIMEZONE=America/Sao_Paulo
AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=True
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://ana@/airflow?host=$PGSOCK
AIRFLOW__DAG_PROCESSOR__REFRESH_INTERVAL=10
AIRFLOW__SCHEDULER__ENABLE_HEALTH_CHECK=False
AIRFLOW__API__PORT=8080
AIRFLOW__API__HOST=127.0.0.1
AIRFLOW__API_AUTH__JWT_SECRET=$jwt

AIRFLOW__LOGGING__COLORED_CONSOLE_LOG=False
AIRFLOW_CONN_SHOP=postgresql://ana@%2Frun%2Fetl-pg/shop
AIRFLOW_CONN_WH=postgresql://ana@%2Frun%2Fetl-pg/wh
PRICES_API_KEY=ponto-final-lab
EOF
}

as_ana() {
  # shellcheck disable=SC2046
  if [ "$(id -un)" = ana ]; then   # `day` and `until` may be run by ana herself
    env -i HOME=/home/ana USER=ana $(cat "$ENVFILE") bash -c "$1"
  else
    runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat "$ENVFILE") bash -c "$1"
  fi
}

need() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
  command -v make >/dev/null || { echo "make is required: apt-get install make" >&2; exit 1; }
  command -v git >/dev/null || { echo "git is required: apt-get install git" >&2; exit 1; }
  [ -x $PGBIN/initdb ] || {
    echo "PostgreSQL 16 is required: apt-get install postgresql-16" >&2; exit 1; }
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
}

venv() {  # venv NAME PACKAGES... — one environment per tool
  local name=$1; shift
  [ -x $OPT/$name/bin/python ] || python3 -m venv $OPT/$name
  $OPT/$name/bin/pip install -q "$@"
}

build_tools() {
  mkdir -p $OPT/bin
  # shellcheck disable=SC2086
  venv py $PY_LIBS
  # Airflow is installed against its own constraints file, as its documentation
  # asks: without it pip resolves today's libraries, which Airflow never tested.
  venv airflow "apache-airflow[postgres]==$AIRFLOW" graphviz \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-$AIRFLOW/constraints-$PYV.txt"
  # shellcheck disable=SC2086
  venv dbt $DBT_LIBS
  venv luigi luigi==3.8.1
  venv prefect prefect==3.8.8
  venv dagster dagster==1.13.25 dagster-webserver==1.13.25
  # A symlink to a virtual environment's python does not find the environment,
  # because Python looks for it beside the name it was started by.
  rm -f $OPT/bin/python
  printf '#!/bin/sh\nexec %s "$@"\n' $OPT/py/bin/python > $OPT/bin/python
  chmod 755 $OPT/bin/python
  ln -sf $OPT/py/bin/pytest $OPT/bin/pytest
  ln -sf $OPT/airflow/bin/airflow $OPT/bin/airflow
  ln -sf $OPT/dbt/bin/dbt $OPT/bin/dbt
  ln -sf $OPT/luigi/bin/luigi $OPT/bin/luigi
  ln -sf $OPT/prefect/bin/prefect $OPT/bin/prefect
  ln -sf $OPT/dagster/bin/dagster $OPT/bin/dagster
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
wal_level = logical
max_replication_slots = 8
max_connections = 200
shared_buffers = 256MB
jit = off
EOF
  fi
  as_ana "pg_ctl -D $PGDATA status >/dev/null 2>&1 || pg_ctl -D $PGDATA -l $PGDATA/server.log -w start >/dev/null"
}

load_shop() {
  as_ana "dropdb --force --if-exists shop 2>/dev/null; createdb shop && psql -q -v ON_ERROR_STOP=1 -f '$HERE/lab/shop.sql'"
  local t
  for t in $TABLES; do
    as_ana "psql -q -v ON_ERROR_STOP=1 -c \"\\copy $t FROM '$DATA/initial/$t.csv' WITH (FORMAT csv, HEADER true)\""
  done
  as_ana "psql -q -c 'VACUUM ANALYZE'"
}

stop_pid() {  # stop_pid NAME — the process lab.sh started under that name, and
  local f=$RUN/$1.pid p      # everything it started: setsid made it the leader
  if [ -f "$f" ]; then       # of its own process group, and the group is killed
    p=$(cat "$f")
    kill -TERM -- "-$p" 2>/dev/null || true
    for _ in $(seq 50); do kill -0 -- "-$p" 2>/dev/null || break; sleep 0.2; done
    kill -KILL -- "-$p" 2>/dev/null || true
    rm -f "$f"
  fi
}

start_bg() {  # start_bg NAME LOG 'COMMAND' — as ana, in its own session
  mkdir -p $RUN && chown ana $RUN
  stop_pid "$1"
    as_ana "cd $ETL; setsid $3 </dev/null >>$2 2>&1 & echo \$! > $RUN/$1.pid"
}

api_up() {
  mkdir -p /var/lib/etl-api && chown ana /var/lib/etl-api
  start_bg api /var/lib/etl-api/access.log "python3 $HERE/lab/api.py $DATA/prices.json 8081 $RUN/clock"
    for _ in $(seq 50); do
    kill -0 "$(cat $RUN/api.pid)" 2>/dev/null || break
    curl -s -o /dev/null http://127.0.0.1:8081/ && return 0; sleep 0.1; done
  echo "the price API did not start: see /var/lib/etl-api/access.log" >&2
  return 1
}

airflow_up() {
  as_ana "airflow db migrate >/dev/null 2>&1"
  local p
  for p in scheduler dag-processor triggerer api-server; do
    start_bg "airflow-$p" "$AFHOME/$p.log" "airflow $p"
  done
  for _ in $(seq 120); do
    curl -s -o /dev/null http://127.0.0.1:8080/api/v2/version && return 0; sleep 0.5; done
  echo "the Airflow API server did not answer in a minute: see $AFHOME/api-server.log" >&2
  return 1
}

airflow_down() {
  local p
  for p in api-server triggerer dag-processor scheduler; do stop_pid "airflow-$p"; done
}

reset() {
  airflow_down
  rm -f /var/lib/etl-api/outage
  as_ana "psql -q -d postgres -tc \"SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots\" >/dev/null"
  rm -rf $ETL $AFHOME
  mkdir -p $ETL/dags $ETL/landing $ETL/inbox $AFHOME
  chown -R ana:ana $ETL $AFHOME
  load_shop
    as_ana "psql -q -d postgres -c 'SET client_min_messages = warning' -c 'DROP ROLE IF EXISTS etl_reader'"
  as_ana "dropdb --force --if-exists wh 2>/dev/null; createdb wh; dropdb --force --if-exists airflow 2>/dev/null; createdb airflow"
  mkdir -p $RUN && chown ana $RUN
  echo 2026-02-28 > $RUN/clock && chown ana $RUN/clock
}

day() {
  local d=$1 last next
  last=$(cat $RUN/clock)
  next=$(date -d "$last + 1 day" +%F)
  if [ "$d" != "$next" ]; then
    echo "the shop has lived up to $last: the next day to play is $next" >&2; exit 1
  fi
  [ -f $DATA/days/$d.sql ] || { echo "the lab's data ends on 2026-03-31" >&2; exit 1; }
  as_ana "psql -q -v ON_ERROR_STOP=1 -f $DATA/days/$d.sql >/dev/null
          mkdir -p $ETL/landing/events
          install -m 644 $DATA/events/$d.jsonl $ETL/landing/events/$d.jsonl
          install -m 644 $DATA/stock/$d.csv $ETL/inbox/stock_$d.csv
          echo $d > $RUN/clock"
}

case "${1:-}" in
  up)
    need; build_user; write_env; build_tools; build_data; pg_up
    # a copy of the lab where ana can read it, and run it with sudo
    rm -rf /home/ana/lab && mkdir -p /home/ana/lab
    cp -r "$HERE/lab.sh" "$HERE/lab" /home/ana/lab/ && chown -R ana:ana /home/ana/lab
    mkdir -p $RUN; [ -f $RUN/clock ] || reset ;;
  reset)
    pg_up; reset ;;
  day)
    day "$2" ;;
  until)
    while [ "$(cat $RUN/clock)" \< "$2" ]; do
      day "$(date -d "$(cat $RUN/clock) + 1 day" +%F)"; done ;;
  api) api_up ;;
  api-down) stop_pid api ;;
  outage)
    if [ "$2" = on ]; then touch /var/lib/etl-api/outage; else rm -f /var/lib/etl-api/outage; fi ;;
  airflow) airflow_up ;;
  airflow-down) airflow_down ;;
  down)
    airflow_down; stop_pid api
    as_ana "pg_ctl -D $PGDATA -m fast stop" || true ;;
  exec)
    as_ana "cd $ETL && $2" ;;
  *)
    echo "usage: lab.sh up | reset | day DATE | until DATE | api | api-down |" >&2
    echo "       outage on|off | airflow | airflow-down | down | exec 'COMMAND'" >&2
    exit 2 ;;
esac
