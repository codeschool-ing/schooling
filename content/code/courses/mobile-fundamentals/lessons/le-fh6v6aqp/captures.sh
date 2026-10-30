#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of mobile-fundamentals, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds
# it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as lab.sh
# installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner with lesson 1's package.json and planner.ts, and lesson 10's
#     backstack.ts, each taken out of the lesson that prints it.
#   - links.ts (the-parser.md), follow.ts (the-parser.md) and site.ts
#     (the-files.md), taken out of this lesson.
#   - site.ts is started in the background on port 8011 for the "curl" block,
#     as the lesson has the student start it in a second terminal, and stopped
#     after it. It answers on 127.0.0.1 only and nothing outside reaches it.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

for f in package.json planner.ts; do put ../le-55jmmbqr/the-planner.md $f $P/$f; done
put ../le-dpej0m52/the-model.md backstack.ts $P/backstack.ts
put the-parser.md links.ts $P/links.ts
put the-parser.md follow.ts $P/follow.ts
put the-files.md site.ts $P/site.ts

block follow
run $P 'node follow.ts'

serve $P 8011 'node site.ts'
block curl
run $P 'curl -si http://127.0.0.1:8011/.well-known/assetlinks.json'
run $P 'curl -si http://127.0.0.1:8011/.well-known/apple-app-site-association'
run $P 'curl -si http://127.0.0.1:8011/.well-known/assetlinks'
run $P 'curl -si http://127.0.0.1:8011/course/sql'
unserve
