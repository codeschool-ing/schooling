/* ==========================================================================
   The console's one screen: find a person, see what is held, export, erase.

   THIS IS AN OBLIGATION AND NOT A FEATURE. Somebody writes in and asks what is
   held about them, or asks to be forgotten. Until this existed the only way to
   answer was a SQL client pointed at production — the same power with no gate
   and no record.

   # IT ASKS FOR A WHOLE ADDRESS AND SHOWS ONE PERSON

   There is no list and no partial match, and the server refuses to provide one
   either (K-22). A search is not a lookup: typing `@example.tld` and reading
   the answer is browsing people, which an audit trail cannot tell apart from
   working.

   # NOTHING HERE DECIDES WHAT IS ALLOWED

   The erase control is hidden from a read-only role because a button that
   always fails is a bad screen — but hiding it is not the check. The server
   refuses, and there is a test for that. A screen that is the only thing
   standing between a role and an action is a screen away from being bypassed
   with a terminal.
   ========================================================================== */

const root = document.getElementById('console');

/* One request shape. `same-origin` because the session cookie is HttpOnly and
   set on the parent domain — there is no token in this file and there is not
   meant to be one. */
async function api(method, path, body) {
  const response = await fetch(path, {
    method,
    credentials: 'same-origin',
    headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (response.status === 204) return null;
  let payload = null;
  try { payload = await response.json(); } catch (e) { /* empty or not JSON */ }
  if (!response.ok) {
    const error = (payload && payload.error) || {};
    throw Object.assign(new Error(error.message || 'that did not work'), { status: response.status });
  }
  return payload;
}

const escape = (s) => String(s ?? '').replace(/[&<>"']/g,
  (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const when = (iso) => {
  const at = new Date(iso);
  return Number.isNaN(at.getTime()) ? '' : at.toISOString().slice(0, 10);
};

/* ---------- who is here ---------- */

let me = null;

async function start() {
  try {
    me = await api('GET', '/console/api/v1/me');
  } catch (e) {
    /* NOT SIGNED IN, AND THE CONSOLE CANNOT SIGN ANYBODY IN YET. Sign-in is a
       school-scoped route today, so a staff member signs in at a school's
       address and comes back. Saying so is better than a form that cannot
       work — and better than a blank screen, which is what a console does when
       it assumes everybody arrives already holding a session. */
    root.innerHTML = `
      <section class="panel">
        <h1>Console</h1>
        <p>${e.status === 401
          ? 'Sign in at your school&rsquo;s address first, then come back here. This console cannot sign anybody in yet.'
          : `Could not tell who you are: ${escape(e.message)}`}</p>
      </section>`;
    return;
  }
  screen();
}

function screen() {
  root.innerHTML = `
    <header class="panel">
      <h1>Console</h1>
      <p>${escape(me.name)} &lt;${escape(me.email)}&gt; &middot; ${escape(me.role)}</p>
    </header>

    <section class="panel">
      <h2>Somebody&rsquo;s personal data</h2>
      <form id="find" novalidate>
        <label for="email">The whole address</label>
        <input id="email" name="email" type="email" autocomplete="off" spellcheck="false"
               required aria-describedby="find-note">
        <p id="find-note">Exactly, and the whole of it. There is no search here.</p>
        <button type="submit">Look up</button>
      </form>
      <div id="answer" role="status" aria-live="polite"></div>
    </section>`;

  document.getElementById('find').addEventListener('submit', async (event) => {
    event.preventDefault();
    await look(document.getElementById('email').value.trim());
  });
}

/* ---------- one person ---------- */

const answer = () => document.getElementById('answer');

async function look(email) {
  if (!email) return;
  answer().textContent = 'Looking…';

  let person;
  try {
    person = await api('GET', `/console/api/v1/people?email=${encodeURIComponent(email)}`);
  } catch (e) {
    answer().innerHTML = `<p>${e.status === 404
      ? 'No account at that address.'
      : escape(e.message)}</p>`;
    return;
  }

  let held = { tables: {}, total: 0 };
  try {
    held = await api('GET', `/console/api/v1/people/${person.id}/held`);
  } catch (e) {
    answer().innerHTML = `<p>Found them, but could not count what is held: ${escape(e.message)}</p>`;
    return;
  }

  const carrying = Object.entries(held.tables)
    .filter(([, count]) => count > 0)
    .sort(([a], [b]) => a.localeCompare(b));

  const rows = carrying
    .map(([table, count]) => `<tr><th scope="row">${escape(table)}</th><td>${count}</td></tr>`)
    .join('');

  // Each number pluralised by ITSELF. Written as one expression it read
  // "562 rows across 18 table", because the table count was being pluralised
  // by whether there were any rows at all.
  const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`;

  /* THE COUNTS AND NOT THE CONTENTS. Reading the rows is the export, and the
     export is recorded — a screen that showed them would be an export nobody
     signed for. */
  answer().innerHTML = `
    <article class="panel">
      <h3>${escape(person.name)}</h3>
      <p>${escape(person.email)} &middot; since ${escape(when(person.createdAt))}
         ${person.synthetic ? '&middot; <strong>synthetic</strong>' : ''}</p>

      <table>
        <caption>${plural(held.total, 'row')} across ${plural(carrying.length, 'table')}</caption>
        <tbody>${rows || '<tr><td>Nothing is held about them.</td></tr>'}</tbody>
      </table>

      <p>
        <a href="/console/api/v1/people/${person.id}/export" download>Export everything</a>
        &mdash; this is recorded, with your name against it.
      </p>

      ${me.role === 'read-only' ? '' : `
      <form id="erase" novalidate>
        <h4>Erase them</h4>
        <p>This cannot be undone. It severs the person and leaves the statistics.</p>
        <label for="confirm">Type their address to confirm</label>
        <input id="confirm" name="confirm" type="email" autocomplete="off" spellcheck="false" required>
        <button type="submit">Erase</button>
      </form>`}
    </article>`;

  const erase = document.getElementById('erase');
  if (erase) {
    erase.addEventListener('submit', async (event) => {
      event.preventDefault();
      await forget(person, document.getElementById('confirm').value.trim());
    });
  }
}

async function forget(person, typed) {
  /* THE CONFIRMATION IS CHECKED BY THE SERVER TOO, against the person in the
     path. This one is here so somebody who mistyped is told immediately
     instead of by a 400 — the check that matters is the other one. */
  if (!typed) return;

  try {
    await api('POST', `/console/api/v1/people/${person.id}/erase`, { email: typed });
  } catch (e) {
    answer().insertAdjacentHTML('beforeend', `<p role="alert">${escape(e.message)}</p>`);
    return;
  }

  answer().innerHTML = `<p role="status">${escape(person.email)} has been erased. ` +
    'The entry in the audit says who did it and how much went, and does not name them.</p>';
}

start();
