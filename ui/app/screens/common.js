/* ==========================================================================
   Pieces that more than one screen uses.

   It exists so that two places do not compute the same number in two different
   ways — the same reason the vitrine's terminal reads `COURSES` instead of having
   the answers written by hand: no screen may contradict another, because they
   all read the same source.
   ========================================================================== */

import { trackById, trackPath } from '../catalog.js';
import { courseProgress, activeOption, now } from '../state.js';
import { esc } from '../text.js';
/* THE MODULE AND NOT THE NAME. `source.school` is `export let` and null until
   the API answers; a named import reads it once, which works in a browser and
   not in the offline bundle. `tools/bundle` refuses the other shape — see the
   note on the same import in `screens/subscribe.js`. */
import * as source from '../source.js';

/* The progress of a whole track, counted in SECTIONS and not in courses or
   lessons: a course with 48 topics and one with 11 are not worth the same, and a
   lesson can have one section or six. The section is the smallest unit of real
   work, and the only one that makes the bar move in proportion to the effort. */
export function trackProgress(t) {
  const path = trackPath(t, activeOption);
  let done = 0, total = 0;
  path.forEach((id) => {
    const p = courseProgress(id);
    total += p.total;
    done += p.done;
  });
  return { done: done, total, pct: total ? Math.round((done / total) * 100) : 0, courses: path.length };
}

export function bar(pct, label) {
  return '<span class="bar" role="img" aria-label="' + esc(label || pct + '%') + '">' +
    '<span class="bar-fill" style="width:' + pct + '%"></span></span>';
}

export const studentTrack = () => {
  const m = now().enrollment;
  return m ? trackById(m.trackId) : null;
};

export function empty(message) {
  const el = document.createElement('div');
  el.className = 'view screen-empty';
  el.innerHTML = '<p class="empty">' + esc(message) + '</p>';
  return el;
}

/* ---------- the video frame ----------

   ONE COMPONENT, because there were two and they drifted. The course screen
   used the vitrine's `.modal-video` — dashed border while the video is
   reserved, a dimmed play button, and the caption in small mono capitals along
   the bottom — and the lesson had a `.video-facade` of its own, which showed a
   solid border, no play button at all, and the caption centred in the middle of
   an empty box. The two say different things about the same state, and the
   lesson's said the weaker one: a grey rectangle with a sentence in it does not
   read as "a video is coming", it reads as something that failed to load.

   The class is named after where it first appeared rather than after what it
   is, which is why `modal-video` looks out of place on a lesson and is still
   the right name: `base.css` is the vitrine's stylesheet, kept syncable with
   it, so a portal-only copy would be a second thing to keep in step for no gain.

   THE FRAME EXISTS WITH NO VIDEO PUBLISHED, and that is the whole reason it is
   worth styling carefully. Today almost every one of them is empty; publishing
   the videos one at a time then fills them in without rearranging anybody's
   screen. */
export function videoFrame(id, { label, duration } = {}) {
  const badge = duration ? '<span class="video-duration mono">' + esc(duration) + '</span>' : '';
  if (!id) {
    return '<div class="modal-video is-empty" aria-hidden="true">' +
      '<span class="video-play"></span>' +
      '<span class="video-notice">' + txt('video coming soon') + '</span>' +
      badge +
      '</div>';
  }
  /* NO THUMBNAIL, AND THAT IS THE POINT OF THE FACADE.

     This used to render an `img` whose source was a thumbnail on `i.ytimg.com`,
     which a browser fetches on its own, before anybody clicks anything — handing
     YouTube the reader's address, their user agent, the video id and a `Referer`
     naming the school and the lesson. The paragraph under `playsOnClick` claimed
     the opposite ("a screen opens without asking YouTube for anything") eight
     lines below the line that did the asking.

     It had never actually leaked, because no video id is published yet and this
     branch is therefore unreachable — which is exactly what made it worth
     removing now rather than later. It was a leak scheduled for the day somebody
     publishes the first video, with a comment beside it saying it could not
     happen.

     A THUMBNAIL IS STILL WORTH HAVING, and when video ships it comes through
     this origin: fetched and cached by the server, served from the host that
     served the page. `tools/check-origin` is what will refuse the shortcut. */
  return '<button type="button" class="modal-video" data-video="' + esc(id) + '" ' +
    'aria-label="' + esc(label || txt('Watch')) + '">' +
    '<span class="video-play"></span>' +
    badge +
    '</button>';
}

/* The facade only becomes a player on a click, so a screen opens without asking
   YouTube for anything and a student who does not watch is not known to them at
   all. That sentence was written before it was true — `videoFrame` above used to
   request the thumbnail with the page — and `tools/check-origin` is what holds
   it now rather than this paragraph.

   THIS IS THE ONE FETCH THAT LEAVES THE ORIGIN, and it is declared there with
   its reason: a student who clicks play is asking for a YouTube player, and the
   video is on YouTube. Refusing it would remove the video rather than protect
   anybody, which is the difference between this and the thumbnail — nobody asked
   for the thumbnail.

   Bound to the screen element rather than delegated from main.js: the element is
   new on every render, so the listener goes with it. */
export function playsOnClick(el, title) {
  el.addEventListener('click', (e) => {
    const thumb = e.target.closest('[data-video]');
    if (!thumb || !thumb.dataset.video) return;
    const frame = document.createElement('div');
    frame.className = 'modal-video playing';
    frame.innerHTML = '<iframe src="https://www.youtube-nocookie.com/embed/' +
      encodeURIComponent(thumb.dataset.video) + '?autoplay=1&rel=0" ' +
      'title="' + esc(title) + '" allowfullscreen ' +
      'allow="accelerometer; autoplay; encrypted-media; picture-in-picture"></iframe>';
    thumb.replaceWith(frame);
  });
}

/* ==========================================================================
   THE SUBSCRIPTION INVITATION

   One block, used in the two places a student meets the paywall: the course
   they tried to open, and the plan screen. One place so the offer cannot say
   two different things, and so the day a payment provider arrives there is one
   button to change rather than two.

   THE ACTION IS AN E-MAIL, AND THAT IS NOT A PLACEHOLDER. There is no payment
   provider and no checkout; an "Assinar agora" that led nowhere would be the
   same lie as the button this replaces, only better dressed. A subscription is
   opened by a person today — see the console's record screen — so the invitation
   asks that person, and says so.

   IT NAMES THE COURSE in the subject, so whoever reads the mail knows what
   made somebody want to pay. That is the most useful thing this screen can
   collect while there is nothing to click.

   THE BENEFITS ARE NOT WRITTEN HERE. `window.FEATURES` already carries them,
   translated into all five languages, and `window.PLANS` says which belong to
   which plan. Re-typing them would be a second copy to keep in step with the
   pricing page — and the pricing page is the one that sells.
   ========================================================================== */


/* The plans' feature sentences carry counts, and this fills them in.

The placeholders survive translation because they are part of the KEY: each
   dictionary carries `{courses}` and `{tracks}` in its own word order, which a
   sentence cut into fragments could not do — French needs "Les 122 cours et les
   19 parcours", and a translator handed "All", "courses and", "tracks" has
   nowhere to put the second "les".

   IT RUNS AFTER THE TRANSLATION AND NOT AROUND IT, deliberately. Wrapping the
   lookup in a helper would hide `features[k]` from `tools/i18n/check.mjs`,
   which follows translation arguments statically and already knows that
   expression; it would have had to be taught a new one for no gain. Translate,
   then fill in the numbers. */
export const withCounts = (s) => s
  .replace('{courses}', COURSES.length)
  .replace('{tracks}', TRACKS.length);

/* WHERE THE INVITATION'S BUTTON GOES.

   IT WAS A `mailto:` AND CARRIED THE COURSE'S NAME. Somebody wrote to us and
   somebody opened the subscription by hand, which is what a platform with no
   gateway can do and is what this payment phase exists to end.

   THE COURSE'S NAME IS GONE WITH IT, and its absence is not an oversight: a
   subscription opens every course in every school, so naming the one somebody
   happened to be looking at would suggest they were buying that. The argument
   for it was to save a support conversation, and there is no longer a
   conversation to save. */
export function subscribeHref() {
  return '#/subscribe';
}

// The paying plan, or nothing when no plan is configured — the offline bundle
// and a local run both reach here with an empty window.PLANS.
const paidPlan = () => (window.PLANS || []).find((p) => p.id === 'student');

/*
shapesOf is the same money said two smaller ways.

	BOTH NUMBERS COME FROM THE SERVER AND NEITHER IS ASSUMED. `pixDiscount` and
	`instalments` ride down with the school beside the prices, so this computes
	arithmetic rather than policy — and a deployment that stopped discounting
	Pix, or capped the split at six again, says so here without anybody editing
	this file.

	IT DRAWS NOTHING IT CANNOT STATE. No school, no line; no discount, no Pix
	figure; a split of one, no instalment figure. The offline bundle reaches here
	with no school at all and gets the price alone, which is what it showed
	before this existed.

	THE ROUNDING IS THE SCREEN'S AND THE CHARGE IS THE SERVER'S. `Money.Split`
	distributes the odd cent across the early instalments; this divides and
	rounds, so a twelfth here can differ by a cent from a twelfth on the invoice.
	That is acceptable in a sentence whose job is to say "about this much a
	month" and would not be in the checkout, which is why the checkout does not
	compute it.
*/
function shapesOf(plan) {
  const school = source.school;
  if (!school) return '';

  const parts = [];

  const off = Number(school.pixDiscount) || 0;
  if (off > 0) {
    parts.push(txt('{amount} with Pix')
      .replace('{amount}', money(plan.price * (1 - off / 10000), plan.currency)));
  }

  const most = Number(school.instalments) || 0;
  if (most > 1) {
    parts.push(txt('or {count}× {amount}, with no interest')
      .replace('{count}', most)
      .replace('{amount}', money(plan.price / most, plan.currency)));
  }

  return parts.length
    ? '<p class="invite-shapes dim">' + esc(parts.join(' · ')) + '</p>'
    : '';
}

/* An amount as the reader's language writes it, in the school's currency.
   Falls back to the plain number when the currency is unknown, rather than
   inventing a symbol for it. */
function money(amount, currency) {
  const lang = document.documentElement.lang || 'en';
  try {
    return currency
      ? new Intl.NumberFormat(lang, { style: 'currency', currency }).format(amount)
      : new Intl.NumberFormat(lang).format(amount);
  } catch (e) {
    return String(amount);
  }
}

/* The block itself.

   IT TOOK A `courseName` AND NO LONGER DOES. The name went into the `mailto:`'s
   subject line, and nothing else here ever read it — so with the mail gone the
   parameter was an argument the one caller still passed and this function
   ignored, which reads as a bug the next time somebody looks. */
export function subscribeInvite() {
  const plan = paidPlan();
  const opens = (plan?.includes || [])
    .map((k) => (window.FEATURES || {})[k])
    .map((t) => (t ? withCounts(t) : t))
    .filter(Boolean);

  return '<section class="block invite">' +
    '<p class="invite-tag mono">' + esc(txt('part of the subscription')) + '</p>' +
    /* ONE STRING LITERAL. tools/i18n/check.mjs reads the source rather than
       running it, so joined fragments are a call it cannot follow. */
    '<p class="invite-lead">' + esc(txt('The first course of every track is free, in full. This one is part of the subscription, which opens every course, the final exams, the certificates and the material to download.')) + '</p>' +
    (opens.length
      ? '<ul class="invite-opens">'
        + opens.map((s) => '<li>' + esc(s) + '</li>').join('')
        + '</ul>'
      : '') +
    /* THE SCHOOL'S PRICE, IN THE SCHOOL'S CURRENCY, and one of the two
       divergences in this file. `R$` was written here beside a number that
       came from the portal's own `plans.js`, so every school on this platform
       quoted codeschool.ing's subscription in Brazilian reais.

       `Intl.NumberFormat` puts the symbol where that currency puts it and
       groups the digits the way the reader's language does — which is not one
       string with a prefix, in any of the five.

       A school with no price set names none: the sentence above already says
       what the subscription opens, and a made-up number is worse than no
       number. */
    /* ONE PRICE AND THREE WAYS TO LOOK AT IT, which is not a price table.

       The figure alone was the LARGEST number this platform can show, standing
       by itself: R$ 690. Beside it are the two that make it small — R$ 655,50
       on Pix, and twelve instalments of R$ 57,50, which is the number a
       Brazilian buyer compares against every other school's and the one that
       wins.

       THE SECOND TERM IS NOT HERE ON PURPOSE. The invitation exists to earn one
       click; choosing between a year and two years is a decision, and the
       subscribe screen already draws both side by side for somebody who is
       deciding. Two prices here invite comparison at the moment you want a
       choice. */
    (plan && plan.price
      ? '<p class="invite-price"><strong>' + esc(money(plan.price, plan.currency)) + '</strong>'
        + '<span class="invite-cycle dim">' + esc(txt(plan?.cycle)) + '</span></p>'
        + shapesOf(plan)
      : '') +
    /* THE BUTTON'S OWN WORDS CHANGED WITH WHAT IT DOES. "Ask for the
       subscription" was accurate while it opened a mail client — somebody
       asked, and somebody answered. It opens a checkout now, so it says the
       thing it does, and the note under it said "write to us and we will open
       it for your account", which stopped being true on the same commit. */
    '<a class="btn btn-primary invite-cta" href="' + subscribeHref() + '">'
      + esc(txt('Subscribe')) + '</a>' +
    '<p class="invite-note dim">' + esc(txt('You pick the term and how to pay on the next screen.')) + '</p>' +
  '</section>';
}
