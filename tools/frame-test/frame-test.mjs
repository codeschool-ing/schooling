/* ==========================================================================
   The frame around the screen: which build it says it is, and the notice that
   says it has moved on.

   # WHAT HAS NO CHECK TODAY, AND WHY IT IS THIS SHAPE OF CHECK

   `paintFrame` draws five things that belong to no screen — the account menu,
   the notice that this platform is unfinished, the confirmation nudge, the
   view-as banner and the stale notice. `lang-test` reads three of them and
   asks one question: do the WORDS follow a language switch. Nothing asks what
   any of them SAY.

   The version badge is the sharpest case of that, because it is the one piece
   of the frame whose content comes from the server rather than from a
   dictionary, and because being wrong is worse than being absent: a badge is
   read as the answer to "which build am I looking at", and a tab left open
   across a deploy is running an older one than the server would name now. Its
   whole reason for existing is to be the honest answer to a question somebody
   is asking because something looks odd.

   None of it is reachable from a unit test. The badge is painted a second time
   when a request lands; the stale notice is painted when a comparison between
   two requests, minutes or days apart, comes out unequal. Both are about WHEN,
   which is the same reason `lang-test` is a browser suite and not an assertion.

   # THE STALE NOTICE NEEDS THE BUILD TO MOVE, AND IT CANNOT HERE

   `release.js` compares the whole of `/version` — the tag, the commit and the
   build time — and an unstamped build answers `{"version":"dev"}` with the
   other two empty. Every dev build shares that, which is the exact thing the
   module's own header says the commit exists to prevent, and it means no
   arrangement of a local server can make this tab find itself behind: the
   answer is a constant.

   So the ROUTE is what moves, not the server. `/version` is answered from here,
   and the answer changes between the request at boot and the request after the
   tab comes back — which is precisely the sequence a deploy produces, and the
   only part of it this suite has to invent.

   # AND THE STYLESHEETS, WHICH IS A SMALLER CLAIM THAN IT LOOKS

   `document.styleSheets` with rules in it catches a stylesheet that did not
   ARRIVE: a renamed file, a path that lost a directory, a 404 served as the
   index page. That is worth one line here, because the shell's seven `<link>`
   elements are part of the frame and nothing else looks at them in a browser.

   It catches nothing else, and the temptation is to think it does. A file
   carrying a comment terminator that closes nothing arrives, parses, and has
   rules in it — the browser drops the one rule below the break and says
   nothing. `tools/check-css` is what reads that, over the source, because there
   is nothing in a loaded sheet to see.

   (The sequence is named rather than written for the reason this paragraph is
   about: the first draft of this header spelled it out, and closed the comment
   it was inside.)
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

const say = (p) => problems.push(p);

/* A tab, signed in, with `/version` answered from here.

   The answer is read from `build` at the moment of the request rather than
   captured, so moving `build` between two requests is the whole of what a
   deploy looks like from inside a tab. */
async function tab(build) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  await page.route('**/version', (route) => route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify(build.now),
  }));
  await signUpThroughTheForm(page, BASE, {
    name: 'Frame Test',
    email: `frame-test-${Date.now()}-${Math.random().toString(36).slice(2, 8)}@example.tld`,
  });
  /* The badge is painted when `/version` lands, which is after the first
     screen — see `release.watch`'s place in `main.js`'s boot. */
  await page.waitForTimeout(2000);
  return page;
}

/* THE TAB COMING BACK, WHICH IS THE ONLY MOMENT `release.js` ASKS.

   The event is dispatched rather than produced by hiding the window, and that
   is a real limit of this suite rather than a shortcut worth hiding: a headless
   page is never backgrounded, so there is no way to make the browser fire this
   for itself. What it does exercise is everything from the listener down — the
   floor between checks, the request, the comparison and the paint — and the one
   thing it takes on trust is that Chromium fires `visibilitychange` when a tab
   is looked at again, which is not a claim about this repository. */
const comeBack = async (page) => {
  await page.evaluate(() => document.dispatchEvent(new Event('visibilitychange')));
  await page.waitForTimeout(1500);
};

const text = (page, sel) => page.evaluate(
  (s) => (document.querySelector(s)?.innerText || '').replace(/\s+/g, ' ').trim(), sel);

/* ON THE SCREEN, MEASURED AND NOT INFERRED.

   `offsetParent !== null` is the usual shorthand for this and it is wrong here
   in the one place it matters: it is null for a `position:fixed` element, and
   the stale notice is fixed — bottom left, over whatever is behind it. The
   first version of this suite used it and reported the notice as never drawn,
   which is a defect in the suite that reads exactly like a defect in the
   interface. A box with a size in it is the thing actually being claimed. */
const shown = (page, sel) => page.evaluate((s) => {
  const el = document.querySelector(s);
  if (!el || el.hidden) return false;
  const box = el.getBoundingClientRect();
  return box.width > 0 && box.height > 0;
}, sel);

try {
  /* ---------- the badge says what the server said ---------- */

  const served = { version: 'v9.9.9-frame-test', commit: 'abc1234', built: '2026-01-01T00:00:00Z' };
  const build = { now: served };
  const page = await tab(build);

  const badge = await text(page, '.db-version');
  if (!(await shown(page, '#dev-banner'))) {
    say('the notice that this platform is being built is not on the screen, so the badge '
      + 'inside it cannot be either — every claim below about it would pass on an empty '
      + 'banner. `UNDER_CONSTRUCTION` is the constant that decides this.');
  } else if (badge !== served.version) {
    say(`the badge says "${badge}" and \`/version\` answered "${served.version}". It is the `
      + 'one piece of the frame whose content comes from the server, and a student reads it '
      + 'as the answer to which build they are looking at — a wrong one is worse than none.');
  }

  /* ---------- and keeps saying it, through everything that repaints ----------

     `paintDevBanner` rebuilds its own `innerHTML` from a module variable, and
     is called from `paintFrame`, which is called on every change of state and
     on every language switch. A badge that is drawn once and lost on the next
     repaint would look perfectly correct in a screenshot taken at boot. */
  const openACourse = async () => {
    const link = page.locator('#content a[href*="/lesson/"]').first();
    if (!(await link.count())) return false;
    await link.click();
    await page.waitForTimeout(2500);
    return true;
  };

  if (!(await openACourse())) {
    say('the dashboard offered no lesson to open, so the badge was never put through a '
      + 'redraw and the claim that it survives one means nothing');
  }

  await page.click('#lang .lang-btn');
  await page.waitForSelector('#lang .lang-op[lang^="pt"]', { timeout: 5000 });
  await page.click('#lang .lang-op[lang^="pt"]');
  await page.waitForTimeout(4000);

  const after = await text(page, '.db-version');
  if (after !== badge) {
    say(`the badge read "${badge}" and reads "${after}" after a course and a language switch. `
      + 'It is painted from a variable this module sets once, and the sentence around it is '
      + 'rebuilt on every repaint — so a version is not a number to translate, it is a number '
      + 'to carry through the translation.');
  }

  /* ---------- every stylesheet the shell links arrived ---------- */

  const sheets = await page.evaluate(() => {
    const linked = [...document.querySelectorAll('link[rel=stylesheet]')].map((l) => l.href);
    const empty = [];
    for (const s of document.styleSheets) {
      if (!s.href) continue;                     // an inline <style>, which cannot 404
      /* `cssRules` THROWS RATHER THAN ANSWERING ZERO for a sheet the browser
         will not let script read, and a missing file is one of them: this
         server answers an unknown path with the index page, and a `text/html`
         body linked as a stylesheet is declined and then unreadable. Measured
         on a renamed link, not assumed — it is the case this line is for. */
      let rules = 0;
      let why = '';
      try {
        rules = s.cssRules.length;
        why = 'parsed to nothing';
      } catch (e) {
        why = 'could not be read at all — a missing file, or an origin that is not ours';
      }
      if (rules <= 0) empty.push(`${new URL(s.href).pathname} ${why}`);
    }
    return { linked: linked.length, empty };
  });

  if (sheets.linked === 0) {
    say('this page links no stylesheet at all, which is not a pass — the check below has '
      + 'nothing to read');
  } else if (sheets.empty.length) {
    say(`${sheets.empty.length} of the ${sheets.linked} stylesheets this page links reached the `
      + `browser with nothing in them: ${sheets.empty.join(', ')}. A stylesheet that 404s is `
      + 'served the index page, parses to nothing, and leaves every screen it dresses looking '
      + 'like a document rather than broken.');
  }

  await page.close();

  /* ---------- a check that finds the same build says nothing ---------- */

  const quiet = { now: served };
  const steady = await tab(quiet);
  await comeBack(steady);
  if (await shown(steady, '#stale-banner')) {
    say('the notice asking somebody to reload appeared on a tab running the build the server '
      + 'is still serving. It interrupts to say something that is not true, and this platform '
      + 'has timed exams — the one place a spurious reload prompt costs a person marks.');
  }
  await steady.close();

  /* ---------- and a check that finds a different one says so ---------- */

  const moved = { now: served };
  const behind = await tab(moved);
  if (await shown(behind, '#stale-banner')) {
    say('the stale notice was already on the screen before the build moved, so its appearing '
      + 'afterwards proves nothing');
  }
  /* THE DEPLOY. Same tag, different commit — which is the case the module's
     header says the tag alone cannot see, and the one an unstamped build meets
     every time. */
  moved.now = { ...served, commit: 'def5678', built: '2026-02-02T00:00:00Z' };
  await comeBack(behind);

  if (!(await shown(behind, '#stale-banner'))) {
    say('the build this tab was served is no longer the one the server answers with, and the '
      + 'tab says nothing. Nothing here can fix that tab — its modules are in memory and will '
      + 'never be asked for again — so noticing is the whole of what it can do.');
  } else {
    const notice = await text(behind, '#stale-banner');
    if (!notice) {
      say('the stale notice is on the screen with no words in it');
    }
    /* AND IT IS A SENTENCE AND A BUTTON, never a reload nobody asked for. The
       claim is checked from the other end — the page is still the one that was
       loaded — because a reload is exactly what this must not do by itself. */
    const reloaded = await behind.evaluate(() => performance.getEntriesByType('navigation')
      .some((n) => n.type === 'reload'));
    if (reloaded) {
      say('the tab reloaded itself when it found it was behind. This platform has timed '
        + 'exams: a reload nobody asked for, at a moment nobody chose, is the worst thing an '
        + 'update mechanism can do here, and it would do it to the one person who cannot '
        + 'afford it.');
    }
    if (!(await behind.locator('#stale-banner .sb-reload').count())) {
      say('the stale notice offers no way to reload, so it is a sentence about a problem with '
        + 'no way out of it');
    }
  }
  await behind.close();

  if (!problems.length) {
    console.log(`the badge reads ${served.version}, keeps reading it through a course and a `
      + `language switch, ${sheets.linked} stylesheets arrived with rules in them, and the `
      + 'stale notice appears when the build moves and not before');
  }
} finally {
  await browser.close();
}

if (problems.length) {
  for (const p of problems) console.error(` - ${p}`);
  console.error(`\n${problems.length} problem(s). The frame is what a student reads when `
    + 'something looks wrong, so it is the last part of the interface allowed to be.');
  process.exit(1);
}
