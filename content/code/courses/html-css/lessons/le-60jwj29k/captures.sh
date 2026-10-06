#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-60jwj29k are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. border-box.html is box.html with one
# declaration added; menu.html is lesson 2's semantic.html with menu.css
# linked. The browser's default font size is Chromium's own, 16 pixels.
#
# Recorded 2026-10-06 on Ubuntu 24.04 with Node 22.22.0, Chromium 141 through
# Playwright 1.56.0, TZ=America/Sao_Paulo.

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

block box
run "probe box.html box .card box '.card p'"
block border-box
run "probe border-box.html box .card box '.card p'"
block display
run 'probe display.html style .tag display box .tag'
block gap
run 'probe gap.html box .frame'
block margins
run 'probe margins.html box .event box h2'
block menu
run "probe menu.html axe box 'nav a' tree nav"
block dpr
run 'probe --dpr 1 sizes.html window box .card'
run 'probe --dpr 3 sizes.html window box .card'
block em
run 'probe em.html style li font-size'
block percent
run 'probe percent.html box .half'
block viewport
run 'probe viewport.html window box .hero'
run 'probe --mobile --width 390 --height 844 viewport.html window box .hero'
block sizes
run 'probe sizes.html box .card spill .link box .link box .poster'
run 'probe --width 320 sizes.html box .card'
