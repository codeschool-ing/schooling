/* ==========================================================================
   Schooling — the graph test

   IT CHECKS THE DRAWING, NOT THE CODE THAT MADE IT. Every track, at six window
   sizes, opened in a real browser: the lines are read back out of the SVG the
   router produced and each one is walked point by point to see whether it
   passes through a card.

   WHY A BROWSER AND NOT A UNIT TEST. The router does not decide where anything
   is — the browser does. It measures the boxes the layout produced and draws
   between them, so its input is a font, a wrapped course name, a column that
   went to two lines at one width and one at another. A unit test would have to
   supply those measurements, which means inventing the one thing the test is
   supposed to be checking.

   WHY SIX SIZES. A crossing that appears at 1366 and not at 1920 is the normal
   case, not the exotic one: the number of cards per column changes with the
   height, and the whole arrangement changes with it. Four landscape and two
   portrait, because a track flows downwards on a phone and that is a different
   drawing rather than a narrower one.

   WHAT IT DOES NOT CHECK: whether two LINES cross each other. That is what the
   ordering algorithm minimises and it cannot always reach zero — a graph can
   be non-planar, and a test demanding zero would be a test demanding the
   impossible. A line through a CARD is different: it is always avoidable, the
   router exists to avoid it, and it is the one that makes a drawing unreadable.

       node tools/graph-test/graph-test.mjs [base url]
   ========================================================================== */

import { chromium } from 'playwright';

const BASE = process.argv[2] || 'http://code.example.tld:8099';

/* Four landscape and two portrait. The first is a laptop nobody has replaced,
   which is the one that finds things. */
const SIZES = [
  { name: '1366×768  laptop',    width: 1366, height: 768 },
  { name: '1920×1080 desktop',   width: 1920, height: 1080 },
  { name: '1280×800  small',     width: 1280, height: 800 },
  { name: '1024×640  narrow',    width: 1024, height: 640 },
  { name: '390×844   phone',     width: 390,  height: 844 },
  { name: '820×1180  tablet',    width: 820,  height: 1180 },
];

/* How far inside a card a line has to go before it counts. A curve that clips
   a rounded corner by a pixel is not what this is looking for, and counting it
   would make the test fail on the antialiasing of a border radius. */
const BITE = 3;

/* PLAYWRIGHT FINDS ITS OWN BROWSER, and this must not tell it where to look.
   `npx playwright install` puts one under the home directory and the driver
   resolves it; a path written here is a path that is right on exactly one
   machine. This defaulted to the one in the development sandbox — a local
   detail that leaked into the repository — and CI failed on the first run with
   "executable doesn't exist", having just downloaded a perfectly good browser
   somewhere else.

   The override stays for a machine that already has one and does not want a
   second copy, and it stays OPT-IN. */
const launch = { args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'] };
if (process.env.CHROMIUM) launch.executablePath = process.env.CHROMIUM;

const browser = await chromium.launch(launch);

let failures = 0;
// Edge crossings alone, so the summary can say what it actually found: the
// block at the end of this file adds failures of another kind entirely.
let crossings = 0;
let drawings = 0;
// Sizes where the stylesheet shows the track as a list and draws no edges. See
// the skip in the measurement below.
const notDrawn = [];

try {
  const page = await browser.newPage({ viewport: SIZES[0] });
  await page.goto(`${BASE}/`, { waitUntil: 'load' });
  await page.waitForTimeout(800);

  const tracks = await page.evaluate(async () => {
    const answer = await (await fetch('/api/v1/tracks')).json();
    return (answer.tracks || []).map((t) => ({ id: t.id, name: t.name }));
  });

  /* WHICH FONTS THE RUN GOT, said out loud. This line was added when the
     faces came from a CDN, which the build machine could reach and the
     development sandbox could not: the cards were measured in one set of
     fonts here and another there, and it cost three rounds of guessing at a
     failure that reproduced nowhere.

     They are served from this origin now, so the answer should be the same
     everywhere — which is exactly why it is still printed. A run that says
     FALLBACK after that change is a run that could not load a file the server
     is holding, and it should say so on line one rather than four hundred
     pixels later. */
  const faces = await page.evaluate(async () => {
    await document.fonts.ready;
    /* NOT `document.fonts.check`, which answers a different question: it says
       whether the text can be rendered in the family LIST it is given, and a
       family nobody ever loaded still renders — in the fallback — so it comes
       back true either way. What settles it is whether a face was registered
       at all. */
    return [...document.fonts].filter((f) => f.status === 'loaded').length;
  });
  console.log(faces
    ? `measured with the webfonts (${faces} faces)`
    : 'measured with the FALLBACK fonts — no webfont loaded');
  await page.close();

  if (!tracks.length) {
    console.log('no tracks to draw — nothing to check');
    await browser.close();
    process.exit(0);
  }

  for (const size of SIZES) {
    const page = await browser.newPage({ viewport: { width: size.width, height: size.height } });

    for (const track of tracks) {
      await page.goto(`${BASE}/#/track/${encodeURIComponent(track.id)}`, { waitUntil: 'load' });
      /* The second routing pass runs on the next animation frame, so the test
         has to wait for the drawing rather than for the document. */
      await page.waitForSelector('.graph-edges .row', { timeout: 5000 }).catch(() => {});
      /* THE WEBFONTS DECIDE HOW BIG A CARD IS, and they arrive with
         `display=swap`: the first layout is the fallback's, the second is the
         real one, and a timeout measures whichever it happened to catch. The
         router runs again on resize, so the drawing is right either way — but a
         test that reads it mid-swap reports a drawing nobody ever saw. */
      await page.evaluate(() => document.fonts.ready).catch(() => {});
      await page.waitForTimeout(400);

      const through = await page.evaluate((bite) => {
        const round = (v) => Math.round(v * 10) / 10;
        /* THE CARDS THE ROUTER PLACED. `[data-node]` and not a class name: the
           interface is `portal-frontend`'s now, where a course card is
           `.course-node` and a fork is `.fork`, and both carry the attribute
           the edges are drawn between. Selecting on the attribute is selecting
           on the thing the router actually knows about, which is why it
           survived the change of interface and the class name did not. */
        const cards = [...document.querySelectorAll('[data-node]')].map((el) => {
          const r = el.getBoundingClientRect();
          return {
            id: el.dataset.node,
            left: r.left + bite, right: r.right - bite,
            top: r.top + bite, bottom: r.bottom - bite,
            box: [round(r.left), round(r.top), round(r.width), round(r.height)],
          };
        });

        const svg = document.querySelector('.graph-edges');
        if (!svg) return [];

        /* A DRAWING NOBODY IS SHOWN IS NOT A DRAWING. Below 860px the
           stylesheet collapses the map into ONE COLUMN and hides the edges —
           that layout answers "what comes first" with `requires` written out
           as text, which is the whole point of it on a phone.

           The router keeps routing into the hidden SVG, in the left-to-right
           coordinates the stacked column no longer has, so every line in it
           runs the width of the screen and through every card under it. All
           twelve crossings this suite reported were that, at the phone and the
           tablet — and the vitrine's suite, the same router and the same
           stylesheet, starts at 1080 and never reaches the layout at all.

           Skipped rather than measured, and NAMED rather than skipped in
           silence: a size that stopped drawing for some other reason would
           otherwise read as a size that passed. */
        if (getComputedStyle(svg).display === 'none') return 'not drawn';

        const origin = svg.getBoundingClientRect();

        const hits = [];
        svg.querySelectorAll('.row').forEach((path) => {
          const edge = path.parentElement;
          const from = edge.dataset.from, to = edge.dataset.to;
          const length = path.getTotalLength();

          /* Every two pixels along the curve. Finer finds nothing more — a card
             is a hundred and ninety pixels wide — and coarser can step over a
             corner. */
          for (let at = 0; at <= length; at += 2) {
            const p = path.getPointAtLength(at);
            const x = p.x + origin.left, y = p.y + origin.top;

            for (const card of cards) {
              // Its own endpoints, which it is supposed to touch.
              if (card.id === from || card.id === to) continue;
              if (x > card.left && x < card.right && y > card.top && y < card.bottom) {
                /* WITH ENOUGH GEOMETRY TO DIAGNOSE IT WITHOUT REPRODUCING IT.
                   This test failed on the build machine and on no window size
                   here, because the fonts it downloads and the fonts a sandbox
                   without a network can reach are different fonts, and the
                   router measures boxes that text sizes. Three rounds of
                   guessing later: the report carries the boxes, the point and
                   the path, and the failure is arithmetic on the way back. */
                hits.push({
                  from, to, card: card.id,
                  at: [round(x), round(y)],
                  cards: cards.map((c) => `${c.id} ${c.box.join(',')}`),
                  d: path.getAttribute('d'),
                });
                return;   // one report per edge is enough to fix it
              }
            }
          }
        });
        return hits;
      }, BITE);

      if (through === 'not drawn') {
        notDrawn.push(`${size.name} · ${track.name}`);
        continue;
      }

      drawings += 1;
      if (through.length) {
        failures += through.length;
        crossings += through.length;
        console.error(`✗ ${size.name} · ${track.name}`);
        through.forEach((h) => {
          console.error(`    ${h.from} → ${h.to} passes through ${h.card}, at ${h.at.join(',')}`);
          console.error('      cards (left,top,width,height):');
          h.cards.forEach((c) => console.error(`        ${c}`));
          console.error(`      d: ${h.d}`);
        });
      }
    }

    await page.close();
  }

  /* ---------- and the graph stays where it was put ----------

     A TRACK IS WIDER THAN THE WINDOW, so most of what somebody is looking at is
     somewhere to the right of where the graph starts. Switching a fork rebuilds
     the whole drawing, and a rebuild that starts a new `.track-graph` at scroll
     zero throws the reader back to level one every time they compare two
     branches — which is precisely when they are switching.

     It is checked here rather than in the accessibility pass because the thing
     that regresses is one line of a rebuild nobody looks at twice: this suite
     already opens every track and knows which one has a fork in it, and axe
     cannot see a scroll position at all.

     THE FOCUS IS THE SAME DEFECT WITH NO PIXELS. The button that was pressed
     stops existing, so focus falls to `<body>` and a keyboard is back at the
     top of the document. Both are one rebuild and both are asked for here. */
  const kept = await browser.newPage({ viewport: SIZES[0] });
  let forked = null;
  for (const track of tracks) {
    await kept.goto(`${BASE}/#/track/${encodeURIComponent(track.id)}`, { waitUntil: 'load' });
    await kept.waitForSelector('.graph-edges .row', { timeout: 5000 }).catch(() => {});
    await kept.waitForTimeout(400);
    if (await kept.locator('.fork-tab').count() > 1) { forked = track; break; }
  }

  if (!forked) {
    // Not a pass. The fixture is supposed to carry a fork — it is the shape
    // this whole screen exists for — so its absence is the check going quiet.
    failures += 1;
    console.error('✗ no track in this school has a fork with two options, so the one '
      + 'rebuild this screen does could not be exercised at all');
  } else {
    const scroller = kept.locator('.track-graph');
    await scroller.evaluate((el) => { el.scrollLeft = Math.round(el.scrollWidth / 2); });
    await kept.waitForTimeout(120);
    const before = await scroller.evaluate((el) => el.scrollLeft);

    /* The tab that is NOT the chosen one, driven by the keyboard: pressing it
       with a mouse would leave the focus question unasked, and the focus is
       half of what this holds. */
    const other = kept.locator('.fork-tab:not(.on)').first();
    const wanted = await other.getAttribute('data-option');
    await other.focus();
    await other.press('Enter');
    await kept.waitForTimeout(300);

    const after = await kept.locator('.track-graph').evaluate((el) => el.scrollLeft);
    const focused = await kept.evaluate(() =>
      document.activeElement?.className?.includes?.('fork-tab')
        ? document.activeElement.dataset.option : null);

    if (before < 40) {
      failures += 1;
      console.error(`✗ ${forked.name} — the graph could not be scrolled (${before}px), so `
        + 'staying put is not something this run actually asked');
    } else if (Math.abs(after - before) > 24) {
      failures += 1;
      console.error(`✗ ${forked.name} — switching a fork moved the graph from ${before}px `
        + `to ${after}px. It is a different drawing in the same place, and the reader was `
        + 'looking at the part that moved.');
    }
    if (focused !== wanted) {
      failures += 1;
      console.error(`✗ ${forked.name} — after switching a fork with the keyboard the focus `
        + `is on ${focused === null ? 'nothing in the graph' : 'option ' + focused}, and the `
        + `option pressed was ${wanted}. A rebuild that drops the focus puts somebody `
        + 'driving this from a keyboard back at the top of the document.');
    }
  }
  await kept.close();
} finally {
  await browser.close();
}

if (notDrawn.length) {
  console.log(`${notDrawn.length} of them show the track as a list and draw no edges: `
    + `${notDrawn[0]}, and ${notDrawn.length - 1} more`);
}

if (failures) {
  if (crossings) {
    console.error(`\n${crossings} lines run through a card, in ${drawings} drawings`);
    console.error('A line through a card is always avoidable: the router takes one around');
    console.error('the outside when it can see something in the way, so this is either a');
    console.error('box it could not see or a lane it decided was free and is not.');
  }
  if (failures > crossings) {
    console.error(`\n${failures - crossings} thing(s) the graph does rather than draws came `
      + 'out wrong — see above. They are in this suite because it is the one that opens every');
    console.error('track and knows which of them has a fork to press.');
  }
  process.exit(1);
}

/* AND A SUITE THAT MEASURED NOTHING IS A FAILURE. Every skip above is a size
   where the check does not apply; all of them skipping would mean it applies
   nowhere, and "no line through a card" would be true of a suite that never
   looked at a line. */
if (drawings === 0) {
  console.error('\nnot one drawing was measured — every size showed the track as a list, '
    + 'so this suite proved nothing');
  process.exit(1);
}

console.log(`${drawings} drawings, no line through a card`);
