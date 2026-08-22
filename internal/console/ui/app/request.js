/* ==========================================================================
   One request shape, and the two states the whole console cares about.

   SIMPLER THAN console-frontend's, and the reason is the deployment rather
   than taste: that console is a static site on GitHub Pages talking to an API
   on another origin, so it carries a `<meta name="backend">`, a base URL and a
   standing notice for the case where it is wired to nothing. This one is
   served BY the API, from the same origin (P-03) — there is no other origin to
   point at and no way to be wired to nothing.

   `same-origin` credentials because the session cookie is HttpOnly and set on
   the parent domain. There is no token in this file and there is not meant to
   be one.
   ========================================================================== */

export class RequestError extends Error {
  constructor(status, code, message) {
    super(message || 'that did not work');
    this.name = 'RequestError';
    this.status = status;
    this.code = code || '';
  }
}

/* Refusals are a state and not a surprise: a read-only role asking to erase
   gets one, and so does a session that has expired while somebody was reading.
   The caller decides which of those it is. */
async function request(method, path, body) {
  let response;
  try {
    response = await fetch(path, {
      method,
      credentials: 'same-origin',
      headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch (e) {
    throw new RequestError(0, 'offline', 'the server could not be reached');
  }

  if (response.status === 204) return null;

  let payload = null;
  try { payload = await response.json(); } catch (e) { /* empty or not JSON */ }

  if (!response.ok) {
    const error = (payload && payload.error) || {};
    throw new RequestError(response.status, error.code, error.message);
  }
  return payload;
}

export const get = (path) => request('GET', path);
export const post = (path, body) => request('POST', path, body === undefined ? {} : body);
