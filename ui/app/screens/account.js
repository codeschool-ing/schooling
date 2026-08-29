/* ==========================================================================
   My account.

   THE MENU HAS BEEN LINKING TO THIS SINCE THE MENU EXISTED. `#/account` was in
   the account dropdown and no route answered it, so the link led to the
   router's "page not found" — the same shape of defect as the sign-in screen's
   sentence about a recovery code that nothing issued: a promise the product
   makes and does not keep, visible to anybody who clicks.

   # THE SECOND FACTOR LIVES HERE AND NOT IN THE CONSOLE

   The console cannot host its own enrolment: reaching it needs a factor, so a
   screen for setting one up would be behind the door it opens. And the routes
   are the school host's — `/api/v1/second-factor/…`, on the same origin as this
   interface — which is exactly where a person already is when they sign in.

   The console's shut door already tells staff to "sign in at a school's
   address, then come back here". This is the screen they arrive at.

   # IT IS OFFERED TO EVERYBODY AND MANDATORY FOR NOBODY

   Mandatory is a property of the staff door (`RequireStaff`), not of the
   account. A student who wants a second factor may have one, which costs
   nothing to allow and is one less screen to write the day it stops being
   staff-only.

   # THE TEN CODES ARE SHOWN ONCE, AND THE SCREEN SAYS SO BEFORE SHOWING THEM

   There is no route that reads them back. A person who closes this without
   writing them down has an account with a second factor and no way past it,
   which is one lost phone from an edit to the database — so the warning is
   above the codes rather than under them.
   ========================================================================== */

import { esc } from '../text.js';
import { goTo } from '../routes.js';
import { now } from '../state.js';
import * as api from '../api.js';

export default async function account() {
  const el = document.createElement('div');
  el.className = 'view view-account';

  const session = now().session;
  if (!session) {
    goTo('/sign-in');
    return { title: txt('My account'), el };
  }

  el.innerHTML =
    '<header class="view-head">' +
      '<h1>' + txt('My account') + '</h1>' +
      '<p>' + txt('Who you are here, and how you get in.') + '</p>' +
    '</header>' +

    '<section class="block">' +
      '<div class="block-top"><h2>' + txt('You') + '</h2></div>' +
      '<dl class="facts">' +
        '<dt>' + txt('name') + '</dt><dd>' + esc(session.name || '') + '</dd>' +
        '<dt>' + txt('sign-in e-mail') + '</dt><dd>' + esc(session.email || '') + '</dd>' +
      '</dl>' +
    '</section>' +

    /* WHAT YOU BOUGHT AND UNTIL WHEN, which nothing on this platform could tell
       anybody until there was a route to ask. Filled after the first paint, like
       the second factor below it: the account's own facts are already in this
       browser and should not wait on a request. */
    '<section class="block" id="holding"></section>' +

    '<section class="block" id="factor"></section>' +

    /* CHANGING THE ADDRESS, WHICH UNTIL NOW NOTHING COULD DO.

       The banner can tell somebody their address refused our mail. Until this
       form that was the whole of it: a true sentence about a problem with no
       remedy anywhere on the platform, and the person who most needed to act
       had nothing to press. */
    '<section class="block">' +
      '<div class="block-top"><h2>' + txt('Change your e-mail') + '</h2></div>' +
      '<p>' + txt('Nothing changes until you follow the link we send to the new address — so a typo costs you a message nobody reads, and never your account.') + '</p>' +
      '<form id="change-email" novalidate>' +
        '<p class="field"><label for="new-email"><span>' + txt('new e-mail') + '</span>' +
          '<input id="new-email" name="email" type="email" autocomplete="email" required></label></p>' +
        /* THE PASSWORD IS ASKED FOR HERE AND THE SERVER REQUIRES IT. A stolen
           cookie lets somebody read; moving where the recovery mail goes is the
           step that turns it into a stolen account. */
        '<p class="field"><label for="change-password"><span>' + txt('your password') + '</span>' +
          '<input id="change-password" name="password" type="password" autocomplete="current-password" required></label></p>' +
        '<p><button class="btn btn-primary" type="submit">' + txt('Send the link') + '</button></p>' +
      '</form>' +
      '<p class="dim" id="change-note" aria-live="polite"></p>' +
    '</section>' +

    /* THE MENU'S HANDLER ALREADY SAID "same as the account screen's button",
       and there was no account screen and no button. Now there is one. */
    '<section class="block">' +
      '<div class="block-top"><h2>' + txt('This browser') + '</h2></div>' +
      '<p>' + txt('Signing out here ends this sitting. Your work stays where it is.') + '</p>' +
      '<p><button type="button" class="btn btn-ghost" id="sign-out">' +
        txt('Sign out') + '</button></p>' +
    '</section>';

  el.querySelector('#sign-out').addEventListener('click', async () => {
    await api.signOut();
    goTo('/sign-in');
  });

  /* ---------- changing the address ---------- */

  const changeForm = el.querySelector('#change-email');
  const changeNote = el.querySelector('#change-note');
  changeForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const button = changeForm.querySelector('button');
    button.disabled = true;
    changeNote.classList.remove('bad');
    changeNote.textContent = txt('Sending…');

    const wanted = el.querySelector('#new-email').value;
    try {
      await api.changeEmail(wanted, el.querySelector('#change-password').value);
      /* THE ADDRESS IS ECHOED BACK, because the commonest failure of this form
         is a second typo — and "we sent a link" without saying where is a
         sentence somebody can believe while waiting at the wrong inbox. */
      changeNote.textContent = txt('Check that inbox:') + ' ' + wanted;
      changeForm.reset();
    } catch (err) {
      changeNote.classList.add('bad');
      changeNote.textContent = reasonFor(err);
      button.disabled = false;
    }
  });

  /* EACH SENTENCE IS ITS OWN `txt('literal')` CALL and the switch picks between
     the RESULTS. `check-interface` reads this file for `txt('…')` and cannot see
     a literal inside an expression handed to it — written the other way these
     stop being policed and ship untranslated. */
  function reasonFor(err) {
    switch (err && err.code) {
      case 'address_refused': return txt('Our mail to that address has come back refused, so a link would not reach you there.');
      case 'same_address': return txt('That is already the address on this account.');
      case 'too_many': return txt('That is a lot of addresses in one hour. Try again later.');
      case 'unauthorized': return txt('That is not this account\'s password.');
      default: return txt('That did not work. Try again.');
    }
  }

  const factor = el.querySelector('#factor');
  paint();

  /* ---------- the second factor, in three states ---------- */

  function paint() {
    if (!session.secondFactor) return offerToSetOneUp();
    return showItIsOn();
  }

  function offerToSetOneUp() {
    factor.innerHTML =
      '<div class="block-top"><h2>' + txt('Two-factor sign-in') + '</h2></div>' +
      '<p>' + txt('A code from an app on your phone, as well as your password. Staff accounts cannot open the console without one.') + '</p>' +
      '<p><button type="button" class="btn btn-primary" id="start">' +
        txt('Set it up') + '</button></p>' +
      '<p class="notice" id="factor-note" role="alert"></p>';

    factor.querySelector('#start').addEventListener('click', async () => {
      const note = factor.querySelector('#factor-note');
      note.textContent = txt('Asking for a secret…');
      try {
        askForTheCode(await api.startSecondFactor());
      } catch (e) {
        note.className = 'notice bad';
        note.textContent = e.message;
      }
    });
  }

  /* THE SECRET IS SHOWN AS TEXT AND AS A LINK, AND NOT AS A QR CODE.
     Drawing one means a QR encoder — a few hundred lines of bit-packing and
     error correction with no dependency to lean on, since nothing here is
     loaded from another origin (P-03). It is worth writing the day somebody
     enrols from a desktop with the app on a different phone; until then the
     link opens the app on the same device, and the secret can be typed. */
  function askForTheCode(started) {
    factor.innerHTML =
      '<div class="block-top"><h2>' + txt('Two-factor sign-in') + '</h2></div>' +
      /* `enrol-steps` AND NOT `steps`: `portal.css` owns `.steps`, where it is
         the row of section tabs at the top of a lesson. Styling it here for
         this list laid that row out as a column on every lesson screen. */
      '<ol class="enrol-steps">' +
        '<li>' + txt('Put this secret into your authenticator app.') +
          '<p class="secret mono" id="secret">' + esc(grouped(started.secret)) + '</p>' +
          '<p><a class="btn btn-ghost" href="' + esc(started.uri) + '">' +
            txt('Open it in the app on this device') + '</a></p>' +
        '</li>' +
        '<li>' + txt('Then type the six digits it shows.') +
          '<form id="confirm" class="inline-form" novalidate>' +
            '<label class="field">' +
              '<span>' + txt('authentication code') + '</span>' +
              '<input id="code" type="text" inputmode="numeric" autocomplete="one-time-code" ' +
                     'maxlength="6" required>' +
            '</label>' +
            '<button class="btn btn-primary" type="submit">' + txt('Turn it on') + '</button>' +
          '</form>' +
        '</li>' +
      '</ol>' +
      '<p class="notice" id="factor-note" role="alert"></p>';

    factor.querySelector('#confirm').addEventListener('submit', async (event) => {
      event.preventDefault();
      const note = factor.querySelector('#factor-note');
      const code = factor.querySelector('#code').value.trim();
      if (!code) return;

      note.className = 'notice';
      note.textContent = txt('Checking…');
      try {
        const codes = await api.enrolSecondFactor(started.secret, code);
        session.secondFactor = true;
        showTheCodes(codes, txt('Two-factor sign-in is on.'));
      } catch (e) {
        note.className = 'notice bad';
        note.textContent = e.message;
      }
    });
  }

  async function showItIsOn() {
    factor.innerHTML =
      '<div class="block-top"><h2>' + txt('Two-factor sign-in') + '</h2></div>' +
      '<p class="on">' + txt('It is on. Signing in asks for a code as well as your password.') + '</p>' +
      '<p class="dim" id="left">' + txt('Counting your recovery codes…') + '</p>' +
      '<p><button type="button" class="btn btn-ghost" id="reissue">' +
        txt('Replace the recovery codes') + '</button></p>' +
      '<p class="notice" id="factor-note" role="alert"></p>';

    const left = factor.querySelector('#left');
    try {
      const answer = await api.recoveryCodesLeft();
      left.textContent = answer.left === 1
        ? txt('One recovery code left.')
        : txt('Recovery codes left:') + ' ' + answer.left;
    } catch (e) {
      left.textContent = txt('Could not count your recovery codes.');
    }

    factor.querySelector('#reissue').addEventListener('click', async () => {
      const note = factor.querySelector('#factor-note');
      note.className = 'notice';
      note.textContent = txt('Making new ones…');
      try {
        showTheCodes(await api.reissueRecoveryCodes(), txt('These replace every code you had.'));
      } catch (e) {
        note.className = 'notice bad';
        note.textContent = e.message;
      }
    });
  }

  // THE WARNING IS ABOVE THE CODES. Under them it is read after the decision.
  function showTheCodes(codes, what) {
    factor.innerHTML =
      '<div class="block-top"><h2>' + txt('Your recovery codes') + '</h2></div>' +
      '<p>' + esc(what) + ' ' +
        '<strong>' + txt('Write these down now. They are shown once and cannot be shown again.') +
        '</strong> ' + txt('Each one gets you in without your phone, and works once.') + '</p>' +
      '<ul class="codes mono">' +
        codes.map((c) => '<li>' + esc(c) + '</li>').join('') +
      '</ul>' +
      '<p><button type="button" class="btn btn-ghost" id="copy">' +
        txt('Copy them') + '</button> ' +
        '<button type="button" class="btn btn-ghost" id="done">' + txt('I have them') + '</button></p>' +
      '<p class="notice" id="factor-note" role="status"></p>';

    factor.querySelector('#copy').addEventListener('click', async () => {
      const note = factor.querySelector('#factor-note');
      try {
        await navigator.clipboard.writeText(codes.join('\n'));
        note.textContent = txt('Copied.');
      } catch (e) {
        // A refused clipboard is not a failure of this screen: the codes are on
        // it, and selecting them is what a person does next.
        note.textContent = txt('Your browser would not copy them — select them instead.');
      }
    });
    factor.querySelector('#done').addEventListener('click', showItIsOn);
  }

  /* ---------- what you hold ---------- */

  const holding = el.querySelector('#holding');
  showHolding();

  async function showHolding() {
    holding.innerHTML =
      '<div class="block-top"><h2>' + txt('Your subscription') + '</h2></div>' +
      '<p class="dim">' + txt('Reading your subscription…') + '</p>';

    let held;
    try {
      held = await api.subscription();
    } catch (e) {
      /* NOT A BROKEN SCREEN. The rest of this page is about who somebody is and
         how they get in, and none of it depends on this answer. A subscription
         that could not be read says so and leaves everything above it alone. */
      holding.innerHTML =
        '<div class="block-top"><h2>' + txt('Your subscription') + '</h2></div>' +
        '<p class="dim">' + txt('This could not be read just now. Nothing has changed.') + '</p>';
      return;
    }

    /* THE HISTORY IS DRAWN IN BOTH BRANCHES, and the branch below is the one it
       would have been lost from. Somebody with no subscription may still have
       purchases — a checkout that errored, a Pix code that expired unpaid — and
       those are precisely the rows they came here to look at. */
    const bought = purchaseTable(held && held.purchases);
    const back = withdrawal(held && held.withdraw);

    if (!held || held.state === 'none') {
      holding.innerHTML =
        '<div class="block-top"><h2>' + txt('Your subscription') + '</h2></div>' +
        '<p class="dim">' + txt('You do not have one. The first course of every track is free, in full.') + '</p>' +
        '<p><a class="btn btn-ghost" href="#/subscribe">' + txt('See what a subscription opens') + '</a></p>' +
        back + bought;
      return;
    }

    const ends = held.paidThrough ? new Date(held.paidThrough) : null;
    const left = ends ? Math.ceil((ends - Date.now()) / 86400000) : null;

    holding.innerHTML =
      '<div class="block-top"><h2>' + txt('Your subscription') + '</h2></div>' +
      '<dl class="facts">' +
        '<dt>' + txt('opens') + '</dt><dd>' +
          (held.opens ? txt('every course, exam and certificate') : txt('nothing — it has run out')) +
        '</dd>' +
        (held.price
          ? '<dt>' + txt('paid') + '</dt><dd>' +
            esc(money(held.price.cents, held.price.currency)) + ' · ' +
            esc(termName(held.price.termMonths)) + '</dd>'
          : '') +
        (ends
          ? '<dt>' + txt('runs to') + '</dt><dd>' + esc(day(ends)) +
            (left !== null && left >= 0
              ? ' <span class="dim">' + esc(daysLeft(left)) + '</span>'
              : '') + '</dd>'
          : '') +
      '</dl>' +

      /* WHAT HAPPENS NEXT, SAID BEFORE IT HAPPENS. Nothing on this platform
         renews itself: every purchase is an instalment plan in the sense that a
         term is bought and at its end there is a new sale. Somebody who assumes
         otherwise loses access on a day nobody warned them about, and this is
         the one screen where the warning fits. */
      '<p class="dim">' + txt('This does not renew by itself. When the term ends, you buy another.') + '</p>' +
      (held.opens
        ? ''
        : '<p><a class="btn btn-primary" href="#/subscribe">' + txt('Subscribe') + '</a></p>') +
      back + bought;
  }

  return { title: txt('My account'), el };
}

/*
withdrawal is the window to change your mind, while somebody still has it.

  THE TERMS PROMISE THIS AND THE SCREEN SAID NOTHING. Whole amount back, no
  reason needed, within a window art. 49 of the Código de Defesa do Consumidor
  puts a floor of seven days under — and the terms of use print the number this
  platform actually offers. The one screen where a person looks at what they
  bought did not mention it at all, and the only address anywhere was in the
  footer of a marketing site they would have to leave the product to find.

  THE SCREEN HOLDS NO COPY OF THE COUNT, which is why nothing here changed when
  it became settable: the server sends a DATE. That was already the rule for a
  different reason — a legal deadline worked out from a browser's clock is not
  a deadline — and it happens to be the shape that survives the number moving.

  A right nobody can reach is worse than no right at all, because the document
  promising it is evidence.

  IT APPEARS ONLY WHILE THE DAYS ARE RUNNING, which the server decides — a
  legal deadline worked out from a browser's clock is not a deadline. Once
  they are gone a refund is discretionary, and a line inviting somebody to
  write about it would be an invitation to a message nobody can answer (N-05).

  THE DEADLINE IS A DATE AND NOT A COUNTDOWN. "3 days left" is stale the
  moment a tab sits open overnight; the day it runs to is true whenever it is
  read.
*/
function withdrawal(when) {
  if (!when || !when.until) return '';

  const until = new Date(when.until);
  if (Number.isNaN(until.getTime())) return '';

  return '<p class="withdraw">' +
    /* ONE LINE, HOWEVER LONG. `check-interface` reads a key with a regular
       expression that starts at the quote and ends at the closing one; a
       sentence split across a `+` is a sentence it cannot see, and an
       unseen sentence is one that ships untranslated without failing
       anything. This was written the other way first and was invisible. */
    esc(txt('Changed your mind? You have until {day} to undo this purchase and get the whole amount back, no reason needed.').replace('{day}', day(until))) +
    (when.email
      ? ' <a href="mailto:' + esc(when.email) + '">' + esc(when.email) + '</a>'
      : '') +
  '</p>';
}

/*
purchaseTable is everything somebody has bought, newest first.

  THE FACTS ABOVE IT ARE THE STATE AND THIS IS THE RECORD. "Runs to 12 March"
  is what somebody checks in passing; "in June you paid R$ 655,50 for a year in
  Pix, and it ran to June next year" is what they need when they are
  reconciling a card statement, questioning a charge, or simply trying to
  remember whether they renewed. The state cannot answer the second: it holds
  one price and one date, and the next purchase overwrites both.

  IT IS ONE LINE PER SALE AND NOT PER PAYMENT. An instalment plan is one
  purchase the issuer collects several times; a table with three rows of
  R$ 363,33 would be showing somebody three prices they never agreed to, and
  the server sends the checkout for exactly this reason.

  THE ROWS THAT WERE NEVER PAID ARE IN IT. A Pix code that expired is the thing
  somebody writes in about, and it still carries the address it was given — so
  the row hands it back rather than making them start a second checkout for one
  sale. It is dimmed and not coloured: most of them are somebody who opened the
  form and thought better of it, which is not a fault to warn about.

  EMPTY IS NOTHING AT ALL. A table with a header row and no body reads as a
  screen that failed to load, and the sentence above it has already said they
  have bought nothing.
*/
function purchaseTable(bought) {
  if (!Array.isArray(bought) || bought.length === 0) return '';

  const rows = bought.map((p) => {
    const paid = p.stage === 'paid';
    const through = p.paidThrough ? new Date(p.paidThrough) : null;
    const discounted = paid && p.listed > p.cents;

    return '<tr' + (paid ? '' : ' class="bought-open"') + '>' +
      '<th scope="row">' + esc(day(new Date(p.openedAt))) + '</th>' +
      '<td>' + esc(termName(p.termMonths)) + '</td>' +
      '<td>' + esc(howPaid(p.method, p.instalments)) + '</td>' +
      '<td class="bought-amount">' + esc(money(p.cents, p.currency)) +
        (discounted
          ? '<span class="bought-was">' + esc(money(p.listed, p.currency)) + '</span>'
          : '') +
      '</td>' +
      '<td>' +
        /* THREE ANSWERS AND NOT TWO, and the third is the one that was wrong.

           A PAID PURCHASE WITH NO DATE IS NOT AN UNFINISHED ONE. The log only
           started recording what a payment bought in `0043`, so every purchase
           made before it has a stage of `paid` and nothing to join — and the
           first version of this fell through to the stage word and told
           somebody their oldest, fully paid year was "not finished". It said
           that about the platform's first real sales. */
        (through ? esc(day(through))
          : paid ? '<span class="bought-stage">' + txt('not recorded') + '</span>'
          : '<span class="bought-stage">' + esc(stageName(p.stage)) + '</span>' +
            /* THE ADDRESS, ONLY WHILE IT CAN STILL BE PAID. An abandoned
               charge's link leads to a page saying it expired, which is a
               worse answer than none. */
            (p.stage === 'charged' && p.invoiceUrl
              ? ' <a href="' + esc(p.invoiceUrl) + '" rel="noopener">' + txt('finish paying') + '</a>'
              : '')) +
      '</td>' +
    '</tr>';
  }).join('');

  return '<div class="bought">' +
    '<div class="bought-scroll">' +
      '<table class="bought-table">' +
        '<caption>' + txt('Everything you have bought') + '</caption>' +
        '<thead><tr>' +
          '<th scope="col">' + txt('bought on') + '</th>' +
          '<th scope="col">' + txt('term') + '</th>' +
          '<th scope="col">' + txt('how') + '</th>' +
          '<th scope="col">' + txt('amount') + '</th>' +
          '<th scope="col">' + txt('access to') + '</th>' +
        '</tr></thead>' +
        '<tbody>' + rows + '</tbody>' +
      '</table>' +
    '</div>' +
  '</div>';
}

/* How it was paid, in one cell. Each branch is its own `txt('literal')` so
   `check-interface` can see it, and the split is spelled out because "12×" on
   its own is a number somebody has to work out the meaning of. */
function howPaid(method, instalments) {
  if (method === 'pix') return txt('Pix');
  if (instalments > 1) return txt('Card, {n}×').replace('{n}', instalments);
  return txt('Card, in one');
}

/* What became of a purchase that was never paid.

   `paid` MUST NOT REACH HERE and the caller is what keeps it out — a paid row
   shows the date it bought, or says the date was not recorded. It fell through
   to this once and the answer was "not finished", about a year somebody had
   paid for in full. */
function stageName(stage) {
  if (stage === 'charged') return txt('waiting for payment');
  if (stage === 'abandoned') return txt('not paid');
  return txt('not finished');
}

/* A date the reader's language writes, without a time on it: what somebody
   wants from "runs to" is a day, and an hour invites the question of which
   timezone it is in. */
function day(when) {
  const lang = document.documentElement.lang || 'en';
  try {
    return new Intl.DateTimeFormat(lang, { dateStyle: 'long' }).format(when);
  } catch (e) {
    return when.toISOString().slice(0, 10);
  }
}

/* HOW LONG IS LEFT, in whole days, and each branch is its own `txt('literal')`
   so `check-interface` can see them. One day is its own sentence because "1
   days" is the kind of thing that makes a paid product look unfinished. */
function daysLeft(n) {
  if (n === 0) return txt('today is the last day');
  if (n === 1) return txt('one day left');
  return txt('{n} days left').replace('{n}', n);
}

/* What a number of months is called. It is `screens/subscribe.js`'s function,
   copied deliberately rather than shared: two screens name a term, the strings
   are four words each, and the dictionary already holds all four.

   AND THE WORDING OF THIS COMMENT IS LOAD-BEARING, which is worth one line to
   say. `tools/bundle` links the interface line by line and refuses anything it
   cannot classify; a line that BEGAN with the word this sentence is avoiding
   read as a declaration and stopped the build. Prose wraps where it wraps, so
   the rule is not "do not mention it" but "do not let it start a line". */
function termName(months) {
  switch (months) {
    case 1: return txt('A month');
    case 12: return txt('A year');
    case 24: return txt('Two years');
    default: return months + ' ' + txt('months');
  }
}

/* An amount as the reader's language writes it, in the currency the server
   said — `screens/subscribe.js`'s, in cents for the same reason. */
function money(cents, currency) {
  const lang = document.documentElement.lang || 'en';
  const amount = (cents || 0) / 100;
  try {
    return currency
      ? new Intl.NumberFormat(lang, { style: 'currency', currency }).format(amount)
      : new Intl.NumberFormat(lang).format(amount);
  } catch (e) {
    return String(amount);
  }
}

// Five and five, which is how somebody reads a long string off a screen.
const grouped = (secret) => String(secret || '').replace(/(.{4})/g, '$1 ').trim();
