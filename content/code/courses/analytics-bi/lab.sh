#!/usr/bin/env bash
# The machine every transcript in analytics-bi was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER AND ONE PERSON. ana is the student; her prompt is
# printed as ana@vm, the name lesson 1 gives the virtual machine it recommends
# (the same machine sql-databases builds). PostgreSQL 16 is Ubuntu's own
# package in Ubuntu's own cluster, which is what `sudo apt install postgresql`
# leaves on a student's machine. The machine's clock is UTC, as the Ubuntu
# Server installer leaves it; the shop's database is told it lives in São
# Paulo by the ALTER DATABASE line lesson 1 shows, so every timestamp prints
# the same on the student's machine whatever its clock says.
#
# WHAT IS REAL AND WHAT WAS WRITTEN FOR THE COURSE.
#
#   real      PostgreSQL 16 and Python 3.12 from Ubuntu's archive; Metabase
#             from its official container image (lesson 3), run by Docker;
#             Streamlit from PyPI in a virtual environment (lesson 5).
#   written   every row of the shop. lantern.sql is the script lesson 1 shows,
#             and each capture script takes it out of the lesson's own .md and
#             runs that, so the file a student copies is the file that was run.
#             The little CRM of lesson 7 is a program lesson 7 shows whole, and
#             is taken out of its .md the same way.
#
#   sudo bash lab.sh up               install, create ana, start the cluster
#   sudo bash lab.sh fresh            drop the cluster and make it again, as a
#                                     new install leaves it (no role ana)
#   sudo bash lab.sh role             createuser ana, quietly
#   sudo bash lab.sh shop             role, then create lantern and load
#                                     lantern.sql out of lesson 1, quietly
#   sudo bash lab.sh exec 'COMMAND'   run COMMAND as ana, in ~
#   sudo bash lab.sh psql DB [ARGS]   an interactive psql as ana; lines on
#                                     stdin are typed at its prompt
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, in October 2026.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export TZ=UTC LC_ALL=C.UTF-8
L1="$HERE/lessons/le-0wmh3j1s"

as_ana() { runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana \
  PATH=/usr/local/bin:/usr/bin:/bin TZ=UTC LANG=C.UTF-8 LC_ALL=C.UTF-8 "$@"; }

start() { pg_ctlcluster 16 main start 2>/dev/null || true; }

role() {
  start
  runuser -u postgres -- psql -qXtc "SELECT 1 FROM pg_roles WHERE rolname='ana'" | grep -q 1 \
    || runuser -u postgres -- createuser --superuser ana
}

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
    role ;;
  shop)
    role
    cd /home/ana
    as_ana dropdb --if-exists lantern
    as_ana createdb lantern
    python3 "$HERE/lab/fence.py" "$L1/setting-up.md" '-- lantern.sql' > /tmp/lantern.sql
    chmod 644 /tmp/lantern.sql
    as_ana psql -qX -v ON_ERROR_STOP=1 lantern -f /tmp/lantern.sql >/dev/null
    python3 "$HERE/lab/fence.py" "$L1/setting-up.md" 'ALTER DATABASE lantern' \
      | as_ana psql -qX -v ON_ERROR_STOP=1 lantern >/dev/null ;;
  exec)
    shift; cd /home/ana; as_ana bash -c "$*" ;;
  psql)
    shift; cd /home/ana; as_ana python3 "$HERE/lab/session.py" "$@" ;;
  *) sed -n '2,33p' "$0"; exit 1 ;;
esac
