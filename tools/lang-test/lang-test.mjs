/* ==========================================================================
   A language switch reaches the lessons, and nothing takes it back.

   # THE FAILURE IT EXISTS TO CATCH

   The store holds ONE language at a time and `forLanguage` is what moves it:
   it empties the structure and the prose so that the next read fetches the
   language on screen. Its only caller was `loadCourseContent` — the first
   course a student opened — and `loadLessonStructure`, which FILLS the store,
   never moved it. So the two halves of one switch were not ordered against
   each other, and one order lost:

     switch to English   `loadLessonStructure` writes the English structure,
                         and the store's language is still Portuguese
     open any course     `loadCourseContent` calls `forLanguage('en')`,
                         which throws that English structure away

   Nothing put it back. `structureLocale` already said `en`, so
   `languageChanged()` was false and no redraw asked again. Every course whose
   prose was not in the store fell to the rule that stands in for a course
   nobody has written — ONE SECTION PER LESSON — so `linux-terminal` reported
   13 sections where it has 228, and the track's total was short by exactly the
   difference, until the tab was reloaded.

   The other half of the same defect is what a student actually reported: with
   the prose store never dropped, the dashboard kept drawing the section title
   it already had, in the language before the switch. The interface was
   Portuguese and the card under it was English, and it stayed that way until
   the student opened a course — "I have to change pages for it to update".

   # WHAT IT CHECKS, AND WHY IN A BROWSER

   Both claims are about WHEN two correct functions run, which is why no unit
   test was ever going to say it. So: open a course, go back, switch language,
   open a course again — the order that loses — and then ask the store what it
   is holding.

     1. every course keeps its section count across the switch, and
     2. the dashboard's own words move language with the interface.

   The counts are read from `lessons.js` rather than off the screen, because
   the screen shows one track and the defect is about the whole catalogue.
   ========================================================================== */
import { chromium } from 'playwright';
import { signUpThroughTheForm } from '../lib/sign-up.mjs';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

const problems = [];
/* THE SCHOOL IS A HOST AND THE RUNNER HAS NEVER HEARD OF IT — the same rule
   every browser suite here carries. */
const browser = await chromium.launch({
  args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

/* Every course in the catalogue and how many sections the portal thinks it
   has. This is the denominator of every bar on every screen. */
const sectionCounts = () => page.evaluate(async () => {
  const store = await import('/app/lessons.js');
  const out = {};
  for (const c of globalThis.COURSES || []) out[c.id] = store.sectionCount(c.id);
  return out;
});

const dashboard = async () => {
  await page.evaluate(() => { location.hash = '#/dashboard'; });
  await page.waitForSelector('#content[data-screen="/dashboard"]', { timeout: 15000 });
  await page.waitForTimeout(1500);
};

/* The resume card names a SECTION, and a section's title comes from the store
   rather than from a dictionary — which is what makes it the right thing to
   read here. */
const resumeTitle = () => page.evaluate(() =>
  document.querySelector('.resume-lesson')?.textContent.trim() || '');

const openACourse = async () => {
  const link = page.locator('#content a[href*="/lesson/"]').first();
  if (!(await link.count())) return false;
  await link.click();
  await page.waitForTimeout(2500);
  return true;
};

const switchTo = async (code) => {
  await page.click('#lang .lang-btn');
  await page.waitForSelector(`#lang .lang-op[lang^="${code}"]`, { timeout: 5000 });
  await page.click(`#lang .lang-op[lang^="${code}"]`);
  /* The switch fetches the catalogue, the tracks and the structure before it
     draws again; there is nothing to wait FOR that is not already on screen in
     the language before it. */
  await page.waitForTimeout(4000);
};

try {
  await signUpThroughTheForm(page, BASE, {
    name: 'Lang Test',
    email: `lang-test-${Date.now()}@example.tld`,
  });
  await page.waitForTimeout(1500);

  const before = await sectionCounts();
  const written = Object.entries(before).filter(([, n]) => n > 0);
  if (!written.length) {
    throw new Error('no course in this catalogue has a section, so there is nothing to lose — '
      + 'the structure never arrived, and every claim below would pass on an empty store');
  }

  /* THE STORE ADOPTS A LANGUAGE HERE, which is what the switch below has to
     move. Without this step `forLanguage` has nothing to drop and the losing
     order cannot happen. */
  if (!(await openACourse())) {
    throw new Error('the dashboard offered no lesson to open, so the store never took a '
      + 'language and this suite would pass without exercising anything');
  }
  await dashboard();

  const titleBefore = await resumeTitle();

  await switchTo('pt');

  /* READ BEFORE ANYTHING ELSE IS OPENED, because opening a course is what used
     to cure this by accident: `loadCourseContent` dropped the store on its way
     past, so a suite that navigated first would watch the defect repair itself
     and report a pass. What the student described is this exact moment —
     switch, look at the screen, and the card is still in the old language. */
  const titleAfter = await resumeTitle();

  /* And now the order that used to lose the other half: a course opened AFTER
     the new structure has landed. */
  await openACourse();
  await dashboard();

  const after = await sectionCounts();
  const lost = written
    .filter(([id, n]) => after[id] !== n)
    .map(([id, n]) => `${id} ${n} → ${after[id]}`);

  if (lost.length) {
    problems.push(`${lost.length} course(s) lost their sections when the language moved: `
      + `${lost.join(', ')}. The structure store was emptied after it was filled, and nothing `
      + 'asks for it again — every bar on every screen is now drawn against the wrong total.');
  }

  if (!titleBefore) {
    problems.push('the dashboard drew no resume card, so what the store is serving the screen '
      + 'was never read — the check on the language of it below means nothing');
  } else if (titleAfter === titleBefore) {
    problems.push(`the dashboard still says "${titleAfter}" with the interface in Portuguese. `
      + 'The prose store was not dropped when the language moved, so the screen is being served '
      + 'the language the student switched away from.');
  }

  if (!problems.length) {
    console.log(`${written.length} course(s) kept their sections across the switch, `
      + `and the dashboard moved from "${titleBefore}" to "${titleAfter}"`);
  }
} finally {
  await browser.close();
}

if (problems.length) {
  for (const p of problems) console.error(` - ${p}`);
  console.error(`\n${problems.length} problem(s). A language switch has to reach the lessons, `
    + 'and nothing that runs after it may take it back.');
  process.exit(1);
}
