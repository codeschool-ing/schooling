/* ==========================================================================
   What is due, everywhere.

   # THE CARDS ARE COUNTED HERE AND ANSWERED THERE

   Each school's share links to that school's own practice screen, and that is
   the design rather than a shortcut. A question is answered where its catalogue
   lives: the paywall, the quarantine, the prose that explains it and the
   language it was written in are all the school's, and a drill at this address
   would be a second place all four of those had to be right.

   What this address does that no school's can is TELL YOU THE WHOLE OF IT — one
   number, and which schools it is spread across.

   # THE SCHOOLS ARE IN THE ORDER THE SERVER SENT

   Which is the order of what is most overdue, not alphabetical and not by size.
   The school somebody has been neglecting comes first, because that is the
   whole reason to look at this screen rather than at either school's own.

   # AND THE SENTENCE ABOUT WHAT THIS QUEUE IS COMES FROM THE SERVER

   A screen holding its own copy of "questions you have never answered are not
   here" would keep saying it after the rule changed. It is the same reason the
   thresholds travel with the numbers they produced (K-16).

   IT STILL GOES THROUGH `txt()`, and that is the one part of this arrangement
   that is easy to forget — it was forgotten here, and shipped: a page reading
   in Portuguese carried one English paragraph, under two translated ones.

   `check-interface` cannot catch it and says so in its own header: a server
   sentence arrives at run time, so no static scan can enumerate one. The
   mechanism is that it arrives in English, English is the key, and a dictionary
   entry translates it at the point of display. What the tool CAN see is the
   entry, which it will report as a translation nothing says — that report is
   the price of the only arrangement that works, and the dictionary says so
   beside the entry.
   ========================================================================== */

const esc = (s) => String(s ?? '')
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&#39;');

/* THE LINK IS BUILT FROM THE HOST THE SERVER SENT, and not from the school's
   slug and this address's domain. Deriving it would be a second copy of a rule
   `tenant_domains` already holds — and the copy is the one that is wrong the
   day a school gets a domain of its own. `/#/practice` is where that school's
   own queue lives. */
const practiceAt = (host) => 'https://' + encodeURI(String(host)) + '/#/practice';

/* How many, in words, because "1 card" reads as a placeholder somebody forgot
   to finish. */
function many(n) {
  return n === 1 ? txt('1 question') : txt('%n questions').replace('%n', String(n));
}

export function drawQueue(schools, due, about) {
  return '<section class="mine-head">' +
      '<h1>' + esc(txt('Due today')) + '</h1>' +
      '<p class="mine-count mono">' + esc(many(due || 0)) + '</p>' +
    '</section>' +

    '<ul class="school-list">' +
      schools.map(one).join('') +
    '</ul>' +

    said(about);
}

/* The server's sentence, translated at the point of display and drawn only when
   there is one — an empty paragraph with a rule above it is a screen that looks
   like it lost something. */
function said(about) {
  return about ? '<p class="mine-about">' + esc(txt(about)) + '</p>' : '';
}

function one(school) {
  const cards = school.cards || [];
  return '<li class="school">' +
    '<div class="school-top">' +
      '<h2>' + esc(school.school_name || school.school) + '</h2>' +
      '<span class="school-count mono">' + esc(many(cards.length)) + '</span>' +
    '</div>' +

    /* WHAT THE COURSES ARE, and not what the questions are. A question drawn
       here would be a question presented outside the screen that marks it —
       and the presentation is where the shuffle is recorded, so drawing one
       here would either be a card nobody can answer or a second place that
       has to record it. The courses say enough to decide whether to go. */
    '<p class="school-where mono">' + esc(courses(cards)) + '</p>' +

    '<a class="btn btn-primary" href="' + esc(practiceAt(school.host)) + '">' +
      esc(txt('Practise at')) + ' ' + esc(school.school) +
    '</a>' +
  '</li>';
}

/* The distinct courses a school's share touches, in the order they appear —
   which is the order of what is most overdue. Three at most and then a count:
   a student with cards in nine courses needs to know it is nine, not to read
   nine ids. */
function courses(cards) {
  const seen = [];
  cards.forEach((c) => {
    if (c.course && !seen.includes(c.course)) seen.push(c.course);
  });
  if (seen.length === 0) return '';
  if (seen.length <= 3) return seen.join(' · ');
  return seen.slice(0, 3).join(' · ') + ' · ' +
    txt('and %n more').replace('%n', String(seen.length - 3));
}

/* NOTHING DUE IS THE GOOD OUTCOME AND HAS TO LOOK LIKE ONE. An empty screen
   here is indistinguishable from one that failed to load, which is the same
   distinction the console's queue screen makes for the same reason. */
export function drawNothing(about) {
  return '<section class="mine-head">' +
      '<h1>' + esc(txt('Nothing due')) + '</h1>' +
      '<p class="mine-none">' +
        /* THE CHECKER READS A CONCATENATION NOW, so this is one long line
           because a long line is easier to read here — not because splitting it
           would hide it.

           IT USED TO HIDE IT. `txt('a ' + 'b')` matched nothing, and being
           invisible failed in both directions at once: the screen said English
           in every language, and the entry that would have translated it was
           reported STALE, so acting on the report deleted the fix. It cost this
           repository two strings, and the defence was this paragraph — a rule
           kept by whoever remembered reading it. `tools/check-interface` joins
           the literals itself now and asks for the same key the runtime asks
           for. A call with a VALUE in it is still invisible, and still must be:
           `txt('over ' + n)` is a key no dictionary can be written against.

           THIS COMMENT USED TO BE WRITTEN AROUND THE CHECKER rather than in
           plain syntax, because the checker scanned with a regular expression
           and did not know what a comment was: the example above was itself
           counted as an interface string, and it asked for the Portuguese of an
           ellipsis. It reads the comments out now, and this paragraph is what
           says so. */
        esc(txt('You have answered everything that came back today. Each school still has questions you have not seen yet.')) +
      '</p>' +
    '</section>' +
    said(about);
}

/* NO FORM, AND NO LIST OF SCHOOLS. Signing in is a school's — it is the school
   that knows who its students are — and a personal address that greeted an
   anonymous visitor with a directory of schools would have stopped being
   personal. What is missing here is a session, not a menu. */
export function drawSignedOut() {
  return '<section class="mine-head">' +
      '<h1>' + esc(txt('Sign in at your school')) + '</h1>' +
      '<p class="mine-none">' +
        esc(txt('This page is yours, so it needs to know who you are. Sign in at any school you study at and come back — one sign-in covers all of them.')) +
      '</p>' +
    '</section>';
}

/* AND A READ THAT FAILED IS NOT AN EMPTY QUEUE. Telling somebody they have
   nothing to practise when the truth is that nothing answered is the one
   mistake this screen must not make: it is the answer they would act on. */
export function drawFailure() {
  return '<section class="mine-head">' +
      '<h1>' + esc(txt('That could not be read')) + '</h1>' +
      '<p class="mine-none">' +
        esc(txt('Your queue is fine — this page could not reach it. Try again in a moment.')) +
      '</p>' +
    '</section>';
}

/* WHAT THE CONFIRMATION LINK LEFT BEHIND.

   TWO SENTENCES AND NOT FOUR. The server tells this screen whether the link
   worked and nothing else: never issued, already spent, expired, and issued for
   an address the account has since left all arrive as the same "no". Telling
   them apart would confirm to somebody guessing that a token is real, and would
   say nothing the person could act on.

   THE FAILURE DOES NOT OFFER A BUTTON, and that is deliberate rather than
   unfinished. Asking for another link means being signed in, and this address
   is the one somebody reaches by clicking a link in their mail — often on a
   phone with no session on it. A button that failed for half the people who saw
   it would be worse than a sentence telling them where the working one is. */
/* AND WHAT THE CHANGE LINK LEFT BEHIND, in three answers rather than two.

   `taken` is its own because a person can act on it and the other two are not
   the same instruction: "that link is no good" sends somebody looking for a
   broken link, when what they need is a different address. */
export function drawChanged(outcome) {
  if (outcome === 'yes') {
    return '<section class="mine-note is-good" role="status">' +
      '<p>' + esc(txt('That is your e-mail address now.')) + ' ' +
        esc(txt('We told the old one, and we will not write to it again.')) + '</p>' +
    '</section>';
  }
  if (outcome === 'taken') {
    return '<section class="mine-note is-bad" role="status">' +
      '<p>' + esc(txt('Somebody took that address while the link was in your inbox.')) + ' ' +
        esc(txt('Sign in at your school and pick another one.')) + '</p>' +
    '</section>';
  }
  return '<section class="mine-note is-bad" role="status">' +
    '<p>' + esc(txt('That link is no longer good.')) + ' ' +
      esc(txt('Sign in at your school and ask for another one.')) + '</p>' +
  '</section>';
}

export function drawConfirmed(worked) {
  if (worked) {
    return '<section class="mine-note is-good" role="status">' +
      '<p>' + esc(txt('Your e-mail address is confirmed.')) + '</p>' +
    '</section>';
  }
  return '<section class="mine-note is-bad" role="status">' +
    '<p>' + esc(txt('That link is no longer good.')) + ' ' +
      esc(txt('Sign in at your school and ask for another one.')) + '</p>' +
  '</section>';
}
