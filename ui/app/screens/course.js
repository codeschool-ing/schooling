/* ==========================================================================
   Course — the syllabus the vitrine shows, plus the list of lessons.

   LESSON = TOPIC. The catalogue has no concept of a lesson; the finest grain is
   `topics`, and the pipeline's exercises are already indexed by the topic text.
   Inventing a third key here would create a mapping to keep in sync with two
   ends that already agree with each other.
   ========================================================================== */

import { courseLessons, courseById, courseAddress, tracksWithCourse, unlockedBy } from '../catalog.js';
import { lessonSections, courseMaterials } from '../lessons.js';
import { courseProgress, lessonProgress, lessonDone, someLessonDone } from '../state.js';
import { courseState } from '../graph.js';
import { courseExam, courseExamOffered, examPaper } from '../exams.js';
import { examCard } from './exam.js';
import { materialList } from '../materials.js';
import { bar, empty, videoFrame, playsOnClick, subscribeInvite } from './common.js';
import { esc, formatted, counted } from '../text.js';
import { ratingBlock, wireRating } from '../rate.js';
/* The one screen that knows which questions went wrong — see `performance.js`,
   where the join lives. Reaching for it from here is what turns a screen nobody
   could find into a link on the way past. */
import { wrongOnes } from './performance.js';
import * as api from '../api.js';

export default async function course({ id }) {
  const c = courseById(id);
  if (!c) return { title: txt('Course'), el: empty(txt('Course not found.')) };

  const lessons = courseLessons(id);
  const p = courseProgress(id);
  const st = courseState(id);
  const opens = unlockedBy(id);
  const exam = courseExam(id);
  const materials = courseMaterials(id);
  // this sitting's wrong answers, in THIS course: the redo screen takes them all
  const missed = wrongOnes().filter((r) => r.courseId === id);

  const el = document.createElement('div');
  el.className = 'view screen-course';

  el.innerHTML =
    '<header class="course-head">' +
      '<span class="node-state" data-state="' + st + '">' + txt({
        done: 'completed', current: 'in progress', available: 'available', ahead: 'further ahead',
      }[st]) + '</span>' +
      '<h1>' + esc(c.name) + '</h1>' +
      '<p class="course-summary">' + esc(c.summary) + '</p>' +
      '<div class="course-meta">' +
        '<span>' + c.hours + 'h</span>' +
        '<span>' + txt(c.level) + '</span>' +
        '<span>' + counted(lessons.length, txt('lesson'), txt('lessons')) + '</span>' +
        '<span>' + txt('in') + ' ' +
          counted(tracksWithCourse(id).length, txt('track'), txt('tracks')) + '</span>' +
      '</div>' +
      bar(p.pct, p.done + ' ' + txt('of') + ' ' + p.total) +
      '<p class="course-count">' + p.done + '/' + p.total + ' ' + txt('sections completed') + '</p>' +
      /* WHAT WENT WRONG IN THIS SITTING, WITH SOMEWHERE TO PUT IT. The screen
         that gathers those questions has existed all along and nothing has ever
         pointed at it, so the only way to find the practice was to know the
         address. Being wrong is not punished anywhere — it does not hold a
         section, a lesson or a certificate — and this line is the whole of what
         it earns: an offer, on the screen a student comes back to. */
      (missed.length
        ? '<p class="course-missed"><a href="#/redo">' +
            counted(missed.length, txt('question to redo'), txt('questions to redo')) +
          '</a></p>'
        : '') +
    '</header>' +

    '<div class="course-cols">' +
      /* The main column is ONE child of the grid, not two: the exam lives inside
         it, below the lessons. Loose, it became a second column and pushed the
         sidebar down to the next row. */
      '<div class="course-main">' +
      videoFrame(c.video, { label: txt('watch the course introduction') }) +
      '<section class="block">' +
        '<div class="block-top"><h2>' + txt('Lessons') + '</h2></div>' +
        '<ol class="lessons">' +
          lessons.map((a) => {
            const done = lessonDone(id, a.ix);
            const sections = lessonSections(id, a.key);
            const pa = lessonProgress(id, a.ix);
            const hasAssessment = sections.some((s) => s.type === 'assessment');
            return '<li><a class="lesson-row' + (done ? ' done' : '') + '" ' +
              'href="#/course/' + esc(id) + '/lesson/' + a.ix + '/' + esc(sections[0].id) + '">' +
              '<span class="lesson-mark" aria-hidden="true">' + (done ? '✓' : '') + '</span>' +
              '<span class="lesson-num">' + String(a.ix + 1).padStart(2, '0') + '</span>' +
              '<span class="lesson-tit">' + esc(a.title) + '</span>' +
              '<span class="lesson-sections">' +
                counted(sections.length, txt('section'), txt('sections')) +
                (hasAssessment ? ' · ' + txt('with an assessment') : '') +
              '</span>' +
              '<span class="lesson-prog">' + pa.done + '/' + pa.total + '</span>' +
            '</a></li>';
          }).join('') +
        '</ol>' +
      '</section>' +

      /* The exam closes the lesson column, not the sidebar: it is the last step
         of the course, and its place is after the last lesson. It is rendered
         whether or not the exercises for it exist yet — see examCard.

         WHETHER IT CAN BE SAT IS THE SERVER'S ANSWER AND NOT A DRAW HERE. It
         was `examReady(exam)` — a paper dealt in the browser out of a bank that
         is empty wherever there is a server — so this card said "in
         preparation" for every course whatever the school held. See
         `courseExamOffered`. `exam` is still drawn because the offline bundle
         has nothing else, and its length is still what the card falls back to
         when no school has answered. */
      examCard({
        key: exam.key, href: '#/course/' + esc(courseAddress(id)) + '/exam', scope: 'course',
        count: examPaper(c.examPool) || exam.items.length, progress: p.pct,
        ready: courseExamOffered(id),
      }) +

      /* ---------- and what they thought of it ----------

         ONCE A LESSON OF IT IS FINISHED, and it used to be once the COURSE was.
         The argument for that was that somebody halfway through has an opinion
         about the half they have read — which is true, and is not a reason to
         wait: the half they have read is the half we can still fix. Against it
         stands the arithmetic. `web-fundamentals` is ninety-four sections; a
         question asked at the end of them is a question asked months after the
         lesson it is about, of somebody who has stopped being the beginner who
         could tell us the third lesson moved too fast.

         A FINISHED LESSON IS THE SMALLEST HONEST BASIS. Somebody who has read
         a lesson and answered everything it asks has met the writing, the
         figures and the questions — the three things the stars ask about. It
         is also, now, a real piece of work rather than a row of clicks: a
         section with questions is finished by answering them (see
         `lesson.js`).

         IT IS THE LAST THING IN THE COLUMN, below the exam, because it is the
         last thing in the course. And it stays there afterwards rather than
         disappearing once given — the control draws what they said, and a
         rating that vanished when answered would be a rating nobody could
         change after the rewrite it asked for. */
      (someLessonDone(id) ? ratingBlock('course') : '') +
      '</div>' +

      '<aside class="course-side">' +
        (materials.length
          ? '<section class="block">' + materialList(materials, { title: txt('Course material') }) + '</section>'
          : '') +
        (c.syllabus?.length
          ? '<section class="block"><div class="block-top"><h2>' + txt('Syllabus') + '</h2></div>' +
            '<ul class="syllabus">' + c.syllabus.map((l) => '<li>' + esc(l) + '</li>').join('') + '</ul></section>'
          : '') +
        (c.prerequisites
          ? '<section class="block"><div class="block-top"><h2>' + txt('Prerequisites') + '</h2></div>' +
            '<p class="prerequisites">' + formatted(c.prerequisites) + '</p></section>'
          : '') +
        ((c.requires || []).length
          ? '<section class="block"><div class="block-top"><h2>' + txt('After') + '</h2></div>' +
            '<div class="related">' + c.requires.map((d) => link(d, 'before')).join('') + '</div></section>'
          : '') +
        (opens.length
          ? '<section class="block"><div class="block-top"><h2>' + txt('Opens the way to') + '</h2></div>' +
            '<div class="related">' + opens.map((x) => link(x.id, 'after')).join('') + '</div></section>'
          : '') +
      '</aside>' +
    '</div>';

  /* The facade only becomes a player on a click, so the screen opens without
     asking YouTube for anything and a student who does not watch receives no
     cookie from them. Bound here rather than in main.js's delegation: the
     screen element is new on every render, so the listener goes with it. */
  playsOnClick(el, txt('course introduction'));

  /* The stars fill themselves in from what this student already said, which is
     one request and only for somebody who has finished the course. It is bound
     here for the same reason the player is: the element is new on every render. */
  wireRating(el, { kind: 'course', subjectId: id });

  /* ---------- and the offer, if this one is not open ----------

     THE BEST PLACE ON THIS PLATFORM TO MAKE THE CASE, and it carried nothing.
     Somebody who reaches here came from the catalogue and has just read the
     whole syllabus of a course they want; the lesson screen only meets people
     who already clicked into one. This screen had no mention of the
     subscription at all.

     IT IS APPENDED AND THE PAGE ABOVE IS UNTOUCHED. The syllabus is the shop
     window (N-04) and stays readable — hiding it would remove the very thing
     that makes somebody want to buy. What is added is the offer under it.

     THE SERVER DECIDES, NOT THIS FILE. `loadCourseContent` answers 'locked' on
     the 402, which is the same signal the lesson screen acts on. Working out
     which courses are free from the track's shape would be a second copy of a
     rule the server already owns — and the copy that disagreed would either
     sell a free course or give away a paid one. */
  if (await api.loadCourseContent(id) === 'locked') {
    const offer = document.createElement('div');
    offer.innerHTML = subscribeInvite();

    /* INTO THE COLUMN AND NOT ONTO THE PAGE. Appended to the view it was a
       sibling of `.course-cols`, so it spanned the grid — 320px and a gap wider
       than every block above it, which reads as a panel that belongs to a
       different page.

       `.course-main` is where the lessons and the exam already are, and the
       offer is the step after the exam in the same sense: the last thing on the
       way down this column. */
    el.querySelector('.course-main').append(offer.firstElementChild);
  }

  return { title: c.name, el };
}

function link(id, direction) {
  const c = courseById(id);
  if (!c) return '';
  return '<a class="link-chip link-' + direction + '" href="#/course/' + esc(id) + '">' + esc(c.name) + '</a>';
}
