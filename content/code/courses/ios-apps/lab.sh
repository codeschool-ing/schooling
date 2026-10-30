#!/usr/bin/env bash
# The machine every transcript in the ios-apps course was recorded on.
#
# THE STUDENT NEVER SEES THIS FILE (C-40). Lesson 1 section `the-lab` tells
# the student what this course can run without a Mac and what it cannot, and
# for the half that runs anywhere it asks for Ubuntu 24.04, on the computer
# or in a virtual machine, with the Swift 6.4.2 toolchain installed the way
# swift.org documents it for Linux:
#
#     sudo apt install binutils git gnupg2 libc6-dev libcurl4-openssl-dev \
#       libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 \
#       libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip \
#       zlib1g-dev curl
#
# then the release archive and its signature from download.swift.org,
# checked with gpg against the keys swift.org publishes, unpacked into
# ~/.local/share, and its usr/bin put on PATH. That is the same toolchain the
# `swift` course installs, and lesson 1 here repeats it in brief.
#
# This script builds exactly that machine as a chroot of its own, because
# the computer the course was recorded on could not run a hypervisor: a
# stock Ubuntu 24.04 from debootstrap, one user called ana, and the steps
# above typed as the lesson types them. Lesson 1's install is captured on a
# copy of the machine taken BEFORE anything was installed.
#
# WHAT WAS NOT RUN, AND CANNOT BE HERE. There is no Mac and no Xcode on the
# recording computer, so nothing that needs SwiftUI, SwiftData, UIKit, the
# simulator, a device, signing or App Store Connect was run. The lessons say
# so where it happens. Everything captured is plain Swift: the planner's
# package, its tests, Observation, Codable, URLSession from
# FoundationNetworking against a server on the same machine.
#
#   sudo bash lab.sh build             the bare machine (debootstrap, once)
#   sudo bash lab.sh install           copy it and run lesson 1's install
#   sudo bash lab.sh bare 'cmd'        run cmd as ana on the bare copy
#   sudo bash lab.sh rebare            throw the bare copy away, take a new one
#   sudo bash lab.sh exec DIR 'cmd'    run cmd as ana, in ~/DIR, installed
#   sudo bash lab.sh fresh DIR         empty ~/DIR and leave it there
#   sudo bash lab.sh extract MD NAME [K]   print the K-th block of MD that is
#                                      the file NAME (default: the last)
#   sudo bash lab.sh put DIR MD NAME [K]   write that block to ~/DIR/NAME
#
# WHAT A FILE BLOCK IS. An ordinary fence labelled `swift` whose FIRST line
# is a comment naming the file, `// Sources/PlannerCore/Plan.swift` (a
# manifest's first line is `// swift-tools-version`, which names it
# Package.swift); an `xml` fence whose SECOND line is `<!-- NAME -->`; a
# fence labelled `json`, `python` or `sh` whose first line names it the
# same way (`# serve.py`) — JSON cannot carry a comment, so a JSON file is
# written by the lesson with a heredoc instead; or a `schooling-example`
# whose `file` is the name, its parts joined as the copy button joins them.
# So the file a capture compiles is the block the student copies.
#
# WHAT IS STAGED, AND WHY
#   - THE NETWORK. The recording computer reaches the internet only through
#     an HTTPS proxy that re-signs every certificate. Its certificate is
#     added to the machine's trust store before anything is installed, and
#     ~ana/.curlrc names the proxy for curl (exempting localhost, so a
#     lesson's curl reaches the server on the same machine as it does on
#     the student's). `swift package` reaches GitHub through git, so
#     ~ana/.gitconfig names the proxy for git. On the student's machine none
#     of these exists and none is needed. No lesson prints them.
#   - GPG. The keyring is fetched with curl (through the proxy) and piped
#     into gpg, as the lesson shows; no key server is contacted.
#   - PATH. Lesson 1 appends one line to ~/.bashrc. A capture runs a
#     non-interactive shell, which never reads ~/.bashrc, so the same
#     directory is written into the environment below instead.
#   - ana may use sudo without a password, which keeps prompts out of the
#     transcripts.
#   - The environment of every command is fixed: HOME, PATH, TZ, LANG.
#   - Colour. swift build paints some lines; the scripts strip the escapes.
#   - `swift run`. In the recording sandbox, `swift run` prints two lines,
#     `warning: safeExec: signal(32, SIG_DFL) failed`, because the sandbox
#     refuses to reset the real-time signals; a student's machine does not.
#     So the transcripts run `swift build` and then the program it built,
#     `.build/debug/<name>`, which is the same program and prints nothing
#     extra.
#   - TIMINGS. `swift build` and `swift test` print how long they took;
#     those numbers are whatever this machine took, and the prose never
#     quotes one as a property of Swift.
#
# Recorded on Ubuntu 24.04 with Swift 6.4.2, TZ=America/Sao_Paulo.
[[ "${BASH_SOURCE[0]}" != "$0" ]] || set -euo pipefail

BASE=/var/lib/machines/ios-base
BARE=/var/lib/machines/ios-bare
LIVE=/var/lib/machines/ios-lab
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
PROXY=${HTTPS_PROXY:-}
CA=/root/.ccr/agent-proxy-ca.crt
SWIFT=6.4.2
TOOLCHAIN=swift-$SWIFT-RELEASE-ubuntu24.04
SWIFT_URL=https://download.swift.org/swift-$SWIFT-release/ubuntu2404/swift-$SWIFT-RELEASE/$TOOLCHAIN.tar.gz
DEPS="binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl"

need_root() { [ "$(id -u)" = 0 ] || { echo "lab.sh: run me as root" >&2; exit 1; }; }
in_root() { # $1 = machine root, $2 = user, $3 = command
  local R=$1 who=$2 cmd=$3
  unshare -m -u --propagation private bash -c '
    R=$1; who=$2; shift 2
    hostname vm
    mount -t proc proc "$R/proc"
    mount --rbind /dev "$R/dev"
    mount --rbind /sys "$R/sys"
    mount -t tmpfs tmpfs "$R/tmp" -o mode=1777
    exec chroot "$R" runuser -u "$who" -- "$@"' _ "$R" "$who" \
    env -i $STUDENT_ENV ${PLAIN_PATH:+PATH=/usr/local/bin:/usr/bin:/bin} bash -c "exec 2>&1; cd ~ 2>/dev/null; $cmd"
}

STUDENT_ENV="HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash TERM=dumb \
LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Sao_Paulo COLUMNS=100 \
PATH=/home/ana/.local/share/$TOOLCHAIN/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

as_ana() { in_root "$1" ana "$2"; }
as_root() { in_root "$1" root "$2"; }

stage_proxy() { # $1 = machine root
  [ -n "$PROXY" ] || return 0
  local R=$1
  printf 'proxy = "%s"\nnoproxy = "localhost,127.0.0.1"\n' "$PROXY" > "$R/home/ana/.curlrc"
  printf '[http]\n\tproxy = %s\n' "$PROXY" > "$R/home/ana/.gitconfig"
  chown 1000:1000 "$R/home/ana/.curlrc" "$R/home/ana/.gitconfig"
}

build() {
  need_root
  if [ ! -x "$BASE/usr/bin/apt-get" ]; then
    debootstrap --include=sudo,ca-certificates,file,less,locales,tzdata,python3,curl \
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
INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $DEPS >/dev/null
mkdir -p ~/downloads ~/.local/share && cd ~/downloads
curl -fsSLO -C - --retry 5 --retry-all-errors $SWIFT_URL
curl -fsSLO $SWIFT_URL.sig
curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --import - 2>/dev/null
gpg --verify $TOOLCHAIN.tar.gz.sig 2>/dev/null
tar xzf $TOOLCHAIN.tar.gz -C ~/.local/share
echo 'export PATH=\"\$HOME/.local/share/$TOOLCHAIN/usr/bin:\$PATH\"' >> ~/.bashrc"

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
    first = body.split('\n', 1)[0]
    if lang == 'swift':
        if first.startswith('// swift-tools-version'):
            blocks.append(('Package.swift', body)); continue
        f = re.fullmatch(r'// ([\w./+-]+\.swift)', first)
        if f: blocks.append((f.group(1), body))
    elif lang == 'xml':
        f = re.fullmatch(r'<!-- ([\w./-]+) -->', (body.split('\n') + [''])[1])
        if f: blocks.append((f.group(1), body))
    elif lang in ('python', 'sh', 'yaml', 'toml'):
        if first.startswith('#!'):
            first = (body.split('\n') + [''])[1]
        f = re.fullmatch(r'# ([\w./-]+)', first)
        if f: blocks.append((f.group(1), body))
    elif lang == 'schooling-example':
        ex = json.loads(body)
        if ex.get('file'):
            blocks.append((ex['file'], ''.join(p['code'] if p['code'].endswith('\n') else p['code'] + '\n' for p in ex['parts'])))
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
#   bare CMD          run CMD on the machine before lesson 1's install
#   bare_quiet CMD    the same, printing nothing
#   copy FROM TO      copy ~/FROM to ~/TO on the installed machine (a lesson
#                     that starts from the package the last one finished)
# PLAIN_PATH=1 runs a command with the PATH a terminal has before ~/.bashrc
# added the toolchain to it.
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  LAB_SH=$(readlink -f "${BASH_SOURCE[0]}")
  _D=.
  _strip() { sed -e $'s/\x1b\\[[0-9;?]*[A-Za-z]//g' -e $'s/\r$//'; }
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
  copy() { bash "$LAB_SH" copy "$1" "$2"; }
  # ibare CMD...      the commands, one after another, in ONE interactive
  #                   terminal on the bare machine that has not read ~/.bashrc
  #                   (bash --norc -i under `script`, for a terminal), with
  #                   PLAIN_PATH: the terminal that was open before the
  #                   install's line was added. `source ~/.bashrc` then does
  #                   what it does for the student, which a non-interactive
  #                   shell would refuse to (Ubuntu's ~/.bashrc returns early
  #                   when the shell is not interactive).
  ibare() {
    local s="__s=0; " c
    for c in "$@"; do s+="printf '%s\\n' $(printf %q "ana@vm:~\$ $c"); (exit \$__s); $c; __s=\$?; "; done
    PLAIN_PATH=1 bash "$LAB_SH" bare "script -qc $(printf %q "bash --norc -i -c $(printf %q "$s")") /dev/null" | _strip
  }
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
  copy)
    need_root
    rm -rf "${LIVE:?}/home/ana/${3:?}"
    cp -a "$LIVE/home/ana/${2:?}" "$LIVE/home/ana/$3"
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
