#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-b9m56ybx are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. justify.html and align.html were written by
# a short script, one container per value, and are otherwise ordinary pages.
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

block axes
run "probe axes.html box '.row .book' box '.column .book'"
block covers
run 'probe covers.html box img'
run 'probe --width 390 covers.html box img'
block justify
run "probe justify.html box '#center .book'"
run "probe justify.html box '#space-between .book'"
run "probe justify.html box '#space-around .book'"
run "probe justify.html box '#space-evenly .book'"
block align
run "probe align.html box '#stretch .book'"
run "probe align.html box '#flex-start .book'"
run "probe align.html box '#center .book'"
run "probe align.html box '#baseline .book'"
block grow
run "probe grow.html box '#grow .book'"
block shrink
run "probe grow.html box '#shrink .book'"
block minwidth
run 'probe minwidth.html box .title box .price spill .row'
block shorthand
run "probe shorthand.html style '.one p:first-child' flex-grow,flex-shrink,flex-basis"
run "probe shorthand.html box '.one p' box '.auto p' box '.none p'"
block order
run 'probe order.html box a tab tab tab'
block patterns
run "probe patterns.html box 'nav li' box '.review img' box '.review h2'"
run 'probe patterns.html box .empty box ".empty p" box main box footer'
