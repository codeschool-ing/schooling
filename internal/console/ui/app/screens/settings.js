/* ==========================================================================
   What this platform is set to — every knob, with the argument for each.

   # THIS SCREEN IS THE THING K-13 WARNED ABOUT, BUILT DELIBERATELY

   `internal/console/writes.go` opens by refusing "a `system_parameters` table —
   a name, a value, a screen that edits any row of it", because a configuration
   surface grows to fill the space it is given. Then `0046` built the registry
   and moved the fence: a knob still costs a declaration, bounds and a sentence
   arguing that the value has no right answer. It no longer costs a table.

   So this screen exists, and what makes it safe is not that it is small. It is
   that it can only draw what some module DECLARED — the server sends the closed
   set, and a name nobody declared is a 404 on the way in and decides nothing on
   the way out. There is no "add a parameter" here and there never will be: the
   way to add one is a declaration in Go, beside the code that reads it.

   # THE ARGUMENT IS ON THE SCREEN AND THAT IS THE POINT

   Each block prints the sentence its declaration carries, above the field. That
   sentence is the entire cost of the knob existing — a screen showing only a box
   and a number would be spending it and throwing it away, and an operator moving
   a number the whole platform behaves by should be reading the case for it while
   they do.

   # AND THE FENCE IS DRAWN, NOT JUST ENFORCED

   Bounds arrive with each parameter and the field says them. A form that refuses
   after the fact can only report that something was outside a limit it never
   named; this one says what the limit is before anybody types.

   # NOTHING HERE DECIDES WHAT IS ALLOWED

   The forms are hidden from a read-only role because a control that always fails
   is a bad screen. The API refuses, and there is a test for that.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, put, RequestError } from '../request.js';
import { mayAct } from '../session.js';

export default async function settings(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Operate</span>' +
      '<h1>What it is set to</h1>' +
      '<p>Numbers the whole platform behaves by, changed here instead of by a ' +
      'deployment. Every change is recorded with your name, what was there and ' +
      'what replaced it — and each one asks you why.</p>' +

      /* WHY THE LIST IS AS LONG AS IT IS AND NO LONGER, said on the screen
         rather than only in the source. Somebody who opens this page and counts
         the entries will wonder where the next one is; the answer is that a
         knob costs a declaration and an argument, which is a decision made in a
         diff and not a gap waiting to be filled.

         IT SAID "FIVE ENTRIES" UNTIL THERE WERE ELEVEN, which is what a comment
         counting something it does not control is always going to do. */
      '<p>This list is closed. A parameter exists because some part of the ' +
      'system declared it — with what it counts in, the range it may move ' +
      'inside, the value the code ships with, and the argument for it being ' +
      'settable at all. There is no way to add one from here, and that is ' +
      'deliberate: a value with a right answer belongs in code, where a test ' +
      'holds it.</p>' +
    '</header>' +
    '<div id="knobs" aria-live="polite">' +
      '<p class="checking">Reading…</p>' +
    '</div>';

  const knobs = el.querySelector('#knobs');

  await show();

  /* READ WHOLE AND REDRAWN WHOLE, on load and after every save. What a block
     says is mostly the SENTENCE about whether anybody has ever decided this one,
     and that sentence changes shape the moment a row appears where there was
     none. Rebuilding is one function; keeping four elements in step is four. */
  async function show() {
    let answer;
    try {
      answer = await get('/console/api/v1/settings');
    } catch (e) {
      knobs.innerHTML = '<p class="none">' + esc(e.message) + '</p>';
      return;
    }

    const all = answer.settings || [];
    if (all.length === 0) {
      /* NOT A BLANK LIST — this platform has had a declared parameter since
         `0046`, so nothing here means the registry came back empty, which is a
         deployment answering wrongly rather than a console with nothing to do. */
      knobs.innerHTML = '<p class="none">Nothing is declared, which should not be ' +
        'possible — this platform has had at least one parameter since the registry ' +
        'existed. Something is answering wrongly rather than there being nothing to set.</p>';
      return;
    }

    knobs.innerHTML = all.map(block).join('');
    all.forEach(wire);
  }

  function block(one) {
    return '<section class="block" data-name="' + esc(one.name) + '">' +
      /* THE HEADING IS THE NAME ITSELF, and it stopped being a derived title
         the moment a second module declared one. `billing.instalments` reads
         as "Instalments" and `exam.passmark` reads as "Passmark", which is a
         function that is approximately right and getting worse — and the name
         is what an audit entry says, what an operator would search for, and
         what somebody would quote over the phone. A prettier word that is not
         the parameter's name is a second name for one thing.

         WHAT THE CHIP CARRIES INSTEAD IS THE FENCE, which is the fact the
         heading used to spend its space repeating: the range this may move
         inside, and the unit it counts in. It is the one thing on this block
         that the form's own `min` and `max` say silently. */
      '<div class="block-top">' +
        '<h2 class="mono">' + esc(one.name) + '</h2>' +
        '<span class="block-score mono">' +
          one.least + '–' + one.most + ' ' + esc(String(one.unit)) +
        '</span>' +
      '</div>' +

      // THE ARGUMENT, above the field. See the header.
      '<p class="aside">' + esc(one.why) + '</p>' +

      '<p class="price-state' + (one.set ? '' : ' none') + '">' + esc(saying(one)) + '</p>' +

      (mayAct()
        ? '<form class="knob-form" novalidate>' +
            '<div class="list-bar">' +
              '<label class="field">' +
                '<span>' + esc(counted(one.unit)) + '</span>' +
                '<input type="number" name="value" inputmode="numeric" autocomplete="off" ' +
                  'min="' + one.least + '" max="' + one.most + '" step="1" ' +
                  'value="' + esc(String(one.value)) + '">' +
              '</label>' +

              /* THE REASON IS REQUIRED AND THE API REFUSES WITHOUT IT. A
                 parameter is one row that is replaced, so this log is the whole
                 history of what the platform was set to — and a number that
                 moved because a fee table changed is a different fact from one
                 that moved because somebody was trying it out.

                 THE PLACEHOLDER SAYS A LENGTH AND NOT A REASON, and it took
                 seeing eleven of these on one screen to notice why that
                 matters. It used to read "the fee bands changed" — written
                 when the only parameter here was the instalment ceiling, where
                 that sentence is plausible. Beside a pass mark or a presence
                 window it is nonsense, and a placeholder is not decoration: it
                 is a SUGGESTION, in the one field whose entire job is to make
                 somebody write down the real reason. An operator in a hurry
                 reads it, thinks close enough, and the log fills with a
                 sentence the screen supplied.

                 So it describes the shape of an answer — how long — and
                 supplies none of its content. */
              '<label class="field field-wide">' +
                '<span>Why</span>' +
                '<input type="text" name="reason" autocomplete="off" maxlength="200" ' +
                  'placeholder="in a few words">' +
              '</label>' +
              '<button type="submit" class="btn btn-primary">Save</button>' +
            '</div>' +
            '<p class="signin-notice"></p>' +
          '</form>'
        : '<p class="list-count">A read-only role may look at this and not set it.</p>') +
    '</section>';
  }

  function wire(one) {
    const box = knobs.querySelector('[data-name="' + cssName(one.name) + '"]');
    if (!box) return;
    const form = box.querySelector('.knob-form');
    if (!form) return;

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const typed = form.querySelector('[name=value]').value.trim();
      const reason = form.querySelector('[name=reason]').value.trim();
      const value = /^-?\d+$/.test(typed) ? Number(typed) : null;

      /* CHECKED HERE SO SOMEBODY WHO MISTYPED IS TOLD AT ONCE — and because the
         audit entry is written FIRST on the server, so a round trip that records
         a change and then refuses it would leave the log saying something
         happened that did not. The check that matters is still the API's, which
         refuses the same things against the same declaration. */
      if (value === null) {
        return say(form, 'bad', 'A whole number. This one is counted in '
          + counted(one.unit).toLowerCase() + '.');
      }
      if (value < one.least || value > one.most) {
        return say(form, 'bad', 'This one takes ' + one.least + ' to ' + one.most
          + '. That range is part of what declares it and cannot be moved from here — '
          + 'it is where the mistake of a digit too many is caught.');
      }
      if (!reason) {
        return say(form, 'bad', 'Say why in a few words. A parameter is replaced rather '
          + 'than appended, so this log is the whole history of what the platform was '
          + 'set to.');
      }

      say(form, '', 'Saving…');
      try {
        await put('/console/api/v1/settings/' + encodeURIComponent(one.name),
          { value, reason });
      } catch (e) {
        return say(form, 'bad', e instanceof RequestError && e.status === 403
          ? 'That asks for an operator.'
          : e.message);
      }

      /* REDRAWN FIRST AND SPOKEN INTO SECOND. Writing the confirmation and then
         rebuilding replaces the node it was written into, so the message would
         disappear at the moment it is earned — a mistake this console has
         already made once, on the refund form. */
      await show();
      const again = knobs.querySelector('[data-name="' + cssName(one.name) + '"] .knob-form');
      say(again, 'ok', 'Saved. Every part of the platform that reads this is on the new '
        + 'number within fifteen seconds — the servers keep a short snapshot rather than '
        + 'asking the database on every request.');
    });
  }

  return { title: section.name, el };
}

/* WHETHER ANYBODY HAS EVER DECIDED THIS ONE, in a sentence rather than a badge.

   The two states are genuinely different decisions:

     a row       somebody chose this number, on a day, for a reason the history
                 has — so changing it is arguing with a decision
     no row      the platform is on what the code shipped with, and nobody has
                 ever had an opinion — so changing it is having the first one

   A field showing the number in both cases looks identical, and the difference
   is exactly what somebody about to type needs to know. */
function saying(one) {
  if (one.set) {
    return 'Set to ' + one.value + (one.since ? ' on ' + day(one.since) : '')
      + '. The code ships with ' + one.fallback + '.'
      + (one.value === one.fallback
        ? ' Somebody set it back to what it was, which is a decision and not an absence.'
        : '');
  }
  return 'Nobody has changed this. It is on ' + one.fallback + ', which is what the code '
    + 'ships with — and what it falls back to if these rows are ever unreadable.';
}

// What the field is labelled, from the unit the declaration carries. An unknown
// unit is still a number worth setting, so it gets the plain label rather than
// nothing.
function counted(unit) {
  const known = {
    count: 'How many',
    percent: 'Per cent',
    days: 'Days',
    hours: 'Hours',
    minutes: 'Minutes',
    seconds: 'Seconds',
    bytes: 'Bytes',
  };
  return known[unit] || 'Value';
}

/* A NAME IS SAFE IN AN ATTRIBUTE SELECTOR because the server's own CHECK says
   what one may contain — lowercase, digits and dots. This quotes it anyway: a
   selector built from data is the kind of line that stays correct until the day
   the shape of the data changes, and the fix costs nothing today. */
function cssName(name) {
  return String(name).replace(/["\\]/g, '\\$&');
}

function day(iso) {
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? String(iso) : at.toLocaleDateString();
}

function say(form, how, text) {
  if (!form) return;
  const where = form.querySelector('.signin-notice');
  if (!where) return;
  where.className = 'signin-notice' + (how ? ' ' + how : '');
  where.textContent = text;
}
