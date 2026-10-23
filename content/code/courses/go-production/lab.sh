#!/usr/bin/env bash
# The go-production course's lab: one machine, one student and one Go
# toolchain, the same ones the go course's lab builds. Every lesson's
# captures.sh runs its commands through this file, so a transcript in lesson 2
# and one in lesson 24 come from the same compiler, the same home directory and
# the same environment.
#
#   sudo bash lab.sh setup                 install Go and create the student, once
#   sudo bash lab.sh fresh DIR             empty ~ana/DIR and leave it there, owned by ana
#   sudo bash lab.sh exec DIR 'cmd'        run cmd as ana, in ~ana/DIR, with the lab's environment
#   sudo bash lab.sh put DIR/FILE          write stdin to ~ana/DIR/FILE, as ana
#   bash lab.sh show LESSON SECTION FILE   print FILE as the lesson prints it
#   sudo bash lab.sh place LESSON SECTION FILE DIR
#                                          show, then put it at ~ana/DIR/FILE
#
# EVERY PROGRAM THE STUDENT SAVES IS READ OUT OF A LESSON. `show` finds, in
# lessons/LESSON/SECTION.md, either the one fence whose preceding line names
# `FILE` in backticks and ends with a colon, or the one schooling-example whose
# "file" is FILE, joined the way the page's copy button joins it. A
# captures.sh never carries a second copy of a program: it places the file
# from the lesson, so the transcript can only come from what the student reads.
#
# WHAT IT INSTALLS. Go 1.27.1 for linux/amd64 in /usr/local/go, where the
# official instructions put it, and where the go course's lesson 3 puts it. The
# official route is the archive from go.dev/dl; this sandbox cannot reach
# go.dev, so setup takes the same release from the module proxy instead, as
# the go command's own toolchain switch does. That download is checked against
# the checksum database before it is used. Whatever was in /usr/local/go is
# moved aside to /usr/local/go.old. gcc comes from Ubuntu's archive, as lesson 1
# tells the student to install it.
#
# THE STUDENT is ana, an ordinary user with a home of her own. Her prompt in
# the lessons, ana@vm:~/hits$, is printed by the capture scripts: the machine
# is not called vm, and nothing in any output depends on its name.
#
# THE ENVIRONMENT IS FIXED and nothing else leaks in from whoever runs this:
# HOME, PATH (with /usr/local/go/bin and ~/go/bin), TZ=America/Sao_Paulo,
# LC_ALL=C.UTF-8 and GOTOOLCHAIN=local, so a go.mod asking for a newer Go fails
# instead of fetching one. The sandbox's proxy variables and its certificate
# bundle are passed through so that the go command can reach the module proxy;
# they are not part of any lesson.
#
# Recorded on Ubuntu 24.04.
set -euo pipefail

GO_VERSION=go1.27.1
STUDENT=ana
HOME_DIR=/home/$STUDENT
CA=/usr/local/share/golab-ca.crt
COURSE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }

setup() {
  need_root
  if ! /usr/local/go/bin/go version 2>/dev/null | grep -q " $GO_VERSION "; then
    local src
    src=$(cd / && GOTOOLCHAIN=$GO_VERSION go env GOROOT)
    [ -x "$src/bin/go" ] || { echo "lab.sh: no $GO_VERSION at $src" >&2; exit 1; }
    if [ -e /usr/local/go ] || [ -L /usr/local/go ]; then
      rm -rf /usr/local/go.old
      mv /usr/local/go /usr/local/go.old
    fi
    cp -a "$src" /usr/local/go
    chmod -R u+w /usr/local/go
  fi
  command -v gcc >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y gcc
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

show() {
  python3 - "$COURSE/lessons/$1/$2.md" "$3" <<'PY'
import json, re, sys
md, name = sys.argv[1], sys.argv[2]
text = open(md, encoding="utf-8").read()
found = re.findall(r"^[^\n]*`" + re.escape(name) + r"`[^\n]*:\n\n```[a-z]*\n(.*?)^```$", text, re.S | re.M)
for raw in re.findall(r"^```schooling-example\n(.*?)^```$", text, re.S | re.M):
    ex = json.loads(raw)
    if ex.get("file") == name:
        found.append("\n".join(p["code"] for p in ex["parts"]).rstrip("\n") + "\n")
if len(found) != 1:
    sys.exit(f"{md}: {len(found)} blocks printing {name}, and this needs exactly one")
sys.stdout.write(found[0])
PY
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
  show)
    [ $# -eq 4 ] || { echo "usage: lab.sh show LESSON SECTION FILE" >&2; exit 2; }
    show "$2" "$3" "$4"
    ;;
  place)
    need_root
    [ $# -eq 5 ] || { echo "usage: lab.sh place LESSON SECTION FILE DIR" >&2; exit 2; }
    # show fails on a missing or ambiguous block; place must fail with it
    # rather than leave an empty file for the next command to trip over.
    body=$(show "$2" "$3" "$4") || exit 1
    body="$body"$'\n'x
    printf '%s' "${body%x}" | as_student "mkdir -p \"\$(dirname ~/'$5/$4')\" && cat > ~/'$5/$4'"
    ;;
  *)
    sed -n '2,20p' "$0" >&2
    exit 2
    ;;
esac
