/* ==========================================================================
   Schooling — every screen, put through axe

   WHY THIS IS PHASE 0 THINKING IN A PHASE 1 TOOL. Accessibility is cheap while
   there are twelve screens and a rewrite of every screen later — the same
   argument as the five tables that could not wait (X-05). And the aggravation
   here is particular: this is an education product, so a screen a reader cannot
   operate is not a degraded experience, it is a student who cannot study.

   # WHAT AN AUTOMATED CHECK DOES AND DOES NOT FIND

   axe finds what is decidable from the document: contrast below the ratio, an
   input with no label, a button whose only content is an icon, a heading level
   that skips, a landmark missing. That is perhaps a third of WCAG and it is the
   third that regresses silently, because none of it is visible to somebody who
   can see the screen.

   IT DOES NOT FIND whether the focus order makes sense, whether an error
   message is announced when it appears, whether a name describes what a control
   does. Those are read by a person, and saying so here is the difference
   between a check and a claim of compliance. This tool is the floor, not the
   ceiling — which is why the interface also carries things axe cannot see: the
   skip link, focus moved on navigation and not on first render, Escape closing
   a picker, ordering answered with buttons rather than a drag.

   # EVERY SCREEN, IN BOTH THEMES

   Both, because contrast is the most common failure and the light theme is a
   different set of colours entirely. A palette that passes in the dark and
   fails in the light is one `data-theme` away from being shipped.

   Signed out and signed in, because half the screens do not exist until
   somebody has an account — and the exam paper, which is the densest screen
   here, needs one that has started an attempt.

       node tools/a11y-test/a11y-test.mjs [base url]
   ========================================================================== */

import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

/* WCAG 2.2 AA, which is the sum of what came before it. The tags are what axe
   understands; naming them all is how "AA" stops being a word and becomes a
   list of rules that either run or do not. */
const STANDARD = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

/* See the header: Playwright finds its own browser and must not be told where
   to look. */
const launch = { args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'] };
if (process.env.CHROMIUM) launch.executablePath = process.env.CHROMIUM;

const browser = await chromium.launch(launch);

let violations = 0;
let screens = 0;

/* One page per theme, and the theme is set before the first paint so the check
   never runs against a half-applied palette.

   THE CONTEXT IS EXPLICIT because axe refuses a page that came from
   `browser.newPage()` — that shortcut makes a context of its own, and axe needs
   one it was given in order to inject itself into every frame. The error it
   raises says only "Please use browser.newContext()", so this comment is the
   rest of the sentence. */
async function open(theme, language) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  await context.addInitScript(([t, l]) => {
    localStorage.setItem('codeschool-theme', t);
    localStorage.setItem('codeschool-language', l);
  }, [theme, language]);
  const page = await context.newPage();
  page.owner = context;
  return page;
}

/* Closing the page is not closing the context it came from, and a context left
   open holds a browser process. */
async function done(page) {
  await page.close();
  await page.owner.close();
}

async function check(page, name, where) {
  await page.goto(BASE + where, { waitUntil: 'load' });
  /* The screens are built by script after the document loads, so waiting for
     the document would be checking an empty page and calling it clean. */
  await page.waitForSelector('#screen h1, #screen .notice', { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(400);

  const result = await new AxeBuilder({ page }).withTags(STANDARD).analyze();
  screens += 1;

  if (!result.violations.length) return;

  violations += result.violations.length;
  console.error(`✗ ${name}`);
  for (const v of result.violations) {
    console.error(`    ${v.id} (${v.impact}) — ${v.help}`);
    /* The selector and the markup, because "colour contrast" on a screen with
       forty elements on it is a fact nobody can act on. */
    for (const node of v.nodes.slice(0, 3)) {
      console.error(`      ${node.target.join(' ')}`);
      if (node.failureSummary) {
        console.error(`        ${node.failureSummary.split('\n').join('\n        ')}`);
      }
    }
    if (v.nodes.length > 3) console.error(`      … and ${v.nodes.length - 3} more`);
  }
}

try {
  for (const theme of ['dark', 'light']) {
    /* Signed out: what a stranger sees, which includes the verification page
       that somebody hiring will open and nothing else. */
    const out = await open(theme, 'en');
    await check(out, `${theme} · catalogue`, '/');
    await check(out, `${theme} · track`, '/#/track/frontend');
    await check(out, `${theme} · course`, '/#/course/web-fundamentals');
    await check(out, `${theme} · sign in`, '/#/sign-in');
    await check(out, `${theme} · sign up`, '/#/sign-up');
    await check(out, `${theme} · nothing there`, '/#/nowhere-at-all');
    await check(out, `${theme} · a code that certifies nothing`, '/verify/0000-0000-0000-0000');
    await done(out);

    /* And in Portuguese, once. A translated string is a different length and
       the layout has to survive it; contrast and labelling do not change, so
       running the whole list twice would be paying for the same answer. */
    const pt = await open(theme, 'pt');
    await check(pt, `${theme} · catalogue, in Portuguese`, '/');
    await done(pt);

    /* Signed in: the screens that do not exist without an account. */
    const student = await open(theme, 'en');
    await student.goto(`${BASE}/#/sign-up`, { waitUntil: 'load' });
    await student.waitForSelector('#email', { timeout: 8000 });
    await student.fill('#email', `a11y-${Date.now()}-${theme}@example.tld`);
    await student.fill('#password', 'a long enough password here');
    await student.fill('#name', 'Ada Lovelace');
    await student.click('button[type=submit]');
    await student.waitForTimeout(1200);

    await check(student, `${theme} · the dashboard`, '/#/dashboard');
    await check(student, `${theme} · certificates`, '/#/certificates');
    await check(student, `${theme} · a lesson`, '/#/course/web-fundamentals/client-and-server');

    /* THE DRILL, WHICH IS A QUESTION AND A VERDICT ON ONE SCREEN. It is worth
       checking separately from the exam paper: the exam shows every question at
       once and never marks one, this shows one at a time and then puts a result
       beside it — which is a live region, a disabled button and a moved focus
       that the exam never has. */
    await check(student, `${theme} · the drill`, '/#/practice');

    /* THE DENSEST SCREEN THERE IS, and the one worth the trouble of getting
       into: every question type on one page, every one of them a control. */
    await student.goto(`${BASE}/#/exam/course/web-fundamentals`, { waitUntil: 'load' });
    await student.waitForTimeout(1500);
    if (await student.locator('.question').count()) {
      /* AND EVERY ONE OF THEM A CONTROL, checked rather than assumed. A type
         the interface cannot draw falls back to a notice saying so, and that
         notice is perfectly accessible — so axe would pass a paper on which a
         question had quietly stopped being answerable. The fixture carries one
         question of every renderable type precisely so that this line can say
         a renderer went missing. */
      const cannot = await student.locator('.notice.bad').allInnerTexts();
      if (cannot.length) {
        violations += cannot.length;
        console.error(`✗ ${theme} · sitting an exam — ${cannot.length} question(s) the ` +
          'interface cannot draw, which is a missing renderer rather than a bad fixture:');
        for (const text of cannot) console.error(`      ${text}`);
      }

      const result = await new AxeBuilder({ page: student }).withTags(STANDARD).analyze();
      screens += 1;
      if (result.violations.length) {
        violations += result.violations.length;
        console.error(`✗ ${theme} · sitting an exam`);
        for (const v of result.violations) {
          console.error(`    ${v.id} (${v.impact}) — ${v.help}`);
          for (const node of v.nodes.slice(0, 3)) console.error(`      ${node.target.join(' ')}`);
        }
      }
    } else {
      console.log(`  (no exam to sit in ${theme}; that screen was not checked)`);
    }

    await done(student);
  }
} finally {
  await browser.close();
}

if (violations) {
  console.error(`\n${violations} violations across ${screens} screens`);
  console.error('These are the failures a person looking at the screen cannot see, which is');
  console.error('why they are checked by a machine. What a machine cannot check — whether the');
  console.error('focus order makes sense, whether a name describes what a control does — is');
  console.error('still somebody reading the screen, and this passing does not mean that was done.');
  process.exit(1);
}

console.log(`${screens} screens, no violation axe can see`);
