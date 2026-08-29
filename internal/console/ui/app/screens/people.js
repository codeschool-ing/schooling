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

   # TWO WAYS IN, AND THEY ANSWER DIFFERENT QUESTIONS

   A WHOLE ADDRESS answers "this person who wrote to me, are they here?" — one
   person or none, and nothing is recorded, because nothing left and nobody was
   browsed.

   A FRAGMENT answers the question that was being asked all along and had no way
   to be: somebody writes in from an address that is not the one they signed up
   with, or signs their e-mail with a surname. That is a list, and K-22 refused
   it — "browsing personal data is what an audit cannot tell from working". The
   amendment is that an audit does not have to tell one read from another in
   order to make the difference visible: fifty rows, forty times in an
   afternoon, is a shape in a log, and a month of answering support is not.

   So the list is BOUNDED (a page, whose size the request does not choose),
   MINIMAL (the same four fields the lookup shows — a name, an address, when
   they arrived, whether they are seeded), COUNTED (an entry per page, carrying
   what was searched for and how many came back), and NAMED: this screen says
   what the list is for, above the field, in the server's own words. That last
   one is the only part of the arrangement that reaches somebody BEFORE they
   type.

   WHAT THE LIST DOES NOT DO is show anything about a person. Reading what is
   held is the block below, one at a time; taking a copy of it is the export,
   recorded against a name; erasing still asks for that person's address to be
   typed. None of those moved, and the last of them was written for exactly this
   day — "an erasure reached by one click from a list somebody was scrolling"
   was a danger this console did not have when the sentence was written.

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
        '<span class="list-count">One person, or none.</span>' +
      '</form>' +
    '</section>' +

    /* AND THE SECOND WAY IN, BELOW THE FIRST. The order is the argument: an
       exact address is what an operator has most of the time and it records
       nothing, so it is what the screen offers first. The list is underneath
       because it is the larger act, not because it is a lesser one. */
    '<section class="block">' +
      '<div class="block-top">' +
        '<h2>Or look for somebody</h2>' +
        '<span class="block-score mono">a page at a time</span>' +
      '</div>' +

      // WHAT THIS IS FOR, FROM THE SERVER. It is the one protection that
      // reaches somebody before they type, so it lives beside the rule it
      // describes rather than in a screen that can drift from it. Filled in
      // after the first search, because that is when the server has spoken.
      '<p class="aside" id="about-list">Anything in an address or a name — a fragment ' +
      'is enough, and nothing at all lists everybody, newest first. Every page is ' +
      'recorded with your name, what you searched for and how many came back.</p>' +

      '<form id="search" class="list-bar" novalidate>' +
        '<label class="search">' +
          '<span class="visually-hidden">Part of an address or a name</span>' +
          '<input id="words" type="search" autocomplete="off" spellcheck="false" ' +
                 'placeholder="silva, or @gmail.com, or nothing">' +
        '</label>' +
        '<button class="btn btn-ghost" type="submit">Look</button>' +
      '</form>' +
      '<div id="matches" aria-live="polite"></div>' +
    '</section>' +

    '<div id="answer" aria-live="polite"></div>';

  const answer = el.querySelector('#answer');
  const field = el.querySelector('#email');
  const matches = el.querySelector('#matches');
  const words = el.querySelector('#words');

  el.querySelector('#find').addEventListener('submit', async (event) => {
    event.preventDefault();
    await look(field.value.trim());
  });

  el.querySelector('#search').addEventListener('submit', async (event) => {
    event.preventDefault();
    await list(words.value.trim(), null);
  });

  /* THE LIST, AND EVERY PAGE OF IT IS A REQUEST THE SERVER RECORDS.

     "Show more" APPENDS RATHER THAN REPLACING, because the pages are one act:
     somebody reading page four is still looking for the person they were
     looking for on page one, and a table that threw away what they had already
     read would make them page back through rows the server counted again. */
  async function list(query, cursor) {
    if (!cursor) matches.innerHTML = '<p class="checking">Looking…</p>';

    let page;
    try {
      const at = new URLSearchParams();
      if (query) at.set('q', query);
      if (cursor) {
        at.set('before', cursor.before);
        at.set('beforeId', cursor.beforeId);
      }
      page = await get('/console/api/v1/people/list?' + at.toString());
    } catch (e) {
      matches.innerHTML = '<p class="none">' + esc(e.message) + '</p>';
      return;
    }

    // The server's own sentence about what this is, once it has said it.
    if (page.about) el.querySelector('#about-list').textContent = page.about;

    const found = page.people || [];
    if (!cursor && found.length === 0) {
      matches.innerHTML = '<p class="none">' + esc(page.none || 'Nobody matches that.') + '</p>';
      return;
    }

    if (!cursor) {
      matches.innerHTML =
        '<div class="table-wrap"><table class="grid">' +
          '<thead><tr>' +
            '<th scope="col">Who</th><th scope="col">Signed up</th>' +
          '</tr></thead><tbody></tbody>' +
        '</table></div>' +
        '<p id="more"></p>';
    }

    matches.querySelector('tbody').insertAdjacentHTML('beforeend', found.map(match).join(''));

    /* HOW MANY ARE ON THE SCREEN, AND NEVER HOW MANY THERE ARE. A total would
       be a second query over the whole table — and it would answer a question
       nobody asked while telling somebody exactly how many people this platform
       has, from a screen whose whole defence is that it shows the minimum. */
    const showing = matches.querySelectorAll('tbody tr').length;
    matches.querySelector('#more').innerHTML =
      (page.before
        ? '<button class="btn btn-ghost" type="button" id="show-more">Show more</button> '
        : '') +
      '<span class="list-count">' + showing + (showing === 1 ? ' person' : ' people') +
        (page.before ? ' so far' : '') + '</span>';

    const button = matches.querySelector('#show-more');
    if (button) {
      button.addEventListener('click', () => {
        button.disabled = true;
        return list(query, { before: page.before, beforeId: page.beforeId });
      });
    }

    /* A ROW OPENS THE PERSON THROUGH THE SAME PATH A TYPED ADDRESS DOES, by
       address and not by id. Not for tidiness: the lookup is what fetches what
       is held and paints the export and erase blocks, so a second way of
       opening somebody would be a second place for those to fall out of step. */
    matches.querySelectorAll('button[data-email]').forEach((one) => {
      one.addEventListener('click', () => {
        field.value = one.dataset.email;
        return look(one.dataset.email);
      });
    });
  }

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
          'Recorded, with your name against it. ' +
          /* THE OTHER SCREEN ABOUT THIS PERSON. What they have — plan, progress,
             exams, certificates — is a read that is not an export, and somebody
             about to erase an account usually wants to look at it first. */
          '<a class="btn btn-ghost" href="#/record/' + person.id + '">Their record</a>' +
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

/* ONE MATCH — a name, an address, the day they arrived, and nothing else.

   THE FOUR FIELDS ARE THE WHOLE OF WHAT MAKES THIS LIST DEFENSIBLE, so the row
   is deliberately dull: no country, no plan, no progress, nothing that would
   make scrolling this worth doing for its own sake. A column added here is a
   change to the decision and not to a table.

   THE WHOLE ROW IS A BUTTON rather than a link, because opening somebody is a
   request this screen makes and not an address it navigates to — and because a
   button is what a keyboard reaches, which is also what makes the scrolling
   table above reachable at all. */
function match(one) {
  return '<tr>' +
    '<td>' +
      '<button type="button" class="btn-plain" data-email="' + esc(one.email) + '">' +
        '<span class="cell-main">' + esc(one.name || '—') +
          (one.synthetic ? '<span class="tag tag-quiet">synthetic</span>' : '') +
        '</span>' +
        '<span class="cell-sub mono">' + esc(one.email) + '</span>' +
      '</button>' +
    '</td>' +
    '<td>' + esc(day(one.createdAt)) + '</td>' +
  '</tr>';
}
