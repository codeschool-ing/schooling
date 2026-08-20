/* ==========================================================================
   `labelling` — putting names on the parts of a picture.

   # WHY IT IS NOT DRAG AND DROP

   The same argument as `ordering`, and it lands harder here. Dragging is what
   everybody builds for this question and it is operable by exactly one kind of
   person: it needs a pointer, a steady hand, and sight of where the pointer is.
   An exam that cannot be sat with a keyboard cannot be sat by everybody (X-05,
   X-06).

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

   # THE PICTURE'S ADDRESS COMES FROM THE ADAPTER

   `ex.image` is a bare file name; where it lives is the course's business, and
   `api.asset` is the one place that knows — over HTTP it is a path, and in a
   bundle opened off a disk it is a data URI baked into the page. Without an
   address there is no picture, and the question says so rather than drawing a
   frame around nothing.
   ========================================================================== */

import { esc } from '../text.js';
import * as api from '../api.js';

const percent = (v) => Math.round(v * 100) + '%';

/* Where each label is, kept on the element rather than in a closure: the
   wrapper builds the body as HTML and wires it in `setup`, so there is no scope
   the two halves share except the DOM. */
const positions = (root) => {
  const board = root.querySelector('.labelling-board');
  if (!board) return null;
  if (!board._at) board._at = JSON.parse(board.dataset.at || '[]');
  return board._at;
};

function said(root, i) {
  const at = positions(root);
  const text = root.querySelector('.labelling-label[data-ix="' + i + '"]').dataset.text;
  return at[i]
    ? text + ' — ' + percent(at[i].x) + ' ' + txt('across') + ', '
      + percent(at[i].y) + ' ' + txt('down')
    : text + ' — ' + txt('not placed yet');
}

function refresh(root) {
  const at = positions(root);
  at.forEach((where, i) => {
    root.querySelector('.labelling-said[data-ix="' + i + '"]').textContent = said(root, i);
    const marker = root.querySelector('.labelling-marker[data-ix="' + i + '"]');
    marker.hidden = !where;
    if (where) {
      marker.style.left = percent(where.x);
      marker.style.top = percent(where.y);
    }
  });
}

/* `change` is dispatched by hand because nothing here is a form control being
   edited. The wrapper listens for it to know the question has been answered,
   and a placement that stayed silent is one nobody ever hears about — which is
   exactly the defect the ordering buttons had. */
function place(root, i, x, y) {
  const at = positions(root);
  at[i] = { x: Math.min(1, Math.max(0, x)), y: Math.min(1, Math.max(0, y)) };
  refresh(root);
  root.querySelector('.labelling-board')
    .dispatchEvent(new Event('change', { bubbles: true }));
}

export default {
  types: ['labelling'],

  body(ex, uid) {
    const labels = ex.labels || [];
    const src = api.asset(ex.course, ex.image);
    if (!src) {
      return '<p class="ex-error">' + esc(txt('This question needs a picture that is not here.'))
        + '</p>';
    }

    const markers = labels.map((_, i) =>
      '<span class="labelling-marker" data-ix="' + i + '" aria-hidden="true" hidden>'
        + '<span>' + (i + 1) + '</span></span>').join('');

    const board = '<div class="labelling-board" data-at="[]">'
      + '<img src="' + esc(src) + '" alt="' + esc(ex.prompt || '') + '" '
      + 'class="labelling-picture" draggable="false" />'
      + markers + '</div>';

    const list = labels.map((label, i) =>
      '<label class="option labelling-label" data-ix="' + i + '" '
        + 'data-text="' + esc(label.text) + '" for="' + uid + '-label-' + i + '">'
        + '<input type="radio" name="' + uid + '-label" id="' + uid + '-label-' + i + '" '
        + 'value="' + i + '" />'
        + '<span class="labelling-number" aria-hidden="true">' + (i + 1) + '</span>'
        + '<span class="labelling-said" data-ix="' + i + '">'
        + esc(label.text) + ' — ' + esc(txt('not placed yet')) + '</span>'
      + '</label>').join('');

    return board
      + '<p class="dim labelling-how">'
      + esc(txt('Choose a label, then click the picture or use the arrow keys.')) + '</p>'
      + '<div class="labelling-labels">' + list + '</div>';
  },

  setup(root) {
    const picture = root.querySelector('.labelling-picture');
    if (!picture) return;   // no address, so the notice above is all there is

    const board = root.querySelector('.labelling-board');
    board._at = (root.querySelectorAll('.labelling-label').length
      ? new Array(root.querySelectorAll('.labelling-label').length).fill(null)
      : []);

    /* THE BOX IS MEASURED AT THE MOMENT OF THE CLICK rather than kept. The
       picture is responsive, and a width remembered from before a window resize
       puts the label somewhere nobody pointed at. */
    picture.addEventListener('click', (event) => {
      const chosen = root.querySelector('.labelling-labels input:checked');
      if (!chosen) return;
      const box = picture.getBoundingClientRect();
      if (!box.width || !box.height) return;
      place(root, Number(chosen.value),
        (event.clientX - box.left) / box.width, (event.clientY - box.top) / box.height);
    });

    root.querySelectorAll('.labelling-labels input').forEach((radio) => {
      /* THE ARROW KEYS ARE HANDLED ON THE RADIO, not on the picture. The picture
         is not focusable — making it so would put a control in the tab order
         that a screen reader has nothing to say about — and the label the
         student has just chosen is the thing their keyboard should be driving.

         A step is a hundredth of the picture, or a twentieth with shift. The
         fine one is what makes a small region reachable; the coarse one is what
         stops crossing a diagram taking ninety presses. */
      radio.addEventListener('keydown', (event) => {
        const i = Number(radio.value);
        const step = event.shiftKey ? 0.05 : 0.01;
        const from = positions(root)[i] || { x: 0.5, y: 0.5 };
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
        place(root, i, x, y);
      });
    });

    refresh(root);
  },

  /* EVERY LABEL OR NONE. The grader compares the list position by position, so
     a partly-placed answer has no meaning to it — and sending one would record
     an answer the student had not finished making. */
  collect(root) {
    const at = positions(root);
    if (!at || !at.length || !at.every(Boolean)) return null;
    return { placed: at.map((p) => ({ x: p.x, y: p.y })) };
  },

  reveal(root) {
    root.querySelectorAll('.labelling-labels input').forEach((r) => { r.disabled = true; });
  },
};
