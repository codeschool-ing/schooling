#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# SECTIONS 03 AND 04 ARE THE STUDENT'S SETUP, and they run first, from a home
# with no ~/site in it: the folder is made, html-validate is installed into it
# with the very `npm install` the lesson shows (its output is not quoted,
# because it depends on the network on the day), and .htmlvalidate.json is
# written from the fence in your-machine.md rather than from a copy, so the
# file the lesson shows is the file the validator read. npm's cache and logs go
# under /home/ana, the HOME of the prompt.
#
# What is STAGED in the failures of section 04: `node --version` is run with
# a PATH that has no Node on it, which is a machine where Node was never
# installed; `html-validate` without npx is run with a PATH that has only the
# system's directories on it, which is what every student's shell has; and the
# question npx asks outside ~/site needs a terminal, so it is run under
# `script`, answered "n", and the terminal's colour and cursor codes are taken
# out of what it printed.
#
# What is STAGED after that, and not shown in the lesson: the pages in
# lab/pages/le-andkcd1z are copied into /home/ana/site beside node_modules,
# and the prompt shows that directory as ~/site. latin1.html is charset.html
# re-encoded with `iconv -f utf-8 -t iso-8859-1`, so that its bytes disagree
# with what it declares; the lesson says how an editor does the same.
#
# Recorded 2026-10-07 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4, Chromium
# 141 through Playwright 1.56.0, html-validate 11.16.2, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="${HTML_CSS_LAB:-$HOME/.cache/html-css-lab}"
export PATH="$LAB/bin:$PATH"
[ -x "$LAB/bin/probe" ] || { echo "run lab.sh first" >&2; exit 1; }
export HOME=/home/ana npm_config_update_notifier=false
SITE=/home/ana/site
SYS=/usr/bin:/bin
NODEBIN="$(dirname "$(command -v node)")"
rm -rf "$SITE" /home/ana/.npm && mkdir -p /home/ana
# what ana typed at her prompt, and everything it printed
at() { printf 'ana@laptop:%s$ %s\n' "$1" "$2"; }
run() { at '~/site' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

cd /home/ana || exit 1
block setup-versions
at '~' 'node --version'; node --version
at '~' 'npm --version'; npm --version
block setup-folder
at '~' 'mkdir site'; mkdir site
at '~' 'cd site'; cd site || exit 1
# Run as the lesson shows it, and not quoted: what npm prints is the network's.
npm install html-validate@11.16.2 >/dev/null 2>&1 || { echo "npm install failed" >&2; exit 1; }
awk '/^```json$/{f=1;next} f&&/^```$/{exit} f' "$HERE/your-machine.md" > .htmlvalidate.json
[ -s .htmlvalidate.json ] || { echo "no json fence in your-machine.md" >&2; exit 1; }
block setup-check
run 'npx html-validate --version'
run 'ls -A'

block fail-node
at '~/site' 'node --version'; env PATH="$SYS" bash -c 'node --version' 2>&1 | sed 's/^bash: line 1: /bash: /'
block fail-global
at '~/site' 'html-validate -f text skeleton.html'
env PATH="$SYS" bash -c 'html-validate -f text skeleton.html' 2>&1 | sed 's/^bash: line 1: /bash: /'
block fail-folder
cd /home/ana || exit 1
at '~' 'npx html-validate --version'
printf 'n\n' | env PATH="$NODEBIN:$SYS" script -qec 'npx html-validate --version' /dev/null \
  | perl -CS -pe 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\r//g; s/[\x{2800}-\x{28FF}]//g' \
  | sed -e '1{/^n$/d}' -e '/^$/d'
cd "$SITE" || exit 1

# The lesson's pages, copied beside what the setup made.
cp -r "$HERE/../../lab/pages/$(basename "$HERE")/." "$SITE/"

block tree
run 'probe skeleton.html title tree'

block standards
run 'probe standards.html mode box div.frame'
block quirks
run 'probe quirks.html mode box div.frame'

block broken-dom
run 'probe broken.html dom'
block unclosed
run 'probe unclosed-title.html title box body'

block charset
run 'probe charset.html text .where'
run 'probe latin1.html text .where'
run 'probe no-charset.html text .where'

block viewport
run 'probe --mobile --width 390 --height 844 --dpr 3 no-viewport.html window box h1'
run 'probe --mobile --width 390 --height 844 --dpr 3 viewport.html window box h1'

block head
run 'probe head.html title'

block links
run 'probe links.html fetched style h1 color'

block validate-broken
run 'npx html-validate -f text broken.html'
block validate-title
run 'npx html-validate -f text unclosed-title.html'
block validate-quirks
run 'npx html-validate -f text quirks.html'
block validate-clean
run 'npx html-validate -f text skeleton.html; echo "exit status $?"'
