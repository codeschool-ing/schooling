#!/usr/bin/env bash
# The machine every transcript in the front-delivery course was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER, ONE PERSON. ana took javascript and git on it, so
# she has Node.js 22.22.0 in ~/.local/node, installed from the official tarball
# exactly as javascript lesson 1 does it, with node, npm and npx linked into
# ~/.local/bin, and Git from Ubuntu's archive. This course adds nothing to that
# machine but packages from the public npm registry, pinned in the project's
# package.json, and a folder for the work, ~/planner.
#
# Lesson 1 tells the student to install it the same way on the computer they
# use (recommended), or in an Ubuntu 24.04 virtual machine, or online. This
# script builds the same thing on the recording computer: a user, ana, whose
# shell is a login shell with Ubuntu's own PATH, and Node unpacked from
# nodejs.org into her home. Nothing of the recording machine's own Node is on
# her PATH, so every `node` in a transcript is the one the lesson installed.
#
# HOW A TRANSCRIPT IS MADE. Each lesson's captures.sh sources lab/lib.sh and
# types commands at ana's shell, printing the prompt `ana@dev:DIR$ ` before
# each, as a terminal would. Each shell runs in a UTS namespace whose hostname
# is `dev`. Servers that a lesson starts in "a second terminal" are started in
# the background as ana, and their output is printed where the lesson shows
# that terminal.
#
# WHAT IS STAGED rather than typed:
#   - the files ana writes. Each one is shown whole in a lesson, and the
#     capture takes it OUT of that lesson's .md with lab/shown.py, so the
#     program the student reads is the program that ran.
#   - the network. The recording computer reaches the internet through a
#     proxy that re-signs TLS, so ana's shell is given the proxy's variables
#     and NODE_EXTRA_CA_CERTS pointing at its certificate. A student's
#     computer needs neither, and nothing in a transcript shows them. The
#     name lesson 4 serves under, planner.test, is added to no_proxy, since a
#     student's curl would reach it directly.
#   - the browser. Playwright is told, through PLAYWRIGHT_BROWSERS_PATH, to use
#     the Chromium already on the recording computer, in /opt/pw-browsers,
#     which is the build Playwright 1.63.0 downloads. A student downloads the
#     same build with `npx playwright install chromium`, as lesson 6 says.
#   - Git's identity and the clock's zone: ana is "Ana Lima <ana@example.org>",
#     TZ=America/Sao_Paulo. The clock itself is not staged, so a date or a
#     timing is what the machine said that day.
#
#   sudo bash lab.sh up                    create ana (Node is installed by
#                                          lesson 1's captures, as she would)
#   sudo bash lab.sh exec 'command'        one command in ana's shell, in ~/planner
#   sudo bash lab.sh down                  stop every process ana is running
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 (npm 10.9.4), TZ=America/Sao_Paulo,
# in October 2026.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CA=/usr/local/share/node-lab-ca.crt

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Ubuntu's own ~/.profile, which puts ~/.local/bin on the PATH once it exists.
  [ -f /home/ana/.profile ] || cp /etc/skel/.profile /home/ana/.profile
  if [ -f /root/.ccr/ca-bundle.crt ]; then install -m 644 /root/.ccr/ca-bundle.crt $CA; fi
  command -v git >/dev/null || { apt-get update -qq && apt-get install -y -qq git; }
  runuser -u ana -- git config --global user.name 'Ana Lima'
  runuser -u ana -- git config --global user.email ana@example.org
  runuser -u ana -- git config --global init.defaultBranch main
  echo "ana is ready; lesson 1's captures install Node.js and make ~/planner, as she would"
}

# The environment of ana's shell: Ubuntu's PATH, and nothing of this machine's.
# /usr/local is left out: the recording machine keeps a Node of its own there.
ana_env() {
  local net
  net=$(env | grep -iE '^(https?_proxy|no_proxy)=' | sed -E 's/^(no_proxy|NO_PROXY)=(.*)$/\1=\2,planner.test/' | tr '\n' ' ' || true)
  # shellcheck disable=SC2086
  echo env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash LANG=C.UTF-8 TERM=dumb \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo \
    $net ${CA:+NODE_EXTRA_CA_CERTS=$CA} PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
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
