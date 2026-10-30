#!/usr/bin/env bash
# The machine every transcript in the swift course was recorded on.
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Lesson 1 section `the-lab` tells
# the student to have Ubuntu 24.04, on the computer or in a virtual machine,
# to install the packages swift.org lists for that release from Ubuntu's own
# archive:
#
#     sudo apt install binutils git gnupg2 libc6-dev libcurl4-openssl-dev \
#       libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 \
#       libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip \
#       zlib1g-dev curl
#
# and to unpack one archive from download.swift.org into ~/.local/share: the
# Swift 6.4.2 toolchain for Ubuntu 24.04
# (swift-6.4.2-RELEASE-ubuntu24.04.tar.gz), checked against the signature
# published beside it with the keys swift.org publishes.
#
# This script builds exactly that machine as a chroot of its own, because
# the computer the course was recorded on could not run a hypervisor: a
# stock Ubuntu 24.04 from debootstrap, one user called ana, and the steps
# above typed as the lesson types them. Lesson 1's install is captured on a
# copy of the machine taken BEFORE anything was installed, so the install
# the student reads is the one that built every later transcript.
#
#   sudo bash lab.sh build             debootstrap the bare machine (once)
#   sudo bash lab.sh install           copy it and run lesson 1's install
#                                      into the copy (once)
#   sudo bash lab.sh bare 'cmd'        run cmd as ana on the bare copy
#   sudo bash lab.sh rebare            throw the bare copy away, take a new one
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~/DIR, on the
#                                      installed machine
#   sudo bash lab.sh fresh DIR         empty ~/DIR and leave it there
#   sudo bash lab.sh extract MD NAME [K]   print the K-th block of MD that is
#                                      the file NAME (default: the last)
#   sudo bash lab.sh put DIR MD NAME [K]   write that block to ~/DIR/NAME
#
# WHAT A FILE BLOCK IS. An ordinary fence labelled `swift` whose FIRST line
# is a comment naming the file, `// Hello.swift` or
# `// Sources/Planner/Week.swift`; a `Package.swift`, whose first line has to
# be `// swift-tools-version:` and which is therefore named by its SECOND
# line, `// Package.swift`; a fence labelled `json` or `sh` that a capture
# names explicitly (see `putraw`); or a `schooling-example` whose `file` is
# the name, its parts joined with one newline as the copy button joins them.
# So the file a capture compiles is the block the student copies, and the
# two cannot drift.
#
# WHAT IS STAGED, AND WHY
#   - THE NETWORK. The recording computer reaches the internet only through
#     an HTTPS proxy that re-signs every certificate. Its certificate is added
#     to the machine's trust store before anything is installed; ~ana/.curlrc
#     names the proxy for curl and ~ana/.gitconfig names it for git, which is
#     what Swift Package Manager fetches a dependency with in lesson 19; and
#     HTTPS_PROXY is in the environment of every command, for the same
#     reason. Each exempts localhost, so lesson 20's curl reaches the server
#     on the same machine as it does on the student's. On the student's
#     machine none of these exists and none is needed. No lesson prints them.
#   - PATH. Lesson 1 appends one line to ~/.bashrc that puts the toolchain's
#     usr/bin on PATH. A capture runs a non-interactive shell, which never
#     reads ~/.bashrc, so the same directory is written into the environment
#     below instead. Before the install it does not exist, and
#     `command not found` is still what the bare machine says.
#   - ana may use sudo without a password, which keeps password prompts out
#     of the transcripts.
#   - The environment of every command is fixed: HOME, PATH, TZ, LANG, the
#     proxy and nothing else.
#   - Colour. swift and swiftc paint diagnostics with ANSI escapes when they
#     think a person is watching; the capture scripts strip any escapes and
#     keep the words.
#
# THE PROMPT in a transcript, ana@vm:~/DIR$, is printed by the capture
# scripts; the chroot's hostname is vm as well.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
[[ "${BASH_SOURCE[0]}" != "$0" ]] || set -euo pipefail  # sourced by a captures.sh: leave its options alone

BASE=/var/lib/machines/swift-base
BARE=/var/lib/machines/swift-bare
LIVE=/var/lib/machines/swift-lab
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
PROXY=${HTTPS_PROXY:-}
CA=/root/.ccr/agent-proxy-ca.crt
SWIFT=6.4.2
TOOLCHAIN=/home/ana/.local/share/swift-$SWIFT-RELEASE-ubuntu24.04

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }
# Each command runs in a mount and hostname namespace of its own, chrooted into
# the machine's root: the machine's own /proc, the host's /dev and /sys, and a
# hostname of vm.
in_root() { # $1 = machine root, $2 = user, $3 = command
  local R=$1 who=$2 cmd=$3
  unshare -m -u --propagation private bash -c '
    R=$1; who=$2; shift 2
    hostname vm
    mount -t proc proc "$R/proc"
    mount --rbind /dev "$R/dev"
    mount --rbind /sys "$R/sys"
    mount -t tmpfs tmpfs "$R/tmp"
    exec chroot "$R" runuser -u "$who" -- "$@"' _ "$R" "$who" \
    env -i $STUDENT_ENV ${PROXY:+HTTPS_PROXY=$PROXY https_proxy=$PROXY NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1} \
    ${PLAIN_PATH:+PATH=/usr/local/bin:/usr/bin:/bin} bash -c "exec 2>&1; cd ~ 2>/dev/null; $cmd"
}

STUDENT_ENV="HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash TERM=dumb \
LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Sao_Paulo COLUMNS=100 \
PATH=$TOOLCHAIN/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

as_ana() { in_root "$1" ana "$2"; }
as_root() { in_root "$1" root "$2"; }

stage_proxy() { # $1 = machine root
  [ -n "$PROXY" ] || return 0
  local R=$1
  printf 'proxy = "%s"\nnoproxy = "localhost,127.0.0.1"\n' "$PROXY" > "$R/home/ana/.curlrc"
  printf '[http]\n\tproxy = %s\n[user]\n\tname = Ana\n\temail = ana@example.com\n[init]\n\tdefaultBranch = main\n' \
    "$PROXY" > "$R/home/ana/.gitconfig"
  chown 1000:1000 "$R/home/ana/.curlrc" "$R/home/ana/.gitconfig"
}

build() {
  need_root
  if [ ! -x "$BASE/usr/bin/apt-get" ]; then
    debootstrap --include=sudo,ca-certificates,file,less,locales,tzdata,python3 \
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
  stage_proxy "$BASE"
  rm -rf "$BARE"; cp -a "$BASE" "$BARE"
}

# Lesson 1's install, as the lesson types it.
PACKAGES="binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl"
TARBALL=swift-$SWIFT-RELEASE-ubuntu24.04.tar.gz
URL=https://download.swift.org/swift-$SWIFT-release/ubuntu2404/swift-$SWIFT-RELEASE/$TARBALL
INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PACKAGES >/dev/null
mkdir -p ~/downloads ~/.local/share && cd ~/downloads
curl -fsSLO $URL
curl -fsSLO $URL.sig
curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --import - 2>/dev/null
gpg --verify $TARBALL.sig $TARBALL
tar -xzf $TARBALL -C ~/.local/share
echo 'export PATH=\"\$HOME/.local/share/swift-$SWIFT-RELEASE-ubuntu24.04/usr/bin:\$PATH\"' >> ~/.bashrc"

install_sw() {
  need_root
  rm -rf "$LIVE"; cp -a "$BASE" "$LIVE"
  as_ana "$LIVE" "$INSTALL"
  as_ana "$LIVE" 'swift --version'
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
    lines = body.split('\n')
    first = lines[0]
    if lang == 'swift':
        f = re.fullmatch(r'// ([\w./+-]+\.swift)', first)
        if not f and first.startswith('// swift-tools-version'):
            # a manifest's tools version has to be its first line, so its name is the second
            f = re.fullmatch(r'// ([\w./+-]*Package\.swift)', (lines + [''])[1])
        if f: blocks.append((f.group(1), body))
    elif lang in ('json', 'sh', 'yaml'):
        f = re.fullmatch(r'(?://|#) ([\w./-]+)', first)
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

# SOURCED by a lesson's captures.sh, this file gives it these words:
#   at DIR            the directory the next commands run in, ~/DIR
#   fresh DIR         empty ~/DIR and make it the current one
#   put MD NAME [K]   write the K-th block of MD that is the file NAME to ~/DIR/NAME
#   run CMD           print the prompt and CMD, then run it, with 2>&1
#   quiet CMD         run CMD and print nothing
#   block NAME        start a named block of output, ##### NAME
#   bare CMD          run CMD on the machine before lesson 1's install, as run does,
#                     in ~/$BARE_D when that is set
#   bare_quiet CMD    the same, printing nothing: what a capture stages
#   sr FILE.swift BLOCK   a block that runs FILE.swift from $MD with `swift FILE.swift`
#   sc FILE.swift BLOCK   a block that compiles it with swiftc and runs the binary
#   se FILE.swift BLOCK   a block that only compiles it, for a refusal
# PLAIN_PATH=1 in the environment runs a command with the PATH a terminal has
# before ~/.bashrc added the toolchain to it.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  LAB_SH=$(readlink -f "${BASH_SOURCE[0]}")
  _D=.
  _strip() { sed -e $'s/\x1b\\[[0-9;]*[mK]//g'; }
  _prompt() { if [ "$1" = . ]; then printf 'ana@vm:~$ %s\n' "$2"; else printf 'ana@vm:~/%s$ %s\n' "$1" "$2"; fi; }
  at() { _D=$1; }
  fresh() { _D=$1; bash "$LAB_SH" fresh "$1"; }
  put() { bash "$LAB_SH" put "$_D" "$1" "$2" "${3:-}"; }
  run() { _prompt "$_D" "$*"; bash "$LAB_SH" exec "$_D" "$*" | _strip; }
  quiet() { bash "$LAB_SH" exec "$_D" "$*" >/dev/null 2>&1 || true; }
  block() { printf '##### %s\n' "$1"; }
  bare() { _prompt "${BARE_D:-.}" "$*"; bash "$LAB_SH" bare "${BARE_D:+cd ~/$BARE_D && }$*" | _strip; }
  bare_quiet() { bash "$LAB_SH" bare "${BARE_D:+cd ~/$BARE_D && }$*" >/dev/null 2>&1 || true; }
  rebare() { bash "$LAB_SH" rebare; }
  _bin() { echo "${1%.swift}" | tr 'A-Z' 'a-z'; }
  sr() { block "$2"; put "$MD" "$1"; run "swift $1"; }
  sc() { block "$2"; put "$MD" "$1"; run "swiftc $1 -o $(_bin "$1") && ./$(_bin "$1")"; }
  se() { block "$2"; put "$MD" "$1"; run "swiftc $1 -o $(_bin "$1")"; }
  return 0
fi

case "${1:-}" in
  build) build ;;
  install) install_sw ;;
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
  *) sed -n '2,45p' "$0" >&2; exit 2 ;;
esac
