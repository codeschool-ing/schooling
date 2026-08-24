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
      '<p>One colour each, and what a subscription costs. Those are the only two ' +
      'things that differ between schools — one design system, one accent — so a ' +
      'student knows which school they are in without the product looking like two ' +
      'products. Every change is recorded with your name, what was there and what ' +
      'replaced it.</p>' +
      '<p>The two are not the same kind of setting. A colour is <strong>replaced</strong>: ' +
      'there is one, and nothing has to be explained about the old one a year later. ' +
      'A price is <strong>appended</strong> — saving one writes a new row dated from ' +
      'today and the old one stays, because a March invoice has to stay explicable ' +
      'in November.</p>' +
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

      /* WHAT IT COSTS, UNDER THE COLOUR AND NOT BESIDE IT. They are two
         settings of one school and the colour is the one somebody came for;
         putting them side by side would make a price look like a field to
         adjust, which is the reading this whole feature exists to prevent. */
      '<form class="price-form" novalidate>' +
        '<h3 class="price-head">What a subscription costs here</h3>' +
        '<div class="price-bar">' +
          '<label class="price-amount">' +
            '<span>Price</span>' +
            '<input type="text" inputmode="decimal" spellcheck="false" autocomplete="off" ' +
              'value="' + esc(asAmount(school.priceCents)) + '" placeholder="490.00" ' +
              'aria-describedby="price-note-' + esc(school.id) + '">' +
          '</label>' +
          '<label class="price-currency">' +
            '<span>Currency</span>' +
            '<input type="text" spellcheck="false" autocomplete="off" maxlength="3" ' +
              'value="' + esc(school.currency || '') + '" placeholder="BRL">' +
          '</label>' +
          (mayAct()
            ? '<button type="submit" class="btn btn-primary">Save a new price</button>'
            : '<span class="list-count">A read-only role may look at this and not set it.</span>') +
        '</div>' +
        '<p class="signin-notice" id="price-note-' + esc(school.id) + '"></p>' +
      '</form>' +

      '<div class="price-series"></div>' +
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
    wirePrice(box, school);
  }

  /* ---------- what it costs ----------

     THE SERIES IS READ WHEN THE SCREEN IS DRAWN AND AGAIN AFTER EVERY SAVE,
     because the point of appending is that the old rows are still there and a
     screen that showed only the newest would be the mutable field again with
     extra steps. */
  async function wirePrice(box, school) {
    const form = box.querySelector('.price-form');
    const amount = box.querySelector('.price-amount input');
    const currency = box.querySelector('.price-currency input');
    const note = box.querySelector('.signin-notice[id^="price-note"]');
    const series = box.querySelector('.price-series');

    await showSeries();

    form.addEventListener('submit', async (event) => {
      event.preventDefault();

      const cents = asCents(amount.value);
      const money = currency.value.trim().toUpperCase();

      /* CHECKED HERE SO SOMEBODY WHO MISTYPED IS TOLD AT ONCE. The check that
         matters is the API's, which refuses the same two things for the same
         reasons and has a test. */
      if (cents === null || cents <= 0) {
        note.className = 'signin-notice bad';
        note.textContent = 'A price is an amount above zero, like 490 or 490.00. '
          + 'A school with no offer has no price at all rather than a price of nothing.';
        return;
      }
      if (!/^[A-Z]{3}$/.test(money)) {
        note.className = 'signin-notice bad';
        note.textContent = 'A currency is three letters, ISO 4217 — BRL, EUR, USD. '
          + 'It is what a browser needs to format the amount.';
        return;
      }

      note.className = 'signin-notice';
      note.textContent = 'Saving…';
      try {
        const saved = await put('/console/api/v1/schools/' + school.id + '/price',
          { cents, currency: money });
        school.priceCents = saved.priceCents;
        school.currency = saved.currency;
        note.className = 'signin-notice ok';
        note.textContent = 'Saved as a new price, from today. The one before it is still '
          + 'in the series below.';
      } catch (e) {
        note.className = 'signin-notice bad';
        note.textContent = e instanceof RequestError && e.status === 403
          ? 'That asks for an operator.'
          : e.message;
      }
      await showSeries();
    });

    async function showSeries() {
      let answer;
      try {
        answer = await get('/console/api/v1/schools/' + school.id + '/prices');
      } catch (e) {
        series.innerHTML = '<p class="none">' + esc(e.message) + '</p>';
        return;
      }

      const rows = answer.prices || [];
      series.innerHTML = rows.length === 0
        ? '<p class="none">This school has no price. The invitation then says what a ' +
          'subscription opens without naming a figure.</p>'
        : '<ol class="price-list">' +
            rows.map((p, i) =>
              '<li class="price-row' + (i === 0 ? ' price-now' : '') + '">' +
                '<span class="price-money mono">' + esc(shown(p.cents, p.currency)) + '</span>' +
                '<span class="price-from">' + (i === 0 ? 'in force since ' : 'from ') +
                  esc(day(p.from)) + '</span>' +
              '</li>').join('') +
          '</ol>' +
          '<p class="aside">' + esc(answer.append_only || '') + '</p>';
    }
  }

  return { title: section.name, el };
}

/* CENTS IN AND A DECIMAL OUT, and the conversion lives in this file rather than
   in the request because the server speaks cents everywhere — the ledger does,
   the audit entry does, and a decimal crossing that boundary is the one place
   money would become a string somebody has to parse.

   `null` FOR ANYTHING THAT IS NOT A NUMBER, so the caller refuses rather than
   sending a NaN that arrives as a zero and reads as "they set it to nothing". */
function asCents(typed) {
  const clean = String(typed || '').trim().replace(',', '.');
  if (!/^\d+(\.\d{1,2})?$/.test(clean)) return null;
  return Math.round(Number(clean) * 100);
}

function asAmount(cents) {
  return cents > 0 ? (cents / 100).toFixed(2) : '';
}

/* What a price looks like in the list. `Intl` rather than a symbol table: the
   console shows every school's currency and this file must not become the place
   that knows which symbol goes on which side of which number. */
function shown(cents, currency) {
  try {
    return new Intl.NumberFormat(undefined, { style: 'currency', currency })
      .format(cents / 100);
  } catch (e) {
    // A currency `Intl` does not know is still a real price. Showing the code
    // beside the number is worse than showing nothing, and better than throwing.
    return (cents / 100).toFixed(2) + ' ' + currency;
  }
}

/* The day, not the second. A price is a decision somebody made on a date, and
   the minute it was typed answers nothing anybody asks of this list. */
function day(when) {
  const at = new Date(when);
  return Number.isNaN(at.getTime()) ? 'an unknown day' : at.toLocaleDateString();
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
