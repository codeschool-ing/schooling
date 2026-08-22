/* ==========================================================================
   Who is holding the door open.

   ONE READ, AT BOOT, AND EVERY SCREEN ASKS THIS RATHER THAN THE API. The role
   decides what a screen offers, and a screen that fetched it for itself would
   be one more request per navigation and one more place for the answer to
   differ from the bar.

   IT IS NOT WHAT PROTECTS ANYTHING. `identity.RequireStaff` is, on the API, and
   every route behind it checks its own rank besides. What this decides is what
   is worth drawing: a control that always fails is a bad screen, not a hole.
   ========================================================================== */

import { get, RequestError } from './request.js';

export const state = { account: null, refused: null };

export async function load() {
  try {
    state.account = await get('/console/api/v1/me');
    state.refused = null;
  } catch (e) {
    state.account = null;
    state.refused = e instanceof RequestError ? e : new RequestError(0, 'offline', e.message);
  }
  return state.account;
}

export const role = () => (state.account ? state.account.role : '');

/* Read-only is the floor the door asks for; anything above it may act. The
   comparison is by name rather than by rank because the console does not need
   the order, only the one distinction it draws. */
export const mayAct = () => Boolean(state.account) && state.account.role !== 'read-only';

export const displayName = () =>
  (state.account && (state.account.name || state.account.email)) || '';
