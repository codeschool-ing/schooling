/* ==========================================================================
   What the answers say about a question.

   THIS IS THE HALF OF PHASE 4 THAT `Done when` NAMES FIRST — "a question with a
   broken answer key is found by the statistics". The finding has worked since
   the discrimination index was corrected; until now the only way to see the
   result was to read a cron job's log or query the table by hand.

   # EVERY NUMBER THAT IS A JUDGEMENT CARRIES ITS BAR

   A verdict without the threshold behind it is an opinion. `−0.32` means nothing
   to somebody who does not know that inverted starts at −0.10, and looking it up
   is a thing nobody does at eleven at night. So every judged number is followed
   by what it was judged against.

   NONE OF THOSE NUMBERS IS WRITTEN IN THIS FILE. They arrive on the answer, from
   the Go package that applied them. A screen holding its own copy of `-0.10`
   would go quietly wrong the day the constant moved — it would keep saying what
   the bar used to be, and somebody would read a question as just above a line it
   is under.

   # AND WHEN THE ROLLUP WAS MADE, WHICH IS THE FAILURE NOBODY SEES

   These are a cache of a nightly job. If it has been failing for a week, every
   number here is a week old and looks exactly like this morning's. The date is
   at the top, and a rollup that was NEVER made says so instead of showing an
   empty table — a school with no statistics and a job that never ran look
   identical in the data and are different problems.

   # THERE IS NO POPULATION SWITCH, AND THE SCREEN SAYS WHY

   The funnel next door has one. This screen shows what the nightly job wrote,
   and that job counts real people only, because it WITHDRAWS questions from
   circulation (K-11). A switch here would be a control with nothing behind it.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';

/* What each verdict means, in a sentence, because the word alone is a category
   and the reader needs the consequence. `inverted` is the only one that is a
   defect; the rest are notes. */
const VERDICTS = {
  inverted: ['Inverted', 'The students who did well on the paper got this right LESS often ' +
    'than the students who did badly. That is a wrong key, an ambiguous prompt, or a ' +
    'question asking something other than what it looks like.'],
  weak: ['Weak', 'It barely separates students. Worth a look, and not evidence of anything ' +
    'broken.'],
  'too-easy': ['Too easy', 'Almost everybody gets it right, so it measures nothing. A content ' +
    'problem rather than a broken question.'],
  fine: ['Fine', 'Doing its job.'],
  insufficient: ['Not enough answers', 'Nothing is being said about this one yet. It is the ' +
    'starting state of every question and it is not a criticism.'],
};

export default async function questions(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">Measure</span>' +
      '<h1>Questions</h1>' +
      '<p>What the answers say about each question, worst first. Every number ' +
      'that is a judgement is followed by what it was judged against — the ' +
      'thresholds come from the code that applied them, so this screen and the ' +
      'job cannot drift apart.</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">Reading…</p></div>';

  const body = el.querySelector('#body');

  let schools;
  try {
    schools = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  if (!schools.length) {
    body.innerHTML = '<section class="block"><p class="none">There are no schools on this ' +
      'platform yet, so there are no questions to have been answered.</p></section>';
    return { title: section.name, el };
  }

  let school = schools[0].id;

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>Which school</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>School</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<span class="list-count">Real students only — see below.</span>' +
      '</form>' +
    '</section>' +
    '<div id="rows"><p class="checking">Reading…</p></div>';

  const rows = body.querySelector('#rows');
  body.querySelector('#school').addEventListener('change', (event) => {
    school = event.target.value;
    draw();
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    rows.innerHTML = '<p class="checking">Reading…</p>';
    const mine = school;

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(school) + '/questions');
    } catch (e) {
      if (mine !== school) return;
      rows.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
      return;
    }
    if (mine !== school) return;

    const bars = answer.thresholds || {};
    const all = answer.questions || [];

    /* THE JOB THAT NEVER RAN IS ITS OWN SCREEN. Showing an empty table for it
       would say "no question here has a problem", which is a claim nothing has
       checked. */
    if (!answer.computed) {
      rows.innerHTML =
        '<section class="block">' +
          '<div class="block-top"><h2>Nothing has been computed for this school</h2></div>' +
          '<p class="empty-note">The nightly analysis has never written a row here. That is ' +
          'not the same as every question being fine — it is nobody having looked. If this ' +
          'school has been answering questions for a while, the job is what to check.</p>' +
        '</section>';
      return;
    }

    rows.innerHTML =
      '<p class="as-of mono">Computed ' + esc(said(answer.computed_at)) + '</p>' +
      (all.length === 0
        ? '<section class="block"><p class="none">The analysis ran and found no question ' +
          'with any answers to it yet.</p></section>'
        : '<section class="block">' +
            '<div class="block-top">' +
              '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
              '<span class="block-score mono">' + all.length +
                (all.length === 1 ? ' question' : ' questions') + '</span>' +
            '</div>' +
            '<ol class="items">' + all.map((q) => item(q, bars)).join('') + '</ol>' +
          '</section>') +
      thresholds(bars, answer.why_no_switch);
  }

  /* One question: what it is, what happened, and every judgement with its bar
     next to it. */
  function item(q, bars) {
    const [name, meaning] = VERDICTS[q.verdict] || [q.verdict, ''];
    const enough = q.attempts >= q.minimum_sample;

    return '<li class="item item-' + esc(q.verdict) + '">' +
      '<div class="item-top">' +
        '<span class="item-id mono">' + esc(q.exercise_id) + ' <span class="item-v">v' +
          q.version + '</span></span>' +
        '<span class="item-type mono">' + esc(q.type) + '</span>' +
        '<span class="item-verdict">' + esc(name) + '</span>' +
        (q.withdrawn
          ? '<span class="item-out">Out of circulation</span>'
          /* FLAGGED AND STILL BEING ASKED IS A REAL STATE and it is the one
             worth saying out loud: the sweep runs nightly, so a question found
             this afternoon is still in front of students tonight. */
          : (q.verdict === 'inverted'
            ? '<span class="item-still">Still being asked</span>'
            : '')) +
      '</div>' +

      (meaning ? '<p class="item-meaning">' + esc(meaning) + '</p>' : '') +

      '<dl class="item-figures">' +
        figure('Answers', q.attempts,
          (enough ? 'at or over ' : 'under ') + q.minimum_sample + ', the minimum to say anything',
          !enough) +
        figure('Got it right', share(q.difficulty) + ' (' + q.correct + ' of ' + q.attempts + ')',
          'too easy at ' + share(bars.too_easy_above) + ' and up, ' +
          'very hard under ' + share(bars.too_hard_below) + ' — hard is not a fault', false) +
        figure('Discrimination', signed(q.discrimination),
          'inverted at ' + signed(bars.inverted_below) + ' and under, ' +
          'weak under ' + signed(bars.weak_below), q.verdict === 'inverted') +
        figure('The two groups', q.strong_group + ' strong, ' + q.weak_group + ' weak',
          'the top and bottom ' + Math.round((bars.group_share || 0) * 100) +
          '% by the REST of the paper, so a question is not part of its own ranking', false) +
      '</dl>' +

      /* THE DATES ARE NOT A JUDGEMENT and they sit outside the figures for that
         reason: every entry above is a number with a bar under it, and a date
         with an empty space where the bar goes reads as a threshold nobody
         wrote. */
      '<p class="item-when mono">Answered ' + esc(said(q.first_answer)) + ' to ' +
        esc(said(q.last_answer)) + '</p>' +
    '</li>';
  }

  function figure(label, value, bar, bad) {
    return '<div class="figure' + (bad ? ' figure-bad' : '') + '">' +
      '<dt>' + esc(label) + '</dt>' +
      '<dd><span class="figure-value mono">' + esc(String(value)) + '</span>' +
        (bar ? '<span class="figure-bar">' + esc(bar) + '</span>' : '') +
      '</dd>' +
    '</div>';
  }

  /* THE BARS ONCE MORE, TOGETHER, and the sentence about the population. Beside
     each number they answer "is this one bad"; here they answer "what is this
     screen deciding", which is a different question and the one somebody asks
     the first time they open it. */
  function thresholds(bars, whyNoSwitch) {
    return '<section class="block">' +
      '<div class="block-top"><h2>How this is decided</h2></div>' +
      /* `decided` AND NOT `facts`: the console's `.facts` is a grid of `.fact`
         tiles, and a definition list dropped into it lays out as four columns
         with terms and definitions interleaved. A class name that already
         belongs to another screen's layout is the defect this codebase met on
         `.steps`, and it is one borrowed word away every time. */
      '<dl class="decided">' +
        '<dt>Minimum sample</dt><dd>' + bars.minimum_sample + ' answers before anything is ' +
          'said. Classical item analysis’s number, and where the index stops being ' +
          'dominated by which particular people sat the paper.</dd>' +
        '<dt>Groups</dt><dd>The top and bottom ' + Math.round((bars.group_share || 0) * 100) +
          '% of attempts, ranked by the rest of the paper. Ranking by the WHOLE paper puts a ' +
          'question inside its own ranking, which hid an inverted key on every paper length ' +
          'this platform sets.</dd>' +
        '<dt>Inverted</dt><dd>Discrimination at ' + signed(bars.inverted_below) + ' or under. ' +
          'The only verdict that is a defect, and the only one this system can find without ' +
          'a person.</dd>' +
        '<dt>Weak</dt><dd>Under ' + signed(bars.weak_below) + '. A note.</dd>' +
        '<dt>Too easy</dt><dd>' + share(bars.too_easy_above) + ' or more get it right.</dd>' +
        '<dt>Very hard</dt><dd>Under ' + share(bars.too_hard_below) + ' get it right. Reported ' +
          'and never condemned on its own — a question almost nobody answers may be an ' +
          'excellent one.</dd>' +
        '<dt>Who is counted</dt><dd>' + esc(whyNoSwitch || '') + '</dd>' +
      '</dl>' +
    '</section>';
  }
}

/* ---------- saying a number the way it is meant ---------- */

const share = (v) => (v === undefined || v === null ? '—' : Math.round(v * 100) + '%');
const signed = (v) =>
  (v === undefined || v === null ? '—' : (v > 0 ? '+' : '') + Number(v).toFixed(2));

/* A date, or a dash. `new Date('')` is Invalid Date and prints as one, which is
   how "there is none" turns into a word nobody can act on. */
function said(iso) {
  if (!iso) return '—';
  const at = new Date(iso);
  if (Number.isNaN(at.getTime())) return '—';
  return at.toISOString().slice(0, 10);
}
