#!/usr/bin/env bash
# The machine every transcript in the vue course was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER, ONE PERSON, ONE BROWSER. ana took the javascript
# course on it, so she has Node.js 22.22.0 in ~/.local/node, unpacked from the
# official tarball exactly as javascript lesson 1 does it, with node, npm and
# npx linked into ~/.local/bin. This course adds to that machine only what its
# lessons install: the study planner in ~/vue/planner, made by create-vue and
# grown lesson by lesson, the Nuxt version of it in ~/vue/planner-nuxt from
# lesson 18, and ~/vue-tools, which holds Playwright and look.mjs, the program
# lesson 1 shows whole that opens a page in Chromium and prints what is on it.
#
# Lesson 1 tells the student to install it the same way on the computer they
# use (recommended), in an Ubuntu 24.04 virtual machine, or online. This
# script builds the same thing on the recording computer: a user, ana, whose
# shell is a login shell with Ubuntu's own PATH, so every `node` in a
# transcript is the one the lesson installed.
#
# HOW A TRANSCRIPT IS MADE. Each lesson's captures.sh sources lab/lib.sh and
# types commands at ana's shell, printing the prompt `ana@dev:DIR$ ` before
# each, as a terminal would. lab/fill.py pastes each block into the lesson's
# fence whose typed lines are the same. A dev server the lesson starts "in a
# second terminal" is started in the background and stopped afterwards.
#
# WHAT IS STAGED rather than typed:
#   - the files ana writes. Each one is shown whole in a lesson, and the
#     capture takes it OUT of that lesson's .md with lab/shown.py, so the
#     program the student reads is the program that ran. lab/state.sh puts
#     the planner in the state an earlier lesson left it, from those lessons'
#     own files.
#   - the network. The recording computer reaches the internet through a
#     proxy that re-signs TLS, so ana's shell is given the proxy's variables
#     and NODE_EXTRA_CA_CERTS pointing at its certificate. A student's
#     computer needs neither, and nothing in a transcript shows them.
#   - the browser. `npx playwright install` is not run here: the recording
#     machine already has the build Playwright 1.63.0 drives, Chromium
#     153.0.8010.12, in /opt/pw-browsers, and ~/.cache/ms-playwright is
#     linked to it. Lesson 1 says so where the student downloads theirs.
#   - the clock's zone: TZ=America/Sao_Paulo. The clock itself is not staged,
#     so a timing is what the machine said that day.
#
#   sudo bash lab.sh up                    create ana
#   sudo bash lab.sh exec 'command'        one command in ana's shell, in ~/vue
#   sudo bash lab.sh script 'script'       a script in a fresh login shell
#   sudo bash lab.sh reset                 empty ~/vue
#   sudo bash lab.sh down                  stop every process ana is running
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 (npm 10.9.4), create-vue
# 3.24.0, Vue 3.5.44, Vite 8.3.5, Playwright 1.63.0 and Chromium
# 153.0.8010.12, TZ=America/Sao_Paulo, in October 2026.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CA=/usr/local/share/vue-lab-ca.crt

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Ubuntu's own ~/.profile, which puts ~/.local/bin on the PATH once it exists.
  [ -f /home/ana/.profile ] || cp /etc/skel/.profile /home/ana/.profile
  if [ -f /root/.ccr/ca-bundle.crt ]; then install -m 644 /root/.ccr/ca-bundle.crt $CA; fi
  echo "ana is ready; lesson 1's captures install Node.js and make ~/vue, as she would"
}

# The environment of ana's shell: Ubuntu's PATH, and nothing of this machine's.
ana_env() {
  local net
  net=$(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ' || true)
  echo env -i HOME=/home/ana USER=ana LOGNAME=ana SHELL=/bin/bash LANG=C.UTF-8 TERM=dumb \
    PATH=/usr/sbin:/usr/bin:/sbin:/bin TZ=America/Sao_Paulo NO_COLOR=1 \
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
  exec) shift; run "cd ~/vue 2>/dev/null || cd ~; $*" ;;
  script) shift; run "$1" ;;
  reset) rm -rf /home/ana/vue && install -d -o ana -g ana /home/ana/vue ;;
  down) pkill -u ana || true ;;
  *) echo "usage: lab.sh up | exec 'command' | script 'script' | reset | down" >&2; exit 2 ;;
esac
