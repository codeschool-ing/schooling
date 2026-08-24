/* ==========================================================================
   "Something here is wrong" — the control, and the only part of this interface
   that talks back about the material.

   WHY IT IS ITS OWN FILE. Not because it is reused — today it is on the lesson
   screen and nowhere else — but because what it does is unlike anything the
   lesson screen does. Every other control there records what the student did
   with the material; this one says the material is wrong, and it is the second
   thing standing between a wrong answer key and somebody studying. The first is
   a check that runs in CI and cannot know that the accepted answer is the wrong
   one.

   # IT IS BUILT WHEN IT IS OPENED, AND NOT BEFORE

   The reasons and whether this section has already been reported both come from
   the server. Fetching them when the lesson is drawn would be a request per
   lesson view to fill in a form almost nobody opens; fetching them when
   somebody opens the control is one request for the people who mean to use it.

   # THE WORDS ARE THE SERVER'S AND THE SENTENCES ARE OURS

   `answer`, `wrong`, `broken`, `unclear`, `other` arrive from the store that
   will accept them — a screen with its own copy of that list keeps offering the
   old one, and the version it then sends is refused. What lives here is the
   sentence beside each word, which is presentation; a word this file has no
   sentence for is drawn under the word itself rather than left off the form,
   because a reason nobody can choose is worse than one that reads oddly.
   ========================================================================== */

import * as api from './api.js';
import { esc } from './text.js';

/* EACH ONE IS A FUNCTION AND NOT A STRING, and that is not style. The strings
   in this interface are held to their translations by a check that reads every
   literal call to `txt` in the source — a map of bare sentences looked up
   through a variable is invisible to it, so the five below would never be
   flagged as untranslated and would quietly stay English for every reader in
   Portuguese. Wrapped in a call each, they are five literal `txt` calls the
   check can see. */
const SAID = {
  answer: () => txt('the answer given as correct is wrong'),
  wrong: () => txt('something here is not true'),
  broken: () => txt('something does not work — a video, an image, a link'),
  unclear: () => txt('I cannot follow this'),
  other: () => txt('something else'),
};

/* Wire one `<details>` so that opening it builds the form, once.

   `at` is the section: `{ courseId, lessonIx, sectionId }`. It is passed rather
   than read, because this file knows nothing about where the student is. */
export function wireReport(details, at) {
  if (!details) return;
  const body = details.querySelector('.report-body');
  let built = false;

  details.addEventListener('toggle', async () => {
    if (!details.open || built) return;
    built = true;

    let answer;
    try {
      answer = await api.reportable();
    } catch (e) {
      /* A CONTROL THAT CANNOT LOAD SAYS SO AND STAYS OPEN TO TRY AGAIN. The
         alternative — an empty form — is somebody typing a paragraph into a
         box that was never going to send it. */
      built = false;
      body.innerHTML = '<p class="report-said">' + esc(txt('that could not be loaded')) + '</p>';
      return;
    }

    const already = (answer.reports || []).find((r) =>
      r.courseId === at.courseId && r.sectionId === at.sectionId);
    if (already) {
      body.innerHTML = '<p class="report-said">' +
        esc(txt('you have already told us about this section, and it has not been answered yet')) +
        '</p>';
      return;
    }

    body.innerHTML = form(answer.reasons || [], answer.noteLimit || 500);
    body.querySelector('form').addEventListener('submit', (event) => {
      event.preventDefault();
      send(body, at);
    });
  });
}

function form(reasons, limit) {
  return '<form class="report-form" novalidate>' +
    '<fieldset class="report-why">' +
      '<legend>' + esc(txt('what is wrong?')) + '</legend>' +
      reasons.map((word, i) =>
        '<label class="report-pick">' +
          '<input type="radio" name="reason" value="' + esc(word) + '"' +
            (i === 0 ? ' checked' : '') + '>' +
          '<span>' + esc(SAID[word] ? SAID[word]() : word) + '</span>' +
        '</label>').join('') +
    '</fieldset>' +

    /* THE BOX IS NOT OPTIONAL DECORATION. A reason on its own is a hunt — "the
       answer key is wrong" in a course of two hundred questions is a day's
       work; "question three says B and the working shows C" is a fix. So the
       placeholder asks for the specific thing rather than for a description. */
    '<textarea class="report-note" rows="3" maxlength="' + limit + '" placeholder="' +
      esc(txt('what did you see? the more exact, the sooner it is fixed…')) + '"></textarea>' +

    '<div class="report-foot">' +
      '<button type="submit" class="btn btn-ghost">' + esc(txt('send')) + '</button>' +
      '<span class="report-status mono dim" aria-live="polite"></span>' +
    '</div>' +
  '</form>';
}

async function send(body, at) {
  const form = body.querySelector('form');
  const status = body.querySelector('.report-status');
  const button = body.querySelector('button[type=submit]');
  const picked = form.querySelector('input[name=reason]:checked');
  if (!picked) return;

  // Disabled while it is in flight, so a second click is not a second report —
  // and the server would answer the second with the first anyway, which would
  // read here as "you already said this" a moment after saying it.
  button.disabled = true;
  status.textContent = txt('sending…');

  try {
    const answer = await api.reportSection(
      at.courseId, at.lessonIx, at.sectionId,
      picked.value, form.querySelector('.report-note').value);

    /* TWO LITERAL CALLS AND NOT ONE AROUND A TERNARY. The check that holds
       these strings to their translations reads the source for calls to `txt`
       with a string in them; a sentence chosen inside the brackets is invisible
       to it, and would have stayed English for every reader in Portuguese with
       nothing looking wrong. It was written the other way first. */
    const said = answer && answer.already
      ? txt('you have already told us about this section, and it has not been answered yet')
      : txt('thank you — somebody will look at this section');
    body.innerHTML = '<p class="report-said">' + esc(said) + '</p>';
  } catch (e) {
    button.disabled = false;
    status.textContent = txt('that did not send');
  }
}
