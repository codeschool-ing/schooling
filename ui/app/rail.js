/* ==========================================================================
   The side rail.

   It answers, without a click, the two questions a student asks all the time:
   where am I and how much is left. Its content changes with the route — inside a
   course it is the list of lessons; outside, it is the portal's navigation with
   the track just below.

   THE HIERARCHY HAS TO BE VISIBLE AT A GLANCE. Before, a lesson and a section
   were two similar rows with different indents, and you could not tell one from
   the other without reading. Now the lesson is a HEADING — uppercase,
   monospaced, with a counter — and the section is an ordinary row with an icon.
   They are two things of different natures and they now look like two things.

   Every section carries an ICON. It says two things at once: the STATE (a green
   check on what is done) and the NATURE of what is coming (play for video, lines
   for reading, a star for the assessment). Before, everything was a play, which
   promised video in every section — including the text-only ones.

   ONE LESSON IS OPEN AT A TIME, and clicking one goes into it.

   It was the other way round twice. First a pure accordion that only ever
   opened the CURRENT lesson, so you could not look ahead at all. Then the
   opposite — any number open at once, and clicking a lesson only folded it —
   which is what this replaces.

   What that cost is what a rail is for: with eleven lessons of eight sections
   each left open, the list is ninety rows and finding where you are means
   scrolling past everything you are not doing. And a click that opened a
   lesson without going into it left the outline describing one lesson and the
   page showing another.

   So a click does the whole gesture: it opens that lesson, closes whichever
   was open, and lands on its first section. Clicking the one already open
   folds it away again, which is the only way to say "not this one" — and
   moving between lessons by any other route (the arrows at the end of a
   section, a link in the text) opens the one you arrive in, because the rail
   follows the reader rather than the other way round.
   ========================================================================== */

import { courseLessons, courseById, courseByAddress, courseAddress, trackPath } from './catalog.js';
import { lessonSections } from './lessons.js';
import {
  lessonDone, sectionDone, lessonProgress, courseProgress, activeOption, examPassed,
} from './state.js';
import { courseExam } from './exams.js';
import { courseState } from './graph.js';
import { studentTrack, bar } from './screens/common.js';
import { esc } from './text.js';

const LINKS = [
  { href: '#/dashboard', label: 'Dashboard' },
  { href: '#/track', label: 'My track' },
  { href: '#/catalog', label: 'Catalog' },
  { href: '#/performance', label: 'Performance' },
  { href: '#/notes', label: 'Notes' },
  { href: '#/certificates', label: 'Certificates' },
];

const ICON_PLAY = '<svg viewBox="0 0 16 16" aria-hidden="true"><path d="M6 4.5l5 3.5-5 3.5z" fill="currentColor"/></svg>';
const ICON_CHECK = '<svg viewBox="0 0 16 16" aria-hidden="true">' +
  '<circle cx="8" cy="8" r="7" fill="currentColor" opacity=".18"/>' +
  '<path d="M4.8 8.2l2.2 2.2 4.2-4.4" fill="none" stroke="currentColor" stroke-width="1.8" ' +
  'stroke-linecap="round" stroke-linejoin="round"/></svg>';
const ICON_CHEVRON = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" ' +
  'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 6l3 3 3-3"/></svg>';
const ICON_TEXT = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" ' +
  'stroke-linecap="round" aria-hidden="true"><path d="M3.5 4h9M3.5 7h9M3.5 10h6"/></svg>';
const ICON_STAR = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.4" ' +
  'stroke-linejoin="round" aria-hidden="true">' +
  '<path d="M8 2.5l1.7 3.5 3.8.5-2.8 2.7.7 3.8L8 11.2l-3.4 1.8.7-3.8L2.5 6.5l3.8-.5z"/></svg>';
const ICON_TROPHY = '<svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" ' +
  'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
  '<path d="M4.5 2.5h7v3a3.5 3.5 0 0 1-7 0zM4.5 3.5H3a1.5 1.5 0 0 0 1.5 3M11.5 3.5H13a1.5 1.5 0 0 1-1.5 3M8 9v2.5M6 13.5h4"/></svg>';

/* WHICH ONE LESSON IS OPEN, per course, and `null` for none of them. It lives
   in memory: it is a navigation preference of the moment, not progress — it
   does not deserve storage, nor a trip to the server in Stage 2.

   A course ABSENT from this map has never been touched by hand, which is not
   the same as "nothing is open": there the current lesson is open, because
   that is where the reader is. `in` rather than a falsy test, so a course
   folded shut by hand stays shut. */
const openOf = {};

/* Where the ROUTE was last time the rail was drawn, per course. It is what
   tells a lesson reached by the arrows from one reached by a click: when the
   route moves to another lesson, that lesson opens and takes the place of
   whatever was open. Without it, reading to the end of lesson three and
   stepping into lesson four left the rail describing three. */
const wasOn = {};

// Answers whether it ended up OPEN, because the caller navigates only then.
export const toggleLesson = (courseId, ix) => {
  openOf[courseId] = openOf[courseId] === ix ? null : ix;
  return openOf[courseId] === ix;
};

export function buildRail(el, path, params) {
  const insideCourse = path.startsWith('/course/');
  /* The rail is listed in window.I18N_DYNAMIC, so the runtime's DOM walk skips
     it — including the aria-label on the element ITSELF, which is static and
     was therefore never translated in any language. Setting it here puts it
     back on a path that runs on every route change and on every language
     switch. */
  el.setAttribute('aria-label', txt('Navigation'));
  el.innerHTML = insideCourse ? courseRail(params, path) : globalRail(path);
  const open = el.querySelector('.rail-lesson.on');
  if (open) open.scrollIntoView({ block: 'nearest' });
}

function globalRail(path) {
  const t = studentTrack();
  const links = LINKS.map((l) =>
    '<a class="rail-link' + (path === l.href.slice(1) ? ' on' : '') + '" href="' + l.href + '">' +
      txt(l.label) + '</a>').join('');

  if (!t) return '<nav class="rail-nav">' + links + '</nav>';

  const courses = trackPath(t, activeOption).map((id) => {
    const c = courseById(id);
    if (!c) return '';
    const p = courseProgress(id);
    const st = courseState(id);
    return '<a class="rail-course no-' + st + '" href="#/course/' + esc(courseAddress(id)) + '">' +
      '<span class="tc-mark" data-state="' + st + '" aria-hidden="true"></span>' +
      '<span class="tc-name">' + esc(c.name) + '</span>' +
      '<span class="tc-count">' + p.done + '/' + p.total + '</span>' +
    '</a>';
  }).join('');

  return (
    '<nav class="rail-nav">' + links + '</nav>' +
    '<div class="rail-sec">' +
      '<span class="rail-tit">' + esc(t.name) + '</span>' +
      '<div class="rail-courses">' + courses + '</div>' +
    '</div>'
  );
}

function courseRail(params, path) {
  /* WHAT THE ADDRESS CARRIES IS EITHER NAME, and this asked `courseById`. A
     link written with the slug found nothing and fell through to the portal's
     navigation below — so the outline a student was reading collapsed when they
     moved to the next section, and came back when they clicked a tab, because
     those two links were written with different names for the same course. */
  const c = courseByAddress(params?.id);
  if (!c) return globalRail(path);
  const id = c.id;
  // Every link out of here says the same thing the rest of the app says.
  const address = courseAddress(id);

  const lessons = courseLessons(id);
  const p = courseProgress(id);
  const here = path.match(/\/lesson\/(\d+)(?:\/([^/]+))?$/);
  const currentIx = here ? Number(here[1]) : -1;
  const currentSec = here && here[2] ? decodeURIComponent(here[2]) : null;

  /* THE RAIL FOLLOWS THE READER. Arriving in a lesson opens it and closes what
     was open, whether the reader got there by clicking the row, by the arrow at
     the end of the section before, or by a link somebody sent them. Only the
     ARRIVAL does this — redrawing the same lesson must not undo a fold the
     reader just asked for, which is what `wasOn` distinguishes. */
  if (currentIx >= 0 && wasOn[id] !== currentIx) {
    wasOn[id] = currentIx;
    openOf[id] = currentIx;
  }
  const openIx = id in openOf ? openOf[id] : currentIx;

  const rows = lessons.map((a) => {
    const sections = lessonSections(id, a.key);
    const done = lessonDone(id, a.ix);
    const isCurrent = a.ix === currentIx;
    const pa = lessonProgress(id, a.ix);
    const open = a.ix === openIx;

    /* THE WHOLE ROW IS THE CONTROL, AND IT IS ONE BUTTON.

       It used to be a chevron that toggled beside a link that navigated, and
       the two were three millimetres apart doing different things: clicking the
       title of the lesson you were already on went to the screen you were
       already looking at, so the row appeared to do nothing.

       ONE BUTTON DOING ONE GESTURE. Pressing it opens the lesson, closes the
       one that was open, and lands on the first section — "go into this
       lesson", which is what a person means by clicking its name. Pressing the
       one already open folds it away and goes nowhere.

       IT IS STILL NOT AN `<a>`, even though it now navigates, and the
       difference is not pedantry: what it does is not "follow this address".
       The same press also folds one lesson and unfolds another, a middle click
       could not sensibly open a second tab of a rail state, and the address it
       lands on depends on which sections that lesson has. `aria-expanded` is
       the promise it makes, and it belongs on the thing a person presses. */
    const head =
      '<button type="button" class="rail-lesson' + (done ? ' done' : '') +
        (isCurrent ? ' on' : '') + (open ? ' is-open' : '') + '" ' +
        'data-lesson="' + a.ix + '" aria-expanded="' + open + '" ' +
        /* WHERE OPENING IT LANDS. The row is not a link — see below — but the
           gesture is "go into this lesson", and the first section is where that
           means. It is written here because this is where the lesson's sections
           are already in hand; `main.js` reads it off the button it was
           handed. */
        'data-first="/course/' + esc(address) + '/lesson/' + a.ix + '/' +
          esc(sections[0].slug || sections[0].id) + '">' +
        '<span class="ta-open" aria-hidden="true">' + ICON_CHEVRON + '</span>' +
        '<span class="ta-title">' +
          '<span class="ta-num">' + txt('lesson') + ' ' + String(a.ix + 1).padStart(2, '0') + '</span>' +
          '<span class="ta-tit">' + esc(a.title) + '</span>' +
        '</span>' +
        '<span class="ta-count">' + pa.done + '/' + pa.total + '</span>' +
      '</button>';

    if (!open) return head;

    const inside = sections.map((s) => {
      const ok = sectionDone(id, a.ix, s.id);
      /* The icon says what the section IS, not only its state: play for what has
         video, a page for what is reading, a star for the assessment. Before,
         every section was a play, which promised video in all of them. */
      const mark = ok ? ICON_CHECK
        : (s.type === 'assessment' ? ICON_STAR
          : (s.video !== undefined ? ICON_PLAY : ICON_TEXT));
      return '<a class="rail-section' + (ok ? ' done' : '') +
        (s.id === currentSec && isCurrent ? ' on' : '') +
        (s.type === 'assessment' ? ' assessment' : '') + (s.pending ? ' pending' : '') + '" ' +
        'href="#/course/' + esc(address) + '/lesson/' + a.ix + '/' + esc(s.id) + '">' +
        '<span class="ts-mark" aria-hidden="true">' + mark + '</span>' +
        '<span class="ts-middle">' +
          '<span class="ts-title">' + esc(s.title) + '</span>' +
          (s.duration ? '<span class="ts-dur mono">' + esc(s.duration) + '</span>' : '') +
        '</span>' +
      '</a>';
    }).join('');

    return head + '<div class="rail-sections">' + inside + '</div>';
  }).join('');

  /* The exam comes in as a row at the end of the list, shaped like a section —
     because that is what it is to someone navigating: the last item of the
     course. It only shows up where there is a question bank, for the same reason
     as the pending assessment: announcing what does not exist is noise. */
  const exam = courseExam(id);
  const onExam = path === '/course/' + id + '/exam';
  const passed = examPassed(exam.key);
  const examRow = exam.items.length
    ? '<a class="rail-exam' + (passed ? ' done' : '') + (onExam ? ' on' : '') + '" ' +
      'href="#/course/' + esc(address) + '/exam">' +
      '<span class="ts-mark" aria-hidden="true">' + (passed ? ICON_CHECK : ICON_TROPHY) + '</span>' +
      '<span class="ts-title">' + txt('Final exam') + '</span>' +
    '</a>'
    : '';

  return (
    '<a class="rail-back" href="#/track">← ' + txt('my track') + '</a>' +
    '<div class="rail-sec">' +
      '<span class="rail-tit">' + esc(c.name) + '</span>' +
      bar(p.pct, p.done + ' ' + txt('of') + ' ' + p.total) +
      '<span class="rail-count">' + p.done + '/' + p.total + ' ' + txt('sections') + '</span>' +
      '<div class="rail-lessons">' + rows + '</div>' +
      examRow +
    '</div>'
  );
}
