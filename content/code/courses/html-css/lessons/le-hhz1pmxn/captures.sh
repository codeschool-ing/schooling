#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-hhz1pmxn are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. `probe style ... grid-template-columns` prints
# the computed value, which Chromium resolves to the tracks it actually made,
# in pixels.
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

block tracks
run "probe tracks.html box '.grid > div'"
block autofit
run "probe autofit.html style .fill grid-template-columns style .fit grid-template-columns"
run "probe autofit.html box '.fill article' box '.fit article'"
block autofit-phone
run "probe --width 390 autofit.html box '.fit article'"
block lines
run "probe lines.html box '.board > *'"
block areas
run 'probe areas.html style body grid-template-areas box header box nav box main box footer'
block implicit
run "probe implicit.html style .sparse grid-template-rows box '.sparse > *'"
block dense
run "probe implicit.html box '.dense > *'"
block align
run "probe align.html box '.labels span' box '.centred p'"
block subgrid
run "probe subgrid.html box '.plain p' box '.plain a'"
run "probe subgrid.html box '.aligned p' box '.aligned a'"
block order
run 'probe order.html box a tab tab tab tab'
block home
run "probe home.html box main box aside style .cards grid-template-columns"
run "probe --width 700 home.html box main box aside style .cards grid-template-columns"
