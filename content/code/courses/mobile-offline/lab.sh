#!/usr/bin/env bash
# The computer every transcript in mobile-offline was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER WITH ONE USER, ana. Lesson 1 tells the student to
# work on their own computer (Linux, WSL on Windows, or a Mac), or in an
# Ubuntu virtual machine, with Node.js 22 installed exactly as lesson 1 of
# `javascript` installs it. The recording machine is itself Ubuntu 24.04, so
# this script makes ana an ordinary user on it, installs Node.js 22.22.0 in her
# ~/.local/node from nodejs.org, and runs every command in her login shell with
# an empty environment. The prompt the transcripts print, ana@dev, is the one
# the student's own terminal shows on a computer called dev.
#
# WHAT IS IN IT
#   Node.js      22.22.0 in ~/.local/node, as `javascript` lesson 1 installs it.
#   sqlite3      Ubuntu's command-line shell for SQLite, which lesson 3 installs
#                with apt (the line is LESSON3 below).
#   everything   else is installed by the lessons, in ~/planner, with npm, at
#                the exact versions the lessons pin.
#
# WHAT IS STAGED, AND WHY
#   - The recording machine reaches the internet through a gateway that
#     re-signs TLS. NODE_EXTRA_CA_CERTS points Node at its certificate, and the
#     proxy variables are passed through. A student's computer talks to npm and
#     GitHub directly and needs neither.
#   - That gateway refuses dl.google.com, which serves the Android SDK and its
#     emulator, and there is no Mac. So no Android or iOS app was built or run:
#     every Kotlin, Swift and React Native listing in the course is quoted from
#     the platform's documentation and marked as not run where it appears.
#   - The clock is the recording machine's, TZ=America/Sao_Paulo. Every date in
#     the planner's data is fixed, in October 2026, and the programs take
#     "today" as an argument rather than reading the clock, so a capture taken
#     on another day prints the same lines.
#
#   sudo bash lab.sh build        the user, Node.js and the apt line (once)
#   sudo bash lab.sh as 'cmd'     run a command as ana, in a login shell, in ~
#   sudo bash lab.sh root 'cmd'   the same as root
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -euo pipefail

NODE=v22.22.0
LESSON3="sqlite3"

build() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  install -m 644 /root/.ccr/ca-bundle.crt /usr/local/share/lab-gateway-ca.crt
  apt-get update -q >/dev/null
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends $LESSON3 >/dev/null
  as "test -x ~/.local/node/bin/node || {
      curl -fsSLO https://nodejs.org/dist/$NODE/node-$NODE-linux-x64.tar.xz &&
      mkdir -p ~/.local/node ~/.local/bin &&
      tar -xJf node-$NODE-linux-x64.tar.xz -C ~/.local/node --strip-components=1 &&
      ln -sf ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/ &&
      rm node-$NODE-linux-x64.tar.xz; }"
}

# as 'command': ana's login shell, in her home, with nothing of the recording
# machine's environment except the proxy and its certificate.
as() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
    LANG=C.UTF-8 TZ=America/Sao_Paulo TERM=dumb PATH=/usr/local/bin:/usr/bin:/bin \
    $(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ') \
    NODE_EXTRA_CA_CERTS=/usr/local/share/lab-gateway-ca.crt \
    NO_UPDATE_NOTIFIER=1 npm_config_update_notifier=false npm_config_fund=false \
    npm_config_audit=false NO_COLOR=1 FORCE_COLOR=0 \
    bash -c 'cd ~; . ~/.profile; eval "$1"' bash "$*"
}

root() { bash -c "$*"; }

case ${1:-} in
  build) build ;;
  as) shift; as "$@" ;;
  root) shift; root "$@" ;;
  *) echo "usage: $0 build|as 'cmd'|root 'cmd'" >&2; exit 2 ;;
esac
