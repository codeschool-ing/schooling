/* ==========================================================================
   What needs a person today.

   # THE SCREEN THAT ANSWERS "WHERE DO I LOOK"

   Fourteen screens each answer one question well, and none of them answered
   that one — so opening this console cold meant already knowing which screen
   held the thing that was wrong. The screens somebody opens are the ones they
   already suspect, and the defect nobody suspects is the one that stays.

   # IT IS EMPTY WHEN NOTHING IS WRONG, AND THAT IS THE FEATURE

   A wall of figures always has something to look at, which is how a screen
   stops being read. This one is a list of things that are TRUE and want
   somebody, so a quiet platform draws a sentence and nothing else — and a line
   appearing on it means something.

   THE EMPTY STATE IS THE SERVER'S SENTENCE, because "there is nothing to do"
   and "this failed to load" look identical, and this is the one screen where
   the first would be read as good news.

   # EVERY LINE IS ONE CLICK FROM THE SCREEN THAT EXPLAINS IT

   Nothing here carries a threshold, a chart or an argument: those live on the
   screen that owns the finding, with the numbers that produced it. This says
   what is true and where to go, which is all a person needs to decide whether
   tonight is the night.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { txt } from '../../assets/language.js';
import { goTo } from '../routes.js';

/* THE RAIL'S OWN NAME FOR A SCREEN, so a finding says "Reported content" rather
   than the route `reports`. It is imported from the file that imports this one,
   which is a cycle — and a safe one, because `sectionById` is only ever CALLED
   while a finding is being drawn, long after both modules have finished
   evaluating. Reading it at module level would be the version that breaks. */
import { sectionById } from '../sections.js';

/* WHAT EACH FINDING SAYS, in one sentence for one of them and another for
   several. A count of one followed by a plural is the defect this console has
   shipped once — "1 trilhas" — and a sentence is what an operator reads
   anyway: `3` beside a label is a number to decode, and "three questions the
   analysis condemned are still being asked" is already the thought.

   EVERY SENTENCE IS ONE LITERAL ON ONE LINE, however long. `language_test.go`
   reads this map — the strings are looked up through a variable, so
   `check-interface` cannot see them — and it takes the first literal of a
   concatenation, which would ask the dictionary for half a sentence.

   THE KEYS ARE THE SERVER'S WORDS. A kind this list does not know is drawn as
   itself rather than folded into the nearest — the closed-list rule every other
   screen here follows, so a finding added on the server appears as something
   nobody has styled rather than as the wrong sentence. */
const SAYS = {
  'questions-still-asked': {
    one: 'A question the analysis condemned is still being asked.',
    many: '%d questions the analysis condemned are still being asked.',
  },
  'reports-waiting': {
    one: 'A student wrote in about a lesson and nobody has answered.',
    many: '%d students wrote in about a lesson and nobody has answered.',
  },
  'roles-without-a-second-factor': {
    one: 'Somebody holds a role and has no second factor, so it opens nothing.',
    many: '%d people hold a role and have no second factor, so it opens nothing.',
  },
  'roles-never-used': {
    one: 'A role was granted and has never been used.',
    many: '%d roles were granted and have never been used.',
  },
  'jobs-that-failed': {
    one: 'A scheduled job failed the last time it ran.',
    many: '%d scheduled jobs failed the last time they ran.',
  },
  'jobs-adrift': {
    one: 'A job started and never said it finished.',
    many: '%d jobs started and never said they finished.',
  },
  'jobs-that-never-ran': {
    one: 'A job that can be started has never recorded a run.',
    many: '%d jobs that can be started have never recorded a run.',
  },
  'could-not-be-checked': {
    one: 'One of the things this screen checks could not be read, so its line is missing rather than empty.',
    many: '%d of the things this screen checks could not be read, so their lines are missing rather than empty.',
  },
};

export default async function today(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Attend')) + '</span>' +
      '<h1>' + esc(txt('What needs you')) + '</h1>' +
      '<p>' + esc(txt('Everything on this platform that is true right now and wants a person. It is empty on the days nothing is — which is most of them, and is the reason a line appearing here means something.')) + '</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const body = el.querySelector('#body');

  let answer;
  try {
    answer = await get('/console/api/v1/today');
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) + '</p></section>';
    return { title: section.name, el };
  }

  const found = answer.findings || [];

  body.innerHTML =
    (found.length === 0
      ? '<section class="block"><p class="none">' +
        esc(txt(answer.nothing_to_do || '')) + '</p></section>'
      : '<section class="block"><ul class="findings">' +
          found.map(row).join('') +
        '</ul></section>') +

    /* SAID WHETHER OR NOT ANYTHING IS WRONG. Somebody looking at a console home
       reasonably expects it to tell them when something breaks, and a screen
       that let the expectation stand is one they would rely on at the worst
       possible moment (K-08). It is the server's sentence. */
    '<section class="block">' +
      '<div class="block-top"><h2>' + esc(txt('This is not an alarm')) + '</h2></div>' +
      '<p class="aside">' + esc(txt(answer.not_an_alarm || '')) + '</p>' +
    '</section>';

  /* THE WHOLE ROW IS THE CONTROL. A finding is a thing to act on, so the target
     is the sentence rather than a "view" link beside it — and it is a `button`
     rather than an anchor because the router is the thing that moves, which is
     what every other in-console navigation does. */
  body.querySelectorAll('[data-where]').forEach((one) => {
    one.addEventListener('click', () => goTo('/' + one.dataset.where));
  });

  return { title: section.name, el };
}

function row(finding) {
  const says = SAYS[finding.kind];

  /* A KIND NOBODY HAS WRITTEN A SENTENCE FOR IS STILL SHOWN. It is a real
     finding that a screen simply does not have words for yet, and hiding it
     would make this screen quietly incomplete — which is the one thing it may
     not be. The count and the server's own word are what there is. */
  const said = says
    ? (finding.count === 1 ? txt(says.one) : txt(says.many).replace('%d', finding.count))
    : finding.kind + ' — ' + finding.count;

  /* A FINDING WITH NOWHERE TO GO IS NOT A BUTTON. `could-not-be-checked` has no
     screen of its own: it is about this one. A control that navigated nowhere
     would be worse than a sentence. */
  if (!finding.where) {
    return '<li class="finding finding-quiet"><span>' + esc(said) + '</span></li>';
  }

  return '<li class="finding">' +
    '<button type="button" class="finding-go" data-where="' + esc(finding.where) + '">' +
      '<span class="finding-said">' + esc(said) + '</span>' +
      '<span class="finding-where mono">' + esc(nameOf(finding.where)) + '</span>' +
    '</button>' +
  '</li>';
}

// What the rail calls the screen a finding points at, falling back to the route
// where a section has been renamed out from under a finding the server still
// sends — visible rather than blank.
function nameOf(where) {
  const section = sectionById(where);
  return section ? txt(section.name) : where;
}
