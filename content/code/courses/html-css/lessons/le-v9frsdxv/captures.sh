#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-v9frsdxv are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. Each of first/, bare/, theme/, variants/,
# dynamic/ and components/ is a small site of its own, with an input.css and
# one page, and each build is run with --cwd in that directory, so that it
# scans one page and nothing else.
#
# The lesson shows `npm install` and does not quote what it printed, because
# that depends on the network on the day. What it would have produced is
# STAGED instead: ~/site/node_modules is a link to the node_modules lab.sh
# installed, which holds tailwindcss and @tailwindcss/cli at 4.3.3, exactly
# the packages that command names. npm_config_offline makes npx use them and
# never ask the registry for anything.
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
ln -s "$LAB/node_modules" node_modules
export npm_config_offline=true

block build
run 'npx @tailwindcss/cli --cwd first -i input.css -o out.css --silent'
block only
run 'grep -A2 "\.p-4 {" first/out.css'
run 'grep -c "p-5" first/out.css'
run 'probe first/index.html style "#content" padding-top,max-width style "#title" font-size,font-weight style "#poetry" border-left-color'
block tokens
run 'grep -n "@layer" first/out.css'
run 'grep -E -- "--(spacing|color-[a-z]+-[0-9]+):" first/out.css'
block preflight
run 'npx @tailwindcss/cli --cwd bare -i input.css -o out.css --silent'
run 'probe bare/index.html style h1 font-size,font-weight style ul list-style-type,padding-left style a color,text-decoration-line'
block theme
run 'npx @tailwindcss/cli --cwd theme -i input.css -o out.css --silent'
run 'grep -E -- "--(color-andorinha|color-cancelled|font-display)[a-z0-9-]*:" theme/out.css'
run 'probe theme/index.html style body background-color style "#title" font-family,font-size style "#poetry,#swap" color'
block media
run 'npx @tailwindcss/cli --cwd variants -i input.css -o out.css --silent'
run 'grep -n "@media" variants/out.css'
block widths
run 'probe --width 700 variants/index.html style "#events" grid-template-columns width 800 style "#events" grid-template-columns width 1100 style "#events" grid-template-columns'
block states
run 'probe variants/index.html style "#reserve" background-color hover "#reserve" at 150 style "#reserve" background-color'
run 'probe --dark variants/index.html style "#page" background-color,color'
block dynamic
run 'npx @tailwindcss/cli --cwd dynamic -i input.css -o out.css --silent'
run 'grep -c "text-red-700" dynamic/out.css'
run 'grep -c "text-green-700" dynamic/out.css'
run 'probe dynamic/index.html style "#status" color'
block apply
run 'npx @tailwindcss/cli --cwd components -i input.css -o out.css --silent'
run 'grep -A8 "^  \.btn {" components/out.css'
run 'probe components/index.html style "#reserve,#wait" background-color'
block canonical
run 'npx @tailwindcss/cli canonicalize "p-[16px] mt-[4px] w-[37rem] text-[#2f6f4e]"'
block minify
run 'npx @tailwindcss/cli --cwd first -i input.css -o out.min.css --minify --silent'
run 'wc -c first/out.css first/out.min.css'
