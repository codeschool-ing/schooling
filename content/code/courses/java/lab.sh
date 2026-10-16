#!/usr/bin/env bash
# The machine every transcript in the java course was recorded on.
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Lesson 1 section `the-lab` tells
# the student to have Ubuntu 24.04, on the computer or in a virtual machine,
# and to install two packages from Ubuntu's own archive:
#
#     sudo apt install openjdk-25-jdk maven
#
# This script builds exactly that machine as a chroot of its own,
# because the computer the course was recorded on could not run a hypervisor:
# a stock Ubuntu 24.04 from debootstrap, one user called ana, and those two
# packages installed with apt as the lesson types them. Lesson 1's install is
# captured on a copy of the machine taken BEFORE they were installed, so the
# install the student reads is the one that built every later transcript.
#
#   sudo bash lab.sh build             debootstrap the bare machine (once)
#   sudo bash lab.sh install           copy it and apt-get install the JDK
#                                      and Maven into the copy (once)
#   sudo bash lab.sh bare 'cmd'        run cmd as ana on the bare copy, the
#                                      machine before lesson 1's install
#   sudo bash lab.sh rebare            throw the bare copy away and take a
#                                      new one, for the next failure to stage
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~/DIR, on the
#                                      installed machine
#   sudo bash lab.sh fresh DIR         empty ~/DIR and leave it there
#   sudo bash lab.sh extract MD NAME [K]   print the K-th block of MD that is
#                                      the file NAME (default: the last)
#   sudo bash lab.sh put DIR MD NAME [K]   write that block to ~/DIR/NAME
#
# WHAT A FILE BLOCK IS. An ordinary fence labelled `java` whose FIRST line is
# a comment naming the file, `// Hello.java` or `// src/main/java/.../X.java`;
# a fence labelled `xml` whose first line is `<!-- pom.xml -->`; or a
# `schooling-example` whose `file` is the name, its parts joined with one
# newline as the copy button joins them. So the file a capture runs is the
# block the student copies, and the two cannot drift.
#
# WHAT IS STAGED, AND WHY
#   - THE NETWORK. The recording computer reaches the internet only through
#     an HTTPS proxy that re-signs every certificate. Its certificate is added
#     to the machine's trust store before anything is installed (so the
#     JDK's cacerts, which ca-certificates-java builds from that store, trusts
#     it too), and ~ana/.m2/settings.xml names the proxy so that Maven can
#     reach Maven Central. On the student's machine neither exists and
#     neither is needed. No lesson prints either file.
#   - ana may use sudo without a password, which keeps password prompts out
#     of the transcripts.
#   - The environment of every command is fixed: HOME, PATH, TZ, LANG and
#     nothing else, so nothing from the recording computer leaks in. In
#     particular JAVA_TOOL_OPTIONS, which the recording computer sets and
#     which makes every JVM print a line about it, is absent.
#
#   - Colour. Maven paints its banner and its verdicts with ANSI escapes; the
#     capture scripts strip the escapes and keep the words, which are what
#     the student reads on their own screen.
#
# THE PROMPT in a transcript, ana@vm:~/DIR$, is printed by the capture
# scripts; the container's hostname is vm as well.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
[[ "${BASH_SOURCE[0]}" != "$0" ]] || set -euo pipefail  # sourced by a captures.sh: leave its options alone

BASE=/var/lib/machines/java-base
BARE=/var/lib/machines/java-bare
LIVE=/var/lib/machines/java-lab
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
PROXY=${HTTPS_PROXY:-}
CA=/root/.ccr/agent-proxy-ca.crt
export SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }
# Each command runs in a mount and hostname namespace of its own, chrooted into
# the machine's root: the machine's own /proc, the host's /dev and /sys, and a
# hostname of vm. A chroot rather than a booted container, because nothing in
# this course needs systemd, and because two captures may then run at once.
in_root() { # $1 = machine root, $2 = user, $3 = command
  local R=$1 who=$2 cmd=$3
  unshare -m -u --propagation private bash -c '
    R=$1; who=$2; shift 2
    hostname vm
    mount -t proc proc "$R/proc"
    mount --rbind /dev "$R/dev"
    mount --rbind /sys "$R/sys"
    exec chroot "$R" runuser -u "$who" -- "$@"' _ "$R" "$who" \
    env -i $STUDENT_ENV bash -c "exec 2>&1; cd ~ 2>/dev/null; $cmd"
}

STUDENT_ENV="HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash TERM=dumb \
LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Sao_Paulo COLUMNS=100 \
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

as_ana() { in_root "$1" ana "$2"; }
as_root() { in_root "$1" root "$2"; }

build() {
  need_root
  if [ ! -x "$BASE/usr/bin/apt-get" ]; then
    debootstrap --include=sudo,ca-certificates,curl,file,less,locales,tzdata \
      noble "$BASE" "$MIRROR"
  fi
  printf 'deb %s noble main universe\ndeb %s noble-updates main universe\ndeb http://security.ubuntu.com/ubuntu noble-security main universe\n' \
    "$MIRROR" "$MIRROR" > "$BASE/etc/apt/sources.list"
  rm -f "$BASE/etc/resolv.conf"; cp /etc/resolv.conf "$BASE/etc/resolv.conf"
  echo vm > "$BASE/etc/hostname"
  printf '127.0.0.1\tlocalhost\n127.0.1.1\tvm\n' > "$BASE/etc/hosts"
  ln -sf /usr/share/zoneinfo/America/Sao_Paulo "$BASE/etc/localtime"
  echo America/Sao_Paulo > "$BASE/etc/timezone"
  if [ -r "$CA" ]; then
    install -m 0644 "$CA" "$BASE/usr/local/share/ca-certificates/recording-proxy.crt"
  fi
  as_root "$BASE" '
    update-ca-certificates >/dev/null
    id ana >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash -G sudo ana
    echo "ana ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ana
    chmod 0440 /etc/sudoers.d/ana
    apt-get update -qq'
  rm -rf "$BARE"; cp -a "$BASE" "$BARE"
}

install_jdk() {
  need_root
  rm -rf "$LIVE"; cp -a "$BASE" "$LIVE"
  as_ana "$LIVE" 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-25-jdk maven >/dev/null'
  if [ -n "$PROXY" ]; then
    local host=${PROXY#*://}; host=${host%/}; local port=${host##*:}; host=${host%:*}
    mkdir -p "$LIVE/home/ana/.m2"
    cat > "$LIVE/home/ana/.m2/settings.xml" <<EOF
<settings>
  <proxies>
    <proxy><id>recording</id><active>true</active><protocol>http</protocol>
      <host>$host</host><port>$port</port></proxy>
  </proxies>
</settings>
EOF
    chown -R 1000:1000 "$LIVE/home/ana/.m2"
  fi
  as_ana "$LIVE" 'java -version; mvn -v'
}

_extract() {
python3 - "$@" <<'PY'
import json, re, sys
md, name = sys.argv[1], sys.argv[2]
k = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else 0
text = open(md, encoding='utf-8').read()
blocks = []
for m in re.finditer(r'^```([\w-]*)\n(.*?)^```$', text, re.S | re.M):
    lang, body = m.group(1), m.group(2)
    first = body.split('\n', 1)[0]
    if lang == 'java':
        f = re.fullmatch(r'// ([\w./-]+\.java)', first)
        if f: blocks.append((f.group(1), body))
    elif lang == 'xml':
        f = re.fullmatch(r'<!-- ([\w./-]+\.xml) -->', first)
        if f: blocks.append((f.group(1), body))
    elif lang == 'schooling-example':
        ex = json.loads(body)
        if ex.get('file'):
            blocks.append((ex['file'], '\n'.join(p['code'] for p in ex['parts']) + '\n'))
mine = [b for n, b in blocks if n == name]
if not mine:
    sys.exit(f'{md}: no block is the file {name}')
if k > len(mine):
    sys.exit(f'{md}: {name} appears {len(mine)} times, not {k}')
sys.stdout.write(mine[k - 1] if k else mine[-1])
PY
}

# SOURCED by a lesson's captures.sh, this file gives it five words:
#   at DIR            the directory the next commands run in, ~/DIR
#   fresh DIR         empty ~/DIR and make it the current one
#   put MD NAME [K]   write the K-th block of MD that is the file NAME to ~/DIR/NAME
#   run CMD           print the prompt and CMD, then run it, with 2>&1
#   quiet CMD         run CMD and print nothing
#   block NAME        start a named block of output, ##### NAME
#   bare CMD          run CMD on the machine before lesson 1's install, as run does
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  LAB_SH=$(readlink -f "${BASH_SOURCE[0]}")
  _D=.
  _strip() { sed -e $'s/\x1b\\[[0-9;]*m//g'; }
  _prompt() { if [ "$1" = . ]; then printf 'ana@vm:~$ %s\n' "$2"; else printf 'ana@vm:~/%s$ %s\n' "$1" "$2"; fi; }
  at() { _D=$1; }
  fresh() { _D=$1; bash "$LAB_SH" fresh "$1"; }
  put() { bash "$LAB_SH" put "$_D" "$1" "$2" "${3:-}"; }
  run() { _prompt "$_D" "$*"; bash "$LAB_SH" exec "$_D" "$*" | _strip; }
  quiet() { bash "$LAB_SH" exec "$_D" "$*" >/dev/null 2>&1 || true; }
  block() { printf '##### %s\n' "$1"; }
  bare() { _prompt . "$*"; bash "$LAB_SH" bare "$*" | _strip; }
  rebare() { bash "$LAB_SH" rebare; }
  return 0
fi

case "${1:-}" in
  build) build ;;
  install) install_jdk ;;
  bare) need_root; as_ana "$BARE" "$2" ;;
  rebare) need_root; rm -rf "$BARE"; cp -a "$BASE" "$BARE" ;;
  exec)
    need_root
    [ $# -ge 3 ] || { echo "usage: lab.sh exec DIR 'command'" >&2; exit 2; }
    as_ana "$LIVE" "mkdir -p ~/'$2' && cd ~/'$2' && $3"
    ;;
  fresh)
    need_root
    rm -rf "${LIVE:?}/home/ana/${2:?}"
    as_ana "$LIVE" "mkdir -p ~/'$2'"
    ;;
  extract) _extract "$2" "$3" "${4:-}" ;;
  put)
    need_root
    dir=$2 md=$3 name=$4 k=${5:-}
    body=$(_extract "$md" "$name" "$k"; printf x) || exit 1
    body=${body%x}
    dest="$LIVE/home/ana/$dir/$name"
    mkdir -p "$(dirname "$dest")"
    printf '%s' "$body" > "$dest"
    chown -R 1000:1000 "$LIVE/home/ana/$dir"
    ;;
  *) sed -n '2,30p' "$0" >&2; exit 2 ;;
esac
