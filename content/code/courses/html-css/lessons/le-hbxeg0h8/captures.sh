#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of html-css, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# the lesson was copied from running it, after `bash lab.sh` beside course.json.
#
#   bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the pages in
# lab/pages/le-hbxeg0h8 are copied into /home/ana/site first, and the prompt
# shows that directory as ~/site. NO SERVER RECEIVES ANYTHING: when a form is
# sent, probe intercepts the request inside the browser, prints its method,
# address and body, and answers it with an empty response. The validation
# messages are Chromium's own, in English, because that is the language the
# browser was started in; a browser set to Portuguese words them in Portuguese.
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

block search
run "probe search.html fill '#q' 'Clarice Lispector' fill '#lang' Portuguese send button"
block labels
run 'probe labels.html tree axe'
block types
run 'probe types.html tree'
block choices-tree
run 'probe choices.html tree'
block choices-send
run 'probe choices.html send button'
run "probe choices.html check 'input[value=hardback]' check 'input[value=wrap]' check 'input[value=bag]' fill '#notes' 'Gift for Ana, 8 Oct' send button"
block buttons
run "probe buttons.html fill '#title' 'Vidas Secas' send .check2"
run "probe buttons.html fill '#title' 'Vidas Secas' send .check"
block enter
run "probe buttons.html fill '#title' 'Vidas Secas' focus '#title' press Enter fetched"
block empty
run 'probe order.html send button'
block wrong
run "probe order.html fill '#name' 'Ana Souza' fill '#email' 'ana@' fill '#cep' 05422000 fill '#copies' 9 fill '#title' V validity input"
block right
run "probe order.html fill '#name' 'Ana Souza' fill '#email' ana@example.com fill '#cep' 05422-000 fill '#copies' 2 fill '#title' 'Vidas Secas' send button"
block describe
run "probe order.html describe '#email'"
run "probe errors.html describe '#cep'"
block unchecked
run "probe unchecked.html fill '#email' 'not an address' fill '#copies' -40 send button"
