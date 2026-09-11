/* Command figure-fit measures a drawing instead of trusting it.
 *
 * # NOTHING READS INSIDE AN SVG, AND BY NOW THAT HAS COST FOUR THINGS
 *
 * A figure is markup inside a content file: past `validate-content`, which
 * reads the catalogue's shape, and past axe, which reads a rendered page and
 * has no opinion about where a rectangle ends. Four defects have lived in that
 * gap — twelve palette tokens that resolved to nothing and would have rendered
 * INVISIBLE; three labels still in Portuguese in the English lesson; two fonts
 * the application has never shipped; and the two this tool exists for.
 *
 * # WIDTH WAS MEASURED ONCE, BY HAND, AND HEIGHT WAS NOT
 *
 * A throwaway script caught a Portuguese label running 33px past the viewBox
 * while the translation was being written. It only looked sideways. A bar
 * labelled `core 4` was two pixels below the box drawn around it, in both
 * languages, and stayed there — visible to anybody who looked at the picture
 * and to no check at all. So this measures BOTH axes, and it is a file in the
 * repository rather than a script in somebody's terminal.
 *
 * # IT LOADS THE REAL FONTS AND REFUSES TO RUN WITHOUT THEM
 *
 * Text width is a property of the typeface. The first hand-run of the width
 * check measured with the faces still `unloaded`, which is a measurement of the
 * fallback font dressed as a measurement of ours — an empty pass of exactly the
 * kind this file is against. `document.fonts.load` is awaited and the status is
 * asserted before anything is measured.
 *
 *     node tools/figure-fit/figure-fit.mjs [content-dir]
 */
import { chromium } from 'playwright';
import { readFileSync, readdirSync, writeFileSync, unlinkSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.argv[2] || 'content';
const ASSETS = 'ui/assets';

/* Every figure in the tree, with where it came from, so a failure names a file
   a person can open rather than an index into an array. */
function figures(dir) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true, recursive: true })) {
    if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
    const path = join(entry.parentPath ?? entry.path, entry.name);
    let n = 0;
    for (const m of readFileSync(path, 'utf8').matchAll(/```schooling-figure\n(.*?)\n```/gs)) {
      try {
        const block = JSON.parse(m[1]);
        if (block.svg) out.push({ path, n: n++, svg: block.svg });
      } catch { /* a malformed fence is `validate-content`'s to report */ }
    }
  }
  return out;
}

const found = figures(ROOT);
if (!found.length) {
  console.log(`no figures under ${ROOT}, nothing to measure`);
  process.exit(0);
}

const page = 'fit-harness.html';
writeFileSync(join(ASSETS, page),
  '<!doctype html><meta charset="utf-8"><link rel="stylesheet" href="fonts/fonts.css">' +
  "<style>body{margin:0;font-family:'IBM Plex Sans',sans-serif}svg{width:720px}</style>" +
  '<div id="h"></div>');

const browser = await chromium.launch();
try {
  const tab = await browser.newPage();
  await tab.goto('file://' + process.cwd() + '/' + join(ASSETS, page));

  const faces = await tab.evaluate(async () => {
    await Promise.all([
      document.fonts.load("600 13px 'IBM Plex Sans'", 'Browser 1234 áéçõ'),
      document.fonts.load("400 13px 'IBM Plex Sans'", 'Browser 1234 áéçõ'),
      document.fonts.load("400 11px 'IBM Plex Mono'", '203.0.113.7 áéçõ'),
    ]);
    await document.fonts.ready;
    return [...document.fonts].filter((f) => f.status === 'loaded').map((f) => f.family);
  });
  for (const want of ['IBM Plex Sans', 'IBM Plex Mono']) {
    if (!faces.includes(want)) {
      console.error(`${want} did not load, so every width below would be the fallback font's. ` +
        'Refusing to measure — a pass here would mean nothing.');
      process.exit(1);
    }
  }

  let problems = 0;
  for (const f of found) {
    for (const p of await tab.evaluate(measure, f.svg)) {
      problems += 1;
      console.error(` - ${f.path} figure ${f.n + 1}: ${p}`);
    }
  }

  if (problems) {
    console.error(`\n${problems} thing(s) outside the box drawn around them, across ` +
      `${found.length} figures. A drawing is not checked by looking at the file.`);
    process.exit(1);
  }
  console.log(`${found.length} figures, every label and bar inside its own box and inside the frame`);
} finally {
  await browser.close();
  unlinkSync(join(ASSETS, page));
}

/* Runs in the page. Two questions, both about geometry and neither about style:
   does anything leave the frame, and does anything leave the box it is drawn
   inside?

   THE SECOND NEEDS A RULE FOR "INSIDE", AND THE FIRST RULE WAS WRONG. It was
   "the containing rectangle, unless that rectangle is wider than 60% of the
   frame, in which case it is a backdrop". That threshold threw away the exact
   box this tool was written for: the panel around the four processor cores is
   578 wide in a 720 frame, so the bar hanging two pixels below it belonged, by
   the rule, to nothing at all. The tool passed on the defect it was written to
   catch — which is how the fonts check began too, and is the reason both are
   now verified by putting the defect back.

   The rule is the SMALLEST rectangle that contains the centre and has more area
   than the thing itself. No threshold: a label centred on a wide panel is
   inside that panel, and reporting it only when it OVERFLOWS is what makes that
   harmless. Nesting is answered by size, which is what nesting is. */
function measure(svg) {
  document.getElementById('h').innerHTML = svg;
  const el = document.querySelector('#h svg');
  if (!el) return ['the fence carries no <svg>'];
  const vb = el.viewBox.baseVal;
  const out = [];

  const boxes = [...el.querySelectorAll('rect')].map((r) => ({
    x: r.x.baseVal.value, y: r.y.baseVal.value,
    w: r.width.baseVal.value, h: r.height.baseVal.value,
  }));
  const inside = (b) => boxes
    .filter((r) => b.cx > r.x && b.cx < r.x + r.w && b.cy > r.y && b.cy < r.y + r.h &&
                   r.w * r.h > b.w * b.h)
    .sort((p, q) => p.w * p.h - q.w * q.h)[0];

  const frame = (what, b) => {
    if (b.x < vb.x - 1) out.push(`${what} starts at x=${Math.round(b.x)}, left of the frame`);
    else if (b.x + b.w > vb.x + vb.width + 1)
      out.push(`${what} ends at x=${Math.round(b.x + b.w)}, past the frame's ${vb.width}`);
    else if (b.y < vb.y - 1) out.push(`${what} starts at y=${Math.round(b.y)}, above the frame`);
    else if (b.y + b.h > vb.y + vb.height + 1)
      out.push(`${what} ends at y=${Math.round(b.y + b.h)}, below the frame's ${vb.height}`);
    else return false;
    return true;
  };

  for (const t of el.querySelectorAll('text')) {
    const r = t.getBBox();
    if (!r.width) continue;
    const b = { x: r.x, y: r.y, w: r.width, h: r.height, cx: r.x + r.width / 2, cy: r.y + r.height / 2 };
    const what = `the label ${JSON.stringify(t.textContent.trim().slice(0, 42))}`;
    if (frame(what, b)) continue;
    const host = inside(b);
    if (host && (b.x < host.x - 1 || b.x + b.w > host.x + host.w + 1)) {
      out.push(`${what} is ${Math.round(b.w)} wide in a box of ${Math.round(host.w)}`);
    }
  }

  /* AND THE SHAPES, WHICH IS THE HALF THAT WAS MISSING. `core 4` was a bar two
     pixels below the panel drawn around it — nothing to do with text. */
  for (const r of el.querySelectorAll('rect, circle, ellipse')) {
    const g = r.getBBox();
    if (!g.width || !g.height) continue;
    const b = { x: g.x, y: g.y, w: g.width, h: g.height, cx: g.x + g.width / 2, cy: g.y + g.height / 2 };
    const what = `a ${r.tagName} at (${Math.round(g.x)}, ${Math.round(g.y)})`;
    if (frame(what, b)) continue;
    const host = inside(b);
    if (!host) continue;
    if (b.y + b.h > host.y + host.h + 1) {
      out.push(`${what} ends at y=${Math.round(b.y + b.h)}, ` +
        `${Math.round(b.y + b.h - host.y - host.h)}px below the box around it`);
    } else if (b.x + b.w > host.x + host.w + 1) {
      out.push(`${what} ends at x=${Math.round(b.x + b.w)}, ` +
        `${Math.round(b.x + b.w - host.x - host.w)}px right of the box around it`);
    }
  }
  return out;
}
