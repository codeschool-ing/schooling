/* ==========================================================================
   Does the course screen offer the exam the school actually has?

   # THE DEFECT THIS EXISTS FOR SHIPPED, AND EVERY OTHER CHECK WAS GREEN

   `sql-databases` reached production with a hundred exam questions, loaded into
   the mirror by the deploy, sittable at its own address — and the card at the
   foot of the course said *"in preparation — not enough exercises yet"*, with
   no link. The card decided by DEALING A PAPER IN THE BROWSER out of
   `window.SAMPLE_EXERCISES`, the predecessor's static sample data, which is
   empty wherever there is a server. It had never asked.

   Nothing caught it and nothing could have. `validate-content` reads files;
   `check-exercises` reads answer keys; the Go tests prove the route answers;
   `a11y-test` draws this very screen and measures the contrast of the words
   "coming soon", which are perfectly legible and perfectly false. A green run
   of everything this repository owns is compatible with an exam nobody can
   reach from the interface.

   # IT SURVIVED BECAUSE IT WAS TRUE

   No course had an exam, so "in preparation" was right by accident for as long
   as the catalogue was empty. That is the shape worth naming: a screen that
   states a fact it never checks is not wrong on the day it is written, it is
   wrong on the day the fact changes, and by then nobody is looking at it.

   # WHAT IT ASKS

   Two questions, of the API and of the screen, and it fails on the DISAGREEMENT
   rather than on either answer alone — which is why it is a browser suite and
   not an assertion in Go or a unit test over the module:

     1. a course the catalogue says has a pool offers a link to sit it;
     2. a course with no pool says so and offers nothing;
     3. the length the card names is the length the paper will be — the smaller
        of the pool and the school's draw. The card said ten while the server
        drew twenty, from a constant of its own, which is the same defect one
        number along.

   The fixture already seeds an exam for one course and leaves the others
   without one, so both sides of every question are present with nothing added
   for the sake of the test.

       node tools/exam-offer-test/exam-offer-test.mjs [base]
   ========================================================================== */
import { chromium } from 'playwright';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

const problems = [];
const say = (p) => problems.push(p);

/* THE SCHOOL IS A HOST AND THE RUNNER HAS NEVER HEARD OF IT — the same rule
   every browser suite here carries. */
const browser = await chromium.launch({
  args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'],
});

/* Read of the API, through a tab, so it arrives on the school's host exactly as
   the interface's own request does. Asked from Node it would reach a server
   that has no idea which school is being talked about. */
async function asked(page, path) {
  return page.evaluate(async (p) => {
    const r = await fetch(p, { headers: { accept: 'application/json' } });
    if (!r.ok) throw new Error(`${p} answered ${r.status}`);
    return r.json();
  }, path);
}

const card = (page) => page.evaluate(() => {
  const el = document.querySelector('.exam-card');
  if (!el) return null;
  const box = el.getBoundingClientRect();
  return {
    shown: box.width > 0 && box.height > 0,
    pending: el.classList.contains('pending'),
    text: (el.innerText || '').replace(/\s+/g, ' ').trim(),
    href: el.querySelector('.exam-card-action a')?.getAttribute('href') || null,
  };
});

/* The number the card names, which is the claim being checked — not whether
   some digit is present. A card that names no length at all is a separate,
   allowed state (the school did not say), so this answers null rather than
   guessing zero. */
const named = (text) => {
  const m = text.match(/(\d+)\s+\S+/);
  return m ? Number(m[1]) : null;
};

/* ARRIVING IS THE COURSE'S OWN NAME ON THE SCREEN, NOT THE NAVIGATION RETURNING.

   Every course here is reached from the one before it by changing the fragment,
   and a fragment is not a page load: `goto` answers as soon as the address has
   changed, and the router paints the new screen after it. Read the card in that
   gap and it is the PREVIOUS course's — which is how this suite reported
   `agents-mcp`, a course with no exam, offering one: it was reading `git`'s card
   under `agents-mcp`'s address. It passed in CI by winning the race on a
   fixture of a handful of courses and lost it on the real catalogue, which is
   the shape of a check that is green by luck.

   So a visit waits for the heading to name the course asked for, and a screen
   that never gets there is said out loud rather than read anyway. */
async function visit(page, c) {
  await page.goto(`${BASE}/#/course/${encodeURIComponent(c.slug)}`, { waitUntil: 'networkidle' });
  const arrived = await page.waitForFunction(
    (name) => (document.querySelector('main h1')?.innerText || '').trim() === name,
    c.name, { timeout: 10000 },
  ).then(() => true, () => false);
  if (!arrived) {
    say(`${c.slug}'s screen never showed its own name, "${c.name}", so its card was not read — `
      + 'whatever the card says there belongs to some other screen.');
  }
  return arrived;
}

try {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  await page.goto(BASE + '/', { waitUntil: 'networkidle' });

  const { courses } = await asked(page, '/api/v1/courses');
  const school = await asked(page, '/api/v1/school');

  const withExam = courses.filter((c) => c.examPool > 0);
  const without = courses.filter((c) => !c.examPool);

  /* THE SUITE REFUSES RATHER THAN PASSING ON A CATALOGUE THAT CANNOT ANSWER IT.
     A school with no exam anywhere would make every question below vacuous, and
     a vacuous pass is what this file exists to stop being possible. */
  if (!withExam.length) {
    console.error('no course in this school has an exam, so there is nothing to offer and '
      + 'nothing to check. The fixture seeds one — this is a fixture that did not load, '
      + 'not a catalogue that is fine.');
    process.exit(1);
  }

  for (const c of withExam) {
    if (!(await visit(page, c))) continue;
    await page.waitForSelector('.exam-card', { timeout: 10000 }).catch(() => {});
    const seen = await card(page);

    if (!seen || !seen.shown) {
      say(`${c.slug} has ${c.examPool} exam question(s) and its course screen draws no exam `
        + 'card at all. The card is meant to be there whether the exam can be sat or not.');
      continue;
    }
    if (seen.pending || !seen.href) {
      say(`${c.slug} has ${c.examPool} exam question(s) in the catalogue and the card says `
        + `"${seen.text}" with ${seen.href ? 'a link' : 'NO link'}. The exam is there and the `
        + 'screen is telling a student it is not.');
      continue;
    }

    /* THE LENGTH, WHICH IS THE HALF THAT IS WRONG QUIETLY. A missing link is
       visible to anybody who looks; a card promising ten questions before a
       paper of twenty is read once and believed. */
    const paper = school.examQuestions > 0
      ? Math.min(c.examPool, school.examQuestions) : c.examPool;
    const said = named(seen.text);
    if (said !== null && said !== paper) {
      say(`${c.slug}'s card names ${said} question(s); the paper will hold ${paper} — `
        + `${c.examPool} in the pool, ${school.examQuestions || 'no'} drawn by this school, `
        + 'and a pool under the draw is asked in full.');
    }
  }

  for (const c of without.slice(0, 3)) {
    if (!(await visit(page, c))) continue;
    await page.waitForSelector('.exam-card', { timeout: 10000 }).catch(() => {});
    const seen = await card(page);

    if (!seen || !seen.shown) {
      say(`${c.slug} has no exam and its course screen draws no card. An empty exam says what `
        + 'is coming instead of vanishing — publishing one at a time must not rearrange '
        + "anyone's screen.");
      continue;
    }
    if (!seen.pending || seen.href) {
      say(`${c.slug} has no exam question in the catalogue and its card offers one anyway `
        + `("${seen.text}"). A button that 404s is worse than a sentence saying it is coming.`);
    }
  }

  /* THE TRACK'S FINAL, PRESSED RATHER THAN READ.

     The card at the foot of a track links to `#/track/exam`, and for as long as
     tracks have had a screen that link led to "you have not chosen a track
     yet": the router takes the first pattern that matches, `/track/:id` was
     registered first, and it read `exam` as a track and enrolled the student in
     it — losing the real enrolment on the way. No track had a final, so the
     card said "in preparation" and nobody pressed the link. Reading the card
     would have passed; only arriving answers it. */
  const { tracks } = await asked(page, '/api/v1/tracks');
  const finals = tracks.filter((t) => t.examPool > 0);
  if (!finals.length) {
    console.error('no track in this school has a final. The fixture seeds one — this is a '
      + 'fixture that did not load, not a school that is fine.');
    process.exit(1);
  }
  for (const t of finals) {
    await page.goto(`${BASE}/#/track/${encodeURIComponent(t.slug)}`, { waitUntil: 'networkidle' });
    await page.waitForSelector('.exam-card', { timeout: 10000 }).catch(() => {});
    const seen = await card(page);
    if (!seen || !seen.href) {
      say(`${t.slug} has ${t.examPool} final question(s) and its track screen offers no link to `
        + `sit them${seen ? ` ("${seen.text}")` : ''}.`);
      continue;
    }
    /* FOLLOWED BY ITS HREF, which is what pressing it does. A click races the
       track screen, which repaints the card after the graph has measured itself
       and leaves the element that was clicked detached.

       WHAT IS ASKED IS WHETHER THE SCREEN ASKED FOR THIS TRACK'S PAPER, not
       whether a paper was drawn: this student is anonymous, the server answers
       401, and whether a paper follows is the paywall's business and the Go
       tests'. The route's is that the request goes out for the right track —
       the broken order never sent one at all. */
    const asks = [];
    const listen = (r) => { if (r.method() === 'POST' && /\/api\/v1\/exams\/track\//.test(r.url())) asks.push(new URL(r.url()).pathname); };
    page.on('request', listen);
    await page.goto(`${BASE}/${seen.href}`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);
    page.off('request', listen);

    const wanted = `/api/v1/exams/track/${t.id}/start`;
    if (!asks.includes(wanted)) {
      const text = (await page.locator('main').innerText()).replace(/\s+/g, ' ').slice(0, 120);
      say(`${t.slug}'s exam card links to ${seen.href}, and following it never asked the server `
        + `for that track's paper (${asks.length ? asks.join(', ') : 'no exam request at all'}); `
        + `the screen says "${text}".`);
    }
    const kept = await page.evaluate(async () => (await import('/app/state.js')).now().enrollment?.trackId);
    if (kept !== t.id) {
      say(`following ${t.slug}'s exam card left the student enrolled in ${JSON.stringify(kept)}, `
        + `not ${t.id}: opening a track's exam must not change which track somebody is on.`);
    }
  }

  if (problems.length) {
    console.error('\nthe course screen and the catalogue disagree about the exam:\n');
    for (const p of problems) console.error(' - ' + p);
    console.error(`\n${problems.length} disagreement(s). The route works; the screen is what `
      + 'has to say so.');
    process.exit(1);
  }

  console.log(`${withExam.length} course(s) with an exam offer it, ${Math.min(without.length, 3)} `
    + 'without one say so, every card names the length of the paper it leads to, and '
    + `${finals.length} track final(s) are asked for by their own card`);
} finally {
  await browser.close();
}
