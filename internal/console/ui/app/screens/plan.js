/* ==========================================================================
   The plan — what a subscription costs, and what it costs for how long.

   # THIS WAS ON THE SCHOOLS SCREEN AND IT WAS IN THE WRONG PLACE

   There was a price form under every school's colour, because `school_prices`
   was keyed by school. One subscription opens every school (N-02), so two
   schools priced differently let somebody buy through the cheaper page and open
   both — `0041` moved the table to the platform and this screen followed it.

   A form on a school's page would now be a control whose effect is somewhere
   other than where it appears: type 590 under `math.` and `code.` changes too.

   # A PRICE IS APPENDED AND THE SCREEN SAYS SO

   Saving writes a new row dated from today; the old one stays, because a March
   invoice has to stay explicable in November (K-14). The series under each term
   is not decoration — it is the half of that promise a single number cannot
   show, and it is re-read after every save for the same reason.

   # THREE TERMS, ONE TABLE

   The year, the two years, and the month. They are separate offers that share a
   series, so the history is drawn once with every term in it: what somebody
   wants to see is that the year moved and the two years did not, which is a
   comparison three separate tables cannot be asked for.

   # NOTHING HERE DECIDES WHAT IS ALLOWED

   The save is hidden from a read-only role because a control that always fails
   is a bad screen. The API refuses, and there is a test for that.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, put, RequestError } from '../request.js';
import { mayAct } from '../session.js';

/* THE TERMS THAT HAVE A FORM, which is not the same as the terms the table can
   hold. The column takes any number of months; these three are what the
   platform sells, and a screen offering an open field for "how many months"
   would be inviting somebody to invent a fourth product by typing. */
const TERMS = [
  {
    months: 12,
    name: 'A year',
    note: 'The subscription as it has always been quoted. One charge or one card that '
      + 'renews at the end of it.',
  },
  {
    months: 24,
    name: 'Two years',
    note: 'One charge for a 24-month term, renewed as a new sale — no gateway here bills '
      + 'a subscription every two years, so this is not a recurrence.',
  },
  {
    months: 1,
    name: 'A month',
    note: 'For subscribers paying from abroad, where a stored card renewing monthly is '
      + 'what people expect.',
  },
];

export default async function plan(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Operate</span>' +
      '<h1>What it costs</h1>' +
      '<p>One subscription opens every school, so there is one price for each ' +
      'term and not one per school. Every change is recorded with your name, ' +
      'what was there and what replaced it.</p>' +
      '<p>A price is <strong>appended</strong>, never edited — saving one writes ' +
      'a new row dated from today and the old one stays, because a March invoice ' +
      'has to stay explicable in November. Saving the same number again is not a ' +
      'mistake: it records that this is still what we ask, as of today.</p>' +
    '</header>' +
    '<div id="terms">' +
      TERMS.map(block).join('') +
    '</div>' +
    /* WHAT COMES OFF FOR PAYING A CHEAPER WAY, above the series because it is
       part of the same offer and below the terms because it applies to all of
       them. It was a constant in `billing/http.go` until `0045`, and that
       constant's own comment named the condition for it stopping to be one.

       APPENDED LIKE THE PRICE, and for a reason of its own: a past sale is
       already explicable without a series — the checkout records what was
       charged beside the price it was sold under — but a rate that was live for
       a fortnight and sold NOTHING leaves no trace in any sale, and that is
       exactly the fortnight somebody asks about. */
    '<section class="block" id="discount">' +
      '<div class="block-top">' +
        '<h2>What comes off for a Pix</h2>' +
        '<span class="block-score mono">every term</span>' +
      '</div>' +
      '<p class="aside">A Pix settles in seconds and costs this platform less to receive ' +
      'than a card does, and this is the share of that handed back. It applies to every ' +
      'term, which is why it is one figure here rather than one per block above.</p>' +
      '<p class="price-state none">Reading…</p>' +
      '<form class="discount-form" novalidate>' +
        '<div class="price-bar">' +
          '<label class="price-amount">' +
            '<span>Off</span>' +
            '<input type="text" inputmode="decimal" spellcheck="false" autocomplete="off" ' +
              'placeholder="5" aria-describedby="discount-note">' +
          '</label>' +
          '<span class="list-count">per cent</span>' +
          (mayAct()
            ? '<button type="submit" class="btn btn-primary">Save a new rate</button>'
            : '<span class="list-count">A read-only role may look at this and not set it.</span>') +
        '</div>' +
        '<p class="signin-notice" id="discount-note"></p>' +
      '</form>' +
    '</section>' +

    '<section class="block" id="series" aria-live="polite">' +
      '<h2>Every price ever set</h2>' +
      '<p class="checking">Reading…</p>' +
    '</section>' +

    /* AND WHERE SOMEBODY WRITES TO GIVE IT BACK, on this screen because it is
       part of the same offer. The terms promise seven days to withdraw — art.
       49 of the Código de Defesa do Consumidor — and the account screen names
       that deadline whether or not there is an address to name it with. A
       price and the way out of it are one subject. */
    '<section class="block" id="contact">' +
      '<h2>Where a student writes to use the seven days</h2>' +
      '<p class="checking">Reading…</p>' +
    '</section>';

  const series = el.querySelector('#series');
  const contact = el.querySelector('#contact');
  const discount = el.querySelector('#discount');

  await showSeries();
  await showContact();
  TERMS.forEach(wire);
  wireDiscount();

  function block(term) {
    return '<section class="block" data-term="' + term.months + '">' +
      '<div class="block-top">' +
        '<h2>' + esc(term.name) + '</h2>' +
        '<span class="block-score mono">' + term.months + ' months</span>' +
      '</div>' +
      '<p class="aside">' + esc(term.note) + '</p>' +

      /* WHAT THIS TERM COSTS RIGHT NOW, IN WORDS, ABOVE THE FIELD.

         The field alone could not say it. Its placeholder was `490.00` — a
         plausible price, in grey, in a box that decides what everybody pays —
         and the first person to open this screen asked whether that was the
         current price or an example. That is the question a control must never
         raise about itself.

         An empty field is now a sentence rather than an inference, and a
         priced term says the number and the day it started, which is the same
         thing the series below says and is worth saying where the decision is
         being made. */
      '<p class="price-state none">Reading…</p>' +

      '<form class="price-form" novalidate>' +
        '<div class="price-bar">' +
          '<label class="price-amount">' +
            '<span>Price</span>' +
            '<input type="text" inputmode="decimal" spellcheck="false" autocomplete="off" ' +
              'placeholder="0,00" aria-describedby="price-note-' + term.months + '">' +
          '</label>' +
          '<label class="price-currency">' +
            '<span>Currency</span>' +
            '<input type="text" spellcheck="false" autocomplete="off" maxlength="3" ' +
              'placeholder="BRL">' +
          '</label>' +
          (mayAct()
            ? '<button type="submit" class="btn btn-primary">Save a new price</button>'
            : '<span class="list-count">A read-only role may look at this and not set it.</span>') +
        '</div>' +
        '<p class="signin-notice" id="price-note-' + term.months + '"></p>' +
      '</form>' +
    '</section>';
  }

  function wire(term) {
    const box = el.querySelector('[data-term="' + term.months + '"]');
    const form = box.querySelector('.price-form');
    const amount = box.querySelector('.price-amount input');
    const currency = box.querySelector('.price-currency input');
    const note = box.querySelector('.signin-notice');

    form.addEventListener('submit', async (event) => {
      event.preventDefault();

      const cents = asCents(amount.value);
      const money = currency.value.trim().toUpperCase();

      /* CHECKED HERE SO SOMEBODY WHO MISTYPED IS TOLD AT ONCE. The check that
         matters is the API's, which refuses the same things for the same
         reasons and has a test. */
      if (cents === null || cents <= 0) {
        note.className = 'signin-notice bad';
        note.textContent = 'A price is an amount above zero, like 490 or 490.00. '
          + 'A term with no offer has no price at all rather than a price of nothing.';
        return;
      }
      if (!/^[A-Z]{3}$/.test(money)) {
        note.className = 'signin-notice bad';
        note.textContent = 'A currency is three letters, ISO 4217 — BRL, EUR, USD. '
          + 'It is what a browser needs to format the amount.';
        return;
      }

      note.className = 'signin-notice';
      note.textContent = 'Saving…';
      try {
        await put('/console/api/v1/plan/price',
          { termMonths: term.months, cents, currency: money });
        note.className = 'signin-notice ok';
        note.textContent = 'Saved as a new price, from today. The one before it is still '
          + 'in the series below.';
      } catch (e) {
        note.className = 'signin-notice bad';
        note.textContent = e instanceof RequestError && e.status === 403
          ? 'That asks for an operator.'
          : e.message;
      }
      await showSeries();
    });
  }

  /* THE SERIES IS READ WHEN THE SCREEN IS DRAWN AND AGAIN AFTER EVERY SAVE,
     because the point of appending is that the old rows are still there and a
     screen that showed only the newest would be the mutable field again with
     extra steps. */
  async function showSeries() {
    let answer;
    try {
      answer = await get('/console/api/v1/plan/prices');
    } catch (e) {
      series.innerHTML = '<h2>Everything ever set</h2><p class="none">' +
        esc(e.message) + '</p>';

      /* AND THE TERMS SAY THEY DO NOT KNOW, rather than keeping the ellipsis
         they were drawn with. A field with nothing above it reads as an
         unpriced term, which is a different fact from "this screen could not
         read what the price is" — and the two would send somebody to type a
         number that already exists. */
      TERMS.forEach((term) => {
        const state = el.querySelector('[data-term="' + term.months + '"] .price-state');
        state.className = 'price-state none';
        state.textContent = 'What this costs could not be read, so this screen '
          + 'cannot say whether it is priced.';
      });
      return;
    }

    /* THE DISCOUNTS COME BACK IN THE SAME ANSWER and are drawn in the same
       list, because "what did we ask in March" and "what did we take off in
       March" are one question asked about one moment. Two lists side by side
       would make somebody read two dates to answer it. */
    fillDiscount(answer.discounts || []);

    const rows = answer.prices || [];
    const off = answer.discounts || [];

    /* ONE LIST, IN ONE ORDER, and the two kinds are told apart by what they say
       rather than by which column they are in. Somebody reading this is asking
       what the offer was on a day, and the offer is both numbers — a list of
       prices beside a list of rates makes them read two dates and hold one in
       their head while they find the other. */
    const everything = [
      ...rows.map((p) => ({
        at: p.from,
        what: named(p.termMonths),
        said: shown(p.cents, p.currency),
        now: inForce(rows, p),
      })),
      ...off.map((d) => ({
        at: d.from,
        what: d.method === 'pix' ? 'A Pix' : d.method,
        said: asPercent(d.basisPoints) + '% off',
        now: newestFor(off, d),
      })),
    ].sort((a, b) => String(b.at).localeCompare(String(a.at)));

    series.innerHTML = '<h2>Everything ever set</h2>' + (everything.length === 0
      ? '<p class="none">Nothing is priced yet. The invitation then says what a ' +
        'subscription opens without naming a figure.</p>'
      : '<ol class="price-list">' +
          everything.map((one) =>
            '<li class="price-row' + (one.now ? ' price-now' : '') + '">' +
              '<span class="price-term">' + esc(one.what) + '</span>' +
              '<span class="price-money mono">' + esc(one.said) + '</span>' +
              '<span class="price-from">' +
                (one.now ? 'in force since ' : 'from ') + esc(day(one.at)) +
              '</span>' +
            '</li>').join('') +
        '</ol>' +
        '<p class="aside">' + esc(answer.append_only || '') + '</p>');

    fill(rows);
  }

  /* WHAT IS IN FORCE IS PER TERM, and the list is newest first — so the first
     row for a term is that term's current price, and every later one is
     history. Marking by position in the whole list would put the badge on
     whichever term happened to be priced last. */
  function inForce(rows, row) {
    return rows.find((r) => r.termMonths === row.termMonths) === row;
  }

  // The same rule for a rate: the list is newest first, so the first row for a
  // method is the one in force and every later one is history.
  function newestFor(rows, row) {
    return rows.find((r) => r.method === row.method) === row;
  }

  /* AND THE FORMS START AT WHAT IS IN FORCE, so a rise is typed over the number
     it replaces rather than into an empty box beside it — and each term says in
     words whether it has a price at all. */
  function fill(rows) {
    TERMS.forEach((term) => {
      const box = el.querySelector('[data-term="' + term.months + '"]');
      const state = box.querySelector('.price-state');
      const now = rows.find((r) => r.termMonths === term.months);

      if (!now) {
        /* NOT PRICED IS NOT THE SAME AS FREE, and the second sentence is the
           one somebody needs: the checkout refuses a term nobody has priced, so
           an empty field here is a product nobody can buy. */
        state.className = 'price-state none';
        state.textContent = 'Nothing is priced for this term, so nobody can buy it.';
        return;
      }

      state.className = 'price-state';
      state.textContent = shown(now.cents, now.currency) + ' — in force since '
        + day(now.from);
      box.querySelector('.price-amount input').value = asAmount(now.cents);
      box.querySelector('.price-currency input').value = now.currency;
    });
  }

  /* THE ADDRESS, DRAWN WHOLE EACH TIME rather than patched, for the same reason
     the series is re-read: what this block says is mostly the SENTENCE about
     which of two sources is answering, and that sentence changes shape when a
     row appears where there was none. Rebuilding it is one function; keeping
     four elements in step with each other is four. */
  async function showContact() {
    let answer;
    try {
      answer = await get('/console/api/v1/support/contact');
    } catch (e) {
      contact.innerHTML = '<h2>Where a student writes to use the seven days</h2>' +
        '<p class="none">' + esc(e.message) + '</p>';
      return;
    }

    contact.innerHTML =
      '<h2>Where a student writes to use the seven days</h2>' +

      /* WHAT THE TERMS ACTUALLY PROMISE, said here because this is where
         somebody decides whether the address is worth setting. An operator who
         reads "support e-mail" and nothing else has no way to know that leaving
         it empty publishes a legal right with no way to exercise it. */
      '<p class="aside">The terms of use give a student seven days from the purchase to ' +
      'give the subscription back, for the whole amount and with no reason — art. 49 of ' +
      'the Código de Defesa do Consumidor. The account screen names that deadline ' +
      'whatever happens here, and names an address only when there is one.</p>' +

      '<p class="price-state' + (answer.published ? '' : ' none') + '">' +
        esc(saying(answer)) +
      '</p>' +

      (mayAct()
        ? '<form class="contact-form" novalidate>' +
            '<div class="list-bar">' +
            '<label class="field">' +
              '<span>Address</span>' +
              '<input type="email" name="email" spellcheck="false" autocomplete="off" ' +
                'inputmode="email" placeholder="contact@example.tld" ' +
                'value="' + esc(answer.email || '') + '">' +
            '</label>' +

            /* THE REASON IS REQUIRED AND THE API REFUSES WITHOUT IT. It is one
               line rather than a paragraph because the useful answers are one
               line: "the old box is closed", "typo", "moved to the shared
               inbox". The log has to be able to tell the second from the first
               — only one of them means the address published in between was
               wrong. */
            '<label class="field">' +
              '<span>Why</span>' +
              '<input type="text" name="reason" autocomplete="off" ' +
                'placeholder="the old inbox is closed" maxlength="200">' +
            '</label>' +
            '<button type="submit" class="btn btn-primary">Save this address</button>' +
            '</div>' +
            '<p class="signin-notice"></p>' +
          '</form>'
        : '<p class="list-count">A read-only role may look at this and not set it.</p>');

    const form = contact.querySelector('.contact-form');
    if (!form) return;
    const note = form.querySelector('.signin-notice');

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const email = form.querySelector('[name=email]').value.trim();
      const reason = form.querySelector('[name=reason]').value.trim();

      /* CHECKED HERE SO A MISTYPED ADDRESS IS REFUSED BEFORE IT IS RECORDED.
         The check that matters is the API's, which refuses the same things and
         has a test — this one exists because the entry is written FIRST, and a
         round trip that records a change and then rejects it would leave the
         log saying something happened that did not. */
      if (!email) {
        return say('bad', 'An address, or nothing at all — but nothing is cleared by the '
          + 'deployment rather than from here, and this form only sets one.');
      }
      if (!reason) {
        return say('bad', 'Say why in a few words. This is published to every student, and '
          + 'the log has to tell an address that moved because the person answering '
          + 'changed from one that moved because the last was a typo.');
      }

      say('', 'Saving…');
      try {
        await put('/console/api/v1/support/contact', { email, reason });
      } catch (e) {
        return say('bad', e instanceof RequestError && e.status === 403
          ? 'That asks for an operator.'
          : e.message);
      }

      /* REDRAWN FIRST AND SPOKEN INTO SECOND. Writing the confirmation and then
         rebuilding the block replaces the node it was written into, so the
         message disappears at the moment it is earned — which is a mistake this
         console has already made once, on the refund form. */
      await showContact();
      say('ok', 'Saved. Every student inside their seven days is now told to write there.');
    });

    function say(how, text) {
      const where = contact.querySelector('.signin-notice');
      if (!where) return;
      where.className = 'signin-notice' + (how ? ' ' + how : '');
      where.textContent = text;
    }
  }

  /* ---------- what comes off ----------

     THE FIELD IS PER CENT AND EVERYTHING ELSE IS BASIS POINTS, and the
     conversion lives here for the reason `asCents` beside it does: the server
     speaks one unit everywhere — the arithmetic that applies the rate, the
     audit entry, the column — and a percentage crossing that boundary is the
     one place a rate could arrive meaning a hundredth of what was typed.

     Somebody typing into a console types "5", not "500". */
  function fillDiscount(rows) {
    const state = discount.querySelector('.price-state');
    const now = rows.find((r) => r.method === 'pix');

    if (!now) {
      /* NOTHING OFF IS A REAL OFFER, not a screen that failed. A method nobody
         has discounted is sold at the price, and saying so is what stops
         somebody typing a rate on the assumption that the blank meant broken. */
      state.className = 'price-state none';
      state.textContent = 'Nothing comes off a Pix. It is charged at the price above.';
      return;
    }
    state.className = 'price-state';
    state.textContent = asPercent(now.basisPoints) + '% off — in force since ' + day(now.from);
    discount.querySelector('.price-amount input').value = asPercent(now.basisPoints);
  }

  function wireDiscount() {
    const form = discount.querySelector('.discount-form');
    const note = form.querySelector('.signin-notice');

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const points = asBasisPoints(form.querySelector('.price-amount input').value);

      /* CHECKED HERE SO SOMEBODY WHO MISTYPED IS TOLD AT ONCE, and the ceiling
         is the API's — `MostBasisPoints` is a fence against 5000 typed where
         500 was meant, and a fence a screen could move is a fence in the way. */
      if (points === null || points <= 0) {
        note.className = 'signin-notice bad';
        note.textContent = 'A rate is a number above zero, like 5 or 7.5. Nothing off is not '
          + 'a rate of nothing — it is no discount at all, which is a different thing and '
          + 'is not set from here.';
        return;
      }

      note.className = 'signin-notice';
      note.textContent = 'Saving…';
      try {
        await put('/console/api/v1/plan/discount', { method: 'pix', basisPoints: points });
        note.className = 'signin-notice ok';
        note.textContent = 'Saved as a new rate, from today. The one before it is still in '
          + 'the series below.';
      } catch (e) {
        note.className = 'signin-notice bad';
        note.textContent = e instanceof RequestError && e.status === 403
          ? 'That asks for an operator.'
          : e.message;
      }
      await showSeries();
    });
  }

  return { title: section.name, el };
}

/* BASIS POINTS IN AND A PERCENTAGE OUT. `500` is five per cent; `750` is seven
   and a half. Two decimal places of a per cent is the whole precision the unit
   carries, which is why the field accepts one and the conversion is exact. */
function asPercent(basisPoints) {
  return String(Number((basisPoints / 100).toFixed(2)));
}

/* AND BACK, refusing anything that is not a number rather than sending a NaN —
   which would arrive as a zero and read as somebody having set the rate to
   nothing, when nothing is a state this form cannot reach on purpose. */
function asBasisPoints(typed) {
  const clean = String(typed || '').trim().replace(',', '.');
  if (!/^\d+(\.\d{1,2})?$/.test(clean)) return null;
  return Math.round(Number(clean) * 100);
}

/* WHICH OF THE TWO SOURCES IS ANSWERING, in a sentence rather than as a badge.

   There are three states and they are genuinely different decisions:

     a row          somebody set this here, and it can be changed here
     no row         the deployment's own variable is answering, and saving an
                    address below takes it over for good
     neither        the notice names the deadline and nobody is told where to
                    write, which is the state this whole screen exists to end

   A field showing the resolved address in all three would look identical in the
   first two and would invite somebody to "fix" a value that is already correct
   by typing it again — with the difference that after typing it, it is a row
   this console owns rather than a value one machine's gitignored file holds. */
function saying(answer) {
  if (answer.email) {
    return 'Students are told to write to ' + answer.email
      + (answer.since ? ', set here on ' + day(answer.since) + '.' : '.');
  }
  if (answer.published) {
    return 'Students are told to write to ' + answer.published + ', which comes from this '
      + "deployment's own configuration and not from here. Saving an address below takes "
      + 'it over — after that this screen is what decides it.';
  }
  return 'Nobody is told where to write. The account screen still names the deadline, '
    + 'because knowing the date is worth something on its own — but a student inside '
    + 'the seven days has no address to use them at.';
}

// A term's name where one exists, and its months where it does not. The table
// can hold a term this screen has no form for, and the history has to be able
// to show it — a row it could not name would be a price nobody can account for.
function named(months) {
  const known = TERMS.find((t) => t.months === months);
  return known ? known.name : months + ' months';
}

/* CENTS IN AND A DECIMAL OUT, and the conversion lives in this file rather than
   in the request because the server speaks cents everywhere — the ledger does,
   the audit entry does, and a decimal crossing that boundary is the one place
   money would become a string somebody has to parse.

   `null` FOR ANYTHING THAT IS NOT A NUMBER, so the caller refuses rather than
   sending a NaN that arrives as a zero and reads as "they set it to nothing". */
function asCents(typed) {
  const clean = String(typed || '').trim().replace(',', '.');
  if (!/^\d+(\.\d{1,2})?$/.test(clean)) return null;
  return Math.round(Number(clean) * 100);
}

function asAmount(cents) {
  return cents > 0 ? (cents / 100).toFixed(2) : '';
}

/* What a price looks like in the list. `Intl` rather than a symbol table: the
   console shows every currency the platform sells in and this file must not
   become the place that knows which symbol goes on which side of which number. */
function shown(cents, currency) {
  try {
    return new Intl.NumberFormat(undefined, { style: 'currency', currency })
      .format(cents / 100);
  } catch (e) {
    // A currency `Intl` does not know is still a real price. Showing the code
    // beside the number is worse than showing nothing, and better than throwing.
    return (cents / 100).toFixed(2) + ' ' + currency;
  }
}

function day(iso) {
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? String(iso) : at.toLocaleDateString();
}
