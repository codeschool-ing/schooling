/* ==========================================================================
   Practice — the questions you are closest to forgetting.

   A SCREEN THE PORTAL DOES NOT HAVE, and one this deployment does: the server
   keeps a schedule per student per question and hands back a queue. The copy
   dropped it along with the interface it belonged to; this brings it back in
   the copied interface's vocabulary.

   ONE CARD AT A TIME, AND THE QUEUE IS FETCHED ONCE. A screen that re-asked
   after every answer would put a round trip between a student and the next
   question, which for a drill — the thing you do twenty of in five minutes —
   is the difference between a habit and a chore.

   AND IT SAYS WHAT IT IS FOR. A queue with a number on it and no explanation is
   a chore somebody is being set; the point is that these are the things they
   are about to forget.

   WHAT IT CANNOT DO YET, IT SAYS. The questions themselves are not imported —
   the portal keys one by the topic's English text and carries a payload per
   type, and this side keys by section id with a grader per type, which is a
   translation rather than a copy (the same note stands over `lessonExercises`
   in api.js). So the queue is empty for everybody today, and a card that did
   arrive would meet a renderer that has never seen its shape. It reports that
   rather than drawing something wrong: an empty drill is honest, and a drill
   that mis-draws a question is a student answering the wrong thing.
   ========================================================================== */

import * as api from '../api.js';
import { now } from '../state.js';
import { empty } from './common.js';

const head = (extra) =>
  '<header class="view-head">' +
    '<h1>' + txt('Practice') + '</h1>' +
    '<p>' + txt('The questions you are closest to forgetting.') + '</p>' +
  '</header>' + (extra || '');

export default async function practice() {
  const el = document.createElement('div');
  el.className = 'view screen-practice';

  /* The offline copy has no session and no schedule; the router puts the
     "this needs the school" notice above whatever this returns, so the screen
     only has to be a screen. */
  if (api.offline) {
    el.innerHTML = head();
    return { title: txt('Practice'), el };
  }

  if (!now().session) {
    return {
      title: txt('Practice'),
      el: empty(txt('Sign in to practise: the schedule is yours and it lives with the school.')),
    };
  }

  let queue = [];
  try {
    const answer = await api.practiceQueue();
    queue = (answer && answer.cards) || [];
  } catch (e) {
    el.innerHTML = head(
      '<section class="block"><p class="empty">'
      + txt('The schedule could not be read.') + '</p></section>');
    return { title: txt('Practice'), el };
  }

  if (!queue.length) {
    el.innerHTML = head(
      '<section class="block">' +
        '<p>' + txt('Nothing is due. Come back tomorrow.') + '</p>' +
        '<p class="dim">' + txt('A question comes back when you are about to forget it, '
          + 'not on a timetable.') + '</p>' +
      '</section>');
    return { title: txt('Practice'), el };
  }

  el.innerHTML = head(
    '<section class="block">' +
      '<p>' + queue.length + ' ' + txt('due') + '</p>' +
      '<p class="dim">' + txt('The questions themselves are not in this school yet.') + '</p>' +
    '</section>');
  return { title: txt('Practice'), el };
}
