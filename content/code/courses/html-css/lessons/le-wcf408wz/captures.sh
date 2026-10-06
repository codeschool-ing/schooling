#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-wcf408wz are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. cascade.html, order.html, inherit.html,
# states.html and extras.html are events.html with a different stylesheet
# linked, made with sed. `probe rules` reads the matched rules from Chromium's
# DevTools protocol (CSS.getMatchedStylesForNode), which is the list the Styles
# panel draws, and the specificity printed beside each selector is Chromium's.
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

block first-rule
run 'probe events.html rules h2 font-size'
block basic
run "probe events.html match h2 match .featured match '#events' match '[href]'"
block combinators
run "probe events.html match 'main p' match 'main > p'"
run "probe events.html match 'h2 + p' match 'h2 ~ p'"
block states
run 'probe states.html style .event background-color'
run "probe states.html style '.event h2' color style .event border-left-width"
block hover
run 'probe states.html style .more text-decoration-line hover .more style .more text-decoration-line'
block focus
run 'probe states.html tab style .more outline-style,outline-width'
block user-invalid
run 'probe signup.html style input border-top-color,background-color fill input ana@ press Tab style input border-top-color,background-color'
block pseudo
run "probe extras.html style '.featured h2::before' content,color text '.featured h2'"
block specificity
run 'probe cascade.html rules .note color'
block specificity-2
run "probe cascade.html rules '.cancelled p' color"
block order
run "probe order.html rules '.featured h2' color"
block important
run 'probe order.html rules .intro color'
block inherit
run 'probe inherit.html style .note color,font-family,border-top-width rules .note color'
block keywords
run "probe inherit.html style .more color style '.cancelled h2' color"
block ua
run 'probe events.html rules .more color'
