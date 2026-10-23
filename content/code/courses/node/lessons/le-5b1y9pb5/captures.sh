#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash ../../lab.sh up
#   sudo bash captures.sh > /tmp/l1.txt && python3 ../../lab/fill.py your-computer.md /tmp/l1.txt
#
# THE SETUP is run as a student would run it: a fresh login shell as ana with
# Ubuntu's own PATH, Node downloaded from nodejs.org. A new terminal is a new
# shell, which is why the first `node --version` fails.
#
# STAGED: for "Two Nodes on one PATH", Ubuntu's own nodejs package is installed
# by root with apt before ana types anything, and removed afterwards; for "The
# wrong processor", the arm64 tarball is downloaded beside the right one. The
# programs ana writes are taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

rm -rf /home/ana/.local /home/ana/server /home/ana/wrong /home/ana/node-v22.22.0-linux-* \
  /home/ana/.npm /home/ana/.npmrc /home/ana/.node_repl_history

block install
session '~' 'uname -m' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz' \
  'mkdir -p ~/.local/node ~/.local/bin' \
  'tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'ln -s ~/.local/node/bin/node ~/.local/node/bin/npm ~/.local/node/bin/npx ~/.local/bin/' \
  'node --version'
block new-terminal
session '~' 'node --version' 'npm --version' 'curl --version | head -1' \
  'npm config set update-notifier false' 'mkdir ~/server'
block which
session '~' 'which node npm' 'ls ~/.local/node'

# The failures.
block wrong-arch
session '~' 'mkdir ~/wrong && cd ~/wrong' \
  'curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz' \
  'tar -xJf node-v22.22.0-linux-arm64.tar.xz --strip-components=1' \
  './bin/node --version'
quiet '~' 'rm -rf ~/wrong'

DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs >/dev/null 2>&1
block two-nodes
session '~' 'which -a node' 'node --version' '/usr/bin/node --version'
DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq nodejs >/dev/null 2>&1
quiet '~/server' 'mkdir -p hello'
shown first-server.md hello.mjs '~/server/hello/hello.mjs'

# The first server: one terminal runs it, the other asks it.
bg hello '~/server/hello' 'node hello.mjs'
wait_port 3000
block server-start
bg_show hello
block server
session '~/server/hello' 'curl -s http://127.0.0.1:3000/' 'curl -si http://127.0.0.1:3000/anything'
bg_stop hello INT
block server-log
bg_show hello
printf '^C\n'
block busy-port
bg hello '~/server/hello' 'node hello.mjs'
wait_port 3000
session '~/server/hello' 'node hello.mjs'
bg_stop hello INT

# The node command.
block run-file
quiet '~/server' 'mkdir -p cmd'
shown the-node-command.md sum.js '~/server/cmd/sum.js'
session '~/server/cmd' 'node sum.js' 'node -p "2 ** 53"' 'node -p "2 ** 53 + 1"' \
  "node -e 'console.log(new Date(0).toISOString())'"
block repl
repl '~/server/cmd' '1 + 2' 'const s = "olá"' 's.length' 'Buffer.byteLength(s)' '.exit'
block check
shown the-node-command.md broken.js '~/server/cmd/broken.js'
session '~/server/cmd' 'node --check sum.js; echo $?' 'node --check broken.js; echo $?'

# Reading errors.
block stack
quiet '~/server' 'mkdir -p errors'
shown reading-errors.md total.js '~/server/errors/total.js'
session '~/server/errors' 'node total.js; echo "exit code $?"'
block enoent
shown reading-errors.md open.js '~/server/errors/open.js'
session '~/server/errors' 'node open.js prices.txt; echo "exit code $?"' 'echo "12.50" > prices.txt' 'node open.js prices.txt'

# The documentation.
block release
session '~/server' 'node -p process.release' "node -p 'process.versions.v8'"
