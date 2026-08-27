/* ==========================================================================
   Schools — one colour each, and what that colour becomes.

   A SCHOOL'S ACCENT IS THE WHOLE OF THE VISUAL DIFFERENCE BETWEEN SCHOOLS. It
   has been a column since the first migration and was set by hand, in SQL,
   against production. This is the screen that ends that.

   # IT SHOWS WHAT WILL HAPPEN, NOT WHAT WAS TYPED

   The colour that is stored is a HUE, not six digits that reach a page: the
   study interface measures it against every surface accent-coloured text lands
   on and moves it along its own lightness until it can be read, once per theme.
   So the swatch a person picks and the swatch a student sees are not the same
   colour, and a screen that showed only the first would be asking somebody to
   choose blind.

   It runs the real correction — `assets/accent.js`, the study interface's own
   module, served to this host because the algorithm may not exist twice — and
   draws both themes as they will be.

   # AND IT SAYS WHERE THE COLOUR RUNS OUT

   Two things are worth knowing before saving and invisible afterwards: a colour
   that had to move (the school gets a relative of what was chosen), and one
   where the two states — a course you finished and one you can open — come out
   the same, because nothing on that hue is both readable and quieter. Neither
   is a refusal. Both are said.

   # NOTHING HERE DECIDES WHAT IS ALLOWED

   The save is hidden from a read-only role because a control that always fails
   is a bad screen. The API refuses, and there is a test for that.

   # AND WHAT IT COSTS IS NOT HERE ANY MORE

   There was a price form under every school's colour, because `school_prices`
   was keyed by school. `0041` moved the price to the platform — one
   subscription opens every school (N-02), so two schools priced differently
   let somebody buy through the cheaper page and open both — and the form went
   with it, to `plan.js`. Left here it would have been a control that changes
   what everybody pays from a screen about one school.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, put, RequestError } from '../request.js';
import { mayAct } from '../session.js';
import { correctionFor } from '/assets/accent.js';

/* Twenty to start from, spread around the wheel and named so that two people
   can talk about one.

   THEY ARE A SUGGESTION AND NOT A LIST OF WHAT IS ALLOWED. The field beside
   them takes any colour; these exist because "pick a hue" is a worse question
   than "pick one of these, or type your own", and because a school chosen from
   a spread is less likely to land next to the school beside it in the rail. */
const SUGGESTED = [
  ['Cobalt', '#2f6bff'], ['Sky', '#0ea5e9'], ['Cyan', '#06b6d4'], ['Teal', '#0d9488'],
  ['Spring', '#00a878'], ['Emerald', '#10a06a'], ['Grass', '#3f9a2f'], ['Lime', '#7cb305'],
  ['Olive', '#8a9a2b'], ['Amber', '#d99000'], ['Tangerine', '#e07a1f'], ['Copper', '#c2571a'],
  ['Vermilion', '#e04a2f'], ['Crimson', '#d92b4b'], ['Rose', '#e0407f'], ['Fuchsia', '#c026d3'],
  ['Violet', '#8b5cf6'], ['Indigo', '#5b5bd6'], ['Periwinkle', '#6f8fe0'], ['Slate', '#64809f'],
];

const HEX = /^#[0-9a-fA-F]{6}$/;

export default async function schools(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Operate</span>' +
      '<h1>Schools</h1>' +
      '<p>One colour each. It is the only thing that differs between schools — one ' +
      'design system, one accent — so a student knows which school they are in ' +
      'without the product looking like two products. Every change is recorded with ' +
      'your name, what was there and what replaced it.</p>' +
      '<p>A colour is <strong>replaced</strong>: there is one, and nothing has to be ' +
      'explained about the old one a year later. What a subscription costs is not ' +
      'here — one subscription opens every school, so there is one price for each ' +
      'term and it is set under <strong>What it costs</strong>.</p>' +
    '</header>' +
    '<div id="list" aria-live="polite"><p class="checking">Reading…</p></div>';

  const list = el.querySelector('#list');

  let all;
  try {
    all = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    list.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  if (!all.length) {
    list.innerHTML = '<section class="block"><p class="none">There are no schools on this ' +
      'platform yet. A school is a row, a host and a colour, in that order.</p></section>';
    return { title: section.name, el };
  }

  list.innerHTML = all.map(block).join('');
  all.forEach(wire);

  /* One school: what it wears now, the twenty to choose from, a field for
     anything else, and the two themes as they will come out. */
  function block(school) {
    return '<section class="block" data-school="' + esc(school.id) + '">' +
      '<div class="block-top">' +
        '<h2>' + esc(school.name) + '</h2>' +
        '<span class="block-score mono">' + esc(school.slug) + '</span>' +
      '</div>' +

      '<form class="accent-form" novalidate>' +
        '<div class="accent-picks" role="group" aria-label="Suggested colours for ' +
          esc(school.name) + '">' +
          SUGGESTED.map(([name, colour]) =>
            '<button type="button" class="accent-pick' +
              (same(colour, school.accent) ? ' on' : '') + '" data-colour="' + colour + '" ' +
              'style="--pick:' + colour + '" title="' + name + ' ' + colour + '">' +
              '<span class="visually-hidden">' + name + ' ' + colour + '</span>' +
            '</button>').join('') +
        '</div>' +

        '<div class="accent-bar">' +
          '<label class="accent-hex">' +
            '<span>Colour</span>' +
            '<input type="text" spellcheck="false" autocomplete="off" ' +
              'value="' + esc(school.accent || '') + '" placeholder="#5b8cff" ' +
              'aria-describedby="note-' + esc(school.id) + '">' +
          '</label>' +
          (mayAct()
            ? '<button type="submit" class="btn btn-primary">Save</button>'
            : '<span class="list-count">A read-only role may look at this and not set it.</span>') +
        '</div>' +

        '<p class="signin-notice" id="note-' + esc(school.id) + '"></p>' +
      '</form>' +

      '<div class="accent-themes"></div>' +

    '</section>';
  }

  function wire(school) {
    const box = list.querySelector('[data-school="' + cssEscape(school.id) + '"]');
    const form = box.querySelector('.accent-form');
    const field = box.querySelector('.accent-hex input');
    const note = box.querySelector('.signin-notice');
    const themes = box.querySelector('.accent-themes');

    const draw = () => {
      const wanted = field.value.trim();
      box.querySelectorAll('.accent-pick').forEach((b) => {
        b.classList.toggle('on', same(b.dataset.colour, wanted));
      });
      themes.innerHTML = HEX.test(wanted)
        ? ['dark', 'light'].map((theme) => specimen(theme, wanted)).join('')
        : '<p class="none">A colour is six hex digits after a hash, like ' +
          '<code class="mono">#5b8cff</code>. Empty is a real answer too: the school then ' +
          'wears the palette\'s own blue.</p>';
    };

    box.querySelectorAll('.accent-pick').forEach((pick) => {
      pick.addEventListener('click', () => {
        field.value = pick.dataset.colour;
        note.textContent = '';
        note.className = 'signin-notice';
        draw();
        // The field is where the value is, so that is where the focus goes: a
        // person choosing from the swatches usually wants to see it written.
        field.focus({ preventScroll: true });
      });
    });
    field.addEventListener('input', () => { draw(); });

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const wanted = field.value.trim().toLowerCase();

      /* CHECKED HERE SO SOMEBODY WHO MISTYPED IS TOLD AT ONCE. The check that
         matters is the API's, which refuses the same thing for the same reason
         and has a test. */
      if (!HEX.test(wanted)) {
        note.className = 'signin-notice bad';
        note.textContent = 'Six hex digits after a hash, like #5b8cff. A shorthand or a name '
          + 'reaches the interface as no colour at all, and the school stays as it was with '
          + 'nothing to say why.';
        return;
      }

      note.className = 'signin-notice';
      note.textContent = 'Saving…';
      try {
        const saved = await put('/console/api/v1/schools/' + school.id + '/accent',
          { accent: wanted });
        school.accent = saved.accent;
        note.className = 'signin-notice ok';
        note.textContent = 'Saved. Students see it on their next page — nothing is cached '
          + 'about a school\'s colour.';
      } catch (e) {
        note.className = 'signin-notice bad';
        note.textContent = e instanceof RequestError && e.status === 403
          ? 'That asks for an operator.'
          : e.message;
      }
      draw();
    });

    draw();
  }

  return { title: section.name, el };
}

/* One theme, as the study interface will actually paint it.

   THE SWATCHES ARE THE CORRECTED VALUES and the ratios are what they score, so
   what is on this screen is what a student gets rather than what was typed. The
   two lines under them are the two things that are invisible afterwards: a
   colour that had to move, and a pair of states that came out the same. */
function specimen(theme, wanted) {
  const worked = correctionFor(wanted, theme);
  if (!worked) {
    return '<div class="accent-theme"><p class="none">This browser could not measure the ' +
      esc(theme) + ' theme.</p></div>';
  }

  if (!worked.phosphor) {
    return '<div class="accent-theme accent-theme-' + theme + '">' +
      '<p class="none"><strong>' + esc(theme) + '</strong> — nothing on this hue reaches ' +
      '4.5:1 against every surface it lands on, so this theme would keep the palette\'s own ' +
      'blue and the school would look like two different schools in the two themes.</p></div>';
  }

  return '<div class="accent-theme accent-theme-' + theme + '" ' +
      'style="--shown:' + worked.phosphor + ';--shown-mid:' + worked.mid + '">' +
    '<div class="accent-theme-top mono">' +
      '<span>' + esc(theme) + '</span>' +
      '<span>' + worked.ratio.toFixed(2) + ':1</span>' +
    '</div>' +
    '<p class="accent-line accent-line-strong">Front-end Development</p>' +
    '<p class="accent-line accent-line-mid">12 courses · 710h</p>' +
    '<p class="accent-swatches mono">' +
      '<span class="accent-chip" style="background:' + worked.phosphor + '"></span>' +
      worked.phosphor +
      '<span class="accent-chip" style="background:' + worked.mid + '"></span>' +
      worked.mid +
    '</p>' +
    (worked.moved
      ? '<p class="accent-said">Moved from ' + esc(worked.given) + ', which reads at ' +
        worked.asGiven.toFixed(2) + ':1 here and needs 4.5. Same hue, far enough to be read.</p>'
      : '<p class="accent-said">Used exactly as chosen.</p>') +
    (worked.distinct
      ? ''
      : '<p class="accent-said accent-said-warn">A finished course and an available one come ' +
        'out the same colour in this theme: nothing on this hue is both readable and quieter ' +
        'than the accent.</p>') +
    '</div>';
}

const same = (a, b) => String(a || '').toLowerCase() === String(b || '').toLowerCase();

/* An id is a uuid, so this is belt and braces rather than a need — but a
   selector built from a value is a selector waiting for the value to change
   shape. */
const cssEscape = (v) => (window.CSS && CSS.escape ? CSS.escape(v) : String(v));
