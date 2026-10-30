#!/usr/bin/env bash
# The machine every transcript in this course was recorded on.
#
# ONE LINUX COMPUTER, ONE PERSON AND ONE APP. ana took `javascript`, so she
# already has Node.js 22.22.0 in ~/.local/node, the way lesson 1 of that course
# installs it. In this course she builds a study planner with React and
# TypeScript in ~/planner, and every lesson is what she typed there and what
# came back. The lab has:
#
#   node, npm            Node.js 22.22.0 and the npm it ships (10.9.4), with its
#                        update notice turned off, because it appears once a day
#                        and would make two runs of one capture differ
#   ~/planner            the app, created in lesson 1 with create-vite 9.3.1 and
#                        grown lesson by lesson. Each lesson's captures.sh starts
#                        from the project as the lesson before left it (saved
#                        under $STATE), so the lessons must be captured in order
#   look URL             lab/look.mjs, which lesson 1 shows whole and the lab
#                        takes out of that lesson: Chromium with no window,
#                        driven by Playwright 1.63.0, printing what a page says
#                        on its console and what it shows, as an accessibility
#                        snapshot. Chromium is build 1243 (153.0.8010.12), the
#                        one Playwright 1.63.0 downloads, already present here
#                        under /opt/pw-browsers
#
# WHAT IS STAGED rather than typed is said in each lesson's captures.sh: the
# files ana "wrote" are put there by the script, and the lesson shows them in
# full. lab/shown.mjs fails a capture run if a file put in a captures.sh is not
# shown, byte for byte, in that lesson's prose.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           empty ~/planner
#   sudo bash lab.sh exec USER 'command'
#   sudo bash lab.sh save NAME       keep ~/planner as it is now, under NAME
#   sudo bash lab.sh restore NAME    put ~/planner back as NAME kept it
#   sudo bash lab.sh serve 'command' start a server in ~/planner in the background
#   sudo bash lab.sh stop            stop it
#
# Recorded 2026-10-23 on Ubuntu 24.04 with Node.js 22.22.0, npm 10.9.4 and
# Playwright 1.63.0, TZ=America/Sao_Paulo. Package versions are pinned in the
# lessons that install them, and npm's registry is the public one.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NODE_HOME=${NODE_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v node)")")")}
TZ_LAB=America/Sao_Paulo
ENVFILE=/etc/rtlab.env
STATE=/var/lib/rtlab
L1=le-1f9bsnn0

need() {
  command -v node >/dev/null || { echo "node is required (Node.js 22)" >&2; exit 1; }
  case $(node --version) in v22.*) ;; *) echo "the lab was recorded on Node.js 22; this is $(node --version)" >&2; exit 1 ;; esac
}

write_env() {
  # The proxy and its certificate are this sandbox's way out to the registry,
  # and are not part of what a student types.
  install -m 0644 "${NODE_EXTRA_CA_CERTS:-/etc/ssl/certs/ca-certificates.crt}" /etc/rtlab-ca.crt
  cat > "$ENVFILE" <<ENV
PATH=/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin
TZ=$TZ_LAB
LANG=C.UTF-8
LC_ALL=C.UTF-8
PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers
NO_COLOR=1
FORCE_COLOR=0
NODE_DISABLE_COLORS=1
COLORS=false
NO_UPDATE_NOTIFIER=1
npm_config_update_notifier=false
NEXT_TELEMETRY_DISABLED=1
NG_CLI_ANALYTICS=false
NODE_EXTRA_CA_CERTS=/etc/rtlab-ca.crt
HTTPS_PROXY=${HTTPS_PROXY:-}
NO_PROXY=${NO_PROXY:-}
ENV
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
  # Node.js as `javascript` lesson 1 installs it: the official folder in
  # ~/.local/node and its three programs linked into ~/.local/bin. Here the
  # folder is a link to the same 22.22.0 the sandbox already carries.
  runuser -u ana -- mkdir -p /home/ana/.local/bin
  ln -sfn "$NODE_HOME" /home/ana/.local/node
  for p in node npm npx; do ln -sfn /home/ana/.local/node/bin/$p /home/ana/.local/bin/$p; done
  chown -h ana: /home/ana/.local/node /home/ana/.local/bin/*
}

# look, as lesson 1 has the student build it: ~/react-tools holds Playwright
# and look.mjs, which is taken out of the lesson.
build_tools() {
  local t=/home/ana/react-tools
  runuser -u ana -- mkdir -p $t
  node "$HERE/lab/extract.mjs" "$HERE/lessons/$L1/look.md" look.mjs > $t/look.mjs
  chown ana: $t/look.mjs
  if [ ! -d $t/node_modules/playwright ]; then
    exec_in ana /home/ana/react-tools 'npm init -y >/dev/null && npm install --save-exact playwright@1.63.0 >/dev/null'
  fi
  printf '#!/bin/sh\nexec node ~/react-tools/look.mjs "$@"\n' > /home/ana/.local/bin/look
  chmod 0755 /home/ana/.local/bin/look
  chown ana: /home/ana/.local/bin/look
}

reset_home() {
  stop_server
  rm -rf /home/ana/planner /home/ana/planner-* /home/ana/other /home/ana/sessions-*
}

exec_in() {  # exec_in USER DIR COMMAND, with the lab's environment and nothing else
  local u=$1 dir=$2; shift 2
  # shellcheck disable=SC2046
  runuser -u "$u" -- env -i HOME=/home/$u USER="$u" $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $dir || exit 1; $*"
}

exec_as() {  # exec_as USER COMMAND: in ~/planner when it exists
  local u=$1; shift
  local dir=/home/$u/planner
  [ -d "$dir" ] || dir=/home/$u
  exec_in "$u" "$dir" "$@"
}

# ~/planner is the project every lesson uses; ~/planner-next, from lesson 15
# on, is kept beside it as NAME.next when it exists.
save() {
  mkdir -p $STATE
  rm -rf "$STATE/$1" "$STATE/$1.next"
  cp -a /home/ana/planner "$STATE/$1"
  if [ -d /home/ana/planner-next ]; then cp -a /home/ana/planner-next "$STATE/$1.next"; fi
}

restore() {
  [ -d "$STATE/$1" ] || { echo "nothing saved as $1: capture the lessons before it first" >&2; exit 1; }
  reset_home
  cp -a "$STATE/$1" /home/ana/planner
  if [ -d "$STATE/$1.next" ]; then cp -a "$STATE/$1.next" /home/ana/planner-next; fi
}

# A dev server, or any server, started the way ana starts one in a second
# terminal: in ~/planner, left running, its output kept in /run/rtlab-server.out.
serve() {
  stop_server
  # shellcheck disable=SC2046
  setsid runuser -u ana -- env -i HOME=/home/ana USER=ana $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd /home/ana/planner 2>/dev/null; $*" > /run/rtlab-server.out 2>&1 < /dev/null &
  echo $! > /run/rtlab-server.pid
}

stop_server() {
  if [ -f /run/rtlab-server.pid ]; then
    local pid
    pid=$(cat /run/rtlab-server.pid)
    kill -- -"$pid" 2>/dev/null || kill "$pid" 2>/dev/null || true
    rm -f /run/rtlab-server.pid
    sleep 0.5
  fi
}

case ${1:-} in
  up)
    need; write_env; build_user; build_tools; reset_home ;;
  reset)
    write_env; build_tools; reset_home ;;
  exec)
    shift; exec_as "$@" ;;
  save)
    save "$2" ;;
  restore)
    restore "$2" ;;
  serve)
    shift; serve "$*" ;;
  stop)
    stop_server ;;
  *)
    echo "usage: $0 up|reset|exec USER COMMAND|save NAME|restore NAME|serve COMMAND|stop" >&2; exit 2 ;;
esac
