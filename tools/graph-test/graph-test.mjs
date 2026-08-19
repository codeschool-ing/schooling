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
let drawings = 0;

try {
  const page = await browser.newPage({ viewport: SIZES[0] });
  await page.goto(`${BASE}/`, { waitUntil: 'load' });
  await page.waitForTimeout(800);

  const tracks = await page.evaluate(async () => {
    const answer = await (await fetch('/api/v1/tracks')).json();
    return (answer.tracks || []).map((t) => ({ id: t.id, name: t.name }));
  });

  /* WHICH FONTS THE RUN GOT, said out loud. The interface asks a CDN for
     three, and a machine that cannot reach it renders in the fallback — a
     different set of measurements, and therefore a different drawing. A run
     that passes says nothing about the other one, and the first time that
     mattered it cost three rounds of guessing at a failure that reproduced
     nowhere. */
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
        const cards = [...document.querySelectorAll('.node')].map((el) => {
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

      drawings += 1;
      if (through.length) {
        failures += through.length;
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
} finally {
  await browser.close();
}

if (failures) {
  console.error(`\n${failures} lines run through a card, in ${drawings} drawings`);
  console.error('A line through a card is always avoidable: the router takes one around');
  console.error('the outside when it can see something in the way, so this is either a');
  console.error('box it could not see or a lane it decided was free and is not.');
  process.exit(1);
}

console.log(`${drawings} drawings, no line through a card`);
