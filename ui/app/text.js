/* ==========================================================================
   Text — escaping and the bare minimum of markup.

   Exercise content uses backticks for code all the time (`pip list`, `9 // 2`,
   `sqrt(x**2)`), and code snippets contain `<`, `>` and `&`. So escaping is not
   security fussiness: without it an exercise about comparison in SQL simply
   disappears from the screen.
   ========================================================================== */

export const esc = (s) => String(s ?? '')
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

/* ==========================================================================
   A count and the noun it counts.

   # "1 TRILHAS"

   Screens across this interface wrote `n + ' ' + txt('tracks')`, which is right
   for every number except the one a student is most likely to meet. A course in
   one track said "in 1 tracks"; a course with one lesson said "1 lessons".
   Portuguese forgives it no more than English does, and it is the kind of
   wrongness that makes a page look machine-made — which is the one thing a
   catalogue is trying not to look like.

   # THE TRANSLATION HAPPENS AT THE CALL SITE, AND THAT IS NOT A STYLE CHOICE

   The obvious signature is `counted(n, 'track', 'tracks')`, calling `txt` in
   here. It would break the tooling. `check-interface` finds what this interface
   says by matching `txt(` with EXACTLY ONE quoted string inside it, so words
   passed to a helper as bare literals are invisible to the scan: they would go
   untranslated, and the check whose entire job is to catch that would report
   nothing wrong.

   So both words arrive already translated, from two separate `txt` calls the
   scanner can see. The same rule rules out `txt(n === 1 ? 'track' : 'tracks')`.

   # WHAT IT DELIBERATELY DOES NOT TOUCH

   A FRACTION. `3/8 sections` is not a count of one even when the numerator is,
   and "1/8 section" would be wrong the other way. Those stay as they are, on
   the dashboard, in the rail and on the graph's nodes.

   AND IT IS NOT A PLURAL RULE. Two forms is what English and Portuguese need
   for these nouns. A language with more would want `Intl.PluralRules` and a
   dictionary keyed by category, which is a different piece of work and one
   nothing here is asking for yet.
   ========================================================================== */
export function counted(n, one, many) {
  return n + ' ' + (n === 1 ? one : many);
}

/* `backticks` become <code>, **bold** becomes <strong>. Nothing else — this is
   not Markdown, it is the subset the content actually uses. It escapes BEFORE
   marking up, or the markup would be escaped along with everything else and
   come out literal on screen. */
export function formatted(s) {
  return esc(s)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    /* LAZY, AND ALLOWING ASTERISKS INSIDE, so that `**the two *jobs*.**` — bold
       with an italic within it, which lesson one writes — is one bold span
       rather than no match at all. `[^*]+` refused it, and then the italic rule
       below matched across the opening `**` and produced a stray asterisk on
       screen. Lazy is what keeps `**a** and **b**` two spans and not one. */
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    /* `**bold**` FIRST AND `*italic*` SECOND, which is what lets this pattern
       be as simple as it is: by the time it runs, every doubled asterisk is
       already a tag, so a lone `*` is unambiguous. The other order turns
       `**a**` into `<em></em>a<em></em>`.

       Italic was missing altogether, and 34 lines of lesson one were showing
       their asterisks to students.

       WHERE THE SUBSET STOPS, said out loud rather than discovered: `**a *b***`
       — a bold span ending the instant an italic inside it does — comes out
       mis-nested, because these are two passes and not a parser. `***a***` is
       the same case. No content file writes either (checked: zero occurrences),
       the shape the content DOES write is `**a *b*.**`, which is correct here,
       and the day one is wanted is the day this becomes a parser rather than
       the day a third regular expression is added. */
    .replace(/\*([^*\n]+)\*/g, '<em>$1</em>');
}

/* ---------- copying the code ----------

   THE BUTTON COPIES A PROGRAM, NOT A SCREEN REGION. In an `example` the code is
   deliberately cut into snippets with a note beside each one, and that is the
   whole point of the block — but nobody wants a third of a program. So the
   button gathers EVERY snippet of the block, in order, and hands over the file
   as it would be written. It is what gobyexample.com does, and it is the same
   argument the block itself makes: the right column is one file.

   The output of an `example` is not copyable. It is what the program prints,
   not something anyone pastes into an editor — offering it would be offering
   the wrong half.

   `textContent` is what reads the code back, and that is deliberate rather than
   convenient: the snippets go through `highlight()` and come out wrapped in
   `<span>`s, so anything reading `innerHTML` would paste markup. The browser
   also decodes the entities `esc()` wrote, which is exactly the round trip we
   want — what is copied is what the author typed. */
const ICON_COPY = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" ' +
  'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
  '<rect x="9" y="9" width="11" height="11" rx="2"/>' +
  '<path d="M5 15H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v1"/></svg>';

const ICON_COPIED = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
  'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>';

export const copyButton = () =>
  '<button type="button" class="code-copy" data-copy ' +
    'title="' + txt('Copy the code') + '" aria-label="' + txt('Copy the code') + '">' +
    ICON_COPY + '</button>';

export const COPY_ICONS = { copy: ICON_COPY, copied: ICON_COPIED };

/* ---------- a code block is a window ----------

   THE BAR WAS ALREADY THERE AND HALF OF IT WAS EMPTY: the language on the left,
   the copy button on the right, and no language at all on the 1,391 terminal
   recordings of `linux-terminal`. A tab on the left and three dots on the right
   is what that strip already looked like — see `assets/code-window.css` for why
   the dots are `--wire` and not another system's red, amber and green.

   THE TITLE IS NOT INVENTED, and that is the part worth reading twice. A
   terminal tab shows the user, the machine and the directory, and a transcript
   already carries all three on its first line: `ana@vm:~/work$` becomes
   `ana@vm: ~/work`. A block with a language shows the language, as the bar did.
   A block with neither — a file's contents, a drawing in box characters — gets
   NO TAB, because a window titled `output` when nobody said so is a label that
   claims to know something.

   THE DOTS ARE `<i>` AND `aria-hidden`. They are the shape of a window, not a
   control: a student who tabs to a close button that closes nothing has been
   lied to, and three unlabelled buttons is what a screen reader would otherwise
   read out before every snippet in the course. */
const ICON_TERMINAL = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
  'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
  '<path d="m4 17 6-5-6-5"/><path d="M12 19h8"/></svg>';

const ICON_FILE = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
  'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">' +
  '<path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/>' +
  '<path d="M14 3v5h5"/></svg>';

const WINDOW_DOTS = '<span class="win-dots" aria-hidden="true"><i></i><i></i><i></i></span>';

/* `user@host:path$ ` and `PS <path>> `, which is every prompt the catalogue
   writes. The bare `$ ` has no machine in it and falls through to the shell's
   own name, which is the only true thing left to say about it. */
const TAB_UNIX = /^([\w.-]+)@([\w.-]+):(\S*?)[$#] /;
const TAB_POWERSHELL = /^(PS [^>\n]*)> /;
const SHELLS = new Set(['sh', 'bash', 'zsh', 'shell', 'console', 'terminal']);

export function windowOf(text, language) {
  const raw = String(text ?? '');
  const unix = TAB_UNIX.exec(raw);
  if (unix) return { title: unix[1] + '@' + unix[2] + ': ' + unix[3], terminal: true };
  const ps = TAB_POWERSHELL.exec(raw);
  if (ps) return { title: ps[1], terminal: true };

  const name = String(language || '').trim();
  if (isTranscript(raw)) return { title: name || 'sh', terminal: true };
  return { title: name, terminal: SHELLS.has(name.toLowerCase()) };
}

/* `trailing` IS THE COPY BUTTON, in every block that has one. It goes in the
   same row as the dots and is CENTRED ON THEM: the two are the only things at
   that end of the bar, and one riding five pixels above the other is the sort
   of thing you cannot unsee once you have seen it. That is what `.win-right` is
   for — a line of its own, so the alignment is a property of the row and not
   arithmetic on two margins and two heights.

   IT IS ALWAYS THERE AND IT IS ALWAYS HERE. A version of this floated it over
   the code, hidden until the pointer arrived; a course is read block after
   block, and a control that is in the bar in one and floating in the next is
   two things to learn for one action. See `assets/code-window.css`. */
export function codeBar(text, language, trailing) {
  const { title, terminal } = windowOf(text, language);
  return '<div class="code-bar">' +
    (title
      ? '<span class="win-tab"><span class="win-icon" aria-hidden="true">' +
          (terminal ? ICON_TERMINAL : ICON_FILE) + '</span>' + esc(title) + '</span>'
      : '') +
    '<span class="win-right">' + (trailing || '') + WINDOW_DOTS + '</span>' +
  '</div>';
}

/* The prose of a lesson section. Ten block forms, and nothing beyond them:

     'text'                        → paragraph, with `code`, **bold**, *italic*
     ['a', 'b']                    → bullet list
     { ordered: ['a', 'b'] }       → numbered list
     { heading: 'Roles', level }   → a heading inside the section
     { table: { head, rows } }     → a comparison table
     { quote: 'said' }             → a quotation
     { code: 'css', text: … }     → code block
     { image: url, caption, alt }  → figure
     { svg: '<svg…>', caption }    → diagram drawn right here
     { example: { … } }            → annotated code, Go By Example style

   FOUR OF THOSE ARRIVED LATE AND THE CONTENT HAD BEEN WRITING THEM ALL ALONG.
   Heading, table, numbered list and quotation are ordinary markdown, `blocksOf`
   did not recognise them, and everything it does not recognise is a paragraph —
   so a student read `## The two roles` with the hashes in it and a comparison
   table as a run of pipes. Nothing could report that: a paragraph is valid
   markup with good contrast whatever it happens to say.

   The code block arrived when the first PRACTICAL course was written. In
   `web-fundamentals`, which is conceptual, a backtick mid-sentence was enough;
   in `html-css` there is no way to teach a selector without showing it over
   three lines with the indentation intact. The content asked for it, the
   architecture did not foresee it — and that is why the shape is still only
   what the content uses.

   It reuses `.code-block`, the same component the exercises use: code looks the
   same wherever it shows up in the portal.

   Deliberately not Markdown. The real content will come from a database in
   Stage 2, and inventing a dialect now would only create a migration.

   The block keys stay in Portuguese because they are content-file fields, and
   the content files are written by the school. */
export function prose(body) {
  if (!body || !body.length) return '';
  return body.map((block) => {
    if (Array.isArray(block)) {
      return '<ul class="prose-list">' + block.map((i) => '<li>' + formatted(i) + '</li>').join('') + '</ul>';
    }
    if (block && typeof block === 'object') {
      if (block.example) return annotatedExample(block.example);
      if (block.image || block.svg) return figure(block);
      if (block.heading !== undefined) {
        const n = Math.min(Math.max(block.level || 3, 3), 6);
        return '<h' + n + ' class="prose-heading">' + formatted(block.heading) + '</h' + n + '>';
      }
      if (block.ordered) {
        return '<ol class="prose-ordered">' +
          block.ordered.map((i) => '<li>' + formatted(i) + '</li>').join('') + '</ol>';
      }
      if (block.quote !== undefined) {
        return '<blockquote class="prose-quote">' + formatted(block.quote) + '</blockquote>';
      }
      if (block.table) return table(block.table);
      if (block.text !== undefined) {
        /* NOT `formatted`: inside a code block a backtick is a backtick and an
           asterisk is an asterisk — marking them up would eat the code itself.

           It goes through `highlight()` for the same reason the `example` block
           does, and it did not before. The effect of that was one course being
           coloured and another not: JavaScript is taught in `example` blocks,
           which were highlighted, while HTML and CSS are taught in these, which
           were not — thirty snippets in one grey. `highlight()` escapes what it
           returns, and falls back to plain escaped text for a language it does
           not know, so a block with no label is exactly what it was.

           The bar renders even with no language to show: it is the window's,
           and a block you cannot copy because its author left the label out
           would be an odd thing to explain. */
        return '<div class="code-block code-win prose-code">' +
          codeBar(block.text, block.code === LOCALISED ? '' : block.code, copyButton()) +
          '<pre class="code"><code>' + highlight(block.text, block.code) + '</code></pre>' +
        '</div>';
      }
    }
    return '<p>' + formatted(block) + '</p>';
  }).join('');
}

/* ---------- table ----------

   IT SCROLLS INSIDE ITS OWN BOX AND THE PAGE DOES NOT. A comparison table has
   as many columns as the comparison has sides, and the reading column is
   narrower than the widest of them on a phone. The choice is a table that
   scrolls sideways or a page that does, and a page that scrolls sideways takes
   every other screen with it.

   A HEADER CELL MAY BE EMPTY, which is what the corner of a comparison table
   is: the rows are the property and the columns are the thing, so the top-left
   names neither. It is still a `<th>` — the column below it has a header even
   when the corner has no word — and `scope` is what tells a screen reader which
   direction each one governs. */
function table(t) {
  const head = '<thead><tr>' +
    (t.head || []).map((c) => '<th scope="col">' + formatted(c) + '</th>').join('') +
  '</tr></thead>';
  const body = '<tbody>' + (t.rows || []).map((r) =>
    '<tr>' + r.map((c, at) =>
      (at === 0
        ? '<th scope="row">' + formatted(c) + '</th>'
        : '<td>' + formatted(c) + '</td>')).join('') +
    '</tr>').join('') + '</tbody>';
  return '<div class="prose-table-wrap"><table class="prose-table">' + head + body + '</table></div>';
}

/* ---------- figure ----------

   TWO FORMS, and the difference is not style: it is where the pixel comes from.

   `image` is a file — a screenshot, a photo, an exported diagram. It is what
   the real content will use, served from a CDN.

   `svg` is a drawing WRITTEN HERE, which enters the document and therefore
   inherits the theme's colours. A diagram exported as a PNG is born with a
   background, and that background is wrong on half the visits — the portal has
   a light and a dark theme, and students switch. A concept diagram, which is
   lines and labels, is better inline.

   The `svg` is NOT escaped: it is our own markup, written in the content file,
   like the track graph. If content ever comes from outside, this is the field
   that needs sanitising — and this comment exists so the question does not slip
   by on the day that happens. */
function figure(b) {
  const body = b.svg
    ? '<div class="fig-svg">' + b.svg + '</div>'
    /* `alt` AND NOT `choice`, WHICH IS WHAT IT SAID. `choice` is a fork's label
       in a track and an option's text in a question; on an image it is a made-up
       attribute, and the image it was on had no alt at all. axe would refuse it
       in a second — and never got the chance, because no content writes an
       `image` figure yet, so this line has never run. A dead path is where a
       defect waits. */
    : '<img src="' + esc(b.image) + '" alt="' + esc(b.alt || b.caption || '') + '" loading="lazy">';
  return '<figure class="fig">' + body +
    (b.caption ? '<figcaption>' + formatted(b.caption) + '</figcaption>' : '') +
  '</figure>';
}

/* ---------- code as an example, Go By Example style ----------

   THE SHAPE IS gobyexample.com's, and it is simpler than the first attempt
   here: the explanation on one side, the program on the other, each note at the
   HEIGHT of the snippet it comments on.

   What changed from the earlier version, and why:

   1. THE NOTE GOES ON THE LEFT, the code on the right. You read the
      explanation and then look sideways — which is the order in which a person
      learns. With the code first, they read something they do not yet know
      what it is.
   2. THERE IS NO LINE BETWEEN SNIPPETS. The lines turned the program into a
      table of pieces, which is exactly what this block exists to avoid: the
      program is ONE file, and the right column has to look like a file.
      Continuity is the whole argument.

   The highlighting comes from further down this file, in three colours — red
   for the structure of the language, blue for literals, white for the rest.

     { example: {
         language: 'css',
         file: 'bar.css',                    // optional
         parts: [ { code: '…', note: 'why this' }, … ],
         output: '…'                               // optional
     } }

   On a narrow screen the two columns become one, with the note BEFORE the
   snippet: reading the explanation and then the code is the order that works
   without the sideways alignment tying the two together. */
function annotatedExample(ex) {
  const parts = ex.parts || [];
  /* THE BAR MOVED INSIDE THE GRID, and that is the whole of what makes this a
     window rather than a strip above one. Wide, it is a cell in the CODE column
     and the frame it opens runs down that column alone, with the notes outside
     it, in the page. Stacked — which is the default, below 1466px — there is no
     code column to frame: the file is cut up with prose between its pieces, so
     the frame holds all of it. One window, around what a column actually is at
     each width. See `assets/code-window.css`.

     `windowOf('', …)` is given no text on purpose: a `file` is what this block
     already names itself by, and there is no prompt in a program to read. */
  return '<div class="example code-win example-win">' +
    '<div class="example-grid">' +
      codeBar('', ex.file || ex.language, parts.length ? copyButton() : '') +
      parts.map((p) => (
        '<p class="example-note">' + (p.note ? formatted(p.note) : '') + '</p>' +
        '<pre class="example-code"><code>' + highlight(p.code, ex.language) + '</code></pre>'
      )).join('') +
      (ex.output
        ? '<span class="example-empty" aria-hidden="true"></span>' +
          '<div class="example-output">' +
            '<span class="example-output-label mono dim">' + txt('output') + '</span>' +
            '<pre class="code"><code>' + esc(ex.output) + '</code></pre>' +
          '</div>'
        : '') +
    '</div>' +
  '</div>';
}

/* Seeded shuffling: the presentation order cannot change on every render (the
   student would lose whatever they had already dragged), nor be the JSON order,
   which in the `ordering` and `matching` types IS the answer key. */
export function shuffleWith(seed, list) {
  let s = 0;
  for (let i = 0; i < String(seed).length; i += 1) s = (s * 31 + String(seed).charCodeAt(i)) & 0x7fffffff;
  const next = () => { s = (s * 1103515245 + 12345) & 0x7fffffff; return s / 0x7fffffff; };
  const a = list.slice();
  for (let i = a.length - 1; i > 0; i -= 1) {
    const j = Math.floor(next() * (i + 1));
    const t = a[i]; a[i] = a[j]; a[j] = t;
  }
  return a;
}

/* ---------- syntax highlighting ----------

   IT LIVES HERE, AND NOT IN A MODULE OF ITS OWN, for a mechanical reason: it
   needs `esc`, and `esc` lives here. Splitting them would create an import
   cycle — which `bundle.py` refuses, and rightly so. It is also coherent: this
   file is the one that turns content into HTML, and highlighting is that.

   THREE COLOURS, AND THEY ARE THE BRAND'S: red (`--amber`) for what is the
   structure of the language, blue (`--phosphor`) for what is a literal value,
   and the text white for everything else. Comments stay in the dim grey. There
   is no fourth colour, and that is a decision: an editor palette with ten
   shades inside a course page competes with the content instead of helping
   anyone read it.

   THIS IS NOT A PARSER. It is a regular-expression sweep with the alternatives
   in order of precedence — comment before string, string before everything —
   so that nothing is highlighted INSIDE a literal. It gets wrong the cases a
   parser would get right (a division slash that looks like a regex, say), and
   it gets them wrong by returning text with no colour, never the wrong text.

   ESCAPING HAPPENS HERE, EXACTLY ONCE. Callers get finished HTML and must not
   escape it again — that would escape the `<span>`. Every piece that leaves
   here went through `esc()`: either the matched snippet, or the text between
   two matches. */

/* ONE LITERAL, MADE SAFE TO PUT INSIDE AN EXPRESSION. Comment markers and
   quotes arrive here as text — `//`, `--`, `/*`, `"""` — and most of them are
   metacharacters. */
const literal = (s) => s.replace(/[.*+?^${}()|[\]\\/-]/g, '\\$&');

/* The two rules that are the same in every language that has functions and
   numbers, written once instead of fifteen times. */
const NUMBER = /\b0[xb][0-9a-f_]+\b|\b\d[\d_]*(?:\.\d+)?(?:e[+-]?\d+)?[a-z_]*\b/i;
const CALL = /\b[A-Za-z_][\w$]*(?=\s*\()/;

const words = (s) => s.trim().split(/\s+/);

/* ---------- a language is a table ----------

   WRITTEN BY HAND, EACH LANGUAGE IS FIVE EXPRESSIONS TO GET SUBTLY WRONG, and
   three of the five are the same three every time: where a comment starts, what
   quotes a string, what a number looks like. What actually differs is small and
   nameable — Python's triple quote, Go's raw backtick, SQL's `--`, R having no
   block comment at all — so those are the arguments and the rest is shared.

   The catalogue names eleven languages in course titles today and it will name
   more. A table entry is what the next one should cost; five hand-written
   expressions is what makes somebody skip it and ship a grey lesson.

   `long` is quoting that spans lines and it comes FIRST, before the ordinary
   quotes: `"""` has to win over `"`, or a Python docstring closes on its own
   second character and everything after it is coloured as if outside a string
   that in fact never ended. The ordinary quotes stop at the newline for the
   opposite reason — an apostrophe in an English comment would otherwise colour
   the next twenty lines. */
function language({ line = ['//'], block = ['/*', '*/'], quotes = ['"', "'"],
  long = [], keywords = '' } = {}) {
  const str = [
    ...long.map((q) => literal(q) + '[\\s\\S]*?' + literal(q)),
    ...quotes.map((q) => (q === '`'
      /* A backtick string spans lines, in JavaScript and in Go both. */
      ? '`(?:\\\\[\\s\\S]|[^`\\\\])*`'
      : literal(q) + '(?:\\\\[\\s\\S]|[^' + literal(q) + '\\\\\\n])*' + literal(q))),
  ];
  const com = [
    ...(block ? [literal(block[0]) + '[\\s\\S]*?' + literal(block[1])] : []),
    ...line.map((l) => literal(l) + '[^\\n]*'),
  ];
  const kw = keywords ? ['\\b(?:' + words(keywords).join('|') + ')\\b'] : [];
  return [['com', com], ['str', str], ['num', [NUMBER.source]], ['kw', kw], ['fun', [CALL.source]]]
    /* An empty alternative would be an expression that matches the empty string
       at every position — a span around nothing, at every position, forever. */
    .filter(([, alts]) => alts.length)
    .map(([cls, alts]) => [cls, new RegExp(alts.join('|'))]);
}

const JS_KEYWORDS = `const let var function return if else for while do switch case break
  continue try catch finally throw new class extends super this typeof instanceof in of
  delete void import export from default async await yield static get set null undefined
  true false NaN`;

const TS_KEYWORDS = `${JS_KEYWORDS} interface type enum implements declare namespace abstract
  readonly public private protected as is keyof satisfies infer never unknown any string
  number boolean object symbol`;

/* Each language is a list of [class, expression]. The order is the precedence:
   the first one to match at a position wins. The class names are short because
   they reach the DOM as `t-com`, `t-str`, `t-num`… */
const RULES = {
  javascript: language({ quotes: ['`', '"', "'"], keywords: JS_KEYWORDS }),
  typescript: language({ quotes: ['`', '"', "'"], keywords: TS_KEYWORDS }),

  python: language({
    line: ['#'],
    block: null,
    long: ['"""', "'''"],
    keywords: `def class return if elif else for while break continue pass import from as
      with try except finally raise lambda yield global nonlocal assert del in is not and or
      None True False async await self match case print len range str int float bool list
      dict set tuple`,
  }),

  go: language({
    quotes: ['`', '"', "'"],
    keywords: `func package import var const type struct interface map chan go defer return
      if else for range switch case default break continue fallthrough select goto nil true
      false error string int int8 int16 int32 int64 uint uint8 uint64 float32 float64 bool
      byte rune make new len cap append copy delete panic recover`,
  }),

  java: language({
    keywords: `class interface enum record extends implements public private protected static
      final abstract sealed void new return if else for while do switch case break continue
      try catch finally throw throws import package this super null true false int long short
      double float boolean char byte String var instanceof synchronized volatile transient
      native default assert`,
  }),

  kotlin: language({
    keywords: `fun val var class object interface data sealed enum companion init constructor
      override open abstract private protected internal public return if else when for while
      do break continue try catch finally throw import package this super null true false is
      as in by lazy suspend it typealias vararg reified inline operator`,
  }),

  swift: language({
    keywords: `func let var class struct enum protocol extension init deinit subscript guard
      if else switch case default for in while repeat return break continue throw throws
      rethrows try catch defer import self super nil true false public private internal
      fileprivate open static final lazy weak unowned mutating override where async await
      some any typealias associatedtype`,
  }),

  sql: language({
    line: ['--'],
    quotes: ["'", '"'],
    keywords: `select from where group by having order limit offset insert into values update
      set delete create table view index drop alter add column constraint primary key foreign
      references unique not null default check join inner left right full outer cross on as
      union all distinct case when then else end exists in between like is asc desc with
      begin commit rollback transaction grant revoke and or count sum avg min max`,
  }),

  r: language({
    line: ['#'],
    block: null,
    keywords: `function if else for while repeat break next return TRUE FALSE NULL NA NaN Inf
      in library require c list data.frame matrix vector factor`,
  }),

  dockerfile: language({
    line: ['#'],
    block: null,
    keywords: `FROM RUN CMD LABEL EXPOSE ENV ADD COPY ENTRYPOINT VOLUME USER WORKDIR ARG
      ONBUILD STOPSIGNAL HEALTHCHECK SHELL AS`,
  }),

  /* ---------- and the ones that are not keyword languages ----------

     CSS, HTML, JSON, YAML and INI have no vocabulary to list: what carries the
     meaning is a position — before a colon, inside a tag, between brackets — so
     they are written out, and the factory above would only get in the way. */

  css: [
    ['com', /\/\*[\s\S]*?\*\//],
    ['str', /"(?:\\[\s\S]|[^"\\\n])*"|'(?:\\[\s\S]|[^'\\\n])*'/],
    ['kw', /@[\w-]+|![\w-]+/],
    ['num', /#[0-9a-f]{3,8}\b|\b\d+(?:\.\d+)?(?:px|rem|em|ch|%|vw|vh|fr|s|ms|deg)?\b/i],
    ['fun', /[.#][\w-]+|&?::?[\w-]+(?=[\s,{:])/],
    ['prop', /[-a-z]+(?=\s*:)/],
  ],

  html: [
    ['com', /<!--[\s\S]*?-->/],
    /* `<!DOCTYPE` is in the tag alternative rather than a rule of its own,
       because a second rule would need a second group named `kw` and duplicate
       named groups are not portable. Without it the first line of every HTML
       lesson was the one uncoloured thing on the screen: `<!\w` does not match
       `</?[\w-]`, so only the closing `>` was picked up. */
    ['str', /"(?:[^"\n])*"|'(?:[^'\n])*'/],
    ['kw', /<!\s*[\w-]+|<\/?[\w-]+|\/?>/],
    ['prop', /\b[\w-]+(?==)/],
  ],

  /* THE KEY BEFORE THE STRING, which is the one thing JSON needs said: a key is
     a quoted string too, and in the ordinary order every name in the file would
     be the colour of a value. */
  json: [
    ['prop', /"(?:\\[\s\S]|[^"\\\n])*"(?=\s*:)/],
    ['str', /"(?:\\[\s\S]|[^"\\\n])*"/],
    ['num', /-?\b\d+(?:\.\d+)?(?:e[+-]?\d+)?\b/i],
    ['kw', /\b(?:true|false|null)\b/],
  ],

  yaml: [
    ['com', /#[^\n]*/],
    ['prop', /^[ \t]*-?[ \t]*[\w.\/-]+(?=\s*:)/],
    ['str', /"(?:\\[\s\S]|[^"\\\n])*"|'(?:[^'\n])*'/],
    ['kw', /^---$|\b(?:true|false|null|yes|no|on|off)\b/],
    ['num', /\b\d+(?:\.\d+)?\b/],
  ],

  /* `[Timer]` is a section and `OnCalendar=` is a key, which is what the twelve
     systemd units of `linux-terminal` are written in. */
  ini: [
    ['com', /[;#][^\n]*/],
    ['kw', /^[ \t]*\[[^\]\n]*\]/],
    ['prop', /^[ \t]*[\w.-]+(?=\s*=)/],
    ['str', /"(?:\\[\s\S]|[^"\\\n])*"|'(?:[^'\n])*'/],
    ['num', /\b\d+(?:\.\d+)?[a-z]*\b/i],
  ],

  /* VIM'S COMMENT CHARACTER IS A DOUBLE QUOTE, which is why this has no string
     rule at all: the two cannot be told apart without parsing, and a `.vimrc`
     is comments and `set` lines. Guessing string would put the rest of a line
     in the colour of a literal every time somebody explains what a mapping is
     for. */
  vim: [
    ['com', /(?:^|[ \t])"[^\n]*/],
    ['kw', new RegExp('^[ \\t]*:[\\w!]+|\\b(?:' + words(`set setlocal let map nmap imap vmap
      noremap nnoremap inoremap vnoremap function endfunction if endif else for endfor while
      endwhile call execute source autocmd augroup syntax filetype colorscheme highlight
      command silent echo`).join('|') + ')\\b')],
    ['num', /\b\d+\b/],
  ],

  /* ---------- the shell, which is a line and not a file ----------

     A COMMAND IS THE FIRST WORD OF A LINE, and there is no list of commands to
     put in a table: `iotop`, `journalctl`, `awk`, whatever the machine has
     installed. So the position is the rule — the start of a line, or the far
     side of a pipe — and that is why this one is written out rather than named.

     `sudo` AND `time` PASS THROUGH, because the word the reader is looking for
     is the one after them.

     THE OPERATOR IS PART OF THE MATCH, deliberately: `| grep` is one span
     rather than two, which is what lets this be written without a lookbehind.
     Both halves are the same colour anyway — a pipe is structure and so is the
     command it feeds. */
  sh: [
    ['com', /(?:^|[ \t])#[^\n]*/],
    /* BOTH QUOTES STOP AT THE NEWLINE. A shell string can legally span lines;
       an unbalanced one cannot be told from a balanced one that does, and
       guessing the second turns the rest of the block into a literal. */
    ['str', /"(?:\\[\s\S]|[^"\\\n])*"|'[^'\n]*'/],
    ['kw', new RegExp('^[ \\t]*(?:sudo |doas |time |env )?[A-Za-z_.\\/][\\w.\\/-]*'
      + '|[|;&]{1,2}[ \\t]*(?:sudo )?[A-Za-z_.\\/][\\w.\\/-]*'
      /* A SHORT LIST, AND `local` IS NOT ON IT. A shell keyword is a word with
         word boundaries either side, and a path is full of those: `/usr/local`
         came out with an amber word in the middle of a directory name. The ones
         that open and close a block cannot appear in a path and stay; the ones
         that could are already covered, because a command at the start of a
         line or after a `;` is matched above whatever the word happens to be. */
      + '|\\b(?:' + words(`if then elif else fi for while until do done case esac in
        function export readonly trap exit`).join('|')
      + ')\\b|\\$\\{?[\\w?#@*-]+\\}?|[<>]{1,2}')],
    ['num', /\b\d+(?:\.\d+)?\b/],
  ],
};

/* THE NAME THE AUTHOR WROTE IS NOT ALWAYS THE NAME OF THE TABLE. Fences say
   ```js, ```py, ```yml, ```bash, and refusing those would be refusing the way
   everybody writes them. */
const ALIAS = {
  js: 'javascript', jsx: 'javascript', mjs: 'javascript', node: 'javascript',
  ts: 'typescript', tsx: 'typescript',
  py: 'python', py3: 'python',
  golang: 'go',
  kt: 'kotlin',
  htm: 'html', xml: 'html',
  yml: 'yaml',
  toml: 'ini', conf: 'ini', cfg: 'ini', properties: 'ini',
  vimrc: 'vim',
  bash: 'sh', zsh: 'sh', shell: 'sh', console: 'sh', terminal: 'sh',
};

/* One single expression, with the alternatives in groups named after the class.
   Matching once per position is what guarantees the precedence — and it is what
   stops the word `const` inside a string from becoming a keyword.

   `m` IS SET SO THAT `^` MEANS THE START OF A LINE. Two of these are line-shaped
   rather than file-shaped — a shell command begins a line, an INI key begins a
   line — and without it each rule would only ever match the first one in the
   block. */
const compile = (rules) => new RegExp(
  rules.map(([cls, re]) => '(?<' + cls + '>' + re.source + ')').join('|'),
  'gim',
);

const COMPILED = Object.fromEntries(
  Object.entries(RULES).map(([lang, rules]) => [lang, compile(rules)]),
);

/* Every name a fence may carry. `tools/check-highlight` imports this rather
   than keeping a list of its own, and says so of a block labelled `pyton`:
   nothing else in the repository can see a lesson served in one grey. */
export const LANGUAGES = Object.keys(COMPILED).concat(Object.keys(ALIAS)).sort();

/* ---------- a recording is not a language ----------

   1,391 FENCES IN `linux-terminal` ARE A TRANSCRIPT: a prompt, what the student
   types, and what the machine answers. They carry no label and should not — a
   recording of a screen is not written in a language, and `sh` would be a claim
   about the output that is not true.

   SO THE PROMPT IS THE LABEL. The content already carries it, on the first line
   of every one of them, in three shapes and no others: `ana@vm:~/work$`,
   `root@vm:~#`, and PowerShell's `PS /home/ana/work/ps>`. A bare `$ ` counts as
   well; a bare `# ` deliberately does not, because that is what a comment looks
   like at the top of a configuration file and there are 374 promptless bare
   fences in the same course to get wrong.

   THE OUTPUT STAYS PLAIN. `ls` prints file names and `free -h` prints numbers,
   and colouring them would be inventing a structure the recording does not
   have — in a screen full of numbers, the one that matters is never the one a
   rule would find. What is coloured is the line the student typed; the prompt
   is dimmed to the colour of a comment, because that is what it is, chrome in
   front of the command. */
const PROMPT = /^(?:[\w.-]+@[\w.-]+:\S*[$#]|PS [^>\n]*>|\$) /;

/* Read twice: here to decide how to colour the block, and by `codeBar` above to
   decide what to write on its tab. */
export const isTranscript = (text) => PROMPT.test(String(text ?? ''));

function transcript(raw) {
  return raw.split('\n').map((line) => {
    const at = PROMPT.exec(line);
    if (!at) return esc(line);
    return '<span class="t-com">' + esc(at[0]) + '</span>'
      + sweep(line.slice(at[0].length), COMPILED.sh);
  }).join('\n');
}

function sweep(raw, re) {
  let out = '';
  let last = 0;
  re.lastIndex = 0;
  let m = re.exec(raw);
  while (m) {
    const cls = Object.keys(m.groups).find((k) => m.groups[k] !== undefined);
    out += esc(raw.slice(last, m.index)) + '<span class="t-' + cls + '">' + esc(m[0]) + '</span>';
    last = m.index + m[0].length;
    // an empty match would lock the loop; no rule should produce one, but a
    // future change might, and the cost of guarding is this line
    if (m[0].length === 0) re.lastIndex += 1;
    m = re.exec(raw);
  }
  return out + esc(raw.slice(last));
}

/* `localised` IS NOT A LANGUAGE, and it is the one label that says so on
   purpose. A code block is the same bytes in every language of the catalogue —
   `validate-content` holds a translation to it — except where the words belong
   to the reader: an explanation drawn in mono (the five fields of a cron line,
   two transactions side by side) or a formula the software itself spells per
   locale (`=ARRED(…; 2)` in a Portuguese spreadsheet, `=ROUND(…, 2)` in an
   English one). Such a block carries this label in both languages, draws with
   no colour and no title, and is the only kind a translation may change. A
   capture never carries it: what a machine printed is evidence of a run, and
   the validator refuses the label on anything that looks like one. */
export const LOCALISED = 'localised';

export function highlight(code, language) {
  const raw = String(code ?? '');
  const name = String(language || '').toLowerCase();
  if (name === LOCALISED) return esc(raw);
  if (!name) return isTranscript(raw) ? transcript(raw) : esc(raw);
  const re = COMPILED[ALIAS[name] || name];
  if (!re) return esc(raw);           // a language we do not know comes out colourless
  return sweep(raw, re);
}
