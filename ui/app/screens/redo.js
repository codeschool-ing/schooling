/* ==========================================================================
   Redo what you got wrong.

   It builds the same assessment wizard with the exercises the student got wrong,
   from any course. It is the only screen in the portal that gathers content from
   different lessons, and it makes sense because the criterion here is not the
   curriculum — it is the mistake.

   EACH EXERCISE'S CONTEXT IS PRESERVED. The wizard stores the answer under
   `progress[course].lessons[ix]`, so each one has to come back with the course and
   the lesson it came from; passing a single context would record the correct
   answer against the wrong lesson, and the performance screen would start lying
   about where the person improved.
   ========================================================================== */

import { buildAssessment } from '../exercises/index.js';
import { wrongOnes } from './performance.js';
import { courseLessons } from '../catalog.js';
import { empty } from './common.js';

export default async function redo() {
  const list = wrongOnes();
  if (!list.length) {
    return { title: txt('Redo'), el: empty(txt('There is nothing wrong to redo.')) };
  }

  const el = document.createElement('div');
  el.className = 'view screen-redo';
  el.innerHTML =
    '<header class="view-head">' +
      '<h1>' + txt('The ones you got wrong') + '</h1>' +
      '<p>' + list.length + ' ' + (list.length === 1
        ? txt('exercise, from the course you answered it in.')
        : txt('exercises, from every course you answered in.')) + '</p>' +
    '</header>' +
    '<section class="block"></section>';

  /* One context per exercise, and not a single one for the whole wizard: each
     answer has to be stored against the lesson it came from.

     AND THE LESSON'S OWN ID RIDES WITH IT, which is what says who marks this.
     Without it the wizard fell through to the local comparator — the offline
     one, against a key this browser does not hold — so four of the nine types
     could not be marked at all and the rest were compared against nothing. A
     lesson's question is marked by the lesson's route, wherever it is being
     asked. */
  const contextByIndex = list.map((r) => ({
    courseId: r.courseId,
    lessonIx: r.lessonIx,
    lessonId: (courseLessons(r.courseId)[r.lessonIx] || {}).key,
  }));
  el.querySelector('.block').appendChild(
    /* `fresh`: this screen is here to ask again. Everywhere else a question
       already answered comes back answered — see `buildExercise` — and here
       that would be a gallery of old mistakes with a button under each. */
    buildAssessment(list.map((r) => r.ex), contextByIndex, { fresh: true }),
  );

  return { title: txt('Redo'), el };
}
