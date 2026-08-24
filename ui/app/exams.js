/* ==========================================================================
   Exams — the one at the end of a course and the one at the end of a track.

   A LESSON'S ASSESSMENT AND AN EXAM ARE NOT THE SAME THING, and the difference
   is not the size:

     assessment  is PRACTICE. It checks on the spot, shows why, lets you redo.
                 Getting it wrong there is part of learning, and the immediate
                 feedback is what makes the mistake teach something.
     exam        is MEASUREMENT. You answer everything and only then see the
                 result. Feedback on every question in an exam is what lets you
                 try until you get it right — and then it stops measuring
                 anything.

   That is why the wizard takes `options.exam`: the same screens, with the
   verdict held back until the end. Without it, an exam would just be a long
   assessment.

   WHERE THE QUESTIONS COME FROM
   From the lessons' own exercise bank, drawn at random. There is no separate
   bank of "exam questions", and there should not be one while the pipeline emits
   one file per topic: keeping two banks aligned is recurring work, and what it
   would buy — unseen questions — the draw already gives, because nobody does all
   1,503 exercises of a track before the exam.

   THE DRAW IS SEEDED BY THE ATTEMPT. Leaving the screen and coming back gives
   the SAME exam (otherwise closing the tab by accident would become a new exam,
   which is the wrong punishment for the wrong mistake). Failing and trying again
   gives a DIFFERENT exam — memorising the list of ten cannot be the strategy.

   IT PREFERS THE TYPES THE PORTAL CAN GRADE. `code`, `expected-output` and
   `expression-answer` need a server and today come back "unchecked" — an exam
   full of them would have no score. They only come in when there are not enough
   gradable ones, and they stay out of the denominator, by the usual rule:
   unjudged becomes neither passed nor failed.
   ========================================================================== */

import { courseLessons, courseById, courseAddress, trackPath } from './catalog.js';
import { lessonExercises } from './lessons.js';
import { NEEDS_SERVER } from './exercises/grade.js';
import { shuffleWith } from './text.js';
import * as api from './api.js';
import * as source from './source.js';

/* THE PASS MARK IS THE SERVER'S, AND THIS IS THE FALLBACK FOR WHEN THERE IS NONE.

   It used to be `PASS_MARK = 70`, exported, and shown on three screens — a
   second copy of `exam.PassMark`, which is the number the server actually marks
   by. Two copies of one decision go wrong in the direction nobody notices: move
   the constant on the server and an exam is marked at the new number while every
   screen describes it as the old one, and nothing fails.

   So the number now travels: a paper carries `pass_mark`, and the school says
   its own on `/api/v1/school` — which is what a course card needs, because it
   prints "minimum to pass" before any paper exists.

   THIS CONSTANT SURVIVES FOR THE ONE CASE THAT HAS NO SERVER: the single-file
   bundle, opened off a disk, which draws and grades in the page. It is named for
   that and is not exported, so nothing can reach for it by accident. */
const OFFLINE_PASS_MARK = 70;

/* What this school marks by, and it is a function rather than a constant because
   the school is fetched at boot and this file is imported before that happens. */
export const passMark = () => {
  const said = source.school && source.school.passMark;
  return typeof said === 'number' && said > 0 ? said : OFFLINE_PASS_MARK;
};

export const COURSE_QUESTIONS = 10;
export const TRACK_QUESTIONS = 15;

/* THE SMALLEST PAPER THAT IS STILL A MEASUREMENT — derived from the pass mark
   rather than chosen. A paper of n questions only scores in steps of 100/n, so
   below a certain n the pass mark can only be reached by a perfect paper: at
   three questions 2 right is 67% and fails, so passing means 3 of 3. An exam
   that demands perfection is not the exam the rules on the screen describe, and
   a single question is not a measurement at all.

   It matters because the exercise bank is written course by course: four of the
   122 courses have one today, and one of those four has a single exercise —
   which was being offered as a "final exam". */
/* IT USES THE OFFLINE CONSTANT AND NOT THE SCHOOL'S, deliberately: this is the
   size of the LOCAL draw, decided while a course card is being painted and
   before any school has necessarily answered. The two are the same number today,
   and if they ever differ the honest reading of this is "the smallest paper that
   could measure anything under the platform's default", which is what a card
   saying "in preparation" is claiming. */
export const MIN_QUESTIONS = (() => {
  let n = 1;
  while (Math.ceil((OFFLINE_PASS_MARK * n) / 100) >= n) n += 1;
  return n;
})();
export const examReady = (exam) => exam.items.length >= MIN_QUESTIONS;

/* Every exercise in a course, each one knowing which lesson it came from — the
   wizard stores the answer under `progress[course].lessons[ix]`, and an exam that
   pooled lessons without keeping the origin would file everything against the
   wrong lesson. */
export function courseBank(courseId) {
  const out = [];
  courseLessons(courseId).forEach((a, ix) => {
    lessonExercises(courseId, a.key).forEach((ex) => {
      out.push({ ex, ctx: { courseId, lessonIx: ix }, lesson: a.title });
    });
  });
  return out;
}

const gradable = (item) => !NEEDS_SERVER.includes(item.ex.type);

/* Draws while keeping the preference for the gradable ones: it shuffles the two
   groups separately and only then concatenates, so the order inside each group
   still varies from attempt to attempt. */
function draw(bank, howMany, seed) {
  const good = shuffleWith(seed + ':ok', bank.filter(gradable));
  const rest = shuffleWith(seed + ':srv', bank.filter((i) => !gradable(i)));
  return good.concat(rest).slice(0, howMany);
}

/* ---- the same exam, drawn by the server ------------------------------------

   WHY BOTH EXIST. Everything below this line draws from the bank in the page,
   which means the answer key is in the page — an open devtools is a guaranteed
   100%. That is the whole reason internal/assessment exists, and with a backend
   configured the paper comes from there instead: stamped into an attempt,
   returned without a key, graded on submit.

   The local draw stays because the portal has to work without a server. The
   single-file bundle is opened off a disk, the smoke suite drives that file,
   and a version of this module that assumed a backend would break both. What it
   cannot do is hold a verdict it already has, and that is the honest limit of a
   portal with no server rather than a thing to hide.

   `items` comes out the same shape from either: `{ex, ctx}`, so the screen and
   the wizard below it do not know which one ran. What the server adds is
   `attempt` — its presence is what makes every answer a recorded one instead of
   a graded one. */
async function drawnByServer(scope, scopeId, meta) {
  const attempt = await api.startExam(scope, scopeId);
  return {
    ...meta,
    attempt: attempt.id,
    responses: attempt.responses,
    items: attempt.questions.map((ex) => ({ ex, ctx: contextOf(ex) })),
    bankSize: null,   // the bank is the server's and it does not say how big

    /* THE MARK THIS PAPER IS HELD TO, off the paper. For one already handed in
       the server sends the mark it was JUDGED by rather than today's, which is
       the reason the column exists — a result explaining itself with a number
       nobody applied to it is worse than no number. */
    passMark: attempt.passMark,
  };
}

/* The lesson an exercise came from, resolved from the catalogue by its topic.

   The wizard files an answer under `progress[course].lessons[ix]`, and the
   server names the lesson by its authored topic title rather than by the index
   the portal counts in. A topic that resolves to nothing gives a null context,
   which the wizard reads as "record this nowhere" — the exam still grades, and
   nothing is filed against the wrong lesson. */
function contextOf(ex) {
  const ix = courseLessons(ex.course).findIndex((a) => a.key === ex.topic);
  return ix < 0 ? null : { courseId: ex.course, lessonIx: ix };
}

export function courseExam(courseId, attempt = 0) {
  const c = courseById(courseId);
  const bank = courseBank(courseId);
  return {
    key: 'course:' + courseId,
    scope: 'course',
    about: courseId,
    title: c ? c.name : courseId,
    backTo: '#/course/' + courseAddress(courseId),
    items: draw(bank, COURSE_QUESTIONS, courseId + ':' + attempt),
    bankSize: bank.length,
  };
}

/* The two entry points the screens call. Async on both paths, because one of
   them is a request and a screen written against a synchronous draw would have
   to be rewritten the day the server arrived — which is the day this was
   written for. */
export async function openCourseExam(courseId, attempt = 0) {
  const c = courseById(courseId);
  const meta = {
    key: 'course:' + courseId,
    scope: 'course',
    about: courseId,
    title: c ? c.name : courseId,
    backTo: '#/course/' + courseAddress(courseId),
  };
  if (api.examOnServer()) return drawnByServer('course', courseId, meta);
  return courseExam(courseId, attempt);
}

export async function openTrackExam(track, activeOption, attempt = 0) {
  const meta = {
    key: 'track:' + track.id,
    scope: 'track',
    about: track.id,
    title: track.name,
    backTo: '#/track',
  };
  if (api.examOnServer()) return drawnByServer('track', track.id, meta);
  return trackExam(track, activeOption, attempt);
}

export function trackExam(track, activeOption, attempt = 0) {
  const path = trackPath(track, activeOption);
  const bank = path.flatMap((id) => courseBank(id));
  return {
    key: 'track:' + track.id,
    scope: 'track',
    about: track.id,
    title: track.name,
    backTo: '#/track',
    items: draw(bank, TRACK_QUESTIONS, track.id + ':' + attempt),
    bankSize: bank.length,
    courses: path.length,
  };
}

/* The score. `right / judged` — and judged excludes what the server has not
   checked yet, never what was left blank. Leaving it blank is an answer, and it
   is a wrong one; not having been checked is not an answer at all. */
// `mark` IS AN ARGUMENT BECAUSE IT IS A PROPERTY OF THE PAPER. This function is
// only reached on the path with no server, where the states in the browser are
// all there is — but a scorer holding its own idea of passing is exactly what
// this change removed everywhere else, and leaving one here would be the copy
// growing back.
export function examScore(states, mark = passMark()) {
  const judged = states.filter((s) => s.correct !== null || !s.answered);
  const right = states.filter((s) => s.correct === true).length;
  const pending = states.length - judged.length;
  const pct = judged.length ? Math.round((right / judged.length) * 100) : 0;
  return {
    lastCorrect: right, judged: judged.length, pending, pct,
    passed: judged.length > 0 && pct >= mark,
  };
}
