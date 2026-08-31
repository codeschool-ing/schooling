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
import { txt, language } from '../../assets/language.js';

/* The windows on offer. The same four the funnel uses, in days, because the API
   takes days and a second calendar in a second screen is a second thing to keep
   in step. Objects rather than pairs, for the reason `funnel.js` gives. */
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

/*
The country names, in the language that was chosen, built once PER LANGUAGE.

	IT USED TO BE `new Intl.DisplayNames(['en'], …)` AT MODULE LOAD, which was
	the right answer for exactly as long as this console had one language. It is
	the `day()` defect in a third place and the loudest of the three: a screen
	otherwise entirely in Portuguese listing `Germany`, `Spain` and `Japan` — and
	they are real country names, so nothing looks broken.

	CACHED, BECAUSE IT IS NOT FREE TO CONSTRUCT and this screen redraws on every
	change of three controls. Keyed by language, because the language moves and a
	single cached one would be the old language's names for the rest of the
	session — which is the same defect wearing a cache.

	AND THE NAMES ARE THE BROWSER'S, not a table this repository carries. That is
	the whole reason the answer comes back as ISO codes: 249 region names in two
	languages is a thing to keep current, and every browser already has it.
*/
const REGIONS = {};

function regions() {
  const at = language();
  if (!(at in REGIONS)) {
    try {
      REGIONS[at] = new Intl.DisplayNames([at === 'pt' ? 'pt-BR' : 'en-GB'], { type: 'region' });
    } catch (e) {
      // An engine without it draws the codes, which are still readable. A screen
      // that failed over a label would be a screen lost to a nicety.
      REGIONS[at] = null;
    }
  }
  return REGIONS[at];
}

/* THE CODE IS ALL THAT ARRIVES, and everything below is derived from it. A
   two-letter code that is not a region — and `unknown` is the one that
   matters — must not throw: `Intl.DisplayNames.of` refuses anything that is
   not shaped like a region, so the shape is checked before it is asked. */
const isRegion = (code) => /^[a-z]{2}$/.test(String(code || ''));

function nameOf(code) {
  if (!isRegion(code)) return String(code || '');
  const upper = String(code).toUpperCase();
  const names = regions();
  try {
    return (names && names.of(upper)) || upper;
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
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('Where they are')) + '</h1>' +
      '<p>' + esc(txt('The people of one school, by the country each request came from. The country is worked out in this process from the address and the address is discarded, which is what the privacy policy promises and the reason there is no city here and never will be.')) + '</p>' +
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
      esc(txt('There are no schools on this platform yet, so there is nobody to be anywhere.')) +
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
    '<div id="where"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

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
    where.innerHTML = '<p class="checking">' + esc(txt('Reading…')) + '</p>';

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
      where.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) +
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
        ? '<p class="notice-strong" role="status">' + esc(txt(answer.banner)) + '</p>'
        : '') +

      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
          '<span class="block-score mono">' +
            esc(txt(NAMES[answer.counting] || answer.counting)) +
          '</span>' +
        '</div>' +

        (rows.length === 0
          ? '<p class="none">' +
            esc(txt('Nobody has done anything at this school, in this window, for these people. An empty world is a real answer and not a failure to read one.')) +
            '</p>'
          : map(rows, biggest, nowhere) +
            '<p class="block-lede">' + esc(lede(people, rows.length)) + '</p>' +

            /* SAID ONLY WHEN IT IS TRUE. Comparing the two numbers is what
               decides, rather than a sentence written here about a subtlety a
               school where nobody travelled does not have. */
            (summed > people
              ? '<p class="hint">' +
                esc(txt('These add up to %s and there are %p people, because somebody who studied from two countries is honestly in both. The countries are shares of where the studying happened; the number above is how many people did it.')
                  .replace('%s', summed)
                  .replace('%p', people)) +
                '</p>'
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

    /* THE LABEL IS THE WHOLE THING A SCREEN READER GETS FOR THIS PICTURE, so it
       is assembled from whole sentences rather than glued together around a
       comma: the tail — "and four more" — sits before the list in some
       languages, and a translator handed ` and ` cannot move it. */
    const first = named.slice(0, 6).join(', ');
    const shown = named.length > 6
      ? (named.length === 7
        ? txt('%s and one more').replace('%s', first)
        : txt('%s and %d more').replace('%s', first).replace('%d', named.length - 6))
      : first;

    const label = named.length
      ? txt('A world map. %s are shaded. The list below has every country and its count.')
        .replace('%s', shown)
      : txt('A world map with nothing shaded on it.');

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
        /* THE QUOTED NAME IS INSIDE THE KEY and not spliced in, so a translator
           sees the caption and the row label together and can make them match.
           Splicing would guarantee they match and guarantee nothing about the
           sentence around it reading in the language it was translated into. */
        ? '<figcaption>' +
          esc(txt('The map shows only the people whose country is known. The rest are in the list below, under “Nobody knows where”.')) +
          '</figcaption>'
        : '') +
    '</figure>';
  }

  /* HOW MANY PEOPLE, IN HOW MANY COUNTRIES — two numbers that can each be one,
     so four whole sentences and no plural assembled from a letter. This console
     has shipped "1 trilhas" once; the fix is never a rule, it is writing the
     sentence out. */
  function lede(people, places) {
    if (people === 1) {
      return places === 1
        ? txt('one person, in one country.')
        : txt('one person, in %c countries.').replace('%c', places);
    }
    return places === 1
      ? txt('%p people, in one country.').replace('%p', people)
      : txt('%p people, in %c countries.').replace('%p', people).replace('%c', places);
  }

  function row(country, biggest, nowhere) {
    const code = String(country.code || '');
    const count = country.people || 0;
    const share = biggest > 0 ? count / biggest : 0;
    const placeless = code === nowhere;

    return '<li class="country' + (placeless ? ' country-nowhere' : '') + '">' +
      '<span class="country-flag" aria-hidden="true">' + flagOf(code) + '</span>' +
      '<span class="country-name">' +
        (placeless ? esc(txt('Nobody knows where')) : esc(nameOf(code))) +
        (placeless
          ? '<span class="country-why">' +
            esc(txt('No country could be worked out — a request from before there was a database to work it out with, or one through something that hides where it came from.')) +
            '</span>'
          : '<span class="country-code mono">' + esc(code.toUpperCase()) + '</span>') +
      '</span>' +
      '<span class="country-bar"><span class="country-fill" ' +
        'style="width:' + (share * 100).toFixed(1) + '%"></span></span>' +
      '<span class="country-count mono">' + count + '</span>' +
    '</li>';
  }
}
