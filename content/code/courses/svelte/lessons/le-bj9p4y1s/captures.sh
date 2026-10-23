#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash ../../lab.sh up
#   sudo bash captures.sh > /tmp/l1.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l1.txt; done
#
# THE SETUP is run as a student would run it: a fresh login shell as ana with
# Ubuntu's own PATH, Node downloaded from nodejs.org, Playwright and the
# project's packages from the public npm registry. A new terminal is a new
# shell, which is why the first `node --version` fails.
#
# STAGED:
#   - the browser. `npx playwright install` cannot reach Playwright's download
#     server from the recording computer, which already has the build 1.63.0
#     asks for in /opt/pw-browsers; ana's ~/.cache/ms-playwright is linked to
#     it, after the dry run and before `look` is first used. The lesson says so.
#   - ana's git identity (name and e-mail), which the git course has the
#     student set, is set here before the project's first commit.
#   - for "A second Node", Ubuntu's own nodejs package (18.19.1) is installed
#     by root with apt before ana types anything, and removed afterwards.
#   - the files ana writes, taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash "$LAB_SH" down >/dev/null 2>&1
DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq nodejs >/dev/null 2>&1
rm -rf /home/ana/.local /home/ana/planner /home/ana/svelte-tools /home/ana/node-v22.22.0-linux-* \
  /home/ana/.npm /home/ana/.npmrc /home/ana/.cache /home/ana/.gitconfig $STATE/*

block install
session '~' 'uname -m' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' \
  'node --version'
block new-terminal
session '~' 'node --version' 'npm --version' 'npm config set update-notifier false'

block look-install
session '~' 'mkdir ~/svelte-tools && cd ~/svelte-tools' \
  'npm init -y > /dev/null' \
  'npm install --save-exact playwright@1.63.0' \
  'npx playwright install --dry-run --only-shell chromium'
# STAGED: the browser, where the download would have put it.
quiet '~' 'mkdir -p ~/.cache && ln -sfn /opt/pw-browsers ~/.cache/ms-playwright'
shown the-look-command.md look.mjs '~/svelte-tools/look.mjs'
quiet '~' "$(python3 ../../lab/shown.py the-look-command.md '~/.local/bin/look' | sed 1d)"
block look-check
session '~' "look 'data:text/html,<main><h1>It works</h1><button>Press me</button></main>'"

# The failures.
mv /home/ana/.cache/ms-playwright /home/ana/.cache/ms-playwright.away
block no-browser
session '~' "look 'data:text/html,<main><h1>It works</h1></main>'"
mv /home/ana/.cache/ms-playwright.away /home/ana/.cache/ms-playwright

# The project.
quiet '~' 'git config --global user.name "Ana" && git config --global user.email ana@example.com && git config --global init.defaultBranch main'
quiet '~' 'npx --yes sv@1.1.1 create planner --template minimal --no-types --no-add-ons --install npm'
block project
session '~' 'cd planner' 'ls -A' 'ls src src/routes src/lib' 'npm pkg get devDependencies'
block pin
session '~/planner' \
  'npm install --save-dev --save-exact svelte@5.57.2 @sveltejs/kit@3.1.0 vite@8.3.5 @sveltejs/vite-plugin-svelte@7.3.1 @sveltejs/adapter-auto@8.0.0' \
  'npm config set save-exact true --location=project' \
  'cat .npmrc' 'npm pkg get devDependencies'
block git
session '~/planner' 'git init -q' 'git add -A' 'git commit -qm "A new SvelteKit project" && git log --oneline'

bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
block dev
bg_show dev
block look-welcome
session '~/planner' 'look http://localhost:5173/'
shown first-project.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block look-planner
session '~/planner' 'look http://localhost:5173/'

block port-in-use
session '~/planner' 'timeout 5 npm run dev'

# A second Node, ahead of yours on the PATH.
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs >/dev/null 2>&1
block second-node
session '~/planner' 'PATH=/usr/bin:$PATH' 'which -a node' 'node --version' 'npm install'
block second-node-dev
session '~/planner' 'PATH=/usr/bin:$PATH npm run dev'
DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq nodejs >/dev/null 2>&1

# The compiler.
shown what-the-compiler-writes.md src/lib/Counter.svelte '~/planner/src/lib/Counter.svelte'
shown what-the-compiler-writes.md compile.mjs '~/planner/compile.mjs'
block compile-client
session '~/planner' 'node compile.mjs src/lib/Counter.svelte'
block compile-server
session '~/planner' 'node compile.mjs src/lib/Counter.svelte server'

bg_stop dev
block build
session '~/planner' 'npm run build'
block sizes
session '~/planner' 'ls .svelte-kit/output/client/_app/immutable/nodes' \
  'cat .svelte-kit/output/client/_app/immutable/nodes/2.*.js'
done_lesson 1 "the planner page, Counter and compile.mjs"
