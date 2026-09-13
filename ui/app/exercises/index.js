/* ==========================================================================
   The shared wrapper around the seven types, and the assessment wizard.

   Everything that does not depend on the type lives here — prompt, hint,
   button, verdict — and each type module handles only the interactive middle.
   The contract:

     types          : which `type` values this module answers for
     selfCompleting : optional. `true` when the exercise itself can tell that it
                      is finished (the matching type, which checks pair by
                      pair). The wrapper hides "Responder" and waits.
     body(ex, uid)                       → HTML of the middle
     setup(root, {exercise, done})  → optional: event listeners
     collect(root)                       → the answer, or null if unanswered
     reveal(root, ex, verdict)           → marks what was right, AFTERWARDS

   THE `_verification` BADGE LEFT THE STUDENT'S SCREEN. It is still in the data
   and still filters in `lessonExercises` — the pipeline docs say it is what
   decides what the portal publishes first, and that is a publishing decision,
   not information for someone who is studying. Telling a student "structural
   check only" warns them that this exercise may be no good; if it may be no
   good, it should not have been published.
   ========================================================================== */

import { formatted, esc } from '../text.js';
import * as api from '../api.js';
import { saveAnswer, answerFor } from '../state.js';
import { wireReport } from '../report.js';

import choices from './choices.js';
import ordering from './ordering.js';
import matching from './matching.js';
import expectedOutput from './expected-output.js';
import code from './code.js';
import expressionAnswer from './expression-answer.js';
/* THE THREE THE COPY LEFT BEHIND. This client came from `portal-frontend`,
   whose catalogue has no cloze, no numeric and no labelling; this school's
   does, and every one of them landed on "unknown exercise type" — on the exam
   paper, where a question nobody can answer is a mark nobody can earn. They are
   ported from the interface this one replaced, keyboard paths and all. */
import cloze from './cloze.js';
import numeric from './numeric.js';
import labelling from './labelling.js';

const MODULES = [choices, ordering, matching, expectedOutput, code, expressionAnswer,
  cloze, numeric, labelling];

const REGISTRY = {};
MODULES.forEach((m) => m.types.forEach((t) => { REGISTRY[t] = m; }));

export const isKnownType = (t) => Boolean(REGISTRY[t]);

/* `options.exam` HOLDS THE FEEDBACK BACK. In an exam the student answers and
   moves on: the verdict, the justification and the "try again" only exist once
   the exam closes. Feedback on every question during an exam is what lets you
   try until you get it right, and then it stops measuring anything. The answer
   is still recorded normally — what changes is only what the screen says, and
   when. */
/* WHAT AN ANSWER IS FILED UNDER. The id where there is one, and a made-up key
   from the question's place where there is not — the offline bundle's sample
   data has no ids. It is a function rather than a line inside `buildExercise`
   because the wizard has to ask the same question about a card it has not
   built yet, and two spellings of one key is how half of them go missing. */
export const answerKey = (ex, ix) => ex.id || `${ex.course}:${ex.topic}:${ix}`;

export function buildExercise(ex, ctx, ix, options = {}) {
  const mod = REGISTRY[ex.type];
  const exam = Boolean(options.exam);
  const uid = answerKey(ex, ix);
  const el = document.createElement('article');
  el.className = 'ex ex-' + ex.type + (exam ? ' ex-exam' : '');
  // the DOM id: answers are stored under it, and it is how you can tell WHICH
  // exercise is on screen without depending on the prompt text
  el.dataset.ex = uid;

  if (!mod) {
    el.innerHTML = '<p class="ex-error">' + txt('unknown exercise type') + ': ' + esc(ex.type) + '</p>';
    return el;
  }

  el.innerHTML =
    '<header class="ex-top">' +
      '<span class="ex-type">' + txt(ex.type) + '</span>' +
      (ex.difficulty ? '<span class="ex-difficulty">' + txt(ex.difficulty) + '</span>' : '') +
    '</header>' +
    /* SOME PROMPTS ARE THE CONTROL. A cloze is a sentence with input boxes
       standing in its holes, so printing it here as well would put the same
       sentence on screen twice — once with the holes and once without. A module
       that draws its own says so; every other type gets it from here and never
       has to think about it. */
    (mod.promptIsTheBody ? '' : '<p class="ex-prompt">' + formatted(ex.prompt) + '</p>') +
    '<div class="ex-body">' + mod.body(ex, uid, { exam }) + '</div>' +
    // the hint is scaffolding for someone learning; in an exam it is a cheat sheet
    (ex.socraticHint && !exam
      ? '<details class="ex-hint"><summary>' + txt('hint') + '</summary><p>' + formatted(ex.socraticHint) + '</p></details>'
      : '') +
    '<div class="ex-actions">' +
      (selfCompleting(mod, exam, ex) ? '' : '<button type="button" class="btn btn-primary ex-answer">' +
        txt(exam ? 'Record answer' : 'Answer') + '</button>') +
      (exam || options.drill
        ? ''
        : '<button type="button" class="btn btn-ghost ex-retry" hidden>' + txt('Try again') + '</button>') +
    '</div>' +
    '<div class="ex-verdict" aria-live="polite"></div>' +

    /* AND, ON EVERYTHING BUT AN EXAM, THE WAY TO SAY THIS QUESTION IS WRONG.

       THE EXAM IS EXCLUDED AND THAT IS THE DECISION, not an omission. A paper
       is timed and held: a control that opens a form mid-question costs a
       student minutes they are being measured on, and the one thing a person
       is most likely to report during an exam — "the answer I gave was right" —
       is a verdict they have not been shown yet. The same question is
       reportable from the drill and from the assessment it belongs to, which is
       where somebody meets it again with nothing at stake.

       IT ASKS `canReport` BEFORE DRAWING rather than showing a control that
       explains itself when opened: signed out there is nothing to attach a
       report to, and in the offline copy there is nobody to send it to. */
    (!exam && ex.id && api.canReport()
      ? '<details class="report report-ex">' +
          '<summary>⚑ ' + txt('something is wrong with this question') + '</summary>' +
          '<div class="report-body"><p class="checking">' + txt('reading…') + '</p></div>' +
        '</details>'
      : '');

  const body = el.querySelector('.ex-body');

  // Built on first open — see `report.js` for why it is not built with the card.
  wireReport(el.querySelector('.report-ex'), { exerciseId: ex.id });

  /* WHEN THE CARD APPEARED. In a drill the time to answer is half of what the
     scheduler reads — the other half is whether it was right — because a
     student is never asked how well they felt they remembered (A-04). It is
     measured from the moment the question is on screen to the moment they
     commit, which is the only span that means anything to them. */
  const shownAt = performance.now();

  /* WHICH LESSON MARKS THIS ONE, and it can arrive two ways.

     A lesson's own assessment hands one down for the whole wizard — every
     question on the screen belongs to the same lesson. `redo` cannot: it
     gathers questions from wherever they were got wrong, so the lesson is a
     fact about the QUESTION and travels in its context.

     It matters more than it looks. Without it `redo` fell through to
     `api.grade` with no attempt, which is `gradeLocally` — the offline
     comparator, against a key the browser does not hold. Four of the nine
     types have no local grader at all, so a cloze or a numeric got wrong in a
     lesson and opened here sat at "not checked" for ever; and the four that do
     have one were compared against a question served without its answer. */
  const lesson = options.lesson
    || (ctx && ctx.lessonId ? { courseId: ctx.courseId, lessonId: ctx.lessonId } : null);

  /* Everything that happens to a card once it has a verdict, in one place
     because there are now two ways in: answering it, and coming back to a
     section where it was already answered. */
  function settle(v) {
    applyKey(ex, v);
    mod.reveal(body, ex, v);
    showVerdict(el, ex, v);
    const button = el.querySelector('.ex-answer');
    if (button) button.disabled = true;
    /* NOT IN A DRILL. The schedule moved the moment the answer landed, so a
       second attempt would be a second answer to a card that has already been
       counted — and the interval it earned would be the one for whichever try
       the student stopped on.

       IN A LESSON IT STAYS, and that is A-10 on a screen: nothing was
       recorded, so trying again costs nobody anything and the second attempt
       is the first thing the student does after reading why they were wrong. */
    const again = el.querySelector('.ex-retry');
    if (again) again.hidden = Boolean(options.drill);
  }

  async function check(answer) {
    const out = el.querySelector('.ex-verdict');
    if (answer === null) {
      out.className = 'ex-verdict v-empty';
      out.textContent = txt('Answer before checking.');
      return;
    }
    const button = el.querySelector('.ex-answer');
    if (button) button.disabled = true;
    out.className = 'ex-verdict v-waiting';
    out.textContent = txt('checking…');

    let v;
    try {
      /* FOUR PLACES AN ANSWER CAN BE MARKED, AND THEY ARE NOT FOUR GRADERS.
         A drill, a lesson and an exam are all marked on the server, against a
         payload this browser has never held; only the offline copy compares
         locally, because it is a bundle with the answers baked in and no server
         to ask.

         THE LESSON IS THE ONE THAT KEEPS NOTHING. A drill's answer moves a
         schedule and an exam's is a mark on a paper; this one leaves an event
         and no row (A-10), which is why the branch below reveals the key
         immediately and leaves the retry button showing. Getting it wrong and
         then getting it right is not a score being repaired — there is no
         score. */
      v = options.drill
        ? await api.drill(ex, answer, performance.now() - shownAt)
        : lesson
          ? await api.lessonAnswer(ex, answer, lesson)
          : await api.grade(ex, answer, options.attempt);
    } catch (e) {
      /* Only reachable inside a server-drawn exam, where the answer is a
         request and not a comparison. It has to be said rather than swallowed:
         the mark is on a paper that closes, and a silent failure would be
         discovered as a zero at submit. */
      out.className = 'ex-verdict v-empty';
      out.textContent = txt('That answer did not reach the server. Try again.') + ' ' + (e.message || '');
      if (button) button.disabled = false;
      return;
    }
    if (ctx) saveAnswer(ctx.courseId, ctx.lessonIx, uid, v, answer);

    if (exam) {
      /* Held back. The element remembers how to reveal itself later — the whole
         exam opens at once when it closes, and the student reviews what they
         answered. */
      out.className = 'ex-verdict v-recorded';
      out.innerHTML = '<strong>' + txt('answer recorded') + '</strong> ' +
        txt('the result comes at the end of the exam.');
      /* The verdict this closure captured is the one grading produced, which in
         a server-drawn exam is no verdict at all — the paper had no key to
         compare against. Submitting brings the real one back, so reveal takes
         an override, and the question is shown against the answer the server
         gave rather than against nothing. */
      el.revealExam = (fromServer) => {
        const shown = fromServer || v;
        if (fromServer) applyKey(ex, fromServer);
        mod.reveal(body, ex, shown);
        showVerdict(el, ex, shown);
      };
    } else {
      /* THE KEY ARRIVES WITH THE VERDICT, OR IT WAS HERE ALL ALONG. A drill is
         drawn without one and the server sends it back once the answer is in;
         the offline copy has it in the question already, and `applyKey` sees
         nothing to apply. Either way `reveal` is looking at a question that
         knows which answer was right. */
      settle(v);
    }
    el.dispatchEvent(new CustomEvent('exercise:answered', { bubbles: true, detail: { ex, v } }));
  }

  if (mod.setup) mod.setup(body, { exercise: ex, done: check, exam });

  /* "already solved" is useful memory in an assessment and hands over the
     answer key in an exam: the exam draws from the same bank as the lessons, so
     almost every question has been seen before. */
  const previous = !exam && ctx && answerFor(ctx.courseId, ctx.lessonIx, uid);

  /* ---------- A QUESTION ALREADY ANSWERED COMES BACK ANSWERED ----------

     Leaving a section and returning to it rebuilt every card blank — under a
     line saying two of five were right. The screen contradicted itself, and
     the contradiction was the honest half: the card really did know nothing.

     WHY THE ANSWER AND NOT JUST THE VERDICT. Every `reveal` reads the DOM to
     say what happened: `choices` marks what was ticked, `ordering` compares
     the rows IN THEIR CURRENT ORDER against the key, `cloze` puts the right
     word beside the typed one. Shown over a blank card they do not merely say
     less — they say something false. An ordering rebuilt from the shuffle and
     revealed would mark an order the student never gave and call it their
     mistake. So what goes back is the answer first, and the verdict over it.

     NOT IN `redo`, WHICH IS THE ONE PLACE THAT WANTS THE QUESTION BACK. That
     screen exists to ask it again; handing back the wrong answer and its
     verdict would make it a gallery of mistakes with a button under each.
     `fresh` is how it says so.

     A card whose answer was not kept — one answered before a reload, or in an
     exam — still gets the old sentence, which claims nothing it cannot show. */
  if (previous && previous.given !== undefined && previous.verdict && !options.fresh) {
    mod.restore?.(body, ex, previous.given);
    settle(previous.verdict);
  } else if (previous?.correct) {
    markAlreadyDone(el, previous);
  }

  const answerButton = el.querySelector('.ex-answer');
  if (answerButton) {
    answerButton.addEventListener('click', () => check(mod.collect(body, { exam, exercise: ex })));
  }

  const retry = el.querySelector('.ex-retry');
  if (retry) {
    retry.addEventListener('click', () => {
      const fresh = buildExercise(ex, ctx, ix, options);
      el.replaceWith(fresh);
      fresh.dispatchEvent(new CustomEvent('exercise:redone', { bubbles: true }));
    });
  }

  return el;
}

function showVerdict(el, ex, v) {
  const out = el.querySelector('.ex-verdict');

  if (v.correct === null) {
    /* Unchecked NEVER becomes passed — it is the pipeline's rule and it holds
       whole here: while there is no execution, the portal says it did not
       check. */
    out.className = 'ex-verdict v-pending';
    out.innerHTML = '<strong>' + txt('not checked') + '</strong> ' + esc(v.detail || '');
    return;
  }

  if (v.correct) {
    /* ITS OWN KEY, BECAUSE THIS ONE IS A SENTENCE AND THE OTHER TWO ARE A UNIT.

       It said `txt('correct')`, which is also what `7/12 correct` and
       `85% correct` say. One English word does both jobs and no other language
       has to: Portuguese translates the unit as `de acerto`, so this banner
       announced a right answer with the words "of accuracy" and nothing else.

       A key is a string in one grammatical role. Sharing one across two is a
       translation that can only be right about one of them, and the dictionary
       had picked the other. */
    out.className = 'ex-verdict v-right';
    out.innerHTML = '<strong>' + txt('That is right') + '</strong>';
    return;
  }

  out.className = 'ex-verdict v-wrong';
  let extra = '';
  if (v.partial) extra = ' ' + txt('not every pair was closed.');
  else if (typeof v.errors === 'number' && v.errors > 0) extra = '';
  /* WHY IT WAS WRONG, IN THE AUTHOR'S WORDS. Today that is the `trap` of an
     ordering exercise — which neighbouring pair gets swapped, and why it is
     tempting — and it arrives as `why` from whichever grader ran: the server's,
     which returns it only once the answer is in, or `grade.js`, which reads it
     off the question it is already holding.

     It is READ FROM THE VERDICT AND NOT FROM THE QUESTION, and that is the
     whole of it: on a paper the question a student was served has no `trap` in
     it, because before the answer the trap IS the answer. This used to say
     `ex.trap` and could therefore never fire on an exam. */
  if (v.why) {
    extra += '<span class="v-trap">' + formatted(v.why) + '</span>';
  }
  out.innerHTML = '<strong>' + txt('not yet') + '</strong>' + extra;
}

function markAlreadyDone(el, previous) {
  const out = el.querySelector('.ex-verdict');
  out.className = 'ex-verdict v-old';
  out.innerHTML = '<strong>' + txt('already solved') + '</strong> ' +
    txt('in') + ' ' + previous.attempts + ' ' +
    (previous.attempts === 1 ? txt('attempt') : txt('attempts'));
}

/* ==========================================================================
   THE ASSESSMENT WIZARD — one question at a time.

   Stacking seven exercises on one page makes people scroll to find where they
   left off, and shows all at once a volume that intimidates. One at a time
   gives focus, and the row of markers at the top says how much is left without
   taking up space.

   The markers are CLICKABLE: on a paper exam you skip the hard one and come
   back later, and blocking progress until you get it right would turn an
   assessment into a gate. The whole track is already a recommendation, not a
   lock — the assessment could not be stricter than it.
   ========================================================================== */

/* Whether the exercise closes itself.
 *
 * `matching` does during practice — the last pair lands and there is nothing
 * left to answer — and does NOT in an exam, where there is no feedback to close
 * on: the student pairs everything up and then presses the button like every
 * other type. So it is a question about the MODE and not only about the type.
 */
/* THE EXERCISE IS PASSED IN, BECAUSE ONE TYPE CANNOT ANSWER FROM THE MODE
   ALONE. `matching` finishes on its own only where the browser holds the answer
   key, and whether it does is a property of the PAYLOAD — the offline copy
   carries one and a question presented by the server does not. See its file.

   Every other type ignores the second argument, which is why this stays one
   call rather than a second hook. */
function selfCompleting(mod, exam, ex) {
  return typeof mod.selfCompleting === 'function'
    ? mod.selfCompleting(exam, ex)
    : Boolean(mod.selfCompleting);
}

/* Put the answer key back on the exercise, from what the server said.

   The renderers mark the right answer by reading the exercise — `choices[i]
   .correct`, `items` in order, `answer`. A server-drawn exam has none of those
   fields, on purpose, so revealing would mark nothing at all. Rather than teach
   three renderers a second way to find the same thing, the verdict is grafted
   back on before they run.

   IT IS NOT A LEAK. The key arrives with the verdict, which arrives at submit,
   which is when the exam is over — that is what revealing a result means. What
   never arrives is anything that was not asked: `code`'s hidden test cases are
   sealed too, and no verdict carries them. */
function applyKey(ex, v) {
  if (!v || v.expected === undefined || v.expected === null) return;
  switch (ex.type) {
    case 'quiz':
      (ex.choices || []).forEach((c, i) => {
        c.correct = i === v.expected;
        if (v.explanations && v.explanations[i]) c.why = v.explanations[i];
      });
      break;
    case 'multiple-choice':
      (ex.choices || []).forEach((c, i) => {
        c.correct = Array.isArray(v.expected) && v.expected.includes(i);
        if (v.explanations && v.explanations[i]) c.why = v.explanations[i];
      });
      break;
    case 'ordering':
      if (Array.isArray(v.expected)) ex.items = v.expected;
      break;
    case 'expected-output':
      ex.answer = String(v.expected);
      break;
    case 'matching':
      /* `expected[i]` is the right-hand text of pair i, which is exactly what
         the sealed half holds and what the public one had removed. */
      if (Array.isArray(v.expected)) {
        (ex.pairs || []).forEach((p, i) => { p.right = v.expected[i]; });
      }
      break;

    /* THE TWO THAT ARE TYPED, AND WHOSE RENDERERS READ THE VERDICT DIRECTLY.

       Nothing is put back on `ex` for these, because there is nothing on `ex`
       to put it on: a public cloze has blanks with no `accept` and a public
       numeric has no `value`, so there is no field a renderer would later read.
       They take the verdict as an argument instead — which is why both appear
       here doing nothing rather than being absent, where their absence would
       read as "these do not need a key" and that is the belief this whole
       family of defects came from. */
    case 'cloze':
    case 'numeric':
      break;
    default:
      break;
  }
}

export function buildAssessment(exercises, ctx, options = {}) {
  const exam = Boolean(options.exam);
  const el = document.createElement('div');
  el.className = 'wizard' + (exam ? ' wizard-exam' : '');
  /* THE DOTS START FROM WHAT IS ALREADY KNOWN, and they used to start grey
     over a section whose questions were all answered a minute ago. The header
     is the one thing that says how far through the set somebody is, so an
     empty header is the screen saying "you have not started this" to somebody
     who has finished it.

     NOT IN AN EXAM, where a dot's colour is the verdict being held back, and
     not in `redo`, which is asking again on purpose. */
  const states = exercises.map((ex, i) => {
    const c = Array.isArray(ctx) ? ctx[i] : ctx;
    const was = !exam && !options.fresh && c
      && answerFor(c.courseId, c.lessonIx, answerKey(ex, i));
    return was && was.given !== undefined
      ? { answered: true, correct: was.checked ? was.correct : null }
      : { answered: false, correct: null };
  });
  let current = 0;
  let submitted = false;
  let confirming = false;

  el.innerHTML =
    '<header class="wz-top">' +
      '<span class="wz-count"></span>' +
      /* A GROUP OF BUTTONS AND NOT A `tablist`.

         It was one, and axe called it critical: a tablist may contain tabs, and
         these are plain buttons. The fix is not to write `role="tab"` on them —
         that role promises arrow-key movement between the tabs and a panel each
         one controls, and this wizard implements neither. Claiming the
         semantics without the behaviour leaves somebody pressing arrow keys
         that do nothing, which is worse than not claiming them.

         What it actually is: a labelled group of buttons that jump to a
         question. Said that way it is accurate, and it is operable exactly as
         it looks — Tab to reach them, Enter to use one. */
      '<div class="wz-dots" role="group" aria-label="' + esc(txt('Questions on this paper')) + '"></div>' +
    '</header>' +
    '<div class="wz-stage"></div>' +
    '<footer class="wz-foot">' +
      '<button type="button" class="btn btn-ghost wz-antes">← ' + txt('previous') + '</button>' +
      '<button type="button" class="btn btn-primary wz-next">' + txt('next') + ' →</button>' +
    '</footer>';

  const stage = el.querySelector('.wz-stage');
  const dots = el.querySelector('.wz-dots');

  function paintHeader() {
    el.querySelector('.wz-count').textContent =
      txt('question') + ' ' + (current + 1) + ' ' + txt('of') + ' ' + exercises.length;
    dots.innerHTML = states.map((s, i) => {
      const cls = ['wz-dot'];
      if (i === current) cls.push('on');
      /* In an exam that is still open the marker says WHETHER it was answered,
         not whether it was right: the colour of a correct answer would be the
         verdict the exam is holding back. */
      if (s.answered) {
        cls.push(exam && !submitted
          ? 'done'
          : (s.correct === true ? 'right' : (s.correct === null ? 'pending' : 'wrong')));
      }
      return '<button type="button" class="' + cls.join(' ') + '" data-ir="' + i + '" ' +
        'aria-label="' + txt('question') + ' ' + (i + 1) + '">' + (i + 1) + '</button>';
    }).join('');
    el.querySelector('.wz-antes').disabled = current === 0;
    const last = current === exercises.length - 1;
    const blank = states.filter((s) => !s.answered).length;
    const next = el.querySelector('.wz-next');
    if (submitted) next.textContent = txt('exam submitted');
    else if (!last) next.textContent = txt('next') + ' →';
    else if (!exam) next.textContent = txt('see the result');
    else if (confirming) next.textContent = txt('Submit with') + ' ' + blank + ' ' + txt('blank');
    else next.textContent = txt('Submit the exam');
    next.classList.toggle('wz-warn', confirming && !submitted);
  }

  /* The elements are KEPT, not recreated. Going to question 3 and back to 1 has
     to give 1 back as it was — with the answer ticked and the verdict in sight.
     Rebuilding would erase that, and the student would think they lost work. */
  const screens = exercises.map(() => null);

  /* WHICH ONES ARE BEING ASKED AGAIN. A card whose answer was thrown away has
     to be BUILT as if it had never been answered — otherwise the rebuild puts
     the wrong answer straight back on it, which is what `fresh` means and why
     it travels per card here rather than per wizard. */
  const asking = new Set();
  const missed = () => states
    .map((s, i) => (s.answered && s.correct === false ? i : -1))
    .filter((i) => i >= 0);

  /* `ctx` can be a single context (one lesson's assessment) or one per exercise
     (the redo screen, which gathers exercises from different lessons and has to
     store each answer against the lesson it came from). */
  const contextFor = (i) => (Array.isArray(ctx) ? ctx[i] : ctx);

  function show(i) {
    current = i;
    /* `lesson` GOES DOWN WITH THE OTHER TWO, and it did not. The wizard took
       the option at the top and built each question without it, so the marking
       fell through to `api.grade` with no attempt — which is `gradeLocally`,
       comparing an answer against a question the browser holds no key for. An
       option accepted at one end and dropped at the other is the same shape as
       the count that never reached `lessonSections`: nothing is missing, it
       just never arrives. */
    if (!screens[i]) {
      /* AND `fresh` GOES DOWN WITH THE OTHER THREE, which is this same comment
         happening a second time: the options are named one by one, so an
         option nobody added here is accepted at the top and dropped on the way
         down. `redo` asked for fresh cards and got answered ones. */
      screens[i] = buildExercise(exercises[i], contextFor(i), i,
        { exam, attempt: options.attempt, lesson: options.lesson,
          fresh: options.fresh || asking.has(i) });
    }
    stage.textContent = '';
    stage.appendChild(screens[i]);
    paintHeader();
  }

  async function finish() {
    const count = () => ({
      right: states.filter((s) => s.correct === true).length,
      unchecked: states.filter((s) => s.answered && s.correct === null).length,
      unanswered: states.filter((s) => !s.answered).length,
    });
    const { right, unchecked, unanswered } = count();

    /* The exam OPENS here: every answered question reveals the verdict that was
       held back, and answering stops being possible. It is the line between
       measuring and teaching — before it the exam measures, after it it
       teaches. */
    /* AWAITED, and that is why this function is async: in a server-drawn exam
       the result is a request, and revealing before it comes back would reveal
       nothing — the browser has no key to reveal against. */
    const grade = options.onSubmit
      ? await options.onSubmit({ right, unchecked, unanswered, states })
      : null;

    /* The verdicts the server sent, by exercise id. They replace what grading
       produced, because in a server-drawn exam grading produced `null` for
       everything — the dots would stay grey and the score would be a lie. */
    if (grade && grade.verdicts) {
      exercises.forEach((ex, i) => {
        const v = grade.verdicts[ex.id];
        if (v) states[i] = { answered: states[i].answered, correct: v.correct, server: v };
      });
    }
    /* Recounted AFTER, or the notes below describe the exam as it was a moment
       before the result arrived: in a server-drawn exam every answer was
       `correct: null` until this point, and the screen would say all ten are
       waiting to be checked underneath a score of 20%. */
    const final = count();

    if (exam) {
      submitted = true;
      screens.forEach((t, i) => {
        if (!t) return;
        if (t.revealExam) t.revealExam(states[i] && states[i].server);
        t.querySelectorAll('.ex-answer, input, textarea, select, button').forEach((b) => { b.disabled = true; });
      });
    }

    stage.textContent = '';
    const r = document.createElement('div');
    r.className = 'wz-result';
    r.innerHTML =
      (grade ? grade.html : '') +
      (grade ? '' : '<span class="wz-res-label">' + txt('result') + '</span>' +
        '<p class="wz-res-score"><strong>' + final.right + '</strong>/' + exercises.length + ' ' + txt('correct') + '</p>') +
      (final.unchecked ? '<p class="wz-res-note">' + final.unchecked + ' ' + txt('are waiting to be checked on the server.') + '</p>' : '') +
      (final.unanswered ? '<p class="wz-res-note">' + final.unanswered + ' ' + txt('unanswered.') + '</p>' : '') +
      /* ---------- and the second go, from the one screen that knows the score

         THE RESULT PANEL IS WHERE SOMEBODY DECIDES WHAT TO DO NEXT, and until
         now it offered one thing: read them all again from the first. The
         ones worth going back to are the ones that were wrong, and every card
         already carries "try again" — but reaching them meant remembering
         which numbers were red and pressing each in turn.

         NOT IN AN EXAM, where the paper is closed and a second answer is not
         a thing that exists; not in a drill, where the schedule already moved
         (see `check`); and not in `redo`, which IS the second go and would be
         offering itself. */
      '<div class="wz-res-actions">' +
        (!exam && !options.drill && !options.fresh && missed().length
          ? '<button type="button" class="btn btn-primary wz-redo">' +
              txt('redo what you got wrong') + ' (' + missed().length + ')</button>'
          : '') +
        '<button type="button" class="btn btn-ghost wz-back">' +
          txt(exam ? 'Review the exam question by question' : 'Review the questions') + '</button>' +
      '</div>';
    stage.appendChild(r);
    r.querySelector('.wz-back').addEventListener('click', () => show(0));

    /* THE ANSWERS GO, THE ATTEMPTS STAY. The cards are rebuilt with nothing on
       them and the dots go back to grey for those questions only — what the
       store keeps is untouched, so `attempts` still counts every try and
       `correct` stays true for anything already got right (A-10: there is no
       score to repair). Answering them again lands on the result again, this
       time with the new verdicts in it. */
    const secondGo = r.querySelector('.wz-redo');
    if (secondGo) {
      secondGo.addEventListener('click', () => {
        const again = missed();
        again.forEach((i) => {
          asking.add(i);
          screens[i] = null;
          states[i] = { answered: false, correct: null };
        });
        el.querySelector('.wz-next').disabled = false;
        show(again[0]);
      });
    }
    el.querySelector('.wz-next').disabled = true;
    paintHeader();
    el.dispatchEvent(new CustomEvent('assessment:concluida', {
      bubbles: true,
      detail: { lastCorrect: final.right, total: exercises.length },
    }));
  }

  el.addEventListener('exercise:answered', (e) => {
    states[current] = { answered: true, correct: e.detail.v.correct };
    paintHeader();
  });
  el.addEventListener('exercise:redone', () => {
    states[current] = { answered: false, correct: null };
    screens[current] = stage.firstElementChild;   // "try again" swaps the element
    paintHeader();
  });

  dots.addEventListener('click', (e) => {
    const b = e.target.closest('.wz-dot');
    if (b) show(Number(b.dataset.ir));
  });
  el.querySelector('.wz-antes').addEventListener('click', () => show(Math.max(0, current - 1)));
  el.querySelector('.wz-next').addEventListener('click', () => {
    if (current !== exercises.length - 1) { confirming = false; show(current + 1); return; }
    /* Submitting with blank questions asks for a second click. It is not a
       modal: the button itself says how many are left and what will happen.
       Submitting without noticing that three were missed is the expensive
       mistake on this screen — after submitting there is no way back. */
    const blank = states.filter((s) => !s.answered).length;
    if (exam && blank && !confirming) { confirming = true; paintHeader(); return; }
    el.querySelector('.wz-next').disabled = true;
    finish().catch((e) => {
      /* The submit failed. The exam is NOT closed — nothing was revealed and
         nothing was disabled — so the button comes back and the paper is still
         open, which is the only recovery that does not cost the attempt. */
      el.querySelector('.wz-next').disabled = false;
      const note = document.createElement('p');
      note.className = 'wz-res-note wz-error';
      note.textContent = txt('The exam could not be submitted.') + ' ' + (e.message || '');
      stage.appendChild(note);
    });
  });

  show(0);
  return el;
}
