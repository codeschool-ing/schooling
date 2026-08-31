/* ==========================================================================
   Console — boot.

   THE SHELL IS `console-frontend`'s, and that is deliberate rather than
   convenient. That console is the one this platform replaces; its layout, its
   rail and its router are what staff already know, and `assets/base.css` is
   already the same file byte for byte. `app/routes.js` and `app/dom.js` are
   copied whole from it for the same reason the study interface is mostly
   `portal-frontend`'s files: two routers diverge the day somebody fixes one.

   WHAT IS NOT COPIED is everything that assumed a static site talking to
   another origin — the `<meta name="backend">`, the base URL, the standing
   notice about being wired to nothing. This console is SERVED BY the API it
   calls, from one origin (P-03), so there is no other origin to point at.

   THIS CONSOLE WAS ENGLISH-ONLY, and this paragraph said why: "translating an
   internal tool for two people buys nothing, and English is this project's
   source language anyway."

   THE SECOND HALF IS STILL TRUE AND THE FIRST WAS AN ASSUMPTION ABOUT WHO
   READS IT. The people who operate this platform are Brazilian, and a console
   that decides refunds, erasures and what everybody pays is exactly where
   reading a sentence twice is expensive. English stays the SOURCE — every key
   is the English string, so a missing translation falls back to it rather than
   breaking a screen — and Portuguese is a dictionary beside it.

   TWO LANGUAGES AND NOT FIVE, because two are translated. A picker offering a
   third would promise a language and then answer in English.

   THE RUNTIME IS STILL NOT SHARED, for a sharper reason than before: the study
   interface's translates a catalogue, reads it from globals this console does
   not declare, and is a copied file the repository forbids adding to. What IS
   shared is the button, which is `base.css`'s. See `assets/language.js`.

   THE ROUTER DOES NOT START UNTIL THE SESSION HAS ANSWERED. Not because the
   console is what protects anything — `identity.RequireStaff` is — but because
   a section rendered before the answer arrives is a section whose loader has
   already fetched, against a door that may be shut.
   ========================================================================== */

import { route, whenChanged, start, goTo, dispatch } from './routes.js';
import { esc } from './dom.js';
import { txt, begin as beginLanguage, onChange as onLanguageChange } from '../assets/language.js';
import { SECTIONS, DETAILS, GROUPS } from './sections.js';
import * as session from './session.js';
/* IT IS THE STUDY INTERFACE'S FILE, SERVED FROM HERE. `interface.go` asks this
   console's `assets/` first and falls back to that tree, which is the same
   arrangement `base.css` uses — so one copy of "is this tab still the build the
   server is serving" answers for both, and the console does not inherit a
   student's markup to get it. */
import * as release from '../assets/release.js';

const $ = (s) => document.querySelector(s);
const stage = $('#stage');

/* ---------- routes ----------
   One per section, from the same list the rail is built from — so a section
   that exists is reachable, and one that does not, is not. */
SECTIONS.forEach((s) => {
  route('/' + s.id, async () => s.screen(s));
});
DETAILS.forEach((d) => {
  route(d.path, async (params) => d.screen(params));
});

let leaving = null;

/* True while the door is shut and the gate holds the page. The router's
   listener is still attached — `start()` is not undoable — so without this a
   hash change would draw a section straight over the gate, rail and all, for
   somebody the API has just refused. */
let gated = false;

whenChanged(async (path, found) => {
  if (gated) return;
  if (leaving) { leaving(); leaving = null; }

  if (!found) {
    stage.innerHTML = notFound(path);
    stage.setAttribute('aria-label', txt('No such screen'));
    stage.dataset.screen = 'not-found';
    paintRail(path);
    return;
  }

  const { title, el, after, onLeave } = await found.r.load(found.params);
  stage.textContent = '';
  stage.appendChild(el);
  stage.scrollTop = 0;

  /* WHAT WAS MATCHED, not where the browser is. See `route()`: this is what
     lets a check refuse a screen that never drew instead of measuring the
     router's miss and calling it clean. */
  stage.dataset.screen = found.r.pattern;

  /* THE TAB KEEPS ONE NAME, AND `index.html` IS WHERE IT IS SET. A long screen
     title pushes the brand off the end and the tab stops being recognisable
     among a dozen others; the screen's name goes to the content region instead,
     where it is still announced to anybody who cannot see it.

     It used to be assigned here, twice, to the string `Console · schooling` —
     which is a name rather than an address, so nothing in it said which
     deployment's console this was. The head of `index.html` now derives it from
     the host that answered, before the first paint, and there is nothing left
     for this to do: a constant written on every navigation is a constant with
     two more chances to disagree with itself. */
  stage.setAttribute('aria-label', title);

  if (after) after();
  leaving = onLeave || null;
  paintRail(path);
});

/* THE ADDRESS IS OUTSIDE THE SENTENCE, which is what lets this be translated
   at all. "Nothing is routed at %s" would be one string per address — a
   dictionary with a million entries and not one match. */
const notFound = (path) =>
  '<div class="view"><header class="view-head">' +
    '<h1>' + esc(txt('No such screen')) + '</h1>' +
    '<p>' + esc(txt('Nothing is routed at this address.')) +
      ' <span class="mono">' + esc(path) + '</span></p>' +
  '</header></div>';

/* ---------- the rail ----------
   Built from the sections, so it is empty when they are — and an empty 216px
   column with a border down one side reads as a broken page rather than as an
   honest nothing, which is why the shell drops it entirely until there is
   something to put in it. */
function paintRail(path) {
  /* THE FIRST SEGMENT, not the whole path. A detail route lives under its
     section's id, and matching the whole thing would unlight the rail the
     moment somebody opened a record — which reads as having left the section
     they are plainly still in. */
  const here = path.replace(/^\//, '').split('/')[0];
  document.body.classList.toggle('no-rail', SECTIONS.length === 0);
  $('#rail').innerHTML = GROUPS.map((g) => {
    const items = SECTIONS.filter((s) => s.group === g);
    if (!items.length) return '';
    /* TRANSLATED HERE AND NOT IN `sections.js`, because that list is the
       console's map of itself — a group and a section name are read by the
       router, by the rail and by whoever is deciding where a new screen goes.
       Putting `txt()` in the data would make the identity of a section depend
       on what language somebody is reading in. */
    return '<span class="rail-head mono">' + esc(txt(g)) + '</span>' +
      items.map((s) =>
        '<a class="rail-link' + (s.id === here ? ' on' : '') + '" href="#/' + esc(s.id) + '">' +
          '<span>' + esc(txt(s.name)) + '</span>' +
        '</a>').join('');
  }).join('');
}

/* ---------- the bar ---------- */
function paintBar() {
  const bar = $('#bar-state');
  if (session.state.account) {
    bar.textContent = session.role();
    bar.dataset.tone = session.mayAct() ? 'ok' : 'warn';
  } else {
    bar.textContent = txt('signed out');
    bar.dataset.tone = 'bad';
  }

  $('#whoami').innerHTML = session.state.account
    ? '<span class="avatar" aria-hidden="true">' +
        esc((session.displayName().trim()[0] || '·').toUpperCase()) + '</span>' +
      '<span class="whoami-name">' + esc(session.displayName()) + '</span>'
    : '';
}

/* ---------- the door, when it is shut ----------

   THE CONSOLE CANNOT SIGN ANYBODY IN YET, and saying so is better than a form
   that cannot work. Sign-in is a school-scoped route today — a staff member
   signs in at a school's address and comes back — and inventing a second flow
   here would be a login screen with no `tenant` behind it.

   The three refusals are told apart because they need different things done:
   nobody signed in, signed in without a role, and a role whose session has not
   shown a second factor. The API refuses all three with the same status on
   purpose; the message is what differs. */
function paintGate() {
  const gate = $('#gate');
  const shut = !session.state.account;
  gate.hidden = !shut;
  gated = shut;
  document.body.classList.toggle('gate-on', shut);
  document.body.classList.toggle('no-rail', shut);
  if (!shut) { gate.innerHTML = ''; return; }

  /* THE REFUSAL IS THE SERVER'S SENTENCE AND GOES THROUGH `txt()` TOO. It
     arrives in English, English is the key, so it is translated by an entry
     like anything else — and it falls back to English if nobody has written
     one, which is the whole point of the key being the string. `check-interface`
     cannot see it: it is written in Go. */
  const why = session.state.refused || {};
  gate.innerHTML =
    '<span class="gate-mark mono">' + esc(txt('shut')) + '</span>' +
    '<span class="gate-text">' +
      esc(why.message ? txt(why.message) : txt('The console could not tell who you are.')) +
    '</span>';

  stage.innerHTML =
    '<div class="view"><header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Not signed in')) + '</span>' +
      '<h1>' + esc(txt('The door is shut')) + '</h1>' +
      '<p>' + esc(txt('Sign in at a school’s address, then come back here. This console cannot sign anybody in yet: sign-in belongs to a school and this belongs to none of them.')) + '</p>' +
      '<p>' + esc(txt('A staff role and a second factor already shown are both needed. The API refuses without either, and this page is not what enforces it.')) + '</p>' +
    '</header></div>';
  stage.setAttribute('aria-label', txt('The door is shut'));
  stage.dataset.screen = 'shut';
}

/* ---------- theme: the vitrine's key, so the three apps agree ---------- */
const THEME_KEY = 'codeschool-theme';
function applyTheme(theme) {
  document.documentElement.dataset.theme = theme === 'light' ? 'light' : '';
  try { localStorage.setItem(THEME_KEY, theme); } catch (e) { /* private mode */ }
  $('#theme-btn').setAttribute('aria-label',
    theme === 'light' ? txt('Switch to the dark theme') : txt('Switch to the light theme'));
}
$('#theme-btn').addEventListener('click', () => {
  applyTheme(document.documentElement.dataset.theme === 'light' ? 'dark' : 'light');
});
applyTheme(document.documentElement.dataset.theme === 'light' ? 'light' : 'dark');

/* ---------- go ----------

   THE LANGUAGE COMES UP FIRST, and before anything is painted. `beginLanguage`
   walks the shell to remember what every node said in English, and a bar or a
   gate already written by JavaScript would be captured by that walk and then
   rewritten from two places for the rest of the session.

   AND A SWITCH REDRAWS THE SCREEN BY BUILDING IT AGAIN. Every screen here is
   built from an answer it fetched, so there is no text node to rewrite;
   `dispatch()` re-runs the route that is showing, which is the honest version
   of the same thing. The bar and the gate are repainted beside it because they
   are outside the router. */
beginLanguage();
onLanguageChange(() => {
  paintBar();
  paintGate();
  if (!gated) dispatch();
});

await session.load();
paintBar();
paintGate();

if (!gated) {
  // `#` alone is the same nothing as no hash at all, and the copied router
  // answers both with the portal's default — a dashboard this console does
  // not have.
  if (!location.hash || location.hash === '#') goTo('/' + (SECTIONS[0] ? SECTIONS[0].id : ''));
  start();
}

/* ---------- "this console has been open since before the last release" ----------

   IT IS OUTSIDE THE GATE ON PURPOSE. A signed-out console is still a console
   somebody left open, and the sign-in screen is as much a screen from before
   the deploy as any other. There is nothing to sign for here — `/version` is
   the one route this interface asks that needs no session.

   NEITHER PREDICATE IS PASSED, and both defaults are the right answer: this
   console has no offline copy to be unable to ask from, and nothing on it is
   timed the way an exam paper is. What it has instead is the reason the check
   matters more here — an operator deciding about money on yesterday's screens.

   NOTHING RELOADS BY ITSELF. It is a sentence and a button, and the button
   belongs to whoever is reading it; an operator halfway through typing a reason
   into a form is exactly the person a surprise reload would rob. */
release.watch(() => {
  const el = $('#stale-banner');
  el.hidden = false;
  el.innerHTML =
    '<span class="sb-text">' + esc(txt('This console has been open since before the last update. Reload it when you are ready.')) + '</span>' +
    '<button type="button" class="sb-reload">' + esc(txt('Reload')) + '</button>';
});

$('#stale-banner').addEventListener('click', (e) => {
  /* `reload()` AND NOT A CACHE-BUSTING QUERY. Every file this page loaded
     carries `no-cache` and an ETag that is the build (`interface.go`), so an
     ordinary reload revalidates all of them. A query string would be a second,
     weaker copy of a rule the server already states correctly. */
  if (e.target.closest('.sb-reload')) location.reload();
});
