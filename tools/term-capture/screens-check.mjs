/*
   EVERY RE-TAKEN SCREEN AGAINST THE ONE ALREADY PUBLISHED.

   `screens.sh` says what was typed at each of the catalogue's captured screens.
   This says whether typing it again produces the screen that is in the lesson —
   which is the only thing that makes re-taking one safe. A figure is quoted by
   the paragraph beside it: `server.conf` is six lines and 101 bytes, the ruler
   reads `1,1`, vim's undo message says `1 second ago`. A screen that comes back
   slightly different does not announce itself; it just stops matching the
   prose, in a file nobody reads again.

   SO EXACTLY ONE DIFFERENCE IS ALLOWED, AND IT IS THE CURSOR. One cell may
   change colour — the block the terminal paints where the program left it, and
   the reason these screens were taken again at all. No character may move.

   It found four wrong recipes and one wrong cause on its first run:

     - `~/.viminfo` made the screens depend on the ORDER they were taken in,
       because Debian's vimrc returns to the line you last held in a file. A
       capture after `:%s/log/LOG/g` opened at line 6 and its ruler said so.
     - emacs had not finished painting after a two-second warmup, so the figure
       was a blank terminal, and `term-capture` reported success.
     - `cwvm2` sent as one string lost its last character on a read-only buffer,
       and with it the `:w` whose error the lesson is about.
     - vim's undo message has a clock in it.

   THIS DOES NOT RUN IN CI, and it is not an oversight. It compares against
   screens taken on ana's machine, which is the machine the lessons describe;
   there is no copy of it on a runner. It is run by hand, beside `screens.sh`,
   on the machine where the photographs are taken.

     node tools/term-capture/screens-check.mjs /tmp/screens
*/
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const LESSONS = 'content/code/courses/linux-terminal/lessons';
const WIDTH = 100;

/* The figure each name in `screens.sh` is, as the file it lives in and its
   position in that file. A name that is not here is a screen nobody published,
   and a figure not named here is one `screens.sh` does not know how to take. */
const WHERE = {
  'vim-modes-0': ['vim-modes.md', 0],
  'vim-modes-1': ['vim-modes.md', 1],
  'vim-modes-2': ['vim-modes.md', 2],
  'vim-moving-0': ['vim-moving.md', 0],
  'vim-survival-0': ['vim-survival.md', 0],
  'vim-survival-1': ['vim-survival.md', 1],
  'vim-editing-0': ['vim-editing.md', 0],
  'vim-editing-1': ['vim-editing.md', 1],
  'vim-editing-2': ['vim-editing.md', 2],
  'vim-editing-3': ['vim-editing.md', 3],
  'vim-sr-0': ['vim-search-and-replace.md', 0],
  'vim-sr-1': ['vim-search-and-replace.md', 1],
  'vim-sr-2': ['vim-search-and-replace.md', 2],
  'vim-config-0': ['vim-config.md', 0],
  'vim-files-0': ['vim-files.md', 0],
  'vim-files-1': ['vim-files.md', 1],
  'vim-files-2': ['vim-files.md', 2],
  'vim-files-3': ['vim-files.md', 3],
  'vim-files-4': ['vim-files.md', 4],
  'vim-files-5': ['vim-files.md', 5],
  'vim-files-6': ['vim-files.md', 6],
  'nano-0': ['nano.md', 0],
  'nano-1': ['nano.md', 1],
  'nano-2': ['nano.md', 2],
  'nano-3': ['nano.md', 3],
  'emacs-0': ['emacs.md', 0],
  'emacs-1': ['emacs.md', 1],
};

/* A screen with a clock or a process id in it cannot come back identical, and
   saying which lines those are is better than loosening the rule for everything.
   `vim-survival-1` is the E325 screen: two timestamps and the pid of the vim
   that was killed to produce it. */
const INHERENTLY_NEW = { 'vim-survival-1': [2, 6, 8] };

const lessonFiles = (() => {
  const out = {};
  for (const dir of readdirSync(LESSONS)) {
    for (const file of readdirSync(join(LESSONS, dir))) out[file] = join(LESSONS, dir, file);
  }
  return out;
})();

const figures = (name) =>
  [...readFileSync(lessonFiles[name], 'utf8').matchAll(/```schooling-figure\n(.*?)\n```/gs)]
    .map((m) => JSON.parse(m[1]).svg);

/* The screen as cells, which is the only shape the two can be compared in.

   A figure is drawn as grounds and runs: a `<rect>` per stretch of background
   and a `<tspan>` per stretch of one foreground. Neither is per cell, and both
   are laid out by arithmetic this file has to invert — geometry from
   `term-capture`, and the reason a wrong constant there would show up here as
   a whole screen having moved. */
const ORIGIN_X = 40;
const ORIGIN_Y = 14;
const CHAR = 7;
const LINE = 15.5;

const unescape = (s) =>
  s.replace(/&#(\d+);/g, (_, d) => String.fromCharCode(+d))
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&amp;/g, '&');

function cells(svg) {
  // The rows are the `<text>`s, counted before anything is placed: a screen is
  // as tall as it was captured at, and a row the program left blank has neither
  // a ground nor a run to announce it. Sizing from whichever element came first
  // leaves holes in the middle of the array.
  const lines = [...svg.matchAll(/<text\b([^>]*)>(.*?)<\/text>/gs)].filter((m) => /xml:space/.test(m[1]));
  const rows = lines.map(() => Array.from({ length: WIDTH }, () => ({ ch: ' ', fg: null, bg: null })));
  const at = (y) => rows[y] || Array.from({ length: WIDTH }, () => ({ ch: ' ', fg: null, bg: null }));

  for (const m of svg.matchAll(/<rect x="([\d.]+)" y="([\d.]+)" width="([\d.]+)" height="[\d.]+" fill="([^"]+)"\/>/g)) {
    const x = Math.round((+m[1] - ORIGIN_X) / CHAR);
    const y = Math.round((+m[2] - ORIGIN_Y) / LINE);
    const wide = Math.round(+m[3] / CHAR);
    for (let i = 0; i < wide; i++) if (x + i < WIDTH) at(y)[x + i].bg = m[4];
  }

  for (const [y, row] of lines.entries()) {
    let x = 0;
    for (const run of row[2].matchAll(/<tspan([^>]*)>(.*?)<\/tspan>/gs)) {
      const fg = (run[1].match(/fill="([^"]*)"/) || [, null])[1];
      for (const ch of unescape(run[2])) {
        if (x < WIDTH) Object.assign(at(y)[x], { ch, fg });
        x += 1;
      }
    }
  }
  return rows;
}

const where = process.argv[2];
if (!where) {
  console.error('usage: screens-check.mjs DIRECTORY-OF-RETAKEN-SVGS');
  process.exit(2);
}

let wrong = 0;
let cursors = 0;
for (const [name, [file, index]] of Object.entries(WHERE).sort()) {
  let taken;
  try {
    taken = readFileSync(join(where, `${name}.svg`), 'utf8');
  } catch {
    console.log(`${name.padEnd(16)} not taken`);
    wrong += 1;
    continue;
  }
  const was = cells(figures(file)[index]);
  const now = cells(taken);
  if (was.length !== now.length) {
    console.log(`${name.padEnd(16)} ${was.length} rows published, ${now.length} taken`);
    wrong += 1;
    continue;
  }

  const allowed = INHERENTLY_NEW[name] || [];
  const moved = [];
  const painted = [];
  for (let y = 0; y < was.length; y++) {
    if (allowed.includes(y)) continue;
    for (let x = 0; x < WIDTH; x++) {
      const a = was[y][x];
      const b = now[y][x];
      if (a.ch !== b.ch) {
        moved.push(`${x},${y} ${JSON.stringify(a.ch)}->${JSON.stringify(b.ch)}`);
        continue;
      }
      // A SPACE'S FOREGROUND PAINTS NOTHING, so it is not a difference. It comes
      // up because trailing padding is only trimmed after the last cell that
      // paints: a cursor at the end of a row keeps the spaces before it, and
      // they arrive carrying whatever colour their run had. Two cells looked
      // repainted on emacs's echo line for exactly that reason, and only one of
      // them was the cursor.
      if (a.ch === ' ' && a.bg === b.bg) continue;
      if (a.fg !== b.fg || a.bg !== b.bg) painted.push(`${x},${y}`);
    }
  }

  if (moved.length === 0 && painted.length <= 1) {
    // Zero is the ordinary answer once the lessons carry the cursor: taking the
    // screen again gives back exactly the figure that is in them. One is the
    // answer while a figure predates the cursor, and it says where the block is.
    const note = painted.length ? `matches, and gains a cursor at ${painted[0]}` : 'matches the lesson';
    console.log(`${name.padEnd(16)} ${note}${allowed.length ? `, apart from ${allowed.length} line(s) that cannot repeat` : ''}`);
    cursors += painted.length;
    continue;
  }
  wrong += 1;
  console.log(`${name.padEnd(16)} NOT THE SAME SCREEN` +
    (moved.length ? `\n  text moved: ${moved.slice(0, 4).join('  ')}${moved.length > 4 ? ` … ${moved.length} cells` : ''}` : '') +
    (painted.length > 1 ? `\n  ${painted.length} cells repainted: ${painted.slice(0, 6).join('  ')}` : ''));
}

const total = Object.keys(WHERE).length;
if (wrong) {
  console.log(`\n${wrong} of ${total} screen(s) came back different from the one published`);
  process.exit(1);
}
console.log(`\n${total} screens, each the one the lesson publishes` +
  (cursors ? `, ${cursors} of them plus a cursor the figure does not have yet` : ''));
