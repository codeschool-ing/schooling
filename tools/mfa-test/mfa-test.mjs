/* ==========================================================================
   Schooling — the second factor, through the interface, in a real browser.

   # WHY THIS EXISTS AND WHY NO GO TEST REPLACES IT

   The API for the second factor has been complete and tested since staff roles
   shipped: enrol, present, recovery codes, and a door that refuses without one.
   Every one of those has a Go test against a real Postgres.

   And the interface could not use any of it. `ui/app/api.js` refused with "this
   school does not have multi-factor sign-in yet" — true of that file and never
   of the server — and the sign-in screen's code step was reached by an
   `mfaRequired` flag nothing ever sent. So the first factor on this platform
   was enrolled by hand, in the browser's own console, against the API.

   That failure is invisible from Go: the server was right the whole time. It is
   invisible to `a11y-test` too, which measures the screen and not the round
   trip. What it needs is a browser doing what a person does — and that is this
   file, on the same argument `landing-test` is written on.

   # WHAT IT DRIVES

   Sign up, enrol a factor from the account screen with a code this file
   computes, keep the ten recovery codes, sign out, sign in again, and go
   through the code step twice: once with the app's six digits and once with a
   recovery code, which is the path a person takes when the phone is gone.

       node tools/mfa-test/mfa-test.mjs [base url]
   ========================================================================== */

import { createHmac } from 'node:crypto';
import { chromium } from 'playwright';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

const launch = { args: [`--host-resolver-rules=MAP ${new URL(BASE).hostname} 127.0.0.1`] };
if (process.env.CHROMIUM) launch.executablePath = process.env.CHROMIUM;

/* RFC 6238, thirty lines rather than a dependency — the same call
   `internal/identity/totp.go` makes, and wrong here is not subtle: the server
   answers `wrong_code` and this run stops. */
function totp(secret, at = Date.now()) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const ch of secret.toUpperCase().replace(/[\s=]/g, '')) {
    const v = alphabet.indexOf(ch);
    if (v < 0) throw new Error(`the secret is not base32: ${ch}`);
    bits += v.toString(2).padStart(5, '0');
  }
  const key = Buffer.from((bits.match(/.{8}/g) || []).map((b) => parseInt(b, 2)));
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 1000 / 30)));
  const mac = createHmac('sha1', key).update(counter).digest();
  const offset = mac[mac.length - 1] & 0x0f;
  return String((mac.readUInt32BE(offset) & 0x7fffffff) % 1_000_000).padStart(6, '0');
}

let problems = 0;
const wrong = (what) => { problems += 1; console.error(`✗ ${what}`); };

const browser = await chromium.launch(launch);
const context = await browser.newContext({ viewport: { width: 1280, height: 900 } });
const page = await context.newPage();
page.on('pageerror', (e) => wrong(`the page threw: ${e.message}`));

// The account screen's own button, which is what a person presses.
async function signOut() {
  await page.goto(`${BASE}/#/account`, { waitUntil: 'load' });
  await page.waitForSelector('#sign-out', { timeout: 8000 });
  await page.click('#sign-out');
}

const email = `mfa-${Date.now()}@example.tld`;
const password = 'a long enough password here';

try {
  /* ---------- an account ---------- */

  await page.goto(`${BASE}/#/sign-in`, { waitUntil: 'load' });
  await page.waitForSelector('#e-toggle', { timeout: 8000 });
  await page.click('#e-toggle');
  await page.waitForSelector('#e-name', { timeout: 8000 });
  await page.fill('#e-name', 'Ada Lovelace');
  await page.fill('#e-email', email);
  await page.fill('#e-password', password);
  const [signedUp] = await Promise.all([
    page.waitForResponse((r) => r.url().endsWith('/api/v1/sign-up'), { timeout: 15000 }),
    page.click('#form-signin button[type=submit]'),
  ]);
  if (!signedUp.ok()) throw new Error(`signing up: ${signedUp.status()}`);

  /* WAIT FOR THE APP AND NOT FOR THE RESPONSE. Signing up lands on the
     dashboard, and the state that says who is signed in is written on the way
     there. Navigating on the 201 alone is a hash change into a screen whose
     session has not arrived, which sends it straight back to sign-in — this
     file did exactly that, and the account screen looked broken. */
  await page.waitForSelector('#content[data-screen="/dashboard"]', { timeout: 15000 });

  /* ---------- enrol, from the account screen ---------- */

  await page.goto(`${BASE}/#/account`, { waitUntil: 'load' });
  await page.waitForSelector('#start', { timeout: 8000 });
  await page.click('#start');
  await page.waitForSelector('#secret', { timeout: 8000 });

  /* THE SECRET IS READ OFF THE SCREEN, not out of the response — that is what
     a person does with it, and a secret rendered wrongly is a secret nobody can
     type into an app. The screen groups it in fours to be readable; the spaces
     are the screen's and not the secret's. */
  const shown = (await page.locator('#secret').innerText()).replace(/\s+/g, '');
  if (!/^[A-Z2-7]{32}$/.test(shown)) {
    wrong(`the secret on screen is not base32: ${JSON.stringify(shown)}`);
  }

  /* THE LINK IS THE SAME SECRET AND THE SAME PERSON. An `otpauth://` that
     carried a different secret would enrol an app that then never agrees with
     the server, and one carrying a different address would put an entry called
     somebody else in the person's authenticator. The label is a path segment
     and keeps its `@`, which is what the key-URI format says and what apps
     split on — so this looks for the address as written. */
  const link = await page.locator('.view-account a[href^="otpauth://"]').first().getAttribute('href');
  if (!link || !link.includes(email) || !link.includes(shown)) {
    wrong(`the otpauth link does not carry this account and this secret: ${link}`);
  }

  await page.fill('#code', totp(shown));
  await page.click('#confirm button[type=submit]');
  await page.waitForSelector('.codes li', { timeout: 8000 });

  const codes = await page.locator('.codes li').allInnerTexts();
  if (codes.length !== 10) wrong(`the screen showed ${codes.length} recovery codes, want 10`);
  for (const code of codes) {
    if (!/^[0-9A-HJ-NP-TV-Z]{5}-[0-9A-HJ-NP-TV-Z]{5}$/.test(code.trim())) {
      wrong(`"${code}" is not a recovery code anybody could copy off this screen`);
    }
  }

  /* ---------- sign out, and back in ---------- */

  /* SIGNING OUT IS THE BUTTON AND NOT A REQUEST. Clearing the cookie by hand
     leaves the app's own document in memory saying somebody is signed in, and
     the sign-in screen then bounces to the dashboard — which is what this file
     did, and it looked like a broken sign-in screen. `api.signOut` ends the
     session AND drops the document, because a document left behind after
     signing out is one person's progress shown to whoever is at the machine
     next. */
  await signOut();
  await page.waitForSelector('#e-email', { timeout: 8000 });
  await page.fill('#e-email', email);
  await page.fill('#e-password', password);
  await page.click('#form-signin button[type=submit]');

  /* THE CODE STEP IS THE WHOLE POINT. Before this branch the server never said
     a code was owed, so the screen went straight to the dashboard and the
     factor was never presented — a person with a second factor signed in as
     though they had none. */
  const asked = await page.waitForSelector('#e-code', { timeout: 8000 }).catch(() => null);
  if (!asked) {
    wrong('signing in did not ask for a code, so an account with a second factor '
      + 'is signed into as though it had none');
    throw new Error('nothing else in this run means anything after that');
  }

  await page.fill('#e-code', totp(shown));
  await page.click('#form-signin button[type=submit]');
  const arrived = await page.waitForSelector('#content[data-screen="/dashboard"]', { timeout: 15000 })
    .catch(() => null);
  if (!arrived) {
    wrong(`after the code, the interface drew `
      + `${await page.locator('#content').getAttribute('data-screen')} rather than the dashboard`);
  }

  /* ---------- and once more, with a recovery code ---------- */

  /* SIGNING OUT IS THE BUTTON AND NOT A REQUEST. Clearing the cookie by hand
     leaves the app's own document in memory saying somebody is signed in, and
     the sign-in screen then bounces to the dashboard — which is what this file
     did, and it looked like a broken sign-in screen. `api.signOut` ends the
     session AND drops the document, because a document left behind after
     signing out is one person's progress shown to whoever is at the machine
     next. */
  await signOut();
  await page.waitForSelector('#e-email', { timeout: 8000 });
  await page.fill('#e-email', email);
  await page.fill('#e-password', password);
  await page.click('#form-signin button[type=submit]');
  await page.waitForSelector('#e-code', { timeout: 8000 });

  await page.fill('#e-code', codes[0].trim());
  await page.click('#form-signin button[type=submit]');
  const gotIn = await page.waitForSelector('#content[data-screen="/dashboard"]', { timeout: 15000 })
    .catch(() => null);
  if (!gotIn) {
    wrong('a recovery code did not get in, which is the one thing recovery codes are for');
  }

  /* AND IT WAS SPENT. A code that stays unspent is a code somebody else can
     still use after the person who owned it did. */
  await page.goto(`${BASE}/#/account`, { waitUntil: 'load' });
  await page.waitForSelector('#left', { timeout: 8000 });
  const left = await page.locator('#left').innerText();
  if (!/\b9\b/.test(left)) {
    wrong(`the account screen says "${left}" after one code was spent, want nine left`);
  }
} finally {
  await browser.close();
}

if (problems) {
  console.error(`\n${problems} problems`);
  console.error('The API for all of this is tested in Go and was right the whole time.');
  console.error('What this file holds is whether the INTERFACE can reach it, which is');
  console.error('the half that was missing for as long as the second factor has existed.');
  process.exit(1);
}

console.log('the second factor works through the interface: enrolled, signed in with the '
  + 'app, signed in with a recovery code, and the code was spent');
