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
   ========================================================================== */

import { esc } from '../dom.js';
import { get } from '../request.js';

/* The three words the store uses, and what each is drawn as. A word this file
   does not know is shown as itself: a fourth outcome should appear on the
   screen as a thing nobody has styled yet, rather than be folded into one of
   the three and read as something it is not. */
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
      '<span class="eyebrow mono">Watch</span>' +
      '<h1>Jobs</h1>' +
      '<p>What runs on a schedule, and how it went. This is the console ' +
      'reporting on itself: the question is not what students did, it is ' +
      'whether the work behind another screen actually happened last night.</p>' +
    '</header>' +
    '<div id="body" aria-live="polite"><p class="checking">Reading…</p></div>';

  const body = el.querySelector('#body');

  let answer;
  try {
    answer = await get('/console/api/v1/jobs');
  } catch (e) {
    body.innerHTML = '<section class="block"><p class="none">' + esc(e.message) + '</p></section>';
    return { title: section.name, el };
  }

  const all = answer.jobs || [];
  const adrift = Math.round((answer.adrift_after_seconds || 0) / 60);

  body.innerHTML =
    (all.length === 0
      ? '<section class="block"><p class="none">' + esc(answer.nothing_yet || '') + '</p></section>'
      : all.map((one) => block(one, adrift)).join('')) +

    '<section class="block">' +
      '<div class="block-top"><h2>Why there is no button</h2></div>' +
      '<p class="aside">' + esc(answer.no_retry || '') + '</p>' +
    '</section>';

  return { title: section.name, el };
}

function block(one, adrift) {
  const runs = one.runs || [];
  const last = runs[0];

  return '<section class="block">' +
    '<div class="block-top">' +
      '<h2 class="mono">' + esc(one.name) + '</h2>' +
      '<span class="block-score mono">' + esc(headline(last)) + '</span>' +
    '</div>' +

    (runs.length === 0
      ? '<p class="none">This job has recorded no runs.</p>'
      : '<ol class="run-list">' + runs.map((r) => row(r, adrift)).join('') + '</ol>') +

    /* THE THRESHOLD BESIDE THE THING IT JUDGED (K-16). It is only worth saying
       where a row was actually judged by it. */
    (runs.some((r) => r.adrift)
      ? '<p class="aside">A run still saying <b>running</b> after ' + adrift +
        ' minutes is drawn as adrift. Nothing rewrites it: the row is what the ' +
        'job itself last said, and a job that was killed says nothing on the way out.</p>'
      : '') +
  '</section>';
}

/* What the block's corner says, which is the one thing somebody scanning this
   screen reads. The failure states are named; a healthy job gets the quietest
   possible sentence, because the point of this screen is the day it is not
   quiet. */
function headline(last) {
  if (!last) return 'never run';
  if (last.adrift) return 'started and never finished';
  if (last.outcome === 'failed') return 'last run failed';
  if (last.outcome === 'running') return 'running now';
  return 'last run ' + ago(last.started_at);
}

function row(r, adrift) {
  const state = r.adrift ? 'adrift' : r.outcome;
  return '<li class="run run-' + esc(state) + '">' +
    '<span class="run-state mono">' +
      esc(r.adrift ? 'Adrift' : (SAID[r.outcome] || r.outcome)) +
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
  const said = seconds < 60
    ? seconds + 's'
    : Math.round(seconds / 60) + 'm';
  return r.finished_at ? said : said + ' and counting';
}

/* When it started, in words. A job runs at the same time every night, so the
   useful reading is "last night" or "three nights ago" rather than a clock. */
function ago(when) {
  const at = new Date(when);
  if (Number.isNaN(at.getTime())) return 'at an unknown time';

  const hours = Math.floor((Date.now() - at.getTime()) / 3600000);
  if (hours < 1) return 'within the hour';
  if (hours < 24) return hours + (hours === 1 ? ' hour ago' : ' hours ago');
  const days = Math.floor(hours / 24);
  return days === 1 ? 'yesterday' : days + ' days ago';
}
