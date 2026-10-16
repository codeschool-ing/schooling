#!/usr/bin/env bash
# The go-concurrency course's lab: one machine, one student and the Go
# toolchain the `go` course installed, plus the C compiler this course adds for
# the race detector. Every lesson's captures.sh runs its programs through this
# file, so a transcript in lesson 2 and one in lesson 30 come from the same
# compiler, the same home directory and the same environment.
#
#   sudo bash lab.sh setup             install Go and gcc and create the student, once
#   sudo bash lab.sh fresh DIR         empty ~ana/DIR and leave it there, owned by ana
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~ana/DIR, with the lab's environment
#   sudo bash lab.sh put DIR/FILE      write stdin to ~ana/DIR/FILE, as ana
#   bash lab.sh fence MD FILE [N]      print the N-th program the section MD shows as FILE
#
# WHAT IT INSTALLS. Go 1.27.1 for linux/amd64 in /usr/local/go, exactly as
# lesson 3 of `go` installs it. The official route is the archive from go.dev/dl
# and its SHA-256; this sandbox cannot reach go.dev, so setup takes the same
# release from the module proxy instead, as the go command's own toolchain
# switch does, checked against sum.golang.org. Whatever Go was already in
# /usr/local/go is moved aside to /usr/local/go.old. gcc comes from Ubuntu
# 24.04's own archive, as lesson 1 of this course tells the student to install
# it; the machine this was recorded on already had it.
#
# THE STUDENT is ana, an ordinary user with a home of her own, as in `go`. Her
# prompt in the lessons, ana@vm:~/work$, is printed by the capture scripts: the
# machine is not called vm, and nothing in any output depends on its name.
#
# THE ENVIRONMENT IS FIXED and nothing else leaks in from whoever runs this:
# HOME, PATH (with /usr/local/go/bin and ~/go/bin), TZ=America/Sao_Paulo,
# LC_ALL=C.UTF-8 and GOTOOLCHAIN=local, so a go.mod asking for a newer Go fails
# instead of fetching one. The sandbox's proxy variables and its certificate
# bundle are passed through so that the go command can reach the module proxy;
# they are not part of any lesson, and no lesson in this course downloads a
# module.
#
# FENCE is how a capture runs the program a lesson shows rather than a copy of
# it. A `schooling-example` is matched by its `file` field and its parts are
# concatenated, which is the program the copy button hands over; a plain fence
# is matched when the paragraph before it ends with "as `FILE`:". N counts
# matches in the file, from 1.
#
# Recorded on Ubuntu 24.04, four processors.
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
    src=$(cd / && GOTOOLCHAIN=$GO_VERSION go env GOROOT)
    [ -x "$src/bin/go" ] || { echo "lab.sh: no $GO_VERSION at $src" >&2; exit 1; }
    if [ -d /usr/local/go ]; then
      rm -rf /usr/local/go.old
      mv /usr/local/go /usr/local/go.old
    fi
    cp -a "$src" /usr/local/go
    chmod -R u+w /usr/local/go
  fi
  command -v gcc >/dev/null || apt-get install -y gcc
  id "$STUDENT" >/dev/null 2>&1 || useradd -m -s /bin/bash "$STUDENT"
  if ! grep -q /usr/local/go/bin "$HOME_DIR/.profile"; then
    printf '%s\n' 'export PATH=$PATH:/usr/local/go/bin' 'export PATH=$PATH:$HOME/go/bin' >> "$HOME_DIR/.profile"
  fi
  if [ -n "${SSL_CERT_FILE:-}" ] && [ -r "$SSL_CERT_FILE" ]; then
    install -m 0644 "$SSL_CERT_FILE" "$CA"
  fi
  /usr/local/go/bin/go version
}

# The environment ana's shell has, and nothing else.
student_env() {
  local e=(
    HOME="$HOME_DIR" USER="$STUDENT" LOGNAME="$STUDENT" SHELL=/bin/bash
    PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:$HOME_DIR/go/bin"
    TZ=America/Sao_Paulo LC_ALL=C.UTF-8 LANG=C.UTF-8 TERM=dumb COLUMNS=100
    GOTOOLCHAIN=local
  )
  local v
  for v in HTTPS_PROXY https_proxy NO_PROXY no_proxy; do
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

fence() {
  python3 - "$@" <<'PY'
import json, re, sys
path, want = sys.argv[1], sys.argv[2]
nth = int(sys.argv[3]) if len(sys.argv) > 3 else 1
lines = open(path).read().split("\n")
i, prev, ended, seen = 0, "", False, 0
while i < len(lines):
    m = re.match(r"^(`{3,})(\S*)\s*$", lines[i])
    if not m:
        if not lines[i].strip():
            ended = True
        else:
            prev = lines[i].strip() if ended else prev + " " + lines[i].strip()
            ended = False
        i += 1
        continue
    j = i + 1
    while lines[j].rstrip() != m.group(1):
        j += 1
    body = "\n".join(lines[i + 1:j])
    hit = None
    if m.group(2) == "schooling-example":
        ex = json.loads(body)
        if ex.get("file") == want:
            hit = "".join(p["code"] for p in ex["parts"])
    else:
        label = re.search(r"\bas `([~\w./-]+)`:$", prev.rstrip())
        if label and label.group(1) == want:
            hit = body + "\n"
    if hit is not None:
        seen += 1
        if seen == nth:
            sys.stdout.write(hit)
            sys.exit(0)
    prev, i = "", j + 1
sys.exit(f"fence: {path} shows no program {want} (#{nth})")
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
  fence) shift; fence "$@" ;;
  *)
    sed -n '2,13p' "$0" >&2
    exit 2
    ;;
esac
