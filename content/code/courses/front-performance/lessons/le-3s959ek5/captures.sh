#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash ../../lab.sh up
#   bash captures.sh > /tmp/l1.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l1.txt; done
#
# THE SETUP is run as a student would run it: a fresh login shell as ana with
# Ubuntu's own PATH, Node downloaded from nodejs.org. A new terminal is a new
# shell, which is why the first `node --version` fails.
#
# STAGED: for "A second, older Node", Ubuntu's own nodejs package is installed
# by root with apt before ana types anything, the shell's PATH is Ubuntu's
# default without ~/.local/bin, and the package is removed afterwards. For
# "Playwright cannot find its browser", PLAYWRIGHT_BROWSERS_PATH points at an
# empty folder, which is what a computer that never ran the install has. The
# files ana writes are taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L=$PWD

bash ../../lab.sh down >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq nodejs >/dev/null 2>&1
rm -rf /home/ana/.local /home/ana/planner /home/ana/node-v22.22.0-linux-* /home/ana/.npm /home/ana/.npmrc

block install
session '~' 'uname -m' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' \
  'node --version'
block new-terminal
session '~' 'node --version' 'npm --version' 'npm config set update-notifier false'

block create
session '~' 'npm create vite@9.3.1 planner -- --template vanilla-ts' 'cd planner' \
  'rm -r src/assets src/counter.ts public/icons.svg' \
  'npm install --save-exact --save-dev vite@8.3.5 typescript@6.0.3' 'cat package.json'
block playwright
session '~/planner' 'npm install --save-exact --save-dev playwright@1.63.0'

shown $L/the-planner.md public/courses.json '~/planner/public/courses.json'
shown $L/the-planner.md src/planner.ts '~/planner/src/planner.ts'
shown $L/the-planner.md src/view.ts '~/planner/src/view.ts'
shown $L/the-planner.md src/main.ts '~/planner/src/main.ts'
shown $L/the-planner.md index.html '~/planner/index.html'
shown $L/the-planner.md src/style.css '~/planner/src/style.css'

bg dev '~/planner' 'npm run dev'
wait_port 5173
block dev
bg_show dev
block dev-check
session '~/planner' 'curl -s http://localhost:5173/courses.json | head -3' 'npx tsc'

# The failures, while the dev server holds 5173.
block port
session '~/planner' 'timeout 5 npx vite'
shown $L/client-side.md tools/look.ts '~/planner/tools/look.ts'
block no-browser
session '~/planner' 'PLAYWRIGHT_BROWSERS_PATH=/tmp/empty node tools/look.ts http://localhost:5173/'
bg_stop dev INT

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs >/dev/null 2>&1
block old-node
bash ../../lab.sh script 'export PATH=/usr/sbin:/usr/bin:/sbin:/bin; cd ~/planner
for c in "which -a node" "node --version" "node node_modules/.bin/vite"; do
  printf "ana@dev:%s\$ %s\n" "$(dirs +0)" "$c"; $c 2>&1; done' 2>&1
DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq nodejs >/dev/null 2>&1

# Client-side.
block build
session '~/planner' 'npm run build'
bg preview '~/planner' 'npm run preview'
wait_port 4173
block preview
bg_show preview
block curl-csr
session '~/planner' 'curl -s http://localhost:4173/'
block look-csr
session '~/planner' 'node tools/look.ts http://localhost:4173/' 'node tools/look.ts http://localhost:4173/ --no-js'

# Server-side.
shown $L/server-side.md server.ts '~/planner/server.ts'
bg ssr '~/planner' 'npm run build >/dev/null && node server.ts'
wait_port 3000
block ssr
bg_show ssr
block curl-ssr
session '~/planner' 'curl -s http://localhost:3000/courses/git'
block look-ssr
session '~/planner' 'node tools/look.ts http://localhost:3000/ --no-js' 'node tools/look.ts http://localhost:3000/'

# What each costs.
block slow-csr
session '~/planner' 'node tools/look.ts http://localhost:4173/ --slow'
block slow-ssr
session '~/planner' 'node tools/look.ts http://localhost:3000/ --slow'
block ttfb
session '~/planner' "for i in 1 2 3; do curl -s -o /dev/null -w '%{time_starttransfer}\n' http://localhost:3000/; done"
bg_stop ssr INT
bg_stop preview INT
