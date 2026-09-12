/* ==========================================================================
   `numeric` — a quantity, and the unit it is in.

   NOT `type="number"`. A number input silently discards what it cannot parse,
   so a student who typed `1,000` or `10 ms` or `1.0.` gets an empty box and no
   idea why. Text with `inputmode="decimal"` keeps what they typed — the numeric
   keypad still comes up on a phone — and the grader gets to say what was wrong
   with it. A control that eats an answer is worse than one that passes a bad
   answer on.

   THE UNIT IS A CONTROL ONLY WHEN THERE IS A CHOICE. A question whose answer is
   in milliseconds and nothing else shows "ms" as text: a select with one option
   is a control that cannot be got wrong and still has to be operated.
   ========================================================================== */

import { esc } from '../text.js';

export default {
  types: ['numeric'],

  body(ex, uid) {
    /* ONE OPTION PER SPELLING, AND `accept_units` MAY REPEAT THE UNIT.

       `accept_units` is documented as OTHER spellings of the same unit, so it
       should not contain `unit` itself — but a list that does is easy to write
       and the reader of it is a menu. Two identical options is a choice with no
       meaning: whichever the student picks, it is the same answer.

       So this deduplicates rather than trusting the content, because the
       failure is silent and lands on the student. `validate-content` refuses
       the repetition as well, which is where an author finds out. */
    const units = [...new Set([ex.unit, ...(ex.accept_units || [])].filter(Boolean))];

    const value = '<input type="text" inputmode="decimal" class="numeric-value" '
      + 'id="' + uid + '-value" autocomplete="off" '
      + 'aria-label="' + esc(txt('Your answer')) + '" />';

    const unit = units.length > 1
      ? '<select class="numeric-unit" id="' + uid + '-unit" '
        + 'aria-label="' + esc(txt('Unit')) + '">'
        + units.map((u) => '<option value="' + esc(u) + '">' + esc(u) + '</option>').join('')
        + '</select>'
      : '<span class="numeric-unit-fixed dim">' + esc(ex.unit || '') + '</span>';

    /* The unit rides on the wrapper as data, so `collect` never has to read it
       back out of what is on screen. Display text is a thing somebody restyles,
       translates or pads, and the grader compares this string exactly. */
    return '<div class="numeric" data-unit="' + esc(ex.unit || '') + '">'
      + value + unit + '</div>';
  },

  collect(root) {
    const value = root.querySelector('.numeric-value');
    if (!value) return null;

    /* A COMMA IS A DECIMAL POINT to most of the people this school serves, and
       `Number('1,5')` is NaN. Accepting it here is not being lenient about the
       answer — it is reading the same number the student wrote. */
    const raw = value.value.trim().replace(',', '.');
    if (raw === '') return null;

    const n = Number(raw);
    const select = root.querySelector('.numeric-unit');
    /* What cannot be read as a number is still sent, as the text it is: the
       grader refuses it and says so, which is better than this file deciding
       their answer was nothing at all. */
    const box = root.querySelector('.numeric');
    return {
      value: Number.isFinite(n) ? n : raw,
      unit: select ? select.value : ((box && box.dataset.unit) || ''),
    };
  },

  /* AND THE NUMBER THAT WAS WANTED — `cloze`'s gap in the type beside it, with
     the same cause and the same fix. A student who answered 340 to a question
     wanting 300 was told "not yet" and never told what.

     THE TOLERANCE IS NOT DRAWN, and the server does not send it. "300" is the
     answer; "300 give or take 5%" is the marking rule, and a rule on the screen
     is read as the answer — which is how somebody comes away believing the
     answer was a range.

     WRITTEN WITH THE STUDENT'S OWN SEPARATOR, because `collect` already accepts
     a comma as a decimal point for most of the people this school serves. Being
     shown `9.81` after typing `9,5` would be answering in a notation the
     question did not ask for. */
  reveal(root, ex, v) {
    root.querySelectorAll('.numeric input, .numeric select').forEach((c) => { c.disabled = true; });

    const want = v && v.expected;
    if (!want || typeof want !== 'object' || want.value === undefined) return;
    if (v.correct === true) return;

    const box = root.querySelector('.numeric');
    const typed = root.querySelector('.numeric-value');
    if (!box) return;

    const comma = Boolean(typed && typed.value.includes(','));
    const shown = comma ? String(want.value).replace('.', ',') : String(want.value);

    const answer = document.createElement('span');
    answer.className = 'numeric-answer';
    answer.textContent = shown + (want.unit ? ' ' + want.unit : '');
    box.append(answer);
  },
};
