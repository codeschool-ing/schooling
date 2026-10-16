#!/usr/bin/env bash
# The machine every transcript in the apis course was recorded on.
#
# IT IS ONE UBUNTU 24.04 MACHINE, called `api`, with one user, ana. Lesson 1
# tells the student to build theirs as a virtual machine with Multipass (or
# any hypervisor) and to install everything from Ubuntu's own archive with one
# apt-get. This script builds the same machine as a debootstrapped root,
# because the computer the course was recorded on could not run a hypervisor:
# the same release, the same packages from the same archive, and the same
# apt-get line lesson 1 prints, which `packages` below holds byte for byte.
#
# EACH LESSON GETS ITS OWN COPY. `up NAME` mounts a fresh overlay of the base
# and starts a holder process in new network, UTS, PID and mount namespaces,
# chrooted into it, with the hostname `api` and nothing but a loopback
# interface. Every lesson's programs listen on 127.0.0.1:8000 like the
# student's do, and two lessons recorded at the same time cannot hear each
# other. `up NAME net` keeps the computer's network instead, for the one step
# that has to download something (lesson 6's pip install).
#
# WHAT IS STAGED, AND WHY
#   - ana may use sudo without a password, which a real machine would not
#     allow. It keeps password prompts out of the transcripts.
#   - The programs the student types are NOT written by this script. Every one
#     is shown whole in a lesson, beginning with a comment that names its path
#     (`# shelf/db.py`), and `shown NAME FILE.md…` copies those blocks out of
#     the lessons into ana's home. So the file a capture runs is the file the
#     lesson prints, and the two cannot drift apart.
#   - TZ=America/Sao_Paulo. Dates, timings, process ids, random tokens and
#     hashes differ on every run; the lessons quote one run.
#
#   sudo bash lab.sh build            debootstrap noble and install (once)
#   sudo bash lab.sh up NAME [net]    a fresh copy called NAME, running
#   sudo bash lab.sh as NAME 'cmd'    run as ana, in /home/ana, login shell
#   sudo bash lab.sh root NAME 'cmd'  the same as root
#   sudo bash lab.sh shown NAME F.md… copy every whole file the lessons show
#   sudo bash lab.sh down NAME
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Lesson 1's sections "Your machine"
# and "The packages" carry everything it installs.
set -euo pipefail

BASE=/var/lib/machines/apis-base
RUNS=/var/lib/machines/apis-runs
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

# The line lesson 1 prints, word for word.
packages() {
  cat <<'EOF'
sudo apt-get install -y curl jq sqlite3 openssl nano python3 python3-venv python3-pip \
    python3-yaml python3-jsonschema python3-graphql-core python3-grpcio python3-grpc-tools \
    protobuf-compiler python3-zeep python3-lxml libxml2-utils xmlsec1 python3-bcrypt \
    python3-argon2 python3-jwt python3-cryptography
EOF
}

build() {
  [ -x "$BASE/usr/bin/apt-get" ] || debootstrap --variant=minbase noble "$BASE" "$MIRROR"
  cat > "$BASE/etc/apt/sources.list" <<EOF
deb $MIRROR noble main universe
deb $MIRROR noble-updates main universe
deb $MIRROR noble-security main universe
EOF
  cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  chroot "$BASE" env DEBIAN_FRONTEND=noninteractive apt-get update -q
  chroot "$BASE" env DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    sudo iproute2 procps less ca-certificates tzdata
  local line; line=$(packages | sed 's/^sudo //' | tr -d '\\\n')
  chroot "$BASE" env DEBIAN_FRONTEND=noninteractive $line
  echo api > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tapi\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  chroot "$BASE" id ana >/dev/null 2>&1 || chroot "$BASE" useradd -m -s /bin/bash ana
  echo 'ana ALL=(ALL) NOPASSWD:ALL' > "$BASE/etc/sudoers.d/ana"
  chroot "$BASE" apt-get clean
}

holder() { cat "$RUNS/$1/pid" 2>/dev/null; }

up() {
  local name=$1 net=${2:-} R="$RUNS/$1"
  down "$name" 2>/dev/null || true
  mkdir -p "$R/upper" "$R/work" "$R/root"
  mount -t overlay overlay -o "lowerdir=$BASE,upperdir=$R/upper,workdir=$R/work" "$R/root"
  for d in proc dev sys; do mkdir -p "$R/root/$d"; done
  mount --bind /dev "$R/root/dev"
  mount -t tmpfs tmpfs "$R/root/tmp"
  local flags="--uts --pid --mount --fork"
  [ "$net" = net ] || flags="--net $flags"
  # The holder: a shell in the new namespaces that mounts /proc, names the
  # machine, raises loopback, and waits. Every command after this enters it.
  setsid unshare $flags chroot "$R/root" /bin/bash -c \
    "mount -t proc proc /proc; hostname api; ip link set lo up; exec -a apis-holder-$name sleep infinity" \
    </dev/null >/dev/null 2>&1 &
  local i p
  for i in $(seq 100); do
    p=$(pgrep -f "^apis-holder-$name infinity$" || true)
    if [ -n "$p" ]; then echo "$p" > "$R/pid"; break; fi
    sleep 0.1
  done
  [ -s "$R/pid" ] || { echo "the holder for $name did not start" >&2; exit 1; }
  if [ "$net" = net ]; then
    # The recording computer reaches the internet only through a proxy that
    # re-signs TLS, so the copy that downloads trusts that proxy's CA and is
    # told where it is. A student's VM needs neither.
    cp /etc/resolv.conf "$R/root/etc/resolv.conf"
    if [ -f /root/.ccr/ca-bundle.crt ]; then
      cp /root/.ccr/ca-bundle.crt "$R/root/etc/ssl/recording-proxy.pem"
      printf 'HTTPS_PROXY=%s\nPIP_CERT=/etc/ssl/recording-proxy.pem\n' "${HTTPS_PROXY:-}" > "$R/env"
    fi
  fi
}

enter() { local name=$1; shift; local p; p=$(holder "$name") || true
  [ -n "$p" ] || { echo "$name is not up" >&2; exit 1; }
  nsenter -t "$p" -u -p -m -n -r -w env -i TERM=dumb LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    TZ=America/Sao_Paulo PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    ${HTTPS_PROXY:+HTTPS_PROXY=$HTTPS_PROXY} "$@"; }

as() { local name=$1; shift
  local pre=""
  [ -f "$RUNS/$name/env" ] && pre="export $(tr '\n' ' ' < "$RUNS/$name/env");"
  enter "$name" su - ana -c "$pre cd /home/ana && $1"; }
root() { local name=$1; shift
  enter "$name" bash -lc "$1"; }

# Every fenced block, and every schooling-example, whose first line is a
# comment naming a path under ~ana, written to that path. A schooling-example
# is joined the way the interface's copy button joins it: parts, by newlines.
shown() { local name=$1; shift; local R="$RUNS/$name/root"
  python3 - "$R/home/ana" "$@" <<'PY'
import json, os, re, sys
home, files = sys.argv[1], sys.argv[2:]
head = re.compile(r'^(?:#|//|--|;|<!--)\s*((?:[\w.-]+/)*[\w.-]+\.[\w]+)\s*(?:-->)?$')
for md in files:
    text = open(md, encoding='utf-8').read()
    for info, body in re.findall(r'^```([^\n]*)\n(.*?)^```$', text, re.S | re.M):
        if info.strip() == 'schooling-example':
            ex = json.loads(body)
            body = '\n'.join(p['code'] for p in ex['parts']) + '\n'
        first = body.split('\n', 1)[0].strip()
        m = head.match(first)
        if not m or not m.group(1).count('/'):
            continue
        path = os.path.join(home, m.group(1))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(body)
        print(m.group(1), file=sys.stderr)
PY
  enter "$name" chown -R ana:ana /home/ana
}

down() { local name=$1 R="$RUNS/$1"; local p; p=$(holder "$name") || true
  if [ -n "$p" ]; then kill -9 "$p" 2>/dev/null || true; fi
  pkill -9 -f "^apis-holder-$name infinity$" 2>/dev/null || true
  pkill -9 -f "chroot $R/root" 2>/dev/null || true
  for m in "$R/root/tmp" "$R/root/dev" "$R/root/proc" "$R/root"; do
    umount -l "$m" 2>/dev/null || true; done
  rm -rf "$R"
}

cmd=${1:-}; shift || true
case "$cmd" in
  build) build ;;
  packages) packages ;;
  up) up "$@" ;;
  as) as "$@" ;;
  root) root "$@" ;;
  shown) shown "$@" ;;
  down) down "$@" ;;
  *) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//' ; exit 1 ;;
esac
