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
    holding(it.holding, person.id, it.refundable) +

    /* AND WHERE THE MONEY ACTUALLY MOVED, under the subscription because it is
       the same subject, and above the schools because it is nobody school's.

       IT IS DRAWN EMPTY AND FILLED AFTERWARDS, which makes it the one thing on
       this screen that asks twice. The record is one request on purpose — a
       person on the telephone is not read out in instalments — and this stays
       out of it because the ADJUSTMENT writes a row immediately, unlike a
       refund, so there has to be a way to re-read this table and nothing else.
       Folded into the record it would be either stale after every correction or
       a whole second record fetched to refresh one table. */
    '<section class="block" id="ledger"><div class="block-top"><h2>The books</h2></div>' +
      '<p class="checking">Reading…</p></section>' +

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

  /* THE THREE CHANGES, ON ONE LISTENER. Every form under the fold posts, says
     what happened in its own line, and — for the two that move a term —
     redraws the block above it from the answer rather than from what the page
     was holding when it loaded.

     IT IS DELEGATED RATHER THAN BOUND PER FORM, because that block is replaced
     wholesale after a change and listeners bound to the old markup would go
     with it. */
  /* CHOOSING WHICH SALE, from the line rather than from a list. The form is
     hidden until this runs, so there is no state in which it is standing open
     with no purchase in it — which would be a "Send it back" button whose
     subject is whatever was last clicked. */
  el.addEventListener('click', (event) => {
    const open = event.target.closest('[data-refund]');
    if (!open) return;

    const row = open.closest('tr');
    const form = el.querySelector('.sub-refund');
    if (!row || !form) return;

    form.hidden = false;
    form.dataset.purchase = open.dataset.refund;
    form.dataset.cents = row.dataset.cents;
    form.querySelector('.sub-chosen').textContent =
      row.cells[0].textContent + ' \u00b7 ' + row.cells[3].textContent.split('of')[0].trim() +
      ' \u00b7 ' + row.cells[5].textContent;
    form.querySelector('[name=amount]').value = '';
    form.querySelector('.sub-said').textContent = '';

    el.querySelector('.sub-change').open = true;
    form.querySelector('[name=amount]').focus();
  });

  el.addEventListener('submit', async (event) => {
    const form = event.target.closest('.sub-form');
    if (!form) return;
    event.preventDefault();

    const what = form.dataset.do;
    const said = form.querySelector('.sub-said');
    const person = form.closest('.sub-change').dataset.person;
    const field = (name) => form.querySelector('[name=' + name + ']');
    const why = field('why').value.trim();

    const tell = (text, bad) => {
      said.className = 'sub-said' + (bad ? ' bad' : '');
      said.textContent = text;
    };

    /* CHECKED HERE SO SOMEBODY WHO MISTYPED IS TOLD AT ONCE, and checked again
       by the API, which refuses the same things for the same reasons and has
       tests. This is the courtesy; that one is the rule. */
    if (!why) {
      tell('Say why. It is written down, and a change nobody can account for is worse '
        + 'than one that did not happen.', true);
      return;
    }

    if (what === 'refund') {
      await sendBack(form, said, why, tell);
      return;
    }

    let where = '/console/api/v1/people/' + encodeURIComponent(person);
    const body = { why };

    if (what === 'extend') {
      const days = Number(field('days').value);
      if (!Number.isInteger(days) || days < 1 || days > 366) {
        tell('Between one day and a year. More than that is two grants, and the second '
          + 'entry in the history is the record that you meant it.', true);
        return;
      }
      where += '/subscription/extend';
      body.days = days;
    } else if (what === 'cancel') {
      where += '/subscription/cancel';
    } else {
      const cents = asCents(field('amount').value);
      const currency = field('currency').value.trim().toUpperCase();
      if (cents === null || cents === 0) {
        tell('An amount, like 69 or 69,00. An adjustment of nothing is not a correction.', true);
        return;
      }
      if (!/^[A-Z]{3}$/.test(currency)) {
        tell('A currency is three letters, ISO 4217 — BRL, EUR, USD.', true);
        return;
      }
      where += '/ledger/adjustment';
      /* THE SIGN IS PUT ON HERE, FROM THE WORD THEY CHOSE. The ledger counts
         what a student paid us, so a credit to them is negative — and that is
         a convention nobody should have to hold in their head while typing a
         number into a box. */
      body.cents = field('way').value === 'credit' ? -cents : cents;
      body.currency = currency;
    }

    const button = form.querySelector('button[type=submit]');
    button.disabled = true;
    tell('Saving…');
    try {
      const answer = await post(where, body);

      if (what === 'adjust') {
        tell('Written. It is in the books and nowhere else — the gateway was not told, '
          + 'and no money has moved because of it. It is in the table below.');
        form.reset();
        /* AND THE BOOKS ARE RE-READ, which is the reason that table is a
           request of its own.

           This is the only write on this screen whose row exists the moment it
           returns. A refund asks the gateway and the ledger row arrives later,
           with the webhook, so there would be nothing to show; an adjustment IS
           the row. Until now the sentence above ended at "nowhere else", which
           was literally true — an operator could write into an append-only
           table and have no way of checking they had put the sign the right way
           round.

           Not awaited: what the sentence says is already true, and holding the
           button disabled through a second round trip would make a correction
           feel slower than the thing it corrects. */
        showLedger();
      } else {
        /* THE BLOCK IS REDRAWN FIRST AND THE ANSWER WRITTEN AFTERWARDS, which
           is the wrong way round only until you try it. `redraw` replaces the
           whole section — including this form and the line being written into
           — so a message set before it is thrown away by the thing that proves
           it worked, and the operator sees a screen that changed and says
           nothing about why. */
        redraw(answer, person);
        say(what, what === 'extend'
          ? 'Given, and recorded as a grant rather than a sale.'
          : 'Cancelled. What they paid for still stands to the date above.');
      }
    } catch (e) {
      tell(e instanceof RequestError && e.status === 403
        ? 'That asks for an operator.'
        : e.message, true);
    } finally {
      button.disabled = false;
    }
  });

  /*
  sendBack is the refund, and it is its own function because nothing it does is
  shared with the other three.

    IT DOES NOT REDRAW. The other two that change a term answer the new
    standing; this one answers "the gateway was asked", and the subscription is
    still open at that moment — it closes when the event arrives. Redrawing here
    would paint a screen that says nothing happened, one second before something
    did.

    THE AMOUNT IS COMPARED IN CENTS AND IN THE BROWSER FIRST, so a mistyped
    figure is a sentence rather than a round trip. The API compares it again,
    against the row rather than against what a screen said the row was, and that
    is the check that counts.
  */
  async function sendBack(form, said, why, tell) {
    const cents = asCents(form.querySelector('[name=amount]').value);
    const want = Number(form.dataset.cents);

    if (cents === null) {
      tell('An amount, like 655,50. Type what the line says.', true);
      return;
    }
    if (cents !== want) {
      tell('That is not what this purchase came to. Type the amount on the line — a '
        + 'record with several purchases has several buttons that look the same.', true);
      return;
    }

    const button = form.querySelector('button[type=submit]');
    button.disabled = true;
    tell('Asking the gateway…');
    try {
      const answer = await post('/console/api/v1/purchases/'
        + encodeURIComponent(form.dataset.purchase) + '/refund', { cents, why });
      tell(answer.note || 'Asked and accepted.');
      form.querySelector('[name=amount]').value = '';
    } catch (e) {
      /* THE GATEWAY'S OWN SENTENCE, THROUGH. A key without the permission and a
         charge in a state that cannot be refunded arrive as the same status
         with different Portuguese, and only the Portuguese says which. */
      tell(e instanceof RequestError && e.status === 403
        ? 'That asks for an operator.'
        : e.message, true);
    } finally {
      button.disabled = false;
    }
  }

  /* REDRAWN FROM THE ANSWER AND NOT FROM A SECOND REQUEST. The API answers the
     new standing, so asking again would be one more round trip and one more
     chance to draw a screen from a moment that is not the one just changed. */
  function redraw(answer, person) {
    const block = el.querySelector('#holding');
    if (!block || !answer) return;
    block.innerHTML = holdingInside(answer, person);
    // The fold was open — somebody was working in it — and a section that
    // closed itself after every change would make the second change a hunt.
    const open = block.querySelector('.sub-change');
    if (open) open.open = true;
  }

  // say writes into the form that exists NOW, which after a redraw is not the
  // one the submit handler was holding.
  function say(what, text) {
    const said = el.querySelector('.sub-form[data-do="' + what + '"] .sub-said');
    if (said) {
      said.className = 'sub-said';
      said.textContent = text;
    }
  }

  /* THE BOOKS, READ AFTER THE RECORD AND AGAIN AFTER EVERY CORRECTION.

     It is not awaited by the caller: the record is already on screen and the
     books are the last thing on it, so holding the whole page for one more
     round trip would make every lookup slower to serve a table most people
     scroll past. It says "Reading…" until it arrives, like the screen it is on
     said a moment ago. */
  async function showLedger() {
    const block = el.querySelector('#ledger');
    if (!block) return;

    let answer;
    try {
      answer = await get('/console/api/v1/people/' + encodeURIComponent(person.id) + '/ledger');
    } catch (e) {
      block.innerHTML = '<div class="block-top"><h2>The books</h2></div>' +
        '<p class="none">' + esc(e.message) + '</p>';
      return;
    }
    block.innerHTML = books(answer);
  }
  showLedger();

  return { title: person.name, el };
}

/* ==========================================================================
   The books — every movement of money, which is NOT the purchase table.

   `record.go` says why in one sentence and it decides the whole of this block:

       An instalment plan is one sale collected several times and the ledger is
       keyed by the charge, so the biennial bought in three parts is three rows
       there and one line here. An operator adding up ledger rows to answer
       "what did they pay" would get the right total by luck and the wrong story
       every time.

   So the two tables are two questions, and the sentence saying so is on the
   screen rather than only in a comment: somebody comparing the two totals will
   look for the explanation exactly there.

   # THE NET IS THE SERVER'S ARITHMETIC

   Money is counted in integer cents by the side that has them. A column handed
   to a browser to add up is the one sum in this system that could have two
   answers, and the difference between them would be the number an operator
   quotes to a student.

   # WHAT EACH ROW HAS TO SAY

   The kind, because a refund and a write-off are different conversations with
   the same person. The reference, because it is what somebody reads out to the
   processor's support desk. And the memo, which only a hand-written line has —
   it is the whole reason that line exists, and a table that hid it would leave
   the escape hatch as anonymous as it was when nothing showed it at all.
   ========================================================================== */
function books(answer) {
  const rows = answer.movements || [];
  const head = '<div class="block-top"><h2>The books</h2>' +
    (answer.net || []).map((n) =>
      '<span class="block-score mono">' + esc(money(n.cents, n.currency)) + '</span>').join('') +
  '</div>';

  if (!rows.length) {
    /* NOTHING IS THE ORDINARY STATE and it is said as one. Most people have
       never paid anything, and a blank table under a heading reads as a screen
       that failed rather than as an account with no money in it. */
    return head + '<p class="none">No money has moved either way.</p>';
  }

  return head +
    '<p class="aside">' + esc(answer.not_the_purchases || '') + '</p>' +
    table('', '', ['When', 'What', 'Amount', 'Reference'], rows.map((m) =>
      '<tr>' +
        '<th scope="row" class="mono">' + esc(when(m.at)) + '</th>' +
        '<td>' + esc(movement(m)) +
          (m.memo ? '<span class="ledger-memo">' + esc(m.memo) + '</span>' : '') +
        '</td>' +
        '<td class="mono' + (m.cents < 0 ? ' ledger-back' : '') + '">' +
          esc(money(m.cents, m.currency)) + '</td>' +
        '<td class="mono dim">' + esc(m.sourceRef || m.source || '—') + '</td>' +
      // `table` joins the rows itself. Handing it a joined string made it call
      // `join` on one, which threw inside a handler nothing was watching: the
      // adjustment was written, the form said so, and the table went on saying
      // no money had moved. `console-test` is what said otherwise.
      '</tr>'));
}

/* WHAT THE LINE IS, IN WORDS. The kinds are the ledger's own vocabulary and a
   screen that printed them raw would be asking an operator to know that
   `chargeback` is the issuer's decision and `refund` is ours. `reversed` is
   said separately because it is a different fact from a negative amount: a
   manual credit is negative and undoes nothing. */
function movement(m) {
  const named = {
    payment: 'Payment',
    refund: 'Refunded to them',
    chargeback: 'Taken back by the issuer',
    adjustment: 'Written by hand',
  }[m.kind] || m.kind;
  return m.reversed ? named + ', against an earlier line' : named;
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
function holding(h, personId, refundable) {
  return '<section class="block" id="holding">' +
    holdingInside(h, personId, refundable) + '</section>';
}

// holdingInside is redrawn on its own after a change, so an operator sees the
// row they just moved rather than the one the page loaded with.
function holdingInside(h, personId, refundable) {
  if (!h) {
    return '<div class="block-top"><h2>Subscription</h2></div>' +
      '<p class="none">They have never bought anything, and never tried to.</p>' +
      changes(personId, false, refundable);
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

  return '<div class="block-top">' +
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
      ['Opened', 'Term', 'How', 'Amount', 'Access to', 'At the gateway', ''],
      bought.map((p) =>
        '<tr data-purchase="' + esc(p.id) + '" data-cents="' + p.cents + '">' +
        '<td class="mono">' + esc(day(p.openedAt)) + '</td>' +
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

        /* THEIR REFERENCE FOR IT, which is what somebody reads out to the
           processor's support desk. Until now it existed only in the database,
           so a conversation with Asaas began by opening a SQL client.

           It is `user-select:all` in the stylesheet: it is copied far more
           often than it is read, and a string of eighteen characters selected
           by dragging is a string selected wrongly. */
        '<td><span class="sub-charge mono">' +
          (p.chargeId ? esc(p.chargeId) : '<span class="none">never sent</span>') +
        '</span></td>' +

        '<td>' + stage(p) + refundButton(p, refundable) + '</td></tr>')) +

    (spent
      ? '<p class="list-count">' + esc(spent) + ' across ' + paid.length +
        (paid.length === 1 ? ' paid purchase.' : ' paid purchases.') +
        ' Not the ledger: an instalment plan is one sale here and one row per ' +
        'collection there.</p>'
      : '') +

    changes(personId, Boolean(h.state), refundable);
}

/* ==========================================================================
   AND WHAT AN OPERATOR MAY DO ABOUT IT.

   IT IS FOLDED SHUT AND IT IS THE ONLY THING ON THIS SCREEN THAT IS. Everything
   above answers a question somebody already has; this is three ways to change
   what a person holds, and a form standing open beside a record somebody is
   reading over the telephone is a form that gets used by the hand rather than
   by the decision. The report control in the study interface is shut for the
   same reason and says so.

   EVERY ONE ASKS WHY, AND THE FIELD IS NOT OPTIONAL. `before` and `after` say
   what changed and can never say what for; two dates do not explain sixty free
   days. The API refuses an empty one — a screen that merely asked politely
   would leave the field empty in exactly the rows somebody goes looking for —
   and this asks first so the refusal is not how somebody finds out.

   A READ-ONLY ROLE SEES NONE OF IT. That is not the check: the API refuses, and
   there is a test for it. A control that always fails is simply a bad screen.
   ========================================================================== */
function changes(personId, hasSubscription, refundable) {
  if (!mayAct()) {
    return '<p class="sub-note">A read-only role may read this and not change it.</p>';
  }

  return '<details class="sub-change" data-person="' + esc(personId) + '">' +
    '<summary>Change something</summary>' +
    '<div class="sub-forms">' +

      /* GIVING TIME, AND THE SENTENCE SAYS WHAT IT IS NOT. "Extend" reads like
         a renewal; this is a gift, it is written down as one, and the ledger
         will not show it because no money moved. */
      '<form class="sub-form" data-do="extend" novalidate>' +
        '<h3 class="eyebrow mono">Give time</h3>' +
        '<p class="sub-note">Time nobody paid for — an outage, a fortnight lost to ' +
          'support. It is recorded as a grant and not as a sale, so it will not appear ' +
          'in the purchases above and no money is written anywhere.</p>' +
        (hasSubscription ? '' :
          '<p class="none">They have no subscription to extend. Giving somebody a term ' +
            'is not this: a subscription has to say what it was sold at, and there is no ' +
            'honest answer for one nobody bought.</p>') +
        '<div class="sub-bar">' +
          '<label class="sub-field"><span>Days</span>' +
            '<input name="days" type="number" min="1" max="366" step="1" ' +
              'inputmode="numeric" autocomplete="off"' +
              (hasSubscription ? '' : ' disabled') + '></label>' +
          '<label class="sub-field sub-why"><span>Why</span>' +
            '<input name="why" type="text" autocomplete="off" ' +
              'placeholder="the March outage cost them a fortnight"' +
              (hasSubscription ? '' : ' disabled') + '></label>' +
          '<button type="submit" class="btn btn-primary"' +
            (hasSubscription ? '' : ' disabled') + '>Give it</button>' +
        '</div>' +
        '<p class="sub-said" aria-live="polite"></p>' +
      '</form>' +

      /* CANCELLING, AND THE SENTENCE HAS TO CORRECT AN EXPECTATION. Everybody
         reads "cancel" as "cut off now". Here the paid term stands and what
         stops is the renewal notice — which is the opposite of what an
         operator would tell a student if this screen did not say so. */
      '<form class="sub-form" data-do="cancel" novalidate>' +
        '<h3 class="eyebrow mono">Cancel</h3>' +
        '<p class="sub-note">This does NOT cut their access. Every purchase here is a ' +
          'term bought outright and the paid period is honoured to its end — what stops ' +
          'is the reminder that it is about to run out.</p>' +
        (hasSubscription ? '' : '<p class="none">They have no subscription to cancel.</p>') +
        '<div class="sub-bar">' +
          '<label class="sub-field sub-why"><span>Why</span>' +
            '<input name="why" type="text" autocomplete="off" ' +
              'placeholder="they asked to stop, ticket 812"' +
              (hasSubscription ? '' : ' disabled') + '></label>' +
          '<button type="submit" class="btn btn-bad"' +
            (hasSubscription ? '' : ' disabled') + '>Cancel it</button>' +
        '</div>' +
        '<p class="sub-said" aria-live="polite"></p>' +
      '</form>' +

      /* THE ESCAPE HATCH, AND THE SIGN IS THE WHOLE DANGER. Which way the
         money went is what an operator gets backwards at four in the
         afternoon, so it is a choice between two words rather than a minus
         sign somebody has to remember to type. */
      '<form class="sub-form" data-do="adjust" novalidate>' +
        '<h3 class="eyebrow mono">Adjust the ledger</h3>' +
        '<p class="sub-note">One line in the books for money that moved outside the ' +
          'gateway: a bank transfer, a write-off, a goodwill credit. It tells the ' +
          'gateway NOTHING — no money moves because of this, it records that money ' +
          'moved somewhere else.</p>' +
        '<div class="sub-bar">' +
          '<label class="sub-field"><span>Direction</span>' +
            '<select name="way">' +
              '<option value="credit">Credited to them</option>' +
              '<option value="charge">Charged to them</option>' +
            '</select></label>' +
          '<label class="sub-field"><span>Amount</span>' +
            '<input name="amount" type="text" inputmode="decimal" autocomplete="off" ' +
              'placeholder="69,00"></label>' +
          '<label class="sub-field"><span>Currency</span>' +
            '<input name="currency" type="text" maxlength="3" autocomplete="off" ' +
              'spellcheck="false" placeholder="BRL" value="BRL"></label>' +
          '<label class="sub-field sub-why"><span>Why</span>' +
            '<input name="why" type="text" autocomplete="off" ' +
              'placeholder="bank transfer, receipt 4471"></label>' +
          '<button type="submit" class="btn btn-primary">Write it</button>' +
        '</div>' +
        '<p class="sub-said" aria-live="polite"></p>' +
      '</form>' +

      /* SENDING MONEY BACK, WHICH IS THE ONE THAT LEAVES THIS PLATFORM.

         IT IS NOT REACHED FROM HERE. The form has no purchase in it until
         somebody presses Refund on a LINE of the table above, because "which
         sale" is a question a dropdown answers badly: a record with four
         purchases has four amounts and two dates that look alike, and the one
         an operator means is the one they have just read out.

         THE AMOUNT IS TYPED, and that is the confirmation. Same shape as the
         erasure asking for the address: the mistake here is the wrong ROW, and
         typing R$ 655,50 means having read the line. */
      (refundable
        ? '<form class="sub-form sub-refund" data-do="refund" novalidate hidden>' +
            '<h3 class="eyebrow mono">Send money back</h3>' +
            '<p class="sub-note">This asks the gateway and writes nothing here. Their ' +
              'access closes when the gateway\u2019s event comes back, which is seconds ' +
              'later and not part of the request. It cannot be undone.</p>' +
            '<p class="sub-chosen mono"></p>' +
            '<div class="sub-bar">' +
              '<label class="sub-field"><span>Type the amount</span>' +
                '<input name="amount" type="text" inputmode="decimal" autocomplete="off" ' +
                  'placeholder="0,00"></label>' +
              '<label class="sub-field sub-why"><span>Why</span>' +
                '<input name="why" type="text" autocomplete="off" ' +
                  'placeholder="the course was withdrawn, ticket 903"></label>' +
              '<button type="submit" class="btn btn-bad">Send it back</button>' +
            '</div>' +
            '<p class="sub-said" aria-live="polite"></p>' +
          '</form>'
        : '<p class="sub-note">This deployment has no payment gateway configured, so ' +
          'nothing can be sent back from here.</p>') +

    '</div>' +
  '</details>';
}

/* THE BUTTON ON A LINE, and only on a line that was actually paid. It carries
   nothing but the row's identity — the form above reads the amount and the date
   off the same row, so there is one place where "which purchase" is decided.

   AND ONLY WHERE PRESSING IT CAN DO SOMETHING, which it was not. `RecordHandler`
   carries `refundable` and its comment states the rule: "a button that always
   fails is worse than a button that is not drawn". The rule was applied to the
   FORM and not to the button that opens it — so a deployment with no gateway key
   explained itself inside the fold, in as many words, and then drew a Refund
   button on every paid line of the table above it. Pressing one found no form
   and returned in silence: nothing failed, nothing was said, and an operator was
   entitled to conclude the console was broken.

   IT SURFACED FROM THE OTHER END. `a11y-test` clicks the first one it finds and
   waits for the form, and against a server started without a key it timed out
   naming a selector and no cause. The suite was right and the screen was wrong;
   what looked like a suite that needed configuring was a screen that needed
   fixing. */
function refundButton(p, refundable) {
  if (!refundable || p.stage !== 'paid' || !mayAct()) return '';
  return ' <button type="button" class="sub-refund-open" data-refund="' + esc(p.id) + '">' +
    'Refund</button>';
}

/*
asCents reads what somebody typed as an amount.

	BOTH SEPARATORS, because this console is in English and its operators are
	in Brazil: "69,00" and "69.00" are the same amount typed by the same person
	on two different days. Anything else is refused rather than guessed — a
	silent zero here writes the wrong number into the books.
*/
function asCents(text) {
  const cleaned = String(text || '').trim().replace(/\s/g, '').replace(',', '.');
  if (!/^\d+(\.\d{1,2})?$/.test(cleaned)) return null;
  return Math.round(Number(cleaned) * 100);
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
