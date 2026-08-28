/* ==========================================================================
   Subscribing — the screen where money starts moving.

   IT REPLACES A `mailto:`. Until now the invitation's one button opened a mail
   client, and somebody opened the subscription by hand at the other end. That
   worked for a platform with no gateway and it is the thing this whole payment
   phase exists to end.

   # WHAT IS ON OFFER COMES FROM THE SERVER, ALWAYS

   `school.plans` is one entry per term the platform has priced. This screen
   draws what is there and nothing else: a term nobody priced is not for sale,
   the checkout refuses it, and a screen listing it would be selling something
   that answers an error.

   So a platform selling only a year shows one choice, and one that has priced
   nothing sends people back to the invitation — which says what a subscription
   opens without naming a figure, and has said that all along.

   # THE PRICE IS SHOWN AND IS NEVER SENT

   Every figure here is drawn from what the server said and recomputed by the
   server when it charges. Nothing in the request carries an amount. A screen
   that posted a price would be a screen where a buyer names their own, and
   there is a test on the other side asserting that a `cents` in the body is
   ignored.

   # THE TAX ID APPEARS ONCE IN SOMEBODY'S LIFE, AND ONLY WHEN ASKED FOR

   Charging in Brazil needs a CPF or CNPJ. The server knows whether this person
   already has a handle at the gateway; the browser does not, and must not
   guess. So the field is absent until a request comes back saying it is needed
   — which means a returning subscriber never sees it, and a first-time one
   sees it exactly once.

   It is typed, sent, and forgotten. The platform stores the handle the gateway
   answers with and never the number, which the privacy policy says in both
   languages.
   ========================================================================== */

import { esc } from '../text.js';
import { goTo } from '../routes.js';
import { now } from '../state.js';
/* THE MODULE AND NOT THE NAME, because `source.school` is `export let` — it is
   null until the API answers and then it is the school. A named import is a
   live binding in a browser and would have worked there, which is exactly what
   makes this worth a comment: the OFFLINE BUNDLE inlines these modules and
   destructures, so the import reads null once and keeps it. The screen would
   have drawn "nothing on sale here yet" in `showcase.html` and been right in
   every other build. `tools/bundle` refuses it for that reason, and `exams.js`
   and `main.js` reach for the same binding the same way. */
import * as source from '../source.js';
import * as api from '../api.js';

/* THE DISCOUNT IS DRAWN HERE AND DECIDED THERE.

   Five per cent, the same number `billing.pixDiscount` applies — and this is a
   copy, which is worth saying out loud. The alternative is a round trip per
   click to be told a figure the screen could work out, and the protection
   against the two drifting is that the SERVER's number is the one charged: a
   screen showing the wrong discount shows a wrong number and takes the right
   money, which is visible and cheap to fix. The reverse arrangement — the
   browser sending what it thinks — is the one that cannot be allowed. */
const PIX_DISCOUNT = 0.05;

export default async function subscribe() {
  const el = document.createElement('div');
  el.className = 'view view-subscribe';

  const session = now().session;
  if (!session) {
    goTo('/sign-in');
    return { title: txt('Subscribe'), el };
  }

  const plans = ((source.school && source.school.plans) || []).slice();
  if (!plans.length) {
    /* NOTHING IS PRICED, so there is nothing to sell and this says so rather
       than drawing an empty form. It is the same state the invitation already
       handles by naming no figure. */
    el.innerHTML =
      '<header class="view-head"><h1>' + esc(txt('Subscribe')) + '</h1></header>' +
      '<p class="none">' + esc(txt('There is nothing on sale here yet.')) + '</p>';
    return { title: txt('Subscribe'), el };
  }

  let term = pick(plans);
  let method = 'pix';
  let instalments = 1;
  let needsTaxID = false;

  el.innerHTML =
    '<header class="view-head">' +
      '<h1>' + esc(txt('Subscribe')) + '</h1>' +
      '<p>' + esc(txt('One subscription opens every course, the final exams, the certificates and the material to download.')) + '</p>' +
    '</header>' +
    '<form id="checkout" novalidate>' +
      '<fieldset class="buy-terms">' +
        '<legend>' + esc(txt('For how long')) + '</legend>' +
        '<div id="terms"></div>' +
      '</fieldset>' +
      '<fieldset class="buy-methods">' +
        '<legend>' + esc(txt('How you pay')) + '</legend>' +
        '<div id="methods"></div>' +
      '</fieldset>' +
      '<div id="tax" hidden></div>' +
      '<button type="submit" class="btn btn-primary">' +
        esc(txt('Continue to payment')) + '</button>' +
      '<p class="buy-note" id="note"></p>' +
    '</form>';

  const note = el.querySelector('#note');
  const button = el.querySelector('button[type=submit]');
  paint();

  el.querySelector('#checkout').addEventListener('submit', async (event) => {
    event.preventDefault();

    const taxID = el.querySelector('#tax input');
    button.disabled = true;
    note.className = 'buy-note';
    note.textContent = txt('Starting…');

    try {
      const started = await api.startCheckout({
        termMonths: term.termMonths,
        method,
        instalments: method === 'card' ? instalments : 1,
        taxId: taxID ? taxID.value : '',
      });

      /* AND THE BROWSER LEAVES. What comes back is the gateway's own page,
         where the card is typed or the Pix code is shown — nothing here ever
         touches a card number, which is what keeps this platform outside the
         part of PCI that has auditors in it. */
      globalThis.location.href = started.invoiceUrl;
    } catch (err) {
      button.disabled = false;
      note.className = 'buy-note bad';
      note.textContent = reasonFor(err);
      if (err && err.code === 'tax_id_required') {
        needsTaxID = true;
        paint();
      }
    }
  });

  /* EACH SENTENCE IS ITS OWN `txt('literal')` CALL and the switch picks between
     the RESULTS, which is `account.js`'s note and the same reason:
     `check-interface` reads this file for `txt('…')` and cannot see a literal
     inside an expression handed to it.

     THE SERVER'S OWN MESSAGE IS NOT USED. It is English, it is written for a
     log and for a developer, and the person reading this screen may not read
     English — so the CODE travels and the sentence is chosen here. */
  function reasonFor(err) {
    switch (err && err.code) {
      case 'email_unconfirmed': return txt('Confirm your e-mail address before paying. The banner on any page will send the link again.');
      case 'tax_id_required': return txt('Paying in Brazil needs a CPF or CNPJ. We pass it to the payment provider and do not store it.');
      case 'not_a_tax_id': return txt('A CPF has eleven digits and a CNPJ has fourteen.');
      case 'payer_refused': return txt('The payment provider would not accept those details.');
      case 'no_offer': return txt('That is not on sale here.');
      case 'offline': return txt('The school could not be reached. Nothing has been charged.');
      default: return txt('The payment could not be started, and nothing has been charged. Try again.');
    }
  }

  function paint() {
    el.querySelector('#terms').innerHTML = plans.map((p) =>
      '<label class="buy-term' + (p === term ? ' on' : '') + '">' +
        '<input type="radio" name="term" value="' + p.termMonths + '"' +
          (p === term ? ' checked' : '') + '>' +
        '<span class="buy-term-name">' + esc(termName(p.termMonths)) + '</span>' +
        '<span class="buy-term-price mono">' + esc(money(p.cents, p.currency)) + '</span>' +
      '</label>').join('');

    /* WHAT EACH METHOD ACTUALLY COSTS, BESIDE ITS NAME. "5% off with Pix" is a
       claim somebody has to do arithmetic on; the two figures side by side are
       the same fact without the arithmetic. */
    el.querySelector('#methods').innerHTML =
      '<label class="buy-method' + (method === 'pix' ? ' on' : '') + '">' +
        '<input type="radio" name="method" value="pix"' +
          (method === 'pix' ? ' checked' : '') + '>' +
        /* NOT `txt('Pix')`. It is the Banco Central's rail and it is called
           Pix in every language there is; putting it through the dictionary
           asks for a translation that cannot exist, and answering that with an
           identity entry would be a line somebody later "fixes" into something
           wrong. `txt` is for sentences, and this is a name. */
        '<span class="buy-method-name">Pix</span>' +
        '<span class="buy-method-price mono">' +
          esc(money(Math.round(term.cents * (1 - PIX_DISCOUNT)), term.currency)) + '</span>' +
        '<span class="buy-method-note dim">' + esc(txt('Five per cent off, and it clears in seconds.')) + '</span>' +
      '</label>' +
      '<label class="buy-method' + (method === 'card' ? ' on' : '') + '">' +
        '<input type="radio" name="method" value="card"' +
          (method === 'card' ? ' checked' : '') + '>' +
        '<span class="buy-method-name">' + esc(txt('Credit card')) + '</span>' +
        '<span class="buy-method-price mono">' + esc(money(term.cents, term.currency)) + '</span>' +
        '<span class="buy-method-note dim">' + esc(txt('In up to six instalments, with no interest.')) + '</span>' +
      '</label>' +
      (method === 'card' ? instalmentPicker() : '');

    el.querySelector('#tax').hidden = !needsTaxID;
    el.querySelector('#tax').innerHTML = needsTaxID
      ? '<label class="buy-tax"><span>' + esc(txt('Your CPF or CNPJ')) + '</span>' +
        '<input type="text" inputmode="numeric" autocomplete="off" spellcheck="false">' +
        '</label>' +
        '<p class="buy-tax-note">' + esc(txt('The payment provider needs it to issue the charge. We send it and keep only the identifier it answers with.')) + '</p>'
      : '';

    wire();
  }

  function instalmentPicker() {
    /* SIX AND NOT TWELVE. The roadmap records why: the published rate for
       twelve is upwards of twenty per cent of the sale, and a lane with
       interest passed to the buyer needs a rate table nobody has yet and a
       disclosure obligation nobody has written. */
    let out = '<label class="buy-instalments"><span>' +
      esc(txt('In how many instalments')) + '</span><select>';
    for (let n = 1; n <= 6; n += 1) {
      out += '<option value="' + n + '"' + (n === instalments ? ' selected' : '') + '>' +
        esc(n + '× ' + money(Math.round(term.cents / n), term.currency)) + '</option>';
    }
    return out + '</select></label>';
  }

  function wire() {
    el.querySelectorAll('input[name=term]').forEach((input) => {
      input.addEventListener('change', () => {
        term = plans.find((p) => String(p.termMonths) === input.value) || term;
        // A LONGER TERM DOES NOT KEEP THE OLD SPLIT. Six instalments of a year
        // and six of two years are different monthly figures, and leaving the
        // number selected while the amount moved would show a stale one.
        instalments = 1;
        paint();
      });
    });
    el.querySelectorAll('input[name=method]').forEach((input) => {
      input.addEventListener('change', () => { method = input.value; paint(); });
    });
    const split = el.querySelector('.buy-instalments select');
    if (split) {
      split.addEventListener('change', () => { instalments = Number(split.value) || 1; });
    }
  }

  return { title: txt('Subscribe'), el };
}

/*
pick is which term is selected when the screen opens.

	THE YEAR, and the shortest priced term when there is no year — the same rule
	the invitation follows, for the same reason: a platform that priced only the
	two years should open on the two years rather than on nothing.
*/
function pick(plans) {
  return plans.find((p) => p.termMonths === 12) || plans[0];
}

/*
termName is what a number of months is called.

	EACH IS ITS OWN `txt('literal')`, for `reasonFor`'s reason. The last branch
	is the one that keeps this honest: the server may price a term this screen
	has no name for, and a product drawn as "6 months" is better than one drawn
	as nothing.
*/
function termName(months) {
  switch (months) {
    case 1: return txt('A month');
    case 12: return txt('A year');
    case 24: return txt('Two years');
    default: return months + ' ' + txt('months');
  }
}

/* An amount as the reader's language writes it, in the currency the server
   said. It is `common.js`'s function, in cents rather than units — every
   number that crosses to the server is in cents, and converting once here is
   one place instead of at every call. */
function money(cents, currency) {
  const lang = document.documentElement.lang || 'en';
  const amount = (cents || 0) / 100;
  try {
    return currency
      ? new Intl.NumberFormat(lang, { style: 'currency', currency }).format(amount)
      : new Intl.NumberFormat(lang).format(amount);
  } catch (e) {
    return String(amount);
  }
}
