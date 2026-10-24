#!/usr/bin/env bash
# The machine every transcript in front-multiplatform was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER CALLED `dev`, WITH ONE USER, ana. Lesson 1 tells
# the student to work on their own computer, with Linux, WSL or a Mac, or in
# an Ubuntu virtual machine. This script builds the same computer as a
# systemd-nspawn container, because the machine the course was recorded on
# could not run a hypervisor: the same release and the same packages from
# Ubuntu's archive, with ana as an ordinary user, so Electron's sandbox and
# every file permission behave as they do on a laptop. It has no screen: a
# window opens on Xvfb, the virtual display lesson 11 explains, and nothing
# else about the programs changes.
#
# WHAT IS IN IT
#   apt          the packages of LESSON_APT below, which are the lines lessons
#                1, 3, 11 and 12 print. The base has them all installed, so a
#                lesson's transcript is never a download log.
#   Node.js      22.22.0 in ~/.local/node, installed exactly as lesson 1 of
#                `javascript` installs it (this course does not install it
#                again; it checks the version).
#   Rust         from rustup-init, in ~/.cargo, as lesson 12 installs it.
#   everything   else is installed by the lessons, inside each project, with
#                npm, at the exact versions the lessons pin.
#
# WHAT IS STAGED, AND WHY
#   - The recording machine reaches the internet through a gateway that
#     re-signs TLS. Its certificates are added to the machine's trust store,
#     and NODE_EXTRA_CA_CERTS points Node at the same store. A student's
#     computer talks to the registry directly and needs neither.
#   - That gateway refuses dl.google.com, which serves the Android SDK, the
#     Android Gradle plugin and Android Studio. So no Android build, emulator
#     or APK was ever made here: lesson 3 says so where it shows the steps.
#   - It also refuses api.expo.dev, which the Expo CLI asks about versions:
#     the expo commands run with EXPO_OFFLINE=1, set in the environment and
#     not typed. Two lines of `npx expo install` in lesson 8 come from it, and
#     the lesson says so; EAS, which needs an Expo account, was never run.
#   - Playwright's browser is the build already on the recording machine
#     (/opt/pw-browsers, bound read-only into the container), the same
#     version `npx playwright install chromium` downloads for Playwright
#     1.63.0. PLAYWRIGHT_BROWSERS_PATH points at it.
#   - rustup's one-line installer at sh.rustup.rs is refused by the gateway;
#     its own binary, rustup-init, comes from static.rust-lang.org and is
#     what that one-liner downloads and runs. Lesson 12 shows that form.
#   - The clock is the recording machine's, TZ=America/Sao_Paulo; the data
#     the lessons use carries fixed dates in October 2026, and the planner
#     is opened with ?today=2026-10-21 so its week is that week.
#
#   sudo bash lab.sh build        debootstrap and the packages (once)
#   sudo bash lab.sh up           start the machine (idempotent)
#   sudo bash lab.sh as 'cmd'     run a command as ana, in a login shell, in ~
#   sudo bash lab.sh root 'cmd'   the same as root
#   sudo bash lab.sh down
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

M=${FM_MACHINE:-/var/lib/machines/fm}
PIDF=/run/front-multiplatform-lab.pid
MIRROR=${MIRROR:-http://archive.ubuntu.com/ubuntu}
CA_DIR=${CA_DIR:-/usr/local/share/ca-certificates}
export SYSTEMD_NSPAWN_UNIFIED_HIERARCHY=1

# The apt lines, as the lessons print them.
LESSON1="git curl ca-certificates"
LESSON3="openjdk-21-jdk-headless"
LESSON11="libgtk-3-0t64 libnss3 libxss1 libasound2t64 libgbm1 libxkbcommon0 libatk-bridge2.0-0t64 libcups2t64 xvfb xauth"
LESSON12="build-essential pkg-config libwebkit2gtk-4.1-dev libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev file wget"
# Not a lesson's: what makes a container look like a desktop to the programs
# that run on it. dbus is the bus every Linux desktop has; x11-apps, x11-utils and
# imagemagick let the lab list the windows on the virtual display.
DESKTOP="dbus dbus-x11 x11-apps x11-utils imagemagick fonts-dejavu-core fonts-liberation2 xz-utils locales tzdata sudo"
NODE=v22.22.0

net_env() {
  env | grep -iE '^(https?_proxy|no_proxy)=' | sed 's/^/--setenv=/' | tr '\n' ' '
}

build() {
  [ -d "$M" ] && { echo "$M exists; remove it to rebuild" >&2; exit 1; }
  debootstrap --variant=minbase --include=ca-certificates,curl noble "$M" "$MIRROR"
  cp "$CA_DIR"/*.crt "$M/usr/local/share/ca-certificates/" 2>/dev/null || true
  cat > "$M/root/build.sh" <<EOF
set -e
export DEBIAN_FRONTEND=noninteractive
cat > /etc/apt/sources.list.d/ubuntu.sources <<S
Types: deb
URIs: $MIRROR
Suites: noble noble-updates noble-security
Components: main universe
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
S
rm -f /etc/apt/sources.list
update-ca-certificates >/dev/null
apt-get update -q >/dev/null
apt-get install -y -q --no-install-recommends $LESSON1 $LESSON3 $LESSON11 $LESSON12 $DESKTOP
useradd -m -s /bin/bash ana
echo dev > /etc/hostname
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
EOF
  # shellcheck disable=SC2046
  systemd-nspawn -q --register=no --keep-unit -D "$M" $(net_env) bash /root/build.sh
  up
  # Node.js, as lesson 1 of javascript installs it.
  as "curl -fsSLO https://nodejs.org/dist/$NODE/node-$NODE-linux-x64.tar.xz &&
      mkdir -p ~/.local/node ~/.local/bin &&
      tar -xJf node-$NODE-linux-x64.tar.xz -C ~/.local/node --strip-components=1 &&
      ln -sf ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/ &&
      rm node-$NODE-linux-x64.tar.xz"
}

pid() { cat "$PIDF" 2>/dev/null; }
running() { local p; p=$(pid) && [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }

up() {
  running && return 0
  setsid systemd-nspawn -q --register=no --keep-unit --hostname=dev -D "$M" --as-pid2 \
    --bind-ro=/opt/pw-browsers sleep infinity </dev/null >/run/front-multiplatform-lab.log 2>&1 &
  local n=$! p=
  for _ in $(seq 50); do p=$(pgrep -P $n | head -1) && [ -n "$p" ] && break; sleep 0.2; done
  [ -n "$p" ] || { echo "the machine did not start; see /run/front-multiplatform-lab.log" >&2; exit 1; }
  echo "$p" > "$PIDF"
  # The system bus a desktop has, for the programs that look for it.
  nsenter -t "$p" -a bash -c 'mkdir -p /run/dbus && dbus-daemon --system --fork' >/dev/null 2>&1 || true
}

down() {
  running || return 0
  local n
  n=$(ps -o ppid= -p "$(pid)" | tr -d ' ')
  kill "$n" 2>/dev/null || true
  for _ in $(seq 50); do kill -0 "$n" 2>/dev/null || break; sleep 0.2; done
  rm -f "$PIDF"
}

# as 'command': ana's login shell, in her home, with nothing of the recording
# machine's environment except the proxy and its certificate.
as() {
  up
  # shellcheck disable=SC2046
  nsenter -t "$(pid)" -a runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana \
    LANG=C.UTF-8 TZ=America/Sao_Paulo TERM=dumb PATH=/usr/sbin:/usr/bin:/sbin:/bin \
    $(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ') \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt \
    PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers EXPO_OFFLINE=1 \
    NO_UPDATE_NOTIFIER=1 npm_config_update_notifier=false npm_config_fund=false NO_COLOR=1 FORCE_COLOR=0 \
    bash -c '. ~/.profile; [ -f ~/.cargo/env ] && . ~/.cargo/env; cd ~; eval "$1"' bash "$*"
}

root() { up; nsenter -t "$(pid)" -a bash -c "$*"; }

case ${1:-} in
  build) build ;;
  up) up ;;
  down) down ;;
  as) shift; as "$@" ;;
  root) shift; root "$@" ;;
  *) echo "usage: $0 build|up|down|as 'cmd'|root 'cmd'" >&2; exit 2 ;;
esac
