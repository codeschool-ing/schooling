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
