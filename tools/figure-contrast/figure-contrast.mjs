/* ==========================================================================
   Every word in every figure can be read, in both themes.

   # WHY THIS DID NOT EXIST, AND WHAT THAT COST

   `docs/CONTENT.md` says it out loud: "a token that does not exist resolves to
   nothing and the figure renders invisible, with every check in this repository
   still green: nothing reads inside an SVG." That sentence was written about a
   missing token and it was true of everything else in there too.

   The whole interface goes through axe, twice, on every screen — and axe does
   not measure text inside an SVG either, because the contrast it can compute is
   between a DOM node and what is painted behind it, and a `<tspan>` over a
   `<rect>` is one node over another inside an image.

   So 258 runs of text shipped below AA, across both courses — 46 in the
   captured figures and 212 in the hand-drawn ones — and four of them were the
   same colour as the ground they sat on. `Press ENTER or type command to
   continue` was 1.24:1. None of it was visible to a person reading the diff
   either: a figure is one line of JSON with an SVG inside it.

   # WHAT IT MEASURES

   Every `<tspan>` with a letter in it, against whatever is behind that tspan —
   the `<rect>` the capture drew under it, or `--panel` where there is none —
   at WCAG AA for body text, in BOTH themes. A figure is drawn once and read by
   two readers.

   THE PALETTE IS READ FROM `terminal.css` RATHER THAN COPIED HERE. It is the
   file that decides what `var(--term-green)` is, and a checker holding its own
   idea of that would pass a figure the browser draws differently. `base.css`
   answers for `--panel` and `--paper` the same way.

   # WHAT IT DOES NOT MEASURE

   Spaces. A run of padding on a coloured ground carries no glyph, and failing
   it would fail every captured screen for the blank half of its own status
   line.

   And the callouts and captions, which are ordinary DOM text in the page
   around the figure: they are `--paper-dim` on `--panel`, they are the same on
   every figure, and axe already measures them where they are drawn.
   ========================================================================== */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';

const ROOT = process.argv[2] || 'content';

/* The palette, from the files that define it. */
const css = (path) => readFileSync(path, 'utf8');
const block = (text, selector) => {
  const at = text.indexOf(selector + '{');
  if (at < 0) throw new Error(`${selector} is not in the stylesheet any more`);
  const body = text.slice(at, text.indexOf('}', at));
  return Object.fromEntries(
    [...body.matchAll(/(--[a-z-]+):\s*(#[0-9a-f]{6})/g)].map((m) => [m[1], m[2]]));
};
const terminal = css('ui/assets/terminal.css');
const base = css('ui/assets/base.css');
const THEME = {
  dark: { ...block(base, ':root'), ...block(terminal, ':root') },
  light: {
    ...block(base, ':root'), ...block(terminal, ':root'),
    ...block(base, 'html[data-theme="light"]'), ...block(terminal, 'html[data-theme="light"]'),
  },
};

const AA = 4.5;

/* ==========================================================================
   WHAT IS STILL WRONG, WRITTEN DOWN RATHER THAN WAIVED.

   It is empty, and it was not: 204 runs of text in 52 hand-drawn figures of
   `web-fundamentals` were below AA when this tool was written. One defect
   repeated — an ACCENT USED AS BODY TEXT, the brand blue or the brand red on a
   fifth of itself — plus `--phosphor-dim`, which is that blue dimmed and reads
   2.48:1 as text. The tint and the border carry which kind of box it is; the
   label does not have to, and is `--paper` now.

   THE LIST STAYS BECAUSE THE RATCHET DOES. A file not on it may not fail at
   all. A file on it may not fail MORE than its number. And a file that fails
   FEWER times than its number fails this tool too, with the new number to put
   here — which is what emptied it, one entry at a time, rather than somebody
   remembering to. It is the same rule `check-css` holds its `deliberate` map
   to, and for the same reason: an exception that outlived what it excused
   reads as current.
   ========================================================================== */
const OUTSTANDING = {};


const luminance = (hex) => {
  const c = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
};
const contrast = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

/* What a fill attribute is worth in one theme. A `var()` this does not know is
   reported rather than skipped: it is the missing-token case CONTENT.md warns
   about, and it renders invisible. */
const value = (fill, theme) => {
  if (fill.startsWith('#')) return fill;
  const m = /^var\((--[a-z-]+)\)$/.exec(fill);
  if (!m) return null;
  return THEME[theme][m[1]] ?? null;
};

const files = [];
const pictures = [];
(function walk(dir) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) walk(path);
    else if (name.endsWith('.md')) files.push(path);
    /* AND THE DRAWINGS A `labelling` QUESTION NAMES, which are the same kind of
       picture kept in a different place — `figure-fit` walks these too and says
       why. Counting its figures against this tool's is what found them missing
       here: 303 against 302, and the one was a whole drawing nobody measured. */
    else if (name.endsWith('.svg') && dir.split(/[\\/]/).includes('images')) pictures.push(path);
  }
}(ROOT));

const problems = [];
let figures = 0;
let runs = 0;

const drawings = [];
for (const path of files.sort()) {
  for (const fence of readFileSync(path, 'utf8').matchAll(/```schooling-figure\n(.*?)\n```/gs)) {
    try {
      drawings.push([path, JSON.parse(fence[1]).svg]);
    } catch (e) {
      problems.push(`${path}: a schooling-figure fence is not JSON: ${e.message}`);
    }
  }
}
for (const path of pictures.sort()) drawings.push([path, readFileSync(path, 'utf8')]);

for (const [path, svg] of drawings) {
  figures += 1;

  /* THE GROUNDS. Attributes are read by name rather than by position, because
     the two kinds of figure in this catalogue write them in different orders: a
     capture emits x, y, width, height, fill, and a drawing puts `rx` and a
     stroke in the middle of that. */
  const attr = (tag, name) => {
    const m = new RegExp(`\\b${name}="([^"]*)"`).exec(tag);
    return m ? m[1] : null;
  };
  const rects = [];
  for (const r of svg.matchAll(/<rect\b[^>]*>/g)) {
    const [x, y, w, h] = ['x', 'y', 'width', 'height'].map((k) => Number(attr(r[0], k)));
    const fill = attr(r[0], 'fill');
    if (!fill || [x, y, w, h].some(Number.isNaN)) continue;
    const alpha = Number(attr(r[0], 'fill-opacity') ?? attr(r[0], 'opacity') ?? 1);
    rects.push([x, y, w, h, fill, Number.isNaN(alpha) ? 1 : alpha]);
  }

  /* WHAT IS ACTUALLY BEHIND A LETTER, which is not the last fill written there.
     A drawing's boxes are TINTS — `fill="var(--phosphor)" fill-opacity=".2"` —
     so the ground under a label is one fifth of the accent over the panel, and
     nothing like the accent itself. Reading the fill and ignoring the opacity
     reported 1682 unreadable runs on the first try, which is what a checker
     that nobody can believe looks like.

     So the rects covering the point are composited, in the order they are
     painted, starting from the panel. */
  const blend = (over, alpha, onto, theme) => {
    const a = value(over, theme);
    const b = value(onto, theme);
    if (a === null || b === null) return null;
    const mix = [1, 3, 5].map((i) => Math.round(
      parseInt(a.slice(i, i + 2), 16) * alpha + parseInt(b.slice(i, i + 2), 16) * (1 - alpha)));
    return `#${mix.map((v) => v.toString(16).padStart(2, '0')).join('')}`;
  };
  const under = (x, y, theme) => {
    let ground = 'var(--panel)';
    for (const [rx, ry, rw, rh, fill, alpha] of rects) {
      if (x < rx || x > rx + rw || y < ry || y > ry + rh) continue;
      ground = alpha >= 1 ? fill : blend(fill, alpha, ground, theme);
      if (ground === null) return null;
    }
    return ground;
  };

  const measure = (text, fg, at) => {
    runs += 1;
    for (const theme of ['dark', 'light']) {
      const bg = under(at[0], at[1], theme);
      const ink = value(fg, theme);
      const ground = bg === null ? null : value(bg, theme);
      if (ink === null || ground === null) {
        problems.push(`${path}: ${ink === null ? fg : String(bg)} resolves to nothing, so that `
          + 'run is drawn in no colour at all');
        continue;
      }
      const ratio = contrast(ink, ground);
      if (ratio < AA) {
        problems.push(`${path}: "${text.slice(0, 44)}" is ${fg} on ${bg}, `
          + `${ratio.toFixed(2)}:1 in the ${theme} theme where AA asks ${AA}`);
      }
    }
  };

  for (const line of svg.matchAll(/(<text\b[^>]*>)(.*?)<\/text>/gs)) {
    const [, open, body] = line;
    const y = Number(attr(open, 'y'));

    /* A CAPTURE SPLITS ITS ROW INTO RUNS and a DRAWING DOES NOT, and both are
       here. The first version read only `<tspan>`, so every drawn figure in the
       catalogue went unmeasured — thirteen of them in `web-fundamentals` lesson
       1 alone — and the count said 302 where `figure-fit` said 303.

       A CAPTURED ROW CARRIES ONE COORDINATE PER CHARACTER, and reading them is
       the only way to know where a run is now. The version before this looked
       for the `textLength` each run used to have; when that stopped being
       written the regex stopped matching, every captured figure fell through to
       the drawn path, found no `fill` on the `<text>`, and was skipped. The
       tool still said every figure was readable — of 1130 runs it had stopped
       looking at. A checker that passes by not measuring is the thing this file
       was written against. */
    const runsIn = [...body.matchAll(/<tspan\b[^>]*fill="([^"]+)"[^>]*>([^<]*)<\/tspan>/g)];
    const cells = (attr(open, 'x') || '').trim().split(/\s+/).map(Number);
    /* WHAT SEPARATES THE TWO IS THE RUNS, NOT THE LENGTH OF THE LIST. Requiring
       more than one coordinate here dropped every row a single character wide —
       290 of them — into the drawn path, where a `<text>` with no `fill` of its
       own is skipped. The count said 3830 where the figures hold 4120. */
    if (runsIn.length && cells.length && !Number.isNaN(cells[0])) {
      let at = 0;              // in cells, which is what the list is indexed by
      for (const [, fg, text] of runsIn) {
        /* AN ENTITY IS ONE CELL. `&#34;` is the quote a vim status line opens
           with, and counting its five letters walks the rest of the row along. */
        const shown = text.replace(/&#\d+;|&[a-z]+;/g, 'x');
        const from = at;
        at += shown.length;
        if (!shown.trim()) continue;   // padding carries no glyph
        /* THE GROUND A RUN SITS ON IS WHATEVER COVERS ITS MIDDLE, and the middle
           of the run is not the left edge of its middle CHARACTER. Reading the
           coordinate straight out of the list put the full stop after emacs's
           `C-h C-a` on the chip it comes after — a rectangle ends exactly where
           the next character begins, and both ends of a box count as inside
           it. The midpoint of the run's own extent has no such edge. */
        const left = cells[Math.min(from, cells.length - 1)];
        const right = cells[Math.min(at - 1, cells.length - 1)] + 7;
        measure(shown.trim(), fg, [(left + right) / 2, y - 11.5 + 1]);
      }
      continue;
    }

    const shown = body.replace(/<[^>]*>/g, '').replace(/&#\d+;|&[a-z]+;/g, 'x').trim();
    if (!shown) continue;
    const fg = attr(open, 'fill');
    if (!fg) continue;         // inherits, and nothing here sets a fill on a group
    measure(shown, fg, [Number(attr(open, 'x')), y]);
  }
}

/* The verdict, against the list above. */
const once = [...new Set(problems)];
const by = {};
for (const p of once) {
  const file = p.slice(0, p.indexOf(': '));
  (by[file] ||= []).push(p);
}

const wrong = [];
for (const [file, found] of Object.entries(by)) {
  const allowed = OUTSTANDING[file] ?? 0;
  if (found.length > allowed) {
    for (const p of found.slice(0, allowed ? found.length - allowed : found.length)) {
      wrong.push(` - ${p}`);
    }
    if (allowed) {
      wrong.push(` - ${file} is listed as having ${allowed} and has ${found.length}`);
    }
  }
}
for (const [file, allowed] of Object.entries(OUTSTANDING)) {
  const found = (by[file] || []).length;
  if (found < allowed) {
    wrong.push(` - ${file} is listed as having ${allowed} run(s) below AA and has ${found}. `
      + `Put ${found || 'nothing'} there — a list that overstates what is broken is a list `
      + 'nobody trusts the rest of.');
  }
}

if (wrong.length) {
  for (const w of wrong.slice(0, 40)) console.error(w);
  if (wrong.length > 40) console.error(` … and ${wrong.length - 40} more`);
  console.error(`\n${wrong.length} thing(s) to answer for. A figure is the one place in this `
    + 'catalogue where nothing else is looking: axe measures a DOM node against what is behind '
    + 'it, and a tspan over a rect is both of those inside an image.');
  process.exit(1);
}

const listed = Object.values(OUTSTANDING).reduce((a, b) => a + b, 0);
console.log(`${runs} runs of text in ${figures} figures, every one of them readable in both `
  + `themes${listed ? `, except ${listed} in ${Object.keys(OUTSTANDING).length} hand-drawn `
    + 'figures of web-fundamentals that this tool is holding at that number' : ''}`);
