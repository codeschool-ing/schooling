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

import { signUpThroughTheForm } from '../lib/sign-up.mjs';

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

/* A student, signed up through the form.

   THE SHARED ONE, because the second-factor suite needs the same thing and the
   fix that made it reliable would otherwise have landed in one of the two. See
   `tools/lib/sign-up.mjs` for what went wrong and why it is checked rather than
   timed.

   It is still the form and not a request: a suite that posted to the API would
   prove the API works and say nothing about the screen a person uses. */
async function signUp(page, name, address) {
  await signUpThroughTheForm(page, BASE, { name, email: address });
}

/* Closing the page is not closing the context it came from, and a context left
   open holds a browser process. */
async function done(page) {
  await page.close();
  await page.owner.close();
}

/* ---------- the drill, answered on purpose ----------

   THIS SUITE READS THE ANSWER KEY, AND THAT IS THE FIX RATHER THAN A CHEAT.

   The drill draws a card, shuffles it, and sends no key with it — so a check
   that answers by clicking something gets a verdict it did not choose. Both
   verdicts are the accent's colour on a tinted background, only one of them
   failed, and so this reported a contrast defect about one run in three and a
   clean pass the rest of the time. A check that reaches a screen by luck is
   worse than one that does not reach it: it looks like coverage.

   The key comes back WITH the verdict — that is the design, so the browser can
   show what the right answer was — which means one throwaway account can learn
   it by answering once and reading the reply. After that every verdict is
   arranged and the arrangement is confirmed against what the server said.

   IT IS KEPT AS TEXT AND NOT AS A POSITION. The server shuffles each card as it
   hands it out, so `expected` is an index into THIS draw; the same index on the
   next account is a different answer. The text is the same card either way.

   AND IT IS ARRANGED THROUGH THE INTERFACE — the ordering card is put in order
   with the ↑ buttons, which is the route a student without a mouse takes. A
   suite that posted the answer itself would be measuring a screen no student
   can reach. */

// Learnt once, by exercise id, because the queue holds more than one card and
// which one comes up first is the server's business rather than this file's.
let theKey = null;

/* One card, answered, with what the server said about it. The reply carries the
   verdict before the screen does, and this waits for the screen anyway: what is
   measured afterwards is the state a person is looking at. */
async function answerCard(page, arrange) {
  if (arrange) await arrange(page);

  /* IF THE ANSWER NEVER LEAVES THE PAGE, SAY WHAT THE PAGE LOOKED LIKE.
     CI failed here once with nothing but "waitForResponse: Timeout", which
     names the symptom and none of the three things that produce it: a card the
     interface considered empty, an answer button already spent, or a script
     that threw on the way to the request. All three are visible in the document
     at the moment it happens, and none of them are visible ten minutes later in
     a log. So the timeout is caught and the screen is described. */
  const reply = await Promise.all([
    page.waitForResponse((r) => r.url().includes('/answered'), { timeout: 15000 }),
    page.locator('.ex-answer').click(),
  ]).then(([r]) => r).catch(async (e) => {
    const seen = await page.evaluate(() => {
      const card = document.querySelector('.ex');
      const verdict = document.querySelector('.ex-verdict');
      const button = document.querySelector('.ex-answer');
      return {
        card: card ? card.className : 'no card on the screen',
        verdict: verdict ? `${verdict.className} — ${verdict.textContent.trim().slice(0, 80)}` : 'none',
        button: button ? (button.disabled ? 'disabled' : 'enabled') : 'no answer button',
        items: document.querySelectorAll('.ord-item').length,
        chosen: document.querySelectorAll('.choice input:checked').length,
      };
    }).catch(() => null);
    throw new Error(`${e.message}\n        the card was "${seen?.card}", the button was `
      + `${seen?.button}, the verdict said [${seen?.verdict}], and the answer on screen was `
      + `${seen?.items} ordered items / ${seen?.chosen} chosen options`
      + (thrown.length ? `\n        the page threw: ${thrown.join(' | ')}` : ''));
  });
  if (!reply.ok()) throw new Error(`answering a card: ${reply.status()} ${await reply.text()}`);

  const said = await reply.json();
  const id = decodeURIComponent(new URL(reply.url()).pathname.split('/').at(-2));
  const shown = await page.waitForSelector('.ex-verdict.v-right, .ex-verdict.v-wrong',
    { timeout: 8000 });
  const state = (await shown.getAttribute('class')).includes('v-right') ? 'v-right' : 'v-wrong';
  return { id, state, expected: said.expected };
}

/* The key of the card on the screen, as text. */
async function keyOf(page, expected) {
  if (await page.locator('.ord-item').count()) {
    // An ordering key already IS the items, in the order they belong in.
    return { kind: 'ordering', right: expected };
  }
  const wanted = Array.isArray(expected) ? expected : [expected];
  const right = [];
  for (const ix of wanted) {
    right.push((await page.locator(`.choice[data-ix="${ix}"] .choice-text`).innerText()).trim());
  }
  return { kind: 'choice', right };
}

/* Selection sort through the two arrows, which is what a keyboard does. Four
   items, so nothing cleverer is worth writing — and the last line is the check
   that this worked, because an ordering left half sorted answers wrong and
   would read as the server disagreeing. */
async function putInOrder(page, right) {
  const order = () => page.$$eval('.ord-item', (li) => li.map((e) => decodeURIComponent(e.dataset.item)));

  for (let slot = 0; slot < right.length; slot += 1) {
    const here = (await order()).indexOf(right[slot]);
    if (here < 0) throw new Error(`this card does not carry "${right[slot]}"`);
    for (let up = here; up > slot; up -= 1) {
      await page.locator('.ord-item').nth(up).locator('.ord-arrow[data-direction="-1"]').click();
    }
  }

  const finished = await order();
  if (finished.join(' ') !== right.join(' ')) {
    throw new Error(`the list ended as ${JSON.stringify(finished)} and the key is `
      + `${JSON.stringify(right)}`);
  }
}

/* Arrange the card on the screen so that answering it produces `want`. */
async function arrangeToBe(page, key, want) {
  if (key.kind === 'ordering') {
    await putInOrder(page, key.right);
    if (want === 'v-wrong') {
      /* ONE SWAP AWAY FROM RIGHT IS WRONG, and it is wrong without this file
         having to know anything else about the card. */
      const last = (await page.locator('.ord-item').count()) - 1;
      await page.locator('.ord-item').nth(last).locator('.ord-arrow[data-direction="-1"]').click();
    }
    return;
  }

  const texts = (await page.locator('.choice .choice-text').allInnerTexts()).map((t) => t.trim());
  const pick = texts
    .map((text, ix) => ({ text, ix }))
    .filter(({ text }) => key.right.includes(text) === (want === 'v-right'));
  if (!pick.length) throw new Error(`no choice on this card can be ${want}`);

  // Every right one, because a multiple-choice answer missing one is wrong;
  // and exactly one wrong one, because that is enough to be wrong.
  for (const { ix } of want === 'v-right' ? pick : pick.slice(0, 1)) {
    await page.locator('.choice').nth(ix).click();
  }
}

/* The queue, answered as drawn on an account that exists for this. Nothing is
   measured here, so answering by luck is fine — what is kept is the reply. */
async function learnTheDrill() {
  const page = await open('dark', 'en');
  await signUp(page, 'Ada Lovelace', `a11y-key-${Date.now()}@example.tld`);
  await page.goto(`${BASE}/#/practice`, { waitUntil: 'load' });

  const learnt = new Map();
  for (;;) {
    const there = await page.waitForSelector('.ex, .drill-done', { timeout: 8000 }).catch(() => null);
    if (!there || await page.locator('.drill-done').count()) break;
    await page.waitForTimeout(300);

    /* SOMETHING HAS TO BE ANSWERED, and it does not matter what. A card with
       nothing chosen is refused before it is sent — "answer before checking" —
       and then there is no reply to learn from. An ordering card always has an
       answer, because the order it was drawn in is one. */
    const seen = await answerCard(page, async (p) => {
      const choices = p.locator('.choice');
      if (await choices.count()) await choices.first().click();
    });
    learnt.set(seen.id, await keyOf(page, seen.expected));

    await page.locator('.drill-next').click();
  }
  await done(page);

  if (!learnt.size) {
    throw new Error('the drill queue was empty, so neither verdict can be reached and '
      + 'the screen this section is about is not being measured at all');
  }
  return learnt;
}

// What the page threw while a card was being answered. A script that fails on
// the way to a request produces no request and no verdict, which from the
// outside looks exactly like a card nobody answered — see `answerCard`.
let thrown = [];

/* A fresh account per verdict, and the FIRST card of its queue — which is the
   one the key was learnt for, whichever of them the server puts first. Asking
   the same student twice would be answering a card that has already moved the
   schedule, and answering it a second time is what a drill does not allow. */
async function drilled(theme, want) {
  const page = await open(theme, 'en');
  thrown = [];
  page.on('pageerror', (e) => thrown.push(e.message));
  page.on('console', (m) => { if (m.type() === 'error') thrown.push(m.text()); });
  try {
    await signUp(page, 'Ada Lovelace', `a11y-drill-${Date.now()}-${theme}@example.tld`);
    const [drawn] = await Promise.all([
      page.waitForResponse((r) => r.url().includes('/draw'), { timeout: 15000 }),
      page.goto(`${BASE}/#/practice`, { waitUntil: 'load' }),
    ]);
    await page.waitForSelector('.ex', { timeout: 8000 });
    await page.waitForTimeout(300);

    const card = (await drawn.json()).exercise;
    const key = theKey.get(card);
    if (!key) throw new Error(`nothing was learnt about the card "${card}"`);

    const seen = await answerCard(page, (p) => arrangeToBe(p, key, want));
    if (seen.state !== want) {
      throw new Error(`the card was arranged to be ${want} and the server called it ${seen.state}`);
    }
    return page;
  } catch (e) {
    await done(page);
    throw e;
  }
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
/* axe on whatever is on the screen right now, reported the one way.
   `check` reaches a screen by its address; the drill and the exam paper reach
   theirs by working the interface. What they must not do is describe the same
   failure differently, so all three end here. */
async function measure(page, name) {
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

  await measure(page, name);
}

try {
  /* Before anything is measured, on an account that exists to be spent. Both
     themes ask for both verdicts and the key is the same card either way, so
     this is once rather than per theme. */
  theKey = await learnTheDrill();

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
    await signUp(student, 'Ada Lovelace', studentEmail);

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
/* AND BOTH VERDICTS, EACH ASKED FOR BY NAME. Which one comes up is not left
       to the shuffle any more — see the drill block above — so being unable to
       reach one is a FAILURE here rather than a state nobody noticed was
       missing. */
    for (const want of ['v-right', 'v-wrong']) {
      let answered = null;
      try {
        answered = await drilled(theme, want);
      } catch (e) {
        violations += 1;
        console.error(`✗ ${theme} · a drilled answer (${want}) — this state could not be `
          + `reached, so it is not being measured: ${e.message}`);
        continue;
      }

      await measure(answered, `${theme} · a drilled answer (${want})`);
      await done(answered);
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

    /* AND THE RULE THE PAPER STATES IS A NUMBER THE SERVER SENT.

       Not an axe check — this suite already refuses to pass a screen it could
       not reach, and this is the same shape: the exam's rules say "minimum to
       pass", and that number used to be a `PASS_MARK = 70` the interface kept
       of its own beside `exam.PassMark` on the server. It comes off the paper
       now, and the way THAT breaks is silently: `undefined%` renders, reads as
       a rendering fault rather than a wrong rule, and passes every contrast
       check there is. A screen stating a rule it did not get is worse than a
       screen missing one. */
    const rules = await student.locator('.exam-rules li').allInnerTexts();
    if (!rules.some((t) => /\d{1,3}\s*%/.test(t))) {
      violations += 1;
      console.error(`✗ ${theme} · the exam's rules state no percentage at all: `
        + `${JSON.stringify(rules)}. The minimum to pass comes off the paper the server `
        + 'drew, so this is the interface having lost it rather than a wrong value.');
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

      await measure(student, `${theme} · exam question ${q + 1} (${kind})`);
    }

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
    /* WHO IS HERE, AND THERE IS SOMEBODY — which is the whole reason the
       student's context is still open at this point in the file. Presence is
       read off `sessions.last_seen_at`, and this suite's student stopped making
       requests several checks ago; measured cold, this screen would be four
       zeroes and a paragraph, which passes every check there is and is not the
       screen.

       So the student is nudged first. The heartbeat writes at most once a
       minute, so after one navigation their session is at most a minute old and
       comfortably inside the five-minute window — and `settled` asks for the
       LIVE tile rather than the grid, so a presence count that silently stopped
       counting anybody fails here instead of passing as a quiet afternoon. */
    await student.goto(`${BASE}/#/dashboard`, { waitUntil: 'load' });
    /* `#content` AND NOT `#stage`. This is the STUDENT's interface, whose region
       is `#content`; `#stage` is the console's, on the other host. The first
       version of this line asked the student's page for the console's element
       and spent eight seconds waiting for something that was never going to be
       there. */
    await student.waitForSelector('#content[data-screen="/dashboard"]', { timeout: 8000 });
    await done(student);

    await check(staff.page, `${theme} · console, who is here`, '/#/presence', '/presence',
      { base: CONSOLE, region: '#stage', settled: '.here-live' });

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

    /* THE STUDENT RECORD, WHICH IS TWO SCREENS: the lookup, and one person.
       The second is reached by looking the student up, because the id is not
       something this file may invent — and a record measured at an id nobody
       has is a "no such person" page passing as a record. */
    await check(staff.page, `${theme} · console, the record lookup`, '/#/record', '/record',
      { base: CONSOLE, region: '#stage' });

    await staff.page.fill('#email', studentEmail);
    await staff.page.click('#find button[type=submit]');
    await staff.page.waitForSelector('#stage[data-screen="/record/:id"]', { timeout: 8000 });
    await check(staff.page, `${theme} · console, one student's record`,
      staff.page.url().slice(CONSOLE.length), '/record/:id',
      { base: CONSOLE, region: '#stage', settled: '.block' });

    /* THE SCHOOLS SCREEN, WHICH IS THE ONE PLACE THE CONSOLE CHANGES SOMETHING
       RATHER THAN READING IT — and the one screen here whose subject is colour,
       which makes measuring it with axe both obvious and easy to get wrong.

       THE SPECIMENS ARE DELIBERATELY NOT THIS PAGE'S THEME. They are pictures of
       the study interface's two themes, drawn on their own grounds, so in the
       light console there is a dark panel and in the dark console a light one.
       Axe measures the text on each against the ground it is actually on, which
       is the whole point of drawing them that way — a preview that followed the
       console's theme would be a preview of a page nobody visits.

       And a colour is typed in, because the screen with a colour chosen is a
       different screen: two specimens, four swatches and the two sentences that
       only appear when a colour had to move. */
    await check(staff.page, `${theme} · console, the schools`, '/#/schools', '/schools',
      { base: CONSOLE, region: '#stage', settled: '.accent-form' });

    await check(staff.page, `${theme} · console, a colour chosen`, '/#/schools', '/schools', {
      base: CONSOLE,
      region: '#stage',
      settled: '.accent-form',
      async act(page) {
        /* AMBER RATHER THAN THE ONE IT IS WEARING: it has to move in both
           themes, so both of the sentences this screen exists to show are on
           the screen when axe looks at it. */
        await page.locator('.accent-pick[data-colour="#d99000"]').first().click();
        await page.waitForSelector('.accent-theme-light .accent-said', { timeout: 8000 });
      },
    });

    /* THE FUNNEL, WHICH IS THE FIRST SCREEN IN `Measure` AND THE FIRST ONE HERE
       THAT DRAWS A QUANTITY. Eight rows of label, bar and count, and the bar is
       a width in per cent — so what axe is being asked is whether a number that
       exists only as the length of a rectangle is also readable as text. It is:
       the count sits beside every bar. This is the check that would notice if it
       stopped doing so.

       TWO STATES, BECAUSE THE SECOND HAS SOMETHING THE FIRST CANNOT. Counting
       the seeded population puts a banner over the chart saying the numbers are
       a demonstration, and a banner is a region with its own contrast, its own
       role and its own place in the reading order. Measured only in the default
       state it would never be looked at. */
    await check(staff.page, `${theme} · console, the funnel`, '/#/funnel', '/funnel',
      { base: CONSOLE, region: '#stage', settled: '#chart .block' });

    await check(staff.page, `${theme} · console, the funnel with the seeded population`,
      '/#/funnel', '/funnel', {
        base: CONSOLE,
        region: '#stage',
        settled: '#chart .block',
        async act(page) {
          await page.selectOption('#counting', 'everybody');
          await page.waitForSelector('.notice-strong', { timeout: 8000 });
        },
      });

    /* AND WHAT THE ANSWERS SAY ABOUT A QUESTION, which is the other half of
       `Measure` and the densest screen in this console: a card per question,
       five verdicts, and a threshold under every number that is a judgement.

       IT HAS ROWS TO DRAW BECAUSE THE FIXTURE WRITES A ROLLUP. Nothing in CI
       runs `cmd/analyse` against a populated stream, so without that this would
       be measured in its "nothing has been computed" state — a paragraph, which
       passes every check there is — and never in the one that matters. That is
       the same reason the fixture carries a lesson and an exam paper. */
    await check(staff.page, `${theme} · console, the questions`, '/#/questions', '/questions',
      { base: CONSOLE, region: '#stage', settled: '.items .item' });

    /* AND THE COHORTS, WHICH IS THE THIRD SCREEN IN `Measure` AND THE ONE WHOSE
       SHAPE IS THE POINT: a triangle, where a younger intake has fewer columns
       and the months that have not happened are drawn as nothing rather than as
       a zero.

       THE FIXTURE WRITES SIX MONTHS OF HISTORY SO THAT SHAPE EXISTS HERE. The
       students this suite signs up all arrive today, so without it the table
       would be one row and one column — no triangle, no empty cells, and a check
       that passes over none of what the screen is for. */
    await check(staff.page, `${theme} · console, the cohorts`, '/#/cohorts', '/cohorts',
      { base: CONSOLE, region: '#stage', settled: '.cohort-table tbody tr' });

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
