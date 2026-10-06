#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-019kbepm are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. flat.html is stack.html without the class
# `lifted`, and nostart.html is starting.html without its @starting-style
# block, both made with sed before the session. `at MS` pauses every animation
# and transition on the page at MS milliseconds from its start, so that a
# value in the middle of one can be read; `frames` reads Chromium's own
# counters of layouts and style recalculations. `--reduced-motion` is what a
# reader's operating system setting for reduced motion does.
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

sed 's/ lifted"/"/' stack.html > flat.html
sed '/@starting-style/,/^      }$/d' starting.html > nostart.html

block move
run 'probe move.html box .book layout .book'
block order
run 'probe order.html box .tile style .tile transform'
block fixed
run 'probe fixed.html box .toast scroll 600 box .toast'
block stack
run 'probe stack.html top 100 140'
run 'probe flat.html top 100 140'
block button
run 'probe transition.html style .button background-color hover .button at 100 style .button background-color at 200 style .button background-color'
block easing
run 'probe transition.html hover .track at 100 style .dot translate'
run 'probe transition.html hover .track at 200 style .dot translate'
block cost
run 'probe cost-margin.html frames 1000'
run 'probe cost-transform.html frames 1000'
block keyframes
run 'probe keyframes.html at 100 style .notice opacity,translate at 400 style .notice opacity,translate'
block delay
run 'probe keyframes.html at 100 style .late,.late-filled opacity'
block spin
run 'probe keyframes.html at 250 style .spinner rotate at 750 style .spinner rotate'
block reduced
run 'probe --reduced-motion reduced.html style .spinner animation-duration,animation-iteration-count style .notice opacity'
block starting
run 'probe starting.html click button at 200 style .toast display,opacity'
run 'probe nostart.html click button at 200 style .toast display,opacity'
