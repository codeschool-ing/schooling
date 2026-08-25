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
    await page.waitForSelector('#content h1, #content .notice, #content .view', { timeout: 8000 })
      .catch(() => {});
    await page.evaluate(() => document.fonts.ready).catch(() => {});
    await page.waitForTimeout(400);
  };

  /* ---------- it opens, and it is a school ---------- */

  await open();

  /* AGAINST WHAT WAS BAKED, and not merely "there is something there". The
     shell ships `codeschool.ing` in the bar because it is `portal-frontend`'s
     markup, and the boot replaces it with the school's own name — so a check
     for a non-empty string passes on the file that never read its catalogue.
     That is not a hypothetical: a linker that handed out a copy of an export
     instead of the binding shipped exactly that, silently. */
  const named = await page.evaluate(() => {
    const baked = window.SCHOOLING_BAKED && window.SCHOOLING_BAKED.answers['/api/v1/school'];
    const shown = (document.querySelector('.brand-name') || {}).textContent || '';
    return { want: (baked && baked.name) || '', got: shown.trim() };
  });
  if (named.want && named.got === named.want) right(`the school is "${named.got}"`);
  else if (!named.want) wrong('no school was baked into the bundle at all');
  else wrong(`the bar says "${named.got}" where the school is "${named.want}" — `
    + 'the shell rendered without its catalogue');

  await open('#/catalog');
  const courses = await page.$$eval('#content a[href^="#/course/"]',
    (links) => [...new Set(links.map((a) => a.getAttribute('href')))]);
  if (courses.length) right(`${courses.length} courses on the catalogue`);
  else wrong('the catalogue is empty — nothing was baked, or nothing can be read back');

  /* THE TRACKS ARE ASKED OF THE PAGE and not read off a screen: the copied
     interface reaches a track through the bar's selector, which is a menu and
     not a list of links, so there is no screen with all nineteen on it. */
  const tracks = await page.evaluate(
    () => (window.TRACKS || []).map((t) => `#/track/${t.id}`));
  if (tracks.length) right(`${tracks.length} tracks`);
  else wrong('no track in the bundle');

  /* ---------- every track draws ---------- */

  for (const where of tracks) {
    await open(where);
    const edges = await page.locator('.graph-edges .row').count();
    const nodes = await page.locator('[data-node]').count();
    if (edges > 0 && nodes > 0) right(`${where} drew ${nodes} cards and ${edges} lines`);
    else wrong(`${where} drew ${nodes} cards and ${edges} lines — the graph did not render`);
  }

  /* ---------- a course, and a lesson with its own sections ----------

     THE SECTIONS ARE THE CHECK, not the length of the screen. A course nobody
     has written yet draws one section called "Content", and so does a course
     whose shape was never baked — the two are the same number of pixels and
     the same number of characters. What tells them apart is the section strip:
     the real lesson has the sections the school wrote, by name.

     AND IT LOOKS PAST THE FIRST COURSE. Most of this school's courses are
     announced and not yet written, so the placeholder is the honest answer for
     them; what is being proved is that a course which HAS material carries it
     into the file. One is the proof, and the search stops there. */
  let read = 0;
  for (const where of courses) {
    await open(where);

    const lessons = await page.$$eval('#content a[href^="#/course/"]',
      (links, here) => links
        .map((a) => a.getAttribute('href'))
        .filter((href) => href !== here && href.split('/').length > 3),
      where);

    if (!lessons.length) continue;

    await open(lessons[0]);
    /* `.step-assessment` is the exam at the end of every lesson and is drawn
       whether or not anybody wrote a section, so it is not evidence. */
    const sections = await page.$$eval('#content .steps .step:not(.step-assessment)',
      (steps) => steps.map((s) => (s.querySelector('.step-title') || {}).textContent || ''));
    if (sections.length && !(sections.length === 1 && /^content$/i.test(sections[0].trim()))) {
      right(`${lessons[0]} has its sections — ${sections.length} of them`);
      read += 1;

      /* ---------- and the outline survives the arrow ----------

         THE RAIL IS THE THING THAT BREAKS, and it breaks by drawing something
         perfectly reasonable: the portal's navigation. A student reading a
         lesson clicked the forward arrow and the list of sections they were
         working through was replaced by Dashboard / My track / Catalog. It came
         back if they clicked a tab, because the tabs wrote the course's id into
         the address and the arrow wrote its slug, and only one of those two was
         a name the rail could resolve.

         Nothing threw and nothing was blank, which is why this is checked in a
         browser rather than trusted to a unit somewhere. */
      /* WHICHEVER FORWARD CONTROL THIS WIDTH ACTUALLY SHOWS. There are two and
         they are the same link: the side arrow above 1400px and the footer
         button below it, one of them hidden by CSS at any given moment. This
         page is 1366 wide, so naming the arrow found it in the DOM and waited
         thirty seconds for something `display:none` to become clickable.
         `.advances` is what both carry, and `:visible` picks the one on screen. */
      const outlineBefore = await page.locator('#rail .rail-lesson').count();
      const arrow = page.locator('#content a.advances:visible');
      if (outlineBefore > 0 && await arrow.count()) {
        await arrow.first().click();
        await page.waitForTimeout(150);
        const outlineAfter = await page.locator('#rail .rail-lesson').count();
        if (outlineAfter > 0) {
          right(`the rail still shows the course after moving on — ${outlineAfter} lessons`);
        } else {
          wrong('moving to the next section collapsed the rail to the portal navigation: '
            + 'the address that control wrote names the course differently from the '
            + 'one the section tabs write, and the rail can only resolve one of them');
        }
      } else if (!outlineBefore) {
        wrong('the rail is not showing the course outline on a lesson at all');
      }
      break;
    }
  }
  if (!read) {
    wrong('not one lesson in the bundle carries the shape the school wrote — '
      + 'every course opened with the placeholder section');
  }

  /* ---------- the two documents, which must NOT refuse ----------

     They are the deliberate exception to the section below. A policy that
     answered "this needs the school" would be unpublished for whoever is
     reading the offline copy — and a file on a laptop is exactly what gets
     handed to somebody else. */

  for (const where of ['#/terms', '#/privacy']) {
    await open(where);
    const said = ((await page.textContent('#content').catch(() => '')) || '').trim();
    if (said.toLowerCase().includes('offline copy')) {
      wrong(`${where} needs the school — the document is not baked into the bundle`);
    } else if (said.length > 400) {
      right(`${where} reads — ${said.length} characters of it`);
    } else {
      wrong(`${where} opened with ${said.length} characters in it`);
    }
  }

  /* ---------- and it refuses the rest, out loud ----------

     The failure this catches is not a crash. It is a bundle that shows a
     student a sign-in form, or an exam paper, and then does nothing at all when
     they use it — which is worse than saying so, because they will try twice
     and then assume it is their fault. */

  for (const where of ['#/sign-in', '#/dashboard', '#/certificates', '#/practice']) {
    await open(where);
    const said = ((await page.textContent('#content').catch(() => '')) || '').toLowerCase();
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
