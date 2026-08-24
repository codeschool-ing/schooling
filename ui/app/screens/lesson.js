/* ==========================================================================
   Lesson — one SECTION at a time.

   TWO THINGS MOVED, AND WHY

   1. "Previous" and "next" left the footer and became arrows on the SIDES, on a
      wide screen. The content is pinned to a reading column, so there is space
      to spare on both sides and none vertically — where every pixel spent is
      text pushed below the fold. Below 1400px there is no side to spare and they
      go back to the footer.

   2. There is no "complete" button any more. It and the arrow did the same
      thing, and merging the two into a "Complete and continue" only postponed
      the question: if moving on already completed the section, the button was a
      second route to the same gesture.

      NOW MOVING ON IS COMPLETING. Going to the next section marks the current
      one as done — which is what the student already meant by clicking next. The
      feedback is still immediate and in two places: the step gets its check and
      so does the rail.

      What is lost, and it is worth knowing: there is no longer a way to mark
      without leaving the section, nor to unmark. Anyone who skims accumulates
      progress without having read. It is the trade accepted in favour of a single
      gesture — and it matches the rest of the portal, which shows and does not
      lock.
   ========================================================================== */

import * as api from '../api.js';
import { courseLessons, courseById, courseAddress } from '../catalog.js';
import { lessonSections, sectionMaterials } from '../lessons.js';
import { materialList } from '../materials.js';
import { sectionDone, visitSection, noteFor, saveNote } from '../state.js';
import { buildAssessment } from '../exercises/index.js';
import { empty, videoFrame, playsOnClick, subscribeInvite } from './common.js';
import { wireReport } from '../report.js';
import { esc, prose } from '../text.js';

const ARROW = (d) => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ' +
  'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="' + d + '"/></svg>';
const ARROW_LEFT = ARROW('M15 5l-7 7 7 7');
const ARROW_RIGHT = ARROW('M9 5l7 7-7 7');

/* The next and previous sections cross the lesson boundary: at the end of the
   last section, "next" leads to the first section of the following lesson.
   Without that the student would go back to the course index at every topic,
   which is pure friction. */
function neighbours(courseId, ix, pos) {
  const lessons = courseLessons(courseId);
  const sections = lessonSections(courseId, lessons[ix].key);
  /* A NEIGHBOUR CARRIES BOTH NAMES. The id is what the screen works with and
     the slug is what goes in the address, and the section next door may belong
     to another lesson — so it is read here, where that lesson's sections are in
     hand, rather than looked up again by whoever builds the link. */
  const at = (i, sec) => ({ ix: i, sectionId: sec.id, sectionSlug: sec.slug || sec.id });
  const lastOf = (i) => {
    const s = lessonSections(courseId, lessons[i].key);
    return s[s.length - 1];
  };
  const previous = pos > 0
    ? at(ix, sections[pos - 1])
    : (ix > 0 ? at(ix - 1, lastOf(ix - 1)) : null);
  const next = pos + 1 < sections.length
    ? at(ix, sections[pos + 1])
    : (ix + 1 < lessons.length
      ? at(ix + 1, lessonSections(courseId, lessons[ix + 1].key)[0])
      : null);
  return { previous, next };
}

/* What a course outside the plan looks like.

   IT IS AN INVITATION AND NOT A REFUSAL. This is the highest-intent moment the
   portal has — somebody wanted this course enough to click it — and it used to
   answer with a grey box and a sentence. The offer lives in
   `subscribeInvite`, shared with the plan screen so the two cannot drift.

   It names the course in the mail it opens, which is the most useful thing this
   screen can collect while there is nothing to click. */
function locked(course) {
  const el = document.createElement('div');
  el.className = 'view view-locked';
  el.innerHTML =
    '<header class="view-head">' +
      '<a class="back mono" href="#/catalog">← ' + esc(txt('Catalog')) + '</a>' +
      '<h1>' + esc(course.name) + '</h1>' +
    '</header>' +
    subscribeInvite(course.name);
  return el;
}

export default async function lesson({ id, ix, sec }) {
  const c = courseById(id);
  const lessons = courseLessons(id);
  const n = Number(ix);
  const a = lessons[n];
  if (!c || !a) return { title: txt('Lesson'), el: empty(txt('Lesson not found.')) };

  /* The prose, which no longer ships with the page. It is awaited here and not
     at boot because it is one course's content, it is what the subscription
     sells, and the server refuses it for a course this plan does not include.

     A REFUSAL IS NOT AN ERROR. It is the paywall working, and what a student
     should meet is the offer rather than a failure — so it gets its own screen,
     instead of falling through to a lesson drawn with no words in it. */
  if (await api.loadCourseContent(id) === 'locked') {
    return { title: c.name, el: locked(c) };
  }

  const sections = lessonSections(id, a.key);
  /* THE ADDRESS CARRIES THE SLUG, and an id is still accepted. A link somebody
     saved before the two were separated names the section by what was then its
     only name; landing them on the first section instead would be a bookmark
     that silently goes to the wrong place. */
  const pos = Math.max(0, sections.findIndex((s) => (s.slug || s.id) === sec || s.id === sec));
  const section = sections[pos];

  visitSection(id, n, section.id);

  const { previous, next } = neighbours(id, n, pos);
  const note = noteFor(id, n, section.id);

  /* WHO IS OFFERED THE CONTROL. A report is written against an account, so
     somebody reading signed out has nothing to attach one to — and the offline
     copy is a file on a disk with no server to send it to. Neither is a failure
     worth a message: the control simply is not there, which is the same choice
     the note makes. */
  const canReport = !api.offline && Boolean(await api.session());

  const routeTo = (v) => '#/course/' + esc(courseAddress(id)) + '/lesson/' + v.ix + '/' + esc(v.sectionSlug || v.sectionId);

  const el = document.createElement('div');
  const hasVideoHere = section.type === 'content' && section.video !== undefined;
  el.className = 'view view-lesson' + (hasVideoHere ? ' lesson-with-video' : ' lesson-text-only');

  const steps = sections.map((s, i) => (
    '<a class="step' + (i === pos ? ' on' : '') + (sectionDone(id, n, s.id) ? ' done' : '') +
      (s.type === 'assessment' ? ' step-assessment' : '') + (s.pending ? ' step-pending' : '') + '" ' +
      'href="#/course/' + esc(id) + '/lesson/' + n + '/' + esc(s.id) + '">' +
      '<span class="step-n">' + (s.type === 'assessment' ? '★' : String(i + 1).padStart(2, '0')) + '</span>' +
      '<span class="step-title">' + esc(s.title) + '</span>' +
    '</a>'
  )).join('');

  /* The forward arrow ALWAYS exists. On the course's last section it leads to
     the course page — if it disappeared there, that section would be the only
     one that could never be completed, because completing became moving on. */
  const nextTarget = next ? routeTo(next) : '#/course/' + esc(courseAddress(id));
  const sideArrow = (target, side, arrow, label, advances) => (target
    ? '<a class="side-arrow side-' + side + (advances ? ' advances' : '') + '" href="' + target +
      '" aria-label="' + label + '">' + arrow + '</a>'
    : '');

  /* THE VIDEO FRAME ONLY EXISTS WHERE THE SECTION SAYS IT HAS VIDEO.

     It used to be in every content section, reserved, on the argument that
     publishing the videos one at a time would not rearrange anyone's screen. The
     argument still holds for a section that WILL have video — and it is terrible
     for one that never will. A text section with a grey rectangle on top
     promises something that is not coming, and the promise does not expire.

     What fixes it is the section DECLARING:

       video: 'ID'   a published video — it plays right there
       video: true   there will be video, there is none yet — the space is held
       (absent)      a text section: no frame, no promise

     The reservation was not lost; it stopped being automatic and started being
     stated. */
  const hasVideo = hasVideoHere;
  const videoReady = hasVideo && typeof section.video === 'string' && section.video;

  el.innerHTML =
    sideArrow(previous && routeTo(previous), 'left', ARROW_LEFT, txt('previous section')) +
    sideArrow(nextTarget, 'right', ARROW_RIGHT, txt('complete and go to the next section'), true) +

    '<nav class="crumbs">' +
      '<a href="#/course/' + esc(id) + '">' + esc(c.name) + '</a>' +
      '<span aria-hidden="true">›</span>' +
      '<span>' + txt('lesson') + ' ' + (n + 1) + ' ' + txt('of') + ' ' + lessons.length + '</span>' +
    '</nav>' +

    '<header class="lesson-head">' +
      '<h1 class="lesson-title">' + esc(a.title) + '</h1>' +
      '<nav class="steps" aria-label="' + txt('Sections of this lesson') + '">' + steps + '</nav>' +
    '</header>' +

    '<h2 class="section-title">' + esc(section.title) + '</h2>' +

    /* THE PLAYER COMES AFTER THE HEADER. It used to come before, so as not to
       push the play button below the fold — and the price was landing in a
       section without knowing which lesson it belongs to. Where am I comes before
       what am I watching, and the answer is the same in the text sections. */
    (hasVideo
      ? videoFrame(videoReady, { label: txt('Watch'), duration: section.duration })
      : '') +

    (section.type === 'assessment'
      ? '<section class="block lesson-exercises' + (section.pending ? ' assessment-pending' : '') + '">' +
          (section.pending
            ? '<p class="mono dim">' + txt('[assessment in preparation — this topic\'s exercises have not been produced yet]') + '</p>'
            : '') +
        '</section>'
      /* A video-only section gets no text block at all — not even the "content
         to come" notice, which would be false there: the content is the video.
         The notice still holds for a lesson with nothing written yet. */
      : (section.body
        ? '<section class="block lesson-text">' + prose(section.body) + '</section>'
        : (hasVideo
          ? ''
          : '<section class="block lesson-text"><p class="mono dim">' +
            txt('[lesson content — the real material lands in Stage 2]') + '</p></section>'))) +

    /* Material comes AFTER the text and BEFORE the note: downloading the PDF is
       what you do having read, and taking a note is the section's last gesture. */
    materialList(sectionMaterials(section)) +

    /* The note sits at the END of the section, and not floating beside it:
       noting is what you do after reading, not during. Collapsed when empty, so
       it does not ask for attention from someone who will not use it. */
    '<details class="note" ' + (note ? 'open' : '') + '>' +
      '<summary>' + (note ? '✎ ' + txt('your note') : '＋ ' + txt('make a note on this section')) + '</summary>' +
      '<textarea class="note-field" rows="4" placeholder="' +
        txt('what you want to remember from this section…') + '">' + esc(note) + '</textarea>' +
      '<span class="note-status mono dim" aria-live="polite"></span>' +
    '</details>' +

    /* AND AFTER THE NOTE, THE OTHER THING SOMEBODY MAY HAVE TO SAY.

       The note is what you write for yourself; this is what you write to us,
       and it is the only channel in the platform by which a wrong answer key
       comes back from the person who found it. Same shape as the note for the
       same reason: collapsed, so it asks nothing of the many people who will
       never use it, and right at the end, because you report a problem having
       met it.

       IT IS BUILT WHEN IT IS OPENED. The list of reasons and whether this
       section has already been reported both come from the server, and
       fetching them on every lesson view would be a request per view to fill in
       a form almost nobody opens. */
    (canReport
      /* `report-section` AND NOT JUST `report`. An assessment section renders
         exercise cards into this same element, each with a control of its own,
         and they are appended BEFORE this line runs — so `querySelector('.report')`
         would find a question's control and wire the section's subject to it.
         The two are told apart by class rather than by position, because
         position is exactly what changed. */
      ? '<details class="report report-section">' +
          '<summary>⚑ ' + txt('something here is wrong') + '</summary>' +
          '<div class="report-body"><p class="checking">' + txt('reading…') + '</p></div>' +
        '</details>'
      : '') +

    /* The footer only exists where there are no side arrows — below 1400px.
       There is no complete button: moving on is completing. */
    '<footer class="lesson-foot">' +
      (previous ? '<a class="btn btn-ghost" href="' + routeTo(previous) + '">← ' + txt('previous') + '</a>' : '<span></span>') +
      '<a class="btn btn-primary advances" href="' + nextTarget + '">' + txt('next') + ' →</a>' +
    '</footer>';

  if (section.type === 'assessment' && !section.pending) {
    const exercises = await api.lessonExercises(id, a.key);
    el.querySelector('.lesson-exercises').appendChild(buildAssessment(exercises, { courseId: id, lessonIx: n }));
  }

  playsOnClick(el, section.title);

  /* The note saves itself, after a pause following the last keystroke. A save
     button would be one more chance to lose what you wrote. */
  const noteField = el.querySelector('.note-field');
  const notice = el.querySelector('.note-status');
  let saveT = null;
  noteField.addEventListener('input', () => {
    clearTimeout(saveT);
    notice.textContent = txt('typing…');
    saveT = setTimeout(() => {
      saveNote(id, n, section.id, noteField.value);
      notice.textContent = txt('note saved');
      setTimeout(() => { notice.textContent = ''; }, 1600);
    }, 600);
  });
  // leaving the section must not lose what has not been saved yet
  noteField.addEventListener('blur', () => {
    clearTimeout(saveT);
    saveNote(id, n, section.id, noteField.value);
  });

  /* The control builds itself the first time it is opened — see `report.js` for
     why it is not built with the rest of the screen. */
  if (canReport) {
    wireReport(el.querySelector('.report-section'), {
      courseId: id, lessonIx: n, sectionId: section.id,
    });
  }

  /* Moving on completes. The marking is synchronous inside, so it happens before
     the browser processes the hash change — there is no race. An assessment with
     no exercises yet stays out: there is nothing to complete in it. */
  el.addEventListener('click', (e) => {
    if (!e.target.closest('.advances')) return;
    if (section.pending) return;
    if (!sectionDone(id, n, section.id)) api.completeSection(id, n, section.id, true);
  });

  return { title: a.title + ' · ' + section.title, el };
}
