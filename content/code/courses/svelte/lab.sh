#!/usr/bin/env bash
# The machine every transcript in the svelte course was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER, ONE PERSON. ana took the javascript course on it,
# so she already has Node.js 22.22.0 in ~/.local/node, installed from the
# official tarball exactly as javascript lesson 1 does it, with node, npm and
# npx linked into ~/.local/bin. This course adds to that machine only what its
# lessons tell the student to add: the planner project in ~/planner, made by
# `npx sv create` in lesson 1 and grown by every lesson after it, and the
# `look` command in ~/svelte-tools (Playwright 1.63.0 and a forty-line
# program lesson 1 shows whole), which opens a page in Chromium and prints
# what a screen reader would be told is on it.
#
# Lesson 1 tells the student to install it the same way on the computer they
# use (recommended), or in an Ubuntu 24.04 virtual machine, or online. This
# script builds the same thing on the recording computer: a user, ana, whose
# shell is a login shell with Ubuntu's own PATH. Nothing of the recording
# machine's own Node is on her PATH, so every `node` in a transcript is the
# one lesson 1 installed.
#
# HOW A TRANSCRIPT IS MADE. Each lesson's captures.sh sources lab/lib.sh and
# types commands at ana's shell, printing the prompt `ana@dev:DIR$ ` before
# each, as a terminal would. Each shell runs in a UTS namespace whose hostname
# is `dev`. A dev server that a lesson starts in "a second terminal" is
# started in the background as ana, and what it printed is shown where the
# lesson shows that terminal.
#
# WHAT IS STAGED rather than typed:
#   - the files ana writes. Each one is shown whole in a lesson, and the
#     capture takes it OUT of that lesson's .md with lab/shown.py, so the
#     program the student reads is the program that ran.
#   - the network. The recording computer reaches the internet through a
#     proxy that re-signs TLS, so ana's shell is given the proxy's variables
#     and NODE_EXTRA_CA_CERTS pointing at its certificate. A student's
#     computer needs neither, and nothing in a transcript shows them.
#   - the browser. Playwright's download server is not reachable from the
#     recording computer, which already has Chromium 153.0.8010.12 (build
#     1243, the build Playwright 1.63.0 asks for) in /opt/pw-browsers, so
#     lesson 1's captures link ana's ~/.cache/ms-playwright to it where the
#     download would have put it. Lesson 1 says so where it shows the
#     download.
#   - the clock's zone: TZ=America/Sao_Paulo. The clock itself is not staged,
#     so a timing or a date in a log is what the machine said that day.
#
#   sudo bash lab.sh up                    create ana (Node is installed by
#                                          lesson 1's captures, as she would)
#   sudo bash lab.sh exec 'command'        one command in ana's shell, in ~/planner
#   sudo bash lab.sh script 'script'       a script in a fresh login shell of ana's
#   sudo bash lab.sh down                  stop every process ana is running
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 (npm 10.9.4), sv 1.1.1,
# Svelte 5.57.2, SvelteKit 3.1.0, Vite 8.3.5 and Playwright 1.63.0,
# TZ=America/Sao_Paulo, in October 2026.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CA=/usr/local/share/svelte-lab-ca.crt

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Ubuntu's own ~/.profile, which puts ~/.local/bin on the PATH once it exists.
  [ -f /home/ana/.profile ] || cp /etc/skel/.profile /home/ana/.profile
  if [ -f /root/.ccr/ca-bundle.crt ]; then install -m 644 /root/.ccr/ca-bundle.crt $CA; fi
  echo "ana is ready; lesson 1's captures install Node.js and make ~/planner, as she would"
}

# The environment of ana's shell: Ubuntu's PATH, and nothing of this machine's.
# /usr/local is left out: the recording machine keeps a Node of its own there.
ana_env() {
  local net
  net=$(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ' || true)
  # shellcheck disable=SC2086
  echo env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash LANG=C.UTF-8 TERM=dumb \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo \
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
