/* ==========================================================================
   The console's language, in English and Portuguese.

   # WHY THIS IS NOT `ui/assets/i18n-runtime.js`

   That file is the study interface's, and sharing it was the first thing tried.
   Two things stop it, and either would be enough.

   IT CANNOT RUN HERE. `saveBase()` and `applyContent()` read `COURSES` and
   `TRACKS` as bare globals — a catalogue this console does not have and never
   will. Not undefined: undeclared, so the first switch of language throws a
   ReferenceError and the screen stops. Half that file translates courses,
   tracks, lessons, exercises and plans, and this console has none of them.

   AND IT IS A COPIED FILE. `CLAUDE.md` says of the stylesheets it came in with:
   "Nothing is added to them here, not even a fix." The repository they were
   copied from was deleted in August 2026, so the rule now rests on whoever is
   reading rather than on a diff anybody can run — which makes it easier to
   break, not less binding.

   WHAT IS SHARED IS THE PART THAT SHOULD BE. `.lang`, `.lang-btn`, `.lang-menu`
   and `.lang-op` are in `base.css`, which this console serves the same bytes of
   — so the button is the study interface's button, in the same place, with the
   same behaviour, and none of that is written twice. What is not shared is the
   machinery for a catalogue. That is the same line `interface.go` already draws:
   this console shares the identity and none of the assumptions that make sense
   for a school.

   # THE KEY IS THE ENGLISH STRING

   So there is no `en` dictionary — it would be an identity map — and a string
   with no entry falls back to English by itself rather than breaking a screen.
   `tools/check-interface internal/console/ui` is what makes that fallback a
   defect somebody is told about instead of a screen half in English.

   # TWO LANGUAGES, AND THE LIST IS THE CLAIM

   The study interface offers five. This offers two, because two are translated:
   a picker offering Italian to somebody who would then read English is a worse
   screen than one that does not offer it. Adding a third is this list and a
   dictionary, in the same commit, or the check fails.

   # A SENTENCE THE SERVER WROTE IS TRANSLATED HERE

   Half of what this console says arrives on an answer — the argument under a
   parameter, why a job cannot be started, what a listing is for — because it is
   a statement about the system rather than about a page. Those come in English,
   English is the key, and they go through `txt()` at the point of display like
   everything else. `check-interface` cannot see them: they are written in Go.
   That is the known edge of what a static check reaches, and it is why the last
   step before pushing is still somebody reading the screens in both languages.
   ========================================================================== */

/* THE TWO, AND EACH LABELLED IN ITSELF. A picker that says "Portuguese" to
   somebody looking for their own language is a picker in the language they are
   trying to leave. */
const LANGUAGES = [
  { code: 'en', html: 'en', label: 'English', short: 'EN' },
  { code: 'pt', html: 'pt-BR', label: 'Português', short: 'PT' },
];

/* THE SAME KEY NAME THE OTHER TWO USE, and the console is its own origin so
   this is a different stored value rather than a shared one. The name matches
   for the reason the theme's does: three applications that agree about what a
   preference is called are three that can ever be served from one host without
   a migration. Nothing is read from an older name — this key has never had one
   here, and inventing a migration for a key that never existed would be a line
   nobody can ever delete. */
const KEY = 'codeschool-language';

function fromBrowser() {
  const list = (navigator.languages && navigator.languages.length)
    ? navigator.languages : [navigator.language || 'en'];
  for (const one of list) {
    const base = String(one).toLowerCase().split('-')[0];
    if (LANGUAGES.some((i) => i.code === base)) return base;
  }
  return 'en';
}

let LANG = (() => {
  try {
    const saved = localStorage.getItem(KEY);
    if (saved && LANGUAGES.some((i) => i.code === saved)) return saved;
  } catch (e) { /* private mode: fall back to what the browser asks for */ }
  return fromBrowser();
})();

export const language = () => LANG;

/*
txt is one interface string in the language now in force.

	NO ENTRY MEANS THE KEY, which is already English. That is what makes a
	half-translated screen work rather than break — and what makes it invisible,
	which is why the check exists.
*/
export function txt(s) {
  const d = window.I18N && window.I18N[LANG] && window.I18N[LANG].ui;
  return (d && d[s]) || s;
}

/*
day is a date in the language that was CHOSEN, not the one the browser is in.

	`toLocaleDateString()` with no argument uses the browser's locale, which was
	the only sensible answer while this console had no language of its own — and
	became wrong the moment it got one. It put `8/30/2026` on a screen otherwise
	entirely in Portuguese: an American date, from a browser configured in
	English, for somebody who had just asked for Portuguese. The defect is
	quiet in the worst way, because a date always looks like a date, and 8/9 is a
	real day in both readings.

	IT LIVES HERE BECAUSE IT IS A FUNCTION OF THE LANGUAGE. Every screen had its
	own two-line `day()` and each would have to be found and fixed; there is one
	now, and it moves when the picker does.

	EN-GB AND NOT EN-US. This repository is written in British English
	throughout — `internationalisation`, `colour` — and 30/08 beside 30/08 is one
	format for both languages rather than two that differ only in the reader's
	head.
*/
export function day(iso) {
  if (!iso) return '—';
  const at = new Date(iso);
  if (Number.isNaN(at.getTime())) return String(iso);
  return at.toLocaleDateString(LANG === 'pt' ? 'pt-BR' : 'en-GB');
}

/*
moment is a date with the time on it, for the screens that need one.

	SAME ARGUMENT AS `day`, and it is separate rather than a flag because the two
	are read for different reasons: a grant is a day, and an audit entry is a
	moment. A caller choosing between them says which it meant.
*/
export function moment(iso) {
  if (!iso) return '—';
  const at = new Date(iso);
  if (Number.isNaN(at.getTime())) return String(iso);
  return at.toLocaleString(LANG === 'pt' ? 'pt-BR' : 'en-GB');
}

/* ---------- the page's own text ----------

   ONE WALK, AND THE ORIGINALS ARE KEPT. Switching language rewrites the same
   nodes, so what they said in English has to survive the first switch — reading
   the node back would translate a translation on the second one.

   ONLY LEAVES, and only nodes this console wrote. Anything a screen builds is
   left alone: screens are rebuilt from scratch on a switch (see `onChange`),
   and rewriting their text here as well would be two mechanisms fighting over
   the same element. */
const originals = [];

function remember() {
  document.querySelectorAll('body *').forEach((el) => {
    if (el.closest('#stage') || el.closest('#rail')) return;
    for (const attr of ['placeholder', 'aria-label', 'title']) {
      const had = el.getAttribute(attr);
      if (had) originals.push({ el, attr, was: had });
    }
    const only = el.childNodes.length === 1 && el.firstChild.nodeType === Node.TEXT_NODE;
    if (only && el.textContent.trim()) {
      originals.push({ el, attr: null, was: el.textContent });
    }
  });
}

function applyStatic() {
  originals.forEach(({ el, attr, was }) => {
    /* THE WHITESPACE IS PUT BACK. `index.html` is indented, so a text node is
       "\n      The console needs JavaScript." — translating that whole string
       would ask a dictionary for an entry with the file's indentation in it,
       which nobody would ever match. */
    if (attr === null) {
      const trimmed = was.trim();
      el.textContent = was.replace(trimmed, txt(trimmed));
      return;
    }
    el.setAttribute(attr, txt(was));
  });
}

/* ---------- the picker ---------- */

let redraw = () => {};

/*
onChange is what to do after the language moves.

	IT IS `dispatch()` FROM THE ROUTER, passed in by `main.js`. Every screen in
	this console is built by JavaScript from an answer it fetched, so there is no
	node here to rewrite — the honest way to redraw one in another language is to
	build it again. `dispatch()` re-runs the route that is already showing, which
	is exactly that.

	WHICH MEANS A FORM IN PROGRESS IS LOST. That is the cost, it is small, and
	the alternative is worse: a screen half in each language, with the half that
	did not change being the half somebody is reading.
*/
export function onChange(fn) { redraw = fn; }

function buildPicker() {
  const box = document.querySelector('#lang-menu');
  if (!box) return;
  box.textContent = '';
  LANGUAGES.forEach((one) => {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'lang-op' + (one.code === LANG ? ' on' : '');
    b.lang = one.html;
    b.textContent = one.label;
    b.addEventListener('click', () => { switchTo(one.code); close(); });
    box.appendChild(b);
  });

  const active = LANGUAGES.find((one) => one.code === LANG);
  document.querySelector('#lang-short').textContent = active.short;

  /* THE DOCUMENT SAYS WHAT LANGUAGE IT IS IN, which is not decoration: it is
     what a screen reader picks a voice from, and what a browser offers to
     translate. `index.html` ships `lang="en"` and this is what moves it. */
  document.documentElement.lang = active.html;
}

function close() {
  const box = document.querySelector('#lang');
  if (!box) return;
  box.classList.remove('is-open');
  box.querySelector('.lang-btn').setAttribute('aria-expanded', 'false');
}

function switchTo(code) {
  if (code === LANG) return;
  LANG = code;
  try { localStorage.setItem(KEY, code); } catch (e) { /* private mode */ }
  applyStatic();
  buildPicker();
  redraw();
}

/*
begin reads the page once and draws the picker.

	IT RUNS BEFORE THE FIRST SCREEN, so that `remember()` sees the shell and
	nothing else. A screen already in the stage would have its text captured
	here and then rewritten from two places for the rest of the session.
*/
export function begin() {
  remember();
  applyStatic();
  buildPicker();

  const box = document.querySelector('#lang');
  if (!box) return;

  box.querySelector('.lang-btn').addEventListener('click', () => {
    const open = box.classList.toggle('is-open');
    box.querySelector('.lang-btn').setAttribute('aria-expanded', String(open));
  });

  /* CLICKING ANYWHERE ELSE CLOSES IT, which a menu opened by a button owes
     whoever opened it by accident. Escape too: a menu that traps somebody who
     reached it by keyboard is a menu they cannot leave. */
  document.addEventListener('click', (e) => { if (!box.contains(e.target)) close(); });
  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') close(); });
}
