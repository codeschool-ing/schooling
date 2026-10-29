#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash ../../lab.sh up
#   sudo bash captures.sh > /tmp/l1.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l1.txt; done
#
# THE SETUP is run as a student would run it: a fresh login shell as ana with
# Ubuntu's own PATH, Node downloaded from nodejs.org. A new terminal is a new
# shell, which is why the first `node --version` fails.
#
# STAGED: for "Two Nodes", Ubuntu's own nodejs package is installed by root with
# apt before ana types anything, and removed afterwards; for "The wrong
# processor", the arm64 tarball is downloaded beside the right one; for "The port
# is taken", a first dev server is left running in another terminal. The files
# ana writes are taken out of the lesson's .md by lab/shown.py. At the end the
# commit the lesson leaves is tagged lesson-1, so that lesson 2's captures start
# from it however many times they are run; no transcript shows the tag.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
rm -rf /home/ana/.local /home/ana/planner /home/ana/wrong /home/ana/node-v22.22.0-linux-* \
  /home/ana/.npm /home/ana/.npmrc /home/ana/.node_repl_history

block install
session '~' 'uname -m' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' \
  'node --version'
block new-terminal
session '~' 'node --version' 'npm --version' 'git --version' 'npm config set update-notifier false'
block which
session '~' 'which node npm' 'ls ~/.local/node'

block wrong-arch
session '~' 'mkdir ~/wrong && cd ~/wrong' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz' \
  'tar -xJf node-v22.22.0-linux-arm64.tar.xz --strip-components=1' \
  './bin/node --version'
quiet '~' 'rm -rf ~/wrong'

# The planner.
block create
session '~' 'npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive'
block pins
session '~' 'cd planner' 'rm -r src/counter.ts src/assets public/icons.svg' \
  'npm install --save-dev --save-exact vite@8.3.5 typescript@6.0.3' 'cat package.json'
shown the-planner.md public/courses.json '~/planner/public/courses.json'
shown the-planner.md src/planner.ts '~/planner/src/planner.ts'
shown the-planner.md src/view.ts '~/planner/src/view.ts'
shown the-planner.md src/main.ts '~/planner/src/main.ts'
shown the-planner.md src/style.css '~/planner/src/style.css'
shown the-planner.md index.html '~/planner/index.html'

bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
block dev
bg_show dev
block dev-curl
session '~/planner' 'curl -s http://localhost:5173/courses.json | head -3'
block git
session '~/planner' 'git init -q' 'git add .' 'git commit -qm "The study planner"' 'git log --oneline'

# The port is taken: the first dev server is still running.
bg dev2 '~/planner' 'npm run dev'
wait_port 5174
sleep 1
block port
bg_show dev2
bg_stop dev2 INT
bg_stop dev INT

# Two Nodes, with the planner to try the old one on.
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs >/dev/null 2>&1
block two-nodes
session '~/planner' 'which -a node' 'node --version' '/usr/bin/node --version' \
  '/usr/bin/node node_modules/.bin/vite'
DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq nodejs >/dev/null 2>&1

# The build.
block build
session '~/planner' 'npm run build'
block find
session '~/planner' 'find dist -type f | sort'
block index
session '~/planner' 'cat dist/index.html'
block hashes
session '~/planner' 'ls dist/assets' 'npm run build > /dev/null && ls dist/assets' \
  "sed -i 's/All courses/Every course/' src/view.ts" 'npm run build > /dev/null && ls dist/assets' \
  'git checkout src/view.ts'
block type-error
session '~/planner' "sed -i 's/minutes: number;/minutes: string;/' src/planner.ts" 'npm run build' \
  'git checkout src/planner.ts'
quiet '~/planner' 'npm run build'

# Like a host.
shown like-a-host.md host.mjs '~/planner/host.mjs'
bg host '~/planner' 'node host.mjs'
wait_port 8080
block host-start
bg_show host
block host-curl
session '~/planner' 'curl -si http://127.0.0.1:8080/ | head -3' \
  'curl -s http://127.0.0.1:8080/courses.json | head -2' \
  'curl -si http://127.0.0.1:8080/nothing-here'
bg_stop host INT
block host-log
bg_show host
printf '^C\n'
block host-commit
session '~/planner' 'git add host.mjs' 'git commit -qm "Serve dist/ the way a static host does"'

# A subpath.
block sub-broken
session '~/planner' 'npm run build > /dev/null' 'rm -rf site && mkdir site && cp -r dist site/planner' \
  "grep -o 'src=\"[^\"]*\"' site/planner/index.html"
bg sub '~/planner' 'node host.mjs site'
wait_port 8080
block sub-curl
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/" \
  "js=\$(grep -o '/assets/[^\"]*\.js' site/planner/index.html); echo \$js" \
  "curl -s -o /dev/null -w '%{http_code}\n' \"http://127.0.0.1:8080\$js\""
block sub-log
bg_show sub
block sub-fixed
session '~/planner' 'npm run build -- --base=/planner/ > /dev/null' \
  'rm -rf site && mkdir site && cp -r dist site/planner' \
  "grep -o 'src=\"[^\"]*\"' site/planner/index.html" \
  "js=\$(grep -o '/planner/assets/[^\"]*\.js' site/planner/index.html)" \
  "curl -s -o /dev/null -w '%{http_code}\n' \"http://127.0.0.1:8080\$js\"" \
  "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/courses.json"
block sub-deep
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/planner/course/git" \
  'rm -rf site'
bg_stop sub INT
quiet '~/planner' 'npm run build'
quiet '~/planner' 'git tag -f lesson-1'
