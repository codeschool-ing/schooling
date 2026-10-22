#!/usr/bin/env bash
# The go-back course's lab: one Ubuntu 24.04 machine, one student, the Go
# toolchain the go course installs and the PostgreSQL that sql-databases
# installs. Every lesson's captures.sh runs through this file, so a transcript
# in lesson 1 and one in lesson 17 come from the same compiler, the same home
# directory and the same database server.
#
#   sudo bash lab.sh setup             Go 1.27.1, the student, PostgreSQL 16 up
#   sudo bash lab.sh fresh DIR         empty ~ana/DIR and leave it there, owned by ana
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~ana/DIR, with the lab's environment
#   sudo bash lab.sh put DIR/FILE      write stdin to ~ana/DIR/FILE, as ana
#   sudo bash lab.sh project N DIR     write the boxoffice project as lesson N
#                                      leaves it into ~ana/DIR (see lab/project.py)
#   sudo bash lab.sh db                PostgreSQL started, role ana present
#
# WHAT IT INSTALLS. Go 1.27.1 for linux/amd64 in /usr/local/go, exactly as the
# go course's lab does: the official route is the archive from go.dev/dl, and
# this sandbox cannot reach go.dev, so the same release comes from the module
# proxy, checked against sum.golang.org. PostgreSQL 16 is Ubuntu's own package
# (`apt install postgresql`), in Ubuntu's own cluster 16/main. gcc, which the
# race detector and sqlc's parser need, is Ubuntu's `gcc`. Docker Engine, for
# lesson 16, is the package Docker publishes for Ubuntu, and lesson 16 shows how
# it is installed; the daemon is started by that lesson's captures.sh.
#
# THE STUDENT is ana, an ordinary user with sudo. Her prompt in the lessons,
# ana@vm:~/boxoffice$, is printed by the capture scripts.
#
# THE ENVIRONMENT IS FIXED and nothing else leaks in from whoever runs this:
# HOME, PATH (with /usr/local/go/bin and ~/go/bin), TZ=America/Sao_Paulo,
# LC_ALL=C.UTF-8 and GOTOOLCHAIN=local. The sandbox's proxy variables and its
# certificate bundle are passed through so that the go command can reach the
# module proxy; they are not part of any lesson.
#
# Recorded on Ubuntu 24.04.
set -euo pipefail

GO_VERSION=go1.27.1
STUDENT=ana
HOME_DIR=/home/$STUDENT
CA=/usr/local/share/golab-ca.crt
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }

setup() {
  need_root
  if ! /usr/local/go/bin/go version 2>/dev/null | grep -q " $GO_VERSION "; then
    local src
    src=$(cd / && GOTOOLCHAIN=$GO_VERSION go env GOROOT)
    [ -x "$src/bin/go" ] || { echo "lab.sh: no $GO_VERSION at $src" >&2; exit 1; }
    if [ -d /usr/local/go ]; then
      rm -rf /usr/local/go.old
      mv /usr/local/go /usr/local/go.old
    fi
    cp -a "$src" /usr/local/go
    chmod -R u+w /usr/local/go
  fi
  command -v psql >/dev/null || { apt-get update -q; apt-get install -y -q postgresql; }
  command -v gcc >/dev/null || apt-get install -y -q gcc
  id "$STUDENT" >/dev/null 2>&1 || useradd -m -s /bin/bash "$STUDENT"
  echo "$STUDENT ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$STUDENT
  if [ -n "${SSL_CERT_FILE:-}" ] && [ -r "$SSL_CERT_FILE" ]; then
    install -m 0644 "$SSL_CERT_FILE" "$CA"
  fi
  db
  /usr/local/go/bin/go version
}

db() {
  pg_lsclusters -h | grep -q '^16 *main' || pg_createcluster 16 main >/dev/null
  pg_ctlcluster 16 main start 2>/dev/null || true
  runuser -u postgres -- psql -qXtc "SELECT 1 FROM pg_roles WHERE rolname='$STUDENT'" | grep -q 1 \
    || runuser -u postgres -- createuser --superuser "$STUDENT"
}

# The environment ana's shell has, and nothing else.
student_env() {
  local e=(
    HOME="$HOME_DIR" USER="$STUDENT" LOGNAME="$STUDENT" SHELL=/bin/bash
    PATH="/usr/local/go/bin:$HOME_DIR/go/bin:/usr/local/bin:/usr/bin:/bin"
    TZ=America/Sao_Paulo LC_ALL=C.UTF-8 LANG=C.UTF-8 TERM=dumb COLUMNS=100
    GOTOOLCHAIN=local
  )
  local v
  for v in HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy; do
    [ -n "${!v:-}" ] && e+=("$v=${!v}")
  done
  [ -r "$CA" ] && e+=(SSL_CERT_FILE="$CA")
  printf '%s\0' "${e[@]}"
}

as_student() {
  local env=()
  mapfile -d '' env < <(student_env)
  runuser -u "$STUDENT" -- env -i "${env[@]}" bash -c "$1"
}

case "${1:-}" in
  setup) setup ;;
  db) need_root; db ;;
  fresh)
    need_root
    [ -n "${2:-}" ] || { echo "usage: lab.sh fresh DIR" >&2; exit 2; }
    rm -rf "${HOME_DIR:?}/$2"
    as_student "mkdir -p ~/'$2'"
    ;;
  exec)
    need_root
    [ $# -ge 3 ] || { echo "usage: lab.sh exec DIR 'command'" >&2; exit 2; }
    as_student "cd ~/'$2' && $3"
    ;;
  put)
    need_root
    [ -n "${2:-}" ] || { echo "usage: lab.sh put DIR/FILE < content" >&2; exit 2; }
    as_student "mkdir -p \"\$(dirname ~/'$2')\" && cat > ~/'$2'"
    ;;
  project)
    need_root
    [ $# -ge 3 ] || { echo "usage: lab.sh project N DIR" >&2; exit 2; }
    rm -rf "${HOME_DIR:?}/$3"
    as_student "mkdir -p ~/'$3'"
    python3 "$HERE/lab/project.py" "$HERE" "$2" | as_student "cd ~/'$3' && python3 -c '
import json, os, sys
for path, body in json.load(sys.stdin).items():
    os.makedirs(os.path.dirname(path) or \".\", exist_ok=True)
    open(path, \"w\").write(body)
'"
    ;;
  *)
    sed -n '2,13p' "$0" >&2
    exit 2
    ;;
esac
