---
title: Dois scripts, um para montar e um para marcar o tempo
version: 1
---

**Dois dos quatro arquivos são scripts de shell, e os dois rodam com `sudo`.** O `setup.sh` monta a
máquina, uma vez. Ele instala o `shop.sh` como o comando `shop`, que é o que você vai digitar pelo
resto do curso sempre que a loja precisar viver mais um dia.

## setup.sh

Salve isto como `~/pontofinal/setup.sh`:

```bash
#!/usr/bin/env bash
# Build the machine this course runs on. Run it once, as ana, with sudo:
#
#   sudo bash ~/pontofinal/setup.sh
#
# from the directory that holds it beside shop.sh, shop.sql and generate.py.
# Running it again is safe: what is already there is kept, and it carries on
# from wherever it stopped.
#
#   /opt/etl            one virtual environment per tool, because Airflow, dbt,
#                       Prefect and Dagster each pin their own versions of the
#                       same libraries; /opt/etl/bin puts them on PATH
#   /etc/etl.env        the environment every command of the course runs in,
#                       read by ana's login shell
#   /usr/local/bin/shop the shop's clock and its services (shop.sh)
#   /var/lib/etl-data   the shop's three months of trade, drawn by generate.py
#   /var/lib/etl-pg     PostgreSQL 16, with the databases shop, wh and airflow
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPT=/opt/etl
PGBIN=/usr/lib/postgresql/16/bin
PY=python3.13
AIRFLOW=3.3.2
PY_LIBS="psycopg[binary]==3.3.6 requests==2.34.2 pytest==9.1.1 pyarrow==25.0.1"
DBT_LIBS="dbt-core==1.12.5 dbt-postgres==1.11.0"
ENVFILE=/etc/etl.env

[ "$(id -u)" = 0 ] || { echo "run it with sudo: sudo bash $0" >&2; exit 1; }
id ana >/dev/null 2>&1 || { echo "there is no user ana: sudo adduser ana" >&2; exit 1; }
for f in shop.sh shop.sql generate.py; do
  [ -f "$HERE/$f" ] || { echo "$HERE/$f is missing" >&2; exit 1; }
done
command -v $PY >/dev/null || { echo "Python 3.13 is required: apt-get install python3.13-venv" >&2; exit 1; }
for c in make git curl; do
  command -v $c >/dev/null || { echo "$c is required: apt-get install $c" >&2; exit 1; }
done
[ -x $PGBIN/initdb ] || { echo "PostgreSQL 16 is required: apt-get install postgresql-16" >&2; exit 1; }

venv() {  # venv NAME PACKAGES...
  local name=$1; shift
  [ -x $OPT/$name/bin/python ] || $PY -m venv $OPT/$name
  $OPT/$name/bin/pip install -q "$@"
}
mkdir -p $OPT/bin
# shellcheck disable=SC2086
venv py $PY_LIBS
# Airflow is installed against its own constraints file, as its documentation
# asks: without it pip resolves today's libraries, which Airflow never tested.
venv airflow "apache-airflow[postgres]==$AIRFLOW" graphviz \
  --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-$AIRFLOW/constraints-3.13.txt"
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
for t in airflow dbt luigi prefect dagster; do ln -sf $OPT/$t/bin/$t $OPT/bin/$t; done

# Airflow's processes sign the tokens tasks use to talk to its API with one
# shared secret. Left unset, each process invents its own and every task fails
# with "Invalid auth token". It is made once, here, and kept.
jwt=$(grep -s '^AIRFLOW__API_AUTH__JWT_SECRET=' "$ENVFILE" | cut -d= -f2- || true)
[ -n "$jwt" ] || jwt=$($PY -c 'import secrets; print(secrets.token_urlsafe(32))')
cat > "$ENVFILE" <<EOF
PATH=$OPT/bin:$PGBIN:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
PGHOST=/run/etl-pg
PGDATABASE=shop
PAGER=cat
AIRFLOW_HOME=/home/ana/airflow
AIRFLOW__CORE__DAGS_FOLDER=/home/ana/etl/dags
AIRFLOW__CORE__LOAD_EXAMPLES=False
AIRFLOW__CORE__EXECUTOR=LocalExecutor
AIRFLOW__CORE__DEFAULT_TIMEZONE=America/Sao_Paulo
AIRFLOW__CORE__SIMPLE_AUTH_MANAGER_ALL_ADMINS=True
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://ana@/airflow?host=/run/etl-pg
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
grep -qs 'etl.env' /home/ana/.profile ||
  echo 'set -a; . /etc/etl.env; set +a' >> /home/ana/.profile

install -m 755 "$HERE/shop.sh" /usr/local/bin/shop
if [ ! -f /var/lib/etl-data/.done ]; then
  rm -rf /var/lib/etl-data && mkdir -p /var/lib/etl-data
  $PY "$HERE/generate.py" /var/lib/etl-data
  touch /var/lib/etl-data/.done
fi
chmod -R a+rX /var/lib/etl-data
[ -f /var/lib/etl-run/clock ] || shop reset
echo "ready: log in again as ana, or run: . ~/.profile"
```

Ele confere antes de mudar qualquer coisa, e quando falta algo diz o que instalar; a seção sobre
falhas lista essas mensagens. Depois cria seis ambientes virtuais em `/opt/etl`, um por ferramenta,
com toda versão fixada, para as suas ferramentas serem as mesmas com que as transcrições foram
gravadas. **O Airflow é instalado contra o arquivo de restrições dele**, como a documentação pede,
porque sem isso o pip escolhe as bibliotecas de hoje e o Airflow foi testado com outras. Ele grava
o `/etc/etl.env`, o ambiente em que todo comando do curso roda, e acrescenta uma linha ao
`~/.profile` da `ana` para um shell de login lê-lo. Por último, instala o `shop`, sorteia os dados
da loja e os carrega.

## shop.sh

Salve isto como `~/pontofinal/shop.sh`:

```bash
#!/usr/bin/env bash
# The shop's clock and its services. setup.sh installs it as /usr/local/bin/shop,
# and ana runs it with sudo:
#
#   sudo shop start              start PostgreSQL, after a reboot
#   sudo shop reset              the shop back to the night of 28 February,
#                                ~/etl and the warehouse emptied, Airflow forgotten
#   sudo shop day DATE           play one day of March into the shop
#   sudo shop until DATE         play every day up to DATE
#   sudo shop api | api-down     start or stop the publishers' price API
#   sudo shop outage on|off      make the price API answer 503, or not
#   sudo shop airflow | airflow-down
#                                start or stop Airflow's four processes
#   sudo shop down               stop everything, the database included
#
# `day` and `until` also run as ana herself, without sudo, which is how a task
# in Airflow plays a day in lesson 9.
#
# TIME, WHICH NO COMPUTER PROVIDES. The shop's March has not happened when the
# machine is built. `shop day 2026-03-01` plays one day of it: every
# transaction the tills ran that day, in order, the website's event file and
# the distributor's stock file. A pipeline then has something new to find.
set -euo pipefail
# A server started from here must not inherit a lock or a pipe from whoever
# called it, or it holds that for as long as it lives.
exec 9>&-

SRC=/home/ana/pontofinal
DATA=/var/lib/etl-data
PGDATA=/var/lib/etl-pg
PGSOCK=/run/etl-pg
RUN=/var/lib/etl-run
ETL=/home/ana/etl
AFHOME=/home/ana/airflow
ENVFILE=/etc/etl.env
TABLES="shops books customers orders order_lines payments"

case "$(id -un):${1:-}" in
  root:*|ana:day|ana:until) ;;
  *) echo "run it with sudo: sudo shop ${*:-}" >&2; exit 1 ;;
esac
[ -f $ENVFILE ] || { echo "$ENVFILE is missing: run setup.sh first" >&2; exit 1; }

as_ana() {  # as_ana 'COMMAND' — as ana, in the course's environment
  # shellcheck disable=SC2046
  if [ "$(id -un)" = ana ]; then
    env -i HOME=/home/ana USER=ana $(cat $ENVFILE) bash -c "$1"
  else
    runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat $ENVFILE) bash -c "$1"
  fi
}

pg_up() {
  [ "$(id -u)" = 0 ] && mkdir -p $PGSOCK && chown ana $PGSOCK
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
  as_ana "dropdb --force --if-exists shop 2>/dev/null; createdb shop && psql -q -v ON_ERROR_STOP=1 -f '$SRC/shop.sql'"
  local t
  for t in $TABLES; do
    as_ana "psql -q -v ON_ERROR_STOP=1 -c \"\\copy $t FROM '$DATA/initial/$t.csv' WITH (FORMAT csv, HEADER true)\""
  done
  as_ana "psql -q -c 'VACUUM ANALYZE'"
}

stop_pid() {  # stop_pid NAME — the process started under that name, and
  local f=$RUN/$1.pid p      # everything it started: setsid made it the leader
  if [ -f "$f" ]; then       # of its own process group, and the group is stopped
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
  [ -f $SRC/prices_api.py ] || { echo "$SRC/prices_api.py is missing: lesson 3 writes it" >&2; exit 1; }
  mkdir -p /var/lib/etl-api && chown ana /var/lib/etl-api
  start_bg api /var/lib/etl-api/access.log "python3 $SRC/prices_api.py $DATA/prices.json 8081 $RUN/clock"
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
  [ -f $DATA/days/$d.sql ] || { echo "the shop's data ends on 2026-03-31" >&2; exit 1; }
  as_ana "psql -q -v ON_ERROR_STOP=1 -f $DATA/days/$d.sql >/dev/null
          mkdir -p $ETL/landing/events
          install -m 644 $DATA/events/$d.jsonl $ETL/landing/events/$d.jsonl
          install -m 644 $DATA/stock/$d.csv $ETL/inbox/stock_$d.csv
          echo $d > $RUN/clock"
}

case "${1:-}" in
  start)
    pg_up ;;
  reset)
    pg_up; reset ;;
  day)
    pg_up; day "$2" ;;
  until)
    pg_up
    while [ "$(cat $RUN/clock)" \< "$2" ]; do
      day "$(date -d "$(cat $RUN/clock) + 1 day" +%F)"; done ;;
  api) api_up ;;
  api-down) stop_pid api ;;
  outage)
    if [ "$2" = on ]; then touch /var/lib/etl-api/outage; else rm -f /var/lib/etl-api/outage; fi ;;
  airflow) pg_up; airflow_up ;;
  airflow-down) airflow_down ;;
  down)
    airflow_down; stop_pid api
    as_ana "pg_ctl -D $PGDATA -m fast stop" || true ;;
  *)
    echo "usage: shop start | reset | day DATE | until DATE | api | api-down |" >&2
    echo "       outage on|off | airflow | airflow-down | down" >&2
    exit 2 ;;
esac
```

**Todo verbo que ele conhece está listado no topo do arquivo.** Os que você vai usar mais são `day`
e `until`, que a seção sobre um dia de vendas mostra; `reset`, sempre que uma lição começa de uma
loja limpa; `api`, a partir da lição 3, que inicia a API de preços que aquela lição escreve; e
`airflow`, a partir da lição 8. O `shop down` para tudo, o PostgreSQL inclusive. Depois de
reiniciar a máquina nada está rodando, e `sudo shop start` traz o banco de volta.
