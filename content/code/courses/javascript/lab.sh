#!/usr/bin/env bash
# The machine every transcript in this course was recorded on.
#
# ONE LINUX COMPUTER, ONE PERSON AND ONE BROWSER. ana is learning JavaScript,
# and every lesson is what she types in ~/js and what came back. JavaScript
# runs in two places in this course, and the lab has both:
#
#   node                 Node.js 22, for the language itself: lessons 1 to 10
#                        and 13 to 22 run most of their programs here
#   page FILE.html       Chromium, headless, driven by Playwright (lab/page.mjs):
#                        it serves ~/js at http://127.0.0.1:8080, opens the
#                        page, and prints what its console said. Lessons 11,
#                        12, 15, 16, 18 and 22 use it. The FORMAT of its lines
#                        is the lab's and is described in lab/page.mjs; what
#                        they say is what the browser said.
#   serve                the same web server on its own (lab/serve.mjs), for a
#                        program in node to fetch from: lesson 16
#   npm, pnpm, yarn      the three package managers of lesson 21: npm as it
#                        ships with Node.js 22.22.0 (10.9.4), pnpm 10.28.0 and
#                        Yarn 4.10.3, the last two installed here at those
#                        versions so that no other copy on the machine answers
#   127.0.0.1:4873       a private npm registry, Verdaccio, holding only the
#                        packages the lab publishes into it: lesson 21. It
#                        reaches nothing outside the machine.
#
# WHAT IS STAGED rather than typed is said in each lesson's captures.sh: the
# files ana "wrote" are put there by the script, and the lesson shows them in
# full.
#
#   sudo bash lab.sh up              build it (idempotent)
#   sudo bash lab.sh reset           empty ~/js and the browser's profile
#   sudo bash lab.sh registry        start the registry and publish its packages
#   sudo bash lab.sh down            stop the registry
#   sudo bash lab.sh exec USER 'command'
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, Playwright 1.56.0 (Chromium
# 141), Verdaccio 6.1.6, pnpm 10.28.0 and Yarn 4.10.3, TZ=America/Sao_Paulo.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPT=/opt/jslab
NODE_DIR=${NODE_DIR:-$(dirname "$(command -v node)")}
TZ_LAB=America/Sao_Paulo
JSLIBS="playwright@1.56.0 verdaccio@6.1.6 pnpm@10.28.0 @yarnpkg/cli-dist@4.10.3"
REG=/var/lib/jslab-registry
ENVFILE=/etc/jslab.env

need() {
  command -v node >/dev/null || { echo "node is required (Node.js 22)" >&2; exit 1; }
  case $(node --version) in v22.*) ;; *) echo "the lab was recorded on Node.js 22; this is $(node --version)" >&2; exit 1 ;; esac
}

write_env() {
  cat > "$ENVFILE" <<ENV
PATH=$OPT/bin:$NODE_DIR:/usr/local/bin:/usr/bin:/bin
TZ=$TZ_LAB
LANG=C.UTF-8
LC_ALL=C.UTF-8
PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers}
NODE_DISABLE_COLORS=1
NO_COLOR=1
NO_UPDATE_NOTIFIER=1
npm_config_update_notifier=false
npm_config_fund=false
YARN_ENABLE_TELEMETRY=0
ENV
}

build_opt() {
  mkdir -p $OPT/bin $OPT/lab
  ( cd $OPT && { [ -f package.json ] || npm init -y >/dev/null; } && npm install --silent $JSLIBS )
  install_lab
}

# The lab's own programs, and the two commands ana types.
install_lab() {
  install -m 0644 "$HERE/lab/serve.mjs" "$HERE/lab/page.mjs" $OPT/lab/
  ln -sfn $OPT/node_modules $OPT/lab/node_modules
  printf '#!/bin/sh\nexec node %s/lab/page.mjs "$@"\n' $OPT > $OPT/bin/page
  printf '#!/bin/sh\nexec node %s/lab/serve.mjs "$@"\n' $OPT > $OPT/bin/serve
  printf '#!/bin/sh\nexec node %s/node_modules/pnpm/bin/pnpm.cjs "$@"\n' $OPT > $OPT/bin/pnpm
  printf '#!/bin/sh\nexec node %s/node_modules/@yarnpkg/cli-dist/bin/yarn.js "$@"\n' $OPT > $OPT/bin/yarn
  chmod 0755 $OPT/bin/page $OPT/bin/serve $OPT/bin/pnpm $OPT/bin/yarn
}

build_user() {
  id ana >/dev/null 2>&1 || useradd -m -s /bin/bash ana
}

reset_home() {
  rm -rf /home/ana/js /home/ana/.page-profile /home/ana/.npm /home/ana/.npmrc \
    /home/ana/.yarn /home/ana/.yarnrc.yml /home/ana/.local/share/pnpm /home/ana/.cache/pnpm
  runuser -u ana -- mkdir -p /home/ana/js
}

# The registry. Its packages are written by lab/registry.sh, published as the
# user "lab", and nothing in it was downloaded from anywhere.
start_registry() {
  stop_registry
  rm -rf $REG/storage $REG/htpasswd   # every run starts with no packages and no users
  mkdir -p $REG/storage
  cat > $REG/config.yaml <<YAML
storage: $REG/storage
auth:
  htpasswd:
    file: $REG/htpasswd
    max_users: 100
packages:
  '**':
    access: \$all
    publish: \$authenticated
    unpublish: \$authenticated
uplinks: {}
listen: 127.0.0.1:4873
log: { type: stdout, format: pretty, level: warn }
YAML
  setsid env -i PATH=$NODE_DIR:/usr/bin:/bin TZ=$TZ_LAB \
    node $OPT/node_modules/verdaccio/bin/verdaccio -c $REG/config.yaml > /run/jslab-registry.out 2>&1 < /dev/null &
  echo $! > /run/jslab-registry.pid
  for _ in $(seq 50); do
    curl -s -o /dev/null http://127.0.0.1:4873/-/ping 2>/dev/null && return 0
    sleep 0.2
  done
  echo "the registry did not start; see /run/jslab-registry.out" >&2; return 1
}

stop_registry() {
  if [ -f /run/jslab-registry.pid ]; then
    kill "$(cat /run/jslab-registry.pid)" 2>/dev/null || true
    rm -f /run/jslab-registry.pid
    sleep 0.3
  fi
}

exec_as() {  # exec_as USER COMMAND: in ~/js, with the lab's environment and nothing else
  local u=$1; shift
  local dir=/home/$u/js
  [ -d "$dir" ] || dir=/home/$u
  # shellcheck disable=SC2046
  runuser -u "$u" -- env -i HOME=/home/$u USER="$u" $(grep -v '^#' $ENVFILE | xargs) \
    bash -c "cd $dir || exit 1; $*"
}

case ${1:-} in
  up)
    need; build_user; write_env; build_opt; reset_home ;;
  reset)
    write_env; install_lab; reset_home ;;
  registry)
    start_registry; bash "$HERE/lab/registry.sh" ;;
  down)
    stop_registry ;;
  exec)
    shift; exec_as "$@" ;;
  *)
    echo "usage: $0 up|reset|registry|down|exec USER COMMAND" >&2; exit 2 ;;
esac
