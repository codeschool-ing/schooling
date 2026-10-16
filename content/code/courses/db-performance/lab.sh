#!/usr/bin/env bash
# The machine every transcript in db-performance was recorded on.
#
# ONE UBUNTU 24.04 SERVER, called `vm`, with one user, ana. Lesson 1 tells the
# student to build theirs as a virtual machine and to install everything from
# Ubuntu's own archive with apt. This script builds the same server as a
# systemd-nspawn container, because the computer the course was recorded on
# could not run a hypervisor: the same release, the same packages at the same
# versions, booted by its own systemd, so `systemctl` and the PostgreSQL
# service behave as they do in a virtual machine. Its network is loopback
# only.
#
# WHAT IS IN IT
#   from Ubuntu's archive, installed with apt exactly as the lessons say:
#     postgresql (16), pgbouncer, redis-server, python3-psycopg, python3-redis
#   written for the course, and printed in full in the lessons, which is where
#   the student gets them (the student never receives this script):
#     market.sql     the course's database, lesson 1 section "Installing"
#     the workload   lesson 2's pgbench scripts
#   Each lesson's captures.sh takes those files out of the lesson's own .md
#   with lab/fence.py, so the file a student copies is the file that ran.
#
# WHAT IS STAGED, AND WHY
#   - ana may use sudo without a password, which a real server would not
#     allow. It keeps the transcripts free of password prompts.
#   - `market` is built once from market.sql, and lesson 1 has the student
#     copy it to `market_base`. `reset` is what the student's ~/reset-market.sh
#     (lesson 2) does: market again as a copy of market_base, plus lesson 2's
#     two additions, pg_stat_statements and orders_seller_id_idx. So every
#     lesson from 3 on starts where lesson 2 leaves the student, whatever the
#     lesson before it changed. `reset bare` is market_base alone, for lesson 2.
#   - `reset` also puts the server's configuration back as apt left it
#     (ALTER SYSTEM RESET ALL), with pg_stat_statements preloaded as lesson 2
#     sets it, and restarts. It removes ~/workload: a lesson that uses the
#     workload writes it again from lesson 2's a-workload.md. And it deletes
#     the statistics pg_stat_statements saved at the last shutdown, so every
#     lesson's counts start at zero, as they would on a server that ran nothing
#     else since the reset.
#
#   sudo bash lab.sh build          debootstrap the machine, install (once)
#   sudo bash lab.sh up             boot it
#   sudo bash lab.sh down
#   sudo bash lab.sh reset [bare]   market from market_base, as lesson 3 starts
#   sudo bash lab.sh as 'cmd'       run a command as ana, in ~, login shell
#   sudo bash lab.sh root 'cmd'     the same as root
#   sudo bash lab.sh psql DB [ARGS] an interactive psql as ana; lines on stdin
#                                   are typed at its prompt (lab/session.py)
#
# Recorded on Ubuntu 24.04, 4 processors, 15 GB of memory, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BASE=/var/lib/machines/vm
PIDFILE=/run/db-performance-lab.pid
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
export SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1 TZ=America/Sao_Paulo

PACKAGES="postgresql pgbouncer redis-server python3-psycopg python3-redis"

nspawn() { systemd-nspawn -q --register=no --keep-unit --timezone=off "$@"; }

leader() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 1
  pgrep -P "$p" -x systemd | head -1
}

in_vm() { local l; l=$(leader) || { echo "lab is not running" >&2; exit 1; }
  nsenter -t "$l" -a env -i TERM=dumb LANG=C.UTF-8 TZ=America/Sao_Paulo \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"; }

build() {
  if [ ! -x "$BASE/usr/bin/python3" ]; then
    rm -rf "$BASE"
    debootstrap --include=systemd,systemd-sysv,dbus,sudo,ca-certificates,iproute2,less,nano,python3,locales,tzdata,procps \
      noble "$BASE" "$MIRROR"
  fi
  printf 'deb %s noble main universe\ndeb %s noble-updates main universe\ndeb http://security.ubuntu.com/ubuntu noble-security main universe\n' \
    "$MIRROR" "$MIRROR" > "$BASE/etc/apt/sources.list"
  rm -f "$BASE/etc/resolv.conf"; cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  install -D -m 644 "$HERE/lab/session.py" "$BASE/usr/local/lib/lab/session.py"
  echo vm > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tvm\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  echo America/Sao_Paulo > "$BASE/etc/timezone"
  nspawn -D "$BASE" --pipe bash -c "
    set -e
    id ana >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash -G sudo ana
    echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana
    systemctl mask console-getty.service >/dev/null 2>&1 || true
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q && apt-get install -y -q $PACKAGES
    systemctl disable pgbouncer redis-server >/dev/null 2>&1 || true"
}

down() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 0
  rm -f "$PIDFILE"
  [ "$(cat /proc/"$p"/comm 2>/dev/null)" = systemd-nspawn ] || return 0
  kill "$p" 2>/dev/null || true
  for _ in $(seq 50); do kill -0 "$p" 2>/dev/null || break; sleep 0.2; done
}

up() {
  leader >/dev/null 2>&1 && return 0
  mountpoint -q /run/systemd/nspawn || { mkdir -p /run/systemd/nspawn; mount -t tmpfs tmpfs /run/systemd/nspawn; }
  setsid systemd-nspawn -q -b --console=passive --register=no --keep-unit \
    --private-network --timezone=off -D "$BASE" --machine vm </dev/null >/var/log/db-performance-lab.log 2>&1 &
  echo $! > "$PIDFILE"
  for _ in $(seq 100); do
    if leader >/dev/null && in_vm systemctl is-system-running --wait >/dev/null 2>&1; then break; fi
    sleep 0.3
  done
  in_vm systemctl is-system-running >/dev/null 2>&1 || in_vm systemctl --failed --no-pager || true
}

reset() { # $1 = bare: market_base exactly, configuration as apt left it (lesson 2)
  local extra=1; [ "${1:-}" = bare ] && extra=
  in_vm bash -c "
    runuser -u postgres -- psql -qXc 'ALTER SYSTEM RESET ALL' >/dev/null
    ${extra:+runuser -u postgres -- psql -qXc \"ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements'\" >/dev/null}
    systemctl stop postgresql@16-main
    rm -f /var/lib/postgresql/16/main/pg_stat/pg_stat_statements.stat
    systemctl start postgresql@16-main
    systemctl stop pgbouncer redis-server 2>/dev/null || true"
  # what ~/reset-market.sh does, lesson 2 section "Back to the known rows"
  in_vm su - ana -c "dropdb --if-exists market && createdb -T market_base market" >/dev/null
  [ -n "$extra" ] && in_vm su - ana -c "psql -qX market -c 'CREATE EXTENSION pg_stat_statements' -c 'CREATE INDEX orders_seller_id_idx ON orders (seller_id)'" >/dev/null
  in_vm su - ana -c "rm -rf ~/workload" ; return 0
}

case "${1:-}" in
  build) build ;;
  up) up ;;
  down) down ;;
  reset) reset "${2:-}" ;;
  as) shift; in_vm su - ana -c "$*" ;;
  root) shift; in_vm bash -lc "$*" ;;
  psql) shift; install -m 644 "$HERE/lab/session.py" "$BASE/usr/local/lib/lab/session.py"
        in_vm su - ana -c "python3 /usr/local/lib/lab/session.py $*" ;;
  *) sed -n '2,45p' "$0"; exit 2 ;;
esac
