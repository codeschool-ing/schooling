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
    holding(it.holding, person.id) +

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
          + 'and no money has moved because of it.');
        form.reset();
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
function holding(h, personId) {
  return '<section class="block" id="holding">' + holdingInside(h, personId) + '</section>';
}

// holdingInside is redrawn on its own after a change, so an operator sees the
// row they just moved rather than the one the page loaded with.
function holdingInside(h, personId) {
  if (!h) {
    return '<div class="block-top"><h2>Subscription</h2></div>' +
      '<p class="none">They have never bought anything, and never tried to.</p>' +
      changes(personId, false);
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

    changes(personId, Boolean(h.state));
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
function changes(personId, hasSubscription) {
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

    '</div>' +
  '</details>';
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
