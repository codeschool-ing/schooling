/* ==========================================================================
   Schooling — a question, as a student answers it

   WHAT ARRIVES HERE HAS NO ANSWER IN IT. The server presents a question rather
   than sending it: the key removed, and where the order IS the answer,
   shuffled. So everything below builds controls over `shown`, and what it reads
   back is expressed in the frame the student saw — the server maps it back
   through the permutation it kept. Nothing in this file knows or could know
   which choice is right.

   # KEYBOARD FIRST, AND THAT IS WHY THESE CONTROLS AND NOT OTHERS

   An exam that cannot be sat with a keyboard cannot be sat by everybody, and
   for two of these types the obvious interaction is the inaccessible one.

   `ordering` is the case: dragging is what everybody builds and it is operable
   by exactly one kind of person. Two buttons per row — move up, move down — are
   operable by everyone, announce themselves, and are less code. `matching` is
   the same argument: a select per left-hand item is a native control that a
   screen reader already knows how to read, where a drag from a list to another
   list is a widget somebody has to reimplement badly.

   Neither is a compromise. They are what these questions should have been.

   # EVERY CONTROL IS LABELLED, AND THE LABEL IS THE QUESTION

   A radio group with no `fieldset` is a set of buttons a screen reader reads
   without ever saying what is being asked. Every type here wraps its controls
   in one, with the prompt as its legend.
   ========================================================================== */

import { txt } from './i18n.js';

function el(tag, props = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (value === undefined || value === null || value === false) continue;
    if (key === 'class') node.className = value;
    else if (key === 'text') node.textContent = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
    else if (value === true) node.setAttribute(key, '');
    else node.setAttribute(key, value);
  }
  for (const child of [].concat(children)) {
    if (child === null || child === undefined || child === false) continue;
    node.append(child);
  }
  return node;
}

/* A group with its question as the legend, which is what makes the controls
   inside it mean something when they are read out one at a time.

   THE PROMPT IS THE LEGEND AND NOT A HEADING BESIDE IT. A heading and a legend
   saying the same sentence is that sentence read out twice, and the second time
   carries no information at all.

   `cloze` is the exception and passes `spoken: false`: its prompt IS the
   sentence with the blanks in it, which is rendered below with an input at each
   hole. Showing the legend as well would print the question twice, once with
   `___` and once with boxes. */
function group(prompt, children, { spoken = true } = {}) {
  return el('fieldset', { class: 'question-body' }, [
    el('legend', { class: spoken ? 'question-prompt' : 'visually-hidden', text: prompt }),
    ...[].concat(children),
  ]);
}

/* ---------- one per type ----------

   Each answers { node, read }. `read` gives the answer as JSON in the frame the
   student was shown, or null when they have not answered — and those are
   different things: an unanswered question is not the same as an empty one, and
   only the second is worth sending. */

function choice(shown, single, name, given) {
  const inputs = [];

  const options = (shown.choices || []).map((option, i) => {
    const input = el('input', {
      type: single ? 'radio' : 'checkbox',
      name, id: `${name}-${i}`, value: String(i),
      checked: Boolean(given && (given.chose || []).includes(i)),
    });
    inputs.push(input);
    return el('label', { class: 'option' }, [input, el('span', { text: option.text })]);
  });

  return {
    node: group(shown.prompt, options),
    read: () => {
      const chose = inputs.map((input, i) => (input.checked ? i : -1)).filter((i) => i >= 0);
      /* Nothing chosen is not an answer to send. Choosing nothing deliberately
         is a real thing a student can mean — but it is indistinguishable from
         not having got there yet, and the exam marks an unanswered question
         wrong either way. */
      return chose.length ? { chose } : null;
    },
  };
}

function ordering(shown, name, given) {
  let items = (shown.items || []).map((text, i) => ({ text, at: i }));

  /* The arrangement they had, put back. `order` is the shown positions in the
     order the student left them, which is exactly what this list is. */
  if (given && Array.isArray(given.order) && given.order.length === items.length) {
    const byPosition = given.order.map((at) => items[at]);
    if (byPosition.every(Boolean)) items = byPosition;
  }

  const list = el('ol', { class: 'ordering' });

  /* A BUTTON DOES NOT FIRE `change`, AND THIS ONE HAS TO.
     Every other type here is native controls, so the exam screen listens for a
     bubbling `change` and saves the answer. Ordering is buttons, which fire
     `click` and nothing else — so it announced no change, saved nothing as it
     went, and an arrangement made over five minutes lived only in this closure
     until the paper was handed in. Found by moving one and watching the
     "Saved" that never appeared. */
  const moved = () => list.dispatchEvent(new Event('change', { bubbles: true }));

  /* The arrangement lives in `items` and the list is redrawn from it, rather
     than the DOM being the state. Reading an order out of the DOM is where an
     off-by-one lives, and here it would mark a correct answer wrong. */
  function draw(focusIndex) {
    list.textContent = '';
    items.forEach((item, i) => {
      const up = el('button', {
        type: 'button', class: 'icon-button', 'aria-label': `${txt('Move up')}: ${item.text}`,
        disabled: i === 0,
        onclick: () => { [items[i - 1], items[i]] = [items[i], items[i - 1]]; draw(i - 1); moved(); },
      }, ['↑']);
      const down = el('button', {
        type: 'button', class: 'icon-button', 'aria-label': `${txt('Move down')}: ${item.text}`,
        disabled: i === items.length - 1,
        onclick: () => { [items[i + 1], items[i]] = [items[i], items[i + 1]]; draw(i + 1); moved(); },
      }, ['↓']);

      list.append(el('li', {}, [
        el('span', { class: 'ordering-text', text: item.text }),
        el('span', { class: 'ordering-buttons' }, [up, down]),
      ]));
    });

    /* Focus follows the item that moved. Without this, moving something twice
       means finding its buttons again after every press — which with a keyboard
       is several tabs, and with a screen reader is losing your place. */
    if (focusIndex !== undefined) {
      const row = list.children[focusIndex];
      const button = row && row.querySelector('button:not([disabled])');
      if (button) button.focus();
    }
  }
  draw();

  return {
    node: group(shown.prompt, [
      el('p', { class: 'dim', text: txt('Put these in order, using the arrows.') }),
      list,
    ]),
    /* The shown positions, in the order the student arranged them. The server
       maps each one back through the permutation it kept. */
    read: () => ({ order: items.map((item) => item.at) }),
  };
}

function matching(shown, name, given) {
  const left = shown.left || [];
  const right = shown.right || [];
  const selects = [];
  const had = (given && given.matched) || [];

  const rows = left.map((text, i) => {
    const select = el('select', { id: `${name}-${i}` }, [
      el('option', { value: '', text: `— ${txt('choose')} —` }),
      ...right.map((option, j) => el('option', { value: String(j), text: option })),
    ]);
    if (had[i] !== undefined) select.value = String(had[i]);
    selects.push(select);

    return el('div', { class: 'matching-row' }, [
      el('label', { for: `${name}-${i}`, text }),
      select,
    ]);
  });

  return {
    node: group(shown.prompt, rows),
    read: () => {
      /* Every left item needs one. The answer is a whole assignment — one
         right-hand index per left-hand item — and there is no way to express
         "not yet" in it, so a half-filled question sends nothing.

         THE COST IS REAL AND IT IS WORTH NAMING: a student who matches two of
         three and reloads loses those two, where every other type here comes
         back as they left it. Fixing it means a shape the answer can be
         partially written in, which is a change to what the server stores and
         to what the grader reads — not something to smuggle into a screen. */
      if (selects.some((s) => s.value === '')) return null;
      return { matched: selects.map((s) => Number(s.value)) };
    },
  };
}

function cloze(shown, name, given) {
  /* The blanks are `___` in the prompt, and the payload says how many there
     are. Splitting on the marker is what puts an input where the sentence has a
     hole, rather than in a list underneath it — which is the difference between
     reading a sentence and doing a crossword. */
  const parts = String(shown.prompt || '').split('___');
  const count = (shown.blanks || []).length;
  const inputs = [];

  const sentence = el('p', { class: 'cloze' });
  parts.forEach((part, i) => {
    sentence.append(document.createTextNode(part));
    if (i < parts.length - 1 && i < count) {
      const input = el('input', {
        type: 'text', class: 'blank', id: `${name}-${i}`,
        autocomplete: 'off', autocapitalize: 'off', spellcheck: 'false',
        'aria-label': `${txt('Blank')} ${i + 1}`,
        value: (given && (given.filled || [])[i]) || '',
      });
      inputs.push(input);
      sentence.append(input);
    }
  });

  return {
    node: group(shown.prompt, sentence, { spoken: false }),
    read: () => {
      const filled = inputs.map((input) => input.value.trim());
      return filled.some((v) => v !== '') ? { filled } : null;
    },
  };
}

function numeric(shown, name, given) {
  /* `inputmode` rather than `type="number"`: a number input silently discards
     what it cannot parse, so a student who typed something slightly wrong gets
     an empty box and no idea why. Text plus a numeric keypad keeps what they
     typed and lets the grader say so. */
  const value = el('input', {
    type: 'text', inputmode: 'decimal', id: `${name}-value`,
    autocomplete: 'off', 'aria-label': txt('Your answer'),
    value: given && given.value !== undefined ? String(given.value) : '',
  });

  const units = [shown.unit, ...(shown.accept_units || [])].filter(Boolean);
  const unit = units.length > 1
    ? el('select', { id: `${name}-unit`, 'aria-label': txt('Unit') },
      units.map((u) => el('option', { value: u, text: u })))
    : el('span', { class: 'dim mono', text: shown.unit || '' });
  if (given && given.unit && unit.tagName === 'SELECT') unit.value = given.unit;

  return {
    node: group(shown.prompt, el('div', { class: 'numeric' }, [value, unit])),
    read: () => {
      const raw = value.value.trim().replace(',', '.');
      if (raw === '') return null;
      const n = Number(raw);
      /* What cannot be read as a number is still sent, as the text it is: the
         grader refuses it and the student is told, which is better than this
         file deciding their answer was nothing. */
      return {
        value: Number.isFinite(n) ? n : raw,
        unit: unit.value !== undefined ? unit.value : (shown.unit || ''),
      };
    },
  };
}

/* `labelling` is not answerable here yet, and it says so rather than rendering
   something that cannot work.

   THE REASON IS THE IMAGE. A labelling question names one, and there is nowhere
   for a content image to be served from — no asset path in the catalogue, none
   in the mirror, none in this binary. A canvas over an image that never loads
   is a question a student cannot answer however well they know the material,
   which is the exact failure the content checks exist to prevent; producing it
   in the interface instead would be the same defect one layer up. */
function unsupported(shown, type) {
  return {
    node: group(shown.prompt, [
      el('p', { text: shown.prompt }),
      el('p', {
        class: 'notice bad',
        text: `${txt('This kind of question cannot be answered here yet.')} (${type})`,
      }),
    ]),
    read: () => null,
  };
}

const renderers = {
  'quiz': (shown, name, given) => choice(shown, true, name, given),
  'multiple-choice': (shown, name, given) => choice(shown, false, name, given),
  'ordering': ordering,
  'matching': matching,
  'cloze': cloze,
  'numeric': numeric,
};

/* Build the controls for one question.
 *
 * `name` groups the radio buttons and ties every label to its input, so it has
 * to be unique on the page — the attempt and the position make it so.
 *
 * `given` IS THE ANSWER THE STUDENT ALREADY MADE, and putting it back is not a
 * nicety. Answers are saved as they are made, so the server has them; a paper
 * reopened after a reload that came back blank would tell somebody their work
 * was gone when it was not. They would then do it again, on a clock, in an
 * exam. It arrives in the frame they were shown, which is the frame these
 * controls are in, so the indices go straight back where they came from.
 */
export function build(type, shown, name, given) {
  const make = renderers[type];
  if (!make) return unsupported(shown, type);
  return make(shown, name, given);
}

/* Whether this type can be answered at all. The exam screen asks so it can say
   how many questions on the paper it cannot show, once and at the top, rather
   than leaving somebody to discover it at question fourteen. */
export function answerable(type) { return Boolean(renderers[type]); }
