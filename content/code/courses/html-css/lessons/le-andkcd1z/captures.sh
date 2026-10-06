#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-andkcd1z are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. latin1.html is charset.html re-encoded with
# `iconv -f utf-8 -t iso-8859-1`, so that its bytes disagree with what it
# declares. .htmlvalidate.json in the same directory sets html-validate's
# presets to "standard" and "document".
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Node 22.22.0, Chromium 141 through
# Playwright 1.56.0, html-validate 11.16.2, TZ=America/Sao_Paulo.

set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="${HTML_CSS_LAB:-$HOME/.cache/html-css-lab}"
export PATH="$LAB/bin:$PATH"
[ -x "$LAB/bin/probe" ] || { echo "run lab.sh first" >&2; exit 1; }
# The lesson's pages, copied to where ana keeps her site.
SITE=/home/ana/site
rm -rf "$SITE" && mkdir -p "$SITE"
cp -r "$HERE/../../lab/pages/$(basename "$HERE")/." "$SITE/"
cd "$SITE" || exit 1
# what ana typed at her prompt, and everything it printed
run() { printf 'ana@laptop:~/site$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

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
run 'html-validate -f text broken.html'
block validate-title
run 'html-validate -f text unclosed-title.html'
block validate-quirks
run 'html-validate -f text quirks.html'
block validate-clean
run 'html-validate -f text skeleton.html; echo "exit status $?"'
