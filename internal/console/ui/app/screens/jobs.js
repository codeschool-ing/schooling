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
      '<span class="eyebrow mono">' + esc(txt('Watch')) + '</span>' +
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
      : '<ol class="run-list">' + runs.map((r) => row(r, adrift)).join('') + '</ol>') +

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

function row(r, adrift) {
  const state = r.adrift ? 'adrift' : r.outcome;
  return '<li class="run run-' + esc(state) + '">' +
    '<span class="run-state mono">' +
      esc(r.adrift ? txt('Adrift') : txt(SAID[r.outcome] || r.outcome)) +
    '</span>' +
    '<span class="run-when">' + esc(ago(r.started_at)) + '</span>' +
    '<span class="run-took mono">' + esc(took(r, adrift)) + '</span>' +
    (r.version ? '<span class="run-version mono">' + esc(r.version) + '</span>' : '') +
    (r.detail ? '<p class="run-detail">' + esc(r.detail) + '</p>' : '') +
  '</li>';
}

/* How long it took, or how long it has been open. An unfinished run shows the
   time SINCE it started, which is the number that makes "adrift" obvious
   without needing the word. */
function took(r, adrift) {
  const from = new Date(r.started_at).getTime();
  const to = r.finished_at ? new Date(r.finished_at).getTime() : Date.now();
  if (Number.isNaN(from) || Number.isNaN(to)) return '';

  const seconds = Math.max(0, Math.round((to - from) / 1000));
  /* `s` AND `m` ARE UNITS AND NOT WORDS, so they are not translated — but "and
     counting" is a sentence, and it goes after the number in English and
     before it in some languages, so the whole thing is one key with a hole. */
  const said = seconds < 60
    ? seconds + 's'
    : Math.round(seconds / 60) + 'm';
  return r.finished_at ? said : txt('%s and counting').replace('%s', said);
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
