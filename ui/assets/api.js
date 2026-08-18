/* ==========================================================================
   Schooling — the API, from the browser

   ONE ORIGIN, SO NO TOKEN LIVES HERE. The session is an HttpOnly cookie set by
   the server on the same host that serves this file (P-03), which means this
   script cannot read it and neither can anything injected beside it. There is
   no Authorization header in this file and there is not meant to be one: the
   day a token has to be put in a header is the day it has to be stored
   somewhere JavaScript can reach, and that is the whole class of problem this
   arrangement avoids.

   `credentials: 'same-origin'` is the default for same-origin requests, and it
   is written out anyway — it is the line somebody would otherwise have to
   deduce is missing.

   EVERY FAILURE ARRIVES AS AN ApiError WITH ITS CODE. The server answers a
   closed set of codes and the screens branch on them: `locked` is a paywall and
   not a mistake, `no-name` is a certificate waiting for a name, `handed-in` is
   an exam that is over. A client that only knew the status would have to guess
   which of those a 409 was.
   ========================================================================== */

export class ApiError extends Error {
  constructor(status, code, message) {
    super(message || 'that did not work');
    this.name = 'ApiError';
    this.status = status;
    this.code = code || '';
  }
}

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
    /* The network, not the server. It is its own code because it is the one
       failure where "try again" is honest advice. */
    throw new ApiError(0, 'offline', 'the server could not be reached');
  }

  if (response.status === 204) return null;

  let payload = null;
  try { payload = await response.json(); } catch (e) { /* an empty or non-JSON body */ }

  if (!response.ok) {
    const error = (payload && payload.error) || {};
    throw new ApiError(response.status, error.code, error.message);
  }
  return payload;
}

export const api = {
  get: (path) => request('GET', path),
  post: (path, body) => request('POST', path, body === undefined ? {} : body),
  put: (path, body) => request('PUT', path, body),

  /* ---------- who ---------- */
  me: () => api.get('/api/v1/me'),
  signIn: (email, password) => api.post('/api/v1/sign-in', { email, password }),
  signUp: (email, password, name) => api.post('/api/v1/sign-up', { email, password, name }),
  signOut: () => api.post('/api/v1/sign-out'),

  /* ---------- what there is to study ---------- */
  school: () => api.get('/api/v1/school'),
  courses: () => api.get('/api/v1/courses'),
  course: (id) => api.get(`/api/v1/courses/${encodeURIComponent(id)}`),
  tracks: () => api.get('/api/v1/tracks'),
  track: (id) => api.get(`/api/v1/tracks/${encodeURIComponent(id)}`),
  /* `lang` is the content locale, which is the language code the Markdown
     files are named with — `roles.pt.md` is locale `pt`. Not the BCP 47 tag:
     the file names are the contract. */
  lesson: (course, lesson, lang) =>
    api.get(`/api/v1/courses/${encodeURIComponent(course)}/lessons/${encodeURIComponent(lesson)}`
      + `?lang=${encodeURIComponent(lang || 'en')}`),

  /* ---------- what a student has done ---------- */
  progress: (course) => api.get(`/api/v1/progress/${encodeURIComponent(course)}`),
  complete: (course, lesson, section) =>
    api.post(`/api/v1/progress/${encodeURIComponent(course)}/${encodeURIComponent(lesson)}`
      + `/${encodeURIComponent(section)}/complete`),
  visit: (course, lesson, section) =>
    api.post(`/api/v1/progress/${encodeURIComponent(course)}/${encodeURIComponent(lesson)}`
      + `/${encodeURIComponent(section)}/visit`),
  resume: () => api.get('/api/v1/resume'),

  /* ---------- exams ---------- */
  startExam: (scope, id) =>
    api.post(`/api/v1/exams/${encodeURIComponent(scope)}/${encodeURIComponent(id)}/start`),
  attempt: (id) => api.get(`/api/v1/exams/attempts/${encodeURIComponent(id)}`),
  answer: (attempt, position, answer) =>
    api.put(`/api/v1/exams/attempts/${encodeURIComponent(attempt)}/answers/${position}`, { answer }),
  handIn: (attempt) =>
    api.post(`/api/v1/exams/attempts/${encodeURIComponent(attempt)}/hand-in`),
  attempts: () => api.get('/api/v1/exams/attempts'),

  /* ---------- certificates ---------- */
  certificates: () => api.get('/api/v1/certificates'),
  verify: (code) => api.get(`/api/v1/verify/${encodeURIComponent(code)}`),
};
