/* ==========================================================================
   The funnel — of the people who arrived at a school, how many got to each step.

   IT HAS BEEN COMPUTED EVERY NIGHT AND PRINTED INTO A LOG. `cmd/analyse` says
   so in a comment: "there is no console yet, and a report nobody can read is a
   report nobody acts on". This is the screen it was waiting for, and it is the
   first entry in `Measure` — a group the rail has had a name for and nothing in.

   # THE HARD PART IS ALREADY DONE AND IS WORTH KNOWING ABOUT

   Every number here is a count of PEOPLE, not of events and not of identities.
   The top of the funnel is browsers and the bottom is accounts, so somebody who
   arrived on Monday with no account and came back signed in on Friday has to be
   one person or the conversion rate is a ratio between two different
   populations. `analysis` folds them; this screen only draws the answer.

   # A STEP WITH NO EVENT IS DRAWN AS A SENTENCE AND NEVER AS A ZERO

   Two of the eight cannot be emitted yet — verifying an address, and
   subscribing. A bar of zero would say everybody drops out there, which would
   be this screen's most alarming finding and would be about a feature nobody
   has written. So those steps carry what is missing instead of a number, and
   they are the reason the answer has a `measured` field at all.

   # THE POPULATION IS A SWITCH, AND THE BANNER COMES FROM THE SERVER

   Seeded students are excluded from every aggregate by default (K-11), and this
   is the one screen in the platform that may be told to count them — because it
   reports and does not act. The sentence saying so is NOT written here: it
   arrives on the same answer as the numbers, so a chart of real people can never
   be drawn under a heading claiming otherwise. If the server says the banner is
   empty, there is nothing to warn about.

   # THE BARS ARE RELATIVE TO THE FIRST MEASURED STEP

   Which is the definition of a funnel: everything is a share of the people who
   arrived. Drawing each bar against the largest number instead would rescale the
   chart whenever the top step changed, and the shape is the whole point.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';

/* The windows on offer. Days, because the API takes days and a screen that
   offered "this quarter" would be a second calendar to keep in step. */
const WINDOWS = [
  ['0', 'Since the beginning'],
  ['30', 'Last 30 days'],
  ['90', 'Last 90 days'],
  ['365', 'Last year'],
];

const NAMES = {
  real: 'Real people',
  seeded: 'The seeded population',
  everybody: 'Everybody, real and seeded',
};

export default async function funnel(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Measure</span>' +
      '<h1>The funnel</h1>' +
      '<p>Of the people who arrived at a school, how many reached each step. ' +
      'Every number is a count of people rather than of visits: somebody who ' +
      'arrived without an account and came back signed in is one person, which ' +
      'is the only reason the top and the bottom of this can be compared at ' +
      'all.</p>' +
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
      'platform yet, so there is nobody to have arrived at one.</p></section>';
    return { title: section.name, el };
  }

  /* WHAT IS BEING ASKED, HELD IN ONE PLACE. Three controls change it and one
     function answers it, so a redraw cannot end up showing one school's numbers
     under another school's name. */
  const asking = { school: schools[0].id, days: '0', counting: 'real' };

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>What to count</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>School</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<label class="field">' +
          '<span>Window</span>' +
          '<select id="days">' +
            WINDOWS.map(([value, label]) =>
              '<option value="' + value + '">' + esc(label) + '</option>').join('') +
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
    '<div id="chart"><p class="checking">Reading…</p></div>';

  const chart = body.querySelector('#chart');
  const controls = body.querySelector('#ask');

  controls.addEventListener('change', (event) => {
    const id = event.target.id;
    if (id === 'school' || id === 'days' || id === 'counting') {
      asking[id === 'school' ? 'school' : id] = event.target.value;
      draw();
    }
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    chart.innerHTML = '<p class="checking">Reading…</p>';

    /* THE REQUEST THAT WAS SENT IS REMEMBERED, so an answer that arrives after
       somebody has already changed the school is dropped rather than drawn.
       Three controls and a network make that ordinary, not exotic. */
    const mine = JSON.stringify(asking);

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(asking.school) +
        '/funnel?days=' + encodeURIComponent(asking.days) +
        '&counting=' + encodeURIComponent(asking.counting));
    } catch (e) {
      if (mine !== JSON.stringify(asking)) return;
      chart.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
      return;
    }
    if (mine !== JSON.stringify(asking)) return;

    const steps = answer.steps || [];

    /* THE TOP OF THE FUNNEL IS THE FIRST MEASURED STEP AND NOT THE BIGGEST
       NUMBER. Everything below is a share of the people who arrived, which is
       what makes this a funnel rather than a bar chart. */
    const top = steps.find((s) => s.measured);
    const arrived = top ? top.people : 0;

    chart.innerHTML =
      /* THE BANNER IS THE SERVER'S SENTENCE, drawn only when it sent one. The
         screen does not decide when the numbers are about invented students —
         the answer that carries them does, so the two cannot disagree. */
      (answer.banner
        ? '<p class="notice-strong" role="status">' + esc(answer.banner) + '</p>'
        : '') +

      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
          '<span class="block-score mono">' + esc(NAMES[answer.counting] || answer.counting) +
          '</span>' +
        '</div>' +
        (arrived === 0 && steps.every((s) => !s.measured || s.people === 0)
          ? '<p class="none">Nobody has reached any step of this, in this window, ' +
            'for these people. An empty funnel is a real answer and not a failure ' +
            'to read one.</p>'
          : '<ol class="funnel">' + steps.map((s) => row(s, arrived)).join('') + '</ol>') +
      '</section>';
  }

  function row(step, arrived) {
    /* NOT MEASURED IS NOT ZERO, and the two do not share a shape on the screen
       either — there is no bar at all, because a bar of length nothing is
       exactly the reading this is here to prevent. */
    if (!step.measured) {
      return '<li class="funnel-step funnel-step-unmeasured">' +
        '<span class="funnel-label">' + esc(step.label) + '</span>' +
        '<span class="funnel-missing">Not counted yet — ' + esc(step.why || '') + '</span>' +
      '</li>';
    }

    const share = arrived > 0 ? step.people / arrived : 0;
    return '<li class="funnel-step">' +
      '<span class="funnel-label">' + esc(step.label) + '</span>' +
      '<span class="funnel-bar"><span class="funnel-fill" ' +
        'style="width:' + (share * 100).toFixed(1) + '%"></span></span>' +
      '<span class="funnel-count mono">' + step.people +
        (arrived > 0 ? ' · ' + Math.round(share * 100) + '%' : '') +
      '</span>' +
    '</li>';
  }
}
