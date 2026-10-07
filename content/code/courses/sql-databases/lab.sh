#!/usr/bin/env bash
# The machine every transcript in sql-databases was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER AND ONE PERSON. ana is the student; her prompt is
# printed as ana@vm, the name the setup in lesson 1 gives the virtual machine
# it recommends. PostgreSQL 16 is Ubuntu's own package, in Ubuntu's own cluster
# (16/main, socket in /var/run/postgresql, log in /var/log/postgresql), which
# is what `sudo apt install postgresql` leaves on a student's machine.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16, and in lesson 12 MySQL 8.0, MariaDB 10.11 and
#             SQLite 3.45, all from Ubuntu's archive.
#   written   every row of data. The small shop is the script lesson 1 shows;
#             the large one is the generator lesson 9 shows. Each capture
#             script extracts those from the lesson's own .md and runs that,
#             so the file a student copies is the file that was run.
#
#   sudo bash lab.sh up                 install, create ana, start the cluster
#   sudo bash lab.sh fresh              drop the cluster and make it again, as
#                                       a new install leaves it (no role ana)
#   sudo bash lab.sh role               the setup's createuser, done quietly
#   sudo bash lab.sh exec 'COMMAND'     run COMMAND as ana, in ~
#   sudo bash lab.sh psql DB [ARGS]     an interactive psql as ana; lines on
#                                       stdin are typed at its prompt
#
# Recorded on Ubuntu 24.04, 4 cores, 15 GB of memory, TZ=UTC.
set -euo pipefail
exec 9>&-
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=UTC LC_ALL=C.UTF-8

as_ana() { runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana \
  PATH=/usr/local/bin:/usr/bin:/bin TZ=UTC LANG=C.UTF-8 LC_ALL=C.UTF-8 "$@"; }

start() { pg_ctlcluster 16 main start 2>/dev/null || true; }

case "${1:-}" in
  up)
    command -v psql >/dev/null || { apt-get update -q; apt-get install -y -q postgresql; }
    id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
    echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana
    pg_lsclusters -h | grep -q '^16 *main' || pg_createcluster 16 main >/dev/null
    start ;;
  fresh)
    pg_dropcluster --stop 16 main 2>/dev/null || true
    pg_createcluster 16 main >/dev/null
    start ;;
  role)
    start
    runuser -u postgres -- psql -qXc "DROP DATABASE IF EXISTS shop" >/dev/null
    runuser -u postgres -- psql -qXtc "SELECT 1 FROM pg_roles WHERE rolname='ana'" | grep -q 1 \
      || runuser -u postgres -- createuser --superuser ana ;;
  exec)
    shift; cd /home/ana; as_ana bash -c "$*" ;;
  psql)
    shift; cd /home/ana; as_ana python3 "$HERE/lab/session.py" "$@" ;;
  *) sed -n '2,30p' "$0"; exit 1 ;;
esac
