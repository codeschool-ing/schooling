/* ==========================================================================
   Who is here — the only screen in this console that is about right now.

   EVERY OTHER SCREEN HERE IS A PHOTOGRAPH OR A FILM OF THE PAST. The funnel is
   everybody at once, cohorts are intakes followed forward, the item analysis is
   what a nightly job wrote. This one is worth nothing five minutes late, which
   is why it refreshes itself and why it says how old the number it is showing
   already is.

   # IT COUNTS AND IT DOES NOT LIST

   K-22 was amended and `Personal data` lists people now, under four conditions
   — bounded, minimal, counted, named. This screen would fail two, and the
   decisive one is COUNTED: it refreshes on a timer, so there is no moment at
   which anybody asked for it and nothing to record a purpose against. A roll of
   who is online, arriving every few seconds unbidden, is the browse with the
   whole of what makes a listing defensible missing.

   So the answer has no names in it, and this screen has nothing to draw them
   with even if one arrived. The number is the whole report, and an operator who
   needs a name has one already — or has the listing, which asks what they are
   looking for and writes down that they asked.

   # THE WINDOW IS NOT WRITTEN IN THIS FILE

   "Seen in the last five minutes" is what the number MEANS, and it comes back
   from the server beside it (K-16), for the same reason the item analysis's
   thresholds do: an interface holding its own copy of a definition keeps
   describing the old one for as long as nobody notices.

   # WHY THE COUNTS DO NOT ADD UP, AND WHY THAT IS NOT A BUG

   Somebody studying in two schools is present in both and is one person on the
   platform. So the total is its own number rather than a sum, and the screen
   says so where somebody would otherwise reach for a calculator.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { txt, language } from '../../assets/language.js';

/* HOW OFTEN THIS ASKS AGAIN. It is deliberately slower than the heartbeat it
   watches: the server writes a session's last-seen at most once a minute, so
   asking every five seconds would draw the same number four times and cost
   twelve reads a minute for it. Fifteen seconds is fast enough that the screen
   feels live and slow enough that it is not lying about its own resolution. */
const EVERY = 15000;

export default async function presence(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('Who is here')) + '</h1>' +
      '<p>' + esc(txt('People signed in and seen a moment ago, by school. This is the one number in the console that comes from the sessions table rather than from the event stream — presence is the question where being overwritten is the point, because nobody asks who was online last March.')) + '</p>' +
    '</header>' +

    /* NOTHING HERE IS A LIVE REGION, and that is a decision rather than an
       oversight. Every other screen in this console marks its answer
       `aria-live="polite"` because it redraws when somebody asks it to; this one
       redraws every fifteen seconds whether anybody asked or not, and a polite
       region would read the whole report out four times a minute, over the top
       of whatever was being read.

       The freshness line is not one either, for the same reason and less
       obviously: its timestamp changes on every pass, so `role="status"` there
       would announce a new clock reading every fifteen seconds — which is the
       same interruption wearing a smaller sentence. What announces this screen
       is the router naming it on arrival, once. */
    '<div id="body"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const body = el.querySelector('#body');

  let timer = null;
  await draw();
  timer = setInterval(draw, EVERY);

  /* THE TIMER STOPS WHEN THE SCREEN DOES. Without this, leaving for the funnel
     leaves a request running every fifteen seconds for as long as the tab is
     open — invisible, and exactly the kind of thing that is discovered in a
     log six months later. */
  return { title: section.name, el, onLeave: () => clearInterval(timer) };

  async function draw() {
    let answer;
    try {
      answer = await get('/console/api/v1/watch/presence');
    } catch (e) {
      /* A READ THAT FAILED IS NOT AN EMPTY PLATFORM. Nobody being here is a
         real answer that looks exactly like this, so the failure has to replace
         the numbers rather than be shown as zero people. */
      body.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) +
        '</p></section>';
      return;
    }

    const schools = answer.schools || [];
    const minutes = Math.round((answer.window_seconds || 0) / 60);
    const cadence = Math.round((answer.cadence_seconds || 0) / 60);

    body.innerHTML =
      '<section class="block">' +
        '<div class="block-top"><h2>' + esc(txt('On the platform')) + '</h2></div>' +
        '<span class="here-total">' + (answer.everywhere || 0) + '</span>' +
        /* TWO NUMBERS IN ONE SENTENCE, AND BOTH ARE HOLES. It was assembled —
           a window, a plural `s` chosen by hand, a cadence, another plural —
           which is the "1 trilhas" shape twice in one paragraph. Four cases,
           because both numbers can be one and each of the two languages
           agrees differently. */
        '<p class="aside">' +
          (minutes === 1 ? txt('Seen in the last minute.') : txt('Seen in the last %w minutes.').replace('%w', minutes)) +
          ' ' +
          (cadence === 1 ? txt('A session says it is still in use at most once a minute, so this number is accurate to that and no better — it moves in steps rather than smoothly, and that is the heartbeat rather than the platform.') : txt('A session says it is still in use at most once every %c minutes, so this number is accurate to that and no better — it moves in steps rather than smoothly, and that is the heartbeat rather than the platform.').replace('%c', cadence)) +
        '</p>' +
      '</section>' +

      '<section class="block">' +
        '<div class="block-top"><h2>' + esc(txt('By school')) + '</h2></div>' +
        (schools.length === 0
          ? '<p class="none">' + esc(txt('There are no schools on this platform yet.')) + '</p>'
          : '<div class="here-all">' + schools.map(tile).join('') + '</div>') +

        /* THE TWO NUMBERS DISAGREE ON PURPOSE, said once, here, rather than
           discovered by somebody adding the tiles up. */
        (schools.length > 1
          ? '<p class="aside">' + txt('These do not add up to the number above, and should not: somebody studying in two schools is present in both and is <b>one person</b> on the platform.') + '</p>'
          : '') +
      '</section>' +

      '<section class="block">' +
        '<div class="block-top"><h2>' + esc(txt('What this does not count')) + '</h2></div>' +
        '<p class="aside">' + esc(txt(answer.not_counted || '')) + '</p>' +

        /* THE RULE ON THE SCREEN, because "why can I not see who" is a question
           an operator will have, and the answer is a rule rather than an
           omission somebody can be asked to fix.

           IT IS A SHARPER ANSWER SINCE K-22 WAS AMENDED, not a weaker one:
           there IS a place to look people up, and the reason it is not this one
           is that this page arrives on a timer with nobody having asked. */
        '<p class="aside">' + txt('And it does not say <b>who</b>. This page refreshes on its own, so there is no moment where somebody asked for it and nothing to record a reason against — which is what a list of people has to carry. Looking somebody up is <b>Personal data</b>, where every page is recorded with what was searched for.') + '</p>' +
      '</section>' +

      '<p class="freshness mono">' +
        esc(txt('Read at %t · refreshing every %n s')
          .replace('%t', clock(answer.as_of))
          .replace('%n', Math.round(EVERY / 1000))) + '</p>';
  }
}

/* One school, and the number is the tile rather than a line in a table. A
   table of two columns and four rows is a table; this is four numbers somebody
   glances at. */
function tile(school) {
  return '<div class="here' + (school.people > 0 ? ' here-live' : '') + '">' +
    '<span class="here-n mono">' + (school.people || 0) + '</span>' +
    '<span class="here-school">' + esc(school.name || '') + '</span>' +
    '<span class="here-slug mono">' + esc(school.slug || '') + '</span>' +
  '</div>';
}

/* The time the server answered, in the reader's own clock. A count of people
   present is worthless without knowing when it was counted, and a screen that
   silently stopped refreshing looks identical to a quiet Tuesday. */
function clock(when) {
  const at = new Date(when);
  if (Number.isNaN(at.getTime())) return txt('an unknown moment');
  /* THE READER'S OWN CLOCK, IN THE READER'S OWN LANGUAGE. `toLocaleTimeString()`
     with no argument is the BROWSER's locale, which is the defect the dates and
     the money on the other screens had: a 12-hour clock with `PM` on a screen
     otherwise in Portuguese. */
  return at.toLocaleTimeString(language() === 'pt' ? 'pt-BR' : 'en-GB');
}
