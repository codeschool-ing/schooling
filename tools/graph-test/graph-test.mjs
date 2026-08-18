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

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM || '/opt/pw-browsers/chromium',
  args: ['--host-resolver-rules=MAP code.example.tld 127.0.0.1'],
});

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
      await page.waitForTimeout(400);

      const through = await page.evaluate((bite) => {
        const cards = [...document.querySelectorAll('.node')].map((el) => {
          const r = el.getBoundingClientRect();
          return {
            id: el.dataset.node,
            left: r.left + bite, right: r.right - bite,
            top: r.top + bite, bottom: r.bottom - bite,
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
                hits.push({ from, to, card: card.id });
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
        through.forEach((h) => console.error(
          `    ${h.from} → ${h.to} passes through ${h.card}`));
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
