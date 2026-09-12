/* ==========================================================================
   `matching` — pairing by clicking.

   The per-row <select> was replaced by two columns of tiles: you click one on
   the left, then one on the right. It works the same on touch and mouse and it
   does not hide the options inside a menu.

   TWO INTERACTIONS, AND WHAT CHOOSES BETWEEN THEM IS WHERE THE KEY IS.

   MAKE THEM ALL, THEN SUBMIT — wherever the question was presented by the
   server, which is every lesson, every drill and every exam. Nothing on screen
   says whether a pair is right, because nothing on screen KNOWS: the pairing is
   the answer and it stays on the server (A-09). The mapping goes up, the server
   marks it, and `reveal` puts the right-hand answer beside each wrong choice.

   CHECKED AS EACH PAIR LANDS — green and locked if right, red and undone if
   not, the Duolingo gesture — only in the offline copy, where the whole
   question including its key is baked into the page and there is nobody to keep
   it from. `setupPractice` below is that one.

   THE SECOND USED TO BE THE DEFAULT FOR EVERYTHING THAT WAS NOT AN EXAM, and it
   could not work: with no key in the browser no pair ever locked, the card never
   completed, and it hid the answer button on the way past. See `selfCompleting`.

   WHAT THE IMMEDIATE ONE BREAKS, where it still runs. The final mapping is
   ALWAYS right — you only have to keep trying — so the verdict cannot compare
   the map to the key or everyone scores 100%. The measure is how many pairs were
   wrong along the way: zero is a pass, any mistake is "not yet", with the count.

   The right-hand column stays SORTED ALPHABETICALLY in that copy. In the JSON
   the correct pair is `pairs[i].left ↔ pairs[i].right`, and presenting it in
   written order would hand over the key by position. The `rightDistractors` go
   in with it, so the last pair cannot fall out by elimination.

   ========================================================================== */

import { formatted, esc, shuffleWith } from '../text.js';

const WRONG_PAIR_PAUSE = 700;   // how long a wrong pair stays red before it lets go

export default {
  types: ['matching'],

  /* WHAT DECIDES THE INTERACTION IS WHETHER THE BROWSER HOLDS THE KEY.

     The Duolingo gesture in the header — every pair checked the instant it
     lands — can only exist where this file can say whether a pair is right.
     `setupPractice` answers that from `exercise.pairs[i].right`.

     A QUESTION PRESENTED BY THE SERVER HAS NO SUCH FIELD. The pairing IS the
     answer and is kept on the server, which is the whole of A-09. So in a
     lesson and in a drill `key[left]` was `undefined`, NO PAIR COULD EVER
     LOCK, `state.done` never reached the total — and there was no answer button
     either, because this said it finishes on its own. A matching question was
     impossible to complete anywhere except on an exam paper. Making the
     right-hand column visible (#306) did not change that: the tiles were there
     and clicking them did nothing.

     So the question is not "is this an exam", it is "is there a key here". No
     key means the exam's interaction: make every pairing, submit, and the
     server marks it. That is the only shape compatible with the key living on
     the server, and it is the one that already works.

     WHAT IT COSTS, said rather than discovered: feedback per pair is gone
     wherever the server presents the question, which is every lesson and every
     drill. It was a good teaching gesture. It cannot be had without either
     sending the key to the browser — which would hand over the answer to
     anybody reading the response — or a request per pair, which is a route and
     a failure mode per pair. The offline copy keeps it, because there the key
     is already in the page and nothing is being protected. */
  selfCompleting: (exam, ex) => !exam && holdsTheKey(ex),

  body(ex, uid, { exam } = {}) {
    const left = shuffleWith(uid + ':e', ex.pairs.map((p) => p.left));
    /* WHERE THE RIGHT-HAND COLUMN COMES FROM IS DECIDED BY `rights` EXISTING
       AND NOT BY THE MODE, and that distinction is the whole of this fix.

       When the server presents a question it sends two parallel arrays, `left`
       and `right` — the second shuffled there with the pairing removed, because
       the pairing IS the answer. `api.js` puts them where this file looks:
       `pairs[i].left` and `ex.rights`. It deliberately writes no
       `pairs[i].right`, because there is none to write.

       THIS READ `exam && …`. An exam is presented by the server, so it worked.
       A LESSON AND A DRILL ARE PRESENTED BY THE SERVER TOO and are not exams,
       so they took the other branch, mapped `p.right` over pairs that have
       none, and drew a column of empty tiles. A matching question was
       unanswerable everywhere except on a paper.

       `api.js` states the rule this file was breaking, as a fact about this
       file: "the renderer reads `ex.rights` … whatever mode it is in". That was
       a belief about the renderer nobody checked — the same shape as the two
       defects in #299 and #300, two halves each right on their own terms and
       disagreeing at the join.

       `rights` present means presented by the server. Absent means the offline
       copy, where `pairs[i].right` is there and is sorted here so that written
       order does not hand over the key by position. */
    const right = Array.isArray(ex.rights) && ex.rights.length
      ? ex.rights.slice()
      : [...ex.pairs.map((p) => p.right), ...(ex.rightDistractors || [])]
        .sort((a, b) => a.localeCompare(b, 'pt'));
    const spare = right.length - ex.pairs.length;

    /* The left tiles carry their index in the EXERCISE's order, not in the
       shuffled order on screen: an exam's answer is the mapping by pair index,
       and reading it off the DOM order would file every choice against its
       neighbour. */
    const at = new Map(ex.pairs.map((p, i) => [p.left, i]));
    /* `tile-left` AND `tile-right` SAY WHICH COLUMN, AND NOTHING ELSE.

       A correct pair is `tile-correct`. It used to be `tile-right` as well —
       `right` meaning correct and `right` meaning the right-hand side, one
       class name for two ideas — so every tile in this column was drawn in the
       styling that means "you got this one", from the moment it rendered:
       tinted blue, faded to .65, and `cursor:default`. Nothing had been
       clicked. It read as a column of options already chosen, and the one that
       is not clickable is the one that says `cursor:default`.

       The two stylesheets had each already picked a different meaning for it,
       a comment apiece, neither of them the other's. */
    const tile = (text, side) =>
      '<button type="button" class="tile tile-' + side + '" data-value="' + esc(text) + '"' +
        (side === 'left' ? ' data-pair="' + at.get(text) + '"' : '') + '>' +
        formatted(text) +
      '</button>';

    return (
      '<p class="ex-instruction">' +
        /* The undo sentence belongs to the interaction and not to the mode: a
           lesson now uses the same one an exam does, and telling a student they
           cannot undo when they can is a worse instruction than none. */
        txt(exam || !holdsTheKey(ex)
          ? 'Tap an item on the left, then its pair on the right. Tap a pair again to undo it.'
          : 'Tap an item on the left, then its pair on the right.') +
        (spare > 0 ? ' <strong>' + spare + ' ' + txt('options are left out.') + '</strong>' : '') +
      '</p>' +
      '<div class="matching-cols">' +
        '<div class="matching-col matching-col-left">' + left.map((t) => tile(t, 'left')).join('') + '</div>' +
        '<div class="matching-col matching-col-right">' + right.map((t) => tile(t, 'right')).join('') + '</div>' +
      '</div>' +
      '<p class="matching-count"><span class="assoc-done">0</span>/' + ex.pairs.length + ' ' + txt('pairs') + '</p>'
    );
  },

  setup(root, { exercise, done, exam }) {
    if (exam || !holdsTheKey(exercise)) return setupExam(root, exercise);
    return setupPractice(root, exercise, done);
  },

  collect(root, { exam, exercise } = {}) {
    if (exam || !holdsTheKey(exercise)) {
      /* The mapping, BY INDEX of the left-hand pair — which is what the server
         grades against, because the left texts live in the public half and the
         grading does not read it. The order here is the exercise's own and not
         the shuffled order on screen: `data-pair` carries it. */
      const chosen = new Array(root.querySelectorAll('.tile-left').length).fill('');
      root.querySelectorAll('.tile-left[data-with]').forEach((f) => {
        chosen[Number(f.dataset.pair)] = f.dataset.with;
      });
      return chosen.some(Boolean) ? chosen : null;
    }
    /* The immediate-feedback interaction, which is the offline copy only. The
       wrapper calls this only if the student hits the button before closing
       every pair — that answer is partial, and partial is not a pass. */
    const done = Number(root.querySelector('.assoc-done').textContent);
    return done > 0 ? { map: {}, errors: -1, partial: true } : null;
  },

  reveal(root, ex, v) {
    root.querySelectorAll('.tile').forEach((f) => { f.disabled = true; });

    /* An exam reveals the PAIRING, because until now nobody has seen it: no
       pair was ever checked on screen, so this is the first time the student
       learns which of them were right. Practice reveals the PATH instead —
       there every pair was checked as it landed, and what was not visible is
       how many were tried and refused. */
    if (v && Array.isArray(v.expected)) {
      root.querySelectorAll('.tile-left').forEach((f) => {
        const want = v.expected[Number(f.dataset.pair)];
        const got = f.dataset.with || '';
        f.classList.add(got === want ? 'tile-correct' : 'tile-wrong');
        /* THE WRONG PAIR STAYS AND THE RIGHT ONE IS ADDED, rather than the
           second overwriting the first.

           `.tile-chosen` already said `→ <what I picked>` while the student was
           working, and revealing replaced that text in place with `→ <what was
           right>`. The shape is identical, so nothing on screen said a
           substitution had happened: it was reported as an answer that was
           marked wrong while apparently showing the answer given. The right
           text was there the whole time and could not be recognised as the
           right text.

           So what they chose stays, struck through, and the answer arrives
           beside it under a word. Same decision as `cloze`, for the same
           reason: what is being taught is the difference between the two, and a
           difference needs both of its halves on screen. */
        const mark = f.querySelector('.tile-chosen');
        if (mark && got !== want) {
          mark.classList.add('tile-missed');
          const answer = document.createElement('span');
          answer.className = 'tile-chosen tile-answer';
          answer.textContent = txt('answer') + ': ' + want;
          mark.insertAdjacentElement('afterend', answer);
        }
      });
      return;
    }

    if (v && v.errors > 0) {
      const p = document.createElement('p');
      p.className = 'matching-errors';
      p.textContent = v.errors === 1
        ? txt('1 pair was tried wrong before it closed.')
        : v.errors + ' ' + txt('pairs were tried wrong before closing.');
      root.appendChild(p);
    }
  },
};

/* Whether THIS COPY of the question can mark a pair itself.

   `pairs[i].right` is the answer. The offline bundle carries it, because there
   the whole question is baked into the page and there is nobody to protect it
   from; a question presented by the server never does, because the pairing is
   what is being asked. One field, asked of the payload rather than of the mode,
   because the mode was never what it depended on. */
function holdsTheKey(ex) {
  return Boolean(ex) && Array.isArray(ex.pairs) && ex.pairs.some((p) => p.right !== undefined);
}

/* ---------- practice: every pair is checked as it lands ---------- */
function setupPractice(root, exercise, done) {
  const key = {};
  exercise.pairs.forEach((p) => { key[p.left] = p.right; });

  const state = { left: null, errors: 0, done: 0, map: {}, locked: false };
  const total = exercise.pairs.length;

  const clear = () => {
    root.querySelectorAll('.tile.sel').forEach((f) => f.classList.remove('sel'));
    state.left = null;
  };

  root.addEventListener('click', (e) => {
    const f = e.target.closest('.tile');
    if (!f || f.disabled || state.locked) return;

    if (f.classList.contains('tile-left')) {
      clear();
      f.classList.add('sel');
      state.left = f;
      return;
    }

    // clicked on the right without picking a left one: nothing to pair yet
    if (!state.left) { f.classList.add('shaking'); setTimeout(() => f.classList.remove('shaking'), 300); return; }

    const leftValue = state.left.dataset.value;
    const rightValue = f.dataset.value;
    state.map[leftValue] = rightValue;

    if (key[leftValue] === rightValue) {
      [state.left, f].forEach((el) => {
        el.classList.remove('sel');
        el.classList.add('tile-correct');
        el.disabled = true;
      });
      state.left = null;
      state.done += 1;
      root.querySelector('.assoc-done').textContent = state.done;
      if (state.done === total) {
        state.locked = true;
        done({ map: state.map, errors: state.errors });
      }
      return;
    }

    // wrong: mark both, count it, and let go after a moment
    state.errors += 1;
    const pair = [state.left, f];
    pair.forEach((el) => el.classList.add('tile-wrong'));
    state.locked = true;
    setTimeout(() => {
      pair.forEach((el) => el.classList.remove('tile-wrong', 'sel'));
      state.left = null;
      state.locked = false;
    }, WRONG_PAIR_PAUSE);
  });
}

/* ---------- an exam: nothing is checked until the exam closes ----------

   THIS IS NOT THE SAME EXERCISE WITH THE COLOURS TURNED OFF. With immediate
   feedback the final mapping is always right and the measure has to be the
   PATH — how many pairs were tried and refused. Here there is no path: a pair
   lands where the student put it and stays there, so the mapping IS the answer,
   which is how the server grades one.

   That changes the gesture too. Practice never needs an undo, because a wrong
   pair undoes itself; here it is the only way to change your mind, and without
   it a mis-tap would be a lost mark. Tapping a paired tile — either side —
   breaks the pair. */
function setupExam(root, exercise) {
  const state = { left: null };
  const total = exercise.pairs.length;

  const count = () => {
    const n = root.querySelectorAll('.tile-left[data-with]').length;
    root.querySelector('.assoc-done').textContent = n;
    return n;
  };

  const unpair = (leftTile) => {
    const rightValue = leftTile.dataset.with;
    delete leftTile.dataset.with;
    leftTile.classList.remove('tile-paired');
    const mark = leftTile.querySelector('.tile-chosen');
    if (mark) mark.remove();
    root.querySelectorAll('.tile-right').forEach((f) => {
      if (f.dataset.value === rightValue) {
        f.classList.remove('tile-taken');
        f.disabled = false;
      }
    });
  };

  root.addEventListener('click', (e) => {
    const f = e.target.closest('.tile');
    if (!f) return;

    if (f.classList.contains('tile-left')) {
      // A paired tile is a request to undo it, not to start a new pair.
      if (f.dataset.with) { unpair(f); count(); return; }
      root.querySelectorAll('.tile.sel').forEach((t) => t.classList.remove('sel'));
      f.classList.add('sel');
      state.left = f;
      return;
    }

    // The right-hand side, taken: the pair it belongs to comes undone.
    if (f.classList.contains('tile-taken')) {
      const owner = [...root.querySelectorAll('.tile-left[data-with]')]
        .find((t) => t.dataset.with === f.dataset.value);
      if (owner) { unpair(owner); count(); }
      return;
    }

    if (!state.left) { f.classList.add('shaking'); setTimeout(() => f.classList.remove('shaking'), 300); return; }

    // Re-pairing a left tile that already had one: the old right comes free.
    if (state.left.dataset.with) unpair(state.left);

    state.left.dataset.with = f.dataset.value;
    state.left.classList.remove('sel');
    state.left.classList.add('tile-paired');
    const mark = document.createElement('span');
    mark.className = 'tile-chosen';
    mark.textContent = f.textContent.trim();
    state.left.appendChild(mark);

    f.classList.add('tile-taken');
    state.left = null;

    const n = count();
    /* Nothing closes at the end. The button is there from the start — it is not
       a self-completing exercise in an exam — and the count is what says how
       much is left, which is the only feedback there is. */
    void n;
    void total;
  });
}
