/* ==========================================================================
   Student Portal — boot.

   LOAD ORDER, and it matters: `dados.js`, the dictionaries and `i18n-runtime.js`
   are CLASSIC scripts, loaded before this module by index.html. Functions
   declared there (`txt`, `applyLanguage`, `saveBase`…) live in the global
   scope and are visible here; the reverse is not automatic, so what the runtime
   needs from us is published by hand just below. It is the price of reusing the
   vitrine's i18n without touching it — and it is cheap next to rewriting five
   languages.

   Those global names stay in Portuguese because `i18n-runtime.js` is a verbatim
   copy of the vitrine's and looks them up by name.
   ========================================================================== */

import { route, whenChanged, start, currentPath, dispatch, goTo } from './routes.js';
import * as sync from './sync.js';
import * as source from './source.js';
import { isChoice, courseBySlug, courseByAddress, trackBySlug, courseAddress } from './catalog.js';
import { subscribe, now } from './state.js';
import { buildRail, toggleLesson } from './rail.js';
import { studentTrack, trackProgress } from './screens/common.js';
import * as api from './api.js';
import { esc } from './text.js';

import signIn from './screens/sign-in.js';
import dashboard from './screens/dashboard.js';
import trackScreen from './screens/track.js';
import course from './screens/course.js';
import lesson from './screens/lesson.js';
import catalogue from './screens/catalog.js';
import certificates from './screens/certificates.js';
import account from './screens/account.js';
/* `subscribeScreen` AND NOT `subscribe`, which `state.js` already exports as
   the store's observer. Two things in this file called subscribe would be a
   collision the compiler catches — it did — and a name that reads wrong at
   every call site afterwards. `trackScreen` above is named for the same
   reason. */
import subscribeScreen from './screens/subscribe.js';
import performance from './screens/performance.js';
import redo from './screens/redo.js';
import notes from './screens/notes.js';
import { courseExamScreen, trackExamScreen } from './screens/exam.js';
import { terms, privacy } from './screens/legal.js';
import practice from './screens/practice.js';
import { openSearch, close as closeSearch, searchOpen } from './search-panel.js';
import { closeModal, modalOpen } from './modal.js';
import { wireCopy } from './copy.js';
import * as release from './release.js';
/* IT IS IN `assets/` AND NOT IN `app/`, which is what lets the console show
   what a school will look like without a second copy of the algorithm: the
   console's host serves `assets/` from this tree when its own has no such
   file, and refuses to serve `app/` at all — those are a student's screens.
   Correcting a colour for contrast is neither side's screen; it is the rule
   both of them have to agree about. */
import { applyAccent } from '../assets/accent.js';

/* ---------- what the i18n runtime needs from us ---------- */
globalThis.isChoice = isChoice;                  // used by applyContent()
/* Switching language rebuilds the screen. The guard exists because
   `applyLanguage()` is called once at boot, BEFORE the router starts: without
   it, the first screen would be built twice — once by the language, once by
   `start()`. */
let booted = false;
/* THE LANGUAGE SWITCH REACHES THE LESSONS THROUGH HERE, and this is the only
   place it can: the runtime's `applyLanguage()` calls `redrawAll` after
   switching, and offers no other hook.

   It matters because the SERVER translates the lessons now. The runtime still
   swaps every interface string and every catalogue field in place, as it always
   did — but the prose in the store came from an HTTP call that named a
   language, and redrawing would put the old language's paragraphs back on
   screen. `languageChanged()` drops the store when it moved; the structure is
   re-read here and the screens re-ask for the course they are showing. */
globalThis.redrawAll = () => {
  if (!booted) return null;

  /* AND THE CATALOGUE ITSELF MOVED LANGUAGE TOO. A course's name and syllabus
     used to be translated in place by the runtime, from a dictionary that
     shipped with the interface; they are the school's own rows now and arrive
     already in the language that was asked for.

     Which means the runtime must not translate them a second time: `saveBase()`
     is re-run over the catalogue that just landed, so the "English" it falls
     back to IS the language on screen. Without that, `applyContent()` would put
     the previous language's snapshot back on every switch. */
  if (source.languageChanged()) {
    source.load(api).then(() => {
      saveBase();
      return api.loadLessonStructure();
    }).then(dispatch);
    return dispatch();
  }

  if (api.languageChanged()) {
    api.loadLessonStructure().then(dispatch);
  }
  return dispatch();
};

/* ---------- routes ---------- */
/* Before any screen renders: the write hook has to be in place for the first
   click, and configured() is a no-op with no backend. */
sync.start();

route('/sign-in', signIn);
route('/dashboard', dashboard);

/* WHERE THE INVITATION'S BUTTON GOES, and it went to a `mailto:` until now.
   One address, no parameters: what is being bought is chosen on the screen
   rather than carried in the link, so a bookmarked one cannot preselect a term
   that has since stopped being sold. */
route('/subscribe', subscribeScreen);
route('/track', trackScreen);

/* ONE ADDRESS PER TRACK, which the portal does not need and this does.

   Over there a student is enrolled in one track, so `/track` means "theirs"
   and there is nothing else to address. Here a school has nineteen: the
   selector in the bar links to each, a map is a thing somebody bookmarks and
   sends to somebody else, and the browser suite opens every one of them by
   name.

   It is the same screen. The id only says which track it is about, which on
   this side is what the enrolment says over there — so it is written into the
   document and the screen reads it exactly as it always did. */
/* ---------- the address carries the slug; everything past here carries the id

   `/course/statistics` is what somebody bookmarks and sends. `co-cbwm5kwa` is
   what a progress row points at, and the two are not the same string any more.

   THE ROUTER IS WHERE THEY MEET, and it is the only place: a screen resolving
   its own parameter would be a second translator, and a second translator is
   how one of them ends up disagreeing. Past `named`, every screen receives an
   id exactly as it always did and none of them needed changing.

   A slug nothing matches is left alone rather than blanked, so the screen
   refuses a course that is not there instead of one that has no name. */
const named = (find, screen) => (params) => {
  const found = find(params.id);
  return screen({ ...params, id: found ? found.id : params.id });
};

route('/track/:id', named(trackBySlug, async (params) => {
  if (params.id && (!now().enrollment || now().enrollment.trackId !== params.id)) {
    await api.enrol(params.id);
  }
  return trackScreen(params);
}));
route('/course/:id', named(courseBySlug, course));
/* Two routes for the same screen: without the section, it lands on the first
   one. That is what keeps an old link (or the course button) working after the
   lesson turned into several sections. */
route('/course/:id/exam', named(courseBySlug, courseExamScreen));
route('/track/exam', trackExamScreen);
route('/course/:id/lesson/:ix', named(courseBySlug, lesson));
route('/course/:id/lesson/:ix/:sec', named(courseBySlug, lesson));
route('/catalog', catalogue);
route('/certificates', certificates);
route('/account', account);
route('/performance', performance);
route('/redo', redo);
route('/notes', notes);

/* THE DRILL, which the portal has no route for because the schedule behind it
   is this server's. */
route('/practice', practice);

/* THE TWO DOCUMENTS, which the portal has no route for because over there they
   are the vitrine's pages. Here the interface is the whole of what a school
   serves, so they live in it — and they are the only screens that ask nothing
   of anybody: no session, no plan, and answered from what was baked when the
   file is opened off a disk. */
route('/terms', terms);
route('/privacy', privacy);

/* Which screens are the school's rather than the catalogue's. Everything that
   reads or writes a student's own record: there is no student in a file on a
   disk. The exams are matched by their ending because there is one per course
   and one per track.

   `/subscribe` JOINED THIS LIST WHEN IT STOPPED REDIRECTING. While it sent a
   signed-out visitor to `/sign-in` it was unreachable in the bundle and listing
   it would have been dead weight — the notice appeared on the form it landed
   on. Now the screen draws, in a file on a disk, offering to create an account
   against a server that is not there. Saying so is the whole of what this list
   does. */
const OF_THE_SCHOOL = ['/sign-in', '/dashboard', '/certificates', '/performance',
  '/redo', '/notes', '/practice', '/subscribe'];
const needsTheSchool = (path) =>
  OF_THE_SCHOOL.includes(path) || path.endsWith('/exam');

const $ = (s) => document.querySelector(s);
const content = $('#content');
const rail = $('#rail');

let leaving = null;

whenChanged(async (path, found) => {
  /* A VISITOR IS NOT TURNED AWAY, and this is the one place the copy could not
     be literal. The portal is a student area: with no session only sign-in
     exists. This is a school, and the first course of every track is free to
     anybody (N-04) — the catalogue, the maps and those courses are the shop
     window. The offline copy has no session at all and would otherwise show a
     sign-in form and nothing else.

     Each screen still refuses what belongs to a student. What changed is that
     refusing is the screen's job rather than the router's. */
  if (now().session && path === '/sign-in') return goTo('/dashboard');

  if (leaving) { leaving(); leaving = null; }

  if (!found) {
    content.innerHTML = '<div class="view"><p class="empty">' + txt('page not found') + '</p></div>';
    content.setAttribute('aria-label', txt('page not found'));
    /* THE ROUTER SAYS WHICH SCREEN IT DREW, in one attribute, and this is the
       only place that says "none of them".

       A miss is a perfectly accessible screen: one heading, good contrast,
       nothing to trip over. So a test that opens a route which no longer
       exists checks a tidy little 404 and reports a pass — which is what
       happened. Two of the screens the accessibility suite believed it was
       measuring had not been drawn since the interface was replaced, and
       nothing anywhere said so.

       It is `data-screen` and not the `aria-label` beside it because that
       label is translated: a check on its text would be a check that passes in
       English and fails in Portuguese. */
    content.dataset.screen = 'not-found';
    return;
  }

  const { title, el, after, onLeave } = await found.r.load(found.params);
  content.textContent = '';
  content.appendChild(el);
  content.scrollTop = 0;

  /* ---------- AND IN THE OFFLINE COPY, THE SCREENS THAT CANNOT WORK SAY SO ----

     The bundle is one file opened off a disk with no server anywhere near it.
     The catalogue, the maps, the courses and every written lesson are in it and
     need nothing; a session, progress, exams, certificates and the drill are
     the school's and are not.

     WITHOUT THIS THE FILE LIES QUIETLY. It draws the sign-in form, the student
     types a password, presses the button and nothing happens — which is worse
     than saying so, because they will try twice and then assume it is their
     fault. Same for a dashboard that reports 0% for ever.

     IT IS ON THE ROUTER AND NOT IN THE SCREENS, deliberately: those files are
     `portal-frontend`'s and stay that way, and the portal has no offline copy
     to know about. One list here beats a branch in eight files. */
  if (api.offline && needsTheSchool(path)) {
    const notice = document.createElement('div');
    notice.className = 'notice';
    notice.setAttribute('role', 'status');
    notice.innerHTML =
      '<p>' + txt('This is the offline copy of this school.') + '</p>' +
      /* ONE LITERAL, however long the line. `tools/check-interface` reads what
         the interface says by finding a `txt` call with one quoted string in
         the source, and a string
         built by concatenation is invisible to it — the sentence would go
         untranslated and no check would ever say so. */
      '<p class="dim">' + txt('Courses, tracks and lessons are all here and need no connection. Signing in, your progress and exams live with the school, so they are not.') + '</p>';
    el.prepend(notice);
  }

  /* THE TAB DOES NOT CHANGE ITS NAME. It used to say where the student was —
     "ES6+ syntax: let/const… · codeschool.ing" — and the effect was the opposite
     of what was intended: with the portal open next to other tabs, the brand was
     cut off at the end of a long title and the tab stopped being recognisable at
     a glance. The school's name fits whole, and it is what people look for when
     they come back here.

     Each screen's `title` does not die with that: it now names the content
     region. It was `document.title` that announced the screen change to a screen
     reader; freezing the tab without passing that name on would leave the
     navigation mute for anyone who cannot see. */
  /* AND THE NAME IS THE ADDRESS. The school's own name was here, and it answered
     a question nobody was asking: `Programming` says nothing about which of the
     three tabs this is, and two schools of the same subject on two deployments
     look identical. The first two labels of the host — `code.schooling` — are
     what actually differ, and they are what somebody types to come back.

     `index.html` sets the same thing before the first paint; this is for the
     case that one cannot reach. Opened from `file://` there is no host at all,
     and an offline bundle IS one school, so its name is the true answer there. */
  const host = location.hostname.split('.');
  document.title = host.length > 1
    ? host[0] + '.' + host[1]
    : (source.school && source.school.name) || 'schooling';
  content.setAttribute('aria-label', title);
  // The route that matched, not the address that was typed: `/course/:id` for
  // every course. See the miss above for what this is for.
  content.dataset.screen = found.r.path;
  if (after) after();
  leaving = onLeave || null;

  /* THE RAIL IS DRAWN FOR EVERYBODY, and it is the same adaptation as the
     router's guard above. Over there it is a student's rail and there is no
     student without a session; here it is the school's shape — the six places
     and the track's courses — which is what a visitor came to look at. What a
     signed-out visitor does not get is the counts, because there are none. */
  document.body.classList.remove('no-rail');
  /* THE RAIL IS TOLD `/track`, WHATEVER TRACK IT IS.

     `rail.js` marks its active link by `path === link.href`, and its link is
     `#/track` because over there a student has one. Here the address carries
     which one — `/track/frontend` — so the comparison never matched and no
     entry in the menu was ever highlighted.

     Normalised here rather than in `rail.js`, which is a verbatim copy: what
     the rail is being asked is "which of the six places is this", and every
     track is the same answer to that question. */
  buildRail(rail, path.replace(/^\/track\/.*/, '/track'), found.params);
  closeRail();
  paintContext();
});

/* ---------- the context in the bar ----------
   Shows the track and how much of it is done. It reads from the same computation
   the dashboard uses, because two computations of the same number diverge on the
   day one of them changes. */
/* THE SELECTOR IS THERE WITHOUT A SESSION, and the progress is not.

   The portal hides the whole control for a visitor, and over there that is
   right: with no session there is no screen but sign-in, so there is nowhere to
   switch to. Here a visitor has a catalogue and nineteen maps, and the offline
   copy — where nobody is ever signed in — is the one place a reader most needs
   to move between them. Hidden, the bundle carried eighteen tracks it could not
   reach.

   What stays hidden is the BAR AND THE PERCENTAGE. A chip reading 0% is a
   statement about somebody's effort, and we have no right to make it about
   somebody who has not started. */
function paintContext() {
  const cx = $('#nav-context');
  const t = studentTrack();
  if (!t) { cx.innerHTML = ''; return; }
  const signedIn = Boolean(now().session);
  const p = trackProgress(t);

  /* The track in the bar is a SELECTOR, not a label. Switching tracks used to
     mean signing out and back in — which is absurd for a choice the student may
     want to revisit at any time, and which costs nothing, because progress is
     per course and a shared course keeps counting. */
  cx.innerHTML =
    '<div class="ctx-box">' +
      '<button type="button" class="ctx" aria-haspopup="true" aria-expanded="false">' +
        '<span class="ctx-name">' + esc(t.name) + '</span>' +
        (signedIn
          ? '<span class="ctx-bar"><span style="width:' + p.pct + '%"></span></span>' +
            '<span class="ctx-pct">' + p.pct + '%</span>'
          : '') +
        '<span class="ctx-arrow" aria-hidden="true">▾</span>' +
      '</button>' +
      '<div class="ctx-menu" role="menu">' +
        '<a class="ctx-op ctx-map" href="#/track/' + esc(t.id) + '">' +
          txt('see the track map') + ' →</a>' +
        TRACKS.map((x) => '<button type="button" class="ctx-op' + (x.id === t.id ? ' on' : '') + '" ' +
          'data-track="' + esc(x.id) + '">' + esc(x.name) + '</button>').join('') +
      '</div>' +
    '</div>';
}

$('#nav-context').addEventListener('click', async (e) => {
  const box = $('#nav-context .ctx-box');
  if (e.target.closest('.ctx')) {
    const opened = box.classList.toggle('is-open');
    box.querySelector('.ctx').setAttribute('aria-expanded', String(opened));
    if (opened) closeRail();
    return;
  }
  const op = e.target.closest('.ctx-op[data-track]');
  if (!op) return;
  box.classList.remove('is-open');
  /* THE ADDRESS IS THE TRACK. `enrol` writes the document so the rail and the
     bar move; going to the track's own path is what makes the map linkable and
     what puts the choice in the history, so Back returns to the one before. */
  await api.enrol(op.dataset.track);
  goTo('/track/' + op.dataset.track);
});

/* ---------- the account menu ---------- */
function paintAccount() {
  const s = now().session;
  $('#account-avatar').textContent = (s?.name || '·').trim().charAt(0).toUpperCase() || '·';
  $('#account-menu').innerHTML = s
    ? '<a class="account-op" href="#/account">' + txt('My account') + '</a>' +
      '<a class="account-op" href="#/certificates">' + txt('Certificates') + '</a>' +
      /* THE SCHOOL'S OWN SITE, OR NO LINK AT ALL. This was
         `https://codeschool.ing` for every student of every school — one
         school's marketing site offered to all of them from inside another
         school's portal. A school that has not told us where its site is now
         gets no line here, which is the honest answer. */
      (source.school && source.school.site
        ? '<a class="account-op" href="' + esc(source.school.site) + '" rel="noopener">'
          + txt('Go to the site') + ' ↗</a>'
        : '') +
      '<button type="button" class="account-op account-op-btn" id="account-signout">' + txt('Sign out') + '</button>'
    : '<a class="account-op" href="#/sign-in">' + txt('Sign in') + '</a>';
}

$('#account').addEventListener('click', async (e) => {
  if (e.target.closest('.account-btn')) {
    const c = $('#account');
    const opened = c.classList.toggle('is-open');
    c.querySelector('.account-btn').setAttribute('aria-expanded', String(opened));
    if (opened) closeRail();
  } else if (e.target.closest('#account-signout')) {
    // Same as the account screen's button: end the session, land on sign-in.
    $('#account').classList.remove('is-open');
    await api.signOut();
    goTo('/sign-in');
  } else if (e.target.closest('.account-op')) {
    $('#account').classList.remove('is-open');
  }
});

/* ---------- "confirm your e-mail" nudge ----------
   Shown while a signed-in account's address is unverified. It gates nothing —
   registering already signed the student in; this only surfaces that the link in
   their inbox is still unclicked. Dismiss hides it for this page load only, so it
   returns on the next visit until the address is confirmed. Painted here (the
   container is in window.I18N_DYNAMIC) so it survives a screen re-render and picks
   up the language on the next state change, exactly like the account menu. */
let bannerDismissed = false;
function paintVerifyBanner() {
  const el = $('#verify-banner');
  const s = now().session;
  const show = !!(s && s.emailVerified === false) && !bannerDismissed;
  el.hidden = !show;
  document.body.classList.toggle('banner-on', show);
  if (!show) { el.innerHTML = ''; return; }

  /* WHICH OF THE THREE SENTENCES IS TRUE.

     "We sent a link to X" was said unconditionally, and it was a lie to every
     account created before confirmations existed and to anybody whose link
     expired unread. The server says whether one is outstanding, so the screen
     can say the true thing in both cases — and the button changes with it,
     because "Resend" is a strange word for a message nobody has had.

     THE THIRD IS THE ONE THAT MATTERS, and it is not a fourth wording of the
     same nudge. Once the address has REFUSED us — the mailbox does not exist,
     the receiving side blocklists us — every sentence above stays technically
     true and stops being worth anything: the message left, it came back, and
     the button offers to do it again. What that person needs is not a nudge,
     it is the reason. */
  const refused = s.emailRefused === true;
  const waiting = s.confirmationPending === true;

  /* EACH STRING IS ITS OWN `txt('literal')` CALL, and the ternary picks between
     the RESULTS rather than between the arguments. `check-interface` reads this
     file for `txt('…')` and cannot see a literal inside a conditional passed to
     it — written the other way these stop being policed, and the fifth language
     this platform learns loses them silently. The tool said so: the strings it
     could see dropped by two and its unused count rose by the same. */
  if (refused) {
    /* NO BUTTON, WHICH IS THE POINT. A control that cannot work is worse than
       no control: it invites somebody to keep trying, and `notify` refuses the
       send anyway — so the click would spend a request to produce silence.

       AND THE SENTENCE SAYS WHAT IS NOT WRONG. Confirming gates nothing here,
       so somebody reading this can carry on studying; saying so is the
       difference between an explanation and an alarm about something they
       cannot fix from this screen. */
    el.innerHTML =
      '<span class="vb-text"><strong>' + txt('We could not reach you.') + '</strong> ' +
      txt('Our message to') + ' <span class="vb-addr">' + esc(s.email || '') + '</span> ' +
      /* ONE LITERAL ON ONE LINE, however long it runs. Split across lines with
         a `+` it reads better and `check-interface` stops seeing it — which is
         a sentence that quietly ships untranslated, in the banner whose entire
         job is to be understood. It was written the wrong way first and the
         tool caught two of the three strings; this is the third. */
      txt('came back refused, so we have stopped writing to it. You can carry on studying — nothing here depends on it.') + '</span>' +
      '<span class="vb-status" id="vb-status" aria-live="polite"></span>' +
      '<button type="button" class="vb-close" aria-label="' + txt('Dismiss') + '">×</button>';
    return;
  }

  const lead = waiting ? txt('We sent a link to') : txt('We can send a link to');
  const action = waiting ? txt('Resend') : txt('Send');

  el.innerHTML =
    '<span class="vb-text"><strong>' + txt('Confirm your e-mail.') + '</strong> ' +
    lead + ' <span class="vb-addr">' + esc(s.email || '') + '</span></span>' +
    '<button type="button" class="vb-resend">' + action + '</button>' +
    '<span class="vb-status" id="vb-status" aria-live="polite"></span>' +
    '<button type="button" class="vb-close" aria-label="' + txt('Dismiss') + '">×</button>';
}
/* WHO IS LOOKING, SAID ON EVERY SCREEN.

   K-02 gives view-as-student three restraints that ship together or not at all,
   and this is the one that works WHILE it is happening: the audit answers
   afterwards and the expiry bounds a machine left unlocked, but only a banner
   stops somebody forgetting, mid-sentence, that the work in front of them is
   not theirs.

   IT NAMES THE OPERATOR, THE STUDENT AND THE SCHOOL. The console crosses schools
   and a student's screens are served on one, so with two tabs open a banner
   saying only "you are viewing a student" is ambiguous — and "the address bar
   says which" is another way of saying the information lives somewhere nobody
   looks while concentrating. The school comes from this interface's own
   `/api/v1/school`, which it already has; the two names come with the session.

   IT CANNOT BE DISMISSED. The verify banner above has a close button because it
   is a nudge about something the person already knows. This is a statement about
   whose data is on the screen, and a restraint somebody can click away is not
   one. */
function paintViewingBanner() {
  const el = $('#viewing-banner');
  const seen = now().session && now().session.viewing;
  el.hidden = !seen;
  document.body.classList.toggle('viewing-on', Boolean(seen));
  if (!seen) { el.innerHTML = ''; return; }

  const school = (source.school && source.school.name) || '';
  el.innerHTML =
    '<span class="vw-text">' +
      '<strong>' + esc(seen.by || txt('Somebody')) + '</strong> ' +
      txt('is looking at') + ' <strong>' + esc(seen.student || '') + '</strong>' +
      (school ? ' · ' + esc(school) : '') +
      ' — ' + txt('nothing here can be changed') +
    '</span>' +
    '<button type="button" class="vw-stop">' + txt('Stop looking') + '</button>' +
    '<span class="vw-status" id="vw-status" aria-live="polite"></span>';
}

/* ---------- "this page has been open since before the last update" ----------

   `release.js` decides WHEN; this decides what it looks like. The split keeps
   the detection readable on its own, and would let a second surface use the
   same check one day without inheriting a student's markup.

   IT SAYS WHAT IS TRUE AND OFFERS THE ONE ACT. Not "an update is available",
   which is a sentence about software to somebody who is not maintaining any.
   What is true is that this page has been open since before the last release,
   and what fixes it is reloading — the same thing they would do anyway if the
   screen started behaving oddly, except that now they know why.

   NO DISMISS, and not for the viewing banner's reason: this is a nudge and
   could perfectly well have one. It has none because there is nothing to
   dismiss it into. It appears once per tab, at the foot of the window, and a
   second control beside the only one that matters would be two decisions where
   there is one. Reloading is what makes it go away and is what it is for. */
let staleShown = false;
function paintStaleBanner() {
  const el = $('#stale-banner');
  el.hidden = !staleShown;
  if (!staleShown) { el.innerHTML = ''; return; }

  el.innerHTML =
    '<span class="sb-text">' +
      txt('This page has been open since before the last update. Reload it when you are ready.') +
    '</span>' +
    '<button type="button" class="sb-reload">' + txt('Reload') + '</button>';
}

$('#stale-banner').addEventListener('click', (e) => {
  if (!e.target.closest('.sb-reload')) return;
  /* `reload()` AND NOT A CACHE-BUSTING QUERY. Every file this page loaded
     carries `no-cache` and an ETag that is the build, so an ordinary reload
     revalidates all of them and the ones that moved come down again. A query
     string would be a second, weaker copy of a caching rule the server already
     states correctly. */
  globalThis.location.reload();
});

$('#viewing-banner').addEventListener('click', async (e) => {
  const stop = e.target.closest('.vw-stop');
  if (!stop) return;
  const status = $('#vw-status');
  stop.disabled = true;
  if (status) status.textContent = txt('Ending…');
  try {
    await api.stopViewing();
    /* A FULL RELOAD AND NOT A REPAINT. The cookie is gone, so what this browser
       is on this host has changed underneath every module that cached anything
       — and the honest way to show that is to load the page as whoever it is
       now, which for the operator is nobody. */
    globalThis.location.href = '/';
  } catch {
    stop.disabled = false;
    if (status) status.textContent = txt('that did not work — close the tab instead');
  }
});

$('#verify-banner').addEventListener('click', async (e) => {
  if (e.target.closest('.vb-close')) { bannerDismissed = true; paintVerifyBanner(); return; }
  const resend = e.target.closest('.vb-resend');
  if (!resend) return;
  // No state changes here, so the banner does not repaint and this feedback
  // survives until the next visit — by which point the link has been clicked or
  // the nudge is back. Disable on success so one click is one mail.
  const status = $('#vb-status');
  resend.disabled = true;
  if (status) { status.textContent = ''; status.classList.remove('bad'); }
  try {
    await api.resendVerification();
    if (status) status.textContent = txt('Sent — check your inbox.');
  } catch {
    resend.disabled = false;
    if (status) { status.textContent = txt('that did not work — try again'); status.classList.add('bad'); }
  }
});

/* ---------- language: the vitrine's selector, unchanged ---------- */
$('#lang').addEventListener('click', (e) => {
  if (!e.target.closest('.lang-btn')) return;
  const c = $('#lang');
  const opened = c.classList.toggle('is-open');
  c.querySelector('.lang-btn').setAttribute('aria-expanded', String(opened));
  if (opened) closeRail();
});

document.addEventListener('click', (e) => {
  if (!e.target.closest('#lang')) $('#lang').classList.remove('is-open');
  if (!e.target.closest('#account')) $('#account').classList.remove('is-open');
  if (!e.target.closest('#nav-context')) $('#nav-context .ctx-box')?.classList.remove('is-open');
});

/* ---------- theme: the vitrine's localStorage key, on purpose ----
   whoever sets the theme on the site finds the portal already in it */
const THEME_KEY = 'codeschool-theme';
function applyTheme(theme) {
  document.documentElement.dataset.theme = theme === 'light' ? 'light' : '';
  try { localStorage.setItem(THEME_KEY, theme); } catch (e) { /* private mode */ }
  $('#theme-btn').setAttribute('aria-label', theme === 'light' ? txt('Switch to the dark theme') : txt('Switch to the light theme'));
}
$('#theme-btn').addEventListener('click', () => {
  applyTheme(document.documentElement.dataset.theme === 'light' ? 'dark' : 'light');
});

/* ---------- the rail as a drawer, on a narrow screen ----------

   ONE NAVIGATION SURFACE AT A TIME, and the enforcement was half-written. Any
   click outside a bar menu closes it, so opening the drawer already closed the
   track picker, the account menu and the language picker. Nothing went the
   other way: opening one of those left the drawer standing, and the two then
   overlapped.

   Overlapped, not merely coexisted. The bar is `position:fixed; z-index:100`,
   which makes it a stacking context, so a menu inside it cannot rise above the
   drawer's 110 however large its own z-index is — the track names came out
   sliced down their left edge by the drawer sitting on top of them.

   FIXED BY THE INTERACTION AND NOT THE PAINT ORDER, for two reasons. The bar's
   z-index lives in base.css, which is a copy shared with the vitrine and the
   staff console, so raising it there is a change in three repositories to
   settle an argument in one. And the veil deliberately starts at 64px, leaving
   the bar reachable while the drawer is open — that is a decision, and the
   answer to "you can still use the bar" is that using it puts the drawer away,
   not that the two share the screen. */
const closeRail = () => {
  document.body.classList.remove('rail-open');
  $('#rail-btn').setAttribute('aria-expanded', 'false');
  $('#rail-veil').hidden = true;
};
$('#rail-btn').addEventListener('click', () => {
  const opened = document.body.classList.toggle('rail-open');
  $('#rail-btn').setAttribute('aria-expanded', String(opened));
  $('#rail-veil').hidden = !opened;
});
$('#rail-veil').addEventListener('click', closeRail);
$('#rail').addEventListener('click', (e) => {
  const opener = e.target.closest('.ta-open');
  if (opener) {
    // it is a <button> and does not navigate: it only shows or hides that
    // lesson's sections
    toggleLesson(routeParams()?.id, Number(opener.dataset.lesson));
    buildRail(rail, currentPath(), routeParams());
    return;
  }
  if (e.target.closest('a')) closeRail();
});
/* Esc closes whatever is on top, in the order the layers stack: modal, search,
   drawer. Without the order, closing the modal would close the drawer behind it
   — which the person was not even looking at. */
addEventListener('keydown', (e) => {
  if (e.key !== 'Escape') return;
  if (modalOpen()) closeModal();
  else if (searchOpen()) closeSearch();
  else closeRail();
});

/* The search. The button and ⌘K existed from day one and both only led to the
   catalogue — a shortcut that promised search and delivered navigation. */
$('#search-btn').addEventListener('click', openSearch);
addEventListener('keydown', (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); openSearch(); }
  // the slash opens it too, as in almost everywhere that has search — except
  // while typing in a field, where "/" is just a slash
  else if (e.key === '/' && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement?.tagName)) {
    e.preventDefault(); openSearch();
  }
});

/* ---------- the state changed: the frame follows ----------
   The rail and the bar read progress, so marking a lesson has to repaint them —
   otherwise the top bar disagrees with the screen, which is the kind of
   divergence that erodes trust in the number. */
subscribe(() => {
  if (now().session) buildRail(rail, currentPath(), routeParams());
  paintContext();
  paintAccount();
  paintVerifyBanner();
  paintViewingBanner();
});

/* THE ID, WHATEVER NAME THE ADDRESS USED. This feeds `toggleLesson`, which
   remembers which lessons a student opened by course, and the rail, which reads
   that memory back. Left as whatever the address carried, the two keyed by
   different names for one course and a lesson opened under the slug looked shut
   when the same screen was reached by the id. */
function routeParams() {
  const m = currentPath().match(/^\/course\/([^/]+)/);
  if (!m) return null;
  const found = courseByAddress(decodeURIComponent(m[1]));
  return { id: found ? found.id : decodeURIComponent(m[1]) };
}

/* One listener for every code block on every screen — see copy.js. */
wireCopy();

/* ---------- i18n: the vitrine's sequence, in the same order ---------- */
mapTexts();       // walks the text nodes of the static skeleton
/* ---------- the catalogue, before anything reads it ----------

   THIS IS AWAITED AND EVERYTHING ELSE IS NOT, and the difference is what would
   be on the screen without it. `COURSES` and `TRACKS` are two files over there
   and two requests here, and every screen, the rail, the bar and the language
   runtime all read them by name — a first paint before they land is not a
   provisional screen, it is an empty school.

   It is also where the multi-tenancy is: the answer is whichever school the
   address named. */
await source.load(api);

/* The English source strings, snapshotted now that there is a catalogue to
   snapshot. Over there this line sits above, because `COURSES` is a script tag
   and is already in memory when the runtime loads; here it arrives over HTTP,
   and running it first would store the English of an empty array — which is
   what put "cannot read properties of undefined" on the first load of this
   client. */
saveBase();

/* THE SCHOOL'S OWN NAME IN THE BAR. The markup carries `codeschool.ing` because
   it is the portal's, and over there that is the only school there is. Here the
   name is a row, and the bar is the first place somebody with two schools open
   tells one from the other. */
if (source.school && source.school.name) {
  const brand = document.querySelector('.brand-name');
  if (brand) brand.textContent = source.school.name;
}

/* AND ITS OWN COLOUR, which `tenants.accent` has held since the first
   migration and nothing has ever applied. See `accent.js`: it is measured
   against both page backgrounds before it is used, because `--phosphor` is
   text and a colour somebody else chose still has to be readable. */
applyAccent(source.school && source.school.accent);

/* Which track the rail and the bar are about.

   The portal reads a student's ENROLMENT, which is a row over there. Nothing
   records one here — see `api.enrol` — so the first track stands in until
   somebody chooses another from the bar, and choosing writes the document the
   same way. Without this a visitor gets a rail with no path in it, which is
   the school's whole shape missing. */
if (!now().enrollment && TRACKS.length) api.enrol(TRACKS[0].id);

applyLanguage();  // applies content + texts + selector, and rebuilds the screen

/* ---------- who does the SERVER say this is? ----------

   `state.session` is this browser's memory and the cookie is the session
   itself, and they can disagree — see `api.restoreSession`, which is where all
   of that reasoning lives. What is decided HERE is only when to wait for the
   answer, and that is a question about the first paint:

     with a session already stored, the portal draws immediately, as it always
     has. Asking the server costs a round trip that nobody should watch, so the
     answer arrives late and acts only if it disagrees;

     with none, there is nothing to draw but the sign-in screen — so waiting
     costs no paint at all, and NOT waiting costs the returning student a
     sign-in form that flashes up and vanishes, which reads as a broken page.

   With no backend there is nobody to ask and this resolves to `kept` at once,
   which is what keeps the offline bundle and every local run unchanged. */
const restoring = api.restoreSession();

/* NOT AWAITED HERE, unlike the portal. Over there a signed-out student has
   nothing to look at but the sign-in form, so waiting costs no paint. Here they
   have a catalogue and nineteen maps, and holding the first screen for a round
   trip that will usually answer "nobody" would put a spinner in front of the
   one thing this school shows everybody. It acts when it disagrees, below. */

/* The shape of every course, which used to arrive in four `<script>` tags.

   IT IS NOT AWAITED. Every screen that reads a section already copes with a
   course that has nothing written — 119 of 122 do — so a first paint without
   this is provisional rather than broken, and the redraw puts the real shape up
   when it lands. Waiting would put a round trip in front of the first screen in
   order to correct a rail that is about to be correct anyway.

   With no backend it returns at once and `window.LESSONS` still answers, which
   is what leaves the offline bundle exactly as it was. */
api.loadLessonStructure().then(() => { if (booted) redrawAll(); });

paintAccount();
paintVerifyBanner();
paintViewingBanner();
booted = true;
start();

/* AND THE WATCH ON THE BUILD, STARTED AFTER THE FIRST SCREEN IS UP. It makes
   one request at boot to record what this tab was served and then asks nothing
   until the tab is left and come back to, so its place in this sequence is
   about politeness rather than correctness: the first paint should not queue
   behind it. */
release.watch(() => { staleShown = true; paintStaleBanner(); });

restoring.then((outcome) => {
  /* The screen on the page was chosen from what the browser remembered, and the
     server has just contradicted it: re-run the router so the guard at the top
     of this file sends a signed-out student to sign-in, and so a switched
     account's screen is rebuilt from ITS data rather than the previous one's.
     `restored` and `unknown` leave the routing as it stands.

     `KEPT` REDRAWS TOO, AND THAT IS NEW. It used to mean "the two already
     agreed, nothing to do", and it no longer does: a kept session now
     reconciles progress and exams with the server, so by the time this
     resolves the numbers on the screen can be out of date — which is exactly
     what the same account open in two windows looked like. The route does not
     change; the screen is rebuilt from the same store, which is what a
     language switch already does several times a session. */
  if (outcome === 'signed-out' || outcome === 'switched' || outcome === 'kept') dispatch();
});
