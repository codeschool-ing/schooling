/* ==========================================================================
   "What did you think of it" — the control, and the second of the two things
   in this interface that talk back.

   # IT IS NOT `report.js`, AND EVERY DECISION HERE COMES FROM THAT

   That one is a `<details>`, closed, opened by somebody who has found a defect
   and knows it. This one is open, visible, and asked of everybody — which means
   it has to survive being ignored, and has to be finishable in ONE GESTURE by
   somebody who does not want to be asked anything.

   So the star row is the whole control. Tapping a star is a complete answer: it
   posts, it says thank you, and it is done. Everything below it exists only
   after that tap, only under a threshold the server names, and is skippable
   without acknowledging it.

   # THE STARS ARE RADIO BUTTONS

   Not five spans with click handlers. The same argument as `labelling`, and it
   lands the same way: a control that needs a pointer and sight of where the
   pointer is cannot be operated by everybody (X-05, X-06). Five radios sharing
   one legend are arrow-key operable, announce the question, and announce which
   of five is chosen — for free, by being the right element.

   The star is then decoration drawn over them, and every one carries a real
   label in words, because "★★★" read aloud is not a rating.

   # THE PAIRS ARE ASKED AFTER, AND SOMETIMES NOT AT ALL

   Somebody who taps five stars has told us what they think. Somebody who taps
   two has the information, and four short questions is a fair thing to ask of
   them and not of everybody. The threshold is `askDeeper`, and it arrives from
   the server with the lists: it is a parameter an operator can move, and a copy
   of it here would keep asking the old question after somebody moved it.

   # NOTHING HERE HAS A TEXT BOX

   Deliberately, and it is the boundary between this feature and the other one.
   A comment box turns this into `report` under another name — with a queue, a
   verdict, and free text somebody has to read — and the point of counting
   opinions is that nobody has to read them one at a time. Somebody with
   something to SAY has the control on every section for exactly that.
   ========================================================================== */

import * as api from './api.js';
import { esc } from './text.js';

/* THE SENTENCES, EACH A FUNCTION RATHER THAN A STRING.

   `check-interface` reads every literal `txt` call in the source to hold the
   interface to its translations; a map of bare sentences looked up through a
   variable is invisible to it, and the ten below would quietly stay English for
   every reader in Portuguese. Wrapped in a call each, they are ten literal
   calls the check can see. This is `report.js`'s `SAID` and its reason exactly.

   EACH PAIR IS TWO ENDS AND NOT A LABEL, because "how complete? 3 out of 5"
   means nothing and "something was left out ← → nothing was missing" means
   something. The ends are what give the number its direction. */
const PAIRS = {
  completeness: {
    ask: () => txt('Was anything left out?'),
    low: () => txt('something was missing'),
    high: () => txt('nothing was missing'),
  },
  padding: {
    ask: () => txt('Does it get to the point?'),
    low: () => txt('it is padded'),
    high: () => txt('it is direct'),
  },
  interest: {
    ask: () => txt('Was it interesting?'),
    low: () => txt('it was not'),
    high: () => txt('it was'),
  },
  /* THE ONE WITH NO GOOD END. Both ends are misses, and the interface says so
     by naming them rather than by implying that five is the answer. */
  depth: {
    ask: () => txt('Was it pitched right?'),
    low: () => txt('too easy'),
    high: () => txt('too hard'),
  },
};

// What the control is asking about, in words, so the legend is a question
// somebody can answer rather than "Rate this".
const ASKED = {
  course: () => txt('What did you think of this course?'),
  track: () => txt('What did you think of this track?'),
  platform: () => txt('What do you think of this place?'),
};

/* The markup, drawn before anything is known.

   IT IS BUILT EMPTY AND FILLED BY `wireRating`, which is the opposite of
   `report.js` — that one builds nothing until somebody opens it, because almost
   nobody does. This is on the screen for everybody, so the shape has to be
   there on the first paint and the request that says whether they have already
   rated it fills it in. A control that appeared a beat late would be a control
   people have already scrolled past. */
export function ratingBlock(kind) {
  if (!api.canRate()) return '';
  return '<section class="rate" data-kind="' + esc(kind) + '" hidden>' +
    '<div class="rate-stars"></div>' +
    '<div class="rate-deeper"></div>' +
    '<p class="rate-said" role="status" hidden></p>' +
  '</section>';
}

/* Wire one block.

   `at` is `{ kind, subjectId }`. The platform sends no id, and the store
   refuses one that is sent — there is one platform and it is in no catalogue. */
export function wireRating(root, at) {
  const el = root && root.querySelector('.rate');
  if (!el || !api.canRate()) return;

  const stars = el.querySelector('.rate-stars');
  const deeper = el.querySelector('.rate-deeper');
  const said = el.querySelector('.rate-said');

  let scale = { lowest: 1, highest: 5, askDeeper: 3, aspects: Object.keys(PAIRS) };
  let mine = null;

  api.ratable().then((answer) => {
    if (!answer) return;
    scale = {
      lowest: answer.lowest || 1,
      highest: answer.highest || 5,
      askDeeper: answer.askDeeper || 0,
      /* THE SERVER'S LIST AND NOT THIS FILE'S. An aspect added there and not
         here is drawn under its own name rather than left out — a question
         nobody can answer is worse than one that reads oddly, which is the
         same judgement `report.js` makes about a reason with no sentence. */
      aspects: answer.aspects || Object.keys(PAIRS),
    };
    mine = (answer.ratings || []).find(
      (r) => r.kind === at.kind && r.subjectId === (at.subjectId || ''),
    ) || null;

    el.hidden = false;
    drawStars();
    if (mine) drawDeeper();
  });

  function drawStars() {
    const chosen = mine ? mine.stars : 0;
    let row = '';
    for (let n = scale.lowest; n <= scale.highest; n += 1) {
      const id = 'rate-' + at.kind + '-' + (at.subjectId || 'here') + '-' + n;
      row +=
        '<input type="radio" name="' + esc(at.kind + ':' + (at.subjectId || '')) + '" ' +
          'id="' + esc(id) + '" value="' + n + '"' + (n === chosen ? ' checked' : '') + '>' +
        /* THE NUMBER IN WORDS IS THE LABEL AND THE STARS ARE HIDDEN FROM IT.
           "★★★" read aloud is not a rating, and a label of three star
           characters is what a screen reader would have to say. */
        '<label for="' + esc(id) + '">' +
          '<span class="rate-glyph" aria-hidden="true">★</span>' +
          '<span class="rate-hide">' + esc(String(n)) + '</span>' +
        '</label>';
    }

    /* HOW MANY ARE LIT IS AN ATTRIBUTE AND NOT A SELECTOR.

       The obvious CSS is `input:checked ~ label`, which lights every star AFTER
       the chosen one — the wrong ones, and the usual fix is to reverse the row
       in the DOM, which then reverses the arrow keys for anybody using them.
       A number on the fieldset costs one line here and leaves the markup in the
       order a keyboard expects. */
    stars.innerHTML =
      '<fieldset class="rate-row" data-stars="' + chosen + '">' +
        '<legend>' + esc((ASKED[at.kind] || ASKED.course)()) + '</legend>' +
        row +
      '</fieldset>';

    stars.querySelectorAll('input').forEach((radio) => {
      radio.addEventListener('change', () => {
        stars.querySelector('.rate-row').dataset.stars = radio.value;
        give(Number(radio.value), null);
      });
    });
  }

  /* THE FOUR PAIRS, OR NONE OF THEM.

     Drawn only once there are stars to be under, and only at or below the
     threshold. Above it the person is thanked and left alone, which is the
     whole reason the threshold exists. */
  function drawDeeper() {
    if (!mine || mine.stars > scale.askDeeper) {
      deeper.innerHTML = '';
      return;
    }

    deeper.innerHTML =
      '<p class="rate-invite">' + esc(txt('If you have another moment — none of these are required.')) + '</p>' +
      scale.aspects.map((name) => {
        const pair = PAIRS[name];
        const at5 = (mine.aspects || {})[name] || 0;
        let row = '';
        for (let n = scale.lowest; n <= scale.highest; n += 1) {
          const id = 'pair-' + at.kind + '-' + (at.subjectId || 'here') + '-' + name + '-' + n;
          row +=
            '<input type="radio" name="' + esc('pair:' + name + ':' + (at.subjectId || '')) + '" ' +
              'id="' + esc(id) + '" value="' + n + '"' + (n === at5 ? ' checked' : '') + '>' +
            '<label for="' + esc(id) + '"><span class="rate-hide">' + esc(String(n)) + '</span></label>';
        }
        /* A PAIR THE SERVER NAMED AND THIS FILE HAS NO SENTENCE FOR is drawn
           under its own name, never left out. */
        const ask = pair ? pair.ask() : name;
        const low = pair ? pair.low() : String(scale.lowest);
        const high = pair ? pair.high() : String(scale.highest);
        return '<fieldset class="rate-pair" data-aspect="' + esc(name) + '">' +
          '<legend>' + esc(ask) + '</legend>' +
          '<span class="rate-end">' + esc(low) + '</span>' +
          '<span class="rate-dots">' + row + '</span>' +
          '<span class="rate-end">' + esc(high) + '</span>' +
        '</fieldset>';
      }).join('');

    deeper.querySelectorAll('.rate-pair input').forEach((radio) => {
      radio.addEventListener('change', () => {
        const aspects = {};
        deeper.querySelectorAll('.rate-pair').forEach((set) => {
          const picked = set.querySelector('input:checked');
          if (picked) aspects[set.dataset.aspect] = Number(picked.value);
        });
        give(mine.stars, aspects);
      });
    });
  }

  /* EVERY CHANGE POSTS, AND THERE IS NO SUBMIT BUTTON.

     A rating is one value and a button would be a second gesture to complete
     the first — which is precisely the cost this control may not have. The
     write is an upsert, so a person moving from three stars to four sends two
     ratings and has one.

     THE PAIRS ARE SENT WHOLE EVERY TIME, because the server's rule is that a
     rating carries the answers it carries: sending one of them would clear the
     other three, which is right for somebody answering the short form again and
     wrong for somebody filling the pairs in one at a time. */
  function give(starsGiven, aspects) {
    said.hidden = false;
    said.textContent = txt('saving…');

    api.rate(at.kind, at.subjectId || '', starsGiven, aspects).then((answer) => {
      if (!answer) {
        said.textContent = txt('that was not recorded — please try again');
        return;
      }
      mine = answer;
      said.textContent = answer.changed ? txt('changed, thank you') : txt('thank you');
      drawDeeper();
    }).catch(() => {
      said.textContent = txt('that was not recorded — please try again');
    });
  }
}
