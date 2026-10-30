#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of angular, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it (lab/fill.py pastes them), so the next
# person can run it and see what moved.
#
#   sudo bash ../../lab.sh up        # once: ana, Node.js 22.22.0 and ~/js-tools
#   sudo bash captures.sh > out.txt && python3 ../../lab/fill.py <section>.md out.txt
#
# It needs the network: the Angular CLI 22.2.4 is fetched by npx, as the
# student's would be, to show that it refuses this Node.
#
# What is STAGED rather than typed: ~/js-tools as javascript lesson 1 leaves it,
# without the look.mjs lesson 2 adds; and the files ana writes in ~/ts, taken
# out of the lesson's .md by lab/shown.py, so the program in the lesson is the
# one that ran.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and TypeScript 5.9.3,
# TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
L=$PWD

quiet '~' 'rm -rf ~/ts ~/js-tools/look.mjs ~/.local/bin/look ~/.npm/_npx'

block your-computer
session '~' 'node --version' 'npm --version' 'ls ~/js-tools' 'du -sh ~/.local/node ~/js-tools'

block cli-22-head
session '~' 'npx @angular/cli@22.2.4 version 2>&1 | head -12'
block cli-22-tail
session '~' 'npx @angular/cli@22.2.4 version 2>&1 | tail -4'
block registry
session '~' 'npm view @angular/cli version --registry http://127.0.0.1:9/'

block ts-folder
session '~' 'mkdir ~/ts' 'cd ~/ts' 'npm init -y > /dev/null' 'npm install --save-exact typescript@5.9.3' 'du -sh ~/ts'
for f in hello.ts session.ts; do shown $L/typescript-types.md $f "~/ts/$f"; done
for f in week.ts first.ts label.ts; do shown $L/typescript-classes.md $f "~/ts/$f"; done
block hello-node
session '~/ts' 'node hello.ts'
block hello-tsc
session '~/ts' 'npx tsc --noEmit --strict hello.ts' 'echo $?'
block session-tsc
session '~/ts' 'npx tsc --noEmit --strict session.ts'
block week-tsc
session '~/ts' 'npx tsc --noEmit --strict week.ts'
block first-tsc
session '~/ts' 'npx tsc --noEmit --strict first.ts'
block label-node
session '~/ts' 'node label.ts'
block label-tsc
session '~/ts' 'npx tsc --strict --target es2022 --experimentalDecorators --outDir out label.ts' 'node out/label.js'
