/* ==========================================================================
   Schooling — internationalisation of the INTERFACE

   THE KEY IS THE ENGLISH STRING. English is the source language, so it needs no
   dictionary and has none: any string with no entry falls back to the key, and
   the key is already what to show. That is why there is no `en` object anywhere
   in this repository — it would be an identity map, and an identity map is a
   file that goes stale without ever being wrong enough to notice.

   WHAT THIS FILE DELIBERATELY DOES NOT DO, and how it differs from
   codeschool-ing.github.io's assets/i18n-runtime.js, which it is otherwise the
   same idea as:

   That file translates the CATALOGUE as well — it keeps a base copy of every
   course name and summary in the browser and rewrites them on a language
   switch, because the showcase ships its catalogue as a JavaScript file. Here
   the catalogue comes from the API, and its translations live in
   `catalog_prose`, one row per section per locale, chosen by the server. So the
   half of that runtime which reads COURSES and TRACKS is not merely unused
   here — it would throw on load.

   Copying it anyway and calling the two files "syncable" would be a claim that
   is checked by nobody and false on the first read. The shared thing is the
   CONTRACT, and it is: the key is the English string, the stored key is
   `codeschool-language`, and the pre-rename key is read once.
   ========================================================================== */

const LANGUAGES = [
  { code: 'en', html: 'en',    label: 'English',   short: 'EN' },
  { code: 'pt', html: 'pt-BR', label: 'Português', short: 'PT' },
];

const LANG_KEY = 'codeschool-language';
const LANG_KEY_LEGACY = 'codeschool-idioma';   // what the key was called before the rename

function browserLanguage() {
  const list = (navigator.languages && navigator.languages.length)
    ? navigator.languages : [navigator.language || 'en'];
  for (const l of list) {
    const base = String(l).toLowerCase().split('-')[0];
    if (LANGUAGES.some((i) => i.code === base)) return base;
  }
  return 'en';
}

/* A student who had already picked a language stored it under the old key.
   Read it, move it, and forget the old name — a rename without this read
   silently resets everybody to browser detection, which for most of them means
   a different language than the one they chose. */
let LANG = (() => {
  try {
    let saved = localStorage.getItem(LANG_KEY);
    if (!saved) {
      saved = localStorage.getItem(LANG_KEY_LEGACY);
      if (saved) {
        localStorage.setItem(LANG_KEY, saved);
        localStorage.removeItem(LANG_KEY_LEGACY);
      }
    }
    if (saved && LANGUAGES.some((i) => i.code === saved)) return saved;
  } catch (e) { /* private mode: fall back to detection */ }
  return browserLanguage();
})();

export function language() { return LANG; }

/* The locale to ask the API for its CONTENT in, which is the language code the
   Markdown files are named with — `roles.pt.md` is locale `pt`. It is the plain
   code rather than the BCP 47 tag because the file names are the contract, and
   `document.documentElement.lang` is the tag for the same language: two
   different jobs that would be one confusing string if they shared a function.

   The server falls back field by field, so a section translated in its title
   and not its body keeps the English body rather than losing the title too
   (C-11). */
export function contentLocale() { return LANG; }

/* One interface string. With no entry it answers the key, which is already
   English — so a missing translation is a sentence in the wrong language,
   never a blank or a bracketed identifier. */
export function txt(s) {
  const d = window.I18N && window.I18N[LANG] && window.I18N[LANG].ui;
  return (d && d[s]) || s;
}

/* ---------- the page's static text ----------

   A single walk of the TEXT NODES, not of the elements: that is what brings in
   a sentence broken by a <strong> in the middle. The original is stored once,
   and switching language is rewriting those same nodes.

   Everything the router builds is left out — it rebuilds itself from the data
   and calls txt() as it goes. */
const DYNAMIC = ['#content', '#rail', '#nav-context', '#lang-menu', '#account-menu'];
const originals = [];

function outside(el) {
  return !el || el.closest('script,style') || DYNAMIC.some((sel) => el.closest(sel));
}

export function mapTexts() {
  originals.length = 0;

  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  while (walker.nextNode()) {
    const n = walker.currentNode;
    if (outside(n.parentElement)) continue;
    const s = n.nodeValue.trim();
    if (s.length > 2 && /[A-Za-zÀ-ÿ]/.test(s)) {
      originals.push({ el: n, kind: 'node', original: s, raw: n.nodeValue });
    }
  }

  for (const attr of ['placeholder', 'aria-label', 'title']) {
    document.querySelectorAll(`[${attr}]`).forEach((el) => {
      if (!outside(el)) originals.push({ el, kind: attr, original: el.getAttribute(attr) });
    });
  }

  const pageTitle = document.querySelector('title');
  if (pageTitle) originals.push({ el: pageTitle, kind: 'page-title', original: pageTitle.textContent.trim() });
}

export function applyTexts() {
  originals.forEach((r) => {
    if (!r.el) return;
    const v = txt(r.original);
    if (r.kind === 'node') r.el.nodeValue = r.raw.replace(r.original, v);
    else if (r.kind === 'page-title') r.el.textContent = v;
    else r.el.setAttribute(r.kind, v);
  });
}

/* The sentences with no translation in the current language. It is what the
   interface-string checker reads, and it is exported from here rather than
   reimplemented there so that the checker cannot disagree with the runtime
   about what counts as a string. */
export function missingTranslations() {
  const d = (window.I18N && window.I18N[LANG] && window.I18N[LANG].ui) || {};
  return [...new Set(originals.map((r) => r.original))].filter((s) => !d[s]);
}

/* ---------- the picker ---------- */

export function buildLanguagePicker(onSwitch) {
  const box = document.querySelector('#lang-menu');
  if (!box) return;

  box.textContent = '';
  LANGUAGES.forEach((i) => {
    const b = document.createElement('button');
    b.type = 'button';
    /* `lang-op` is what base.css styles these with — the portal's stylesheet is
       copied byte for byte, so the class names it expects are the contract. */
    b.className = 'lang-op' + (i.code === LANG ? ' on' : '');
    b.lang = i.html;
    b.textContent = i.label;
    b.addEventListener('click', () => switchLanguage(i.code, onSwitch));
    box.appendChild(b);
  });

  const active = LANGUAGES.find((i) => i.code === LANG);
  document.querySelector('#lang-short').textContent = active.short;
  document.documentElement.lang = active.html;
}

export function switchLanguage(code, onSwitch) {
  if (code === LANG) return;
  LANG = code;
  try { localStorage.setItem(LANG_KEY, code); } catch (e) { /* private mode */ }
  applyTexts();
  buildLanguagePicker(onSwitch);
  if (onSwitch) onSwitch();
}
