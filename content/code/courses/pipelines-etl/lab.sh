#!/usr/bin/env bash
# The machine every transcript in pipelines-etl was recorded on, built exactly
# the way lesson 1 teaches the student to build theirs. AUTHORING ONLY: the
# student never receives this file, and no lesson names it.
#
# ONE LINUX COMPUTER AND ONE PERSON. ana is the data analyst of Ponto Final,
# the chain of bookshops that does not exist from warehouse-modeling, and in
# this course she stops loading the warehouse by hand. ~/etl is her working
# directory.
#
# lab/student/ holds the six files the lessons show whole, byte for byte:
# setup.sh, shop.sh, shop.sql, generate.py and replay.py in lesson 1, and
# prices_api.py in lesson 3. `up` puts them where the lesson tells the student
# to put them, ~/pontofinal, and runs setup.sh as the lesson does. Every other
# verb is `shop`, the command setup.sh installs, so a capture that prints
# `sudo shop day 2026-03-02` ran exactly that.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16 and its logical decoding, Apache Airflow 3.3.2,
#             dbt-core 1.12.5 with dbt-postgres 1.11.0, Luigi 3.8.1,
#             Prefect 3.8.8 and Dagster 1.13.25, pinned in setup.sh.
#   written   every row of data, by generate.py, from fixed seeds; and
#             prices_api.py, the publishers' price API, a hundred lines of
#             Python that paginates, limits its rate and can be made to fail.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: Kafka, Debezium, any cloud warehouse
# and any managed Airflow. The lessons that name them show what they would
# do and say that it was not run here.
#
#   sudo bash lab.sh up              the student's lab, from lab/student/
#   sudo bash lab.sh exec 'COMMAND'  run COMMAND as ana, in ~/etl, in the
#                                    environment her login shell has
#   sudo bash lab.sh ARGS            sudo shop ARGS
#
# Recorded on Ubuntu 24.04 with Python 3.13 and PostgreSQL 16, 4 cores,
# TZ=America/Sao_Paulo.
set -euo pipefail
# The capture scripts hold a lock on fd 9 while they run. A server started
# here must not inherit it, or it holds the lock for as long as it lives.
exec 9>&-

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

as_ana() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat /etc/etl.env) bash -c "$1"
}

case "${1:-}" in
  up)
    # The student makes the user with `adduser`; here nobody types a password.
    id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
    rm -rf /home/ana/lab
    mkdir -p /home/ana/pontofinal
    cp "$HERE"/lab/student/* /home/ana/pontofinal/
    chown -R ana:ana /home/ana/pontofinal
    bash /home/ana/pontofinal/setup.sh ;;
  exec)
    as_ana "cd /home/ana/etl && $2" ;;
  "")
    echo "usage: lab.sh up | exec 'COMMAND' | any verb of shop" >&2; exit 2 ;;
  *)
    /usr/local/bin/shop "$@" ;;
esac
