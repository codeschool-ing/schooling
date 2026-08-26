/* ==========================================================================
   The student's state — schooling's copy.

   THIS IS ONE OF THE THREE FILES THAT ARE NOT A COPY, and it is worth saying
   exactly what differs, because everything else in `app/` arrived from
   `portal-frontend` unchanged — a repository since deleted, so that is how the
   files were produced and not a claim anybody can check. See `CLAUDE.md`.

   Over there the portal is local-first: the document lives in `localStorage`
   under `codeschool-portal`, every write lands there first and a backend is
   synchronised afterwards. That is right for a portal that has to work as a
   single downloaded file with no server anywhere.

   HERE THE SERVER IS THE AUTHORITY, because here there are MANY SCHOOLS behind
   one deployment and a student's progress belongs to whichever school the
   address names. A browser document keyed by nothing would be one student's
   progress in `code` shown to them in `math`, and no rename or migration would
   dig that back apart afterwards.

   So the store is held in memory, filled from the API at boot by `hydrate`,
   and every write goes to the server through `onWrite` — which is the hook the
   portal already has, used for its only purpose rather than as a second
   destination.

   THE READS AND THE WRITES BELOW ARE THE PORTAL'S, VERBATIM. They are pure
   functions over the document and the catalogue, so they carry across without a
   character changed — including the compatibility branches for the older shape,
   which cost nothing here and would be a silent divergence if trimmed.

   WHAT IS DELIBERATELY ABSENT: the Portuguese-to-English migration and the
   retired-track rescue. Both read a document written by an older version of the
   portal, and no such document exists on this side — this store has never been
   persisted in a browser. Carrying them would be code that can only ever run
   against something that cannot be here.
   ========================================================================== */

import {
  courseLessons,
} from './catalog.js';
import { lessonSections, countableSections, sectionCount } from './lessons.js';

const EMPTY = {
  session: null,      // { name, email, emailVerified }
  enrollment: null,   // { trackId, choices: { 'backend:3': 1 } }
  progress: {},       // { courseId: { lessons: { ix: { sections, exercises } } } }
  notes: {},          // { courseId: { lessonIx: { sectionId: text } } }
  exams: {},          // { 'course:javascript': { attempts, best, passed } }
  account: null,      // { planId, since }
  last: null,         // { courseId, lessonIx, sectionId } — the "carry on from here"
};

let state = structuredClone(EMPTY);
const listeners = new Set();

/* No `save()`. The portal's writes localStorage and then notifies; ours only
   notifies, because the durable copy is the server's and `onWrite` is what
   sends it there. The name is kept so the copied writes below read the same. */
function save() {
  listeners.forEach((f) => f(state));
}

export const now = () => state;
export function subscribe(f) { listeners.add(f); return () => listeners.delete(f); }

/* Where a write goes after the in-memory copy. `app/sync.js` sets it.

   The local copy is written FIRST, exactly as in the portal, and that is not
   an accident of the copy: a student mid-lesson does not wait on a network
   round trip to see the next section tick. What differs is that here the
   server's copy is the one that survives the tab closing.

   A failed write is reported by sync.js and not swallowed here — this function
   knows nothing about how the write travels, which is why it is a hook. */
let onWrite = () => {};
export const onEveryWrite = (fn) => { onWrite = fn; };

export function change(fn) {
  fn(state);
  save();
}

/* Everything the school knows about this student, in one go.

   IT REPLACES RATHER THAN MERGES. The server is the authority; merging would
   let something deleted on one device come back from another, which is the
   defect the portal's own `replaceExams` comment names. Called at boot, after
   signing in, and after signing out — where it is called with nothing, which
   is how one person's counts stop being shown to whoever is at the machine
   next. */
export function hydrate({ session, progress, notes, exams, account, last } = {}) {
  change(() => {
    state.session = session || null;
    state.progress = progress || {};
    state.notes = notes || {};
    state.exams = exams || {};
    state.account = account || null;
    state.last = last || null;
    /* NOT AN ENROLMENT, and this is the one shape that has no counterpart.
       The portal records which track a student chose; nothing here does, so
       `studentTrack()` answers from the track being looked at instead — see
       `app/main.js`. It stays in the document so the copied screens that read
       `now().enrollment` find the field they expect. */
    state.enrollment = state.enrollment || null;
  });
}

export function forget() {
  change(() => {
    Object.assign(state, structuredClone(EMPTY));
  });
}

// The portal's `reset` empties the document and the browser's copy. There is no
// browser copy here, so it is `forget` under the name the screens call.
export const reset = forget;

export function replaceEnrollment(e) {
  const choices = { ...(e?.choices || {}) };
  const has = Boolean(e && (e.trackId || Object.keys(choices).length));
  change(() => {
    state.enrollment = has
      ? { trackId: e.trackId || null, since: e.since || null, choices }
      : null;
  });
}

/* ---------- reads ----------
   They live here, and not in the screens, because more than one screen asks the
   same question and two computations of the same number diverge on the day one
   of them changes. */

const lessonRecord = (courseId, ix) => state.progress[courseId]?.lessons?.[ix];

export function sectionDone(courseId, ix, sectionId) {
  const r = lessonRecord(courseId, ix);
  if (!r) return false;
  /* Compatibility with the earlier shape, where the whole lesson was a single
     checkbox: an old record marked as finished counts for every section.
     Without this, anyone who already had progress would watch it reset. */
  if (r.sections === undefined) return Boolean(r.completed);
  return Boolean(r.sections[sectionId]);
}

export function lessonProgress(courseId, ix) {
  const a = courseLessons(courseId)[ix];
  if (!a) return { done: 0, total: 0, pct: 0 };
  // only the countable ones: an assessment with no exercises yet shows on
  // screen but stays out of the denominator, or the course would never close
  const sections = countableSections(courseId, a.key);
  const done = sections.filter((s) => sectionDone(courseId, ix, s.id)).length;
  return { done: done, total: sections.length, pct: sections.length ? Math.round((done / sections.length) * 100) : 0 };
}

export const lessonDone = (courseId, ix) => {
  const p = lessonProgress(courseId, ix);
  return p.total > 0 && p.done === p.total;
};

export function courseProgress(courseId) {
  const total = sectionCount(courseId);
  let done = 0;
  courseLessons(courseId).forEach((a, ix) => {
    countableSections(courseId, a.key).forEach((s) => {
      if (sectionDone(courseId, ix, s.id)) done += 1;
    });
  });
  return { done: done, total, pct: total ? Math.round((done / total) * 100) : 0 };
}

export const courseDone = (courseId) => {
  const p = courseProgress(courseId);
  return p.total > 0 && p.done === p.total;
};

/* ---------- exams ----------
   It keeps the BEST result, not the last one. Failing after having already
   passed cannot take away a certificate that was issued — and retaking an exam
   you already passed, to practise, is exactly what we want to encourage.

   The attempt count is what seeds the draw for the next exam: same attempt,
   same exam; new attempt, new exam. */
export const examResult = (key) => state.exams[key] || null;
export const examPassed = (key) => Boolean(state.exams[key]?.passed);
export const examAttempts = (key) => state.exams[key]?.attempts || 0;

export function saveExam(key, { pct, passed, lastCorrect, total }) {
  change(() => {
    const before = state.exams[key] || { attempts: 0, best: 0, passed: false };
    state.exams[key] = {
      attempts: before.attempts + 1,
      best: Math.max(before.best, pct),
      passed: before.passed || passed,
      lastPct: pct,
      lastCorrect,
      lastTotal: total,
      lastAt: new Date().toISOString(),
    };
  });
}

/* The server's copy of the same thing, replacing this one wholesale.

   Wholesale and not merged, because the server computes it from the attempts it
   holds and this browser's copy is a cache of that — merging would let a result
   erased on one device come back from another. `saveExam` above stays: with no
   backend configured it is still the only record there is.

   `lastCorrect`/`lastTotal` are dropped rather than invented. The summary
   carries the percentage and not the counts behind it, and a zero here would
   render as "0 of 0 questions graded" under a score of 80%. */
export function replaceExams(list) {
  const exams = {};
  (list || []).forEach((e) => {
    exams[e.scope + ':' + e.scopeId] = {
      attempts: e.attempts,
      best: e.best,
      passed: e.passed,
      lastPct: e.lastPct,
      lastAt: e.lastAt,
    };
  });
  change((e) => { e.exams = exams; });
}

export const answerFor = (courseId, ix, exId) =>
  lessonRecord(courseId, ix)?.exercises?.[exId] || null;

/* ---------- writes ---------- */

function ensureLesson(courseId, ix) {
  const p = state.progress;
  p[courseId] = p[courseId] || { lessons: {} };
  const r = p[courseId].lessons[ix] || {};
  if (r.sections === undefined) {
    // migrate the old shape on the first write, instead of carrying both
    const a = courseLessons(courseId)[ix];
    const all = a ? lessonSections(courseId, a.key) : [];
    r.sections = {};
    if (r.completed) all.forEach((s) => { r.sections[s.id] = true; });
    delete r.completed;
  }
  r.exercises = r.exercises || {};
  p[courseId].lessons[ix] = r;
  return r;
}

export function markSection(courseId, ix, sectionId, done = true) {
  change(() => {
    const r = ensureLesson(courseId, ix);
    if (done) r.sections[sectionId] = true;
    else delete r.sections[sectionId];
    state.last = { courseId: courseId, lessonIx: ix, sectionId };
  });
  onWrite({ kind: 'section', courseId, ix, sectionId, done });
}

export function visitSection(courseId, ix, sectionId) {
  change(() => {
    ensureLesson(courseId, ix);
    state.last = { courseId: courseId, lessonIx: ix, sectionId };
  });
  onWrite({ kind: 'visit', courseId, ix, sectionId });
}

export function saveAnswer(courseId, ix, exId, verdict) {
  change(() => {
    const r = ensureLesson(courseId, ix);
    const before = r.exercises[exId] || { attempts: 0, correct: false, checked: false };
    r.exercises[exId] = {
      attempts: before.attempts + 1,
      // once right, still right: redoing it to practise does not take the credit
      correct: before.correct || verdict.correct === true,
      /* `checked` separates "got it wrong" from "nobody checked". Without it,
         a code exercise that was answered and never executed was
         indistinguishable from a mistake, and the performance screen would
         count as a failure something that was never judged — the same confusion
         that "unjudged never becomes passed" avoids from the other side of the
         ruler. */
      checked: before.checked || verdict.correct !== null,
      lastAt: new Date().toISOString(),
    };
  });
}

/* ---------- notes ----------
   One per section, free text. It is the only thing in the portal the STUDENT
   writes, and that is why it does not get lost even when the content changes:
   the key is the same one progress uses — course, lesson index, section id. */
export const noteFor = (courseId, ix, sectionId) =>
  state.notes[courseId]?.[ix]?.[sectionId] || '';

export function saveNote(courseId, ix, sectionId, text) {
  change(() => {
    const clean = String(text || '').trim();
    if (!clean) {
      // an empty note is a deleted note: not worth the space nor a row in the list
      if (state.notes[courseId]?.[ix]) delete state.notes[courseId][ix][sectionId];
      return;
    }
    state.notes[courseId] = state.notes[courseId] || {};
    state.notes[courseId][ix] = state.notes[courseId][ix] || {};
    state.notes[courseId][ix][sectionId] = clean;
  });
  onWrite({ kind: 'note', courseId, ix, sectionId, body: String(text || '').trim() });
}

/* Every note, flattened. The notes screen and the search read from here — two
   readings of one source. */
export function allNotes() {
  const out = [];
  Object.entries(state.notes).forEach(([courseId, lessons]) => {
    Object.entries(lessons).forEach(([ix, sections]) => {
      Object.entries(sections).forEach(([sectionId, text]) => {
        out.push({ courseId: courseId, lessonIx: Number(ix), sectionId, text: text });
      });
    });
  });
  return out;
}

/* ---------- performance ----------
   The portal was already recording attempts and hits for each exercise and
   never showing them. This is only the read: the screen is what interprets. */
export function answersGiven() {
  const out = [];
  Object.entries(state.progress).forEach(([courseId, course]) => {
    Object.entries(course.lessons || {}).forEach(([ix, lesson]) => {
      Object.entries(lesson.exercises || {}).forEach(([exId, r]) => {
        out.push({ courseId: courseId, lessonIx: Number(ix), exId, ...r });
      });
    });
  });
  return out;
}

/* ---------- account and plan ----------
   FUTURE: `planoId` comes from the billing service, and changing plans is a
   POST that returns the new one. Here it is a field, so the screens are written
   against the right shape from the start.

   Someone who arrives without a plan lands on the first in the list — not on
   "none": a portal with no plan at all has states that do not exist in real
   life, and every one of them becomes an `if` nobody will ever exercise. */
export function studentAccount() {
  const c = state.account;
  const planId = c?.planId || (window.PLANS?.[0]?.id ?? 'guest');
  return { planId: planId, since: c?.since || null, email: state.session?.email || '' };
}

export const currentPlan = () =>
  (window.PLANS || []).find((p) => p.id === studentAccount().planId) || (window.PLANS || [])[0] || null;

export function changePlan(planId) {
  change(() => {
    state.account = { ...(state.account || {}), planId: planId, since: new Date().toISOString() };
  });
}

export function changeEmail(email) {
  change(() => {
    state.session = { ...(state.session || {}), email: String(email || '').trim() };
  });
}

/* The password is NOT stored. There is no client-side hash worth anything, and
   writing the password to localStorage would be worse than having no screen at
   all: it would give the impression that authentication exists. What stays is
   the DATE of the change — which is what the student needs to see, and what the
   server will confirm in Stage 2. */
export function markPasswordChange() {
  change(() => {
    state.account = { ...(state.account || {}), passwordAt: new Date().toISOString() };
  });
}

export function activeOption(trackId, idx) {
  return state.enrollment?.choices?.[trackId + ':' + idx] ?? 0;
}

export function chooseOption(trackId, idx, option) {
  change(() => {
    state.enrollment = state.enrollment || { trackId: trackId, choices: {} };
    state.enrollment.choices = state.enrollment.choices || {};
    state.enrollment.choices[trackId + ':' + idx] = option;
  });
}
