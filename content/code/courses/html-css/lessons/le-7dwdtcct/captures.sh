#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-7dwdtcct are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. The trees are Playwright's ARIA snapshot of
# what Chromium exposes to assistive technology; the rule list is axe-core
# 4.13.0 run with the WCAG 2.0, 2.1 and 2.2 A and AA tags and best practices.
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

block soup-tree
run 'probe soup.html tree'
block semantic-tree
run 'probe semantic.html tree'
block headings
run 'probe headings.html tree axe'
block sections
run 'probe sections.html tree'
block lists
run 'probe lists.html tree'
block controls-tree
run 'probe controls.html tree'
block controls-tab
run 'probe controls.html tab press Enter text "#status" tab tab'
block names
run 'probe names.html tree axe'
block axe-soup
run 'probe soup.html axe'
block axe-semantic
run 'probe semantic.html axe box "nav a"'
