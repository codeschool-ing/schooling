/* Command check-highlight reads every code fence in the catalogue and asks the
 * highlighter what it would do with it.
 *
 * # A LABEL NOBODY TAUGHT THE HIGHLIGHTER IS A GREY LESSON, AND IT IS SILENT
 *
 * `highlight()` returns plain escaped text for a language it does not know.
 * That is the right behaviour — colouring a language by guessing is how you get
 * the wrong text — but it means a fence marked ```pyton, or ```rust in a course
 * nobody has taught this file about, renders perfectly: correct content, right
 * font, no colour, no error anywhere. It has happened once already in this
 * repository, for a whole course: HTML and CSS were taught in `code` blocks
 * while only `example` blocks were highlighted, and thirty snippets sat in one
 * grey until somebody looked at the screen.
 *
 * So the check is the obvious one, and it is only possible from here: the
 * catalogue's fences on one side, the table in `ui/app/text.js` on the other,
 * imported rather than copied, because a list transcribed into a second
 * language is a list that will disagree.
 *
 * # AND THE TEXT ITSELF, WHICH MATTERS MORE THAN THE COLOUR
 *
 * Every rule added here is a regular expression running over 2,000 real blocks,
 * and the failure that would cost the most is not a missing colour: it is a
 * character eaten or doubled on the way through. So every block is highlighted
 * and then read back — spans stripped, entities decoded — and has to be the
 * file's own bytes again. A student copying a command that lost its quote would
 * find out in their terminal.
 *
 *     node tools/check-highlight/check-highlight.mjs [content-dir]
 */
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { highlight, LANGUAGES } from '../../ui/app/text.js';

const ROOT = process.argv[2] || 'content';
const problems = [];
const say = (where, what) => problems.push(`${where}: ${what}`);

/* The fence's own markers are content in `schooling-figure` and friends: those
   are JSON blocks with a reader of their own, and `validate-content` is what
   reads them.

   `schooling-example` IS THE EXCEPTION, because it carries a language too — in
   a `language` field inside the JSON rather than after the backticks — and it
   reaches the same `highlight()` call. No content writes one yet; the first
   arrives with the JavaScript course, and a check that only looked at fences
   would go on passing while the block the whole course is written in came out
   grey. */
const OURS = /^schooling-(?!example$)/;

/* Each snippet of an annotated example is highlighted on its own, exactly as
   the renderer does it, because a snippet is what the rules actually see: the
   program is cut into pieces and a rule that needs the line before it has
   already lost. */
function example(path, at, json) {
  try {
    const block = JSON.parse(json);
    return (block.parts || []).map((p) => ({
      path, line: at, lang: block.language || '', text: String(p.code ?? ''),
    }));
  } catch {
    return [];   // a malformed block is `validate-content`'s to report
  }
}

function fences(dir) {
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true, recursive: true })) {
    if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
    const path = join(entry.parentPath ?? entry.path, entry.name);
    const lines = readFileSync(path, 'utf8').split('\n');
    let open = null;
    let body = [];
    let at = 0;
    lines.forEach((line, n) => {
      if (!line.startsWith('```')) {
        if (open !== null) body.push(line);
        return;
      }
      if (open === null) {
        open = line.slice(3).trim();
        at = n + 1;
        body = [];
        return;
      }
      if (open === 'schooling-example') out.push(...example(path, at, body.join('\n')));
      else if (!OURS.test(open)) out.push({ path, line: at, lang: open, text: body.join('\n') });
      open = null;
    });
  }
  return out;
}

/* What the browser would read back out of the element, which is what the copy
   button hands the student. */
const plain = (html) => html
  .replace(/<span class="t-[a-z]+">/g, '').replace(/<\/span>/g, '')
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
  .replace(/&#39;/g, "'").replace(/&amp;/g, '&');

const known = new Set(LANGUAGES);
const coloured = new Set();
const seen = new Set();

const all = fences(ROOT);
if (!all.length) {
  console.error(`no code fence under ${ROOT}/ — either the path is wrong or this checked nothing`);
  process.exit(1);
}

for (const f of all) {
  const where = `${f.path}:${f.line}`;

  if (f.lang && !known.has(f.lang.toLowerCase())) {
    say(where, `the fence is labelled \`${f.lang}\`, which the highlighter has never heard of — `
      + 'the block will render in one grey and nothing will say so. Add it to `RULES` or `ALIAS` '
      + 'in ui/app/text.js, or correct the label');
    continue;
  }
  seen.add(f.lang.toLowerCase());

  const html = highlight(f.text, f.lang);
  if (plain(html) !== f.text) {
    say(where, 'highlighting changed the text. What the student copies out of this block is no '
      + 'longer what the file says');
    continue;
  }
  if (/class="t-/.test(html)) coloured.add(f.lang.toLowerCase());
}

/* A LANGUAGE CAN BE REGISTERED AND STILL DO NOTHING. A rule set whose
   expression is wrong compiles, matches nothing, and reads as "that course is
   not colourful, I suppose". If the catalogue teaches a language, at least one
   of its blocks has to come out with a colour in it. */
for (const lang of seen) {
  if (!coloured.has(lang)) {
    say('ui/app/text.js', `${all.filter((f) => f.lang.toLowerCase() === lang).length} block(s) are `
      + `labelled \`${lang || '(none)'}\` and not one came out with a colour in it — the rules are `
      + 'registered but they match nothing');
  }
}

/* ---------- and the claims that no content file happens to make ----------

   THE TRANSCRIPTS ARE THE REASON THIS TOOL EXISTS at all: they carry no label,
   so nothing above would notice the day they stopped being recognised. Each of
   these is a thing the highlighter promises and a thing that has a way to go
   quietly wrong. */
const claims = [
  ['a prompt is what marks a transcript',
    'ana@vm:~/work$ ls -l', '', (h) => h.startsWith('<span class="t-com">ana@vm:~/work$ </span>')],
  ['the root prompt counts too',
    'root@vm:~# id', '', (h) => h.startsWith('<span class="t-com">root@vm:~# </span>')],
  ['and PowerShell\'s — escaped, because the prompt ends in a character HTML wants',
    'PS /home/ana> $x = 1', '', (h) => h.startsWith('<span class="t-com">PS /home/ana&gt; </span>')],
  ['what the machine answers is left alone',
    'ana@vm:~$ free -h\ntotal        used        free\n7.6Gi       2.1Gi       1.2Gi',
    '', (h) => h.split('\n').slice(1).every((l) => !l.includes('class="t-'))],
  ['a comment at the top of a file is not a root prompt',
    '# the file this machine reads at boot\nroot=/dev/sda1', '', (h) => !h.includes('class="t-')],
  ['a drawing in a bare fence is not a screen recording',
    '┌──────────┐\n│ a buffer │\n└──────────┘', '', (h) => !h.includes('class="t-')],
  ['a keyword inside a string is a string',
    'x = "const"', 'js', (h) => !h.includes('>const<')],
  ['a language nobody registered comes out plain, not broken',
    'fn main() {}', 'rust', (h) => h === 'fn main() {}'],
  /* A tag inside a highlighted block is text and has to come out as text — and
     the ampersand of an entity the author wrote has to be escaped a second time
     or the browser eats it and shows `&`. */
  ['and the escaping still happens exactly once',
    '<p>&amp;</p>', 'html',
    (h) => plain(h) === '<p>&amp;</p>' && !/<(?!\/?span)/.test(h) && h.includes('&amp;amp;')],
  ['the command after a pipe is a command',
    'dmesg -T | grep -i oom', 'sh', (h) => h.includes('| grep')],
  ['a section is the structure of a unit file',
    '[Timer]\nOnCalendar=daily', 'ini', (h) => h.includes('>[Timer]<')],
];

for (const [claim, text, lang, holds] of claims) {
  if (!holds(highlight(text, lang))) {
    say('ui/app/text.js', `${claim} — and it does not:\n     ${JSON.stringify(highlight(text, lang))}`);
  }
}

if (problems.length) {
  for (const p of problems) console.error(` - ${p}`);
  console.error(`\n${problems.length} problem(s). A fence the highlighter does not know is a `
    + 'lesson served in one grey, and nothing else in this repository looks at one.');
  process.exit(1);
}

console.log(`${all.length} fences, ${seen.size} labels, all of them coloured by rules this `
  + 'file imported rather than copied');
