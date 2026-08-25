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

import { drawQueue, drawNothing, drawSignedOut, drawFailure } from './queue.js';

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
