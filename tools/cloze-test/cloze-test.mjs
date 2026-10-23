/* Command cloze-test draws every cloze in the catalogue the way the screen
 * does, and counts the boxes.
 *
 * # A HOLE THAT DRAWS AS TEXT IS A QUESTION NOBODY CAN ANSWER, AND IT IS SILENT
 *
 * `cloze.js` turns each `___` of a prompt into a marker, formats the sentence,
 * and turns each marker into an input. `formatted()` in `ui/app/text.js` sets
 * its code spans aside with a marker of its own. When the two markers were the
 * same string, `formatted()` read every hole as a code span it had stored and
 * drew it as `<code>undefined</code>`: no box, so no answer, in every cloze
 * whose prompt has a hole outside a code span. It renders as a sentence with a
 * word in it, so nothing failed, and the walk of `java-functional` found it by
 * reading the screen.
 *
 * So this asks the real module, imported rather than copied, for the markup of
 * every cloze prompt in English and in each translation, and demands one box
 * per hole that has a blank behind it, and no marker or `undefined` left over.
 * It needs no browser and no database: `cloze.js` is a function from a question
 * to a string.
 *
 *     node tools/cloze-test/cloze-test.mjs [content-dir]
 */
import fs from 'node:fs';
import path from 'node:path';

// The screen's dictionary lookup. Only the boxes' labels use it, and the
// label's words are not what this measures.
globalThis.txt = (s) => s;
const { default: cloze } = await import('../../ui/app/exercises/cloze.js');

const root = process.argv[2] || 'content';

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.json')) out.push(p);
  }
  return out;
}

const isQuestionFile = (f) => /(^|[-/])(exercises|exam)(\.[a-z]{2}(-[A-Za-z]{2})?)?\.json$/.test(f);

const problems = [];
let drawn = 0;

function check(where, prompt, blanks) {
  const holes = (prompt.match(/___/g) || []).length;
  const html = cloze.body({ prompt, blanks }, 'u');
  const boxes = (html.match(/<input /g) || []).length;
  const want = Math.min(holes, blanks.length);
  drawn++;
  if (boxes !== want) problems.push(`${where}: ${boxes} box(es) drawn for ${want} hole(s)`);
  if (/[\u0000\u0001]/.test(html)) problems.push(`${where}: a marker reached the markup`);
  // Counted, not searched for: a prompt about JavaScript may say `undefined`
  // itself, and only one the prompt did not write is a hole drawn as text.
  const said = (s) => (s.match(/undefined/g) || []).length;
  if (said(html) > said(prompt)) problems.push(`${where}: a hole was drawn as "undefined"`);
}

for (const file of walk(root).filter(isQuestionFile).sort()) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!Array.isArray(data)) continue; // a translation, read beside its English below
  const english = data.filter((q) => q && q.type === 'cloze');
  if (english.length === 0) continue;
  for (const q of english) check(`${file} ${q.id}`, q.prompt || '', q.blanks || []);

  const base = file.replace(/\.json$/, '');
  for (const other of fs.readdirSync(path.dirname(file))) {
    const full = path.join(path.dirname(file), other);
    if (!full.startsWith(base + '.') || full === file || !full.endsWith('.json')) continue;
    const tr = JSON.parse(fs.readFileSync(full, 'utf8'));
    for (const q of english) {
      const t = tr[q.id];
      if (!t || typeof t.prompt !== 'string') continue;
      check(`${full} ${q.id}`, t.prompt, q.blanks || []);
    }
  }
}

if (drawn === 0) {
  console.error(`cloze-test: no cloze found under ${root}, so nothing was measured`);
  process.exit(1);
}
if (problems.length) {
  for (const p of problems.slice(0, 40)) console.error(' - ' + p);
  if (problems.length > 40) console.error(` … and ${problems.length - 40} more`);
  console.error(`cloze-test: ${problems.length} of ${drawn} cloze prompt(s) do not draw their boxes`);
  process.exit(1);
}
console.log(`${drawn} cloze prompt(s), every hole a box`);
