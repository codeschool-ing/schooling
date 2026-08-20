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

  reveal(root) {
    root.querySelectorAll('.blank').forEach((b) => { b.disabled = true; });
  },
};
