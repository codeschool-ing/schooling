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

   For the same reason it stays quiet while an exam paper is open — see `hold`.

   # WHY IT IS IN `assets/` AND NOT IN `app/`

   The console needs this more than the study interface does, and it was written
   in the student's tree where the console cannot reach it: `interface.go` serves
   `assets/` from the console's own files and falls back to the study
   interface's, and refuses to serve `app/` at all, because those are a
   student's screens. `accent.js` lives here for exactly this reason and says so.

   That move is what took the imports out. This file used to call the student's
   `api.get`, which does not exist over there; it asks `fetch` itself now, and
   the two things it cannot know about the surface it is on arrive as
   predicates:

       skip()   do not ask at all — the offline bundle has no server, and
                telling somebody their tab is old because a file:// page has
                nowhere to ask would be the worst possible answer
       hold()   behind, but this is not the moment to say so — a student with
                an exam paper open

   Both default to false, which is the console's answer to both: it has no
   offline copy and nothing on it is timed.

   IT COST A DAY BEFORE IT EXISTED. A console tab left open across a deploy runs
   every screen's module from before it — the screens are imported statically,
   so one page load fixes the whole interface in memory — and the release that
   added the books to the record was read as not having shipped, from a tab that
   could not see it. The student's version of this shipped in the same release
   and the console had none.
   ========================================================================== */

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

/*
Ask the server what it is, and answer whether this tab is behind it.

	EVERY FAILURE IS A NO. There is no server in the offline copy, a request can
	fail because the network went away, and neither of those is news about a
	release. The one thing this must never do is tell somebody their tab is old
	because their train went into a tunnel.
*/
async function ask(skip) {
  if (skip()) return false;

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

  /* ITS OWN `fetch` AND NOT THE CALLER'S REQUEST HELPER, which is the price of
     living in `assets/` — see the header. It is also the honest shape: this
     asks one unauthenticated route for a hundred bytes and wants none of what
     a request helper adds. A non-200 is read as no news rather than as a
     failure, for the same reason every other failure here is. */
  let info;
  try {
    const answer = await fetch('/version', { credentials: 'same-origin' });
    if (!answer.ok) return behind;
    info = await answer.json();
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
export function watch(whenBehind, { skip = () => false, hold = () => false } = {}) {
  let told = false;

  const look = async () => {
    if (told || document.visibilityState !== 'visible') return;
    if (!(await ask(skip))) return;
    if (hold()) return;   // asked again on the next return to the tab
    told = true;
    whenBehind();
  };

  document.addEventListener('visibilitychange', look);

  /* AND THE ONE AT BOOT, WHICH IS NOT A CHECK. It cannot find anything — there
     is nothing to compare against yet — and it is not gated on visibility for
     that exact reason: a tab opened in the background has still been SERVED,
     and what this records is what it was served. */
  ask(skip);
}
