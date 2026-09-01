/* ==========================================================================
   Jobs — the console reporting on the console.

   EVERY OTHER SCREEN HERE IS ABOUT STUDENTS. This one is about whether the
   machinery behind one of them did its work last night, and it exists because
   the console already had a signal and it was the wrong one: the item analysis
   shows when its rollup was last WRITTEN. A job that failed at 03:10, a job
   nobody scheduled, and a job that ran perfectly and found nothing to change
   all look identical through that number — the last case is what makes it
   useless as an alarm, because a healthy night can leave it untouched.

   # THE MOST IMPORTANT ROW IS THE ONE THAT NEVER FINISHED

   A run is recorded before the work and closed after it. A job that was killed,
   ran out of memory, or had its instance withdrawn writes nothing on the way
   out — so it leaves a row that still says `running`, and that row is the only
   trace of it there will ever be. After an hour it is drawn as ADRIFT rather
   than as busy, and the hour comes from the server beside the runs.

   # AND AN EMPTY SCREEN IS A REAL ANSWER

   No job has ever recorded a run is exactly the state this platform was in for
   as long as nothing scheduled anything, and it must not look like a screen
   that failed to load. The sentence for it comes from the server, because it is
   a statement about the system rather than about this page.

   # A JOB THAT HAS NEVER RUN STILL GETS ITS BUTTON

   The list of jobs comes from what has RECORDED a run, which is the right list
   for a history and the wrong one for a control: a job that has never run is
   exactly the one somebody wants to start, and drawing only jobs with rows
   would put the button everywhere except the state it is for — which is the
   state this platform was actually in. So the blocks are the union of what has
   run and what may be started.

   # AND WHERE THERE IS NOTHING TO PRESS THERE IS NO BUTTON

   `startable` is empty on any deployment that cannot start a job — every
   laptop, the local stack, CI — and the screen then draws none. A control that
   always fails is a worse screen than a missing one, which is the argument the
   schools screen makes about a read-only role and the same argument here about
   a process with no metadata server behind it.

   # AND THE HISTORY ONCE AS A STRIP, WHICH ANSWERS TWO THINGS THE LIST CANNOT

   Three failures scattered through a fortnight and three failures in a row are
   the same three rows in a list and completely different diagnoses — the first
   is a flaky job and the second is a job that broke on Tuesday and has been
   broken since. And a job that used to take forty seconds and now takes six
   minutes is a column of durations nobody compares pairwise.

   Both are one glance in a strip and neither is in a list, which is the whole
   of why it is here. It is HTML bars and not an SVG, because a bar per row is
   what `funnel.js` and the country list already draw and this is that idiom
   turned on its side.
   ========================================================================== */

import { esc } from '../dom.js';
import { get, post, RequestError } from '../request.js';
import { mayAct } from '../session.js';
import { txt } from '../../assets/language.js';

/* The three words the store uses, and what each is drawn as. A word this file
   does not know is shown as itself: a fourth outcome should appear on the
   screen as a thing nobody has styled yet, rather than be folded into one of
   the three and read as something it is not. */
/* THE THREE OUTCOMES ARE THE STORE'S OWN WORDS, English here and looked up
   where they are drawn — like every closed list in this console. A fourth would
   appear on the screen as itself rather than folded into one of the three. */
const SAID = {
  ok: 'Finished',
  failed: 'Failed',
  running: 'Running',
};

export default async function jobs(section) {
  const el = document.createElement('div');
  el.className = 'view';

  el.innerHTML =
    '<header class="view-head">' +
      '<span class="eyebrow mono">' + esc(txt('Measure')) + '</span>' +
      '<h1>' + esc(txt('Jobs')) + '</h1>' +
      '<p>' + esc(txt('What runs on a schedule, and how it went. This is the console reporting on itself: the question is not what students did, it is whether the work behind another screen actually happened last night.')) + '</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">' + esc(txt('Reading…')) + '</p></div>';

  const body = el.querySelector('#body');

  let answer;
  try {
    answer = await get('/console/api/v1/jobs');
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  const adrift = Math.round((answer.adrift_after_seconds || 0) / 60);

  /* TWO REASONS THERE MAY BE NOTHING TO PRESS, and they are not the same
     reason. The server sends an empty `startable` where the deployment cannot
     start a job at all, and then the job does not exist as a thing that could
     be started. `mayAct` is the other half — the schools screen's rule applied
     here, because the API refuses a read-only role and there is a test for
     that, so a control that always fails would be a bad screen rather than a
     safe one.

     The distinction is drawn rather than collapsed: a read-only operator still
     sees the BLOCK for a job that has never run, because that is a fact about
     the platform they are here to read. What they do not get is the button. */
  const known = answer.startable || [];
  const startable = mayAct() ? known : [];

  /* WHAT HAS RUN, AND THEN WHAT MAY BE STARTED AND HAS NOT. The order is that
     way round because the history is what somebody came for; a job with no rows
     is appended rather than promoted, so a platform where everything is fine
     does not open with the one thing that has never happened. */
  const ran = answer.jobs || [];
  const never = known
    .filter((name) => !ran.some((one) => one.name === name))
    .map((name) => ({ name, runs: [] }));
  const all = ran.concat(never);

  body.innerHTML =
    (all.length === 0
      ? '<section class="block"><p class="none">' + esc(txt(answer.nothing_yet || '')) + '</p></section>'
      : all.map((one) => block(one, adrift, startable.includes(one.name))).join('')) +

    /* THERE IS ALWAYS A SENTENCE HERE, and which one depends on why. Somebody
       looking for a control has to find the reason rather than conclude it was
       forgotten — that is what this screen carried for as long as nothing could
       be started at all, and it is still true in two of the three states. */
    '<section class="block">' +
      '<div class="block-top"><h2>' +
        esc(startable.length ? txt('What starting one does') : txt('Why there is no button')) +
      '</h2></div>' +
      '<p class="aside">' + esc(why(answer, known, startable)) + '</p>' +
    '</section>';

  all.forEach((one) => {
    if (startable.includes(one.name)) wireStart(body, one.name);
  });

  return { title: section.name, el };
}

/* The sentence under the jobs, and there are three states rather than two.

   THE TWO ABOUT THE SYSTEM COME FROM THE SERVER, because they are statements
   about the platform rather than about this page — the rule the empty-screen
   sentence has followed since this screen existed. The third is about the
   PERSON READING, which the server did not put on this answer and the session
   already knows; the schools screen owns its read-only sentence for the same
   reason, in the same words. */
function why(answer, known, startable) {
  if (startable.length) return txt(answer.about_starting || '');
  if (known.length) {
    /* ONE LITERAL, HOWEVER LONG THE LINE. `txt('a ' + 'b')` asks the dictionary
       for a key no dictionary can be written against — the concatenation is
       gone by the time `check-interface` reads the file, so it reports nothing
       and the sentence stays English in every language. It has cost this
       repository eighteen strings once already. */
    return txt('A read-only role may read this screen and not press anything. Starting a job withdraws questions from circulation when the analysis finds them broken, which is not a thing looking at a screen should do.');
  }
  return txt(answer.nothing_to_press || '');
}

/* Pressing it.

   THE BUTTON IS DISABLED WHILE THE CALL IS OUT AND STAYS DISABLED ON SUCCESS,
   because the run has been ASKED for and pressing again would ask for a second
   one — which the server refuses, but only for as long as the first is actually
   running. The window between "accepted" and "the container is up" is exactly
   where a second press gets through.

   WHAT COMES BACK IS A SENTENCE AND NOT A REDRAW. The run's row does not exist
   yet: the container has to start before it writes one, which is usually within
   a minute. Redrawing here would find nothing new and look like a button that
   did nothing — the honest thing is to say what was asked for and let somebody
   reload when they want to see it. */
function wireStart(body, name) {
  const box = body.querySelector('[data-job="' + cssEscape(name) + '"]');
  if (!box) return;

  const button = box.querySelector('.job-start');
  const said = box.querySelector('.job-said');
  if (!button) return;

  button.addEventListener('click', async () => {
    button.disabled = true;
    said.className = 'job-said';
    said.textContent = txt('Asking…');

    try {
      const answer = await post('/console/api/v1/jobs/' + encodeURIComponent(name) + '/run');
      said.className = 'job-said ok';
      said.textContent = answer.started ? txt(answer.started) : txt('Asked for.');
    } catch (e) {
      button.disabled = false;
      said.className = 'job-said bad';
      said.textContent = e instanceof RequestError && e.status === 403
        ? txt('That asks for an operator.')
        : txt(e.message);
    }
  });
}

// An id is a job name, so this is belt and braces — but a selector built from a
// value is a selector waiting for the value to change shape.
const cssEscape = (v) => (window.CSS && CSS.escape ? CSS.escape(v) : String(v));

function block(one, adrift, startable) {
  const runs = one.runs || [];
  const last = runs[0];

  return '<section class="block" data-job="' + esc(one.name) + '">' +
    '<div class="block-top">' +
      '<h2 class="mono">' + esc(one.name) + '</h2>' +
      '<span class="block-score mono">' + esc(headline(last)) + '</span>' +
    '</div>' +

    (runs.length === 0
      ? '<p class="none">' + esc(txt('This job has recorded no runs.')) + '</p>'
      : strip(runs) +
        '<ol class="run-list">' + runs.map((r) => row(r)).join('') + '</ol>') +

    /* THE CONTROL IS UNDER THE HISTORY AND NOT BESIDE THE HEADING, because the
       history is the answer to the question somebody opened this screen with
       and the button is what they might do about it. A button in the corner
       would be the first thing read on a screen whose whole point is the rows
       beneath it. */
    (startable
      ? '<div class="job-bar">' +
          '<button type="button" class="btn btn-ghost job-start">' +
            esc(txt('Run it now')) + '</button>' +
          '<span class="job-said"></span>' +
        '</div>'
      : '') +

    /* THE THRESHOLD BESIDE THE THING IT JUDGED (K-16). It is only worth saying
       where a row was actually judged by it. */
    (runs.some((r) => r.adrift)
      ? '<p class="aside">' +
        txt('A run still saying <b>running</b> after %d minutes is drawn as adrift. Nothing rewrites it: the row is what the job itself last said, and a job that was killed says nothing on the way out.')
          .replace('%d', adrift) + '</p>'
      : '') +
  '</section>';
}

/* What the block's corner says, which is the one thing somebody scanning this
   screen reads. The failure states are named; a healthy job gets the quietest
   possible sentence, because the point of this screen is the day it is not
   quiet. */
function headline(last) {
  if (!last) return txt('never run');
  if (last.adrift) return txt('started and never finished');
  if (last.outcome === 'failed') return txt('last run failed');
  if (last.outcome === 'running') return txt('running now');
  return txt('last run %s').replace('%s', ago(last.started_at));
}

/* ONE JOB'S HISTORY AS A SHAPE.

   Each run is a bar, oldest at the LEFT — which is the opposite of the list
   underneath it, and deliberately: a series of time reads left to right and a
   list of what happened reads newest first, and both are right for what they
   are. The two ends are labelled with when they were, so nobody has to work out
   which way round it goes.

   # THE SCALE IS THIS JOB'S OWN AND THE CAPTION SAYS SO

   Unlike the item-analysis chart next door, there is no natural range for a
   duration: a sweep takes seconds and an analysis takes minutes, and one scale
   across the screen would draw every fast job as a flat line. So each strip is
   scaled to its own longest run, the longest is named in words underneath, and
   the caption says outright that two strips here cannot be compared by eye.
   That is a real cost of this drawing, and a cost stated is a cost somebody can
   allow for.

   # A RUN THAT NEVER FINISHED HAS NO LENGTH TO DRAW

   Its `took` is the time SINCE it started, which is not a duration — it grows
   for as long as nobody looks. Drawn as a bar it would be the tallest thing on
   every strip that contained one and would flatten every real run into the
   floor, so it is an OUTLINE at full height instead: present, obviously not a
   measurement, and in the same colour the list gives it. The status vocabulary
   this stylesheet opens with, applied — colour AND shape, never colour alone.

   # AND UNDER THREE RUNS THERE IS NO PICTURE

   Two bars is a comparison the list makes just as well, and a chart of two bars
   reads as something that failed to load the rest. Nor is one drawn where
   nothing has finished: there would be no scale, and a strip of outlines says
   only what the list already says in words. */
function strip(runs) {
  const measured = runs.map((r) => span(r)).filter((s) => s !== null && s.done);
  if (runs.length < 3 || measured.length === 0) return '';

  const longest = measured.reduce((most, s) => Math.max(most, s.seconds), 0);
  const open = runs.some((r) => !r.finished_at);

  const label = txt('A bar for each run, oldest at the left, as tall as the run took. The list below has every run with its outcome and its length.');

  /* HOW WIDE THE BARS MAY GET, AND THE ONLY GEOMETRY THIS SCREEN WRITES.

     A strip of `flex:1 1 0` bars fills whatever it is given, so three runs
     across a console-wide block are three columns a hundred pixels each — which
     is not a series, it is three tiles. Capping the bar in the stylesheet was
     the first answer and it was wrong in the other direction: the bars stopped
     at the cap and the strip did not, so the label for the newest run sat five
     hundred pixels to the right of the newest bar. The width belongs to the
     COUNT, which only this file knows, so it is computed here and the ends ride
     on the same box. */
  const across = runs.length * 26 + (runs.length - 1) * 4;

  return '<figure class="runs">' +
    '<div class="runs-plot" style="max-width:' + across + 'px">' +
      '<div class="runs-strip" role="img" aria-label="' + esc(label) + '">' +
        /* REVERSED HERE AND NOT IN THE CALLER, so the list below keeps the
           order the server sent it in. A screen that sorted its data once for
           two readings is a screen where fixing one of them moves the other. */
        runs.slice().reverse().map((r) => bar(r, longest)).join('') +
      '</div>' +
      '<div class="runs-ends">' +
        '<span>' + esc(ago(runs[runs.length - 1].started_at)) + '</span>' +
        '<span>' + esc(ago(runs[0].started_at)) + '</span>' +
      '</div>' +
    '</div>' +

    '<figcaption>' +
      esc(txt('As tall as the run took. The longest here is %s, and the scale is this job’s own — the strips on this screen are not to be read against each other.')
        .replace('%s', clock(longest))) +
      (open
        ? ' ' + esc(txt('An outline is a run that never finished. It has no length to draw: a run still open grows for as long as nobody looks, so drawn as a bar it would be the tallest thing here and would flatten every real one.'))
        : '') +
    '</figcaption>' +
  '</figure>';
}

/* One run. The `title` is a hover tooltip and not an accessibility claim — the
   strip is one labelled image, so nothing inside it is announced — and it is
   three values with a separator rather than a sentence, so there is nothing in
   it a translator would need to reorder.

   THE FLOOR IS THERE BECAUSE A RUN THAT HAPPENED HAS TO BE VISIBLE. Beside a
   six-minute run, a one-second one rounds to nothing and the strip loses it —
   and "it ran" is most of what this picture is for. The world map's shading has
   a floor of its own for the same reason, in its own units. */
function bar(r, longest) {
  const state = r.adrift ? 'adrift' : r.outcome;
  const ran = span(r);
  const done = ran !== null && ran.done;
  const height = done && longest > 0
    ? Math.max(8, (ran.seconds / longest) * 100)
    : 100;

  return '<span class="runs-bar runs-' + esc(state) + (done ? '' : ' runs-open') +
    '" style="height:' + height.toFixed(1) + '%" title="' +
    esc([r.adrift ? txt('Adrift') : txt(SAID[r.outcome] || r.outcome),
      ago(r.started_at), took(r)].join(' · ')) + '"></span>';
}

function row(r) {
  const state = r.adrift ? 'adrift' : r.outcome;
  return '<li class="run run-' + esc(state) + '">' +
    '<span class="run-state mono">' +
      esc(r.adrift ? txt('Adrift') : txt(SAID[r.outcome] || r.outcome)) +
    '</span>' +
    '<span class="run-when">' + esc(ago(r.started_at)) + '</span>' +
    '<span class="run-took mono">' + esc(took(r)) + '</span>' +
    (r.version ? '<span class="run-version mono">' + esc(r.version) + '</span>' : '') +
    (r.detail ? '<p class="run-detail">' + esc(r.detail) + '</p>' : '') +
  '</li>';
}

/* How long a run has been going, and WHETHER THAT IS ITS LENGTH. The two are
   different facts and one number cannot carry both: a finished run's seconds
   are how long it took, and an open one's are how long it has been open, which
   is not a duration at all. The strip needs to tell them apart to know what it
   may draw, so the answer says which it is rather than leaving that to be
   inferred from a field somewhere else. */
function span(r) {
  const from = new Date(r.started_at).getTime();
  const to = r.finished_at ? new Date(r.finished_at).getTime() : Date.now();
  if (Number.isNaN(from) || Number.isNaN(to)) return null;
  return { seconds: Math.max(0, Math.round((to - from) / 1000)), done: !!r.finished_at };
}

/* `s` AND `m` ARE UNITS AND NOT WORDS, so they are not translated. */
const clock = (seconds) => (seconds < 60 ? seconds + 's' : Math.round(seconds / 60) + 'm');

/* How long it took, or how long it has been open. An unfinished run shows the
   time SINCE it started, which is the number that makes "adrift" obvious
   without needing the word — and "and counting" is a sentence, which goes after
   the number in English and before it in some languages, so the whole thing is
   one key with a hole rather than a phrase glued to a figure. */
function took(r) {
  const ran = span(r);
  if (ran === null) return '';
  return ran.done
    ? clock(ran.seconds)
    : txt('%s and counting').replace('%s', clock(ran.seconds));
}

/* When it started, in words. A job runs at the same time every night, so the
   useful reading is "last night" or "three nights ago" rather than a clock. */
function ago(when) {
  const at = new Date(when);
  if (Number.isNaN(at.getTime())) return txt('at an unknown time');

  // Five whole sentences. See `reports.js` for why a plural is never built by
  // appending a letter to a translated word.
  const hours = Math.floor((Date.now() - at.getTime()) / 3600000);
  if (hours < 1) return txt('within the hour');
  if (hours < 24) {
    return hours === 1 ? txt('an hour ago') : txt('%d hours ago').replace('%d', hours);
  }
  const days = Math.floor(hours / 24);
  return days === 1 ? txt('yesterday') : txt('%d days ago').replace('%d', days);
}
