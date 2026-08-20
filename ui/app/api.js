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
import { courseLessons } from './catalog.js';
import { putStructure, putCourse, structureLoaded as structureIsLoaded } from './lessons.js';

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

async function request(method, path, body) {
  if (reading) {
    if (method === 'GET' && Object.hasOwn(baked.answers, path)) return baked.answers[path];
    if (path === '/api/v1/me') throw new ApiError(401, 'anonymous', 'nobody is signed in');
    throw new ApiError(0, 'no-server',
      'This is the offline copy. Reading works; signing in, progress and exams need the school.');
  }

  let response;
  try {
    response = await fetch(path, {
      method,
      credentials: 'same-origin',
      headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
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

   THEY ARE JOINED BY THE TITLE, and that is safe here for a reason that would
   not hold in general: both sides took their lessons from the same list — the
   course's technical topics — so the title is the same string on both, and it
   was the portal's own join key long before this. `app/catalog.js` is a
   verbatim copy and stays one; the map lives here instead of a field being
   added to it. */
const lessonIDs = {};    // courseId -> { title: lessonId }

function lessonIdOf(courseId, ix) {
  const lesson = courseLessons(courseId)[ix];
  if (!lesson) return null;
  return (lessonIDs[courseId] || {})[lesson.key] || null;
}

/* Where a lesson sits in the course, by its title. The store keys on the
   position and the server answers with ids and titles; this is the same join as
   `lessonIdOf`, read the other way. */
function indexOfTitle(courseId, title) {
  return courseLessons(courseId).findIndex((a) => a.key === title);
}

function indexOfLesson(courseId, lessonId) {
  const titles = lessonIDs[courseId] || {};
  const title = Object.keys(titles).find((t) => titles[t] === lessonId);
  if (title === undefined) return -1;
  return courseLessons(courseId).findIndex((a) => a.key === title);
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
    session: me ? { name: me.name, email: me.email, emailVerified: true } : null,
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

export async function signOut() {
  try { await post('/api/v1/sign-out'); } catch (e) { /* the cookie may already be gone */ }
  /* Their work goes with them. A document left in memory after signing out is
     one person's progress shown to whoever is at the machine next. */
  state.hydrate({});
}

/* MULTI-FACTOR DOES NOT EXIST HERE, and this refuses rather than pretending.
   The copied sign-in screen offers a code field when the server asks for one;
   this server never asks, so nothing reaches here in normal use — and if
   anything does, it says what is missing instead of failing as a wrong code. */
export function completeMfa() {
  return Promise.reject(new ApiError(0, 'no-mfa',
    'this school does not have multi-factor sign-in yet'));
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
const wanted = () => (globalThis.contentLocale ? globalThis.contentLocale() : 'en');

export function languageChanged() {
  return loadedLocale !== null && loadedLocale !== wanted();
}

export const structureLoaded = () => structureIsLoaded();

/* The shape of every course — lessons and sections, no prose — in one request.
   It is what the rail and every denominator are drawn from. */
export async function loadLessonStructure() {
  const answer = await get('/api/v1/lessons').catch(() => null);
  if (!answer) return false;

  /* The store is keyed by the lesson's TITLE, because that is what
     `courseLessons` produces as a key: over there a lesson is an entry of the
     course's `topics`, and both sides took their lessons from the same list. */
  /* A LIST OF COURSES AND NOT A MAP OF THEM, because that is what
     `putStructure` iterates. The server answers a map keyed by course, which is
     the cheaper shape over the wire; the store wants `{ courseId, lessons }`. */
  const structure = [];
  Object.entries(answer.lessons || {}).forEach(([courseId, lessons]) => {
    lessonIDs[courseId] = {};
    lessons.forEach((l) => { lessonIDs[courseId][l.title] = l.id; });
    structure.push({ courseId, lessons: lessons.map((l) => ({
      /* `lessonIx` IS WHAT THE STORE LOOKS A LESSON UP BY. `writtenSections`
         finds a lesson with `source.find((x) => x.lessonIx === ix)`, and
         without it every lookup missed and every lesson fell back to the
         "one section called Content" placeholder — which is what put
         "2 sections" on a course whose lessons have four. */
      lessonIx: indexOfTitle(courseId, l.title),
      key: l.title,
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
        ...(s.body ? { body: s.body } : {}),
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

/* THE EXERCISES ARE NOT IMPORTED YET. The portal keys a question by the topic's
   English text and carries a payload per type; this side keys by section id and
   every type has to satisfy its own grader and the answer-key checker, which is
   a translation per type rather than a copy.

   It answers an empty list, which is a state every screen here already handles:
   119 of the 122 courses have no questions either. */
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

/* Where the student was, newest first, in the shape the dashboard reads. */
export function resumeFrom() {
  const last = state.now().last;
  return echo(last);
}

/* ---------- exams ---------- */

export const examOnServer = () => !reading;

export async function startExam(scope, scopeId) {
  const answer = await post(`/api/v1/exams/${enc(scope)}/${enc(scopeId)}/start`);
  return answer;
}

export async function submitExam(attemptId) {
  const answer = await post(`/api/v1/exams/attempts/${enc(attemptId)}/hand-in`);
  /* The result changes what the certificates screen may claim, so the document
     is refreshed rather than patched from the response — the server is the
     authority on whether an exam was passed. */
  const me = await get('/api/v1/me').catch(() => null);
  if (me) state.hydrate(documentFrom(await pull(), me));
  return answer;
}

/* ---------- certificates ---------- */

export const certificatesOnServer = () => !reading;

export async function certificates() {
  const answer = await get('/api/v1/certificates');
  return (answer && answer.certificates) || [];
}

/* The printed address, which is a path and not a fragment: it is read off paper
   and typed by somebody checking a stranger's claim. */
export const certificateUrl = (code) => `/verify/${enc(code)}`;
