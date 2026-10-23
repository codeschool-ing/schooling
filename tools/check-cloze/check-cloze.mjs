/* Command check-cloze draws every cloze in the catalogue with the screen's own
 * code and counts the boxes.
 *
 * # A HOLE THAT DRAWS AS SOMETHING ELSE IS A QUESTION NOBODY CAN ANSWER
 *
 * `ui/app/exercises/cloze.js` marks each `___` before it formats the sentence
 * and turns the marks into boxes after. `formatted()` in `ui/app/text.js` sets
 * code spans aside the same way, and for a while the two used the same mark,
 * so every hole in the catalogue came back as `<code>undefined</code>` — or as
 * another code span of the same prompt — and not one box was drawn. Nothing
 * failed: the grader is on the server and never sees the screen, and the page
 * renders a perfectly good sentence with a word missing. A render walk of one
 * course found it by reading the text.
 *
 * So every cloze, in every language its course has, goes through `body()`, and
 * the number of boxes has to be the number of holes the question has blanks
 * for, with no `undefined` anywhere in what was drawn.
 *
 *     node tools/check-cloze/check-cloze.mjs [content-dir]
 */
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

globalThis.txt = (s) => s; // the dictionary lookup the screen provides; English is the key
const { default: cloze } = await import('../../ui/app/exercises/cloze.js');

const ROOT = process.argv[2] || 'content';
const problems = [];
let drawn = 0;

function* files(dir) {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) yield* files(p);
    else if (/^(exercises|exam|.*-exam)\.json$/.test(e.name)) yield p;
  }
}

for (const file of files(ROOT)) {
  const questions = JSON.parse(readFileSync(file, 'utf8'));
  const ptFile = file.replace(/\.json$/, '.pt.json');
  const pt = existsSync(ptFile) ? JSON.parse(readFileSync(ptFile, 'utf8')) : {};
  for (const q of questions) {
    if (q.type !== 'cloze') continue;
    const versions = [['en', q]];
    if (pt[q.id]?.prompt) versions.push(['pt', { ...q, ...pt[q.id], blanks: q.blanks }]);
    for (const [lang, ex] of versions) {
      const html = cloze.body(ex, 'x');
      drawn++;
      const holes = (ex.prompt.match(/___/g) || []).length;
      const want = Math.min(holes, (ex.blanks || []).length);
      const boxes = (html.match(/<input /g) || []).length;
      if (boxes !== want) problems.push(`${file} ${q.id} [${lang}]: ${want} box(es) expected, ${boxes} drawn`);
      if (html.includes('undefined') && !ex.prompt.includes('undefined')) problems.push(`${file} ${q.id} [${lang}]: "undefined" on screen`);
    }
  }
}

if (problems.length) {
  console.log(problems.slice(0, 40).map((p) => ' - ' + p).join('\n'));
  console.log(`\n${problems.length} problem(s) across ${drawn} drawn clozes.`);
  process.exit(1);
}
console.log(`${drawn} clozes drawn, every hole a box`);
