#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-7s5msbz3 are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. notab.html is reflow-fixed.html with the
# tabindex="0" taken off its wrapper, made with sed before the session.
# `--width` sets the window's width and `width` changes it while the page is
# open. `--mobile` makes Chromium behave like a phone's browser: a touch
# screen, so `(pointer: coarse)` matches. `--reduced-motion` is what a reader's
# operating system setting for reduced motion does.
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

sed 's/ tabindex="0"//' reflow-fixed.html > notab.html

block menu
run 'probe --width 390 first.html box ".menu a"'
run 'probe --width 800 first.html box ".menu a"'
block media
run 'probe --width 600 first.html media "(width >= 40rem)" width 640 media "(width >= 40rem)" media "(min-width: 40rem)"'
block rem
run 'probe --width 700 rem.html box .box media "(width >= 40rem)" media "(width >= 45rem)"'
block measure
run 'probe --width 1200 measure.html box p'
block shell
run 'probe --width 700 shell.html box "body > *"'
run 'probe --width 800 shell.html box "body > *"'
run 'probe --width 1200 shell.html box "body > *"'
block fluid
run 'probe --width 320 fluid.html style h1 font-size width 768 style h1 font-size width 1280 style h1 font-size'
block container
run 'probe container.html box .slot box .event-card__date box .event-card__body style .event-card__title font-size'
block motion
run 'probe prefs.html style .notice animation-name'
run 'probe --reduced-motion prefs.html style .notice animation-name'
block pointer
run 'probe prefs.html media "(pointer: coarse)" box button'
run 'probe --mobile --width 390 --height 844 prefs.html media "(pointer: coarse)" box button'
block reflow
run 'probe --width 320 reflow.html overflow spill p'
block reflowed
run 'probe --width 320 reflow-fixed.html overflow spill .url spill .table-wrap'
block notab
run 'probe --width 320 notab.html axe tab'
run 'probe --width 320 reflow-fixed.html axe'
