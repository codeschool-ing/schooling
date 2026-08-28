/* ==========================================================================
   The student record — what one person has, at each school.

   THE OTHER HALF OF WHAT `Personal data` LEFT OPEN. That screen answers "is
   this the right person, and how much is held about them", which is what
   somebody needs before erasing and nothing anybody needs before talking. This
   one answers the conversation that actually brings a person to write in: what
   am I paying for, how far did I get, did I pass, where is my certificate.

   # TWO SCREENS AND TWO LOOKUPS, ON PURPOSE

   Each is entered on its own, from its own place in the rail, and an operator
   answering a support message should not have to walk through the erasure
   screen to read somebody's plan. The form is the same shape in both because
   the rule is the same — a whole address, never a list (K-22) — and the
   sentence that refuses a partial one comes from the API in both cases, so
   there is one refusal and not two.

   Once found, the record is its own address: `#/record/<id>` survives a reload
   and can be pasted into a message.

   # IT IS PER SCHOOL AND SAYS SO (K-18)

   Progress, exams and certificates are school-scoped and a subscription is held
   for a scope; the account is not. So the record is a person, then a section
   per school they have anything in — and a school they have never touched is
   left out rather than drawn as four empty tables.

   # IT IS NOT AN EXPORT

   Counts, states, dates and titles: what somebody needs to hold a conversation.
   Not a note they wrote, not an answer they gave. Reading that is the export,
   and the export is audited.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, post, RequestError } from '../request.js';
import { goTo } from '../routes.js';
import { mayAct } from '../session.js';

/* ---------- the way in ---------- */

export default async function lookup(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Operate</span>' +
      '<h1>Student record</h1>' +
      '<p>What one person has, at each school: their plan, how far they have got, ' +
      'what they sat and what they were awarded. Reading it is not an export and ' +
      'is not recorded — what it shows is somebody&rsquo;s standing rather than ' +
      'their work.</p>' +
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
      '<p class="none" id="answer" aria-live="polite"></p>' +
    '</section>';

  const answer = el.querySelector('#answer');

  el.querySelector('#find').addEventListener('submit', async (event) => {
    event.preventDefault();
    const email = el.querySelector('#email').value.trim();
    if (!email) return;

    answer.textContent = 'Looking…';
    try {
      const person = await get('/console/api/v1/people?email=' + encodeURIComponent(email));
      goTo('/record/' + person.id);
    } catch (e) {
      answer.textContent = e instanceof RequestError && e.status === 404
        ? 'No account at that address.'
        : e.message;
    }
  });

  return { title: section.name, el };
}

/* ---------- one person's record ---------- */

export async function record(params) {
  const el = document.createElement('div');
  el.className = 'view';
  el.innerHTML = '<p class="checking">Reading…</p>';

  let it;
  try {
    it = await get('/console/api/v1/people/' + encodeURIComponent(params.id) + '/record');
  } catch (e) {
    el.innerHTML =
      '<header class="view-head"><h1>No such person</h1>' +
      '<p>' + esc(e instanceof RequestError && e.status === 404
        ? 'Nothing is held under that id.' : e.message) + '</p>' +
      '<p class="list-bar"><a class="btn btn-ghost" href="#/record">Look somebody up</a></p>' +
      '</header>';
    return { title: 'No such person', el };
  }

  const person = it.person;

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Operate</span>' +
      '<h1>' + esc(person.name) +
        (person.synthetic ? '<span class="tag tag-quiet">synthetic</span>' : '') + '</h1>' +
      '<p class="mono">' + esc(person.email) + ' &middot; arrived ' + esc(day(person.createdAt)) + '</p>' +
      '<p class="list-bar">' +
        '<a class="btn btn-ghost" href="#/record">Somebody else</a> ' +
        /* THE TWO SCREENS ABOUT ONE PERSON KNOW ABOUT EACH OTHER. An operator
           who has decided to erase somebody arrived at that decision here. */
        '<a class="btn btn-ghost" href="#/people">Personal data</a> ' +
        '<a class="btn btn-ghost" href="#/audit/on/account/' + esc(person.id) + '">' +
          'Everything done to them</a>' +
      '</p>' +
    '</header>' +

    /* WHAT THEY ARE PAYING FOR COMES FIRST AND IS NOT UNDER A SCHOOL. One
       subscription covers every school (N-02), and it is also the first thing
       asked on nearly every support message — so it sits above the schools
       rather than being hunted for inside one of them. */
    holding(it.holding) +

    (it.schools.length
      ? it.schools.map((s) => atSchool(s, person.id)).join('')
      : '<section class="block"><p class="none">They have nothing at any school: ' +
        'no plan, no progress, no exam, no certificate.</p></section>') +

    sittings(it.sittings);

  /* STARTING A VIEWING IS A REQUEST AND THEN A NAVIGATION, and the two are
     separate on purpose. The console cannot set a cookie for a school's host, so
     the server answers with a LINK and the operator's own browser follows it —
     which is also the only way the cookie lands where it has to.

     IT OPENS IN A NEW TAB. The console stays where it is: an operator who has
     just started looking at somebody usually wants both, and losing the console
     to a viewing would make stopping one harder than starting it. */
  el.addEventListener('click', async (event) => {
    const button = event.target.closest('[data-view]');
    if (!button) return;

    const said = button.parentElement.querySelector('.list-count');
    button.disabled = true;
    if (said) said.textContent = 'Starting…';
    try {
      const answer = await post('/console/api/v1/students/' +
        encodeURIComponent(button.dataset.person) + '/view/' +
        encodeURIComponent(button.dataset.view));

      /* `noopener` BECAUSE THE PAGE BEING OPENED IS A SESSION. Without it the
         new tab can reach back into this one through `window.opener`, and this
         one is the console. */
      globalThis.open(answer.link, '_blank', 'noopener');
      if (said) said.textContent = 'Opened in a new tab. It ends in half an hour, ' +
        'or when you press stop there.';
    } catch (e) {
      if (said) said.textContent = e.message;
    } finally {
      button.disabled = false;
    }
  });

  return { title: person.name, el };
}

function atSchool(s, personId) {
  return '<section class="block">' +
    '<div class="block-top">' +
      '<h2>' + esc(s.name) + '</h2>' +
      '<span class="block-score mono">' + esc(s.school) + '</span>' +
    '</div>' +

    /* SEEING WHAT THEY SEE, PER SCHOOL, because that is what a viewing is: a
       session on one school's host. It is offered here rather than beside the
       person's name for that reason — "view this student" would have to ask
       which school next, and the answer is already the heading above.

       IT IS HIDDEN FROM A READ-ONLY ROLE because a control that always fails is
       a bad screen. Hiding it is not the check — the API refuses, and there is a
       test for that. */
    (mayAct()
      ? '<p class="view-as"><button type="button" class="btn btn-ghost" ' +
          'data-view="' + esc(s.school) + '" data-person="' + esc(personId) + '">' +
          'See what they see</button>' +
        '<span class="list-count">Recorded with your name. Read-only, ends in half ' +
          'an hour, and they are not told.</span></p>'
      : '') +

    /* A PLAN HELD FOR THIS SCHOOL ALONE, WHICH TODAY IS NOBODY. N-02 made one
       subscription cover every school and it is held at scope `all`, so this
       line is empty for everyone — and the sentence says where to look rather
       than "no subscription", which would be false about most of the people it
       was drawn for. It stays because `scope` exists so this can narrow later
       (N-03), and the day it does, this is where the answer appears. */
    '<p class="list-count">' +
      (s.plan
        ? esc(s.plan) + ' &middot; <span class="mono">' + esc(s.state) + '</span>' +
          (s.paidThrough ? ' &middot; paid through ' + esc(day(s.paidThrough)) : '')
        : 'Nothing held for this school on its own — the subscription above covers every school.') +
    '</p>' +

    table('Courses', 'Nothing started here.', ['Course', 'Sections'], s.courses.map((c) =>
      '<tr><td><span class="cell-main mono">' + esc(c.course) + '</span></td>' +
      '<td class="num mono">' + c.sections + '</td></tr>')) +

    table('Exams', 'No paper sat here.', ['Paper', 'Sat', 'Result'], s.exams.map((e) =>
      '<tr><td><span class="cell-main mono">' + esc(e.subject) + '</span>' +
        '<span class="cell-sub mono">' + esc(e.scope) + '</span></td>' +
      '<td class="mono">' + esc(day(e.startedAt)) + '</td>' +
      '<td>' + verdict(e) + '</td></tr>')) +

    table('Certificates', 'Nothing awarded here.', ['Code', 'For', 'Issued'], s.certificates.map((c) =>
      '<tr><td><span class="cell-main mono">' + esc(c.code) + '</span></td>' +
      '<td>' + esc(c.title) + '</td>' +
      '<td class="mono">' + esc(day(c.issuedAt)) + '</td></tr>')) +
  '</section>';
}

/* ==========================================================================
   WHAT THEY ARE PAYING FOR, AND EVERYTHING THEY HAVE EVER BOUGHT.

   THE STATE AND THE RECORD ARE TWO ANSWERS AND AN OPERATOR NEEDS BOTH. The
   line at the top is what is true today — opens or does not, runs to this day,
   bought at this price — and it is one row that the next purchase overwrites.
   The table under it is what happened, and it is the half a support message is
   nearly always about: a charge on a statement, a Pix that was paid twice, a
   card that was split and shows as three lines at the bank.

   THE TABLE IS THE CHECKOUTS AND NOT THE LEDGER, and reading it as a ledger is
   the mistake it is drawn this way to prevent. An instalment plan is ONE sale
   the issuer collects several times; the ledger has a row per collection,
   keyed by the charge, and adding those up to answer "what did they pay" gets
   the right total and the wrong story every time. One line here is one sale.

   AND IT SHOWS WHAT WAS NEVER PAID. A checkout that stopped at `charged` is a
   Pix code somebody may still be about to pay — the row carries the address,
   so an operator can give it back rather than tell them to start again, which
   would open a second checkout for one sale.
   ========================================================================== */
function holding(h) {
  if (!h) {
    return '<section class="block">' +
      '<div class="block-top"><h2>Subscription</h2></div>' +
      '<p class="none">They have never bought anything, and never tried to.</p>' +
    '</section>';
  }

  const bought = h.purchases || [];
  const paid = bought.filter((p) => p.stage === 'paid');
  /* WHAT THEY HAVE SPENT, ADDED UP FROM THE SALES. Only the paid ones, and only
     when they are all in one currency: a sum across two is a number about
     nothing, and the honest answer there is no sum at all. */
  const currencies = new Set(paid.map((p) => p.currency));
  const spent = currencies.size === 1
    ? money(paid.reduce((n, p) => n + p.cents, 0), paid[0].currency)
    : null;

  return '<section class="block">' +
    '<div class="block-top">' +
      '<h2>Subscription</h2>' +
      '<span class="block-score mono">every school</span>' +
    '</div>' +

    '<p class="list-count">' +
      (h.state
        ? '<span class="tag ' + (h.opens ? 'tag-staff' : 'tag-warn') + '">' +
            esc(h.state) + '</span> ' +
          (h.opens ? 'opens every course' : 'opens nothing') +
          (h.paidThrough ? ' &middot; paid through ' + esc(day(h.paidThrough)) : '') +
          (h.price
            ? ' &middot; ' + esc(money(h.price.cents, h.price.currency)) +
              ' for ' + h.price.termMonths + ' months'
            : '') +
          /* NOTHING RENEWS ITSELF HERE, and an operator telling somebody their
             subscription will renew would be telling them something this
             platform does not do. */
          ' &middot; does not renew by itself'
        : 'No subscription — but they have tried to buy, below.') +
    '</p>' +

    table('Purchases',
      'Nothing bought, and nothing attempted.',
      ['Opened', 'Term', 'How', 'Amount', 'Access to', ''],
      bought.map((p) =>
        '<tr><td class="mono">' + esc(day(p.openedAt)) + '</td>' +
        '<td class="mono">' + p.termMonths + ' months</td>' +
        '<td>' + esc(howPaid(p)) + '</td>' +
        '<td class="num mono">' + esc(money(p.cents, p.currency)) +
          (p.listed > p.cents
            ? '<span class="cell-sub mono">of ' + esc(money(p.listed, p.currency)) + '</span>'
            : '') +
        '</td>' +
        /* A PAID PURCHASE WITH NO DATE IS NOT AN UNPAID ONE. The log only
           started recording what a payment bought in `0043`, so every sale
           before it has nothing to join — and the honest cell says so rather
           than a dash, which reads as "bought nothing". */
        '<td class="mono">' +
          (p.paidThrough ? esc(day(p.paidThrough))
            : p.stage === 'paid' ? '<span class="none">not recorded</span>'
            : '\u2014') +
        '</td>' +
        '<td>' + stage(p) + '</td></tr>')) +

    (spent
      ? '<p class="list-count">' + esc(spent) + ' across ' + paid.length +
        (paid.length === 1 ? ' paid purchase.' : ' paid purchases.') +
        ' Not the ledger: an instalment plan is one sale here and one row per ' +
        'collection there.</p>'
      : '') +
  '</section>';
}

/* HOW IT WAS PAID, SPELLED OUT. "12x" on its own is a number an operator has to
   work out the meaning of while somebody waits on the telephone. */
function howPaid(p) {
  if (p.method === 'pix') return 'Pix';
  return p.instalments > 1 ? 'Card, ' + p.instalments + '\u00d7' : 'Card, in one';
}

/* HOW FAR A PURCHASE GOT. A paid one is not tagged: it is the ordinary case and
   a tag on every row is a column of noise. The link is offered only while the
   charge can still be paid — an abandoned one leads to a page saying it
   expired, which is a worse answer than none. */
function stage(p) {
  if (p.stage === 'paid') return '';
  if (p.stage === 'charged') {
    return '<span class="tag tag-quiet">waiting</span>' +
      (p.invoiceUrl
        ? ' <a href="' + esc(p.invoiceUrl) + '" target="_blank" rel="noopener">invoice</a>'
        : '');
  }
  return '<span class="tag tag-quiet">' +
    esc(p.stage === 'abandoned' ? 'not paid' : 'not finished') + '</span>';
}

/* An amount in the currency the server said, in cents. `en-GB` and not the
   operator's locale: the console is one language and a figure that moved its
   separators between two staff members reading the same screen is a figure two
   people would read out differently. */
function money(cents, currency) {
  const amount = (cents || 0) / 100;
  try {
    return new Intl.NumberFormat('en-GB',
      { style: 'currency', currency: currency || 'BRL' }).format(amount);
  } catch (e) {
    return String(amount) + ' ' + String(currency || '');
  }
}

/* AN EXAM IN PROGRESS IS NOT A FAILED ONE. Drawing a blank where the verdict
   goes would read as "did not pass", which is the wrong thing to tell somebody
   who is sitting the paper right now. */
function verdict(e) {
  if (!e.handedInAt) return '<span class="tag tag-quiet">open</span>';
  if (e.passed === undefined || e.passed === null) return '<span class="none">not marked</span>';
  return '<span class="tag ' + (e.passed ? 'tag-staff' : 'tag-warn') + '">' +
    (e.passed ? 'passed' : 'failed') + '</span>' +
    (e.score === undefined || e.score === null ? '' : ' <span class="mono">' + e.score + '</span>');
}

function sittings(list) {
  const live = list.filter((s) => s.live).length;
  return '<section class="block">' +
    '<div class="block-top">' +
      '<h2>Sittings</h2>' +
      '<span class="block-score mono">' + live + ' live of ' + list.length + '</span>' +
    '</div>' +
    '<p class="list-count">One row per browser they have signed in on. The token is not ' +
      'here and never will be — this says how many and since when, not how to become them.</p>' +
    table('', 'They have never signed in.', ['Started', 'Last seen', 'From', ''], list.map((s) =>
      '<tr><td class="mono">' + esc(when(s.createdAt)) + '</td>' +
      '<td class="mono">' + esc(s.lastSeenAt ? when(s.lastSeenAt) : '—') + '</td>' +
      '<td class="detail">' + esc(s.userAgent || 'not said') + '</td>' +
      '<td>' + (s.live
        ? '<span class="tag tag-staff">live</span>'
        : '<span class="tag tag-quiet">' + (s.revokedAt ? 'ended' : 'expired') + '</span>') +
      '</td></tr>')) +
  '</section>';
}

/* A table, or a sentence saying there is nothing — never an empty grid with a
   header row, which reads as a screen that failed to load.

   THE SENTENCE IS WRITTEN AND NOT ASSEMBLED. Built from the heading it came out
   as "Nothing — courses.", which is a machine describing its own data
   structure at somebody who wanted to know whether this student had started
   anything. */
function table(name, nothing, columns, rows) {
  const head = name ? '<h3 class="eyebrow mono">' + esc(name) + '</h3>' : '';
  if (!rows.length) {
    return head + '<p class="none">' + esc(nothing) + '</p>';
  }
  return head +
    '<div class="table-wrap"><table class="grid"><thead><tr>' +
      columns.map((c) => '<th scope="col">' + esc(c) + '</th>').join('') +
    '</tr></thead><tbody>' + rows.join('') + '</tbody></table></div>';
}

const day = (iso) => {
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? 'an unknown day' : at.toISOString().slice(0, 10);
};

const when = (iso) => {
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? 'an unknown moment'
    : at.toISOString().replace('T', ' ').slice(0, 16) + 'Z';
};
