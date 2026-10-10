#!/usr/bin/env bash
# The machine every transcript in db-reliability was recorded on.
#
# THE STUDENT NEVER RECEIVES THIS FILE. Lesson 1 tells them to build the same
# machine by hand: an Ubuntu 24.04 virtual machine, PostgreSQL 16 from
# Ubuntu's own packages, a role and a database of their own, and the shop
# database from the script that lesson shows whole. Later lessons install what
# they need (pgBackRest, Patroni, etcd, HAProxy, PgBouncer) with the commands
# they print. This script does the same steps, quietly, so that a capture can
# start from a known state; whatever a lesson's prose shows the student typing
# is typed again by that lesson's capture script, not done here.
#
# ONE COMPUTER, SEVERAL SERVERS. ana is the student; her prompt is printed as
# ana@vm. Every PostgreSQL server in the course is a cluster on this one
# machine, made with Ubuntu's pg_createcluster (16/main on 5432, and whatever a
# lesson adds on 5433 and up), or a node Patroni runs from ana's home. What a
# single machine cannot show, a real network partition between two hosts, is
# said in the lessons that need it.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16.15, pgBackRest 2.50, Patroni 3.2.2, etcd 3.4,
#             HAProxy 2.8 and PgBouncer 1.22, all from Ubuntu 24.04's archive;
#             PostgreSQL 17 in lesson 14 is the official image, run by Docker
#             from Ubuntu's docker.io package.
#   written   every row of data. The shop is the script lesson 1 shows; each
#             capture script extracts it from the lesson's .md (lab/fence.py)
#             and runs that, so the file a student copies is the file that ran.
#
# THERE IS NO systemd IN THE SANDBOX. Where a student's machine starts a
# service from its package (etcd), this script starts the same program with the
# same arguments the package's unit uses, and the lesson's header says so.
#
#   sudo bash lab.sh up                 install everything, create ana
#   sudo bash lab.sh fresh              stop every server, drop every cluster,
#                                       and leave 16/main as apt leaves it
#   sudo bash lab.sh base               fresh, then lesson 1's setup: role ana,
#                                       database shop loaded from shop.sql
#   sudo bash lab.sh exec 'COMMAND'     run COMMAND as ana, in ~
#   sudo bash lab.sh psql ARGS          an interactive psql as ana; lines on
#                                       stdin are typed at its prompt
#   sudo bash lab.sh etcd               start etcd as the package would
#
# Recorded on Ubuntu 24.04, 4 cores, 15 GB of memory, TZ=America/Sao_Paulo.
set -euo pipefail
exec 9>&-
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
L1="$HERE/lessons/le-5277pqzg"

as_ana() { runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 "$@"; }

stop_everything() {
  # Patroni first, or it restarts the servers it is told have stopped.
  pkill -u ana -f '/usr/bin/patroni' 2>/dev/null || true
  for _ in $(seq 1 30); do pgrep -u ana -f '/usr/bin/patroni' >/dev/null || break; sleep 1; done
  pkill -u ana -x postgres 2>/dev/null || true
  pkill -x etcd 2>/dev/null || true
  pkill -x haproxy 2>/dev/null || true
  pkill -x pgbouncer 2>/dev/null || true
  pkill -u ana -x pg_receivewal 2>/dev/null || true
  pkill -u ana -x pgbench 2>/dev/null || true
  if [ -S /var/run/docker.sock ]; then docker rm -f pg17 >/dev/null 2>&1 || true; fi
  for c in $(pg_lsclusters -h 2>/dev/null | awk '$1==16{print $2}'); do
    pg_dropcluster --stop 16 "$c" 2>/dev/null || true
  done
  rm -rf /var/lib/postgresql/16/* /var/log/postgresql/*
  rm -rf /var/lib/pgbackrest/* /var/log/pgbackrest/* /var/spool/pgbackrest /tmp/pgbackrest
  rm -rf /var/lib/etcd/default /var/lib/etcd/*
  printf '[demo]\npg1-path=/var/lib/postgresql/14/demo\n' > /etc/pgbackrest.conf
  rm -rf /etc/pgbackrest/conf.d/* 2>/dev/null || true
  rm -f /etc/pgbouncer/userlist.txt
  find /home/ana -mindepth 1 -maxdepth 1 ! -name '.bashrc' ! -name '.profile' ! -name '.bash_logout' -exec rm -rf {} +
}

case "${1:-}" in
  up)
    command -v psql >/dev/null || { apt-get update -q; apt-get install -y -q postgresql; }
    command -v pgbackrest >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
      pgbackrest pgbouncer patroni etcd-server etcd-client haproxy
    id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
    echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana
    # The package's own units would run these as their own users; nothing here
    # starts them until a lesson does.
    pg_lsclusters -h | grep -q '^16 *main' || pg_createcluster 16 main >/dev/null
    pg_ctlcluster 16 main start 2>/dev/null || true ;;
  fresh)
    stop_everything
    pg_createcluster 16 main >/dev/null
    pg_ctlcluster 16 main start ;;
  base)
    "$0" fresh
    runuser -u postgres -- createuser --superuser ana
    as_ana createdb shop
    python3 "$HERE/lab/fence.py" "$L1/installing.md" shop.sql > /home/ana/shop.sql
    chown ana: /home/ana/shop.sql
    (cd /home/ana && as_ana psql -qX -v ON_ERROR_STOP=1 shop -f shop.sql >/dev/null) ;;
  etcd)
    # /etc/default/etcd ships empty, so the unit runs `etcd` with no arguments
    # as the etcd user, in /var/lib/etcd: one member called `default`,
    # listening on localhost:2379.
    mkdir -p /var/lib/etcd; chown etcd: /var/lib/etcd
    (cd /var/lib/etcd && setsid runuser -u etcd -- /usr/bin/etcd >/var/log/etcd.log 2>&1 </dev/null &)
    for _ in $(seq 1 30); do etcdctl endpoint health >/dev/null 2>&1 && break; sleep 1; done ;;
  exec)
    shift; cd /home/ana; as_ana bash -c "$*" ;;
  psql)
    shift; cd /home/ana; as_ana python3 "$HERE/lab/session.py" "$@" ;;
  *) sed -n '2,45p' "$0"; exit 1 ;;
esac
