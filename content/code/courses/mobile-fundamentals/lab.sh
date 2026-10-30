#!/usr/bin/env bash
# The machine every transcript in mobile-fundamentals was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER CALLED `dev`, WITH ONE USER, ana. Lesson 1 tells the
# student to work on their own computer (Linux, WSL or a Mac), in an Ubuntu
# virtual machine, or online. This course needs no phone, no Android SDK and
# no Mac: everything it runs is TypeScript on Node.js, plus SQLite through
# better-sqlite3 in lesson 16. So the machine is an ordinary user account:
#
#   ana          an ordinary user, uid 1500, home /home/ana
#   Node.js      22.22.0 in ~/.local/node, from nodejs.org's tarball, checked
#                against its published SHA-256, with node, npm and npx linked
#                into ~/.local/bin: exactly as lesson 1 of `javascript`
#                installs it, which lesson 1 of this course names
#   git          from Ubuntu's archive
#
# WHAT IS STAGED, AND WHY
#   - Each lesson is recorded in a home of its own, /var/lib/mflab/homes/LESSON,
#     mounted over /home/ana in a private mount namespace, so that two lessons
#     captured at once cannot see each other's files. It runs in a PID namespace
#     of its own as well, so a process id a program prints (Node.js puts one in
#     every warning) is the same on every run. Node.js is mounted at
#     ~/.local/node in every one of them from a single copy. A student has one
#     home and one ~/planner, and the lessons say which files each one adds.
#   - The recording machine reaches the internet through a gateway that
#     re-signs TLS. Its certificate bundle is copied to /var/lib/mflab/ca.crt
#     and npm and Node are pointed at it (npm_config_cafile,
#     NODE_EXTRA_CA_CERTS). A student's computer talks to the registry
#     directly and needs neither.
#   - The clock is the recording machine's, TZ=America/Sao_Paulo. The planner's
#     data carries fixed dates in the week of Monday 2026-10-19, and the
#     programs are given "today" as 2026-10-21 rather than reading the clock.
#   - Not run here, and said so in every lesson that shows it: Android Studio
#     and the Android SDK (dl.google.com, which serves them, is refused by the
#     gateway), Xcode and the iOS simulator (there is no Mac), Expo on a phone,
#     and anything in a store console. The Kotlin, Swift and React Native
#     fragments the lessons show side by side are quoted from each platform's
#     documentation and were not compiled.
#
#   sudo bash lab.sh up                 create ana and install Node (idempotent)
#   sudo bash lab.sh reset LESSON       empty that lesson's home
#   sudo bash lab.sh as LESSON 'cmd'    run cmd as ana, in a login-like shell,
#                                       with that lesson's home as /home/ana
#   sudo bash lab.sh path LESSON        print where that lesson's home is
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -euo pipefail

BASE=/var/lib/mflab
NODE_VERSION=22.22.0
NODE_SHA256=9aa8e9d2298ab68c600bd6fb86a6c13bce11a4eca1ba9b39d79fa021755d7c37
NODE_TAR=node-v$NODE_VERSION-linux-x64.tar.xz
CA_SRC=${CA_SRC:-/root/.ccr/ca-bundle.crt}

up() {
  id ana >/dev/null 2>&1 || useradd -m -u 1500 -s /bin/bash ana
  mkdir -p $BASE/homes
  if [ ! -x $BASE/node/bin/node ]; then
    local t; t=$(mktemp -d)
    curl -fsSL -o "$t/$NODE_TAR" "https://nodejs.org/dist/v$NODE_VERSION/$NODE_TAR"
    echo "$NODE_SHA256  $t/$NODE_TAR" | sha256sum -c --quiet
    mkdir -p $BASE/node
    tar -xJf "$t/$NODE_TAR" -C $BASE/node --strip-components=1
    rm -rf "$t"
    chown -R ana:ana $BASE/node
  fi
  [ -f "$CA_SRC" ] && install -m 0644 "$CA_SRC" $BASE/ca.crt || true
  if [ ! -d $BASE/skel ]; then
    mkdir -p $BASE/skel/.local/node $BASE/skel/.local/bin
    for b in node npm npx; do ln -s /home/ana/.local/node/bin/$b $BASE/skel/.local/bin/$b; done
    cat > $BASE/skel/.gitconfig <<'GIT'
[user]
	name = Ana Lima
	email = ana@example.org
[init]
	defaultBranch = main
GIT
    chown -R ana:ana $BASE/skel
  fi
}

home() { # home LESSON: create it from the skeleton when it is missing
  local h=$BASE/homes/$1
  [ -d "$h" ] || { cp -a $BASE/skel "$h"; chown ana:ana "$h"; }
  printf '%s' "$h"
}

as() { # as LESSON 'cmd'
  local h; h=$(home "$1"); shift
  local cmd=$*
  unshare -m --propagation private --pid --fork --mount-proc -- bash -c '
    mount --bind "$1" /home/ana
    mount --bind '"$BASE"'/node /home/ana/.local/node
    exec runuser -u ana -- env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash \
      PATH=/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin \
      TZ=America/Sao_Paulo LANG=C.UTF-8 LC_ALL=C.UTF-8 TERM=dumb \
      NO_COLOR=1 NODE_DISABLE_COLORS=1 FORCE_COLOR=0 \
      npm_config_update_notifier=false npm_config_fund=false npm_config_audit=false \
      npm_config_cafile='"$BASE"'/ca.crt NODE_EXTRA_CA_CERTS='"$BASE"'/ca.crt \
      HTTPS_PROXY="${HTTPS_PROXY:-}" HTTP_PROXY="${HTTP_PROXY:-}" NO_PROXY="127.0.0.1,localhost" \
      https_proxy="${HTTPS_PROXY:-}" http_proxy="${HTTP_PROXY:-}" no_proxy="127.0.0.1,localhost" \
      bash -c "cd /home/ana && $2"
  ' _ "$h" "$cmd"
}

case ${1:-} in
  up) up ;;
  reset) up; rm -rf "${BASE:?}/homes/${2:?lesson}"; home "$2" >/dev/null ;;
  as) up; as "${2:?lesson}" "${3:?command}" ;;
  path) up; home "${2:?lesson}"; echo ;;
  *) sed -n '2,45p' "$0"; exit 2 ;;
esac
