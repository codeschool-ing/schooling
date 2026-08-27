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

  return { title: txt('My account'), el };
}

// Five and five, which is how somebody reads a long string off a screen.
const grouped = (secret) => String(secret || '').replace(/(.{4})/g, '$1 ').trim();
