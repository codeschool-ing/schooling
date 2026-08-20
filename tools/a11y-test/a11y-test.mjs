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

/* A SCREEN THAT WAS NEVER DRAWN IS THE EASIEST SCREEN IN THE WORLD TO PASS.

   The router answers an address it does not recognise with a short, tidy,
   perfectly accessible "page not found": one paragraph, good contrast, nothing
   to trip over. Axe reads it and reports no violation, this counted a screen,
   and the run went green.

   That is not a hypothetical. When the interface here was replaced by the
   portal's client the routes changed shape, and two of the lines below kept
   asking for the old ones — `/#/course/<id>/<lesson>` and `/#/exam/course/<id>`.
   The lesson screen and the exam paper, the two densest screens there are, had
   not been measured since. Nothing said so, because there was nothing that
   could: every check this file makes is a check on what is on the screen, and
   what was on the screen was fine.

   So the router now writes the route it matched onto the content region, and
   this refuses a screen that is not the one it asked for. `expect` is the
   pattern — `/course/:id`, not the address — and `expect: 'not-found'` is how
   the one deliberate miss below says it means it. */
async function check(page, name, where, expect, settled) {
  await page.goto(BASE + where, { waitUntil: 'load' });
  /* The screens are built by script after the document loads, so waiting for
     the document would be checking an empty page and calling it clean. */
  await page.waitForSelector('#content h1, #content .notice', { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(400);

  const drew = await page.locator('#content').getAttribute('data-screen');
  if (expect && drew !== expect) {
    violations += 1;
    console.error(`✗ ${name} — the router drew ${drew ? `"${drew}"` : 'nothing'} and this asked `
      + `for "${expect}". A screen that was never drawn passes every check there is, `
      + `so this is a route that moved rather than a screen that is fine.`);
    return;
  }

  /* AND A SCREEN THAT FILLS ITSELF AFTERWARDS IS WAITED FOR. `data-screen` is
     written when the screen is BUILT, and the drill's card arrives one request
     later — so without this, axe would measure the word "drawing…" on an
     otherwise empty page and report it clean. Same failure the `expect` above
     exists for, one step further in. */
  if (settled) {
    const there = await page.waitForSelector(settled, { timeout: 8000 }).catch(() => null);
    if (!there) {
      violations += 1;
      console.error(`✗ ${name} — the screen drew but "${settled}" never arrived, so what `
        + 'would have been measured is a placeholder. A screen that is still loading '
        + 'passes every check there is.');
      return;
    }
  }

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
    /* Signed out: what a stranger sees.

       `/` IS THE DASHBOARD AND NOT THE CATALOGUE. With no fragment the router
       falls back to `/dashboard`, which signed out is the invitation to sign
       in. That is worth checking and it is not the catalogue, so it is named
       for what it is and the catalogue is asked for by its own address.

       The certificate verification page used to be here too, as
       `/verify/<code>`. There is no such route in this client — that address
       has no fragment, so it drew the dashboard, under a name that said
       otherwise. It is left out rather than renamed: a screen this suite cannot
       reach should be absent from the list, where somebody will notice it, and
       not present as a line that measures something else. */
    const out = await open(theme, 'en');
    await check(out, `${theme} · the way in`, '/', '/dashboard');
    await check(out, `${theme} · catalogue`, '/#/catalog', '/catalog');
    await check(out, `${theme} · track`, '/#/track/frontend', '/track/:id');
    await check(out, `${theme} · course`, '/#/course/web-fundamentals', '/course/:id');
    await check(out, `${theme} · sign in`, '/#/sign-in', '/sign-in');
    await check(out, `${theme} · nothing there`, '/#/nowhere-at-all', 'not-found');
    /* The two documents, signed out, because signed out is when they are read:
       somebody deciding whether to hand over an e-mail address. They are also
       the longest prose the interface renders outside a lesson, which is where
       a heading level skipped by the Markdown renderer would show up. */
    await check(out, `${theme} · terms of use`, '/#/terms', '/terms');
    await check(out, `${theme} · privacy policy`, '/#/privacy', '/privacy');
    await done(out);

    /* And in Portuguese, once. A translated string is a different length and
       the layout has to survive it; contrast and labelling do not change, so
       running the whole list twice would be paying for the same answer. */
    const pt = await open(theme, 'pt');
    await check(pt, `${theme} · catalogue, in Portuguese`, '/#/catalog', '/catalog');
    await check(pt, `${theme} · privacy policy, in Portuguese`, '/#/privacy', '/privacy');
    await done(pt);

    /* Signed in: the screens that do not exist without an account. */
    /* ONE SCREEN, TWO MODES. There is no `#/sign-up`: the interface is
       `portal-frontend`'s, where signing in and registering are the same screen
       and `#e-toggle` swaps between them. The ids are that screen's too.

       This list used to ask for `/#/sign-up` all the same, and got the router's
       "page not found" — a clean screen that passes every check there is. */
    const student = await open(theme, 'en');
    await student.goto(`${BASE}/#/sign-in`, { waitUntil: 'load' });
    await student.waitForSelector('#e-toggle', { timeout: 8000 });
    await student.click('#e-toggle');
    await student.waitForSelector('#e-name', { timeout: 8000 });
    await student.fill('#e-name', 'Ada Lovelace');
    await student.fill('#e-email', `a11y-${Date.now()}-${theme}@example.tld`);
    await student.fill('#e-password', 'a long enough password here');
    await student.click('#form-signin button[type=submit]');
    await student.waitForTimeout(1500);

    await check(student, `${theme} · the dashboard`, '/#/dashboard', '/dashboard');
    await check(student, `${theme} · certificates`, '/#/certificates', '/certificates');
    /* A LESSON IS `/course/:id/lesson/:ix` AND HAS BEEN SINCE THE INTERFACE WAS
       REPLACED. This asked for `/#/course/<id>/<lesson-id>`, which is the shape
       the retired client used and matches no route here — so what was measured
       under the name "a lesson" was the router's miss. Two contrast defects had
       been sitting on the real screen the whole time. */
    await check(student, `${theme} · a lesson`,
      '/#/course/web-fundamentals/lesson/0', '/course/:id/lesson/:ix');

    /* THE DRILL, WHICH IS A QUESTION AND A VERDICT ON ONE SCREEN. It is worth
       checking separately from the exam paper: the exam shows every question at
       once and never marks one, this shows one at a time and then puts a result
       beside it — which is a live region, a disabled button and a moved focus
       that the exam never has. */
    await check(student, `${theme} · the drill`, '/#/practice', '/practice', '.ex');

    /* AND THE DRILL WITH A VERDICT ON IT, which is a different screen and the
       one this feature is actually about: a live region that has just been
       written into, controls that have gone disabled, the answer revealed over
       what the student gave, and focus moved to "next". None of that exists on
       the screen above, and an exam never reaches this state at all — it holds
       every verdict until the paper closes. */
    const card = await student.locator('.ex').count();
    if (!card) {
      violations += 1;
      console.error(`✗ ${theme} · a drilled answer — no card was drawn, so the state after `
        + 'answering one was never measured.');
    } else {
      const choices = student.locator('.choice');
      if (await choices.count()) await choices.first().click();
      await student.locator('.ex-answer').click();
      await student.waitForSelector('.ex-verdict.v-right, .ex-verdict.v-wrong', { timeout: 8000 })
        .catch(() => null);

      const marked = await new AxeBuilder({ page: student }).withTags(STANDARD).analyze();
      screens += 1;
      if (marked.violations.length) {
        violations += marked.violations.length;
        console.error(`✗ ${theme} · a drilled answer`);
        for (const v of marked.violations) {
          console.error(`    ${v.id} (${v.impact}) — ${v.help}`);
          for (const node of v.nodes.slice(0, 3)) console.error(`      ${node.target.join(' ')}`);
        }
      }
    }

    /* THE EXAM PAPER, QUESTION BY QUESTION — and it is walked rather than
       glanced at, because this wizard shows ONE question at a time.

       That is what makes the fixture worth its length. It carries one question
       of every renderable type, and each of them is a different set of controls:
       a radio group, a checkbox group, the ordering buttons, the matching tiles,
       an input inside a sentence, a number with a unit, and a picture with a
       radio per label and the arrow keys driving it. Axe run once on this screen
       would measure whichever one happened to be first and report eight.

       IT ALSO CATCHES A RENDERER GOING MISSING. A type the interface cannot draw
       falls back to `.ex-error`, which is a perfectly accessible paragraph — so
       without this line axe would happily pass a paper on which a question had
       quietly stopped being answerable. Three of them were in exactly that state
       until the modules for them were ported. */
    await student.goto(`${BASE}/#/course/web-fundamentals/exam`, { waitUntil: 'load' });
    await student.waitForTimeout(1800);

    const paper = await student.locator('.wz-dot').count();
    if (!paper) {
      violations += 1;
      console.error(`✗ ${theme} · sitting an exam — the paper did not draw at all. `
        + 'This is the densest screen in the interface and nothing here was measured.');
    }

    for (let q = 0; q < paper; q += 1) {
      if (q) {
        await student.locator('.wz-next').click();
        await student.waitForTimeout(350);
      }

      const kind = (await student.locator('.ex').first().getAttribute('class') || '')
        .replace(/(^| )ex( |$)/, ' ').replace(/ex-exam/, '').replace(/ex-/g, '').trim();

      const cannot = await student.locator('.ex-error').allInnerTexts();
      if (cannot.length) {
        violations += cannot.length;
        console.error(`✗ ${theme} · exam question ${q + 1} (${kind}) — the interface cannot `
          + 'draw it, which is a missing renderer rather than a bad fixture:');
        for (const text of cannot) console.error(`      ${text}`);
      }

      const result = await new AxeBuilder({ page: student }).withTags(STANDARD).analyze();
      screens += 1;
      if (result.violations.length) {
        violations += result.violations.length;
        console.error(`✗ ${theme} · exam question ${q + 1} (${kind})`);
        for (const v of result.violations) {
          console.error(`    ${v.id} (${v.impact}) — ${v.help}`);
          for (const node of v.nodes.slice(0, 3)) {
            console.error(`      ${node.target.join(' ')}`);
            if (node.failureSummary) {
              console.error(`        ${node.failureSummary.split('\n').join('\n        ')}`);
            }
          }
        }
      }
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
