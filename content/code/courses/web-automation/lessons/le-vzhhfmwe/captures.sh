#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `what-breaks` shows
# overlap.mjs, `taking-turns` shows turns.config.js and `the-cost` shows
# measure.sh; every test file run here was shown by lessons 1 to 18, and
# ../../lab.sh builds the project from those very blocks. Nothing in
# playwright.config.js is changed: every setting is a flag or turns.config.js.
# What is STAGED rather than typed, beyond what ../../lab.sh's header lists for
# every lesson:
#   - nothing is started by hand: every run starts the shop through webServer,
#     and a run that finds port 3000 already taken would reuse somebody else's
#     shop, so the script refuses to start if anything listens there;
#   - the colour codes. Playwright forces colour on in its workers, so a
#     failure's text can carry ANSI escapes; every Playwright line here goes
#     through sed, which deletes exactly ESC[...m and nothing else;
#   - the JSON reports are copied to /tmp/lab/L19-run1.json, -run2.json and
#     -run8.json; the lesson's timeline figure was drawn from the first;
#   - turns.config.js. `taking-turns` shows it twice at the same path, and the
#     project is built with the second; for "turns4-v1", "turns8-v1" and
#     "overlap8-v1" the first is written back with ../../lab.sh fence, and the
#     second restored after;
#   - the shards. The three run one after the other on this one machine,
#     standing in for three CI machines, and the zip each writes is moved into
#     all-blob-reports/ the way a CI job would upload it;
#   - the machine was not otherwise idle: other lessons' authors shared it,
#     though never the lab lock. /proc/loadavg is printed into blocks named
#     load-* (not quoted in the lesson) so the timings can be judged.
#
# Recorded 2026-10-16 on Ubuntu 24.04, 4 logical processors, with Node 22.22.0,
# npm 10.9.4, Playwright 1.56.0 and Chromium 141.0.7390.37,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 19 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
if (exec 3<>/dev/tcp/127.0.0.1/3000) 2>/dev/null; then
  echo "captures: something already listens on port 3000" >&2; exit 1
fi
nocolour() { sed 's/\x1b\[[0-9;]*m//g'; }
pw() { run "$1" | nocolour; }
SUMMARY="grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'"

block load-start; cat /proc/loadavg

block nproc
run 'nproc'
block default50
run "grep -n '\"50%\"' node_modules/playwright/lib/common/config.js"

block three-files
pw 'npx playwright test tests/responsive.spec.js tests/headless.spec.js tests/deals.spec.js --workers 4'
block three-files-fp
pw 'npx playwright test tests/responsive.spec.js tests/headless.spec.js tests/deals.spec.js --workers 4 --fully-parallel'

for w in 1 2 4; do
  block "w$w"
  pw "npx playwright test --workers $w | $SUMMARY"
done
block load-after-w; cat /proc/loadavg

block red4
pw "PLAYWRIGHT_JSON_OUTPUT_FILE=run.json npx playwright test --workers 4 --reporter=list,json | $SUMMARY"
block overlap1
run 'node overlap.mjs run.json'
cp run.json /tmp/lab/L19-run1.json
block red4b
pw "PLAYWRIGHT_JSON_OUTPUT_FILE=run2.json npx playwright test --workers 4 --reporter=list,json | $SUMMARY"
block overlap2
run 'node overlap.mjs run2.json'
cp run2.json /tmp/lab/L19-run2.json

# turns.config.js as taking-turns first shows it, before the fix.
cp turns.config.js /tmp/l19-turns-v2.js
bash "$HERE/../../lab.sh" fence "$HERE/taking-turns.md" turns.config.js > turns.config.js
block turns4-v1
pw "for i in 1 2 3; do npx playwright test --config turns.config.js --workers 4 | $SUMMARY; done"
block turns8-v1
pw "PLAYWRIGHT_JSON_OUTPUT_FILE=run8.json npx playwright test --config turns.config.js --workers 8 --reporter=list,json | $SUMMARY"
block overlap8-v1
run 'node overlap.mjs run8.json'
cp run8.json /tmp/lab/L19-run8.json
cp /tmp/l19-turns-v2.js turns.config.js; chown ana:ana turns.config.js

block turns-v2
for w in 1 2 4 4 8 8; do
  pw "npx playwright test --config turns.config.js --workers $w | $SUMMARY"
done

block shard-lists
for i in 1 2 3; do
  pw "npx playwright test --config turns.config.js --list --shard=$i/3 | tail -1"
done

block shards
run 'mkdir -p all-blob-reports'
for i in 1 2 3; do
  pw "npx playwright test --config turns.config.js --shard=$i/3 --reporter=list,blob | $SUMMARY"
  run "mv blob-report/report-$i.zip all-blob-reports/"
done
block merge
pw "npx playwright merge-reports --reporter list all-blob-reports | $SUMMARY"

block shards-split
run 'rm -rf all-blob-reports && mkdir all-blob-reports'
for i in 1 2 3; do
  pw "npx playwright test --config turns.config.js --project parallel --shard=$i/3 --reporter=list,blob | $SUMMARY"
  run "mv blob-report/*.zip all-blob-reports/parallel-$i.zip"
  pw "npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=$i/3 --reporter=list,blob | $SUMMARY"
  run "mv blob-report/*.zip all-blob-reports/one-at-a-time-$i.zip"
done
block merge-split
pw "npx playwright merge-reports --reporter list all-blob-reports | $SUMMARY"
block load-before-cost; cat /proc/loadavg

block cost
for w in 1 2 3 4 6 8; do
  run "bash measure.sh npx playwright test --config turns.config.js --project parallel --fully-parallel --repeat-each 4 --workers $w"
done
block load-end; cat /proc/loadavg
