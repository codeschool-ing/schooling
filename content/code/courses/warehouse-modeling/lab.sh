#!/usr/bin/env bash
# The machine every transcript in warehouse-modeling was recorded on.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Ponto Final, a
# chain of bookshops that does not exist: six shops in five Brazilian cities
# and a website. ~/wh is her working directory, and the course builds a data
# warehouse in it out of the shop's operational database.
#
# IT IS BUILT THE WAY LESSON 1 TELLS THE STUDENT TO BUILD THEIRS, and that is
# the point of it: Ubuntu's own PostgreSQL 16 cluster, 16/main, configured by
# the same four ALTER SYSTEM lines; the database `shop` made by the schema
# lesson 1 shows; the data written by the generator lesson 1 shows and loaded
# by its load.sh; DuckDB and the Python libraries in a virtual environment in
# ~/wh-env, at the versions lesson 1 pins.
#
#   /var/lib/wh-data   the generator's output, data/ and extracts/, made once
#                      and copied into ~/wh by `reset`, because it takes
#                      fifteen seconds and never changes
#   /home/ana/wh       the working directory, rebuilt by `reset`
#   /home/ana/wh-env   the virtual environment
#
# EVERY FILE IN lab/ IS SHOWN WHOLE IN A LESSON, and `check` fails on the
# first one that is not, byte for byte. `up`, `reset` and `warehouse` run it
# first, so a capture cannot be taken from a file the student has not been
# given. The table below says which lesson shows which file.
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
#             Python 3.12, the one Ubuntu 24.04 ships, and 3.13 write the same
#             bytes; that was compared, not assumed.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: BigQuery, Snowflake, Redshift and
# Databricks. Lessons 9 and 10 show their SQL and say that it was not run;
# what they run instead runs here, on DuckDB, and says so.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           rebuild ~/wh and the database `shop`
#   sudo bash lab.sh warehouse       build ~/wh/wh.duckdb with lesson 2's build.sh
#   sudo bash lab.sh wipe            undo what lesson 1 builds, so that it can
#                                    build it again on camera
#   sudo bash lab.sh check           every file in lab/ is shown in its lesson
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/wh
#
# Recorded on Ubuntu 24.04 with Python 3.12 and PostgreSQL 16, 4 cores,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. The server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=/home/ana/wh-env
DATA=/var/lib/wh-data
WH=/home/ana/wh
PYLIBS="duckdb==1.5.6 duckdb-cli==1.5.6 deltalake==1.6.6 pyarrow==25.0.1"

# The lesson that shows each file in lab/, by its directory under lessons/.
SHOWN="
oltp.sql                        le-104hb1qb
generate.py                     le-104hb1qb
load.sh                         le-104hb1qb
extract.sh                      le-t095sn5b
build.sh                        le-t095sn5b
warehouse/staging.sql           le-t095sn5b
warehouse/dim_date.sql          le-t095sn5b
warehouse/dim_shop.sql          le-t095sn5b
warehouse/dim_book.sql          le-t095sn5b
warehouse/dim_promotion.sql     le-t095sn5b
warehouse/dim_customer.sql      le-t095sn5b
warehouse/dim_author.sql        le-t095sn5b
warehouse/fact_sales.sql        le-t095sn5b
warehouse/fact_inventory.sql    le-t095sn5b
warehouse/fact_fulfilment.sql   le-t095sn5b
warehouse/fact_payments.sql     le-t095sn5b
warehouse/fact_event_attendance.sql le-t095sn5b
warehouse/dim_author.sql        le-rkw0xahw
warehouse/dim_customer.sql      le-6ez3jq9m
delta/write_sales.py            le-7e8gy455
delta/read_sales.py             le-7e8gy455
delta/history.py                le-7e8gy455
delta/bad_append.py             le-7e8gy455
delta/fix_line.py               le-7e8gy455
delta/vacuum.py                 le-7e8gy455
meta/sources.json               le-yec48gde
meta/gen_staging.py             le-yec48gde
meta/fact_sales.contract.json   le-yec48gde
meta/check_contract.py          le-yec48gde
catalog/comments.sql            le-zg1chrmr
catalog/classification.csv      le-zg1chrmr
catalog/check_docs.py           le-zg1chrmr
catalog/dictionary.py           le-zg1chrmr
"

check() {
  echo "$SHOWN" | python3 -I -c '
import glob, json, re, sys
here = sys.argv[1]
bad = 0
for line in sys.stdin.read().split("\n"):
    if not line.strip():
        continue
    name, lesson = line.split()
    want = open(f"{here}/lab/{name}", encoding="utf-8").read().rstrip("\n")
    shown = []
    for md in glob.glob(f"{here}/lessons/{lesson}/*.md"):
        if md.endswith(".pt.md"):
            continue
        text = open(md, encoding="utf-8").read()
        for lang, body in re.findall(r"^```(\S*)\n(.*?)\n```$", text, re.M | re.S):
            if lang == "schooling-example":
                body = "".join(p["code"] for p in json.loads(body)["parts"])
            shown.append(body.rstrip("\n"))
    if want not in shown:
        print(f"lab/{name} is not shown whole in lessons/{lesson}", file=sys.stderr)
        bad += 1
sys.exit(1 if bad else 0)
' "$HERE"
}

ENVFILE=/etc/wh.env
write_env() {
  cat > "$ENVFILE" <<EOF
PATH=$VENV/bin:/usr/local/bin:/usr/bin:/bin
TZ=America/Sao_Paulo
LANG=C.UTF-8
LC_ALL=C.UTF-8
PYTHONDONTWRITEBYTECODE=1
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
  pg_lsclusters -h 2>/dev/null | grep -q '^16 main ' || {
    echo "PostgreSQL 16 is required: apt-get install postgresql" >&2; exit 1; }
  python3 -c 'import ensurepip' 2>/dev/null || {
    echo "python3-venv is required: apt-get install python3-venv" >&2; exit 1; }
}

# ana may use sudo without a password, as the first user of an Ubuntu machine
# may with hers; lesson 1's transcripts type it.
build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  echo 'ana ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ana
  chmod 440 /etc/sudoers.d/ana
}

# python3.12 by name: it is what `python3` is on Ubuntu 24.04, and the
# recording machine's own python3 is a newer one the student does not have.
build_venv() {
  as_ana "[ -x $VENV/bin/python ] || python3.12 -m venv $VENV"
  as_ana "pip install -q $PYLIBS"
}

build_data() {
  if [ ! -f $DATA/.done ]; then
    rm -rf $DATA && mkdir -p $DATA
    (cd $DATA && python3 -I "$HERE/lab/generate.py")
    touch $DATA/.done
  fi
  chmod -R a+rX $DATA
}

# The cluster apt made, started the way systemd would start it in a virtual
# machine, with ana as a superuser and lesson 1's four settings.
pg_up() {
  pg_ctlcluster 16 main status >/dev/null 2>&1 || pg_ctlcluster 16 main start
  runuser -u postgres -- psql -tAqc "SELECT 1 FROM pg_roles WHERE rolname = 'ana'" | grep -q 1 ||
    runuser -u postgres -- createuser --superuser ana
  if [ "$(runuser -u postgres -- psql -tAqc 'SHOW jit')" != off ]; then
    runuser -u postgres -- psql -q \
      -c "ALTER SYSTEM SET timezone = 'America/Sao_Paulo'" \
      -c "ALTER SYSTEM SET shared_buffers = '512MB'" \
      -c "ALTER SYSTEM SET max_parallel_workers_per_gather = 0" \
      -c "ALTER SYSTEM SET jit = off"
    pg_ctlcluster 16 main restart
  fi
}

load_shop() {
  as_ana "dropdb --if-exists shop && createdb --locale=C.UTF-8 --template=template0 shop"
  as_ana "psql -q -v ON_ERROR_STOP=1 -f '$HERE/lab/oltp.sql'"
  as_ana "cd $DATA && sh '$HERE/lab/load.sh'"
}

reset() {
  rm -rf $WH
  mkdir -p $WH
  cp -r $DATA/extracts $WH/
  chown -R ana:ana $WH
  load_shop
}

# The warehouse lesson 2 ends by building: its build.sh, run on the files it
# names, which lessons 2, 4 and 5 show.
warehouse() {
  cp "$HERE/lab/extract.sh" "$HERE/lab/build.sh" "$HERE"/lab/warehouse/*.sql $WH/
  chown ana:ana $WH/*.sh $WH/*.sql
  as_ana "cd $WH && sh build.sh >/dev/null"
}

# Back to the machine as apt left it, so that lesson 1 can build the rest on
# camera: no role ana, no database `shop`, none of the four settings, and an
# empty ~/wh, which is what the student's `mkdir ~/wh` makes. The cluster is
# left STOPPED, as apt leaves it where nothing starts services at boot: WSL
# without systemd, and the container this course was recorded in.
wipe() {
  as_ana "dropdb --if-exists shop" 2>/dev/null || true
  runuser -u postgres -- dropuser --if-exists ana
  runuser -u postgres -- psql -q -c "ALTER SYSTEM RESET ALL"
  pg_ctlcluster 16 main stop
  rm -rf $WH
  install -d -o ana -g ana $WH
}

case "${1:-}" in
  up)
    check; need; build_user; write_env; build_venv; build_data; pg_up; reset ;;
  reset)
    check; pg_up; reset ;;
  warehouse)
    check; warehouse ;;
  wipe)
    wipe ;;
  check)
    check ;;
  exec)
    as_ana "cd $WH && $2" ;;
  *)
    echo "usage: lab.sh up | reset | warehouse | wipe | check | exec 'COMMAND'" >&2; exit 2 ;;
esac
