#!/usr/bin/env bash
# The go course's lab: one machine, one student and one Go toolchain. Every
# lesson's captures.sh runs its programs through this file, so a transcript in
# lesson 4 and one in lesson 38 come from the same compiler, the same home
# directory and the same environment.
#
#   sudo bash lab.sh setup             install Go and create the student, once
#   sudo bash lab.sh fresh DIR         empty ~ana/DIR and leave it there, owned by ana
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~ana/DIR, with the lab's environment
#   sudo bash lab.sh put DIR/FILE      write stdin to ~ana/DIR/FILE, as ana
#
# WHAT IT INSTALLS. Go 1.27.1 for linux/amd64 in /usr/local/go, where the
# official instructions put it. The official route is the archive from
# go.dev/dl and its SHA-256, and lesson 3 shows it; this sandbox cannot reach
# go.dev, so setup takes the same release from the module proxy instead, as the
# go command's own toolchain switch does (lesson 3 again). That download is
# checked against the checksum database, sum.golang.org, before it is used.
# Whatever Go was already in /usr/local/go is moved aside to /usr/local/go.old.
#
# THE STUDENT is ana, an ordinary user with a home of her own. Her prompt in
# the lessons, ana@vm:~/work$, is printed by the capture scripts: the machine
# is not called vm, and nothing in any output depends on its name.
#
# THE ENVIRONMENT IS FIXED and nothing else leaks in from whoever runs this:
# HOME, PATH (with /usr/local/go/bin and ~/go/bin), TZ=America/Sao_Paulo,
# LC_ALL=C.UTF-8 and GOTOOLCHAIN=local, so a go.mod asking for a newer Go fails
# instead of fetching one. The sandbox's proxy variables and its certificate
# bundle are passed through so that the go command can reach the module proxy
# and the checksum database; they are not part of any lesson.
#
# Recorded on Ubuntu 24.04.
set -euo pipefail

GO_VERSION=go1.27.1
STUDENT=ana
HOME_DIR=/home/$STUDENT
CA=/usr/local/share/golab-ca.crt

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }

setup() {
  need_root
  if ! /usr/local/go/bin/go version 2>/dev/null | grep -q " $GO_VERSION "; then
    local src
    # The go command downloads a toolchain module and verifies it against
    # sum.golang.org before printing its GOROOT; any Go from 1.21 on can do it.
    src=$(cd / && GOTOOLCHAIN=$GO_VERSION go env GOROOT)
    [ -x "$src/bin/go" ] || { echo "lab.sh: no $GO_VERSION at $src" >&2; exit 1; }
    if [ -d /usr/local/go ]; then
      rm -rf /usr/local/go.old
      mv /usr/local/go /usr/local/go.old
    fi
    cp -a "$src" /usr/local/go
    chmod -R u+w /usr/local/go
  fi
  id "$STUDENT" >/dev/null 2>&1 || useradd -m -s /bin/bash "$STUDENT"
  if [ -n "${SSL_CERT_FILE:-}" ] && [ -r "$SSL_CERT_FILE" ]; then
    install -m 0644 "$SSL_CERT_FILE" "$CA"
  fi
  /usr/local/go/bin/go version
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
  *)
    sed -n '2,10p' "$0" >&2
    exit 2
    ;;
esac
