/* ==========================================================================
   Schooling — the offline bundle, opened

   BUILT IS NOT THE CLAIM. A bundler that exits zero has proved that it wrote a
   file, and every way this can fail produces a file: an unescaped `</script`
   that ends the page halfway, a module linked in the wrong order, a font whose
   relative URL means nothing once the stylesheet is inline, a lesson whose key
   differs from the one the client asks for by a single `?lang=`. All of those
   are a 300 kB HTML document that opens to a blank screen.

   So this opens it, FROM `file://`, in a real browser, and reads it.

   AND IT COUNTS THE REQUESTS. The one property the whole design rests on is
   that a bundle opened from a file asks nobody for anything — no API, no font
   CDN, no favicon. That is not visible in the markup and it is not visible in a
   screenshot; it is visible in the network log, and a single entry there is a
   failure however good the page looks.

   IT FINDS THE CONTENT RATHER THAN NAMING IT. The fixture is a stand-in until
   `content/` has a school, and a test that hardcoded `web-fundamentals` would
   have to be rewritten on the day that stops being true. It reads the
   catalogue, follows the links it finds, and asserts about their shape.

       node tools/bundle-test/bundle-test.mjs <path to the bundle>
   ========================================================================== */

import { chromium } from 'playwright';
import { resolve } from 'node:path';

const file = process.argv[2];
if (!file) {
  console.error('usage: node tools/bundle-test/bundle-test.mjs <path to the bundle>');
  process.exit(2);
}
const BUNDLE = 'file://' + resolve(file);

/* See the graph test for why this is opt-in rather than a path written here. */
const launch = {};
if (process.env.CHROMIUM) launch.executablePath = process.env.CHROMIUM;

const browser = await chromium.launch(launch);

let failures = 0;
const wrong = (what) => { failures += 1; console.error(`✗ ${what}`); };
const right = (what) => console.log(`✓ ${what}`);

/* Everything the page asked anybody for, and everything it complained about.
   Collected for the whole run rather than per screen: a request made once, on
   the fifth navigation, is exactly the one a per-screen check would miss. */
const offsite = [];
const complaints = [];

try {
  const page = await browser.newPage({ viewport: { width: 1366, height: 768 } });

  page.on('request', (r) => {
    if (!r.url().startsWith('file://') && !r.url().startsWith('data:')) {
      offsite.push(`${r.method()} ${r.url().slice(0, 120)}`);
    }
  });
  page.on('pageerror', (e) => complaints.push(`uncaught: ${e.message}`));
  page.on('console', (m) => { if (m.type() === 'error') complaints.push(`console: ${m.text()}`); });

  const open = async (fragment = '') => {
    await page.goto(BUNDLE + fragment, { waitUntil: 'load' });
    await page.waitForSelector('#screen h1, #screen .notice', { timeout: 8000 }).catch(() => {});
    await page.evaluate(() => document.fonts.ready).catch(() => {});
    await page.waitForTimeout(400);
  };

  /* ---------- it opens, and it is a school ---------- */

  await open();

  const school = await page.textContent('#school-name').catch(() => '');
  if (school && school.trim()) right(`the school is "${school.trim()}"`);
  else wrong('the school has no name — the shell rendered without its catalogue');

  const courses = await page.$$eval('#screen .card',
    (cards) => cards.map((c) => c.getAttribute('href')).filter(Boolean));
  if (courses.length) right(`${courses.length} courses on the catalogue`);
  else wrong('the catalogue is empty — nothing was baked, or nothing can be read back');

  const tracks = await page.$$eval('#screen a[href^="#/track/"]',
    (links) => [...new Set(links.map((a) => a.getAttribute('href')))]);
  if (tracks.length) right(`${tracks.length} tracks`);
  else wrong('no track on the catalogue');

  /* ---------- every track draws ---------- */

  for (const where of tracks) {
    await open(where);
    const edges = await page.locator('.graph-edges .row').count();
    const nodes = await page.locator('.node').count();
    if (edges > 0 && nodes > 0) right(`${where} drew ${nodes} cards and ${edges} lines`);
    else wrong(`${where} drew ${nodes} cards and ${edges} lines — the graph did not render`);
  }

  /* ---------- a course, and a lesson with words in it ---------- */

  let read = 0;
  for (const where of courses) {
    await open(where);

    const lessons = await page.$$eval('#screen a[href^="#/course/"]',
      (links, here) => links
        .map((a) => a.getAttribute('href'))
        .filter((href) => href !== here && href.split('/').length > 3),
      where);

    if (!lessons.length) continue;

    await open(lessons[0]);
    const prose = (await page.textContent('#screen .prose').catch(() => '')) || '';
    if (prose.trim().length > 40) {
      right(`${lessons[0]} reads — ${prose.trim().length} characters of it`);
      read += 1;
      break;   // one is the proof; the rest are the same code path
    }
    wrong(`${lessons[0]} opened with no prose in it`);
    break;
  }
  if (!read) wrong('not one lesson in the bundle could be read');

  /* ---------- and it refuses the rest, out loud ----------

     The failure this catches is not a crash. It is a bundle that shows a
     student a sign-in form, or an exam paper, and then does nothing at all when
     they use it — which is worse than saying so, because they will try twice
     and then assume it is their fault. */

  for (const where of ['#/sign-in', '#/dashboard', '#/certificates', '#/practice']) {
    await open(where);
    const said = ((await page.textContent('#screen').catch(() => '')) || '').toLowerCase();
    if (said.includes('offline copy')) right(`${where} says it is the offline copy`);
    else wrong(`${where} does not say a server is needed — it shows: ${said.slice(0, 70).trim()}`);
  }

  /* ---------- the whole point ---------- */

  if (offsite.length === 0) right('it asked nobody for anything');
  else {
    wrong(`${offsite.length} requests left the file:`);
    offsite.forEach((r) => console.error(`    ${r}`));
  }

  if (complaints.length === 0) right('nothing threw and nothing was logged as an error');
  else {
    wrong(`${complaints.length} complaints from the page:`);
    complaints.forEach((c) => console.error(`    ${c}`));
  }
} finally {
  await browser.close();
}

if (failures) {
  console.error(`\n${failures} things wrong with the bundle`);
  process.exit(1);
}
console.log('\nthe bundle opens, reads, and asks nobody for anything');
