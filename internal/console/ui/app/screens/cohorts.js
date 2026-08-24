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

const WINDOWS = [['6', '6 months'], ['12', '12 months'], ['24', '24 months']];

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
      '<span class="eyebrow mono">Measure</span>' +
      '<h1>Cohorts</h1>' +
      '<p>People grouped by the month they signed up, followed forward. Each ' +
      'row is one intake and each column is a month of its life, so two ' +
      'intakes can be compared at the same age — which the funnel, being a ' +
      'single photograph of everybody at once, cannot do.</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">Reading…</p></div>';

  const body = el.querySelector('#body');

  let schools;
  try {
    schools = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  if (!schools.length) {
    body.innerHTML = '<section class="block"><p class="none">There are no schools on this ' +
      'platform yet, so nobody has signed up to one.</p></section>';
    return { title: section.name, el };
  }

  const asking = { school: schools[0].id, months: '12', counting: 'real' };

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>What to follow</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>School</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<label class="field">' +
          '<span>Followed for</span>' +
          '<select id="months">' +
            WINDOWS.map(([value, label]) =>
              '<option value="' + value + '"' + (value === '12' ? ' selected' : '') + '>' +
              esc(label) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<label class="field">' +
          '<span>People</span>' +
          '<select id="counting">' +
            Object.keys(NAMES).map((k) =>
              '<option value="' + k + '">' + esc(NAMES[k]) + '</option>').join('') +
          '</select>' +
        '</label>' +
      '</form>' +
    '</section>' +
    '<div id="table"><p class="checking">Reading…</p></div>';

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
    table.innerHTML = '<p class="checking">Reading…</p>';

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
      table.innerHTML = '<section class="block"><p class="none">' + esc(e.message) +
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
        ? '<p class="notice-strong" role="status">' + esc(answer.banner) + '</p>'
        : '') +

      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
          '<span class="block-score mono">' +
            esc(NAMES[answer.counting] || answer.counting) + '</span>' +
        '</div>' +

        (rows.length === 0
          ? '<p class="none">Nobody has signed up to this school yet, for these people. ' +
            'An empty table is a real answer and not a failure to read one.</p>'
          : grid(rows, widest)) +

        '<p class="cohort-said">Active means <strong>' + esc(answer.active || '') +
          '</strong> — the smallest signal that somebody actually studied that month. ' +
          'Every share is of the intake, including the first column: an intake where ' +
          'half never started is a different problem from one that starts well and leaks.</p>' +
      '</section>' +

      /* THE HALF THAT IS NOT BUILT, SAID ON THE SCREEN. An operator looking for
         "by subscription start" should find the reason here rather than conclude
         it was forgotten. */
      (answer.by_subscription
        ? ''
        : '<section class="block">' +
            '<div class="block-top"><h2>By subscription start</h2></div>' +
            '<p class="empty-note">' + esc(answer.why_no_subscription || '') + '</p>' +
          '</section>');
  }

  function grid(rows, widest) {
    const head = ['<th scope="col">Signed up</th>', '<th scope="col">People</th>']
      .concat(Array.from({ length: widest }, (_, i) =>
        '<th scope="col" class="mono">' + (i === 0 ? 'same month' : '+' + i) + '</th>'))
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
              'not yet</span></td>';
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
