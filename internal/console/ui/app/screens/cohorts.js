/* ==========================================================================
   Cohorts — who started when, and what became of them.

   THE FUNNEL BESIDE THIS IS A PHOTOGRAPH AND THIS IS A FILM. That report mixes
   somebody who arrived yesterday with somebody who arrived a year ago. Improve
   the first lesson in August and it barely moves, because it is dominated by
   everybody who came before — while this puts August's intake beside July's AT
   THE SAME AGE, which is the only way a change to the product shows up as a
   number.

   # THE TABLE IS TRIANGULAR, AND THE EMPTY HALF IS EMPTY

   A cohort is followed as far as it is old. The cells that do not exist are the
   months that have not happened yet, and they are drawn as nothing rather than
   as a zero — a zero in a retention table reads as everybody having left, which
   is the same mistake the funnel's unmeasured steps exist to avoid.

   # THE FIRST COLUMN IS NOT ALWAYS THE HUNDRED PER CENT

   Month zero is "signed up AND finished a section in that same month", and that
   is already a number worth seeing: an intake where only half of them ever
   started is a different problem from one that starts well and leaks. So the
   denominator is the intake, on every column including the first, and the screen
   shows both the count and the share.

   # WHAT "ACTIVE" MEANS COMES FROM THE SERVER

   A cohort table means whatever that word means. It is not written in this file
   for the same reason the item analysis's thresholds are not: a screen with its
   own copy of a definition is a screen that keeps describing the old one.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { txt } from '../../assets/language.js';

/* OBJECTS AND NOT PAIRS, for the reason `funnel.js` gives at its own copy: one
   half is a number the API takes and the other is a sentence somebody reads,
   and `language_test.go` has to be able to tell which is which. */
const WINDOWS = [
  { months: '6', label: '6 months' },
  { months: '12', label: '12 months' },
  { months: '24', label: '24 months' },
];

const NAMES = {
  real: 'Real people',
  seeded: 'The seeded population',
  everybody: 'Everybody, real and seeded',
};

export default async function cohorts(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('Cohorts')) + '</h1>' +
      '<p>' + esc(txt('People grouped by the month they signed up, followed forward. Each row is one intake and each column is a month of its life, so two intakes can be compared at the same age — which the funnel, being a single photograph of everybody at once, cannot do.')) + '</p>' +
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
      esc(txt('There are no schools on this platform yet, so nobody has signed up to one.')) +
      '</p></section>';
    return { title: section.name, el };
  }

  const asking = { school: schools[0].id, months: '12', counting: 'real' };

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>' + esc(txt('What to follow')) + '</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>' + esc(txt('School')) + '</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<label class="field">' +
          '<span>' + esc(txt('Followed for')) + '</span>' +
          '<select id="months">' +
            WINDOWS.map((w) =>
              '<option value="' + w.months + '"' + (w.months === '12' ? ' selected' : '') + '>' +
              esc(txt(w.label)) + '</option>').join('') +
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
    '<div id="table"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const table = body.querySelector('#table');
  body.querySelector('#ask').addEventListener('change', (event) => {
    if (Object.hasOwn(asking, event.target.id)) {
      asking[event.target.id] = event.target.value;
      draw();
    }
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    table.innerHTML = '<p class="checking">' + esc(txt('Reading…')) + '</p>';

    /* The request that was sent is remembered, so an answer arriving after
       somebody changed the school is dropped rather than drawn. */
    const mine = JSON.stringify(asking);

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(asking.school) +
        '/cohorts?months=' + encodeURIComponent(asking.months) +
        '&counting=' + encodeURIComponent(asking.counting));
    } catch (e) {
      if (mine !== JSON.stringify(asking)) return;
      table.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) +
        '</p></section>';
      return;
    }
    if (mine !== JSON.stringify(asking)) return;

    const rows = answer.cohorts || [];
    const widest = rows.reduce((n, c) => Math.max(n, (c.active || []).length), 0);

    table.innerHTML =
      /* The banner is the server's sentence, drawn only when it sent one, so a
         table of real people cannot appear under a heading claiming otherwise. */
      (answer.banner
        ? '<p class="notice-strong" role="status">' + esc(txt(answer.banner)) + '</p>'
        : '') +

      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
          '<span class="block-score mono">' +
            esc(txt(NAMES[answer.counting] || answer.counting)) + '</span>' +
        '</div>' +

        (rows.length === 0
          ? '<p class="none">' +
            esc(txt('Nobody has signed up to this school yet, for these people. An empty table is a real answer and not a failure to read one.')) +
            '</p>'
          : grid(rows, widest)) +

        /* THE SENTENCE IS TRANSLATED AND THE THING IT NAMES IS NOT. What comes
           back on `active` is `section.completed` — an event name, which is
           what the stream holds and what somebody would grep for. It is on the
           same line as the roles and the parameter names: a screen calling it
           something else would be a second name for one thing.

           THE `<strong>` IS INSIDE THE KEY rather than wrapped around a hole,
           because where the emphasis falls is part of how a sentence reads and
           a translation cut either side of the tag cannot move it. */
        '<p class="cohort-said">' +
          txt('Active means <strong>%s</strong> — the smallest signal that somebody actually studied that month. Every share is of the intake, including the first column: an intake where half never started is a different problem from one that starts well and leaks.')
            .replace('%s', esc(answer.active || '')) +
        '</p>' +
      '</section>' +

      /* THE HALF THAT IS NOT BUILT, SAID ON THE SCREEN. An operator looking for
         "by subscription start" should find the reason here rather than conclude
         it was forgotten. */
      (answer.by_subscription
        ? ''
        : '<section class="block">' +
            '<div class="block-top"><h2>' + esc(txt('By subscription start')) + '</h2></div>' +
            '<p class="empty-note">' + esc(txt(answer.why_no_subscription || '')) + '</p>' +
          '</section>');
  }

  function grid(rows, widest) {
    /* `+1` IS A COORDINATE AND NOT A WORD, so it is not translated; "same
       month" is a word and is. The first column is named rather than numbered
       because `+0` reads as an offset nobody applied. */
    const head = [
      /* `Month they signed up` AND NOT `Signed up`, which the student record
         already uses for the DAY somebody registered. The key IS the English
         string, so two screens meaning different things by the same words get
         one entry and one of them is wrong. */
      '<th scope="col">' + esc(txt('Month they signed up')) + '</th>',
      '<th scope="col">' + esc(txt('People')) + '</th>',
    ]
      .concat(Array.from({ length: widest }, (_, i) =>
        '<th scope="col" class="mono">' + (i === 0 ? esc(txt('same month')) : '+' + i) + '</th>'))
      .join('');

    /* `table-wrap` IS THE CONSOLE'S OWN SCROLL CONTAINER, already used by every
       other table here. A second one would be the same rule written twice, and
       the copy is the one that stops matching. */
    return '<div class="table-wrap"><table class="cohort-table">' +
      '<thead><tr>' + head + '</tr></thead><tbody>' +
      rows.map((c) => {
        const active = c.active || [];
        const cells = Array.from({ length: widest }, (_, i) => {
          /* A MONTH THAT HAS NOT HAPPENED IS EMPTY AND NOT ZERO. The cell is
             marked so a screen reader says so rather than reading silence. */
          if (i >= active.length) {
            return '<td class="cohort-none"><span class="visually-hidden">' +
              esc(txt('not yet')) + '</span></td>';
          }
          const share = c.people > 0 ? active[i] / c.people : 0;
          return '<td class="cohort-cell" style="--fill:' + (share * 100).toFixed(1) + '%">' +
            '<span class="cohort-n mono">' + active[i] + '</span>' +
            '<span class="cohort-pct mono">' + Math.round(share * 100) + '%</span>' +
          '</td>';
        }).join('');

        return '<tr>' +
          '<th scope="row" class="mono">' + esc(c.month) + '</th>' +
          '<td class="mono cohort-size">' + c.people + '</td>' + cells +
        '</tr>';
      }).join('') +
      '</tbody></table></div>';
  }
}
