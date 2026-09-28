#!/usr/bin/env bash
# Lesson 13 of portfolio-project: what axe and a keyboard find on loanbook's page.
#
# THIS ONE DID NOT RUN IN THE LAB. laptop and srv have no browser, so these two
# checks ran on the machine that recorded the course, from a checkout of this
# repository after `npm ci` (Playwright with Chromium, and @axe-core/playwright
# 4.13), with Python 3.11 serving loanbook. The transcripts in the lesson say `$`
# rather than ana@laptop for that reason.
#
# What is STAGED rather than typed, and not shown in the lesson:
#   - loanbook is rebuilt with lab.sh at step 10, then at step 12; each time two
#     items are added, Projector 2 is lent, and the server started on port 8000.
#   - The two scripts below are written into .axe-demo/ in the checkout.
mkdir -p ${CHECKOUT:-/home/user/schooling}/.axe-demo
cat > ${CHECKOUT:-/home/user/schooling}/.axe-demo/axe-check.mjs <<'MJS'
// Open the page in Chromium at two widths and print what axe finds.
import { chromium } from 'playwright';
import { AxeBuilder } from '@axe-core/playwright';

const url = process.argv[2] || 'http://127.0.0.1:8000/';
const browser = await chromium.launch();
for (const width of [1280, 320]) {
  const context = await browser.newContext({ viewport: { width, height: 800 } });
  const page = await context.newPage();
  await page.goto(url);
  await page.waitForSelector('#items tr');
  const { violations } = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa', 'wcag22aa'])
    .analyze();
  const sideways = await page.evaluate(
    () => document.documentElement.scrollWidth > window.innerWidth);
  console.log(`${width}px: ${violations.length} problem(s)` +
    (sideways ? ', and the page scrolls sideways' : ''));
  for (const v of violations) {
    console.log(`  ${v.id}: ${v.nodes.length} element(s). ${v.help}`);
  }
  await context.close();
}
await browser.close();
MJS
cat > ${CHECKOUT:-/home/user/schooling}/.axe-demo/tab-walk.mjs <<'MJS'
// Press Tab through the page and print what each stop is called: its label,
// else its placeholder, else its text. A rough stand-in for what a screen
// reader announces, and enough to hear a name that says nothing.
import { chromium } from 'playwright';

const url = process.argv[2] || 'http://127.0.0.1:8000/';
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url);
await page.waitForSelector('#items tr');
for (let i = 1; i <= 6; i++) {
  await page.keyboard.press('Tab');
  const stop = await page.evaluate(() => {
    const el = document.activeElement;
    if (!el || el === document.body) return null;
    const name = (el.labels && el.labels[0] && el.labels[0].innerText) ||
      el.getAttribute('placeholder') || el.innerText;
    return `${el.tagName.toLowerCase()}: ${name.trim()}`;
  });
  if (!stop) break;
  console.log(`${i}. ${stop}`);
}
await browser.close();
MJS
set -u
D=${CHECKOUT:-/home/user/schooling}/.axe-demo
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1; }
serve() { rm -rf $D/lb; LOANBOOK=$D/lb bash ${CHECKOUT:-/home/user/schooling}/content/code/courses/portfolio-project/lab.sh stage $1 >/dev/null 2>&1
  (cd $D/lb && python3 app.py add "Projector 1" >/dev/null && python3 app.py add "Projector 2" >/dev/null && (python3 app.py >/dev/null 2>&1 &) ); sleep 1
  curl -s -X POST localhost:8000/api/items/2/loan -d '{"borrower": "Beatriz Nunes"}' >/dev/null; }
stop() { pkill -f '^python3 app[.]py$'; sleep 0.5; }
cd $D
serve 10
printf '##### before\n'
run node axe-check.mjs
printf '##### before-tab\n'
run node tab-walk.mjs
stop
serve 12
printf '##### after\n'
run node axe-check.mjs
printf '##### after-tab\n'
run node tab-walk.mjs
stop
