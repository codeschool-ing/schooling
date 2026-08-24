/* ==========================================================================
   The server, from the browser — schooling's copy.

   THE SECOND OF THE THREE FILES THAT ARE NOT A COPY. Everything in `app/` other
   than this, `state.js` and `sync.js` is `portal-frontend`'s file unchanged, and
   this is where the difference is absorbed: the portal talks to
   `portal-backend`, which serves ONE school and keeps a student's document; this
   talks to `schooling`, which serves MANY from one deployment and keeps the
   student's work in tables of its own.

   The function names, arguments and return shapes are the portal's, because the
   screens above call them and the screens are the copy.

   ONE ORIGIN, SO NO TOKEN LIVES HERE. The session is an HttpOnly cookie set by
   the server on the host that served this file (P-03). There is no
   Authorization header in this file and there is not meant to be one.

   WHAT SCHOOLING DOES NOT HAVE, SAYS SO. Multi-factor, session revocation and
   enrolment have no route here. They are not stubbed into silence: the two the
   copied screens can reach throw with a sentence naming what is missing, and
   the third is answered locally with a comment saying why that is honest.
   ========================================================================== */

import * as state from './state.js';
import { courseLessons, courseById, trackById } from './catalog.js';
import {
  lessonSections,
  putStructure,
  putCourse,
  structureLoaded as structureIsLoaded,
} from './lessons.js';
/* The four types that close on a comparison. Imported here rather than called
   from the wizard, so that `grade` below is the ONE door — with a paper open it
   is a request, without one it is this, and nothing that renders a question has
   to know which. */
import { gradeLocally } from './exercises/grade.js';

const baked = globalThis.SCHOOLING_BAKED || null;

/* Reading, rather than using: the offline copy is one file opened off a disk,
   where there is no server to reach and every answer is already in the page. */
const reading = Boolean(baked) && globalThis.location.protocol === 'file:';
export const offline = reading;

export class ApiError extends Error {
  constructor(status, code, message) {
    super(message || 'that did not work');
    this.name = 'ApiError';
    this.status = status;
    this.code = code || '';
  }
}

/* ---------- where this visit came from ----------

   READ ONCE, AT LOAD, AND NEVER AGAIN. `document.referrer` names the site that
   sent them and `location.href` still carries the campaign — but only until the
   first fragment route rewrites the address, which happens within a second of
   the app starting. Read here, at module load, both are still the landing.

   IT IS SENT BECAUSE THE SERVER CANNOT SEE IT. The middleware that issues a
   visitor identity is mounted on `/api/v1/`, and the page itself never passes
   through it — so an API call's `Referer` is THIS page, its path is an API
   route, and the campaign parameters were in the address bar and are on no
   request at all. The three fields a first touch is made of came out as: the
   site's own name, an API route, and nothing.

   NOTHING HERE IS NEWLY TRUSTED. A `Referer` is a header the caller sets, a
   path is what they asked for, a campaign is a query string; all three were
   already theirs to choose. The server takes these only while it has no
   visitor, and bounds them exactly as it bounds a query parameter. */
const landing = (() => {
  if (reading) return null;
  try {
    return {
      href: String(globalThis.location.href).slice(0, 512),
      referrer: String(globalThis.document.referrer || '').slice(0, 512),
    };
  } catch (e) {
    return null; // no document at all: a worker, or a harness
  }
})();

async function request(method, path, body) {
  if (reading) {
    if (method === 'GET' && Object.hasOwn(baked.answers, path)) return baked.answers[path];
    if (path === '/api/v1/me') throw new ApiError(401, 'anonymous', 'nobody is signed in');
    throw new ApiError(0, 'no-server',
      'This is the offline copy. Reading works; signing in, progress and exams need the school.');
  }

  const headers = body === undefined ? {} : { 'Content-Type': 'application/json' };
  if (landing) {
    headers['X-Schooling-Landing'] = landing.href;
    // Sent even when empty, because empty MEANS something: they typed the
    // address or followed a bookmark. Left out, the server would fall back to
    // this request's own `Referer`, which is this page.
    headers['X-Schooling-Landing-Referrer'] = landing.referrer;
  }

  let response;
  try {
    response = await fetch(path, {
      method,
      credentials: 'same-origin',
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch (e) {
    if (baked && method === 'GET' && Object.hasOwn(baked.answers, path)) {
      return baked.answers[path];
    }
    throw new ApiError(0, 'offline', 'the server could not be reached');
  }

  if (response.status === 204) return null;

  let payload = null;
  try { payload = await response.json(); } catch (e) { /* empty or non-JSON */ }

  if (!response.ok) {
    const error = (payload && payload.error) || {};
    throw new ApiError(response.status, error.code, error.message);
  }
  return payload;
}

/* Exported because `app/source.js` fills the catalogue with it. Nothing else
   outside this file uses it: the screens call the named functions below, which
   is what keeps the routes in one place. */
export const get = (path) => request('GET', path);
const post = (path, body) => request('POST', path, body === undefined ? {} : body);
const put = (path, body) => request('PUT', path, body);
const enc = encodeURIComponent;

/* The portal's `echo`: a resolved promise around what is already in memory, so
   a caller may await it without knowing which answers cost a request. */
const echo = (v) => Promise.resolve(v);

/* ---------- who ---------- */

export const session = () => echo(state.now().session);
export const configured = () => !reading;

/* Everything the school knows about this student, in one hydrate.

   FIVE REQUESTS AND NOT ONE, because they are five modules and each owns its
   own tables — which is the rule this platform is built on (X-02) and not an
   accident of the routes. They are asked for together and the document is
   replaced once, so no screen ever sees a half-filled student.

   A FAILURE OF ANY ONE IS NOT A FAILURE OF THE SIGN-IN. Somebody whose notes
   could not be read can still study; the alternative is a student who cannot
   get in because a report is down. */
async function pull() {
  const [completed, notes, exams, resume] = await Promise.all([
    get('/api/v1/progress/sections').catch(() => null),
    get('/api/v1/notes').catch(() => null),
    get('/api/v1/exams/attempts').catch(() => null),
    get('/api/v1/resume').catch(() => null),
  ]);
  return { completed, notes, exams, resume };
}

/* THE SERVER KEYS BY LESSON ID AND THE SCREENS KEY BY LESSON INDEX, and this
   pair of maps is the one translation this file exists to do.

   Neither side is being awkward. An id is stable across a reordering, which is
   why the server has one; and over there a lesson IS a position in the course's
   `topics`, which is what the copied screens were written against.

   THEY USED TO BE JOINED BY THE TITLE. Both sides took their lessons from the
   same list — the course's technical topics — so the title was the same string
   on both, and it was the portal's own join key long before this. It held right
   up until somebody edited a sentence.

   A topic declares its id now, and that id IS the lesson id. There is nothing
   left to look up: `courseLessons` hands back the key and the key is the
   answer. The map that used to translate one into the other is gone, and with
   it the two functions that searched it in either direction. */

function lessonIdOf(courseId, ix) {
  const lesson = courseLessons(courseId)[ix];
  return lesson ? lesson.key : null;
}

// Where a lesson sits in the course. The store keys on the position, and the
// position is where the id appears in the course's declared topics.
function indexOfLesson(courseId, lessonId) {
  return courseLessons(courseId).findIndex((a) => a.key === lessonId);
}

function documentFrom({ completed, notes, exams, resume }, me) {
  const progress = {};
  ((completed && completed.completed) || []).forEach((row) => {
    const ix = indexOfLesson(row.course, row.lesson);
    if (ix < 0) return;   // a lesson the catalogue no longer has
    progress[row.course] = progress[row.course] || { lessons: {} };
    const lesson = progress[row.course].lessons[ix] || { sections: {}, exercises: {} };
    lesson.sections[row.section] = true;
    progress[row.course].lessons[ix] = lesson;
  });

  const byCourse = {};
  ((notes && notes.notes) || []).forEach((n) => {
    const ix = indexOfLesson(n.course, n.lesson);
    if (ix < 0) return;
    byCourse[n.course] = byCourse[n.course] || {};
    byCourse[n.course][ix] = byCourse[n.course][ix] || {};
    byCourse[n.course][ix][n.section] = n.body;
  });

  const sat = {};
  ((exams && exams.attempts) || []).forEach((a) => {
    if (!a.result) return;
    const key = `${a.scope || 'course'}:${a.exam}`;
    const before = sat[key] || { attempts: 0, best: 0, passed: false };
    const pct = a.result.of ? Math.round((a.result.score / a.result.of) * 100) : 0;
    sat[key] = {
      attempts: before.attempts + 1,
      best: Math.max(before.best, pct),
      passed: before.passed || Boolean(a.result.passed),
      lastPct: pct,
      lastAt: a.handed_in_at || a.started_at,
    };
  });

  const newest = ((resume && resume.resume) || [])[0];
  const last = newest && indexOfLesson(newest.course, newest.lesson) >= 0
    ? {
      courseId: newest.course,
      lessonIx: indexOfLesson(newest.course, newest.lesson),
      sectionId: newest.section,
    }
    : null;

  return {
    /* `secondFactor` and `mfaRequired` are the server's two different answers:
       whether the ACCOUNT has one, and whether THIS SITTING still owes a code.
       The account screen reads the first and the sign-in screen the second. */
    session: me ? {
      name: me.name,
      email: me.email,
      emailVerified: true,
      secondFactor: Boolean(me.secondFactor),
      mfaRequired: Boolean(me.mfaRequired),

      /* AND WHETHER SOMEBODY IS LOOKING AT THIS RATHER THAN LIVING IN IT.

         The third of K-02's three restraints is a visible banner, and it is the
         only one of the three that works while the viewing is happening — the
         audit answers afterwards and the expiry bounds a machine left unlocked.
         So it arrives with the session rather than being asked for separately:
         a screen that could draw itself before learning this is a screen that
         can draw itself without the banner. */
      viewing: me.viewing || null,
    } : null,
    progress,
    notes: byCourse,
    exams: sat,
    account: me ? { planId: me.plan || 'guest', since: me.created_at || null } : null,
    last,
  };
}

export async function restoreSession() {
  let me = null;
  try {
    me = await get('/api/v1/me');
  } catch (e) {
    state.hydrate({});          // a visitor, which is half of this platform's traffic
    return null;
  }
  state.hydrate(documentFrom(await pull(), me));
  return state.now().session;
}

export async function signIn({ email, password }) {
  const me = await post('/api/v1/sign-in', { email, password });
  state.hydrate(documentFrom(await pull(), me));
  return state.now().session;
}

export async function register({ name, email, password }) {
  const me = await post('/api/v1/sign-up', { name, email, password });
  state.hydrate(documentFrom(await pull(), me));
  return state.now().session;
}

/* Ending a viewing, which is the banner's one button.

   IT IS NOT UNDER `/api/v1/`, and that is the server's doing rather than a
   convention here: everything under that prefix refuses a viewing session
   anything but a GET, and a banner whose only control the rule refuses would be
   a joke at somebody's expense. Ending a viewing is not acting as the student;
   it is the opposite. */
export const stopViewing = () => post('/viewing/stop');

export async function signOut() {
  try { await post('/api/v1/sign-out'); } catch (e) { /* the cookie may already be gone */ }
  /* Their work goes with them. A document left in memory after signing out is
     one person's progress shown to whoever is at the machine next. */
  state.hydrate({});
}

/* ---------- the second factor ----------

   THIS FILE USED TO REFUSE. `completeMfa` rejected with "this school does not
   have multi-factor sign-in yet" — true of THIS FILE and never of the server:
   `/api/v1/second-factor/{start,enrol,present}` have existed for as long as
   staff roles have, and the sign-in screen's code step was reached by a
   `mfaRequired` flag nothing ever sent.

   So an account could have a second factor, be refused at the console without
   it, and have no way through this interface to present one. That is how the
   first factor on this platform came to be enrolled by hand, in the browser's
   own console, against the API. */

// completeMfa presents a code on this sitting: the app's six digits, or one of
// the recovery codes.
export async function completeMfa(code) {
  await post('/api/v1/second-factor/present', { code });
  state.hydrate(documentFrom(await pull(), await get('/api/v1/me')));
  return state.now().session;
}

// startSecondFactor asks for a secret. NOTHING IS STORED BY IT — the enrolment
// writes, and only once a code from that secret has arrived, so a person who
// abandons this halfway is not left with a factor they never scanned.
export const startSecondFactor = () => post('/api/v1/second-factor/start');

// enrolSecondFactor proves the secret and returns the recovery codes, which are
// readable exactly here and never again.
export async function enrolSecondFactor(secret, code) {
  const out = await post('/api/v1/second-factor/enrol', { secret, code });
  state.hydrate(documentFrom(await pull(), await get('/api/v1/me')));
  return out.recoveryCodes || [];
}

export const recoveryCodesLeft = () => get('/api/v1/second-factor/recovery-codes');

// reissueRecoveryCodes replaces the set: whatever was written down before this
// call returned has stopped working.
export async function reissueRecoveryCodes() {
  const out = await post('/api/v1/second-factor/recovery-codes');
  return out.recoveryCodes || [];
}

/* ---------- the track a student is on ---------- */

export const enrolment = () => echo(state.now().enrollment);

/* NOTHING RECORDS AN ENROLMENT ON THIS SIDE, so this writes the document and
   not the server, and that is honest rather than a stub.

   Over there enrolment is a row, because the portal is one school and the
   student picks one path through it. Here the same question is answered by the
   address and the screen: the track being looked at is the track in view, and
   choosing another is navigating to it. Recording it would be a second place
   for the answer to live, disagreeing with the first the moment somebody opens
   a different map.

   What it must still do is move the rail and the bar, which read the document —
   so the document is written and the caller navigates. */
export function enrol(trackId) {
  state.replaceEnrollment({ ...(state.now().enrollment || {}), trackId });
  return echo(state.now().enrollment);
}

export function chooseOption(trackId, index, option) {
  const e = state.now().enrollment || {};
  const choices = { ...(e.choices || {}), [`${trackId}:${index}`]: option };
  state.replaceEnrollment({ ...e, trackId: e.trackId || trackId, choices });
  return echo(state.now().enrollment);
}

/* ---------- the material ---------- */

/* Which language the prose in the store was fetched in. The runtime redraws on
   a language switch and the paragraphs came from a request that named one, so
   the store has to be dropped when it moves — see `redrawAll` in main.js. */
let loadedLocale = null;
/* And the language the SHAPE was fetched in, which is a second answer and moves
   on its own. The shape carries the section titles — what the rail, the section
   strip and the "pick up where you left off" card call a place — and over there
   those are in a file per language; here they are rows, asked for by locale
   like everything else. Tracked separately because a student who has opened no
   lesson has a shape and no prose, and the switch has to reach it anyway. */
let structureLocale = null;
/* WHICH LANGUAGE IS ON SCREEN, ASKED OF THE DOCUMENT.

   `i18n-runtime.js` keeps its `LANG` to itself — it is a module-local `const`
   with no accessor — and the one thing it does publish is
   `document.documentElement.lang`, which it writes on load and rewrites on
   every switch. So that is the source: it cannot drift from what the runtime
   is showing, because it is what the runtime showed.

   THE PREVIOUS LINE ASKED FOR `globalThis.contentLocale`, WHICH DOES NOT
   EXIST — not here, and not in `portal-frontend` either; it was invented by
   this adapter and nothing ever defined it. It failed the way a made-up global
   fails: silently, always falling to the default, so every request for the
   material asked for English and a student reading in Portuguese was served
   English paragraphs with a Portuguese interface around them.

   `pt-BR` is the document's tag and `pt` is the locale the school's rows are
   keyed by, so the region is dropped. */
const wanted = () => {
  const tag = (document.documentElement.lang || 'en').toLowerCase();
  return tag.split('-')[0];
};

export function languageChanged() {
  return (loadedLocale !== null && loadedLocale !== wanted())
    || (structureLocale !== null && structureLocale !== wanted());
}

export const structureLoaded = () => structureIsLoaded();

/* The shape of every course — lessons and sections, no prose — in one request.
   It is what the rail and every denominator are drawn from. */
export async function loadLessonStructure() {
  const locale = wanted();
  const answer = await get(`/api/v1/lessons?lang=${enc(locale)}`).catch(() => null);
  if (!answer) return false;
  structureLocale = locale;

  /* The store is keyed by the lesson's ID, because that is what `courseLessons`
     produces as a key: a lesson is a topic of the course somebody has written,
     and a topic declares its id.

     IT USED TO BE THE TITLE, on both sides, and that is what made a lesson
     unreachable the moment its wording changed anywhere.

     A LIST OF COURSES AND NOT A MAP OF THEM, because that is what
     `putStructure` iterates. The server answers a map keyed by course, which is
     the cheaper shape over the wire; the store wants `{ courseId, lessons }`. */
  const structure = [];
  Object.entries(answer.lessons || {}).forEach(([courseId, lessons]) => {
    structure.push({ courseId, lessons: lessons.map((l) => ({
      /* `lessonIx` IS WHAT THE STORE LOOKS A LESSON UP BY. `writtenSections`
         finds a lesson with `source.find((x) => x.lessonIx === ix)`, and
         without it every lookup missed and every lesson fell back to the
         "one section called Content" placeholder — which is what put
         "2 sections" on a course whose lessons have four. */
      lessonIx: indexOfLesson(courseId, l.id),
      key: l.id,
      title: l.title,
      sections: (l.sections || []).map((s) => ({
        id: s.id,
        title: s.title || s.id,
        ...(s.kind === 'video' ? { video: true } : {}),
        ...(s.duration ? { duration: s.duration } : {}),
        countable: s.countable !== false,
      })),
    })) });
  });

  putStructure(structure);
  return true;
}

/* ---------- THE MATERIAL ARRIVES AS TEXT AND IS DRAWN AS BLOCKS ----------

   `text.js` renders a LIST: a string is a paragraph, an array is a bullet list,
   `{ code, text }` is a code block, `{ image | svg, caption }` is a figure and
   `{ example }` is the annotated, Go-By-Example column. It is not markdown, and
   its own comment says why it is not — a dialect invented now is a migration
   later.

   This school stores a section's words as one text field, authored as markdown
   in `content/`. So the two have to meet, and this is where.

   IT BROKE LOUDLY AND LOOKED QUIET. `prose(body)` starts `body.map(...)`, and a
   string has no `.map` — so the moment a section with words in it reached the
   screen the render threw, the dispatch chain swallowed it, and the lesson
   stayed on the placeholder it had been drawn with a moment earlier. Every
   section that is a video rendered, because a video has no prose; every section
   that is READING did not, in either language. That is what "the material lands
   in Stage 2" was on screen for.

   MARKDOWN SPELLS THREE OF THE FIVE — paragraph, bullet list, fenced code with
   its language. The other two have no markdown of their own, so the content
   files carry them as a fence whose info string names the block and whose body
   is the block as JSON. It is a fence to every markdown reader, including the
   ones nobody has written yet, and one `switch` here. `tools/…/reimport` wrote
   them; this reads them. */
function blocksOf(text) {
  if (typeof text !== 'string') return text;   // already a list: the offline copy

  const out = [];
  const lines = text.split('\n');
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];

    if (line.startsWith('```')) {
      const kind = line.slice(3).trim();
      const body = [];
      i += 1;
      while (i < lines.length && !lines[i].startsWith('```')) { body.push(lines[i]); i += 1; }
      i += 1;                                   // the closing fence
      const inside = body.join('\n');
      if (kind === 'schooling-example' || kind === 'schooling-figure' || kind === 'schooling-block') {
        try {
          const parsed = JSON.parse(inside);
          out.push(kind === 'schooling-example' ? { example: parsed } : parsed);
        } catch (e) {
          out.push(inside);                     // unreadable: the words, at least
        }
      } else {
        out.push({ code: kind, text: inside });
      }
      continue;
    }

    if (line.startsWith('- ')) {
      const items = [];
      while (i < lines.length && lines[i].startsWith('- ')) { items.push(lines[i].slice(2)); i += 1; }
      out.push(items);
      continue;
    }

    if (line.trim() === '') { i += 1; continue; }

    // A paragraph, which the content files write on one line and a person
    // editing one may well wrap. It ends at a blank line or at a fence.
    const paragraph = [];
    while (i < lines.length && lines[i].trim() !== ''
           && !lines[i].startsWith('```') && !lines[i].startsWith('- ')) {
      paragraph.push(lines[i]);
      i += 1;
    }
    out.push(paragraph.join(' '));
  }
  return out;
}

/* One course's prose. It is the request the paywall refuses, which is why it is
   per course and not part of the structure above. */
export async function loadCourseContent(courseId) {
  const lessons = courseLessons(courseId);
  if (!lessons.length) return false;

  const locale = wanted();
  const fetched = await Promise.all(lessons.map((a, ix) => {
    const id = lessonIdOf(courseId, ix);
    if (!id) return null;   // announced and not yet written
    return get(`/api/v1/courses/${enc(courseId)}/lessons/${enc(id)}?lang=${enc(locale)}`)
      .catch(() => null);
  }));

  const out = [];
  fetched.forEach((lesson, ix) => {
    if (!lesson) return;
    out.push({
      lessonIx: ix,
      key: lessons[ix].key,
      title: lesson.title || lessons[ix].title,
      sections: (lesson.sections || []).map((s) => ({
        id: s.id,
        title: s.title || s.id,
        ...(s.body ? { body: blocksOf(s.body) } : {}),
        ...(s.kind === 'video' ? { video: true } : {}),
        ...(s.duration ? { duration: s.duration } : {}),
        countable: s.countable !== false,
      })),
    });
  });

  loadedLocale = locale;
  putCourse(courseId, out);
  return true;
}

/* THE QUESTIONS ARE HERE AND THIS ROUTE IS NOT.

   They were imported — 36 of them, across four courses — and they are reachable:
   the drill draws one and marks it. What is missing is the route that answers
   "the questions in THIS lesson", and it is missing for a reason worth writing
   down rather than left as a stub nobody revisits.

   A lesson's assessment cannot be served with the answers in it, because that is
   an assessment you pass by reading the response. So it needs the same
   present-then-mark pair the drill uses, scoped to a lesson — and the drill's
   own two routes cannot be reused for it, because they check `drillable`, which
   is precisely what keeps an exam-only question out of a student's reach.

   It answers an empty list until then, which is a state every screen here
   already handles: 118 of the 122 courses have no questions either. */
export function lessonExercises() {
  return [];
}

/* ---------- progress ---------- */

export const progress = () => echo(state.now().progress);

/* COMPLETION IS SET-TRUE AND NEVER TOGGLED (A-05). The portal's signature
   carries `done`, and un-completing is refused here rather than sent — a bar
   that moves backwards for somebody who did nothing wrong is the thing that
   rule exists to prevent. */
export function completeSection(courseId, ix, sectionId, done = true) {
  if (!done) return echo(null);
  const lesson = lessonIdOf(courseId, ix);
  if (!lesson) return echo(null);
  return post(`/api/v1/progress/${enc(courseId)}/${enc(lesson)}/${enc(sectionId)}/complete`);
}

export function visitSection(courseId, ix, sectionId) {
  const lesson = lessonIdOf(courseId, ix);
  if (!lesson) return echo(null);
  return post(`/api/v1/progress/${enc(courseId)}/${enc(lesson)}/${enc(sectionId)}/visit`);
}

export function saveNote(courseId, ix, sectionId, body) {
  const lesson = lessonIdOf(courseId, ix);
  if (!lesson) return echo(null);
  return put(`/api/v1/notes/${enc(courseId)}/${enc(lesson)}/${enc(sectionId)}`, { body });
}

/* ---------- something here is wrong ---------- */

/* THE ONE DIRECTION NOTHING ELSE IN THE INTERFACE RUNS IN. Every other call in
   this file reads the material or records what the student did with it; this
   one says the material itself is wrong, which is the only channel by which a
   wrong answer key comes back from the person who found it.

   IT IS FETCHED ONCE AND KEPT, and it is not fetched at all until somebody
   opens the control. Most people never will, and a request per lesson view to
   populate a form nobody opened is a request per lesson view. The answer also
   carries the sections this student has already reported, which is what lets
   the form say "you told us this" instead of inviting them to say it twice. */
let reportsHeld = null;

export function reportable() {
  if (reportsHeld) return reportsHeld;
  reportsHeld = get('/api/v1/reports');
  return reportsHeld;
}

export function reportSection(courseId, ix, sectionId, reason, note) {
  const lesson = lessonIdOf(courseId, ix);
  if (!lesson) return echo(null);
  return post('/api/v1/reports', {
    courseId, lessonId: lesson, sectionId, reason, note,
  }).then((answer) => {
    // What is held is now out of date by exactly one report, and the next
    // section they open has to know. Dropped rather than patched: a cache
    // updated by hand is a cache that disagrees with the server eventually.
    reportsHeld = null;
    return answer;
  });
}

/* Where the student stopped — and now with the SECTION, not just the lesson.
   Returning the top of a four-hour lesson is returning the person to scrolling;
   it is the difference between the feature being useful and being decorative.

   It falls back to the first section of the track when there is no history yet,
   instead of returning null and forcing every screen to invent a fallback.

   THE PORTAL'S FUNCTION, RESTORED. This adapter first shortened it to "whatever
   `last` says", which reads as correct and is not: `last` is empty until
   somebody has opened a section, so the "pick up where you left off" card —
   the first thing on the dashboard and the one that says what to do next —
   never appeared for anybody who had not already started. It is not a server
   question either; every value it reads is the catalogue and this browser's own
   document, which is why it can be the portal's line for line. */
export function resumeFrom() {
  const e = state.now();
  const firstSection = (courseId, ix) => {
    const a = courseLessons(courseId)[ix];
    return a ? lessonSections(courseId, a.key)[0]?.id : undefined;
  };

  if (e.last && courseById(e.last.courseId)) {
    const { courseId, lessonIx } = e.last;
    return echo({ ...e.last, sectionId: e.last.sectionId || firstSection(courseId, lessonIx) });
  }
  const t = e.enrollment && trackById(e.enrollment.trackId);
  if (!t) return echo(null);
  const first = t.courses.find((i) => typeof i === 'string');
  if (!first) return echo(null);
  return echo({ courseId: first, lessonIx: 0, sectionId: firstSection(first, 0) });
}

/* ---------- exams ----------

   THIS IS WHERE THE PAPER IS TRANSLATED, AND IT WAS NOT BEING TRANSLATED.

   `exams.js` is the portal's and speaks of an attempt: `{id, responses,
   questions}`, where a question IS the exercise the wizard renders. This server
   speaks of a paper: `{paper: {attempt, questions: [{position, exercise,
   version, type, question}]}}`, where the exercise is one field inside a
   wrapper that also says where it sits and what it is called.

   The three functions below were the envelope handed straight through, so
   `exams.js` read `attempt.questions` off an object whose only key was `paper`
   and threw `Cannot read properties of undefined (reading 'map')` before the
   screen rendered anything. The exam route was the one screen nobody could
   open, and it stayed that way because the accessibility suite was asking for
   the retired client's address and being told, accurately, that there was no
   exam to sit.

   Reconciling the two shapes belongs HERE and not in `exams.js`: that file is a
   copy, and a copy that learns this server's field names is a copy that has to
   be re-merged by hand for ever. */

export const examOnServer = () => !reading;

/* A paper as an attempt.

   THE POSITION RIDES ON THE EXERCISE. Recording an answer is a PUT to
   `.../answers/{position}`, and by then all the wizard is holding is the
   exercise it rendered — so the position of the question on this paper is
   carried on it. It is a property of this attempt rather than of the exercise,
   which is why it is attached here and not expected from the catalogue.

   `responses` is what the student already gave, echoed by the server so a
   reopened paper shows their own work. Keyed by position, which is what the
   answer route takes. */
function attemptFrom(paper) {
  const questions = paper.questions || [];
  const responses = {};
  questions.forEach((q) => {
    if (q.answer !== undefined && q.answer !== null) responses[q.position] = q.answer;
  });
  return {
    id: paper.attempt,
    responses,

    /* THE MARK THIS PAPER IS HELD TO, carried through rather than dropped.
       This function reshapes the server's paper into what the wizard wants, and
       a field it does not name is a field that arrives as `undefined` at the
       screen — which for this one would fall back to the school's number and
       look right, while a paper judged under an older constant quietly stopped
       reporting the rule it was actually held to. */
    passMark: paper.pass_mark,

    questions: questions.map((q) => ({
      ...shownAsExercise(q.question || {}),
      position: q.position,
      /* The course the question came from, which the wrapper does not carry and
         the renderers need: a labelling question's diagram is addressed under
         its course. On a course exam that is the exam itself; on a track exam
         the server does not say, and a diagram then cannot be found — which the
         renderer reports rather than drawing a frame around nothing. */
      course: paper.scope === 'course' ? paper.exam : (q.question || {}).course,
    })),
  };
}

/* One shown question, in the vocabulary the renderers speak.

   ONLY `matching` DIFFERS, and it differs in a way that throws rather than
   looking odd. This server presents one as two parallel arrays — `left` and
   `right`, the second shuffled and the pairing gone — because the pairing IS
   the answer. The portal's renderer reads `ex.pairs.map(p => p.left)` for the
   left-hand column whatever mode it is in, and `ex.rights` for the shuffled
   right-hand one, which is the shape ITS server sends.

   So the columns are put where that renderer looks for them. It is done here,
   in the adapter, for the same reason the envelope above is: `exercises/` is a
   copy, and a copy that learns this server's field names is a copy somebody has
   to re-merge by hand for ever. */
function shownAsExercise(shown) {
  /* `hint` on the wire, `socraticHint` in the renderers. One field, two names,
     and the renderers keep theirs: they are the portal's files unchanged, and a
     rename there to please this server is the edit that stops them being a
     copy. The exam never shows it — a hint on a paper is a cheat sheet — so
     this only ever reaches a screen through a drill or a lesson. */
  const out = shown.hint ? { ...shown, socraticHint: shown.hint } : { ...shown };

  if (shown.type !== 'matching' || !Array.isArray(shown.left)) return out;
  return {
    ...out,
    pairs: shown.left.map((left) => ({ left })),
    rights: shown.right || [],
  };
}

/* Where a course's picture lives.

   A BARE FILE NAME IS ALL A QUESTION CARRIES; which address it is under is the
   course's business, and this is the one place that knows. Offline it is a data
   URI baked into the page under the very same key — see the bundler, which
   builds these addresses to key them by.

   Empty when there is no course to hang it on, and the renderer says so rather
   than drawing an image that will not load: a diagram that fails is a question
   a student cannot answer however well they know the material. */
export function asset(courseId, name) {
  if (!courseId || !name) return '';
  const path = `/api/v1/courses/${enc(courseId)}/images/${enc(name)}`;
  if (reading) return (baked && baked.pictures && baked.pictures[path]) || '';
  return path;
}

/* THE LANGUAGE GOES WITH THE START AND NOWHERE ELSE. A paper is drawn once and
   copied onto the attempt, so this is the only moment that can decide which
   language it is in — and a student who changes language halfway through keeps
   the paper they were given, which is what a paper is. Sending it on every
   answer would suggest otherwise. */
export async function startExam(scope, scopeId) {
  const answer = await post(
    `/api/v1/exams/${enc(scope)}/${enc(scopeId)}/start?lang=${enc(wanted())}`);
  return attemptFrom(answer.paper);
}

/* One answer.

   INSIDE AN EXAM NOTHING COMES BACK ABOUT WHETHER IT WAS RIGHT, and that is the
   server's rule rather than an omission here: the paper is not marked until it
   is handed in, and a reply that differed for a correct answer would be a
   grader a client could run one question at a time. So this answers `correct:
   null` — recorded, not judged — which is exactly what the wizard draws as
   "recorded" and what `examScore` counts as pending.

   WITH NO ATTEMPT IT GRADES HERE. That is the lesson assessment and the offline
   copy, where there is no paper and no server: four of the seven types close on
   a comparison and the other three say they cannot. Same function, because the
   wizard must not know which one it is in. */
export async function grade(ex, answer, attempt) {
  if (!attempt) return gradeLocally(ex, answer);

  await put(`/api/v1/exams/attempts/${enc(attempt)}/answers/${enc(ex.position)}`,
    { answer: answerForServer(ex, answer) });
  return { correct: null, recorded: true };
}

/* An answer in the shape this server grades.

   THE RENDERERS SPEAK A DIFFERENT DIALECT AND THEY ARE NOT GOING TO STOP. Each
   `collect` was written for the portal's own backend and returns what was
   convenient there — a bare index for a quiz, the item TEXTS in order for an
   ordering, the right-hand text per left-hand slot for a matching. This server
   grades by position everywhere, because an exercise is immutable within a
   version and a position cannot be mistyped.

   Translating here keeps `exercises/` a copy. It also keeps the failure loud:
   an ordering sent as a list of strings came back "That answer did not reach
   the server", on the one screen where an answer that does not arrive is a mark
   that cannot be earned.

   POSITIONS ARE INTO WHAT WAS SHOWN, not into the original question. The server
   shuffled the paper and remembers the permutation — `restore` maps them back —
   so the honest index is the one the student was looking at.

   A type not named here is already in the right shape and is passed through
   whole. That is the default on purpose: a new type on the server arrives as a
   payload this file has never seen, and guessing at it would be worse than
   sending what the renderer built. */
function answerForServer(ex, answer) {
  switch (ex.type) {
    case 'quiz':
      return { chose: answer === null || answer === undefined ? [] : [answer] };

    case 'multiple-choice':
      return { chose: Array.isArray(answer) ? answer : [] };

    case 'ordering': {
      // The texts the student put in order, back to where each one was shown.
      const shown = ex.items || [];
      return { order: (answer || []).map((text) => shown.indexOf(text)) };
    }

    case 'matching': {
      /* `collect` gives the right-hand TEXT chosen for each left-hand slot, in
         the exercise's own left order. The server wants which of the shuffled
         right-hand items that was. An empty slot is -1 rather than dropped: the
         grader reads this position by position, and a shorter list would move
         every answer after the gap onto the wrong pair. */
      const rights = ex.rights || [];
      return { matched: (answer || []).map((text) => (text ? rights.indexOf(text) : -1)) };
    }

    case 'expression-answer':
      return { expression: String(answer ?? '') };

    default:
      return answer;
  }
}

export async function submitExam(attemptId) {
  const answer = await post(`/api/v1/exams/attempts/${enc(attemptId)}/hand-in`);
  const paper = answer.paper || {};
  const result = paper.result || {};
  const questions = paper.questions || [];

  /* BY EXERCISE ID, because that is what the wizard holds. It replaces what
     grading produced, which in a server-drawn exam was `null` for every
     question — without this the dots stay grey and the score is a lie.

     A question with no verdict is one the server has not marked, and it is left
     out rather than defaulted to wrong: `pending` below is how the screen says
     so, and a false zero would be worse than a blank. */
  const verdicts = {};
  questions.forEach((q) => {
    if (q.correct === true || q.correct === false) verdicts[q.exercise] = { correct: q.correct };
  });

  const judged = result.of || 0;

  /* The result changes what the certificates screen may claim, so the document
     is refreshed rather than patched from the response — the server is the
     authority on whether an exam was passed. */
  const me = await get('/api/v1/me').catch(() => null);
  if (me) state.hydrate(documentFrom(await pull(), me));

  return {
    pct: judged ? Math.round(((result.score || 0) / judged) * 100) : 0,
    passed: !!result.passed,
    correct: result.score || 0,
    judged,
    pending: Math.max(0, questions.length - judged),
    verdicts,

    /* THE MARK THIS PAPER WAS JUDGED BY, which is stored on the attempt and is
       not necessarily today's constant. Moving the pass mark changes what a NEW
       attempt has to reach and nothing about an old one, so a result shown
       beside today's number would explain itself with a rule nobody applied to
       it. */
    passMark: result.pass_mark,
  };
}

/* ---------- the drill ----------

   The schedule is the server's: which question a student is closest to
   forgetting is computed from their own history, so there is nothing to keep
   in this browser and nothing to reconcile. */
export const practiceQueue = () => get('/api/v1/practice');

/* One card, drawn now.

   IT IS A POST BECAUSE IT WRITES. Drawing shuffles the question and the server
   writes down the arrangement, so that the answer coming back can be mapped
   onto the question as it was written. A GET that changed the shuffle on every
   retry would be a card that moves under somebody who reloaded.

   It comes back with no key in it — see the server — so there is nothing here
   that can mark it, which is the point rather than a limitation. */
export async function practiceDraw(exerciseId) {
  const card = await post(`/api/v1/practice/${enc(exerciseId)}/draw?lang=${enc(wanted())}`);
  return {
    ...shownAsExercise(card.question || {}),
    id: card.exercise,
    type: card.type,
    course: card.course,
  };
}

/* The answer, and what comes back with the verdict.

   THE ELAPSED TIME IS PART OF THE ANSWER. The schedule is derived from whether
   it was right and how long it took — never from asking the student how well
   they felt they remembered (A-04) — so a drill that did not measure would be
   handing the scheduler half of what it needs. */
export const practiceAnswered = (exerciseId, answer, elapsedMs) =>
  post(`/api/v1/practice/${enc(exerciseId)}/answered?lang=${enc(wanted())}`,
    { answer, elapsed_ms: Math.max(0, Math.round(elapsedMs)) });

/* One drilled answer, in the renderers' dialect on the way in and the shape
   `applyKey` reads on the way out.

   IT IS `grade`'s THIRD CASE and lives beside it for that reason: the same
   translation table serves the exam and the drill, because both are marked by
   the same grader against the same payload. The difference is only WHEN the key
   comes back — at submit for a paper, immediately here. */
export async function drill(ex, answer, elapsedMs) {
  return practiceAnswered(ex.id, answerForServer(ex, answer), elapsedMs);
}

/* ---------- the two documents ----------

   OUTSIDE EVERY GATE, and the only route here that is. No session, no plan, no
   school of the reader's — see `screens/legal.js`. The offline copy answers
   them from what was baked, which is why they are the one thing a bundle must
   never say "this needs the school" about. */
export const legal = (document, lang) =>
  get(`/api/v1/legal/${enc(document)}?lang=${enc(lang || 'en')}`);

/* ---------- certificates ---------- */

export const certificatesOnServer = () => !reading;

export async function certificates() {
  const answer = await get('/api/v1/certificates');
  return (answer && answer.certificates) || [];
}

/* The printed address, which is a path and not a fragment: it is read off paper
   and typed by somebody checking a stranger's claim. */
export const certificateUrl = (code) => `/verify/${enc(code)}`;
