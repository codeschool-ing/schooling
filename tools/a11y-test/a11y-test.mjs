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

   # AND THE CONSOLE, WHICH IS A SECOND HOST

   `console.<platform domain>` is served by the same binary and is not a
   school's address (K-17), so nothing in the list above ever reached it. The
   console shipped with its markup written FOR this check — labels tied to
   inputs, a live region for the answer, a focus outline of its own — and
   markup written for a check nobody runs is a claim, which is the failure this
   whole file exists to refuse.

   It costs a staff account, and there is no way to make one from a browser
   alone: the first role cannot be granted by the console, because reaching the
   console needs one. So this shells out to `cmd/staff`, which is the door that
   exists for exactly that reason and writes to the audit like every other
   administrative path. It also needs a second factor, which is thirty lines of
   RFC 6238 below rather than a dependency — the same argument `internal/
   identity/totp.go` makes, and it is checked by the server refusing a wrong
   code.

       node tools/a11y-test/a11y-test.mjs [base url]

   The console's address is derived from the school's rather than passed: it is
   the platform domain with `console.` in front, which is what `console.HostOf`
   does in Go. Two ways to say one address is two ways to disagree about it.
   ========================================================================== */

import { execFileSync } from 'node:child_process';
import { createHmac } from 'node:crypto';
import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

const CONSOLE = (() => {
  const at = new URL(BASE);
  at.hostname = 'console.' + at.hostname.split('.').slice(1).join('.');
  return at.origin;
})();

/* WCAG 2.2 AA, which is the sum of what came before it. The tags are what axe
   understands; naming them all is how "AA" stops being a word and becomes a
   list of rules that either run or do not. */
const STANDARD = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'];

/* See the header: Playwright finds its own browser and must not be told where
   to look. */
const launch = {
  args: [`--host-resolver-rules=MAP ${new URL(BASE).hostname} 127.0.0.1,`
       + `MAP ${new URL(CONSOLE).hostname} 127.0.0.1`],
};
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

/* ---------- the second factor, RFC 6238 ----------

   Base32 without padding, HMAC-SHA1, six digits, thirty seconds — the same
   parameters `internal/identity/totp.go` writes out, and for the same reason:
   it is a HMAC and a truncation, and a wrong one is not a subtle failure here
   because the server answers `wrong_code` and this run stops. */
function totp(secret, at = Date.now()) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const ch of secret.toUpperCase().replace(/[\s=]/g, '')) {
    const v = alphabet.indexOf(ch);
    if (v < 0) throw new Error(`the secret is not base32: ${ch}`);
    bits += v.toString(2).padStart(5, '0');
  }
  const key = Buffer.from(
    (bits.match(/.{8}/g) || []).map((b) => parseInt(b, 2)));

  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 1000 / 30)));

  const mac = createHmac('sha1', key).update(counter).digest();
  const offset = mac[mac.length - 1] & 0x0f;
  const truncated = mac.readUInt32BE(offset) & 0x7fffffff;
  return String(truncated % 1_000_000).padStart(6, '0');
}

/* ---------- an operator, made the only way there is ----------

   Sign up, then `cmd/staff` for the role, then enrol a factor — which the API
   marks on the enrolling session, so no code has to be presented a second time.

   THE ORDER IS NOT INTERCHANGEABLE. `identity.RequireStaff` asks for a live
   role AND a factor already shown, so a console opened between the sign-up and
   the enrolment is a console showing its own door — which is a screen this
   suite checks on purpose, elsewhere, with a context that never signed in.

   # THE SIGN-UP IS A REQUEST AND NOT A FORM, and that is the second attempt

   The first drove the school's sign-up screen — toggle to register, fill three
   fields, submit, wait a beat. It worked here every time and failed on the
   first CI run, with no `POST /api/v1/sign-up` in the server's log at all: the
   fields go in while the screen is still swapping modes, and on a slower
   machine the render lands after them and takes them with it. A blind
   `waitForTimeout` then hides it, because what follows is a role grant for an
   account that was never created.

   THAT FORM IS NOT THIS SUITE'S SUBJECT. The student block above already drives
   it through the interface, in both themes, and axe measures the screen. What
   this needs is a session, so it asks for one the way the page would — same
   origin, same cookie, no timing to lose. */
async function operator(theme, label) {
  const page = await open(theme, 'en');
  const email = `a11y-staff-${Date.now()}-${theme}@example.tld`;

  await page.goto(`${BASE}/`, { waitUntil: 'load' });
  const failed = await page.evaluate(async ([name, address]) => {
    const r = await fetch('/api/v1/sign-up', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email: address, password: 'a long enough password here' }),
    });
    return r.ok ? '' : `${r.status} ${await r.text()}`;
  }, [label, email]);
  if (failed) throw new Error(`signing the operator up: ${failed}`);

  execFileSync('go', ['run', './cmd/staff', 'grant', email, 'operator',
    '--by', 'the accessibility suite'], { stdio: 'pipe' });

  const secret = await page.evaluate(async () => {
    const r = await fetch('/api/v1/second-factor/start', { method: 'POST' });
    if (!r.ok) throw new Error(`starting the second factor: ${r.status}`);
    return (await r.json()).secret;
  });

  const enrolled = await page.evaluate(async ([s, c]) => {
    const r = await fetch('/api/v1/second-factor/enrol', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ secret: s, code: c }),
    });
    return r.ok ? '' : `${r.status} ${await r.text()}`;
  }, [secret, totp(secret)]);

  if (enrolled) throw new Error(`enrolling the second factor: ${enrolled}`);
  return { page, email };
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
async function check(page, name, where, expect,
  { settled, act, base = BASE, region = '#content' } = {}) {
  await page.goto(base + where, { waitUntil: 'load' });
  /* The screens are built by script after the document loads, so waiting for
     the document would be checking an empty page and calling it clean. */
  await page.waitForSelector(`${region} h1, ${region} .notice`, { timeout: 8000 }).catch(() => {});
  await page.waitForTimeout(400);

  const drew = await page.locator(region).getAttribute('data-screen');
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

  /* SOME STATES ONLY EXIST AFTER SOMEBODY DOES SOMETHING — a verdict beside an
     answered question, a form that has been submitted. `act` is how a caller
     reaches one, and it runs HERE so that everything below is identical: the
     same axe, the same tags, the same report. An acted state checked by its own
     copy of this function is a state whose failures are described differently
     from every other, which is exactly what happened the first time. */
  if (act) {
    try {
      await act(page);
    } catch (e) {
      violations += 1;
      console.error(`✗ ${name} — could not reach the state to measure: ${e.message}`);
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
    const studentEmail = `a11y-${Date.now()}-${theme}@example.tld`;
    await student.goto(`${BASE}/#/sign-in`, { waitUntil: 'load' });
    await student.waitForSelector('#e-toggle', { timeout: 8000 });
    await student.click('#e-toggle');
    await student.waitForSelector('#e-name', { timeout: 8000 });
    await student.fill('#e-name', 'Ada Lovelace');
    await student.fill('#e-email', studentEmail);
    await student.fill('#e-password', 'a long enough password here');

    /* THE SUBMIT IS WAITED FOR, NOT SLEPT THROUGH.

       This was `click` and a 1500ms pause, and the pause is what makes the
       failure silent: the fields are `required`, so a form that did not take
       them is blocked by the browser and never sends anything — and then every
       screen below is measured signed OUT, under a name that says signed in.
       The dashboard exists either way, so `expect` does not catch it.

       Waiting for the response is the only thing here that can tell the two
       apart, and it is also faster than the pause it replaces. */
    const [signedUp] = await Promise.all([
      student.waitForResponse((r) => r.url().endsWith('/api/v1/sign-up'), { timeout: 15000 }),
      student.click('#form-signin button[type=submit]'),
    ]);
    if (!signedUp.ok()) {
      throw new Error(`signing the student up: ${signedUp.status()} ${await signedUp.text()}`);
    }
    await student.waitForTimeout(400);

    await check(student, `${theme} · the dashboard`, '/#/dashboard', '/dashboard');
    await check(student, `${theme} · certificates`, '/#/certificates', '/certificates');

    /* MY ACCOUNT, WHICH THE MENU LINKED TO BEFORE IT EXISTED. Two screens in
       one: the account as it sits, and the enrolment the second factor needs —
       a secret to read off the screen and a code to type back. The second is
       reached by pressing the button, because a state nobody can reach from the
       first is a state this suite would be measuring on its own. */
    await check(student, `${theme} · my account`, '/#/account', '/account');
    await check(student, `${theme} · setting up a second factor`, '/#/account', '/account', {
      async act(page) {
        await page.locator('#start').click();
        await page.waitForSelector('#secret', { timeout: 8000 });
      },
    });
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
    await check(student, `${theme} · the drill`, '/#/practice', '/practice', { settled: '.ex' });

    /* AND THE DRILL WITH A VERDICT ON IT, which is a different screen and the
       one this feature is actually about: a live region that has just been
       written into, controls that have gone disabled, the answer revealed over
       what the student gave, and focus moved to "next". None of that exists on
       the screen above, and an exam never reaches this state at all — it holds
       every verdict until the paper closes. */
    await check(student, `${theme} · a drilled answer`, '/#/practice', '/practice', {
      settled: '.ex',
      async act(page) {
        const choices = page.locator('.choice');
        if (await choices.count()) await choices.first().click();
        await page.locator('.ex-answer').click();
        await page.waitForSelector('.ex-verdict.v-right, .ex-verdict.v-wrong', { timeout: 8000 });
      },
    });

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

    /* ---------- the console, on its own host ----------

       THE SHUT DOOR FIRST, with a context that has never signed in — because
       that is what a stranger who follows a link to this address sees, and
       because the console is deliberately served to them rather than hidden
       behind the gate that protects its API. A page nobody can open is also a
       page that cannot say what is needed to open it. */
    const stranger = await open(theme, 'en');
    await check(stranger, `${theme} · console, the door shut`, '/', 'shut',
      { base: CONSOLE, region: '#stage' });
    await done(stranger);

    const staff = await operator(theme, 'Grace Hopper');

    await check(staff.page, `${theme} · console, personal data`, '/#/people', '/people',
      { base: CONSOLE, region: '#stage' });

    /* AND THE SCREEN WITH SOMEBODY ON IT, which is the one this section is
       about: a table of counts, a link that hands over everything held, and a
       destructive block with a confirmation field. None of that exists on the
       screen above — an empty lookup form passes checks the answer would
       fail. */
    await check(staff.page, `${theme} · console, a person found`, '/#/people', '/people', {
      base: CONSOLE,
      region: '#stage',
      async act(page) {
        await page.fill('#email', studentEmail);
        await page.click('#find button[type=submit]');
        await page.waitForSelector('#answer .block-top h2', { timeout: 8000 });
      },
    });

    /* THE HISTORY, WHICH BY NOW HAS SOMETHING IN IT: granting this operator its
       role wrote an entry, so the list is never the empty state here. The empty
       state is a paragraph and would pass every check there is, which is why
       this is worth saying. */
    await check(staff.page, `${theme} · console, history`, '/#/audit', '/audit', {
      base: CONSOLE,
      region: '#stage',
      settled: '#rows table',
    });

    /* AND ONE ENTRY, REACHED THE WAY A PERSON REACHES IT — by following a row
       rather than by an address this file made up. An id typed in here would go
       stale the first time the fixture changed, and a screen behind a stale
       address is a screen nobody measures. */
    const entry = await staff.page.locator('#rows tbody tr td a').first().getAttribute('href');
    await check(staff.page, `${theme} · console, one entry`, '/' + entry, '/audit/entry/:id', {
      base: CONSOLE,
      region: '#stage',
      settled: '.states',
    });

    /* AND THE SAME LIST NARROWED TO ONE ACTOR, because a filtered list is a
       different screen: it carries a heading that says so and a way back. */
    const byActor = await staff.page.locator('#stage a[href^="#/audit/by/"]').first()
      .getAttribute('href');
    await check(staff.page, `${theme} · console, one actor's doing`, '/' + byActor,
      '/audit/by/:actor', { base: CONSOLE, region: '#stage', settled: '#rows table' });

    await check(staff.page, `${theme} · console, nothing there`, '/#/nowhere-at-all', 'not-found',
      { base: CONSOLE, region: '#stage' });

    await done(staff.page);
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
