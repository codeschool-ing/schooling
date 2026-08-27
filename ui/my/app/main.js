/* ==========================================================================
   The student's own place — boot.

   WHAT IS DIFFERENT ABOUT THIS BOOT is what it does NOT do. The study interface
   opens by asking for its school, its catalogue and its tracks; there is no
   school at this address, so there is nothing to ask and nothing to wait for.
   One request answers the whole screen.

   # THERE IS NO ROUTER

   One address, one screen. A fragment router here would be machinery for a
   choice nobody is offered — and the day this place holds the account, the
   certificates and the subscription is the day to add one, with three
   destinations to justify it rather than none.

   # SIGNED OUT IS AN ANSWER AND NOT AN ERROR

   The session cookie lives on the parent domain, so a student signed in at
   their school is signed in here. Somebody who is not gets a sentence rather
   than a form: there is no sign-in at this address, because signing in is a
   school's — it is the school that knows who its students are, and the school
   is the public website (N-04).

   AND IT DOES NOT LIST THE SCHOOLS. A personal address that greeted an
   anonymous visitor with a directory would have stopped being personal; what
   somebody at this address is missing is a session, not a menu.
   ========================================================================== */

import { drawQueue, drawNothing, drawSignedOut, drawFailure, drawConfirmed, drawChanged } from './queue.js';

const here = document.getElementById('here');

/* ---------- the theme ----------

   The study interface's key, so that the choice made at a school and the choice
   made here are the same word in two origins' storage. They cannot be the same
   VALUE — `localStorage` is per origin — but a student who ever opens the two
   side by side should at least find the same switch. */
const THEME = 'codeschool-theme';

const themeButton = document.getElementById('theme');
if (themeButton) {
  themeButton.addEventListener('click', () => {
    const light = document.documentElement.dataset.theme === 'light';
    if (light) {
      delete document.documentElement.dataset.theme;
    } else {
      document.documentElement.dataset.theme = 'light';
    }
    try {
      localStorage.setItem(THEME, light ? 'dark' : 'light');
    } catch (e) { /* private mode: the choice holds for this page and no longer */ }
  });
}

/* ---------- what the confirmation link left behind ----------

   THE LINK LANDS ON THIS HOST AND THE SERVER HAS ALREADY DEALT WITH IT. What
   arrives here is one word in the query string saying how it went, so this
   screen reads a fact rather than performing an action — which is why it runs
   before the request below and does not wait for it. Somebody clicking the link
   on a phone they have never signed in on is the ordinary case, and they must
   still be told it worked.

   THE PARAMETER IS REMOVED FROM THE ADDRESS AFTERWARDS. Left there, a refresh
   or a bookmark would say "your address is confirmed" a week later, about
   nothing that just happened — and `?confirmed=yes` in a copied URL would say
   it to somebody else entirely. */
function saySoIfALinkWasFollowed() {
  let outcome = null;
  try {
    outcome = new URLSearchParams(location.search).get('confirmed');
  } catch (e) { /* an address this browser will not parse says nothing */ }
  if (outcome !== 'yes' && outcome !== 'no') return;

  const note = document.createElement('div');
  note.innerHTML = drawConfirmed(outcome === 'yes');
  here.parentNode.insertBefore(note, here);

  try {
    history.replaceState(null, '', location.pathname);
  } catch (e) { /* the note is drawn either way, which is the part that matters */ }
}

saySoIfALinkWasFollowed();

/* AND THE SAME FOR A CHANGE LINK, which lands on this host for the same reason
   and is a different question: `confirmed` says an address was proved, `changed`
   says the account moved onto one. Two parameters and not one word with four
   values, because a stale bookmark carrying the wrong one would say something
   false rather than nothing. */
function saySoIfAnAddressChanged() {
  let outcome = null;
  try {
    outcome = new URLSearchParams(location.search).get('changed');
  } catch (e) { /* an address this browser will not parse says nothing */ }
  if (outcome !== 'yes' && outcome !== 'no' && outcome !== 'taken') return;

  const note = document.createElement('div');
  note.innerHTML = drawChanged(outcome);
  here.parentNode.insertBefore(note, here);

  try {
    history.replaceState(null, '', location.pathname);
  } catch (e) { /* the note is drawn either way, which is the part that matters */ }
}

saySoIfAnAddressChanged();

/* ---------- the one request ---------- */

async function show() {
  let answer;
  try {
    const response = await fetch('/api/v1/review', {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });

    /* 401 IS THE ORDINARY CASE ON A COLD BROWSER and is told apart from every
       other failure here, because the two need different sentences: one is
       "sign in", the other is "this is not your fault". */
    if (response.status === 401) {
      here.innerHTML = drawSignedOut();
      return;
    }
    if (!response.ok) {
      here.innerHTML = drawFailure();
      return;
    }
    answer = await response.json();
  } catch (e) {
    here.innerHTML = drawFailure();
    return;
  }

  const schools = answer.schools || [];
  here.innerHTML = schools.length === 0
    ? drawNothing(answer.about)
    : drawQueue(schools, answer.due, answer.about);
}

show();
