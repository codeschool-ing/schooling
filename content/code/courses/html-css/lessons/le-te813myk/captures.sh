#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-te813myk are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. layers-plus.css is layers.css with one
# unlayered rule appended. `probe --dark` starts Chromium with its colour
# scheme set to dark, which is what a reader's operating system setting does.
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

block tokens
run "probe events.html style :root --accent,--space style '.event h2' color style .event padding-left"
block scope
run 'probe events.html style .cancelled --accent style .event border-left-color'
block fallback
run 'probe fallback.html style .missing padding-left style .typo padding-left'
block invalid
run 'probe fallback.html rules .wrong color'
block theme
run 'probe theme.html style body background-color,color style a color axe'
run 'probe --dark theme.html style body background-color,color style a color axe'
block scale
run 'probe scale.html style :root --space-2,--space-4 style .card padding-top,margin-bottom box .main'
block files
run 'find css -type f | sort'
block fetched
run 'probe site.html fetched'
block site
run 'probe site.html style .event-card border-left-color,padding-top style .event-card__title font-size'
block layers
run 'probe layers.html rules .button color'
block unlayered
run 'probe layers-plus.html rules .button color'
