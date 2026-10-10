#!/usr/bin/env bash
# The machine every transcript in db-administration was recorded on.
#
# IT IS ONE UBUNTU 24.04 SERVER, called `db`, with one user, ana. Lesson 3
# tells the student to build theirs as a virtual machine and to install
# PostgreSQL 16 from Ubuntu's own archive with apt. This script builds the
# same server as a systemd-nspawn container, because the computer the course
# was recorded on could not run a hypervisor: the same release, the same
# packages at the same versions, booted by its own systemd, so `systemctl`,
# `journalctl`, the cluster's unit and its log behave as they do in a virtual
# machine. It has a network of its own with only loopback in it, so nothing
# it serves is reachable from anywhere else.
#
# The student never receives this file, the lessons' captures.sh, or lab/.
# Everything a lesson asks the student to run is printed in that lesson.
#
# WHAT IS IN IT
#   from Ubuntu's archive, with apt, as the lessons say:
#     postgresql (16), postgresql-16-postgis-3, postgresql-16-repack,
#     mysql-server-8.0, pgloader
#   written for the course and printed in the lessons, extracted from the
#   lesson's own .md by lab/fence.py so the file a student copies is the file
#   that ran:
#     shop.sql      lesson 4's generator for the course's database
#     every configuration file and script a lesson shows
#
# WHAT IS STAGED, AND WHY
#   - THE MACHINE HAS NO NETWORK. Every package the course installs was
#     downloaded into apt's cache while the machine was built, so `apt
#     install` works offline and prints no download lines. The lessons show
#     apt commands as commands and quote none of apt's output.
#   - PostgreSQL 16.2, the version noble was released with, is also in the
#     cache, because lesson 20 performs a minor upgrade from it to the current
#     16.15 and needs both.
#   - PostgreSQL 17 is NOT in Ubuntu 24.04's archive; lesson 20 tells the
#     student to add the PostgreSQL project's apt repository (PGDG) for it.
#     That repository was not reachable from the recording computer, so the
#     17 used for lesson 20's captures was built from the source tarball of
#     Ubuntu's own postgresql-17 package (17.10) and installed into the paths
#     the PGDG package uses (/usr/lib/postgresql/17, /usr/share/postgresql/17),
#     where postgresql-common's tools find it. Lesson 20 says the repository
#     step was not run here.
#   - ana may use sudo without a password, which a real server would not
#     allow. It keeps the transcripts free of password prompts.
#   - The recording computer had 4 processors and 15 GB of memory, and a
#     container sees all of it; the virtual machine lesson 3 recommends has 2
#     and 4 GB. Lessons that size anything from the memory say both.
#   - TZ=America/Sao_Paulo, and every row of the course's data carries a
#     fixed date, so what a query prints is the same on every run. The times
#     in log lines and the process ids are not: they are the clock and the
#     kernel.
#
#   sudo bash lab.sh build          debootstrap the server and download every
#                                   package into its cache (once)
#   sudo bash lab.sh reset [N]      a fresh copy of the server, booted, in the
#                                   state lesson N starts from
#   sudo bash lab.sh as 'cmd'       run a command as ana, in /home/ana, in a
#                                   login shell
#   sudo bash lab.sh root 'cmd'     the same as root
#   sudo bash lab.sh psql DB [ARGS] an interactive psql as ana; lines on stdin
#                                   are typed at its prompt (lab/session.py)
#   sudo bash lab.sh down
#
# LAB_NAME=other runs a second, independent machine beside the first.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NAME=${LAB_NAME:-db}
BASE=/var/lib/machines/dba-base
PGBASE=/var/lib/machines/dba-pg
LIVE=/var/lib/machines/dba-$NAME
PIDFILE=/run/dba-lab-$NAME.pid
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
export SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1 TZ=America/Sao_Paulo

PACKAGES="postgresql postgresql-16-postgis-3 postgresql-16-repack mysql-server-8.0 pgloader"
OLD16="postgresql-16=16.2-1ubuntu4 postgresql-client-16=16.2-1ubuntu4 libpq5=16.2-1ubuntu4"

nspawn() { systemd-nspawn -q --register=no --keep-unit --timezone=off "$@"; }

leader() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 1
  pgrep -P "$p" -x systemd | head -1
}

in_vm() { local l; l=$(leader) || { echo "lab is not running" >&2; exit 1; }
  nsenter -t "$l" -a env -i TERM=dumb LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Sao_Paulo \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"; }

as_ana() { in_vm su - ana -c "$*"; }

build() {
  if [ ! -x "$BASE/usr/bin/python3" ]; then
    rm -rf "$BASE"
    debootstrap --include=systemd,systemd-sysv,dbus,sudo,curl,ca-certificates,iproute2,less,nano,jq,python3,locales,tzdata,file,procps,util-linux,psmisc,git,gnupg,lsb-release,xfsprogs,e2fsprogs,bc \
      noble "$BASE" "$MIRROR"
  fi
  printf 'deb %s noble main universe\ndeb %s noble-updates main universe\ndeb http://security.ubuntu.com/ubuntu noble-security main universe\n' \
    "$MIRROR" "$MIRROR" > "$BASE/etc/apt/sources.list"
  rm -f "$BASE/etc/resolv.conf"; cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  echo db > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tdb\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  echo America/Sao_Paulo > "$BASE/etc/timezone"
  nspawn -D "$BASE" --pipe bash -c "
    set -e
    id ana >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash -G sudo ana
    echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana
    systemctl mask console-getty.service >/dev/null 2>&1 || true
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen; locale-gen >/dev/null
    echo 'Binary::apt::APT::Keep-Downloaded-Packages \"true\";' > /etc/apt/apt.conf.d/01keep
    apt-get update -q
    apt-get install -y -q --download-only $PACKAGES
    apt-get install -y -q --download-only --allow-downgrades $OLD16"
  # The server as lesson 3 leaves it: PostgreSQL installed with apt, and a
  # role for ana. Kept apart so every later lesson starts without reinstalling.
  rm -rf "$PGBASE"; cp -a "$BASE" "$PGBASE"
  nspawn -D "$PGBASE" --pipe bash -c "
    set -e
    DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-download postgresql >/dev/null"
}

down() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 0
  rm -f "$PIDFILE"
  [ "$(cat /proc/"$p"/comm 2>/dev/null)" = systemd-nspawn ] || return 0
  kill "$p" 2>/dev/null || true
  for _ in $(seq 50); do kill -0 "$p" 2>/dev/null || break; sleep 0.2; done
}

up() {
  mountpoint -q /run/systemd/nspawn || { mkdir -p /run/systemd/nspawn; mount -t tmpfs tmpfs /run/systemd/nspawn; }
  setsid systemd-nspawn -q -b --console=passive --register=no --keep-unit \
    --private-network --timezone=off --capability=CAP_SYS_ADMIN \
    -D "$LIVE" --machine "dba-$NAME" --hostname db \
    </dev/null >"/var/log/dba-lab-$NAME.log" 2>&1 &
  echo $! > "$PIDFILE"
  for _ in $(seq 100); do
    if leader >/dev/null && in_vm systemctl is-system-running --wait >/dev/null 2>&1; then break; fi
    sleep 0.3
  done
  in_vm systemctl is-system-running >/dev/null 2>&1 || in_vm systemctl --failed --no-pager || true
  mkdir -p "$LIVE/usr/local/lib/lab"
  cp "$HERE/lab/"*.py "$LIVE/usr/local/lib/lab/"
}

# Run what a lesson prints. FILE is relative to the course's lessons/.
fence() { python3 "$HERE/lab/fence.py" "$HERE/lessons/$1" "$2"; }

stage() { # where lesson N starts: what the lessons before it left behind
  local n=${1:-1}
  [ "$n" -ge 4 ] || return 0
  # Lesson 3: a superuser role for ana, as the setup makes it.
  in_vm su - postgres -c "createuser --superuser ana" >/dev/null
  [ "$n" -ge 5 ] || return 0
  # Lesson 4: the course's database, from the generator that lesson prints.
  STAGE_LESSON=4 stage_shop
}

stage_shop() {
  fence le-56a5dn23/a-database-to-look-after.md '-- shop.sql' | as_ana 'cat > shop.sql'
  as_ana 'createdb shop && psql -q shop -f shop.sql >/dev/null'
}

reset() {
  down
  rm -rf "$LIVE"
  if [ "${1:-1}" -ge 4 ]; then cp -a "$PGBASE" "$LIVE"; else cp -a "$BASE" "$LIVE"; fi
  up
  stage "${1:-1}"
}

case "${1:-}" in
  build) build ;;
  reset) reset "${2:-1}" ;;
  up) up ;;
  down) down ;;
  as) shift; as_ana "$*" ;;
  root) shift; in_vm bash -lc "$*" ;;
  psql) shift; in_vm su - ana -c "python3 /usr/local/lib/lab/session.py $*" ;;
  *) sed -n '2,70p' "$0"; exit 2 ;;
esac
