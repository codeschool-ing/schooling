#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of manual-testing, and the widths
# the lesson quotes from the browser, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   bash ../../lab.sh isolated bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM LESSON 1: boxoffice.py is the block of
# lesson 1 section `the-app`, which ../../lab.sh app extracts. What is STAGED
# rather than typed:
#   - the server is started by lab.sh with BOXOFFICE_NOW=2026-10-10T14:00:00-03:00
#     and BOXOFFICE_SEED=lab, TZ=America/Sao_Paulo;
#   - HOME is a fresh temporary directory standing for /home/ana, so the
#     prompt reads as Ana's and two captures never share a boxoffice.py;
#   - "widths" is what the student reads in the browser's console, typing
#     document.documentElement.scrollWidth in responsive mode. Here a headless
#     Chromium driven by Playwright sets the window and asks the same
#     expression; it also reads the columns' edges, which the figure in
#     `narrow-screens` is drawn from. "outbox" signs up one account first, so
#     the outbox holds an e-mail.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Python 3.13.16, curl 8.5.0 and
# Chromium 141.0.7390.37 (Playwright's build, in /opt/pw-browsers).

HERE=$(cd "$(dirname "$0")" && pwd)
LAB=$HERE/../../lab.sh
NODE_MODULES=$(cd "$HERE/../../../../../.." && pwd)/node_modules
source "$LAB" lib
HOME=$(mktemp -d); export HOME
APP=$HOME/boxoffice
bash "$LAB" app "$APP" || exit 1
bash "$LAB" serve "$APP" || exit 1
cd "$APP" || exit 1

block css-rule
run "curl -s http://127.0.0.1:8000/ | grep -o 'table.shows{[^}]*}'"

block viewport
run "curl -s http://127.0.0.1:8000/ | grep -o '<meta name=\"viewport\"[^>]*>'"

measure() {  # PATH WIDTH...: the page's scrollWidth at each window width
  PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers node --input-type=module -e "
    import { chromium } from '$NODE_MODULES/playwright/index.mjs';
    const [path, ...widths] = process.argv.slice(1);
    const b = await chromium.launch();
    console.log('chromium', b.version());
    for (const w of widths) {
      const p = await b.newPage({ viewport: { width: +w, height: 740 } });
      await p.goto('http://127.0.0.1:8000' + path);
      const s = await p.evaluate(() => document.documentElement.scrollWidth);
      const cols = await p.evaluate(() => [...document.querySelectorAll('th')].map(t => {
        const r = t.getBoundingClientRect(); return (t.textContent || 'Book') + ' ' + Math.round(r.left) + '-' + Math.round(r.right); }));
      console.log(path, 'window', w, 'scrollWidth', s, cols.length ? 'columns: ' + cols.join(', ') : '');
      await p.close();
    }
    await b.close();" "$@"
}

block widths
measure / 360 768 775 776 1280

block other-pages
measure /signup 360
measure /book 360

block outbox
curl -s -d 'name=Ana&email=ana@example.org&password=correct-horse-2' http://127.0.0.1:8000/signup >/dev/null
measure /outbox 360
