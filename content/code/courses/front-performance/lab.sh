#!/usr/bin/env bash
# The machine every transcript in the front-performance course was recorded on.
#
# ONE UBUNTU 24.04 COMPUTER, ONE PERSON. ana took the javascript course on it,
# so she already has Node.js 22.22.0 in ~/.local/node, installed from the
# official tarball exactly as javascript lesson 1 does it, with node, npm and
# npx linked into ~/.local/bin. Lesson 1's captures install it again from
# nothing, the way the lesson tells a student who arrives without it.
#
# Everything else comes from the public npm registry, pinned to an exact
# version in each project's package.json: Vite, TypeScript, Playwright, the
# four meta-frameworks, web-vitals, Lighthouse, sharp. The work lives in
# ~/planner (the plain TypeScript app, built in lesson 1 and grown in every
# lesson after it) and ~/meta (the four meta-framework projects of lessons 2
# to 4).
#
# HOW A TRANSCRIPT IS MADE. Each lesson's captures.sh sources lab/lib.sh and
# types commands at ana's shell, printing the prompt `ana@dev:DIR$ ` before
# each, as a terminal would. Each shell runs in a UTS namespace whose hostname
# is `dev`. Servers that a lesson starts in "a second terminal" are started in
# the background as ana, and their output is printed where the lesson shows
# that terminal. Programs that drive the browser are shown whole in a lesson
# and run as ana, exactly as shown.
#
# WHAT IS STAGED rather than typed:
#   - the files ana writes. Each one is shown whole in a lesson, and the
#     capture takes it OUT of that lesson's .md with lab/shown.py, so the
#     program the student reads is the program that ran.
#   - the browser. Playwright 1.63.0 expects Chromium build 1243
#     (153.0.8010.12). The recording computer cannot reach Playwright's
#     download server and already has that exact build in /opt/pw-browsers,
#     so `up` links it into ~/.cache/ms-playwright, which is where
#     `npx playwright install chromium` would have unpacked it. The lesson
#     that installs it says this line was not run here.
#   - the network. The recording computer reaches the internet through a
#     proxy that re-signs TLS, so a shell of ana's that needs the network is
#     given the proxy's variables and NODE_EXTRA_CA_CERTS pointing at its
#     certificate; builds, servers and requests to localhost run without
#     them (`offline` below). A student's computer needs neither, and nothing
#     in a transcript shows them.
#   - the clock's zone: TZ=America/Sao_Paulo. The clock itself is not staged,
#     so a Date header or a timing is what the machine said that day.
#
#   sudo bash lab.sh up                    create ana and link the browser
#   sudo bash lab.sh exec 'command'        one command in ana's shell, in ~/planner
#   sudo bash lab.sh script 'script'       a script in a fresh login shell of ana's
#   sudo bash lab.sh offline 'script'      the same, with no proxy: for builds,
#                                          servers and localhost, which need no
#                                          network, so a tool that warns about a
#                                          proxy (Nuxt's does) has none to warn of
#   sudo bash lab.sh down                  stop every process ana is running
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 (npm 10.9.4),
# TZ=America/Sao_Paulo, in October 2026.
set -euo pipefail

CA=/usr/local/share/front-lab-ca.crt

up() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Ubuntu's own ~/.profile, which puts ~/.local/bin on the PATH once it exists.
  [ -f /home/ana/.profile ] || cp /etc/skel/.profile /home/ana/.profile
  if [ -f /root/.ccr/ca-bundle.crt ]; then install -m 644 /root/.ccr/ca-bundle.crt $CA; fi
  install -d -o ana -g ana /home/ana/.cache /home/ana/.cache/ms-playwright
  for b in chromium-1243 chromium_headless_shell-1243 ffmpeg-1011; do
    [ -e /home/ana/.cache/ms-playwright/$b ] || ln -s /opt/pw-browsers/$b /home/ana/.cache/ms-playwright/$b
  done
  echo "ana is ready; lesson 1's captures install Node.js and make ~/planner, as she would"
}

# The environment of ana's shell: Ubuntu's PATH, and nothing of this machine's.
ana_env() {
  local net=""
  [ "${OFFLINE:-}" = 1 ] || net=$(env | grep -iE '^(https?_proxy|no_proxy)=' | tr '\n' ' ' || true)
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
  offline) shift; OFFLINE=1 run "$1" ;;
  down) pkill -u ana || true ;;
  *) echo "usage: lab.sh up | exec 'command' | script 'script' | down" >&2; exit 2 ;;
esac
