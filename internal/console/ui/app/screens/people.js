/* ==========================================================================
   Personal data — find a person, see what is held, export it, erase them.

   THIS IS AN OBLIGATION AND NOT A FEATURE. Somebody writes in and asks what is
   held about them, or asks to be forgotten. Until this screen existed the only
   way to answer was a SQL client pointed at production — the same power with no
   gate and no record.

   IT IS IN `Govern` AND NOT IN `Operate`, and the difference is who the screen
   is about. Operating is done TO a student: changing a plan, opening a record.
   This is done FOR one, because they asked, and the entry it writes is about
   the person doing it.

   # IT ASKS FOR A WHOLE ADDRESS AND SHOWS ONE PERSON

   No list, no partial match, and the API refuses to provide either (K-22). A
   search is not a lookup: typing `@example.tld` and reading the answer is
   browsing people, which an audit trail cannot tell apart from working.

   # NOTHING HERE DECIDES WHAT IS ALLOWED

   The erase block is hidden from a read-only role because a control that always
   fails is a bad screen — but hiding it is not the check. The API refuses, and
   there is a test for that. A screen that is the only thing standing between a
   role and an action is a screen away from being bypassed with a terminal.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, post, RequestError } from '../request.js';
import { mayAct } from '../session.js';

export default async function people(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Govern</span>' +
      '<h1>Personal data</h1>' +
      '<p>What is held about one person, handed to them, or removed. ' +
      'Both of the last two are recorded with your name against them — an ' +
      'export is a read that leaves this system, and the record of who took it ' +
      'has to already exist by the time anybody asks.</p>' +
    '</header>' +

    '<section class="block">' +
      '<div class="block-top">' +
        '<h2>Find somebody</h2>' +
        '<span class="block-score mono">exact address</span>' +
      '</div>' +
      '<form id="find" class="list-bar" novalidate>' +
        '<label class="search">' +
          '<span class="visually-hidden">The whole address</span>' +
          '<input id="email" type="email" autocomplete="off" spellcheck="false" ' +
                 'placeholder="somebody@example.tld" required>' +
        '</label>' +
        '<button class="btn btn-primary" type="submit">Look up</button>' +
        '<span class="list-count">There is no search here, only a lookup.</span>' +
      '</form>' +
    '</section>' +

    '<div id="answer" aria-live="polite"></div>';

  const answer = el.querySelector('#answer');
  const field = el.querySelector('#email');

  el.querySelector('#find').addEventListener('submit', async (event) => {
    event.preventDefault();
    await look(field.value.trim());
  });

  async function look(email) {
    if (!email) return;
    answer.innerHTML = '<p class="checking">Looking…</p>';

    let person;
    try {
      person = await get('/console/api/v1/people?email=' + encodeURIComponent(email));
    } catch (e) {
      answer.innerHTML = '<section class="block"><p class="none">' +
        (e instanceof RequestError && e.status === 404
          ? 'No account at that address.'
          : esc(e.message)) + '</p></section>';
      return;
    }

    let held;
    try {
      held = await get('/console/api/v1/people/' + person.id + '/held');
    } catch (e) {
      answer.innerHTML = '<section class="block"><p class="none">Found them, but could not ' +
        'count what is held: ' + esc(e.message) + '</p></section>';
      return;
    }
    paint(person, held);
  }

  function paint(person, held) {
    /* THE COUNTS AND NOT THE CONTENTS. Reading the rows is the export, and the
       export is recorded — a screen that showed them would be an export nobody
       signed for. */
    const carrying = Object.entries(held.tables)
      .filter(([, count]) => count > 0)
      .sort(([a], [b]) => a.localeCompare(b));

    // Each number pluralised by ITSELF: written as one expression this read
    // "562 rows across 18 table", pluralising the tables by whether there were
    // any rows at all — right for exactly the case nobody looks at.
    const plural = (n, word) => n + ' ' + word + (n === 1 ? '' : 's');

    const rows = carrying.map(([table, count]) =>
      '<tr><td><span class="cell-main mono">' + esc(table) + '</span></td>' +
      '<td class="num mono">' + count + '</td></tr>').join('');

    answer.innerHTML =
      '<section class="block">' +
        '<div class="block-top">' +
          '<h2>' + esc(person.name) + (person.synthetic
            ? '<span class="tag tag-quiet">synthetic</span>' : '') + '</h2>' +
          '<span class="block-score mono">' + esc(person.email) + '</span>' +
        '</div>' +
        '<p class="list-count">Arrived ' + esc(day(person.createdAt)) + ' &middot; ' +
          plural(held.total, 'row') + ' across ' + plural(carrying.length, 'table') + '</p>' +

        (rows
          ? '<div class="table-wrap"><table class="grid">' +
              '<thead><tr><th scope="col">Table</th><th scope="col" class="num">Rows</th></tr></thead>' +
              '<tbody>' + rows + '</tbody>' +
            '</table></div>'
          : '<p class="none">Nothing is held about them beyond the account itself.</p>') +

        '<p class="list-count">' +
          '<a class="btn btn-ghost" href="/console/api/v1/people/' + person.id + '/export" download>' +
            'Export everything</a> ' +
          'Recorded, with your name against it.' +
        '</p>' +
      '</section>' +

      (!mayAct() ? '' :
      '<section class="block" id="erase-block">' +
        '<div class="block-top">' +
          '<h2>Erase them</h2>' +
          '<span class="block-score mono">cannot be undone</span>' +
        '</div>' +
        '<p class="list-count">It severs the person and leaves the statistics. ' +
          'The entry in the audit says who did it and how much went, and does not name them.</p>' +
        '<form id="erase" class="list-bar" novalidate>' +
          '<label class="search">' +
            '<span class="visually-hidden">Type their address to confirm</span>' +
            '<input id="confirm" type="email" autocomplete="off" spellcheck="false" ' +
                   'placeholder="type ' + esc(person.email) + ' to confirm" required>' +
          '</label>' +
          '<button class="btn btn-bad" type="submit">Erase</button>' +
        '</form>' +
        '<p class="signin-notice" id="erase-note" role="alert"></p>' +
      '</section>');

    const form = answer.querySelector('#erase');
    if (form) {
      form.addEventListener('submit', async (event) => {
        event.preventDefault();
        await forget(person, answer.querySelector('#confirm').value.trim());
      });
    }
  }

  async function forget(person, typed) {
    /* THE CONFIRMATION IS CHECKED BY THE API TOO, against the person in the
       path. This one exists so somebody who mistyped is told at once rather
       than by a 400 — the check that matters is the other one. */
    const note = answer.querySelector('#erase-note');
    if (!typed) return;

    try {
      await post('/console/api/v1/people/' + person.id + '/erase', { email: typed });
    } catch (e) {
      note.className = 'signin-notice bad';
      note.textContent = e.message;
      return;
    }

    answer.innerHTML =
      '<section class="block">' +
        '<div class="block-top"><h2>Erased</h2>' +
        '<span class="block-score mono">' + esc(person.email) + '</span></div>' +
        '<p class="list-count">The entry in the audit says who did it and how much went. ' +
        'It does not name them: an append-only table that recorded the address would ' +
        'be the last surviving copy of somebody who asked to be forgotten.</p>' +
      '</section>';
  }

  return { title: section.name, el };
}

const day = (iso) => {
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? 'an unknown day' : at.toISOString().slice(0, 10);
};
