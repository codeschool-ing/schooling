/* ==========================================================================
   A course is fetched once, and a redraw does not fetch it again.

   # THE FAILURE IT EXISTS TO CATCH

   `loadCourseContent` asked the server for every lesson of a course every time
   it ran, and nothing asked whether the course was already in the store. On top
   of that `redrawAll` dispatches TWICE on a language switch — once straight
   away, once when the catalogue lands — so one click cost three full rounds.

   While a course was a handful of sections that was invisible. `linux-terminal`
   is 228 sections across thirteen lessons, about 1.2 MB a round: opening it
   pulled 5 MB, took the best part of a minute, and Firefox offered to stop the
   page. The biggest course did not cause the defect, it made a standing one
   visible — which is exactly the kind of thing no unit test was ever going to
   say, because every piece of it works.

   IT IS NOT A PERFORMANCE BUDGET. A budget in milliseconds fails on a slow
   runner and teaches people to raise the number. This counts REQUESTS, which is
   a property of the code: the same screen drawn twice asks the server for the
   same lesson twice, or it does not.

   # WHAT IT CHECKS

   Open the biggest course, redraw it three times, and count the requests for a
   lesson's prose. Thirteen and then thirteen. Then switch the language and
   watch them happen again, because a store holding one language has to be
   dropped when it moves — a guard that skipped that would be this defect traded
   for a worse one, Portuguese prose served to a reader who asked for English.
   ========================================================================== */
import { chromium } from 'playwright';
import { signUpThroughTheForm } from '../lib/sign-up.mjs';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

/* A lesson's prose, which is the request this is about. The shape of a course
   (`/lessons?lang=`) is one request for the whole catalogue and is not it. */
const isLessonProse = (url) => /\/api\/v1\/courses\/[^/]+\/lessons\/le-/.test(url);

const problems = [];
/* THE SCHOOL IS A HOST AND THE RUNNER HAS NEVER HEARD OF IT. The same rule the
   other browser suites carry; without it this failed with ERR_NAME_NOT_RESOLVED
   and said nothing about fetching. */
const browser = await chromium.launch({
  args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'],
});
const page = await browser.newPage({ viewportSize: { width: 1280, height: 900 } });

try {
  await signUpThroughTheForm(page, BASE, {
    name: 'Fetch Once',
    email: `fetch-once-${Date.now()}@example.tld`,
  });

  /* THE BIGGEST COURSE THIS ACCOUNT CAN ACTUALLY READ.

     Naming `linux-terminal` would pass here and fail in CI, where the catalogue
     is a seven-course fixture — and the claim is not about that course: a
     screen drawn twice must not ask twice, whatever it is drawing. The biggest
     one only makes the arithmetic loudest.

     READABLE IS THE OTHER HALF, and it is not decoration. A course outside the
     plan answers `locked`, stores nothing, and is therefore asked for again on
     every redraw — which looks exactly like the defect and is not it. The
     fixture's `html-css` is one, and picking it measured the wrong thing. */
  const COURSE = await page.evaluate(async () => {
    const api = await import('/app/api.js');
    const store = await import('/app/lessons.js');
    const bySize = (globalThis.COURSES || [])
      .slice()
      .sort((a, b) => (b.topics || []).length - (a.topics || []).length);
    for (const c of bySize) {
      if (!(c.topics || []).length) continue;
      if (await api.loadCourseContent(c.id) === true && store.courseLoaded(c.id)) {
        return c.slug || c.id;
      }
    }
    return null;
  });

  if (!COURSE) {
    throw new Error('no course in this catalogue could be read, so there is nothing to count — '
      + 'the account has no plan, or the catalogue arrived empty');
  }

  /* FROM AN EMPTY STORE, because choosing the course above filled it. Counting
     from here would count zero and call the defect fixed. */
  await page.reload({ waitUntil: 'load' });
  await page.waitForTimeout(1200);

  let asked = 0;
  page.on('response', (r) => { if (isLessonProse(r.url())) asked += 1; });

  await page.goto(`${BASE}/#/course/${COURSE}`, { waitUntil: 'load' });
  await page.waitForSelector('.screen-course', { timeout: 30000 });
  await page.waitForTimeout(2000);

  const first = asked;
  if (first === 0) {
    problems.push(`opening ${COURSE} asked for no lesson at all — either the course is `
      + 'empty or this suite is signed out, and both make the count below meaningless');
  }

  /* THREE, BECAUSE ONE WOULD PASS ON THE DEFECT. A language switch dispatches
     twice; a student clicking about does it more. */
  for (let i = 0; i < 3; i += 1) {
    await page.evaluate(() => globalThis.redrawAll && globalThis.redrawAll());
    await page.waitForTimeout(1200);
  }

  if (asked > first) {
    problems.push(`${COURSE} was fetched again on a redraw: ${first} requests to open it and `
      + `${asked} after three redraws. The store is not being read before the server is asked.`);
  }

  /* And the other half of the guard: the store holds one language. */
  await page.evaluate(() => {
    document.documentElement.lang = 'pt-BR';
    if (globalThis.redrawAll) globalThis.redrawAll();
  });
  await page.waitForTimeout(3000);

  if (asked <= first) {
    problems.push('switching the language fetched nothing, so the store was reused across '
      + 'languages — the reader is being served the prose they did not ask for');
  }

  if (!problems.length) {
    console.log(`${COURSE}: ${first} lesson requests to open, none on three redraws, `
      + `${asked - first} again when the language moved`);
  }
} finally {
  await browser.close();
}

if (problems.length) {
  for (const p of problems) console.error(` - ${p}`);
  console.error(`\n${problems.length} problem(s). A screen drawn twice must not ask twice.`);
  process.exit(1);
}
