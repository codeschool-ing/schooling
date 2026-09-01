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

   # AND THE SAME NUMBERS ONCE, AS A SHAPE

   The list answers "is this question broken" one question at a time. It cannot
   answer "what shape is this bank of questions", and that is the question
   somebody opening this screen for the first time actually has — a bank where
   everything sits at 95% correct and no discrimination is a bank measuring
   nothing, and no amount of reading cards one at a time says so.

   So the chart is the canonical picture of item analysis: how often each
   question is got right, across; how well it separates students, up. THE
   THRESHOLDS ARE THE LINES ON IT, which is the whole reason this chart earns
   its place here rather than being decoration — a dot below the line labelled
   `Inverted` IS an inverted question, so the picture carries what each point was
   judged against (K-16) without repeating one number the cards already show.

   The colour of a dot says the same thing its position does, deliberately, and
   that is why there is no legend: position is the finding and colour is the
   echo of it. A legend would be a second place to look up something the chart
   already states twice.
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';
import { txt } from '../../assets/language.js';

/* What each verdict means, in a sentence, because the word alone is a category
   and the reader needs the consequence. `inverted` is the only one that is a
   defect; the rest are notes.

   A LIST OF OBJECTS AND NOT A MAP OF PAIRS. `verdict` is what the server sends
   and never moves; `name` and `meaning` are read by a person and go through
   `txt()` where they are drawn, which no static scan can see — so
   `language_test.go` reads this list and checks both halves have Portuguese,
   and it can only do that if the halves are named. A pair says nothing about
   which of its two strings is a wire value and which is a sentence. */
const VERDICTS = [
  {
    verdict: 'inverted',
    name: 'Inverted',
    meaning: 'The students who did well on the paper got this right LESS often than the students who did badly. That is a wrong key, an ambiguous prompt, or a question asking something other than what it looks like.',
  },
  {
    verdict: 'weak',
    name: 'Weak',
    meaning: 'It barely separates students. Worth a look, and not evidence of anything broken.',
  },
  {
    verdict: 'too-easy',
    name: 'Too easy',
    meaning: 'Almost everybody gets it right, so it measures nothing. A content problem rather than a broken question.',
  },
  {
    verdict: 'fine',
    name: 'Fine',
    meaning: 'Doing its job.',
  },
  {
    verdict: 'insufficient',
    name: 'Not enough answers',
    meaning: 'Nothing is being said about this one yet. It is the starting state of every question and it is not a criticism.',
  },
];

/* Where the chart's plot area sits inside its own viewBox, in the viewBox's
   units. The margins are the room the labels need and nothing else: the left is
   five characters of `+0.50`, the bottom is a line of ticks and the axis name
   under them, and the top is the one line the vertical thresholds label
   themselves on.

   AND THE RIGHT IS A GUTTER, WHICH THE FIRST DRAFT DID NOT HAVE. The two
   horizontal thresholds labelled themselves at the right end of their own line,
   inside the plot — which is exactly where a question that is too easy lives:
   high on the difficulty axis and, being too easy, near zero on the other. The
   first school this was opened against had its `too-easy` question drawn
   underneath the word `INVERTED`. A label that hides the point it explains is
   worse than no label, and it hides it SYSTEMATICALLY rather than by chance, so
   the words moved out of the picture rather than being nudged within it. */
const PLOT = { left: 52, right: 424, top: 24, bottom: 268 };
const CANVAS = '0 0 520 312';

/* THE AXES ARE THE STATISTIC'S OWN RANGE AND NOT THIS DATA'S.

   A proportion runs 0 to 1 and a discrimination index runs −1 to +1, so that is
   what is drawn, every time, for every school. Fitting the axes to the points
   would be the defect `funnel.js` names one screen over: the shape is the
   finding, and a chart that rescales itself is a chart where two schools cannot
   be compared, where last month cannot be compared to this one, and where the
   threshold lines land at a different height every time somebody edits a
   question. Half of the vertical range is usually empty. That emptiness is
   information — it is where the broken questions would be. */
const TICKS_X = [0, 0.25, 0.5, 0.75, 1];
const TICKS_Y = [1, 0.5, 0, -0.5, -1];

const atX = (share) => PLOT.left + (PLOT.right - PLOT.left) * bounded(share, 0, 1);
const atY = (index) =>
  PLOT.top + (PLOT.bottom - PLOT.top) * (1 - (bounded(index, -1, 1) + 1) / 2);

/* Neither statistic can leave its range by construction, and a value that did
   would be drawn off the canvas — invisible, rather than obviously wrong. It is
   pinned to the edge instead, where it is still a dot somebody can ask about. */
function bounded(value, low, high) {
  const n = Number(value);
  if (!Number.isFinite(n)) return low;
  return Math.min(high, Math.max(low, n));
}

export default async function questions(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('Questions')) + '</h1>' +
      '<p>' + esc(txt('What the answers say about each question, worst first. Every number that is a judgement is followed by what it was judged against — the thresholds come from the code that applied them, so this screen and the job cannot drift apart.')) + '</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const body = el.querySelector('#body');

  let schools;
  try {
    schools = (await get('/console/api/v1/schools')).schools || [];
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) + '</p></section>';
    return { title: section.name, el };
  }

  if (!schools.length) {
    body.innerHTML = '<section class="block"><p class="none">' +
      esc(txt('There are no schools on this platform yet, so there are no questions to have been answered.')) +
      '</p></section>';
    return { title: section.name, el };
  }

  let school = schools[0].id;

  body.innerHTML =
    '<section class="block">' +
      '<div class="block-top"><h2>' + esc(txt('Which school')) + '</h2></div>' +
      '<form id="ask" class="list-bar" novalidate>' +
        '<label class="field">' +
          '<span>' + esc(txt('School')) + '</span>' +
          '<select id="school">' +
            schools.map((s) =>
              '<option value="' + esc(s.id) + '">' + esc(s.name) + '</option>').join('') +
          '</select>' +
        '</label>' +
        '<span class="list-count">' + esc(txt('Real students only — see below.')) + '</span>' +
      '</form>' +
    '</section>' +
    '<div id="rows"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const rows = body.querySelector('#rows');
  body.querySelector('#school').addEventListener('change', (event) => {
    school = event.target.value;
    draw();
  });

  await draw();
  return { title: section.name, el };

  async function draw() {
    rows.innerHTML = '<p class="checking">' + esc(txt('Reading…')) + '</p>';
    const mine = school;

    let answer;
    try {
      answer = await get('/console/api/v1/schools/' + encodeURIComponent(school) + '/questions');
    } catch (e) {
      if (mine !== school) return;
      rows.innerHTML = '<section class="block"><p class="none">' + esc(txt(e.message)) + '</p></section>';
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
          '<div class="block-top"><h2>' +
            esc(txt('Nothing has been computed for this school')) + '</h2></div>' +
          '<p class="empty-note">' +
            esc(txt('The nightly analysis has never written a row here. That is not the same as every question being fine — it is nobody having looked. If this school has been answering questions for a while, the job is what to check.')) +
          '</p>' +
        '</section>';
      return;
    }

    rows.innerHTML =
      /* THE DATE IS ISO AND STAYS ISO — see `said` at the foot of this file —
         so what moves between languages is the word in front of it, and it is
         one key with a hole because the word does not always go in front. */
      '<p class="as-of mono">' +
        esc(txt('Computed %s').replace('%s', said(answer.computed_at))) + '</p>' +
      (all.length === 0
        ? '<section class="block"><p class="none">' +
          esc(txt('The analysis ran and found no question with any answers to it yet.')) +
          '</p></section>'
        : '<section class="block">' +
            '<div class="block-top">' +
              '<h2>' + esc((answer.school && answer.school.name) || '') + '</h2>' +
              /* TWO WHOLE SENTENCES rather than a noun with an `s` appended to
                 it, which is the plural this console has already shipped wrong
                 once — "1 trilhas", a count of one and a plural after it. */
              '<span class="block-score mono">' +
                esc(all.length === 1
                  ? txt('one question')
                  : txt('%d questions').replace('%d', all.length)) +
              '</span>' +
            '</div>' +
            scatter(all, bars) +
            '<ol class="items">' + all.map((q) => item(q, bars)).join('') + '</ol>' +
          '</section>') +
      thresholds(bars, answer.why_no_switch);
  }

/* THE PICTURE.

   ONE IMAGE WITH ONE LABEL, and not one labelled shape per question. The list
   under it is the accessible answer and the better one for everybody — the same
   division `countries.js` makes, for the same reason: a screen reader handed
   sixty dots reads out sixty coordinates in whatever order the array happens to
   be in, which is worse than useless, and the cards below already say every
   number in sentences.

   # A QUESTION NOBODY HAS ANSWERED ENOUGH IS NOT A DOT AT ZERO

   Below the minimum sample, the job writes a discrimination of zero, because it
   has not measured one. Plotting that puts a dot on the line marked `Weak` and
   claims a measurement nobody made — the same mistake the funnel refuses when
   it draws an unmeasured step as a sentence instead of an empty bar. Those
   questions are counted in a sentence under the chart and left off it.

   THE TEST IS THE ROW'S OWN NUMBERS AND NOT THE WORD `insufficient`. Verdicts
   are a closed list this screen may one day not fully know, and a sixth one it
   has never heard of must not be silently plotted at a zero it never measured.
   Comparing the answers to the minimum is the same condition the server
   applied, expressed in what it sent. */
  function scatter(all, bars) {
    const plotted = all.filter((q) => q.attempts >= q.minimum_sample);
    const held = all.length - plotted.length;

    /* TWO WHOLE SENTENCES, because a count can be one. This console has shipped
       a plural assembled from a letter once and the fix is never a rule. */
    const note = held === 0
      ? ''
      : (held === 1
        ? txt('One question is not on the chart: too few people have answered it, and an index nobody has measured is not a zero to draw. It is in the list below, with the number of answers it still needs.')
        : txt('%d questions are not on the chart: too few people have answered them, and an index nobody has measured is not a zero to draw. They are in the list below, with the number of answers each still needs.')
          .replace('%d', held));

    /* NO AXES WITH NOTHING BETWEEN THEM. An empty plot area under two labelled
       scales reads as "every question is broken and none of them plotted"; the
       sentence alone says what actually happened. */
    if (!plotted.length) {
      return note ? '<p class="hint">' + esc(note) + '</p>' : '';
    }

    const label = txt('A scatter plot of the questions on this screen: how often each one is got right, across; how well each one separates students, up. The lines on it are the thresholds. The list below has every question and its numbers.');

    return '<figure class="scatter">' +
      '<svg viewBox="' + CANVAS + '" role="img" aria-label="' + esc(label) + '" ' +
        'preserveAspectRatio="xMidYMid meet">' +

        TICKS_X.map((t) => rule(atX(t), PLOT.top, atX(t), PLOT.bottom)).join('') +
        TICKS_Y.map((t) => rule(PLOT.left, atY(t), PLOT.right, atY(t))).join('') +

        /* The thresholds, under the dots so a dot sitting exactly on one is not
           drawn over by the line that judged it. Only `Inverted` is coloured,
           because only `Inverted` is a defect — the other three are notes, and
           four red lines would say this chart is mostly bad news. */
        across(bars.weak_below, txt('Weak'), false) +
        across(bars.inverted_below, txt('Inverted'), true) +
        down(bars.too_hard_below, txt('Very hard'), 'start', 4) +
        down(bars.too_easy_above, txt('Too easy'), 'end', -4) +

        plotted.map((q) => dot(q)).join('') +

        /* The axes last and on top, so the leftmost and lowest dots do not sit
           over the lines that give them their meaning. */
        '<line class="scatter-axis" x1="' + PLOT.left + '" y1="' + PLOT.top +
          '" x2="' + PLOT.left + '" y2="' + PLOT.bottom + '"/>' +
        '<line class="scatter-axis" x1="' + PLOT.left + '" y1="' + PLOT.bottom +
          '" x2="' + PLOT.right + '" y2="' + PLOT.bottom + '"/>' +

        TICKS_X.map((t) =>
          '<text class="scatter-tick" x="' + atX(t).toFixed(1) + '" y="' + (PLOT.bottom + 14) +
            '" text-anchor="middle">' + esc(share(t)) + '</text>').join('') +
        TICKS_Y.map((t) =>
          '<text class="scatter-tick" x="' + (PLOT.left - 8) + '" y="' + atY(t).toFixed(1) +
            '" text-anchor="end" dy=".32em">' + esc(signed(t)) + '</text>').join('') +

        /* THE AXIS NAMES ARE THE FIGURE LABELS FROM THE CARDS BELOW, the same
           two keys deliberately: somebody moving between the picture and a card
           is matching one word to the other, and two translations of one word
           would break that in every language but the one this is written in. */
        '<text class="scatter-title" x="' + ((PLOT.left + PLOT.right) / 2) +
          '" y="' + (PLOT.bottom + 36) + '" text-anchor="middle">' +
          esc(txt('Got it right')) + '</text>' +
        '<text class="scatter-title" transform="rotate(-90 14 ' +
          ((PLOT.top + PLOT.bottom) / 2) + ')" x="14" y="' +
          ((PLOT.top + PLOT.bottom) / 2) + '" text-anchor="middle" dy=".32em">' +
          esc(txt('Discrimination')) + '</text>' +
      '</svg>' +

      (note ? '<figcaption>' + esc(note) + '</figcaption>' : '') +
    '</figure>';
  }

  function rule(x1, y1, x2, y2) {
    return '<line class="scatter-grid" x1="' + x1.toFixed(1) + '" y1="' + y1.toFixed(1) +
      '" x2="' + x2.toFixed(1) + '" y2="' + y2.toFixed(1) + '"/>';
  }

  /* A threshold across the plot, labelled in the gutter beside it with the WORD
     and not the number. The number is on every card below and again under `How
     this is decided`; a third copy of it here would be a third thing to keep in
     step for no reading anybody does. The word is what makes the line mean
     something, and the axis opposite is where the number is read off.

     IN THE GUTTER AND NOT ON THE LINE — see `PLOT`. A word inside the plot area
     covers the dots at that height, and the dots at that height are the ones it
     is there to explain. */
  function across(value, word, bad) {
    if (value === undefined || value === null) return '';
    const y = atY(value);
    return '<line class="scatter-bar' + (bad ? ' scatter-bar-bad' : '') +
        '" x1="' + PLOT.left + '" y1="' + y.toFixed(1) +
        '" x2="' + PLOT.right + '" y2="' + y.toFixed(1) + '"/>' +
      '<text class="scatter-word' + (bad ? ' scatter-word-bad' : '') +
        '" x="' + (PLOT.right + 6) + '" y="' + y.toFixed(1) +
        '" text-anchor="start" dy=".32em">' + esc(word) + '</text>';
  }

  /* And down it. These two label themselves on the line above the plot rather
     than beside the line, because a word rotated ninety degrees is a word
     nobody reads; the anchor leans each of them inwards so neither runs off its
     own edge of the picture. */
  function down(value, word, anchor, dx) {
    if (value === undefined || value === null) return '';
    const x = atX(value);
    return '<line class="scatter-bar" x1="' + x.toFixed(1) + '" y1="' + PLOT.top +
        '" x2="' + x.toFixed(1) + '" y2="' + PLOT.bottom + '"/>' +
      '<text class="scatter-word" x="' + (x + dx).toFixed(1) + '" y="' + (PLOT.top - 7) +
        '" text-anchor="' + anchor + '">' + esc(word) + '</text>';
  }

  /* One question. The `<title>` is a hover tooltip and NOT an accessibility
     claim — the SVG is one labelled image, so nothing in it is announced — and
     it holds only an id, a version and two numbers, which is a coordinate
     somebody quotes into the list below rather than a sentence to translate.

     THE CLASS IS THE VERDICT AND ONLY TWO OF THEM ARE STYLED, which is not an
     oversight: `fine` is brighter and `inverted` is red, and the other three
     fall through to the same quiet dot. A colour per verdict would be five
     categories to tell apart in a picture where the position already says which
     is which — and it would need a legend, which is the thing that makes charts
     unreadable. A verdict this screen has never heard of gets no class at all,
     the same closed-list rule the cards follow. */
  function dot(q) {
    const known = VERDICTS.find((v) => v.verdict === q.verdict);
    return '<circle class="scatter-dot' + (known ? ' scatter-dot-' + esc(q.verdict) : '') +
        '" cx="' + atX(q.difficulty).toFixed(1) + '" cy="' + atY(q.discrimination).toFixed(1) +
        '" r="4">' +
      '<title>' + esc(q.exercise_id + ' v' + q.version + ' · ' +
        share(q.difficulty) + ' · ' + signed(q.discrimination)) + '</title>' +
    '</circle>';
  }

  /* One question: what it is, what happened, and every judgement with its bar
     next to it. */
  function item(q, bars) {
    /* A VERDICT THIS SCREEN HAS NEVER HEARD OF IS DRAWN AS ITSELF, which is the
       closed-list rule this console follows everywhere: a sixth appears as the
       word the server sent rather than folded into the nearest of the five, so
       it looks like a thing nobody has styled yet instead of a wrong answer. */
    const known = VERDICTS.find((v) => v.verdict === q.verdict);
    const name = known ? txt(known.name) : q.verdict;
    const meaning = known ? txt(known.meaning) : '';
    const enough = q.attempts >= q.minimum_sample;

    return '<li class="item item-' + esc(q.verdict) + '">' +
      '<div class="item-top">' +
        '<span class="item-id mono">' + esc(q.exercise_id) + ' <span class="item-v">v' +
          q.version + '</span></span>' +
        '<span class="item-type mono">' + esc(q.type) + '</span>' +
        '<span class="item-verdict">' + esc(name) + '</span>' +
        (q.withdrawn
          ? '<span class="item-out">' + esc(txt('Out of circulation')) + '</span>'
          /* FLAGGED AND STILL BEING ASKED IS A REAL STATE and it is the one
             worth saying out loud: the sweep runs nightly, so a question found
             this afternoon is still in front of students tonight. */
          : (q.verdict === 'inverted'
            ? '<span class="item-still">' + esc(txt('Still being asked')) + '</span>'
            : '')) +
      '</div>' +

      (meaning ? '<p class="item-meaning">' + esc(meaning) + '</p>' : '') +

      /* EVERY BAR IS ONE WHOLE SENTENCE WITH THE NUMBERS PUNCHED OUT OF IT, and
         none of them is a phrase glued to a figure. "at or over " + n reads in
         English and nowhere else: the number goes elsewhere in the sentence in
         other languages, and a translator handed the fragment cannot move what
         they cannot see. */
      '<dl class="item-figures">' +
        figure(txt('Answers'), q.attempts,
          (enough
            ? txt('at or over %d, the minimum to say anything')
            : txt('under %d, the minimum to say anything')).replace('%d', q.minimum_sample),
          !enough) +

        figure(txt('Got it right'),
          txt('%s (%c of %a)')
            .replace('%s', share(q.difficulty))
            .replace('%c', q.correct)
            .replace('%a', q.attempts),
          txt('too easy at %e and up, very hard under %h — hard is not a fault')
            .replace('%e', share(bars.too_easy_above))
            .replace('%h', share(bars.too_hard_below)),
          false) +

        figure(txt('Discrimination'), signed(q.discrimination),
          txt('inverted at %i and under, weak under %w')
            .replace('%i', signed(bars.inverted_below))
            .replace('%w', signed(bars.weak_below)),
          q.verdict === 'inverted') +

        figure(txt('The two groups'),
          txt('%s strong, %w weak')
            .replace('%s', q.strong_group)
            .replace('%w', q.weak_group),
          txt('the top and bottom %p% by the REST of the paper, so a question is not part of its own ranking')
            .replace('%p', Math.round((bars.group_share || 0) * 100)),
          false) +
      '</dl>' +

      /* THE DATES ARE NOT A JUDGEMENT and they sit outside the figures for that
         reason: every entry above is a number with a bar under it, and a date
         with an empty space where the bar goes reads as a threshold nobody
         wrote. */
      '<p class="item-when mono">' +
        esc(txt('Answered %a to %b')
          .replace('%a', said(q.first_answer))
          .replace('%b', said(q.last_answer))) + '</p>' +
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
      '<div class="block-top"><h2>' + esc(txt('How this is decided')) + '</h2></div>' +
      /* `decided` AND NOT `facts`: the console's `.facts` is a grid of `.fact`
         tiles, and a definition list dropped into it lays out as four columns
         with terms and definitions interleaved. A class name that already
         belongs to another screen's layout is the defect this codebase met on
         `.steps`, and it is one borrowed word away every time. */
      '<dl class="decided">' +
        '<dt>' + esc(txt('Minimum sample')) + '</dt><dd>' +
          esc(txt('%d answers before anything is said. Classical item analysis’s number, and where the index stops being dominated by which particular people sat the paper.')
            .replace('%d', bars.minimum_sample)) + '</dd>' +

        '<dt>' + esc(txt('Groups')) + '</dt><dd>' +
          esc(txt('The top and bottom %p% of attempts, ranked by the rest of the paper. Ranking by the WHOLE paper puts a question inside its own ranking, which hid an inverted key on every paper length this platform sets.')
            .replace('%p', Math.round((bars.group_share || 0) * 100))) + '</dd>' +

        /* THE SAME FOUR WORDS AS THE VERDICTS ABOVE, and deliberately the same
           keys: the heading of a threshold and the verdict it decides have to
           read alike, or somebody matching one to the other is comparing two
           translations of one word. */
        '<dt>' + esc(txt('Inverted')) + '</dt><dd>' +
          esc(txt('Discrimination at %s or under. The only verdict that is a defect, and the only one this system can find without a person.')
            .replace('%s', signed(bars.inverted_below))) + '</dd>' +

        '<dt>' + esc(txt('Weak')) + '</dt><dd>' +
          esc(txt('Under %s. A note.').replace('%s', signed(bars.weak_below))) + '</dd>' +

        '<dt>' + esc(txt('Too easy')) + '</dt><dd>' +
          esc(txt('%s or more get it right.').replace('%s', share(bars.too_easy_above))) + '</dd>' +

        '<dt>' + esc(txt('Very hard')) + '</dt><dd>' +
          esc(txt('Under %s get it right. Reported and never condemned on its own — a question almost nobody answers may be an excellent one.')
            .replace('%s', share(bars.too_hard_below))) + '</dd>' +

        '<dt>' + esc(txt('Who is counted')) + '</dt><dd>' +
          esc(txt(whyNoSwitch || '')) + '</dd>' +
      '</dl>' +
    '</section>';
  }
}

/* ---------- saying a number the way it is meant ---------- */

const share = (v) => (v === undefined || v === null ? '—' : Math.round(v * 100) + '%');
const signed = (v) =>
  (v === undefined || v === null ? '—' : (v > 0 ? '+' : '') + Number(v).toFixed(2));

/* A date, or a dash. `new Date('')` is Invalid Date and prints as one, which is
   how "there is none" turns into a word nobody can act on.

   THIS IS THE ONE DATE ON THIS SCREEN THAT IS NOT `language.js`'s `day()`, and
   it is ISO on purpose. Every date here sits in a `mono` line beside an exercise
   id and a version — it is a coordinate somebody quotes into a query, not a day
   somebody reads — and `2026-08-31` is the same coordinate in every language.
   The words AROUND it move; the date does not. */
function said(iso) {
  if (!iso) return '—';
  const at = new Date(iso);
  if (Number.isNaN(at.getTime())) return '—';
  return at.toISOString().slice(0, 10);
}
