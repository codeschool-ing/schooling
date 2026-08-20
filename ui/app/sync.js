/* ==========================================================================
   Sending a write to the school — schooling's copy.

   THE THIRD AND LAST FILE THAT IS NOT A COPY, and the smallest by a long way.

   The portal's `sync.js` is a queue with retries, because over there the browser
   is the authority and the server is a second copy that has to catch up: a write
   that fails must be kept and sent again, or it is lost with the tab.

   HERE THE SERVER IS THE AUTHORITY, so there is nothing to queue. A write goes
   straight to it; if it fails the in-memory copy is now ahead of the school, and
   that is reported rather than retried in the dark — a tick that appears, stays,
   and turns out never to have been recorded is worse than one that visibly did
   not take.
   ========================================================================== */

import { onEveryWrite } from './state.js';
import * as api from './api.js';

/* Whether there is a school at the other end. The offline copy is one file on a
   disk and has none, which is what every screen branches on before it offers
   something that would need one. */
export const configured = () => api.configured();

/* What a failed write does. `app/main.js` sets it; until it does, a failure is
   still not silent — it reaches the console with the write that was lost. */
let onTrouble = null;
export const whenWriteFails = (fn) => { onTrouble = fn; };

function failed(write, error) {
  if (onTrouble) onTrouble(write, error);
  else console.error('schooling: a write did not reach the school', write, error);
}

/* THE WRITES THE COPIED SCREENS MAKE, each named by the kind `state.js` emits.
   A kind nothing here knows is reported rather than dropped: it means a screen
   started writing something new and nobody wired it up, which is exactly the
   silent failure this project forbids (X-03). */
const send = {
  section: (w) => api.completeSection(w.courseId, w.ix, w.sectionId, w.done),
  visit: (w) => api.visitSection(w.courseId, w.ix, w.sectionId),
  note: (w) => api.saveNote(w.courseId, w.ix, w.sectionId, w.body),
};

export function start() {
  onEveryWrite((write) => {
    if (!configured()) return;      // the offline copy: reading only, and it says so

    const handler = send[write.kind];
    if (!handler) {
      failed(write, new Error(`no handler for a write of kind "${write.kind}"`));
      return;
    }

    Promise.resolve()
      .then(() => handler(write))
      .catch((error) => failed(write, error));
  });
}
