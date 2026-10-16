#!/usr/bin/env bash
# The machine every transcript in the non-functional-testing course was
# recorded on.
#
# IT IS ONE UBUNTU 24.04 MACHINE, called `nft`, with one user, ana. Lesson 1
# tells the student to build theirs as a virtual machine with Multipass (or any
# hypervisor) and to install the base from Ubuntu's own archive with one
# apt-get. Each later lesson installs the tool it uses, in that lesson. This
# script builds the same machine as a debootstrapped root, because the computer
# the course was recorded on could not run a hypervisor: the same release, the
# same packages from the same archive, and the install lines the lessons print,
# which the functions below hold byte for byte.
#
# WHAT IS STAGED, AND WHY
#   - Every tool is installed once, here, rather than in the lesson that
#     installs it, so that every lesson's copy starts with all of them.
#   - k6, Vegeta and gitleaks: the lessons download the release archive from
#     GitHub, which the recording computer could not reach. Here each one is
#     built from the same tagged source with `go install`, with the version
#     stamped the way the release stamps it, so `k6 version` names the Go
#     version of this build (go1.25.1) where a release names its own.
#   - Chromium: the lessons run `npx playwright install chromium`, which
#     downloads from a host the recording computer could not reach. Here the
#     same build (chromium-1194, the one playwright 1.56.0 asks for) is copied
#     from the recording computer's own Playwright cache. The system libraries
#     come from the same `npx playwright install-deps chromium` the lesson runs.
#     Artillery's own install would download a Chromium too, for its browser
#     engine, which this course never uses; here it is told not to.
#   - ana may use sudo without a password, which a real machine would not
#     allow. It keeps password prompts out of the transcripts.
#   - The programs the student types are NOT written by this script. Every one
#     is shown whole in a lesson, beginning with a comment that names its path
#     (`# boxoffice/app.py`), and `shown NAME FILE.md…` copies those blocks out
#     of the lessons into ana's home. So the file a capture runs is the file
#     the lesson prints.
#   - TZ=America/Sao_Paulo. Timings, process ids and dates differ on every run;
#     the lessons quote one run, and every load test's numbers depend on the
#     recording computer (4 processors, shared with the load generator).
#
# EACH LESSON GETS ITS OWN COPY. `up NAME` mounts a fresh overlay of the base
# and starts a holder process in new network, UTS, PID and mount namespaces,
# chrooted into it, with the hostname `nft` and nothing but a loopback
# interface. `up NAME net` keeps the computer's network instead, for a step
# that has to reach the internet.
#
#   sudo bash lab.sh build            debootstrap noble and install (once)
#   sudo bash lab.sh up NAME [net]    a fresh copy called NAME, running
#   sudo bash lab.sh as NAME 'cmd'    run as ana, in /home/ana, login shell
#   sudo bash lab.sh root NAME 'cmd'  the same as root
#   sudo bash lab.sh shown NAME F.md… copy every whole file the lessons show
#   sudo bash lab.sh down NAME
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Lesson 1's sections carry the
# machine and the base packages; each tool's lesson carries its install.
set -euo pipefail

BASE=/var/lib/machines/nft-base
RUNS=/var/lib/machines/nft-runs
CACHE=/var/cache/nft-lab
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8

# Lesson 1, "The base packages", word for word.
packages() {
  cat <<'EOF'
sudo apt-get install -y curl jq sqlite3 git nano unzip xz-utils python3 python3-venv \
    python3-pip openjdk-21-jdk-headless
EOF
}

# The versions every lesson pins.
NODE=v24.21.0
JMETER=5.6.3
GATLING=3.15.1
LOCUST=2.46.7
PIPAUDIT=2.10.1
ARTILLERY=2.0.34
LIGHTHOUSE=13.5.0
PLAYWRIGHT=1.56.0
AXE=4.13.0
K6=v1.8.1
VEGETA=v12.13.0
GITLEAKS=v8.30.1

fetch() { # URL: into $CACHE, retried, because Maven Central answers 429 in bursts
  local f="$CACHE/${1##*/}" i
  [ -s "$f" ] && return 0
  for i in 1 2 3 4 5; do curl -fsSL -o "$f.part" "$1" && mv "$f.part" "$f" && return 0; sleep $((i * 4)); done
  echo "could not fetch $1" >&2; return 1
}

gobuild() {
  export PATH=/usr/local/go1.25.1/bin:$PATH GOTOOLCHAIN=local GOBIN=$CACHE/bin
  [ -x "$GOBIN/k6" ] || go install go.k6.io/k6@$K6
  [ -x "$GOBIN/vegeta" ] || go install -ldflags "-X main.Version=$VEGETA" github.com/tsenart/vegeta/v12@$VEGETA
  [ -x "$GOBIN/gitleaks" ] || go install -ldflags "-X github.com/zricethezav/gitleaks/v8/version.Version=$GITLEAKS" \
    github.com/zricethezav/gitleaks/v8@$GITLEAKS
}

# Network inside the chroot during the build: the recording computer reaches
# the internet only through a proxy that re-signs TLS, so the build trusts
# that proxy's CA. A student's VM needs none of this.
netenv() {
  local pem=/etc/ssl/recording-proxy.pem
  echo "HTTPS_PROXY=${HTTPS_PROXY:-} https_proxy=${HTTPS_PROXY:-} SSL_CERT_FILE=$pem PIP_CERT=$pem NODE_EXTRA_CA_CERTS=$pem npm_config_cafile=$pem"
}
inchroot() { chroot "$BASE" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOME=/root LC_ALL=C.UTF-8 TZ=America/Sao_Paulo DEBIAN_FRONTEND=noninteractive $(netenv) "$@"; }
asana() { chroot "$BASE" env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  HOME=/home/ana USER=ana LC_ALL=C.UTF-8 TZ=America/Sao_Paulo $(netenv) setpriv --reuid=ana --regid=ana --init-groups \
  bash -c "cd /home/ana && $1"; }

build() {
  mkdir -p "$CACHE"
  [ -x "$BASE/usr/bin/apt-get" ] || debootstrap --variant=minbase noble "$BASE" "$MIRROR"
  cat > "$BASE/etc/apt/sources.list" <<EOF
deb $MIRROR noble main universe
deb $MIRROR noble-updates main universe
deb $MIRROR noble-security main universe
EOF
  cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  mkdir -p "$BASE/etc/ssl"; [ -f /root/.ccr/ca-bundle.crt ] && cp /root/.ccr/ca-bundle.crt "$BASE/etc/ssl/recording-proxy.pem"
  for d in proc dev sys; do mountpoint -q "$BASE/$d" || mount --bind /$d "$BASE/$d"; done
  trap 'for d in proc dev sys; do umount -l "$BASE/$d" 2>/dev/null || true; done' EXIT
  inchroot apt-get update -q
  inchroot apt-get upgrade -y -q
  inchroot apt-get install -y -q sudo iproute2 procps less ca-certificates tzdata util-linux
  local line; line=$(packages | sed 's/^sudo //' | tr -d '\\\n')
  inchroot $line
  echo nft > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tnft\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  chroot "$BASE" id ana >/dev/null 2>&1 || chroot "$BASE" useradd -m -s /bin/bash ana
  echo 'ana ALL=(ALL) NOPASSWD:ALL' > "$BASE/etc/sudoers.d/ana"

  # Node, the way the lesson that first needs it installs it.
  fetch https://nodejs.org/dist/$NODE/node-$NODE-linux-x64.tar.xz
  [ -x "$BASE/usr/local/bin/node" ] || tar -xJf "$CACHE/node-$NODE-linux-x64.tar.xz" -C "$BASE/usr/local" --strip-components=1
  # JMeter and Gatling, unpacked into ana's home.
  fetch https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER.tgz
  [ -d "$BASE/home/ana/apache-jmeter-$JMETER" ] || asana "tar -xzf /dev/stdin" < "$CACHE/apache-jmeter-$JMETER.tgz"
  fetch https://repo.maven.apache.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/$GATLING/gatling-charts-highcharts-bundle-$GATLING-bundle.zip
  if [ ! -d "$BASE/home/ana/gatling-charts-highcharts-bundle-$GATLING" ]; then
    cp "$CACHE/gatling-charts-highcharts-bundle-$GATLING-bundle.zip" "$BASE/tmp/"
    asana "unzip -q /tmp/gatling-charts-highcharts-bundle-$GATLING-bundle.zip -d ~"
    rm "$BASE/tmp/gatling-charts-highcharts-bundle-$GATLING-bundle.zip"
  fi
  # Python tools, in one virtual environment in ana's home.
  [ -x "$BASE/home/ana/venv/bin/locust" ] || asana "python3 -m venv ~/venv && ~/venv/bin/pip install -q locust==$LOCUST pip-audit==$PIPAUDIT"
  # Node tools.
  [ -x "$BASE/usr/local/bin/artillery" ] || inchroot PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install -g artillery@$ARTILLERY
  [ -x "$BASE/usr/local/bin/lighthouse" ] || inchroot npm install -g lighthouse@$LIGHTHOUSE
  # Playwright's Chromium and the libraries it needs.
  if [ ! -d "$BASE/home/ana/.cache/ms-playwright/chromium-1194" ]; then
    asana "mkdir -p ~/.pwdeps && cd ~/.pwdeps && npm install --no-fund --no-audit -s playwright@$PLAYWRIGHT"
    inchroot bash -c "cd /home/ana/.pwdeps && npx playwright install-deps chromium"
    mkdir -p "$BASE/home/ana/.cache/ms-playwright"
    cp -a /opt/pw-browsers/chromium-1194 /opt/pw-browsers/chromium_headless_shell-1194 "$BASE/home/ana/.cache/ms-playwright/"
    # The recording computer wraps its headless shell in a script that adds
    # three rendering flags; the copy gets the binary Playwright shipped.
    local hs="$BASE/home/ana/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell"
    [ -f "$hs.real" ] && mv "$hs.real" "$hs"
    chroot "$BASE" chown -R ana:ana /home/ana/.cache
    rm -rf "$BASE/home/ana/.pwdeps"
  fi
  # Prometheus, from Ubuntu's archive.
  inchroot apt-get install -y -q prometheus
  # The three Go programs.
  gobuild
  install -m 0755 "$CACHE/bin/k6" "$CACHE/bin/vegeta" "$CACHE/bin/gitleaks" "$BASE/usr/local/bin/"
  inchroot apt-get clean
  rm -f "$BASE/etc/ssl/recording-proxy.pem"
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
  mount -t tmpfs tmpfs "$R/root/dev/shm"
  local flags="--uts --pid --mount --fork"
  [ "$net" = net ] || flags="--net $flags"
  # The holder: a shell in the new namespaces that mounts /proc, names the
  # machine, raises loopback, and waits. Every command after this enters it.
  setsid unshare $flags chroot "$R/root" /bin/bash -c \
    "mount -t proc proc /proc; mount -t sysfs sysfs /sys 2>/dev/null; hostname nft; ip link set lo up; exec -a nft-holder-$name sleep infinity" \
    </dev/null >/dev/null 2>&1 &
  local i p
  for i in $(seq 100); do
    p=$(pgrep -f "^nft-holder-$name infinity$" || true)
    if [ -n "$p" ]; then echo "$p" > "$R/pid"; break; fi
    sleep 0.1
  done
  [ -s "$R/pid" ] || { echo "the holder for $name did not start" >&2; exit 1; }
  if [ "$net" = net ]; then
    cp /etc/resolv.conf "$R/root/etc/resolv.conf"
    if [ -f /root/.ccr/ca-bundle.crt ]; then
      cp /root/.ccr/ca-bundle.crt "$R/root/etc/ssl/recording-proxy.pem"
      netenv | tr ' ' '\n' > "$R/env"
    fi
  fi
}

enter() { local name=$1; shift; local p; p=$(holder "$name") || true
  [ -n "$p" ] || { echo "$name is not up" >&2; exit 1; }
  nsenter -t "$p" -u -p -m -n -r -w env -i TERM=dumb LANG=C.UTF-8 LC_ALL=C.UTF-8 \
    TZ=America/Sao_Paulo PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"; }

as() { local name=$1; shift
  local pre=""
  [ -f "$RUNS/$name/env" ] && pre="export $(tr '\n' ' ' < "$RUNS/$name/env");"
  enter "$name" su - ana -c "$pre cd /home/ana && $1"; }
root() { local name=$1; shift
  enter "$name" bash -lc "$1"; }

# Every fenced block, and every schooling-example, whose first line is a
# comment naming a path under ~ana with at least one directory, written to that
# path. A schooling-example is joined the way the interface's copy button
# joins it: parts, by newlines.
shown() { local name=$1; shift; local R="$RUNS/$name/root"
  python3 - "$R/home/ana" "$@" <<'PY'
import json, os, re, sys
home, files = sys.argv[1], sys.argv[2:]
head = re.compile(r'^(?:#|//|--|;|<!--)\s*((?:[\w.-]+/)+[\w.-]+\.[\w]+)\s*(?:-->)?$')
for md in files:
    text = open(md, encoding='utf-8').read()
    for info, body in re.findall(r'^```([^\n]*)\n(.*?)^```$', text, re.S | re.M):
        if info.strip() == 'schooling-example':
            ex = json.loads(body)
            body = '\n'.join(p['code'] for p in ex['parts']) + '\n'
        first = body.split('\n', 1)[0].strip()
        m = head.match(first)
        if not m:
            continue
        path = os.path.join(home, m.group(1))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(body)
        print(m.group(1), file=sys.stderr)
PY
  chown -R "$(stat -c %u:%g "$R/home/ana")" "$R/home/ana"
}

down() { local name=$1 R="$RUNS/$1" p
  p=$(holder "$name" || true)
  # The holder is init of its PID namespace, which ignores TERM: only KILL ends it.
  [ -n "$p" ] && kill -9 "$p" 2>/dev/null || true
  sleep 0.2
  for m in tmp dev/shm dev ""; do umount -l "$R/root/$m" 2>/dev/null || true; done
  rm -rf "$R"
}

cmd=${1:-}; shift || true
case "$cmd" in
  build|up|as|root|shown|down) "$cmd" "$@" ;;
  *) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
