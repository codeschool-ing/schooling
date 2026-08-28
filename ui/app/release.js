/* ==========================================================================
   Whether the tab is still running the build the server is serving.

   # THE CACHING IS CORRECT AND THAT IS EXACTLY THE PROBLEM

   `ui.Handler` serves every file with `Cache-Control: no-cache` and an ETag
   that is the build, which means the browser revalidates on every request and a
   deploy invalidates all of them at once. There is no arrangement of caches
   that can serve one file from before a release and another from after it — the
   handler's own comment says so, and it is true.

   It is true of a PAGE LOAD. A tab that was opened before the deploy and never
   reloaded is running the modules it already has, in memory, and nothing will
   ever ask the server about them again. Somebody who leaves this open on a
   second monitor for three days is three days behind, and the way they find out
   is a screen that does something odd against an API that has moved on.

   Nothing here can fix that tab. What it can do is notice, and say so.

   # WHAT IT COMPARES

   The whole of `/version` — the tag, the commit and the build time — rather
   than the tag alone. An unstamped build calls itself `dev` and every one of
   them shares that string, which is the same reason `ui.Handler` refuses to
   offer `dev` as an ETag; the commit is what tells two of them apart, and on a
   laptop it is the only thing that does.

   # WHEN IT ASKS

   WHEN THE TAB COMES BACK, which is the moment that matters. The case this
   exists for is a tab nobody has looked at since Tuesday, and the request that
   answers it is the one made when somebody looks at it again. A timer would ask
   all night on behalf of a person who is asleep.

   There is a floor between checks so that flicking between two tabs is not a
   request per flick, and the first check is not made at boot: the page has just
   been served, so it is by definition current.

   # AND IT NEVER RELOADS BY ITSELF

   This platform has TIMED EXAMS. A reload nobody asked for, at a moment nobody
   chose, is the worst thing an update mechanism can do here — and it would do
   it to the one person who cannot afford it. The banner is a sentence and a
   button; the button belongs to the reader.

   For the same reason it stays quiet while an exam paper is open. The answer to
   "you are running an old build" is not one anybody can act on with a clock
   running, and a nudge that cannot be acted on is a distraction.
   ========================================================================== */

import * as api from './api.js';

/* How long two checks must be apart. Fifteen minutes is chosen against the
   behaviour rather than against the server: somebody moving between a tab of
   this and a tab of something else does it many times an hour, and the answer
   cannot have changed in between unless a deploy landed in that minute. */
const MIN_APART = 15 * 60 * 1000;

/* WHAT WAS SERVED TO THIS TAB, recorded at boot and never again.

   IT COSTS ONE REQUEST PER PAGE LOAD and it is worth it. The alternative is to
   record on the first check instead, which is free — and wrong in a way that is
   hard to see later: a tab opened into the background and looked at on Thursday
   would record Thursday's build as its own and report itself current forever.

   The request has no database behind it and answers about a hundred bytes. This
   page already asks for a session, a catalogue and the lesson structure before
   it draws. */
let running = '';
let lastChecked = 0;

// Once true it stays true. A build does not become current again, and a tab
// that has been told twice has been told twice for no reason.
let behind = false;

const identity = (info) => [info?.version, info?.commit, info?.built]
  .map((s) => String(s || '')).join(' ');

/* Whether an exam paper is on screen, by the same test `main.js` already uses
   to decide which routes need a school: an exam address ends in `/exam`. The
   route the router matched is on the content region, so this reads what was
   DRAWN rather than what the address bar says — a hash that has changed while
   the screen behind it has not is exactly the state to be careful about. */
function sittingAnExam() {
  const drew = document.querySelector('#content')?.getAttribute('data-screen') || '';
  return drew.endsWith('/exam');
}

/*
Ask the server what it is, and answer whether this tab is behind it.

	EVERY FAILURE IS A NO. There is no server in the offline copy, a request can
	fail because the network went away, and neither of those is news about a
	release. The one thing this must never do is tell somebody their tab is old
	because their train went into a tunnel.
*/
async function ask() {
  if (api.offline) return false;

  /* THE FLOOR IS MEASURED FROM THE LAST COMPARISON AND NOT FROM THE LAST
     REQUEST, which is a distinction with two consequences and both are wanted.

     The ask at boot compares nothing — it records what this tab was served, and
     there is nothing yet to compare against. Starting the clock there would
     mean somebody who loads a page, looks away and looks back a minute later
     hears nothing for the next quarter of an hour, and the first return to a
     tab is a perfectly ordinary moment for a deploy to have landed in.

     It also makes the state REACHABLE. A check that cannot run twice in a row
     could only be exercised by a suite willing to wait fifteen minutes, and a
     state nothing exercises is a state nobody has ever seen drawn. */
  const now = Date.now();
  if (running && now - lastChecked < MIN_APART) return behind;
  if (running) lastChecked = now;

  let info;
  try {
    info = await api.get('/version');
  } catch (e) {
    return behind;
  }

  const said = identity(info);
  if (!said.trim()) return behind;

  if (!running) {
    running = said;
    return false;
  }
  if (said !== running) behind = true;
  return behind;
}

/*
watch calls back the first time this tab is found to be behind, and never again.

	THE CALLER PAINTS. This module knows about builds and nothing about banners,
	which is what lets the whole of it be read without opening a stylesheet — and
	what would let a second surface (the console, one day) use the same check
	without inheriting a student's markup.
*/
export function watch(whenBehind) {
  let told = false;

  const look = async () => {
    if (told || document.visibilityState !== 'visible') return;
    if (!(await ask())) return;
    if (sittingAnExam()) return;   // asked again on the next return to the tab
    told = true;
    whenBehind();
  };

  document.addEventListener('visibilitychange', look);

  /* AND THE ONE AT BOOT, WHICH IS NOT A CHECK. It cannot find anything — there
     is nothing to compare against yet — and it is not gated on visibility for
     that exact reason: a tab opened in the background has still been SERVED,
     and what this records is what it was served. */
  ask();
}
