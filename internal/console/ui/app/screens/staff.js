/* ==========================================================================
   Who can open this console.

   # THE QUESTION THIS CONSOLE COULD NOT ASK ABOUT ITSELF

   `cmd/staff list` has printed this roster since phase 0, into a terminal
   beside the database. So the console could set what every student pays, erase
   a person, quarantine a question and read every entry in the audit — and could
   not answer "who else can do all of that". An access list nobody can see is an
   access list nobody reviews, and the row that matters on it is always the one
   nobody remembered was there.

   # IT IS NOT WHAT K-22 REFUSES

   That decision is about producing a page of STUDENTS from something somebody
   typed, and its argument is that browsing personal data cannot be told from
   working. It does not reach here: this is the platform's own access-control
   list, and there is no version of reviewing one that goes an address at a time
   — the whole question is who is on it that nobody thought to ask about.

   # AND THERE IS NO FORM, WHICH THE SCREEN SAYS OUT LOUD

   Granting lives in `cmd/staff`, which has to exist regardless: the first owner
   cannot be granted a role by a console that needs a role to open. A second
   door onto the same table would be a second thing to keep audited and in
   agreement, bought for the convenience of not opening a terminal on the rarest
   write this platform has. The sentence comes from the server, so somebody
   looking for the button finds the reason rather than concluding it was
   forgotten.

   # THE COLUMN WORTH READING IS THE LAST ONE

   Role and enrolment say what somebody CAN do. Neither says whether they have.
   A role granted a year ago and never used since is access nobody is missing,
   and it is the row an access review exists to find — so it is drawn as a
   finding rather than as a date, and the row is marked.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';

export default async function staff(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Govern</span>' +
      '<h1>Who can open this</h1>' +
      '<p>Everybody with a role on this platform, and everybody who has had ' +
      'one. A role opens nothing without a second factor, and neither says ' +
      'whether it has been used — which is the column an access review is ' +
      'actually for.</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">Reading…</p></div>';

  const body = el.querySelector('#body');

  let answer;
  try {
    answer = await get('/console/api/v1/staff');
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  const all = answer.staff || [];

  /* AN EMPTY ROSTER IS A DEFECT AND NOT AN EMPTY STATE. This page was opened by
     somebody holding a live staff row, so "nobody has a role" cannot be true —
     and it is a sentence somebody would act on. The server says so in its own
     words, because it is a statement about the system rather than about a page. */
  if (all.length === 0) {
    body.innerHTML = '<section class="block"><p class="none">'
      + esc(answer.impossible || '') + '</p></section>';
    return { title: section.name, el };
  }

  body.innerHTML =
    '<section class="block">' +
      /* THE SCROLL CONTAINER IS FOCUSABLE HERE AND IS NOT ON THE OTHER TABLES,
         and the difference is what is INSIDE them rather than a preference.

         `table-wrap` scrolls sideways — it is the console's one element allowed
         to, so the page never does — and a region that scrolls has to be
         reachable by keyboard. Everywhere else in this console the rows contain
         links: the history links to an entry, the record links to a person, and
         tabbing through them scrolls the box as a side effect. This table is six
         columns of facts with nothing to click, so there is nothing for a
         keyboard to land on and the container has to take the focus itself.

         WHICH MEANS IT NEEDS A NAME. A focusable box announced as "region" and
         nothing else is a stop on the tab order that says nothing about why it
         is there. `a11y-test` found this — the table went out without it. */
      '<div class="table-wrap" tabindex="0" role="region" ' +
        'aria-label="Everybody with a role on this platform">' +
      '<table class="grid">' +
        '<thead><tr>' +
          '<th scope="col">Who</th>' +
          '<th scope="col">Role</th>' +
          '<th scope="col">Can get in</th>' +
          '<th scope="col">Since</th>' +
          '<th scope="col">Let in by</th>' +
          '<th scope="col">Last opened this</th>' +
        '</tr></thead>' +
        '<tbody>' + all.map(row).join('') + '</tbody>' +
      '</table></div>' +
      '<p class="list-count">' + all.length
        + (all.length === 1 ? ' row' : ' rows') + '</p>' +
    '</section>' +

    '<section class="block">' +
      '<div class="block-top"><h2>Reading this list</h2></div>' +
      '<p class="aside">' + esc(answer.about_reviewing || '') + '</p>' +
    '</section>' +

    '<section class="block">' +
      '<div class="block-top"><h2>Why there is no form</h2></div>' +
      '<p class="aside">' + esc(answer.how_to_change_it || '') + '</p>' +
    '</section>';

  return { title: section.name, el };
}

function row(one) {
  const gone = Boolean(one.revoked_at);

  return '<tr>' +
    /* THE NAME READS AND THE ADDRESS IDENTIFIES, which is this console's
       two-line cell everywhere it shows a person. The address is the half that
       matters here: it is what `staff grant` and `staff revoke` take, so
       somebody acting on this row is copying that line. */
    '<td>' +
      '<span class="cell-main">' + esc(one.name || '—') +
        (gone ? '<span class="tag tag-quiet">left</span>' : '') +
      '</span>' +
      '<span class="cell-sub mono">' + esc(one.email) + '</span>' +
    '</td>' +

    // THE ROLE AS THE SERVER SAID IT. There are three, and a fourth would be a
    // decision about a person — drawn as itself rather than folded into the
    // nearest of the three, so it appears as a thing nobody has styled yet.
    '<td class="mono">' + esc(one.role) + '</td>' +

    '<td>' + access(one, gone) + '</td>' +

    '<td>' + esc(day(one.granted_at)) +
      (gone ? '<span class="cell-sub">until ' + esc(day(one.revoked_at)) + '</span>' : '') +
    '</td>' +

    /* NOBODY, SPELLED OUT. `staff.granted_by` is null for exactly one row in
       any deployment's life — the first owner, granted from a terminal by
       somebody who is not in this system — and a blank cell there reads as a
       field that failed to load. */
    '<td>' +
      (one.granted_by_email
        ? '<span class="cell-main">' + esc(one.granted_by_name || '—') + '</span>' +
          '<span class="cell-sub mono">' + esc(one.granted_by_email) + '</span>'
        : '<span class="none">nobody — the first owner</span>') +
    '</td>' +

    '<td>' + used(one, gone) + '</td>' +
  '</tr>';
}

/* WHETHER THE ROLE ACTUALLY OPENS ANYTHING, which is not the same fact as
   having one. The check is at the door: an account with a role and no second
   factor cannot reach a staff route, and there is no state in between. A screen
   that showed the role alone would describe access that does not exist. */
function access(one, gone) {
  if (gone) return '<span class="none">revoked</span>';
  if (!one.second_factor) {
    return '<span class="tag tag-warn">no second factor</span>';
  }
  return '<span class="tag tag-staff">yes</span>';
}

/* THE FINDING, RATHER THAN THE DATE. A role nobody has used is what somebody
   opens this screen to find, and a column of dates makes them do the
   subtraction — on the row that is easiest to skip past, because nothing about
   it looks wrong.

   NINETY DAYS IS THIS SCREEN'S OWN LINE and it is drawn, not enforced: nothing
   is refused by it and nothing is recorded against it, so it is a reading aid
   rather than a threshold a row was judged by (K-16). A number that decided
   something would belong beside the row it decided about. */
const QUIET_DAYS = 90;

function used(one, gone) {
  if (!one.last_opened_console) {
    return '<span class="tag tag-warn">never</span>' +
      (gone ? '' : '<span class="cell-sub">granted and not used</span>');
  }

  const when = new Date(one.last_opened_console);
  const days = Math.floor((Date.now() - when.getTime()) / 86400000);

  return '<span class="cell-main">' + esc(day(one.last_opened_console)) + '</span>' +
    (!gone && days >= QUIET_DAYS
      ? '<span class="cell-sub">' + days + ' days ago</span>'
      : '');
}

function day(iso) {
  if (!iso) return '—';
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? String(iso) : at.toLocaleDateString();
}
