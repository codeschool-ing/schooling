#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-049pvk3q are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. sticky-broken.html is fixed.html with its
# sections wrapped in a <div> that has overflow: hidden; stacking-fixed.html is
# stacking.html without the header's z-index. `probe box` prints positions in
# page coordinates, which is where scrolling shows up; `probe top X Y` takes a
# point in the window.
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

block relative
run 'probe relative.html box .card'
block absolute
run 'probe absolute.html box .card box .badge'
block fixed
run 'probe fixed.html box .chat'
run 'probe fixed.html scroll 500 box .chat'
block sticky
run 'probe fixed.html box h2'
run 'probe fixed.html scroll 500 box h2 top 100 20'
run 'probe fixed.html scroll 880 box h2 top 100 20'
block sticky-broken
run 'probe sticky-broken.html scroll 500 box h2'
block stacking
run 'probe stacking.html box .menu box .hero top 100 120'
run 'probe stacking-fixed.html top 100 120'
block overlay
run 'probe overlay.html box .overlay box .notice'
run 'probe --width 390 --height 844 overlay.html box .notice'
block skip
run 'probe patterns.html box .skip tab box .skip'
block stretched
run 'probe patterns.html box .card top 330 230 top 30 110'
block hidden
run 'probe patterns.html box caption tree table'
