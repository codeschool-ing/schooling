/* ==========================================================================
   Reported content — the one screen here with somebody waiting on the other
   end of it.

   EVERY OTHER SCREEN IN THIS CONSOLE ANSWERS A QUESTION THE OPERATOR HAD. This
   one carries a question somebody else had, and two things follow from that.

   The queue is OLDEST FIRST, which is the opposite of every other list here. A
   queue is worked through rather than watched: newest-first buries the report
   that has been waiting three weeks under the one that arrived this morning,
   and the one that has been waiting is the one that has been failing somebody
   the longest. The wait is drawn beside each row for the same reason.

   And it is EMPTY MOST OF THE TIME, which is the state that matters. An empty
   queue is the good outcome and it must not look like a screen that failed to
   load — so it says so in a sentence rather than by drawing nothing.

   # IT DOES NOT SAY WHO

   A person is found in this console by an exact address and never listed
   (K-22). A queue naming who complained is a list of people to browse, which is
   the read an audit cannot tell apart from working. The answer carries no
   account and this screen has nothing to draw one with.

   # THE VERDICTS ARE THE SERVER'S

   Three words, and they arrive on the answer rather than being written here —
   the same rule as a threshold, and for the same failure: a screen with its own
   copy of a list keeps offering the old one, and the version it then sends is
   refused.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, post } from '../request.js';

/* The sentence beside each word. Presentation, so it lives here — but a verdict
   the server offers and this file has no sentence for is drawn under its own
   word rather than dropped, because a decision an operator cannot reach is
   worse than a button that reads oddly. */
const MEANS = {
  fixed: 'The material was changed',
  'no-change': 'Looked at it — nothing is wrong',
  noted: 'Real, and not being fixed now',
};

const WHY = {
  answer: 'answer key',
  wrong: 'not true',
  broken: 'does not work',
  unclear: 'cannot follow it',
  other: 'something else',
};

export default async function reports(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Operate</span>' +
      '<h1>Reported content</h1>' +
      '<p>What students say is wrong with the material. It is the only channel ' +
      'by which a wrong answer key comes back from the person who found it — ' +
      'the check that runs on every pull request can tell that a key parses ' +
      'and not that it is the right one.</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">Reading…</p></div>';

  const body = el.querySelector('#body');

  let schools;
  try {
    schools = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  if (!schools.length) {
    body.innerHTML = '<section class="block"><p class="none">There are no schools on this ' +
      'platform yet, so there is no material to report.</p></section>';
    return { title: section.name, el };
  }

  const asking = { school: schools[0].id };

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>Which school</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>School</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
      '</form>' +
    '</section>' +
    '<div id="queue"><p class="checking">Reading…</p></div>';

  const queue = body.querySelector('#queue');
  body.querySelector('#ask').addEventListener('change', (event) => {
    if (event.target.id === 'school') {
      asking.school = event.target.value;
      draw();
    }
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    queue.innerHTML = '<p class="checking">Reading…</p>';
    const mine = asking.school;

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' +
        encodeURIComponent(asking.school) + '/reports');
    } catch (e) {
      if (mine !== asking.school) return;
      queue.innerHTML = '<section class="block"><p class="none">' + esc(e.message) +
        '</p></section>';
      return;
    }
    if (mine !== asking.school) return;

    const rows = answer.reports || [];

    queue.innerHTML =
      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>Waiting</h2>' +
          '<span class="block-score mono">' + rows.length + '</span>' +
        '</div>' +

        /* NOTHING TO ANSWER IS THE GOOD OUTCOME AND SAYS SO. An empty list
           drawn as nothing is indistinguishable from a read that failed, and
           this screen is empty most of the time by design. */
        (rows.length === 0
          ? '<p class="none">Nobody has reported anything in this school. That is the ' +
            'state this screen is meant to be in.</p>'
          : rows.map((r) => card(r, answer.verdicts || [])).join('')) +

        '<p class="aside">' + esc(answer.anonymous || '') + '</p>' +
      '</section>';

    queue.querySelectorAll('.verdict-pick').forEach((button) => {
      button.addEventListener('click', () => settle(button, button.dataset.report,
        button.dataset.verdict));
    });
  }

  async function settle(button, id, verdict) {
    const card = button.closest('.report-card');
    const said = card.querySelector('.report-status');
    card.querySelectorAll('.verdict-pick').forEach((b) => { b.disabled = true; });
    said.textContent = 'Settling…';

    try {
      await post('/console/api/v1/reports/' + encodeURIComponent(id) + '/settle', { verdict });
    } catch (e) {
      /* A CONFLICT IS NOT A FAILURE, it is somebody else having answered this
         one first — which is the ordinary thing when two people work a queue.
         The message says so and the row is redrawn out of existence by the
         reload rather than left claiming to be open. */
      card.querySelectorAll('.verdict-pick').forEach((b) => { b.disabled = false; });
      said.textContent = e.message;
      return;
    }
    await draw();
  }
}

function card(r, verdicts) {
  return '<article class="report-card">' +
    '<div class="report-top">' +
      '<span class="tag-why mono">' + esc(WHY[r.reason] || r.reason) + '</span>' +
      '<span class="report-waited mono">' + esc(waited(r.reported_at)) + '</span>' +
    '</div>' +

    /* THE COORDINATES IN MONO, because they are not a label — they are what
       somebody types to find the file this report is about, which is the next
       thing they do.

       A BLANK PART IS DRAWN AS BLANK. A question the catalogue cannot place
       carries a course and no path, and a hyphen where the lesson goes is more
       honest than closing the gap: what is missing is missing in the catalogue
       too, and that is itself worth seeing. */
    '<p class="report-where mono">' +
      [r.course_id, r.lesson_id, r.section_id].map((p) => esc(p || '—')).join(' / ') +
    '</p>' +

    /* AND WHICH QUESTION, WHERE IT WAS ONE. It is on its own line and not
       appended to the path, because it is the thing an operator opens: the path
       names a section holding twelve questions and only one of them was ever
       wrong. The version is beside it — a key fixed last week and a report from
       last month are about different questions with one id. */
    (r.exercise_id
      ? '<p class="report-which mono">' + esc(r.exercise_id) +
        '<span class="report-version"> v' + esc(String(r.exercise_version || 0)) + '</span></p>'
      : '') +

    (r.note
      ? '<blockquote class="report-note">' + esc(r.note) + '</blockquote>'
      : '<p class="report-nonote">They picked a reason and wrote nothing.</p>') +

    '<div class="report-foot">' +
      verdicts.map((v) =>
        '<button type="button" class="btn btn-ghost verdict-pick" ' +
          'data-report="' + esc(r.id) + '" data-verdict="' + esc(v) + '">' +
          esc(MEANS[v] || v) +
        '</button>').join('') +
      '<span class="report-status mono"></span>' +
    '</div>' +
  '</article>';
}

/* How long somebody has been waiting, which is the only thing about this
   timestamp anybody reads. Rounded down and never to the minute: "three days"
   is the fact, and "3 days, 4 hours" invites arithmetic nobody wanted. */
function waited(when) {
  const at = new Date(when);
  if (Number.isNaN(at.getTime())) return 'unknown';

  const hours = Math.floor((Date.now() - at.getTime()) / 3600000);
  if (hours < 1) return 'just now';
  if (hours < 24) return hours + (hours === 1 ? ' hour' : ' hours');
  const days = Math.floor(hours / 24);
  return days + (days === 1 ? ' day' : ' days');
}
