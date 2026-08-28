/* ==========================================================================
   The console, used rather than looked at.

   # WHAT THIS EXISTS FOR, AND WHY AXE IS NOT IT

   `a11y-test` opens every console screen and measures it. It proves the markup
   is sound and that the data arrived. It never presses anything — so every
   WRITE this console can do has a Go test against a real Postgres and has never
   been performed by a browser.

   That gap has a precedent with a name. `mfa-test` says it: every part of the
   second factor had a Go test against a real Postgres and every one of them
   passed while `ui/app/api.js` refused with "this school does not have
   multi-factor sign-in yet". The server being right is not the claim; the round
   trip is.

   # THE TWO WRITES IT PERFORMS

   Both are chosen because a Go test cannot see them and axe cannot either: they
   are about what happens to the SCREEN after the server has answered.

     SETTLING A REPORT   a student says a section is wrong, an operator answers
                         it, and the queue must lose the card. A screen that
                         wrote the decision and left the row standing is a queue
                         two people work twice.

     SAVING A PRICE      the whole of K-14 is that the old price is still there,
                         and that pricing the year leaves the other terms alone.
                         A screen showing only the newest number would be the
                         mutable column again with extra steps, and it would
                         look correct.

   # IT IS NOT A SECOND ACCESSIBILITY SUITE

   Nothing here measures contrast or labels. Where the two suites overlap is the
   operator, which is why making one moved to `tools/lib/operator.mjs`.

       node tools/console-test/console-test.mjs [base url]

   The console's address is derived from the school's, as it is over there and
   in `console.HostOf`: two ways to say one address is two ways to disagree.
   ========================================================================== */

import { chromium } from 'playwright';

import { signUpThroughTheForm } from '../lib/sign-up.mjs';
import { makeAnOperator } from '../lib/operator.mjs';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

const CONSOLE = (() => {
  const at = new URL(BASE);
  at.hostname = 'console.' + at.hostname.split('.').slice(1).join('.');
  return at.origin;
})();

const launch = {
  args: [`--host-resolver-rules=MAP ${new URL(BASE).hostname} 127.0.0.1,`
       + `MAP ${new URL(CONSOLE).hostname} 127.0.0.1`],
};
if (process.env.CHROMIUM) launch.executablePath = process.env.CHROMIUM;

const browser = await chromium.launch(launch);

let failures = 0;
const stamp = Date.now();

function bad(what, said) {
  failures += 1;
  console.error(`✗ ${what}\n    ${said}`);
}

function good(what) {
  console.log(`✓ ${what}`);
}

async function open() {
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
  const page = await context.newPage();
  page.owner = context;
  return page;
}

async function done(page) {
  await page.close();
  await page.owner.close();
}

/* Reaching a console screen and knowing it is really there. `data-screen` is
   written when the screen is BUILT, which is the same signal the accessibility
   suite settles on — and for the same reason: a router that missed answers with
   a tidy "no such screen" that would pass anything asked loosely enough. */
async function go(page, hash, expect) {
  await page.goto(`${CONSOLE}/#/${hash}`, { waitUntil: 'load' });
  await page.waitForSelector(`#stage[data-screen="/${expect}"]`, { timeout: 15000 });
}

/* THE QUEUE IS ONE SCHOOL'S, and which school is a `<select>` that starts on
   the first. CI seeds exactly one, so the report is under the default there —
   but the local stack seeds a second under another name, and a suite that only
   ever looked at the first would fail on one machine and pass on the other for
   a reason that has nothing to do with the feature.

   So it walks the list. What it is proving is that the report reached the
   console at all; which option was selected when it did is not the claim. */
async function findTheReport(page, note) {
  const options = await page.locator('#school option').evaluateAll(
    (all) => all.map((o) => o.value));

  for (const school of options.length ? options : ['']) {
    if (school) {
      await page.selectOption('#school', school);
      await page.waitForSelector('#queue .checking', { state: 'detached', timeout: 15000 })
        .catch(() => {});
    }
    await page.waitForSelector('.report-card, #queue .none', { timeout: 15000 });

    const mine = page.locator('.report-card').filter({ hasText: note });
    if (await mine.count() === 1) return mine;
  }
  return null;
}

try {
  /* ---------- a student, and something to answer ----------

     THE REPORT IS MADE THROUGH THE STUDENT'S OWN SCREEN. It is setup rather
     than the claim, and it is still the screen: a suite that posted the report
     would be arranging the console's half against a row no interface can
     produce, which is the shape of a test that passes while the feature is
     unreachable. */
  const student = await open();
  await signUpThroughTheForm(student, BASE, {
    name: 'Ada Lovelace',
    email: `console-${stamp}@example.tld`,
  });

  /* A LESSON IS `/course/:id/lesson/:ix`, the same address the accessibility
     pass reaches, and `web-fundamentals` is the fixture's first course. */
  await student.goto(`${BASE}/#/course/web-fundamentals/lesson/0`, { waitUntil: 'load' });
  await student.waitForSelector('#content[data-screen="/course/:id/lesson/:ix"]',
    { timeout: 15000 });

  /* THE NOTE CARRIES THE RUN'S STAMP, because this database is not truncated
     between runs and the queue holds every report any previous one made. A card
     found by its reason or its path would be a card from March. */
  const NOTE = `the console round trip put this here (${stamp})`;

  const control = student.locator('.report-section');
  if (!(await control.evaluate((d) => d.open))) {
    await control.locator('summary').click();
  }
  await student.waitForSelector('.report-section .report-form', { timeout: 15000 });
  await student.locator('.report-section .report-note').fill(NOTE);
  await student.locator('.report-section .report-form button[type=submit]').click();
  await student.waitForSelector('.report-section .report-said', { timeout: 15000 });
  await done(student);

  /* ---------- the operator ---------- */

  const staff = await open();
  await makeAnOperator(staff, BASE, {
    name: 'Grace Hopper',
    email: `console-staff-${stamp}@example.tld`,
    by: 'the console round trip',
  });

  /* ---------- settling a report ---------- */

  await go(staff, 'reports', 'reports');
  const mine = await findTheReport(staff, NOTE);

  if (!mine) {
    bad('a report made on the student screen reaches the console queue',
      'no school\'s queue holds the report just made — the two ends of this feature '
      + 'are not joined');
  } else {
    good('a report made on the student screen reaches the console queue');

    const before = await staff.locator('.report-card').count();

    // "The material was changed" — the first of the verdicts the server offers.
    await mine.locator('.verdict-pick').first().click();

    /* THE CARD MUST GO. The screen redraws the queue after a settle, and a
       decision written to the database while the row stays on the glass is a
       report the next operator picks up again.

       IT IS THIS CARD AND NOT THE COUNT. A queue that shrank by one while
       leaving the settled report standing would pass a count, and it is exactly
       the shape a redraw against the wrong school produces. */
    try {
      await mine.waitFor({ state: 'detached', timeout: 15000 });
      good('settling a report takes it out of the queue');
    } catch (e) {
      const now = await staff.locator('.report-card').count();
      bad('settling a report takes it out of the queue',
        `the card was still there after the verdict (${before} before, ${now} now) — a `
        + 'decision written and a row left standing is a queue two people work twice');
    }
  }

  /* ---------- a price, and the one before it ---------- */

  /* IT IS ITS OWN SCREEN NOW. This walked the schools screen while every school
     carried a price form, and had to scope every locator to one school's block
     so that the second school's rows were not counted into the first one's
     series. `0041` made the price the platform's — one subscription opens every
     school (N-02) — so there is one series, and the scoping that mattered here
     is gone with the thing it was guarding against.

     WHAT IS SCOPED INSTEAD IS THE TERM. The three products share the series, so
     "a row was added" has to be a row for the term that was saved; counting the
     whole list would be satisfied by a price for the month while the year went
     nowhere. */

  await go(staff, 'plan', 'plan');

  await staff.locator('.price-list, #series .none').first()
    .waitFor({ timeout: 15000 });

  const year = staff.locator('.block[data-term="12"]');
  const rows = staff.locator('.price-row');
  const yearRows = () => staff.locator('.price-row', { hasText: 'A year' });
  const rowsBefore = await yearRows().count();

  // What is in force before the save, which is what has to survive it.
  const wasShown = rowsBefore > 0
    ? (await yearRows().first().locator('.price-money').innerText()).trim()
    : '';

  /* AN AMOUNT NO FIXTURE USES. The series is not emptied between runs, so a
     price equal to the seeded one would make "the newest row is the one just
     saved" true without anything having been saved. */
  await year.locator('.price-amount input').fill('612.34');
  await year.locator('.price-currency input').fill('EUR');
  await year.locator('.price-form button[type=submit]').click();

  try {
    await staff.waitForFunction(
      (n) => [...document.querySelectorAll('.price-row')]
        .filter((r) => r.querySelector('.price-term')?.textContent.trim() === 'A year')
        .length > n,
      rowsBefore, { timeout: 15000 });
    good('saving a price adds a row to the series');
  } catch (e) {
    const said = await year.locator('.signin-notice').innerText().catch(() => '');
    bad('saving a price adds a row to the series',
      `the year has ${rowsBefore} row(s) and the screen says ${JSON.stringify(said)} `
      + '— a price that replaced instead of appending is the mutable column again, and it '
      + 'looks correct');
  }

  if (await yearRows().count() > rowsBefore) {
    const newest = (await yearRows().first().locator('.price-money').innerText()).trim();
    if (!newest.includes('612')) {
      bad('the price in force is the one just saved',
        `the top of the year's series says ${newest} — the newest row is the one a student `
        + 'is quoted, and this one is not it');
    } else {
      good('the price in force is the one just saved');
    }

    /* THE WHOLE OF K-14 IN ONE ASSERTION. What was there before has to still be
       there — a March invoice has to stay explicable in November, and a screen
       showing only the newest number would be the mutable column with extra
       steps. */
    if (wasShown) {
      const all = (await yearRows().locator('.price-money').allInnerTexts())
        .map((t) => t.trim());
      if (!all.includes(wasShown)) {
        bad('the price that was replaced is still in the series',
          `the year's series holds ${JSON.stringify(all)} and the price that was in force `
          + `before this run — ${wasShown} — is not among them`);
      } else {
        good('the price that was replaced is still in the series');
      }
    } else {
      /* THE FIXTURE SEEDS ONE, so this branch is a platform that has never had a
         price. It is said rather than passed silently: the strongest of the
         three assertions could not be made, and a run that reported three
         successes would be claiming otherwise. */
      console.log('· nothing was priced before this run, so nothing could be '
        + 'checked about the one it replaced');
    }

    /* AND THE OTHER TERMS DID NOT MOVE, which is the assertion the old shape
       could not make: there was one price, so there was nothing for a save to
       spill into. Now three products share a table, and a `Set` that ignored
       the term would raise all of them at once. */
    /* IT COUNTS THE OTHER TERMS AND NOT THE WHOLE LIST, which is the difference
       between this assertion and the one that used to stand here.

       Counting every row carrying the amount contradicts the assertion three
       lines up. That one requires the year's series to GROW — append, never
       edit, which is the whole of K-14 — so the second save into the same
       database leaves two rows carrying 612, both of them the year's, both of
       them correct, and the count said the price had spilled.

       It only ever passed because CI builds a fresh schema per run, so this
       suite had never been run twice against one database. That is the same
       shape as the four isolation bugs in #190 and the race in #198: a test
       that is correct exactly once is indistinguishable from a correct test
       until somebody runs it twice.

       What "spilled" means is a row for ANOTHER term carrying the year's
       amount, so that is what is counted, and one is already too many. */
    const spilled = await rows
      .filter({ hasText: '612' })
      .filter({ hasNotText: 'A year' })
      .count();
    if (spilled > 0) {
      bad('pricing one term leaves the others alone',
        `${spilled} row(s) outside the year carry the amount that was saved for the year alone`);
    } else {
      good('pricing one term leaves the others alone');
    }
  }

  await done(staff);
} finally {
  await browser.close();
}

if (failures > 0) {
  console.error(`\n${failures} round trip(s) did not complete.`);
  console.error('These are the failures where every part works and the whole does not —');
  console.error('the server has a test, the screen has been measured, and nothing had');
  console.error('ever pressed the button that joins them.');
  process.exit(1);
}

console.log('\nthe console writes what it says it writes');
