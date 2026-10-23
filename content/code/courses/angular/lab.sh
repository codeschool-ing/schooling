#!/usr/bin/env bash
# The machine every transcript in the angular course was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER, ONE PERSON. ana took the javascript course on it,
# so she already has what its lesson 1 installs: Node.js 22.22.0 unpacked from
# the official tarball into ~/.local/node, with node, npm and npx linked into
# ~/.local/bin, and ~/js-tools holding Playwright 1.56.0 and the page command.
# This course adds a folder for its work, ~/planner, everything npm installs
# into it, and one more program beside page.mjs: look.mjs, which lesson 2
# shows whole.
#
# Lesson 1 tells the student to check that machine (or build it, the way
# javascript lesson 1 does, if they came straight here). This script builds the
# same thing on the recording computer: a user, ana, whose shell is a login
# shell with Ubuntu's own PATH, and Node unpacked from nodejs.org into her
# home. Nothing of the recording machine's own Node is on her PATH, so every
# `node`, `npm` and `ng` in a transcript is the one the lessons installed.
#
# HOW A TRANSCRIPT IS MADE. Each lesson's captures.sh sources lab/lib.sh and
# types commands at ana's shell, printing the prompt `ana@dev:DIR$ ` before
# each, as a terminal would. Each shell runs in a UTS namespace whose hostname
# is `dev`. A server a lesson starts in "a second terminal" (ng serve, the
# small API of lesson 12) is started in the background as ana, and what it
# printed is shown where the lesson shows that terminal.
#
# THE PROJECT GROWS FROM LESSON TO LESSON, as the student's does. Each
# lesson's captures.sh starts from the ~/planner the lesson before it left
# (lib.sh's `restore`) and saves what it leaves (`snapshot`), so the captures
# are run in course order. node_modules is kept in place between lessons and
# reinstalled only when package-lock.json changed.
#
# WHAT IS STAGED rather than typed:
#   - Node.js and ~/js-tools, as javascript lesson 1 leaves them. `up` does
#     the same steps without printing them; lesson 1 here only checks them.
#   - the browser. Playwright 1.56.0 drives the Chromium build it was made
#     for, 141 (chromium_headless_shell-1194), which the recording computer
#     could not download. It had Chromium 153 (build 1243) in
#     /opt/pw-browsers, and `up` links that build where Playwright 1.56.0
#     looks for its own. Every transcript that starts with `look` or `page`
#     was printed through that browser.
#   - the files ana writes. Each one is shown whole in a lesson, and the
#     capture takes it OUT of that lesson's .md with lab/shown.py, so the
#     file the student reads is the file that ran.
#   - the network. The recording computer reaches the internet through a
#     proxy that re-signs TLS, so ana's shell is given the proxy's variables
#     and NODE_EXTRA_CA_CERTS pointing at its certificate. A student's
#     computer needs neither, and nothing in a transcript shows them.
#   - the Angular CLI's question about sharing usage data, which it asks the
#     first time `ng` runs at a terminal. NG_CLI_ANALYTICS=false answers it
#     no; lesson 2 tells the student what the question is.
#   - the colours. NO_COLOR=1 and FORCE_COLOR=0, so a transcript is the text
#     without the escape codes a terminal turns into colour.
#   - the clock's zone: TZ=America/Sao_Paulo. The browser's DATE is fixed
#     where a lesson says so (look --today), because the planner's week total
#     depends on it; the computer's own clock is not staged, so a build time
#     or a timing is what the machine said that day.
#
#   sudo bash lab.sh up                    create ana, Node.js and ~/js-tools
#   sudo bash lab.sh exec 'command'        one command in ana's shell, in ~/planner
#   sudo bash lab.sh script 'script'      a script in a fresh login shell of ana's
#   sudo bash lab.sh down                  stop every process ana is running
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 (npm 10.9.4), the Angular CLI
# 21.2.28 and Angular 21.2.25, TZ=America/Sao_Paulo, in October 2026.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CA=/usr/local/share/angular-lab-ca.crt
NODE_V=v22.22.0
PW_REAL=/opt/pw-browsers/chromium_headless_shell-1243/chrome-headless-shell-linux64

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Ubuntu's own ~/.profile, which puts ~/.local/bin on the PATH once it exists.
  [ -f /home/ana/.profile ] || cp /etc/skel/.profile /home/ana/.profile
  if [ -f /root/.ccr/ca-bundle.crt ]; then install -m 644 /root/.ccr/ca-bundle.crt $CA; fi
  # javascript lesson 1: Node.js from the tarball, linked into ~/.local/bin.
  if [ ! -x /home/ana/.local/node/bin/node ]; then
    run "cd ~ && curl -fsSLO https://nodejs.org/dist/$NODE_V/node-$NODE_V-linux-x64.tar.xz &&
      mkdir -p ~/.local/node ~/.local/bin &&
      tar -xJf node-$NODE_V-linux-x64.tar.xz -C ~/.local/node --strip-components=1 &&
      ln -sf ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/ &&
      rm node-$NODE_V-linux-x64.tar.xz"
  fi
  # javascript lesson 1: ~/js-tools with Playwright 1.56.0, and the page command.
  if [ ! -d /home/ana/js-tools/node_modules/playwright ]; then
    run "mkdir -p ~/js-tools && cd ~/js-tools && npm init -y >/dev/null && npm install --silent playwright@1.56.0"
  fi
  local js=$HERE/../javascript
  node "$js/lab/extract.mjs" "$js/lessons/le-twhd2nyk/your-computer.md" page.mjs > /home/ana/js-tools/page.mjs
  node "$js/lab/extract.mjs" "$js/lessons/le-twhd2nyk/your-computer.md" serve.mjs > /home/ana/js-tools/serve.mjs
  printf '#!/bin/sh\nexec node "$HOME/js-tools/page.mjs" "$@"\n' > /home/ana/.local/bin/page
  chmod +x /home/ana/.local/bin/page
  # The browser Playwright 1.56.0 looks for, linked to the one this machine has.
  local b=/home/ana/.cache/ms-playwright/chromium_headless_shell-1194
  if [ ! -e $b/chrome-linux/headless_shell ]; then
    mkdir -p $b/chrome-linux
    for f in "$PW_REAL"/*; do ln -sf "$f" $b/chrome-linux/; done
    ln -sf "$PW_REAL/chrome-headless-shell" $b/chrome-linux/headless_shell
    touch $b/INSTALLATION_COMPLETE $b/DEPENDENCIES_VALIDATED
  fi
  chown -R ana: /home/ana
  echo "ana is ready: Node.js $NODE_V, ~/js-tools and its browser"
}

# The environment of ana's shell: Ubuntu's PATH, and nothing of this machine's.
# /usr/local and /opt are left out: the recording machine keeps a Node there.
ana_env() {
  local net
  net=$(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ' || true)
  echo env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash LANG=C.UTF-8 TERM=dumb \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo \
    NO_COLOR=1 FORCE_COLOR=0 NG_CLI_ANALYTICS=false \
    npm_config_update_notifier=false npm_config_fund=false \
    $net ${CA:+NODE_EXTRA_CA_CERTS=$CA}
}

# run SCRIPT: a bash script typed into a fresh login shell of ana's, on `dev`.
run() {
  local script=$1
  # shellcheck disable=SC2046
  unshare --uts --fork bash -c 'hostname dev; exec "$@"' _ \
    runuser -u ana -- $(ana_env) bash --noprofile -c ". ~/.profile; $script"
}

case ${1:-} in
  up) up ;;
  exec) shift; run "cd ~/planner 2>/dev/null || cd ~; $*" ;;
  script) shift; run "$1" ;;
  down) pkill -u ana || true ;;
  *) echo "usage: lab.sh up | exec 'command' | script 'script' | down" >&2; exit 2 ;;
esac
