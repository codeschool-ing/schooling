/* ==========================================================================
   `cloze` — a sentence with holes in it.

   THE INPUT GOES WHERE THE HOLE IS. The prompt writes its blanks as `___`, and
   this splits on that marker so the boxes sit inside the sentence rather than
   in a list underneath it. That is the difference between reading a sentence
   and doing a crossword, and it is the whole reason this type exists instead of
   three short-answer questions.

   THE PROMPT IS DRAWN HERE AND NOT ABOVE. Every other type gets `.ex-prompt`
   from the wrapper and then draws its controls below it; for this one the
   prompt IS the control, so drawing it twice would put the sentence on screen
   once with holes and once without. `promptIsTheBody` tells the wrapper to
   leave it alone.

   Each box is labelled "Blank 1", "Blank 2" — invisible on screen and the only
   thing a screen reader has to tell one hole from another (X-05).
   ========================================================================== */

import { esc } from '../text.js';

export default {
  types: ['cloze'],

  // See the header: the wrapper must not print `.ex-prompt` as well.
  promptIsTheBody: true,

  body(ex, uid) {
    const parts = String(ex.prompt || '').split('___');
    const count = (ex.blanks || []).length;

    let html = '<p class="cloze">';
    parts.forEach((part, i) => {
      html += esc(part);
      if (i < parts.length - 1 && i < count) {
        html += '<input type="text" class="blank" data-blank="' + i + '" '
          + 'id="' + uid + '-blank-' + i + '" autocomplete="off" autocapitalize="off" '
          + 'spellcheck="false" aria-label="' + esc(txt('Blank') + ' ' + (i + 1)) + '" />';
      }
    });
    html += '</p>';
    return html;
  },

  /* ANSWERED IF ANY BOX HAS SOMETHING IN IT, and the empty ones travel as empty
     strings. The grader wants one entry per blank and refuses a list of the
     wrong length, so dropping the blanks somebody left alone would turn a
     half-finished answer into a malformed one — which is a different message
     from the one they need to read. */
  collect(root) {
    const boxes = [...root.querySelectorAll('.blank')];
    if (!boxes.length) return null;
    const filled = boxes.map((b) => b.value.trim());
    return filled.some((v) => v !== '') ? { filled } : null;
  },

  // The words that were typed, back in the boxes they were typed into.
  restore(root, ex, answer) {
    const filled = (answer && answer.filled) || [];
    [...root.querySelectorAll('.blank')].forEach((b, i) => {
      if (filled[i] !== undefined) b.value = filled[i];
    });
  },

  /* AND WHAT IT SHOULD HAVE SAID, WHICH THIS USED TO KEEP TO ITSELF.

     It disabled the boxes and stopped. A student who typed the wrong word was
     told "not yet", left looking at their own wrong word, and had no way to
     find the right one — on the one question type where the answer is a word
     rather than something they could re-read in the options.

     `reveal.go` claimed a cloze needed nothing here because its renderer
     "already has" the key. That is true of an exam paper and false everywhere a
     cloze is actually answered: a lesson and a drill are drawn from the public
     payload, which carries no `accept`. The key now arrives with the verdict,
     the same way every other type's does.

     THE WRONG WORD STAYS ON SCREEN, beside the right one and not replaced by
     it. Overwriting the box would leave somebody looking at the correct answer
     in the place they typed, with nothing to compare and a fair suspicion that
     they had typed it. What is being taught is the difference. */
  reveal(root, ex, v) {
    const want = v && Array.isArray(v.expected) ? v.expected : null;

    root.querySelectorAll('.blank').forEach((b, i) => {
      b.disabled = true;
      if (!want) return;

      const right = String(want[i] === undefined ? '' : want[i]);
      if (!right) return;

      /* Whether THIS blank was right is not on the verdict — it marks the
         answer as a whole — so it is decided here the way a person would: the
         normalisation the question declared is not on the public payload
         either, so this compares leniently and is only ever used to decide
         whether to draw the answer. The grader's verdict is what stands. */
      const said = b.value.trim();
      const same = said.localeCompare(right, undefined,
        { sensitivity: 'base', usage: 'search' }) === 0;

      b.classList.add(same ? 'blank-right' : 'blank-wrong');
      if (same) return;

      const answer = document.createElement('span');
      answer.className = 'blank-answer';
      answer.textContent = right;
      b.insertAdjacentElement('afterend', answer);
    });
  },
};
