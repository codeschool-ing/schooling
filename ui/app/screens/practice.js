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

   # THE CARD IS DRAWN ONE AT A TIME, AND THE QUEUE IS NOT

   The queue is a list of ids. Each question is fetched when it comes up,
   because drawing is what fixes the arrangement: the server shuffles it and
   writes down the permutation so the answer can be mapped back. Drawing twenty
   at once would fix twenty arrangements a student may never reach, and the
   nineteenth would have been shuffled for a session they abandoned.

   # AND IT IS NEVER MARKED HERE

   The card arrives with no answer in it, so this file could not mark it if it
   wanted to. The verdict is a request, and the key comes back WITH the verdict
   — never before it. That is the same rule an exam runs on, and a drill obeys
   it for a plainer reason than secrecy: a question whose answer is in the page
   is a drill you can pass without remembering anything.

   # ONE ANSWER PER CARD

   No "try again" here, unlike a lesson. The schedule moves the moment the
   answer lands — that is what a drill IS — so a second attempt would be a
   second answer to a card already counted, and the interval it earned would be
   whichever try the student stopped on.
   ========================================================================== */

import * as api from '../api.js';
import { now } from '../state.js';
import { buildExercise } from '../exercises/index.js';
import { empty } from './common.js';
import { esc } from '../text.js';

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
    '<section class="block drill">' +
      '<p class="drill-count" aria-live="polite"></p>' +
      '<div class="drill-stage"></div>' +
      '<footer class="drill-foot" hidden>' +
        '<button type="button" class="btn btn-primary drill-next"></button>' +
      '</footer>' +
    '</section>');

  const stage = el.querySelector('.drill-stage');
  const count = el.querySelector('.drill-count');
  const foot = el.querySelector('.drill-foot');
  const next = el.querySelector('.drill-next');

  let at = 0;
  let done = 0;
  let right = 0;

  function tally() {
    count.textContent = txt('question') + ' ' + Math.min(at + 1, queue.length)
      + ' ' + txt('of') + ' ' + queue.length;
  }

  /* WHAT WAS DRAWN AND ANSWERED, SAID PLAINLY AT THE END. A drill that ended by
     simply emptying would leave somebody with no idea whether the twenty
     minutes went well — and the number that matters is not a mark, it is how
     many are now further away from being forgotten. */
  function finish() {
    stage.innerHTML = '';
    foot.hidden = true;
    count.textContent = '';
    stage.innerHTML =
      '<p class="drill-done"><strong>' + txt('Done for today.') + '</strong></p>' +
      '<p class="dim">' + esc(
        txt('{right} of {done} right. Each one comes back further away.')
          .replace('{right}', String(right))
          .replace('{done}', String(done))) + '</p>';
  }

  async function draw() {
    if (at >= queue.length) {
      finish();
      return;
    }
    tally();
    foot.hidden = true;
    stage.innerHTML = '<p class="dim">' + txt('drawing…') + '</p>';

    let card;
    try {
      card = await api.practiceDraw(queue[at].exercise);
    } catch (e) {
      /* A CARD THAT CANNOT BE DRAWN IS SKIPPED, NOT FATAL. A question withdrawn
         between the queue being read and this card coming up is the ordinary
         case, and it must not end a session somebody is halfway through. */
      stage.innerHTML = '<p class="empty">' + txt('That question could not be drawn.') + '</p>';
      at += 1;
      foot.hidden = false;
      next.textContent = txt('next') + ' →';
      return;
    }

    stage.innerHTML = '';
    const question = buildExercise(card, null, at, { drill: true });
    stage.appendChild(question);

    question.addEventListener('exercise:answered', (e) => {
      done += 1;
      if (e.detail && e.detail.v && e.detail.v.correct) right += 1;
      at += 1;
      foot.hidden = false;
      next.textContent = at >= queue.length ? txt('Finish') : txt('next') + ' →';
      next.focus();
    });
  }

  next.addEventListener('click', draw);
  await draw();

  return { title: txt('Practice'), el };
}
