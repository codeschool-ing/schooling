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

/* `labelling` — putting names on the parts of a picture.

   # WHY IT IS NOT DRAG AND DROP

   The same argument as `ordering`, and it lands harder here. Dragging is what
   everybody builds for this question and it is operable by exactly one kind of
   person: it needs a pointer, a steady hand, and sight of where the pointer is.
   An exam that cannot be sat with a keyboard cannot be sat by everybody.

   So a label is CHOSEN and then PLACED — two steps that each work by any means.
   Choosing is a radio button. Placing is a click on the picture, or the arrow
   keys, and both do the same thing to the same number.

   # THE POSITION IS A FRACTION, AND IT IS ALSO SAID IN WORDS

   The grader compares fractions of the image and never pixels, because the same
   question is answered on a phone and on a monitor. So the interface has a
   number to show, and it shows it: "63% across, 41% down", inside the radio
   button's own label. That is what makes this legible to somebody who cannot
   see the picture — they can be told where they have put a thing, and move it.

   It is not a substitute for seeing the diagram and nothing here pretends it
   is. It is the difference between a question that is hard and one that is
   impossible.

   # THE PICTURE'S ADDRESS COMES FROM THE CALLER

   `shown.image` is a bare file name; where it lives is the course's business,
   which this file does not know and should not. Without a resolver there is no
   picture, and the question says so rather than drawing a frame around
   nothing. */
function labelling(shown, name, given, pictures) {
  const labels = shown.labels || [];
  const src = pictures && shown.image ? pictures(shown.image) : '';
  if (!src) return unsupported(shown, 'labelling');

  /* Where each label is, as fractions, or null for one not placed yet. An
     unplaced label is not a label at (0, 0): the corner is somewhere a student
     could mean. */
  const at = labels.map((_, i) => {
    const placed = given && Array.isArray(given.placed) ? given.placed[i] : null;
    return placed && Number.isFinite(placed.x) && Number.isFinite(placed.y)
      ? { x: placed.x, y: placed.y } : null;
  });

  const percent = (v) => `${Math.round(v * 100)}%`;
  const said = (i) => (at[i]
    ? `${labels[i].text} — ${percent(at[i].x)} ${txt('across')}, ${percent(at[i].y)} ${txt('down')}`
    : `${labels[i].text} — ${txt('not placed yet')}`);

  const picture = el('img', {
    src, alt: shown.prompt, class: 'labelling-picture', draggable: 'false',
  });

  const markers = labels.map((_, i) => el('span', {
    class: 'labelling-marker', 'aria-hidden': 'true', hidden: true,
  }, [el('span', { text: String(i + 1) })]));

  const board = el('div', { class: 'labelling-board' }, [picture, ...markers]);

  const radios = [];
  const words = [];

  const refresh = () => labels.forEach((_, i) => {
    words[i].textContent = said(i);
    markers[i].hidden = !at[i];
    if (at[i]) {
      markers[i].style.left = percent(at[i].x);
      markers[i].style.top = percent(at[i].y);
    }
  });

  /* `change` is dispatched by hand because nothing here is a form control being
     edited. The exam screen listens for it to save the answer, and a placement
     that stayed silent is one the server never hears about — which is exactly
     the defect the ordering buttons had. */
  const place = (i, x, y) => {
    at[i] = { x: Math.min(1, Math.max(0, x)), y: Math.min(1, Math.max(0, y)) };
    refresh();
    board.dispatchEvent(new Event('change', { bubbles: true }));
  };

  /* THE BOX IS MEASURED AT THE MOMENT OF THE CLICK rather than kept. The
     picture is responsive, and a width remembered from before a window resize
     puts the label somewhere nobody pointed at. */
  picture.addEventListener('click', (event) => {
    const i = radios.findIndex((r) => r.checked);
    if (i < 0) return;
    const box = picture.getBoundingClientRect();
    if (!box.width || !box.height) return;
    place(i, (event.clientX - box.left) / box.width, (event.clientY - box.top) / box.height);
  });

  const list = el('div', { class: 'labelling-labels' }, labels.map((label, i) => {
    const radio = el('input', {
      type: 'radio', name: `${name}-label`, id: `${name}-label-${i}`, value: String(i),
    });
    radios.push(radio);

    const spoken = el('span', { text: said(i) });
    words.push(spoken);

    /* THE ARROW KEYS ARE HANDLED ON THE RADIO, not on the picture. The picture
       is not focusable — making it so would put a control in the tab order that
       a screen reader has nothing to say about — and the label the student has
       just chosen is the thing their keyboard should be driving.

       A step is a hundredth of the picture, or a twentieth with shift. The fine
       one is what makes a small region reachable; the coarse one is what stops
       crossing a diagram taking ninety presses. */
    radio.addEventListener('keydown', (event) => {
      const step = event.shiftKey ? 0.05 : 0.01;
      const from = at[i] || { x: 0.5, y: 0.5 };
      let { x, y } = from;

      switch (event.key) {
        case 'ArrowLeft': x -= step; break;
        case 'ArrowRight': x += step; break;
        case 'ArrowUp': y -= step; break;
        case 'ArrowDown': y += step; break;
        default: return;
      }
      /* A radio group's own arrow-key behaviour is to move to the next radio,
         which would change which label is being placed on every press. */
      event.preventDefault();
      radio.checked = true;
      place(i, x, y);
    });

    return el('label', { class: 'option labelling-label', for: radio.id }, [
      radio,
      el('span', { class: 'labelling-number', 'aria-hidden': 'true', text: String(i + 1) }),
      spoken,
    ]);
  }));

  refresh();

  return {
    node: group(shown.prompt, [
      board,
      el('p', {
        class: 'dim',
        text: txt('Choose a label, then click the picture or use the arrow keys.'),
      }),
      list,
    ]),
    /* EVERY LABEL OR NONE. The grader compares the list position by position, so
       a partly-placed answer has no meaning to it — and sending one would record
       an answer the student had not finished making. */
    read: () => (at.every(Boolean) ? { placed: at.map((p) => ({ x: p.x, y: p.y })) } : null),
  };
}

/* A type this interface cannot draw, saying so rather than rendering something
   that cannot work.

   It is also what `labelling` falls back to when nothing told it where the
   pictures live. A frame around an image that never loads is a question a
   student cannot answer however well they know the material — the exact failure
   the content checks exist to prevent, and producing it here would be the same
   defect one layer up. */
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
  'labelling': labelling,
  'matching': matching,
  'cloze': cloze,
  'numeric': numeric,
};

/* Build the controls for one question.
 *
 * `name` groups the radio buttons and ties every label to its input, so it has
 * to be unique on the page — the attempt and the position make it so.
 *
 * `pictures` turns a file name into an address, and only `labelling` uses it.
 * It is a function passed in rather than a base path built here, because where
 * a course's images live is the caller's business — and in the offline bundle
 * the answer is a data URI rather than a path at all.
 *
 * `given` IS THE ANSWER THE STUDENT ALREADY MADE, and putting it back is not a
 * nicety. Answers are saved as they are made, so the server has them; a paper
 * reopened after a reload that came back blank would tell somebody their work
 * was gone when it was not. They would then do it again, on a clock, in an
 * exam. It arrives in the frame they were shown, which is the frame these
 * controls are in, so the indices go straight back where they came from.
 */
export function build(type, shown, name, given, pictures) {
  const make = renderers[type];
  if (!make) return unsupported(shown, type);
  return make(shown, name, given, pictures);
}

/* Whether this type can be answered at all. The exam screen asks so it can say
   how many questions on the paper it cannot show, once and at the top, rather
   than leaving somebody to discover it at question fourteen. */
export function answerable(type) { return Boolean(renderers[type]); }
