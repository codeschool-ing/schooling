#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of manual-testing, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# What is STAGED rather than typed:
#   - boxoffice.py is 1.0 from lesson 1 with the 1.1 edits of lesson 9 applied
#     (../../lab.sh app, then release), which is the student's file by now;
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, and the whole script runs in a network namespace
#     of its own, so the timings are of one machine talking to itself;
#   - "axe" is not a step of the lesson and the student is not asked to run it:
#     it is the evidence for one sentence of `accessibility`, that axe-core
#     passes the tickets field. It needs the repository's node_modules
#     (@axe-core/playwright and a Chromium for Playwright) and is skipped with a
#     line saying so when they are missing.
#
# The timings differ on every run and on every machine; the prose quotes the
# ones below and says so. The Date header is the real clock.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16, curl 8.5.0 and
# axe-core 4.13.0, TZ=America/Sao_Paulo. Run as root with HOME=/home/ana, so
# the paths read as Ana's.

LESSON=$(cd "$(dirname "$0")" && pwd)
LAB=$LESSON/../../lab.sh
REPO=$(cd "$LESSON/../../../../../.." && pwd)
source "$LAB" lib
APP=$HOME/boxoffice
rm -rf "$APP"; bash "$LAB" app "$APP" && bash "$LAB" release "$APP" || exit 1
bash "$LAB" serve "$APP" || exit 1
cd "$HOME" || exit 1

block one-request
run "curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' http://127.0.0.1:8000/"

block twenty
run "for i in \$(seq 20); do curl -s -o /dev/null -w '%{time_total}\n' http://127.0.0.1:8000/ & done | sort -n | tail -n 3"

block leak
run "curl -s -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book"
echo    # the page ends without a newline; the next prompt would follow it on the same line

block leak-status
run "curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book"

block headers
run "curl -s -o /dev/null -D - http://127.0.0.1:8000/"

block no-order
run "curl -s 'http://127.0.0.1:8000/order?id=9999' | grep msg"

block password
run "curl -s -d 'name=Caio&email=caio@example.org&password=12345678' http://127.0.0.1:8000/signup | grep msg"
run "curl -s http://127.0.0.1:8000/outbox | grep -c 12345678"

block exists
run "curl -s -d 'name=Somebody&email=member@example.org&password=long-enough' http://127.0.0.1:8000/signup | grep msg"

block label
run "curl -s http://127.0.0.1:8000/book | grep -E '<input|<select'"

block axe
if [ -d "$REPO/node_modules/@axe-core/playwright" ]; then
  ( cd "$REPO" && node --input-type=module -e "
import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';
const browser = await chromium.launch();
const page = await (await browser.newContext()).newPage();
await page.goto('http://127.0.0.1:8000/book');
const r = await new AxeBuilder({ page })
  .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa']).analyze();
console.log('axe-core', r.testEngine.version, 'violations:', r.violations.length);
for (const n of r.passes.find((x) => x.id === 'label').nodes)
  console.log('label passes', n.html, n.any.map((a) => a.id).join(' '));
await browser.close();
" )
else
  echo "axe skipped: no node_modules/@axe-core/playwright in $REPO"
fi
