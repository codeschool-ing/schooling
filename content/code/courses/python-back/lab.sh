#!/usr/bin/env bash
# The machine every transcript in python-back was recorded on.
#
# IT IS ONE UBUNTU 24.04 SERVER, called `vm`, with one user, ana. Lesson 1
# tells the student to build theirs as a virtual machine, or to use the one
# the `python` course already gave them, and to install everything from
# Ubuntu's own archive with apt, plus uv with pipx. This script builds the same
# server as a systemd-nspawn container, because the computer the course was
# recorded on could not run a hypervisor: the same release, the same packages
# at the same versions, booted by its own systemd, so `systemctl`, `journalctl`
# and the services behave as they do in a virtual machine. It shares the
# recording computer's network, which is how `uv add` reaches PyPI and apt
# reaches Ubuntu's archive, with no proxy and nothing rewritten.
#
# WHAT IS IN IT, installed with the apt line of the lesson that needs it:
#   lesson 1   python3 python3-venv python3-pip pipx git curl, and uv with
#              `pipx install uv`, as ana
#   lesson 4   postgresql (16)
#   lesson 13  redis-server (7.0)
#   lesson 16  nginx
# The base image has every one of them installed already, so a lesson's
# transcript is never a download log; each service is DISABLED in the base
# and enabled by the lesson that installs it, as `apt install` would have.
# Every Python library comes from PyPI through uv, inside each project, and
# the versions are the ones uv.lock recorded on the day: each lesson's
# captures print them.
#
# WHERE EACH LESSON STARTS
#   Lesson N starts from the machine lesson N-1's captures left behind:
#   `save N` keeps a snapshot of it when a lesson's captures finish, and
#   `reset N` boots a fresh copy of snapshot N-1 (the base, for lesson 1). So
#   the captures have to be run IN ORDER the first time, and after that any
#   lesson may be run again on its own. Everything a student types to get
#   from one lesson to the next is in the lessons; the snapshot only saves
#   retyping it here.
#
# WHAT IS STAGED, AND WHY
#   - ana may use sudo without a password, which a real server would not
#     allow. It keeps the transcripts free of password prompts.
#   - The clock is the recording computer's, and TZ is America/Sao_Paulo;
#     every date the course's data carries is fixed in the data itself.
#   - The recording computer reaches PyPI through a gateway that re-signs
#     TLS. Its certificates, the extra ones in that computer's own
#     /usr/local/share/ca-certificates (CA_DIR below), are added to the
#     machine's trust store with update-ca-certificates, and
#     UV_SYSTEM_CERTS=1 is set in ana's ~/.profile so uv reads that store
#     rather than its own built-in list; `pipx install uv` ran with PIP_CERT
#     pointing at the same store. None of it is a step of the course: a
#     student's machine talks to PyPI directly and needs neither.
#
#   sudo bash lab.sh build          debootstrap, then the packages (once)
#   sudo bash lab.sh reset N        a fresh copy of the machine lesson N
#                                   starts from, booted
#   sudo bash lab.sh save N         snapshot the machine as lesson N leaves it
#   sudo bash lab.sh as 'cmd'       run a command as ana, in /home/ana, in a login shell
#   sudo bash lab.sh root 'cmd'     the same as root
#   sudo bash lab.sh down
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

MACHINES=/var/lib/machines
BASE=$MACHINES/pyback-base
LIVE=$MACHINES/pyback
SNAP=$MACHINES/pyback-after
PIDFILE=/run/python-back-lab.pid
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
CA_DIR=${CA_DIR:-/usr/local/share/ca-certificates}
export SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1 TZ=America/Sao_Paulo

# The apt lines, as the lessons print them.
LESSON1="python3 python3-venv python3-pip pipx git curl"
LESSON4="postgresql"
LESSON13="redis-server"
LESSON16="nginx"
SERVICES="postgresql redis-server nginx"

nspawn() { systemd-nspawn -q --register=no --keep-unit --timezone=off "$@"; }

leader() {
  local p; p=$(cat "$PIDFILE" 2>/dev/null) || return 1
  pgrep -P "$p" -x systemd | head -1
}

in_vm() { local l; l=$(leader) || { echo "lab is not running" >&2; exit 1; }
  nsenter -t "$l" -a env -i TERM=dumb LANG=C.UTF-8 TZ=America/Sao_Paulo \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"; }

build() {
  if [ ! -x "$BASE/usr/bin/systemctl" ]; then
    rm -rf "$BASE"
    debootstrap --include=systemd,systemd-sysv,dbus,sudo,curl,ca-certificates,iproute2,less,nano,locales,tzdata,file,procps,psmisc \
      noble "$BASE" "$MIRROR"
  fi
  printf 'deb %s noble main universe\ndeb %s noble-updates main universe\ndeb http://security.ubuntu.com/ubuntu noble-security main universe\n' \
    "$MIRROR" "$MIRROR" > "$BASE/etc/apt/sources.list"
  rm -f "$BASE/etc/resolv.conf"; cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  echo vm > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tvm\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  echo America/Sao_Paulo > "$BASE/etc/timezone"
  mkdir -p "$BASE/usr/local/share/ca-certificates"
  rm -f "$BASE"/usr/local/share/ca-certificates/*.crt
  cp "$CA_DIR"/*.crt "$BASE/usr/local/share/ca-certificates/" 2>/dev/null || true
  nspawn -D "$BASE" --pipe bash -c "
    set -e
    export DEBIAN_FRONTEND=noninteractive
    id ana >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash -G sudo ana
    echo 'ana ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ana
    touch /home/ana/.sudo_as_admin_successful
    systemctl mask console-getty.service >/dev/null 2>&1 || true
    update-ca-certificates >/dev/null
    grep -q UV_SYSTEM_CERTS /home/ana/.profile || echo 'export UV_SYSTEM_CERTS=1' >> /home/ana/.profile
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen >/dev/null
    apt-get update -q
    apt-get install -y -q $LESSON1 $LESSON4 $LESSON13 $LESSON16
    for s in $SERVICES; do systemctl disable \$s >/dev/null 2>&1 || true; done
    rm -rf /home/ana/.local/share/pipx /home/ana/.local/state/pipx
    runuser -u ana -- bash -lc 'PIP_CERT=/etc/ssl/certs/ca-certificates.crt pipx install uv && pipx ensurepath'
  "
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
    --timezone=off -D "$LIVE" --machine vm </dev/null >/var/log/python-back-lab.log 2>&1 &
  echo $! > "$PIDFILE"
  for _ in $(seq 100); do
    if leader >/dev/null && in_vm systemctl is-system-running --wait >/dev/null 2>&1; then break; fi
    sleep 0.3
  done
  in_vm systemctl is-system-running >/dev/null 2>&1 || in_vm systemctl --failed --no-pager || true
}

reset() {
  local n=${1:-1} from
  down
  if [ "$n" -le 1 ]; then from=$BASE; else from=$SNAP-$((n - 1)); fi
  [ -d "$from" ] || { echo "no snapshot $from: run the captures of lesson $((n - 1)) first" >&2; exit 1; }
  rm -rf "$LIVE"
  cp -a "$from" "$LIVE"
  up
}

save() {
  down
  rm -rf "$SNAP-$1"
  rsync -a --link-dest="$BASE" "$LIVE/" "$SNAP-$1/"
}

case "${1:-}" in
  build) build ;;
  reset) reset "${2:-1}" ;;
  save) save "${2:?lesson number}" ;;
  up) up ;;
  down) down ;;
  as) shift; in_vm su - ana -c "$*" ;;
  root) shift; in_vm bash -lc "$*" ;;
  *) sed -n '2,52p' "$0"; exit 2 ;;
esac
