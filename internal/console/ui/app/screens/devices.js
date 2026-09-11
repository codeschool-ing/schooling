/* ==========================================================================
   What they are on — the people of one school, by the kind of thing they
   studied on.

   # IT IS `countries.js` WITHOUT THE MAP, AND THAT IS THE WHOLE DESIGN

   The same question shape: people seen on a thing, folded the way the funnel
   folds them, one row each, biggest first, with the honest total beside them
   because the rows add up to more. There is no picture because there is nothing
   to draw — four rows are a list, and a chart of four bars is a list with
   decoration on it.

   # THE SECOND COLUMN IS WHY THIS SCREEN EXISTS

   "Seventy per cent are on phones" is trivia and every analytics product in the
   world will tell you it. Next to it is how many of those people ever signed
   up, and that comparison is the only place on this platform where "the site is
   hard to use on a phone" appears as a number rather than as a feeling.

   So the share is drawn and the conversion is drawn beside it, and neither is
   ranked by the other: sorting by conversion would bury the row that matters,
   which is the big one that converts badly.

   # `unknown` IS A ROW AND KEEPS ITS PLACE IN THE ORDER

   `countries.js`'s argument exactly, and here the reason is different and worth
   saying: only Chromium sends the hint this is read from, the page fills in for
   the browsers it can, and what is left told us nothing. Hiding that row, or
   moving it politely to the bottom, would turn a report about the browsers we
   can read into a report about the audience.

   THE SENTENCE SAYING SO COMES FROM THE SERVER. A screen that wrote its own
   would keep saying it after the collection changed, and it is the interface of
   a console whose whole job is to be trusted about arithmetic.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { txt } from '../../assets/language.js';

/* The windows and the populations, the same four and the same three the funnel
   and the map offer. Copied rather than shared for the reason `countries.js`
   gives about its own: they are separate literals in separate screens, and a
   `language_test.go` entry names every one of them for exactly that. */
const WINDOWS = [
  { days: '0', label: 'Since the beginning' },
  { days: '30', label: 'Last 30 days' },
  { days: '90', label: 'Last 90 days' },
  { days: '365', label: 'Last year' },
];

const NAMES = {
  real: 'Real people',
  seeded: 'The seeded population',
  everybody: 'Everybody, real and seeded',
};

/* WHAT EACH WORD IS CALLED ON SCREEN. The keys are the server's and stay
   English — they are what the events carry — and these are the words beside
   them. A kind the server sends and this file has no word for is drawn under
   its own word rather than dropped, which is `reports.js`'s rule for a verdict
   and right here for the same reason: a row nobody can read is better than a
   row nobody can see. */
const KINDS = {
  phone: 'Phone',
  tablet: 'Tablet',
  computer: 'Computer',
  unknown: 'Did not say',
};

export default async function devices(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('What they are on')) + '</h1>' +
      '<p>' + esc(txt('The people of one school, by the shape of the thing they studied on, '
        + 'and how many of each ever signed up. Three shapes and a shrug: there is no model '
        + 'here and no screen size, because that is the granularity at which a dimension '
        + 'becomes a way of recognising somebody.')) + '</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const body = el.querySelector('#body');

  let schools;
  try {
    schools = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) + '</p></section>';
    return { title: section.name, el };
  }

  if (!schools.length) {
    body.innerHTML = '<section class="block"><p class="none">' +
      esc(txt('There are no schools on this platform yet, so there is nobody to be on anything.')) +
      '</p></section>';
    return { title: section.name, el };
  }

  // What is being asked, in one place, so a redraw cannot show one school's
  // numbers under another school's name.
  const asking = { school: schools[0].id, days: '0', counting: 'real' };

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>' + esc(txt('What to count')) + '</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>' + esc(txt('School')) + '</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<label class="field">' +
          '<span>' + esc(txt('Window')) + '</span>' +
          '<select id="days">' +
            WINDOWS.map((w) =>
              '<option value="' + w.days + '">' + esc(txt(w.label)) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<label class="field">' +
          '<span>' + esc(txt('People')) + '</span>' +
          '<select id="counting">' +
            Object.keys(NAMES).map((k) =>
              '<option value="' + k + '">' + esc(txt(NAMES[k])) + '</option>').join('') +
          '</select>' +
        '</label>' +
      '</form>' +
    '</section>' +
    '<div id="held"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const held = body.querySelector('#held');

  body.querySelector('#ask').addEventListener('change', (event) => {
    const id = event.target.id;
    if (id === 'school' || id === 'days' || id === 'counting') {
      asking[id] = event.target.value;
      draw();
    }
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    held.innerHTML = '<p class="checking">' + esc(txt('Reading…')) + '</p>';

    // The request that was sent is remembered, so an answer arriving after
    // somebody changed the school is dropped rather than drawn.
    const mine = JSON.stringify(asking);

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(asking.school) +
        '/devices?days=' + encodeURIComponent(asking.days) +
        '&counting=' + encodeURIComponent(asking.counting));
    } catch (e) {
      if (mine !== JSON.stringify(asking)) return;
      held.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) +
        '</p></section>';
      return;
    }
    if (mine !== JSON.stringify(asking)) return;

    const rows = answer.devices || [];
    const people = answer.people || 0;
    const nothing = answer.unknown || '';

    /* THE BARS ARE RELATIVE TO THE BIGGEST ROW, INCLUDING `unknown`. Scaling
       against the biggest KNOWN kind would draw a chart in which the largest
       group of people on the platform is not visible — `countries.js`'s
       reasoning, and the same situation: that row is the majority today. */
    const biggest = rows.reduce((most, d) => Math.max(most, d.people || 0), 0);
    const summed = rows.reduce((total, d) => total + (d.people || 0), 0);

    held.innerHTML =
      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc(txt('What they are on')) + '</h2>' +
          '<span class="block-score mono">' + people + '</span>' +
        '</div>' +

        (rows.length === 0
          ? '<p class="none">' + esc(txt('Nobody has been seen in this school in this window.')) + '</p>'
          : '<ul class="holds">' + rows.map((d) => row(d, biggest, nothing)).join('') + '</ul>') +

        /* THE ROWS ADD UP TO MORE THAN THE PEOPLE, AND THE SENTENCE APPEARS
           ONLY WHEN THEY DO. Asserted always, it would tell a school where
           nobody used two devices about a subtlety it does not have; drawn from
           comparing the two numbers, it is true whenever it is on screen. */
        (summed > people
          ? '<p class="aside">' + esc(txt('Somebody who read on a phone and drilled on a '
            + 'laptop is in both rows, so these add up to more than the people. The number '
            + 'beside the heading is everybody, counted once.')) + '</p>'
          : '') +

        // AND WHY THE LAST ROW IS BIG, in the server's words rather than this
        // screen's — see the header.
        (rows.some((d) => d.kind === nothing)
          ? '<p class="aside">' + esc(txt(answer.why_unknown || '')) + '</p>'
          : '') +

        '<p class="aside">' + esc(txt(answer.banner || '')) + '</p>' +
      '</section>';
  }

  /* One kind, with its share of the people and how many of them are students.

     THE CONVERSION IS A NUMBER AND NOT A SECOND BAR. Two bars of different
     denominators side by side read as a comparison of the same thing, which
     these are not: one is a share of everybody and the other is a share of that
     row. */
  function row(d, biggest, nothing) {
    const people = d.people || 0;
    const students = d.students || 0;
    const share = biggest ? Math.round((people / biggest) * 100) : 0;
    const rate = people ? Math.round((students / people) * 100) : 0;
    const name = KINDS[d.kind] ? txt(KINDS[d.kind]) : String(d.kind || '');

    return '<li class="hold' + (d.kind === nothing ? ' hold-nothing' : '') + '">' +
      '<span class="hold-what">' + esc(name) + '</span>' +
      '<span class="hold-bar" role="img" aria-label="' +
        esc(String(people) + ' ' + txt('people')) + '">' +
        '<span class="hold-fill" style="width:' + share + '%"></span>' +
      '</span>' +
      '<span class="hold-people mono">' + esc(String(people)) + '</span>' +
      '<span class="hold-rate mono" title="' + esc(txt('of them have an account')) + '">' +
        esc(String(students)) + ' · ' + esc(String(rate)) + '%' +
      '</span>' +
    '</li>';
  }
}
