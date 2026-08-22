/* ==========================================================================
   History — who did what, to whom, when, and what it was before.

   THIS IS THE READ THAT MAKES THE OTHER SCREEN SAFE TO USE. An operator who can
   export and erase a person, and nobody who can see that they did, is one half
   of an arrangement. Every administrative write has recorded its actor since
   phase 0; until this screen the only way to read one back was a SQL client
   pointed at production, which is the same power with no gate and no record.

   # THREE QUESTIONS, AND EACH ONE IS AN INDEX

   Everything newest first, one actor's entries, everything done to one subject.
   The API refuses anything else — free text, a filter on the action, a date
   range — because each of those reads a table that only grows (K-21). The
   refusal arrives as a sentence and this screen shows it rather than swallowing
   it.

   Each question is an ADDRESS, not a control: `#/audit`, `#/audit/by/<actor>`,
   `#/audit/on/<kind>/<id>`. A filter somebody cannot link to is a filter they
   describe over the phone.

   # THE LIST IS METADATA AND THE ENTRY IS THE WHOLE THING

   `before` and `after` are the personal data in this table, so the list does not
   carry them and one entry does. That is the same shape as the personal-data
   screen — counts on the list, contents when somebody asks for exactly one —
   and here it is the API that enforces it, not this file.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, RequestError } from '../request.js';

/* ---------- the list ---------- */

export default async function history(section, filter = {}) {
  const el = document.createElement('div');
  el.className = 'view';

  const where = query(filter);

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Govern</span>' +
      '<h1>' + esc(heading(filter)) + '</h1>' +
      '<p>Every administrative action, newest first, with the person who took it ' +
      'against it. Nothing here can be edited: the table refuses an update and a ' +
      'delete, and a correction is a new entry.</p>' +
      (filter.actor || filter.kind
        ? '<p class="list-bar"><a class="btn btn-ghost" href="#/audit">Everything again</a></p>'
        : '') +
    '</header>' +

    '<section class="block">' +
      '<div class="block-top">' +
        '<h2>Entries</h2>' +
        '<span class="block-score mono" id="scope">…</span>' +
      '</div>' +
      '<div id="rows"><p class="checking">Reading…</p></div>' +
      '<p class="list-bar" id="more"></p>' +
    '</section>';

  const rows = el.querySelector('#rows');
  const more = el.querySelector('#more');
  const scope = el.querySelector('#scope');

  let table = null;
  let entries = 0;

  async function load(after) {
    let page;
    try {
      page = await get('/console/api/v1/audit' + where + (after ? sep(where) + 'after=' + encodeURIComponent(after) : ''));
    } catch (e) {
      /* A REFUSAL IS SHOWN AND NOT SWALLOWED. The API answers a question with no
         index behind it with a sentence saying which questions it does answer,
         and a screen that turned that into "something went wrong" would be
         hiding the only useful part. */
      rows.innerHTML = '<p class="none">' + esc(e instanceof RequestError
        ? e.message : 'the history could not be read') + '</p>';
      more.innerHTML = '';
      return;
    }

    scope.textContent = page.scope;

    if (!page.entries.length && !entries) {
      rows.innerHTML = '<p class="none">Nothing has been recorded here yet.</p>';
      more.innerHTML = '';
      return;
    }

    if (!table) {
      rows.innerHTML =
        '<div class="table-wrap"><table class="grid">' +
          '<thead><tr>' +
            '<th scope="col">When</th><th scope="col">Who</th>' +
            '<th scope="col">Did what</th><th scope="col">To</th>' +
          '</tr></thead><tbody></tbody>' +
        '</table></div>';
      table = rows.querySelector('tbody');
    }

    table.insertAdjacentHTML('beforeend', page.entries.map(row).join(''));
    entries += page.entries.length;

    /* THE COUNT SAYS "SO FAR" BECAUSE IT IS. A total would be a second query
       over the whole table on every page — the expensive half this screen is
       built to avoid — and a number that said 4,812 while showing fifty rows
       would be answering a question nobody asked. */
    more.innerHTML =
      (page.next
        ? '<button class="btn btn-ghost" type="button" id="show-more">Show more</button> '
        : '') +
      '<span class="list-count">' + entries + (entries === 1 ? ' entry' : ' entries') +
        (page.next ? ' so far' : '') + '</span>';

    const button = more.querySelector('#show-more');
    if (button) {
      button.addEventListener('click', () => {
        button.disabled = true;
        load(page.next);
      });
    }
  }

  await load('');
  return { title: heading(filter), el };
}

/* Each of the three list addresses, as the router hands them over. They are
   separate routes rather than one with an optional segment, because a route
   that means three things is a route whose bugs mean three things. */
export const byActor = (params) => history(null, { actor: params.actor });
export const onSubject = (params) => history(null, { kind: params.kind, subject: params.subject });

function query(filter) {
  if (filter.actor) return '?actor=' + encodeURIComponent(filter.actor);
  if (filter.kind) {
    return '?subjectKind=' + encodeURIComponent(filter.kind) +
           '&subject=' + encodeURIComponent(filter.subject);
  }
  return '';
}

const sep = (where) => (where ? '&' : '?');

function heading(filter) {
  if (filter.actor) return 'One person’s doing';
  if (filter.kind) return 'Everything done to one ' + filter.kind;
  return 'History';
}

function row(e) {
  const [name, address] = twoLines(e.actor);
  return '<tr>' +
    '<td class="mono nowrap"><a href="#/audit/entry/' + esc(e.id) + '">' +
      esc(when(e.occurredAt)) + '</a></td>' +
    '<td><a href="#/audit/by/' + esc(e.actorId) + '">' +
      '<span class="cell-main">' + esc(name) + '</span></a>' +
      (e.actorKind === 'system' ? '<span class="tag tag-quiet">system</span>' : '') +
      (address ? '<span class="cell-sub mono">' + esc(address) + '</span>' : '') + '</td>' +
    '<td class="mono">' + esc(e.action) + '</td>' +
    '<td><a href="#/audit/on/' + esc(e.subject) + '/' + esc(e.subjectId) + '">' +
      '<span class="cell-main">' + esc(e.subject) + '</span></a>' +
      '<span class="cell-sub mono">' + esc(short(e.subjectId)) + '</span></td>' +
  '</tr>';
}

/* `actor_label` is one denormalised string — "Ada Lovelace <ada@example.tld>",
   as `wrote()` assembles it — and on one line it is wide enough to push the
   fourth column off the side of the table. Two lines fit, and the name is the
   half somebody reads.

   IT IS A SPLIT AND NOT A PARSE. The column is deliberately free text written
   at the time of the action; a label in another shape is shown whole rather
   than mangled into a shape this screen prefers. */
function twoLines(label) {
  const at = label.indexOf(' <');
  if (at < 0 || !label.endsWith('>')) return [label, ''];
  return [label.slice(0, at), label.slice(at + 2, -1)];
}

/* ---------- one entry ---------- */

export async function entry(params) {
  const el = document.createElement('div');
  el.className = 'view';
  el.innerHTML = '<p class="checking">Reading…</p>';

  let deed;
  try {
    deed = await get('/console/api/v1/audit/' + encodeURIComponent(params.id));
  } catch (e) {
    el.innerHTML =
      '<header class="view-head"><h1>No such entry</h1>' +
      '<p>' + esc(e instanceof RequestError && e.status === 404
        ? 'Nothing is recorded under that number. History does not lose entries, so the number is wrong.'
        : e.message) + '</p>' +
      '<p class="list-bar"><a class="btn btn-ghost" href="#/audit">Back to the history</a></p>' +
      '</header>';
    return { title: 'No such entry', el };
  }

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Govern &middot; entry ' + esc(deed.id) + '</span>' +
      '<h1>' + esc(deed.action) + '</h1>' +
      '<p class="list-bar"><a class="btn btn-ghost" href="#/audit">Back to the history</a></p>' +
    '</header>' +

    '<section class="block">' +
      '<div class="block-top"><h2>What happened</h2>' +
        '<span class="block-score mono">' + esc(when(deed.occurredAt)) + '</span></div>' +
      '<div class="table-wrap"><table class="grid"><tbody>' +
        fact('Who', '<a href="#/audit/by/' + esc(deed.actorId) + '">' + esc(deed.actor) + '</a>' +
          (deed.actorKind === 'system' ? ' <span class="tag tag-quiet">system</span>' : '')) +
        fact('To', '<a href="#/audit/on/' + esc(deed.subject) + '/' + esc(deed.subjectId) + '">' +
          '<span class="mono">' + esc(deed.subject) + ' ' + esc(deed.subjectId) + '</span></a>') +
        fact('School', deed.school
          ? '<span class="mono">' + esc(deed.school) + '</span>'
          : '<span class="none">the platform, not a school</span>') +
        (deed.reason ? fact('Why', esc(deed.reason)) : '') +
        (deed.requestId ? fact('Request', '<span class="mono">' + esc(deed.requestId) + '</span>') : '') +
      '</tbody></table></div>' +
    '</section>' +

    /* THE TWO STATES, WHICH ARE WHY THERE IS A SCREEN PER ENTRY AT ALL.

       AN ABSENT SIDE IS REPORTED AND NOT INTERPRETED. A missing `before`
       usually means the thing did not exist yet and a missing `after` that it
       does not any more — but not always: an export records how much was handed
       over, which is not a state change at all and leaves one side empty for a
       third reason. So the screen says what the entry does and does not carry,
       and what that means is the reader's, who can see the action it is
       under. */
    '<section class="block">' +
      '<div class="block-top"><h2>What the value was</h2>' +
        '<span class="block-score mono">before &rarr; after</span></div>' +
      '<p class="list-count">A thing that did not exist yet has no before, and one that ' +
        'does not exist any more has no after. Not every action is a change of state, so an ' +
        'empty side is what was recorded rather than what happened.</p>' +
      '<div class="states">' +
        state('Before', deed.before) +
        state('After', deed.after) +
      '</div>' +
    '</section>';

  return { title: deed.action, el };
}

const fact = (name, value) =>
  '<tr><th scope="row">' + esc(name) + '</th><td>' + value + '</td></tr>';

function state(name, value) {
  const body = value === undefined || value === null
    ? '<p class="none">Nothing was recorded on this side.</p>'
    : '<pre class="state mono">' + esc(JSON.stringify(value, null, 2)) + '</pre>';
  return '<div><h3 class="eyebrow mono">' + esc(name) + '</h3>' + body + '</div>';
}

/* ---------- two small things ---------- */

// The whole instant, in UTC, because an audit read in one timezone and written
// in another is an audit two people disagree about.
function when(iso) {
  const at = new Date(iso);
  if (Number.isNaN(at.getTime())) return 'an unknown moment';
  return at.toISOString().replace('T', ' ').slice(0, 19) + 'Z';
}

// Enough of an id to recognise, and it is never the whole answer — the entry
// itself carries the whole thing.
const short = (id) => (id.length > 12 ? id.slice(0, 8) + '…' : id);
