/* ==========================================================================
   Where they are — the people of one school, by the country they studied from.

   # THE MAP IS THE PICTURE AND THE LIST IS THE REPORT

   Both are here and neither is decoration. A choropleth answers "is this
   platform local or is it everywhere" in one glance and cannot answer "how
   many"; a shape a tenth of a degree wide is not a number, and eight countries
   of similar shade are not a ranking. The list under it is the answer to
   everything the picture cannot say, and it is what a screen reader gets —
   the SVG is one image with one label, deliberately, rather than 174 shapes
   read out in alphabetical order.

   THE OUTLINES ARE GENERATED AND COMMITTED. `tools/world` turns Natural
   Earth's public-domain country borders into `world.js`; its own comment holds
   the command, the projection and why Antarctica is not there. Nothing is
   fetched at run time — this page loads from one origin and no other (P-03).

   # THE ROWS ADD UP TO MORE THAN THE PEOPLE, AND THAT IS NOT A DEFECT

   Somebody who studied at home and again on a trip is honestly in two
   countries. Anybody reading a column of numbers adds them up, so the true
   count of people comes back on the same answer (K-16) and this screen shows
   both — and says why they differ, WHEN they differ. The sentence is drawn
   from comparing the two numbers rather than asserted, so a school where
   nobody travelled is not told about a subtlety it does not have.

   # `unknown` IS A ROW AND KEEPS ITS PLACE IN THE ORDER

   It is where every event written before there was a database came from, and
   where everything behind a VPN will keep coming from. Today it is most of the
   platform. Hiding it would make this screen look complete and every share on
   it a lie, and moving it to the bottom would be the same lie told politely.

   It is drawn differently because it is not a place — no flag, and a sentence
   under it saying what it means. The word itself comes from the server: a copy
   of it here is a copy that stops matching the day the server's changes, and
   the symptom is a row labelled with a country code nobody recognises.

   # THE NAMES AND THE FLAGS COST NOTHING

   `Intl.DisplayNames` is in the browser and knows every region name; the flag
   is the two letters of the code shifted into regional indicators, which is
   arithmetic. Neither is a table this repository has to carry, keep current, or
   translate — which is the whole reason the answer is ISO codes and not names
   (`analysis` says so where it reads them).
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { WORLD, BOX } from './world.js';

/* The windows on offer. The same four the funnel uses, in days, because the API
   takes days and a second calendar in a second screen is a second thing to keep
   in step. */
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

/* Built once. It is not free to construct and this screen redraws on every
   change of three controls. */
const REGIONS = regionNames();

function regionNames() {
  try {
    return new Intl.DisplayNames(['en'], { type: 'region' });
  } catch (e) {
    // An engine without it draws the codes, which are still readable. A screen
    // that failed over a label would be a screen lost to a nicety.
    return null;
  }
}

/* THE CODE IS ALL THAT ARRIVES, and everything below is derived from it. A
   two-letter code that is not a region — and `unknown` is the one that
   matters — must not throw: `Intl.DisplayNames.of` refuses anything that is
   not shaped like a region, so the shape is checked before it is asked. */
const isRegion = (code) => /^[a-z]{2}$/.test(String(code || ''));

function nameOf(code) {
  if (!isRegion(code)) return String(code || '');
  const upper = String(code).toUpperCase();
  try {
    return (REGIONS && REGIONS.of(upper)) || upper;
  } catch (e) {
    return upper;
  }
}

/* The flag is the two letters shifted into REGIONAL INDICATOR SYMBOLS, which
   every platform pairs into a flag on its own. `A` is 0x41 and the first
   indicator is 0x1F1E6. */
function flagOf(code) {
  if (!isRegion(code)) return '';
  return String.fromCodePoint(
    ...String(code).toUpperCase().split('').map((c) => 0x1f1e6 + c.charCodeAt(0) - 0x41));
}

export default async function countries(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Measure</span>' +
      '<h1>Where they are</h1>' +
      '<p>The people of one school, by the country each request came from. The ' +
      'country is worked out in this process from the address and the address ' +
      'is discarded, which is what the privacy policy promises and the reason ' +
      'there is no city here and never will be.</p>' +
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
      'platform yet, so there is nobody to be anywhere.</p></section>';
    return { title: section.name, el };
  }

  // What is being asked, in one place, so a redraw cannot show one school's
  // numbers under another school's name.
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
    '<div id="where"><p class="checking">Reading…</p></div>';

  const where = body.querySelector('#where');
  const controls = body.querySelector('#ask');

  controls.addEventListener('change', (event) => {
    const id = event.target.id;
    if (id === 'school' || id === 'days' || id === 'counting') {
      asking[id] = event.target.value;
      draw();
    }
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    where.innerHTML = '<p class="checking">Reading…</p>';

    // The request that was sent is remembered, so an answer arriving after
    // somebody changed the school is dropped rather than drawn.
    const mine = JSON.stringify(asking);

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(asking.school) +
        '/countries?days=' + encodeURIComponent(asking.days) +
        '&counting=' + encodeURIComponent(asking.counting));
    } catch (e) {
      if (mine !== JSON.stringify(asking)) return;
      where.innerHTML = '<section class="block"><p class="none">' + esc(e.message) +
        '</p></section>';
      return;
    }
    if (mine !== JSON.stringify(asking)) return;

    const rows = answer.countries || [];
    const people = answer.people || 0;
    const nowhere = answer.unknown || '';

    /* THE BARS ARE RELATIVE TO THE BIGGEST ROW, INCLUDING `unknown`. Scaling
       against the biggest KNOWN country would draw a chart in which the largest
       group of people on the platform is not visible — which is the opposite of
       what this screen is for while most of the stream predates the database. */
    const biggest = rows.reduce((most, c) => Math.max(most, c.people || 0), 0);
    const summed = rows.reduce((total, c) => total + (c.people || 0), 0);

    where.innerHTML =
      // The server's sentence, drawn only when it sent one.
      (answer.banner
        ? '<p class="notice-strong" role="status">' + esc(answer.banner) + '</p>'
        : '') +

      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
          '<span class="block-score mono">' + esc(NAMES[answer.counting] || answer.counting) +
          '</span>' +
        '</div>' +

        (rows.length === 0
          ? '<p class="none">Nobody has done anything at this school, in this window, ' +
            'for these people. An empty world is a real answer and not a failure to ' +
            'read one.</p>'
          : map(rows, biggest, nowhere) +
            '<p class="block-lede">' + people + (people === 1 ? ' person' : ' people') +
              ', in ' + rows.length + (rows.length === 1 ? ' country' : ' countries') + '.' +
            '</p>' +

            /* SAID ONLY WHEN IT IS TRUE. Comparing the two numbers is what
               decides, rather than a sentence written here about a subtlety a
               school where nobody travelled does not have. */
            (summed > people
              ? '<p class="hint">These add up to ' + summed + ' and there are ' + people +
                ' people, because somebody who studied from two countries is honestly ' +
                'in both. The countries are shares of where the studying happened; the ' +
                'number above is how many people did it.</p>'
              : '') +

            '<ul class="countries">' +
              rows.map((c) => row(c, biggest, nowhere)).join('') +
            '</ul>')+
      '</section>';
  }

/* THE MAP.

   ONE IMAGE WITH ONE LABEL, and not 174 shapes with names on them. A screen
   reader given a labelled path per country reads the whole world out in the
   order the file happens to be in, which is worse than useless — so the SVG is
   `role="img"` with a sentence saying what it shows, and the list below is the
   accessible answer. That is not a shortcut: the list is the better answer for
   everybody, and the picture is what says "everywhere" or "one city" at a
   glance.

   THE SHADE IS THE SHARE OF THE BIGGEST COUNTRY, on the same scale as the bars
   below, so the eye can move between the two without rescaling. It never goes
   to nothing: a country with one person in it is drawn at a floor that is still
   visibly different from a country with nobody, because "somebody is there" is
   the whole finding on a map of a platform this size.

   AND `unknown` IS NOT ON IT, which is the one thing the map cannot say. It is
   not a place, so it has no shape — and today it is most of the platform. The
   list carries it; the picture is honestly a picture of the part we know, and
   the sentence under it says so rather than leaving somebody to conclude the
   world is emptier than it is. */
  function map(rows, biggest, nowhere) {
    const shade = {};
    let placed = 0;
    rows.forEach((c) => {
      const code = String(c.code || '');
      if (code === nowhere || !WORLD[code]) return;
      placed += c.people || 0;
      /* THE FLOOR IS HIGH, AND IT WAS HIGHER THAN THE FIRST GUESS. At 0.2 a
         country with one person sat within a shade of a country with none —
         rendered side by side, Japan and Kazakhstan were the same colour. The
         difference between somebody and nobody is the entire finding on a map
         of a platform this size, so the scale starts where that difference is
         already visible and spends the rest of its range on the ranking. */
      shade[code] = biggest > 0 ? 0.35 + 0.65 * ((c.people || 0) / biggest) : 0.35;
    });

    const named = rows
      .filter((c) => shade[c.code] !== undefined)
      .map((c) => nameOf(c.code));

    const label = named.length
      ? 'A world map. ' + named.slice(0, 6).join(', ') +
        (named.length > 6 ? ' and ' + (named.length - 6) + ' more' : '') +
        ' are shaded. The list below has every country and its count.'
      : 'A world map with nothing shaded on it.';

    return '<figure class="worldmap">' +
      '<svg viewBox="' + BOX + '" role="img" aria-label="' + esc(label) + '" ' +
        'preserveAspectRatio="xMidYMid meet" fill-rule="evenodd">' +
        Object.keys(WORLD).map((code) =>
          '<path d="' + WORLD[code] + '" class="land' +
            (shade[code] !== undefined ? ' land-on" style="opacity:' + shade[code].toFixed(2) : '') +
          '"/>').join('') +
      '</svg>' +

      /* SAID ONLY WHEN THERE IS SOMETHING TO SAY. A platform where everybody's
         country is known needs no footnote, and a footnote nobody needs is one
         more sentence people learn to skip. */
      (placed < rows.reduce((t, c) => t + (c.people || 0), 0)
        ? '<figcaption>The map shows only the people whose country is known. The ' +
          'rest are in the list below, under “Nobody knows where”.</figcaption>'
        : '') +
    '</figure>';
  }

  function row(country, biggest, nowhere) {
    const code = String(country.code || '');
    const count = country.people || 0;
    const share = biggest > 0 ? count / biggest : 0;
    const placeless = code === nowhere;

    return '<li class="country' + (placeless ? ' country-nowhere' : '') + '">' +
      '<span class="country-flag" aria-hidden="true">' + flagOf(code) + '</span>' +
      '<span class="country-name">' +
        (placeless ? 'Nobody knows where' : esc(nameOf(code))) +
        (placeless
          ? '<span class="country-why">No country could be worked out — a request ' +
            'from before there was a database to work it out with, or one through ' +
            'something that hides where it came from.</span>'
          : '<span class="country-code mono">' + esc(code.toUpperCase()) + '</span>') +
      '</span>' +
      '<span class="country-bar"><span class="country-fill" ' +
        'style="width:' + (share * 100).toFixed(1) + '%"></span></span>' +
      '<span class="country-count mono">' + count + '</span>' +
    '</li>';
  }
}
