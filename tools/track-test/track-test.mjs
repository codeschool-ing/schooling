/* ==========================================================================
   A section that says something different to each track says the right thing.

   # WHY THIS IS THE TEST AND NOT THE GO ONE

   The grammar of a passage written for one track is `internal/trackblock`'s,
   and the Go tests hold it there: the checker refuses a malformed group, the
   loader renames a slug to an id, the public page keeps the `*` passage. None
   of that can see `ui/app/api.js`, which reads the same markers a second time
   because a browser cannot import Go — and the two could drift apart with every
   Go test green. So this opens the one lesson the fixture gives a group and
   asks the SCREEN which passage it shows:

     1. a student on the fixture's track meets that track's passage, and not
        the other one, and no marker reaches the page;
     2. the choice beside the group is labelled, names the track, and moving it
        to "any other track" shows the `*` passage instead;
     3. a student on a track the group does not name meets the `*` passage —
        which is also what a student on no track at all is shown.

   The fixture writes the marker with the track's ID, because the mirror is
   past the loader and nothing there speaks slugs — see the comment on the
   group in `tools/graph-test/fixture.sql`.
   ========================================================================== */
import { chromium } from 'playwright';
import { signUpThroughTheForm } from '../lib/sign-up.mjs';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

const OWN = 'On the front-end track, the client you write is the page in the browser.';
const ANY = 'Whatever you build, the part that asks is the client.';

const problems = [];
const browser = await chromium.launch({
  args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });

await signUpThroughTheForm(page, BASE, {
  name: 'Grace Hopper', email: `track-${Date.now()}@example.tld`,
});

/* What the reader can see of the group: which passages are visible, what the
   choice says, and whether a marker leaked into the text. */
const group = () => page.evaluate(() => {
  const g = document.querySelector('.lesson-text .prose-track');
  if (!g) return null;
  const pick = g.querySelector('select.prose-track-pick');
  return {
    visible: [...g.querySelectorAll(':scope > .prose-track-passage')]
      .filter((p) => !p.hidden).map((p) => p.innerText.trim()),
    chosen: pick && pick.options[pick.selectedIndex].text,
    options: pick ? [...pick.options].map((o) => o.text) : [],
    labelled: !!(pick && pick.closest('label') && pick.closest('label').innerText.trim()),
    marker: document.querySelector('.lesson-text').innerText.includes(':::'),
  };
});

const open = async () => {
  await page.goto(`${BASE}/#/course/web-fundamentals/lesson/0`, { waitUntil: 'load' });
  await page.waitForSelector('.lesson-text .prose-track', { timeout: 15000 });
};

/* 1. On the track: its own passage. The fixture has one track, and the
   interface puts a student with no choice yet on the first. */
await open();
let seen = await group();
if (!seen) {
  problems.push('the lesson drew no group of passages — the fixture writes one at the end of `roles`');
} else {
  if (seen.visible.length !== 1 || !seen.visible[0].includes(OWN)) {
    problems.push(`a student on the track sees ${JSON.stringify(seen.visible)}, not its own passage`);
  }
  if (seen.marker) problems.push('a `:::` marker reached the page');
  if (!seen.labelled) problems.push('the choice beside the group has no label');
  if (seen.chosen !== 'Front-end Development') {
    problems.push(`the choice says ${JSON.stringify(seen.chosen)}, not the track the student is on`);
  }
  if (seen.options.length !== 2) {
    problems.push(`the choice offers ${JSON.stringify(seen.options)} — one track and "any other track"`);
  }

  /* 2. Moving the choice moves the passage, and nothing else on the page. */
  await page.selectOption('.lesson-text select.prose-track-pick', '*');
  seen = await group();
  if (seen.visible.length !== 1 || !seen.visible[0].includes(ANY)) {
    problems.push(`after choosing "any other track" the page shows ${JSON.stringify(seen.visible)}`);
  }
}

/* 3. On a track the group does not name: the passage for everybody else. The
   enrolment is the document's, so it is written the way `api.enrol` writes it
   and the section drawn again from another screen, because a hash change is
   not a reload and the document is only in memory. */
await page.goto(`${BASE}/#/dashboard`, { waitUntil: 'load' });
await page.evaluate(async () => {
  const state = await import('/app/state.js');
  state.replaceEnrollment({ ...(state.now().enrollment || {}), trackId: 'tr-zzzzzzzz' });
});
await open();
seen = await group();
if (!seen || seen.visible.length !== 1 || !seen.visible[0].includes(ANY)) {
  problems.push(`a student on another track sees ${JSON.stringify(seen && seen.visible)}, not the passage for everybody else`);
}

await browser.close();

if (problems.length) {
  console.error('A section that varies by track said the wrong thing:');
  for (const p of problems) console.error('  - ' + p);
  process.exit(1);
}
console.log('a passage for the reader\'s track, the choice beside it, and the passage for everybody else');
