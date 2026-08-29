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

   # THE WRITES IT PERFORMS

   Every one is chosen because a Go test cannot see it and axe cannot either:
   they are about what happens to the SCREEN, or to another screen, after the
   server has answered.

     SETTLING A REPORT   a student says a section is wrong, an operator answers
                         it, and the queue must lose the card. A screen that
                         wrote the decision and left the row standing is a queue
                         two people work twice.

     SAVING A PRICE      the whole of K-14 is that the old price is still there,
                         and that pricing the year leaves the other terms alone.
                         A screen showing only the newest number would be the
                         mutable column again with extra steps, and it would
                         look correct.

     THE SUPPORT ADDRESS the terms promise seven days to withdraw and this is
                         the address that promise names. What is checked is that
                         it survives the round trip AND that the block says the
                         row is answering rather than the deployment's variable
                         — two states that look identical if all you show is the
                         address, and only one of them is this console's.

     A PARAMETER         the registry `0046` built, used: move the instalment
                         ceiling on the console and ask the SCHOOL's own host
                         what it now tells a buyer. This is the only assertion
                         here that crosses hosts, and it is the whole claim the
                         registry makes — a number that moved in the table and
                         not in the answer is a screen that lies.

     A LEDGER LINE       the escape hatch, written by hand and read back out of
                         the table below it without a reload.

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

  /* ---------- and what comes off for a Pix ----------

     THE CLAIM IS THAT THE NUMBER REACHES THE PRICE A STUDENT IS QUOTED, which
     is what makes this worth a browser rather than a Go test. The rate was a
     constant compiled into `billing/http.go` until `0045`; now the console
     appends to a series, the checkout reads it, and the school route quotes it
     — three readers of one row, and a suite that only checked the form would
     prove that a screen accepts typing.

     So it saves a rate and then asks the STUDENT's side what a Pix costs. */
  const rate = 12;
  await staff.locator('#discount .discount-form input').fill(String(rate));
  await staff.locator('#discount .discount-form button[type=submit]').click();

  try {
    await staff.locator('#discount .price-state', { hasText: `${rate}% off` })
      .waitFor({ timeout: 15000 });
    good('a new Pix rate is saved and read back');
  } catch (e) {
    const said = await staff.locator('#discount .price-state').innerText().catch(() => '—');
    bad('a new Pix rate is saved and read back',
      `after saving ${rate}% the block says "${said.trim()}"`);
  }

  /* AND THE SCHOOL QUOTES IT, which is the reader furthest from the write. It
     is the number the invitation strikes a price through with, so a rate that
     reached the table and not this answer would be a screen quoting one figure
     while the checkout charged another — the exact drift the constant was
     handed in to prevent. */
  /* A PAGE OF ITS OWN, ON THE SCHOOL'S HOST. The student above was closed
     before the operator signed in, and the console's origin is not a school's —
     `/api/v1/school` answers 404 there, which is `K-17` working rather than a
     problem. Asking has to happen where a student would ask. */
  const asking = await open();
  await asking.goto(`${BASE}/#/dashboard`, { waitUntil: 'load' });
  const quoted = await asking.evaluate(async () => {
    const answer = await fetch('/api/v1/school', { credentials: 'same-origin' });
    return (await answer.json()).pixDiscount;
  });
  await done(asking);
  if (quoted !== rate * 100) {
    bad('the school quotes the rate that was just set',
      `the school route says ${quoted} basis points and the console set ${rate * 100} — `
      + 'the screen would strike a price through with one figure while the checkout took '
      + 'off another');
  } else {
    good('the school quotes the rate that was just set');
  }

  /* ---------- and where a student writes to give it back ----------

     ON THE SAME SCREEN AND IN THE SAME RUN, because it is the same offer: the
     terms promise seven days to withdraw and this is the address that promise
     names. It was an environment variable until `0044`, which meant it could
     only be changed by an apply from the one machine holding a gitignored
     file — and an apply from anywhere else planned it back to empty and took
     the address off the account screen with nothing failing.

     WHAT THIS PROVES THAT THE GO TESTS CANNOT. The handler's tests use a fake
     store, and the store's tests use no handler; what neither presses is the
     button. This is the round trip — type an address, save, and read it back
     off a block that re-fetched it from the server. */
  const address = `seven-days-${Date.now()}@example.tld`;

  await staff.locator('#contact .contact-form').waitFor({ timeout: 15000 });
  await staff.locator('#contact [name=email]').fill(address);
  await staff.locator('#contact [name=reason]').fill('the console suite, proving the round trip');
  await staff.locator('#contact button[type=submit]').click();

  /* THE SENTENCE AND NOT THE FIELD. The field would still hold what was typed
     into it even if nothing had been saved — it is the paragraph above it that
     is rebuilt from a fresh read, so that is what is waited on. */
  try {
    await staff.locator('#contact .price-state', { hasText: address })
      .waitFor({ timeout: 15000 });
    good('the address students are told to write to is saved and read back');
  } catch (e) {
    const said = await staff.locator('#contact .price-state').innerText().catch(() => '—');
    bad('the address students are told to write to is saved and read back',
      `after saving ${address} the block still says "${said.trim()}" — the value did not `
      + 'survive the round trip through the server');
  }

  /* AND IT SAYS THE ROW IS ANSWERING, which is the distinction the block exists
     to draw: an address coming from the deployment's own variable and one
     somebody typed here look identical if all the screen shows is the address,
     and only one of the two can be changed from this console. */
  const saying = (await staff.locator('#contact .price-state').innerText()).trim();
  if (!saying.includes('set here')) {
    bad("the screen says the address is the console's and not the deployment's",
      `the block says "${saying}" — after a save it has to be the row talking, or an `
      + 'operator cannot tell whether this screen is what decides it');
  } else {
    good("the screen says the address is the console's and not the deployment's");
  }

  /* AND A CHANGE WITH NO REASON IS REFUSED, on the screen and not only in the
     handler. It is the one field the price form does not have, and it is here
     because the log has to be able to tell an address that moved because the
     person answering changed from one that moved because the last was a typo —
     only the second means what was published in between was wrong. */
  await staff.locator('#contact [name=email]').fill(`unsaid-${Date.now()}@example.tld`);
  await staff.locator('#contact [name=reason]').fill('');
  await staff.locator('#contact button[type=submit]').click();

  const refusal = (await staff.locator('#contact .signin-notice')
    .innerText().catch(() => '')).trim();
  const stillSaying = (await staff.locator('#contact .price-state').innerText()).trim();
  if (!refusal || !stillSaying.includes(address)) {
    bad('an address with no reason is refused',
      `the form said "${refusal || 'nothing'}" and the block now says "${stillSaying}" — a `
      + 'change with no reason has to be refused and leave the published address alone');
  } else {
    good('an address with no reason is refused');
  }

  /* ---------- a knob, moved, and the storefront on the new number ----------

     THIS IS THE ROUND TRIP THE WHOLE REGISTRY IS FOR. `0046` moved K-13's fence
     from "a knob costs a table" to "a knob costs a declaration and an argument",
     and the claim that buys is that a number the platform behaves by can be
     changed without a deployment. Nothing in Go can press that: the handler's
     tests use a fake store, the store's tests use no handler, and neither of
     them asks the SCHOOL API what it is now telling a buyer.

     So the assertion is end to end and deliberately crosses hosts — set the
     instalment ceiling on the console, then ask the storefront on the school's
     own host what it says a card sale splits into. A value that moved in the
     table and not in the answer is a screen that lies, which is the exact
     failure a parameter surface is worth nothing without. */

  await go(staff, 'settings', 'settings');

  const knob = staff.locator('.block[data-name="billing.instalments"]');
  await knob.waitFor({ timeout: 15000 });

  /* A COUNT NO FIXTURE USES, and not the one it is already on. Saving the value
     that is already there is a legitimate act — it records that this is still
     what we ask — but it would make "the answer changed" true without anything
     having moved. */
  const wasSet = (await knob.locator('[name=value]').inputValue()).trim();
  const want = wasSet === '7' ? '6' : '7';

  await knob.locator('[name=value]').fill(want);
  await knob.locator('[name=reason]').fill('the console suite, proving the round trip');
  await knob.locator('button[type=submit]').click();

  /* THE SENTENCE AND NOT THE FIELD, for the reason the address block gives: the
     field holds what was typed into it whether or not anything was saved, and
     the paragraph above it is rebuilt from a fresh read of the server. */
  try {
    await knob.locator('.price-state', { hasText: `Set to ${want}` })
      .waitFor({ timeout: 15000 });
    good('a parameter is saved and read back');
  } catch (e) {
    const said = await knob.locator('.price-state').innerText().catch(() => '—');
    bad('a parameter is saved and read back',
      `after saving ${want} the block still says "${said.trim()}" — the value did not `
      + 'survive the round trip through the server');
  }

  /* AND THE STOREFRONT IS ON THE NEW NUMBER. A fresh page on the SCHOOL's host,
     because the console's origin does not serve the school API — and because
     the student page opened at the top of this run is long closed.

     IT NAVIGATES TO THE ROUTE RATHER THAN FETCHING IT. A blank page has no
     origin, so a `fetch` from one is cross-origin to everything and fails
     before it is sent; loading the storefront first would boot the whole
     interface to ask it one question. Going straight at the JSON is one
     request and the same answer a buyer's browser gets. */
  const shop = await open();
  try {
    await shop.goto(`${BASE}/api/v1/school`, { waitUntil: 'load' });
    const says = JSON.parse(await shop.locator('body').innerText()).instalments;

    if (says !== Number(want)) {
      bad('the storefront is on the number the console set',
        `the console saved ${want} and the school API says ${says} — a parameter that moved `
        + 'in the table and not in the answer is a screen that lies about what it decides');
    } else {
      good('the storefront is on the number the console set');
    }
  } finally {
    await done(shop);
  }

  /* AND A CHANGE WITH NO REASON IS REFUSED, on the screen. Same field and same
     argument as the address above: a parameter is REPLACED rather than
     appended, so the audit is the whole history of what this platform was set
     to, and an entry with no sentence is a number that changed for reasons
     nobody wrote down. */
  await knob.locator('[name=value]').fill(want === '7' ? '8' : '9');
  await knob.locator('[name=reason]').fill('');
  await knob.locator('button[type=submit]').click();

  const unsaid = (await knob.locator('.signin-notice').innerText().catch(() => '')).trim();
  const stillSet = (await knob.locator('.price-state').innerText()).trim();
  if (!unsaid || !stillSet.includes(`Set to ${want}`)) {
    bad('a parameter with no reason is refused',
      `the form said "${unsaid || 'nothing'}" and the block now says "${stillSet}" — a `
      + 'change with no reason has to be refused and leave the value alone');
  } else {
    good('a parameter with no reason is refused');
  }

  /* AND THE FENCE IS THE DECLARATION'S, not the screen's opinion. `Most` is
     twelve because that is where the gateway's card bands stop; a console that
     accepted thirteen would be selling a split it cannot charge. The form
     refuses first so nothing is recorded — the server refuses too, and has a
     test. */
  await knob.locator('[name=value]').fill('40');
  await knob.locator('[name=reason]').fill('the console suite, past the fence on purpose');
  await knob.locator('button[type=submit]').click();

  const fenced = (await knob.locator('.signin-notice').innerText().catch(() => '')).trim();
  const unmoved = (await knob.locator('.price-state').innerText()).trim();
  if (!fenced || !unmoved.includes(`Set to ${want}`)) {
    bad('a value past the declaration\'s bound is refused',
      `the form said "${fenced || 'nothing'}" and the block now says "${unmoved}" — the `
      + 'bounds are part of what declares a parameter and cannot be moved from a screen');
  } else {
    good('a value past the declaration\'s bound is refused');
  }

  /* ---------- a line written by hand, and read back ----------

     THIS IS THE ONE WRITE IN THIS CONSOLE WHOSE RESULT NOBODY COULD SEE. The
     adjustment is the escape hatch — one line for money that moved outside the
     gateway — and until the books got a table it wrote into an append-only
     table and showed nothing afterwards. An operator had no way of checking
     they had put the sign the right way round, and no way of noticing they had
     already made the same correction last week.

     So the round trip is the claim: type it on the record screen, and find it
     in the table below without reloading the page. Neither half proves the
     other — the handler's tests use a fake store, the store's tests use no
     handler, and what neither presses is the button. */
  await go(staff, 'record', 'record');
  await staff.locator('#email').fill(`console-${stamp}@example.tld`);
  await staff.locator('#find button[type=submit]').click();
  await staff.waitForSelector('#stage[data-screen="/record/:id"]', { timeout: 15000 });

  /* THE BOOKS ARE EMPTY FIRST, and saying so is half the check: a table that
     was already full would let "the row is there" pass without the write. */
  await staff.locator('#ledger .none, #ledger .grid').first().waitFor({ timeout: 15000 });
  const booksBefore = (await staff.locator('#ledger').innerText()).trim();

  const memo = `console suite ${stamp}`;
  await staff.locator('.sub-change summary').click();
  const adjust = staff.locator('.sub-form[data-do=adjust]');
  await adjust.locator('[name=amount]').fill('12,34');
  await adjust.locator('[name=currency]').fill('BRL');
  await adjust.locator('[name=why]').fill(memo);
  await adjust.locator('button[type=submit]').click();

  try {
    await staff.locator('#ledger', { hasText: memo }).waitFor({ timeout: 15000 });
    good('a line written by hand appears in the books');
  } catch (e) {
    bad('a line written by hand appears in the books',
      `after writing an adjustment the books say "${(await staff.locator('#ledger')
        .innerText().catch(() => '—')).trim().slice(0, 200)}" — the memo is what identifies `
      + 'the line, and a write nobody can read back is a write nobody can review');
  }

  /* AND THE TABLE WAS NOT ALREADY SHOWING IT, which is what makes the line
     above about the write rather than about the fixture. */
  if (booksBefore.includes(memo)) {
    bad('the books were empty of this line before it was written',
      'the memo carries this run\'s stamp and the table already held it, so the check '
      + 'above would pass without anything having been written');
  } else {
    good('the books were empty of this line before it was written');
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
