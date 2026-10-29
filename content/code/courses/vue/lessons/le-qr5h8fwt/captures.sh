#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash ../../lab.sh up
#   sudo bash captures.sh > /tmp/l1.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l1.txt; done
#
# THE SETUP is run as a student would run it: ana's home is emptied of Node,
# the tools and the work, and every session is a fresh login shell with
# Ubuntu's own PATH. It downloads Node.js from nodejs.org and the packages
# from the npm registry.
#
# STAGED: look.mjs is taken out of your-computer.md, and every file of the
# planner out of the section that shows it. The browser: `npx playwright
# install` is not run here, and ~/.cache/ms-playwright is linked to the
# recording machine's copy of the same build (the section says so). The
# failures in when-setup-fails are produced for real, by doing the wrong
# thing: a terminal opened too early, a folder with no project, a project
# with no node_modules, a second dev server, a browser not yet downloaded and
# a typo in a template.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh

files() {
  quiet '~/vue' 'rm -rf planner && npm create vue@3.24.0 -- --prettier --bare planner'
  for f in package.json vite.config.js index.html; do shown the-project.md $f $P/$f; done
  shown first-screen.md src/App.vue $P/src/App.vue
  quiet $P 'npm install --silent'
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

rm -rf /home/ana/.local /home/ana/vue-tools /home/ana/vue /home/ana/.npm /home/ana/.npmrc \
  /home/ana/.cache/ms-playwright /home/ana/node-v22.22.0-linux-*

block install
session '~' 'uname -m' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' \
  'node --version'
block versions
session '~' 'node --version' 'npm --version' 'npm config set update-notifier false' 'mkdir ~/vue ~/vue-tools'

block playwright
session '~/vue-tools' 'npm init -y > /dev/null' 'npm install --save-exact playwright@1.63.0'
quiet '~' 'mkdir -p ~/.cache && ln -sfn /opt/pw-browsers ~/.cache/ms-playwright'
shown your-computer.md look.mjs '~/vue-tools/look.mjs'
quiet '~' "printf '#!/bin/sh\nexec node \"\$HOME/vue-tools/look.mjs\" \"\$@\"\n' > ~/.local/bin/look && chmod +x ~/.local/bin/look"
block look-file
session '~' 'cat ~/.local/bin/look' 'cat ~/vue-tools/package.json'

# the project
block create
session '~/vue' 'npm create vue@3.24.0 -- --prettier --bare planner'
block scaffold
session '~/vue/planner' 'find . -type f | sort' 'cat package.json'
for f in package.json vite.config.js index.html; do shown the-project.md $f $P/$f; done
block install-project
session '~/vue/planner' 'npm install' 'ls' 'npm ls'
dev d1 $P 'npm run dev' 5173
block the-project/dev
bg_show d1
block the-project/look-first
session $P 'look http://localhost:5173/'
block anatomy
session $P "curl -s http://localhost:5173/src/App.vue | grep -A 16 '^function _sfc_render'"
block anatomy-import
session $P "curl -s http://localhost:5173/src/App.vue | grep -o 'from \"/node_modules/[^\"]*\"'"

# when the setup fails
block when-setup-fails/fail-nodir
session '~/vue' 'npm run dev'
block when-setup-fails/fail-nomodules
session $P 'mv node_modules /tmp/vuelab/nm' 'npm run dev'
quiet $P 'mv /tmp/vuelab/nm node_modules'
dev d2 $P 'npm run dev' 5174
block when-setup-fails/fail-port
bg_show d2
bg_stop d2
quiet '~' 'mv ~/.cache/ms-playwright ~/.cache/ms-playwright.away'
block when-setup-fails/fail-browser
session $P 'look http://localhost:5173/'
quiet '~' 'mv ~/.cache/ms-playwright.away ~/.cache/ms-playwright'
quiet $P "cp src/App.vue /tmp/vuelab/App.vue && sed -i 's|</h1>|</h2>|' src/App.vue"
sleep 1
block when-setup-fails/fail-template
session $P 'look http://localhost:5173/'
block when-setup-fails/fail-template-server
bg_show d1
quiet $P 'cp /tmp/vuelab/App.vue src/App.vue'
bg_stop d1

# the first screen
dev d3 $P 'npm run dev' 5173
shown first-screen.md src/App.vue $P/src/App.vue
shown first-screen.md src/components/AppFooter.vue $P/src/components/AppFooter.vue
sleep 1
block first-screen/first-screen
session $P 'look http://localhost:5173/'
block scoped-html
session $P 'look http://localhost:5173/ --text - --html footer'
block scoped-network
session $P 'look http://localhost:5173/ --text - --network | grep AppFooter'
block scoped-css
session $P "curl -s 'http://localhost:5173/src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css' | grep -o 'const __vite__css = .*'"
bg_stop d3

# a page at a time
block adopt
session '~/vue' 'mkdir adopt && cd adopt' 'cp ../planner/node_modules/vue/dist/vue.esm-browser.prod.js .' 'ls'
shown progressive.md index.html '~/vue/adopt/index.html'
bg py '~/vue/adopt' 'python3 -m http.server 8000'
wait_port 8000
block adopt-look
session '~/vue/adopt' "look http://localhost:8000/ --do 'click button' --do 'click button' --text body"
block adopt-size
session '~/vue/adopt' 'ls -l vue.esm-browser.prod.js ../planner/node_modules/vue/dist/vue.runtime.esm-browser.prod.js'
bg_stop py
block adopt-server
bg_show py
rm -rf /home/ana/vue/adopt
snapshot
