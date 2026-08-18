/* ==========================================================================
   Schooling — the study interface

   THE ROUTES ARE FRAGMENTS. `#/course/web-fundamentals`, never
   `/course/web-fundamentals`, and that is not a preference: the offline bundle
   is one file opened from `file://`, where there is no server to fall back to
   and the History API simply does not work. Choosing fragments now makes the
   bundle a packaging job later instead of a second router.

   The one exception is `/verify/<code>`, which is PRINTED ON A CERTIFICATE and
   typed by somebody checking a stranger's claim. A `#` in an address that is
   read off paper is a support conversation, so the server serves the shell for
   that path and the router reads the code out of `location.pathname`.

   NOTHING HERE KNOWS A TOKEN. The session is an HttpOnly cookie on the same
   origin (P-03); this file cannot read it and does not try.

   WHAT IS NOT HERE YET: sitting an exam, and the track graph. Both have their
   server halves and neither has a screen. They are the next two pieces rather
   than an omission — a screen that half-renders an exam would be worse than a
   link that says the exam is next.
   ========================================================================== */

import { api, ApiError } from './api.js';
import { render as markdown } from './markdown.js';
import {
  txt, contentLocale, mapTexts, applyTexts, buildLanguagePicker, missingTranslations,
} from './i18n.js';

/* ---------- the little that is remembered ---------- */

const state = {
  me: null,          // the signed-in account, or null
  school: null,      // { slug, name, accent }
  courses: [],       // the catalogue, as this student may see it
  query: '',         // what is in the search box
};

/* ---------- building blocks ----------

   Elements are built rather than assembled from strings. It is not taste: the
   one place this file writes HTML is the Markdown renderer, and keeping that
   the ONLY one means "does anything here paste text into innerHTML" has a
   one-word answer. */

function el(tag, props = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (value === undefined || value === null || value === false) continue;
    if (key === 'class') node.className = value;
    else if (key === 'text') node.textContent = value;
    else if (key === 'html') node.innerHTML = value;
    else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
    else if (value === true) node.setAttribute(key, '');
    else node.setAttribute(key, value);
  }
  for (const child of [].concat(children)) {
    if (child === null || child === undefined || child === false) continue;
    node.append(child);
  }
  return node;
}

const screen = () => document.querySelector('#screen');

function show(...nodes) {
  const main = screen();
  main.textContent = '';
  nodes.filter(Boolean).forEach((n) => main.append(n));
}

/* A message a person can act on, and never a status code. `offline` is the one
   worth telling somebody to retry; everything else is a state of the world.

   THE SERVER'S MESSAGE GOES THROUGH txt() TOO. It arrives in English, and
   English is the key — so a sentence the API wrote can be translated by adding
   an entry for it, and one nobody has translated is shown in English rather
   than swallowed. The interface-string checker cannot see these, because they
   are written in Go; that is the known edge of what a static check reaches. */
function trouble(error) {
  const message = (error instanceof ApiError && error.message)
    ? txt(error.message) : txt('Something went wrong');
  return el('div', { class: 'notice bad', role: 'alert' }, [
    el('p', { text: message }),
    error instanceof ApiError && error.code === 'offline'
      ? el('p', { class: 'dim', text: txt('Check your connection and try again.') })
      : null,
  ]);
}

function pageTitle(title, subtitle) {
  return el('div', {}, [
    el('h1', { text: title }),
    subtitle ? el('p', { class: 'dim', text: subtitle }) : null,
  ]);
}

/* ---------- screens ---------- */

async function catalogue() {
  show(pageTitle(state.school ? state.school.name : txt('Courses'), txt('What there is to learn here.')));

  let tracks = [];
  try {
    const answer = await api.tracks();
    tracks = (answer && answer.tracks) || [];
  } catch (e) {
    show(pageTitle(txt('Courses')), trouble(e));
    return;
  }

  const matching = filtered(state.courses);
  const body = el('div', {});

  if (state.query && matching.length === 0) {
    body.append(el('p', { class: 'empty', text: txt('Nothing here matches that.') }));
  }

  if (!state.query) {
    tracks.forEach((track) => {
      body.append(el('h2', { text: track.name }));
      if (track.goal) body.append(el('p', { class: 'dim', text: track.goal }));
      body.append(courseGrid(coursesOfTrack(track)));
    });
  }

  const rest = state.query ? matching : coursesOutsideTracks(tracks);
  if (rest.length) {
    if (!state.query) body.append(el('h2', { text: txt('Everything else') }));
    body.append(courseGrid(rest));
  }

  show(pageTitle(state.school ? state.school.name : txt('Courses'),
    txt('What there is to learn here.')), body);
}

function coursesOfTrack(track) {
  const ids = [];
  (track.steps || []).forEach((step) => {
    if (step.course) ids.push(step.course);
    (step.options || []).forEach((option) => (option.courses || []).forEach((id) => ids.push(id)));
  });
  return ids.map((id) => state.courses.find((c) => c.id === id)).filter(Boolean);
}

function coursesOutsideTracks(tracks) {
  const inside = new Set(tracks.flatMap((t) => coursesOfTrack(t)).map((c) => c.id));
  return state.courses.filter((c) => !inside.has(c.id));
}

function filtered(courses) {
  const q = state.query.trim().toLowerCase();
  if (!q) return courses;
  return courses.filter((c) =>
    `${c.name} ${c.summary || ''} ${c.category || ''}`.toLowerCase().includes(q));
}

function courseGrid(courses) {
  if (!courses.length) return el('p', { class: 'empty', text: txt('Nothing here yet.') });

  return el('div', { class: 'grid' }, courses.map((course) => el('a', {
    class: 'card' + (course.locked ? ' is-locked' : ''),
    href: `#/course/${encodeURIComponent(course.id)}`,
  }, [
    el('h3', { text: course.name }),
    course.summary ? el('p', { class: 'dim', text: course.summary }) : null,
    el('div', { class: 'meta' }, [
      course.hours ? el('span', { text: `${course.hours} h` }) : null,
      course.level ? el('span', { text: course.level }) : null,
      /* The free tier is the shop window and is open at every door (N-04), so
         it is said on the card rather than discovered at the paywall. */
      course.free ? el('span', { class: 'tag free', text: txt('Free') }) : null,
      course.locked ? el('span', { class: 'tag locked', text: txt('Subscription') }) : null,
    ]),
  ])));
}

async function coursePage(id) {
  let course;
  let done = [];
  try {
    course = await api.course(id);
  } catch (e) {
    show(pageTitle(txt('Course')), trouble(e));
    return;
  }

  /* Progress is a second request and a failing one must not take the course
     down with it: somebody who cannot see their ticks can still read the
     lesson, and that is the more important half. */
  if (state.me) {
    try {
      const answer = await api.progress(id);
      done = (answer && answer.completed) || [];
    } catch (e) { /* the ticks are missing; the course is not */ }
  }

  const finished = new Set(done.map((d) => `${d.lesson}/${d.section}`));
  const sections = (course.lessons || []).flatMap((l) => l.sections.map((s) => `${l.id}/${s.id}`));
  const share = sections.length ? Math.round((finished.size / sections.length) * 100) : 0;

  show(
    pageTitle(course.name, course.summary),
    course.locked ? el('div', { class: 'notice', role: 'note' }, [
      el('p', { text: txt('This course is part of the subscription.') }),
    ]) : null,
    state.me && sections.length ? el('div', {}, [
      el('div', { class: 'bar' }, [el('i', { style: `width:${share}%` })]),
      el('p', { class: 'dim', text: `${share}% ${txt('complete')}` }),
    ]) : null,
    el('ol', { class: 'lessons' }, (course.lessons || []).map((lesson) => el('li', {}, [
      el('h3', {}, [el('a', {
        href: `#/course/${encodeURIComponent(course.id)}/${encodeURIComponent(lesson.id)}`,
        text: lesson.title,
      })]),
      el('p', { class: 'dim', text: `${lesson.sections.length} ${txt('sections')}` }),
    ]))),
  );
}

async function lessonPage(courseID, lessonID) {
  let lesson;
  try {
    lesson = await api.lesson(courseID, lessonID, contentLocale());
  } catch (e) {
    show(pageTitle(txt('Lesson')), trouble(e));
    return;
  }

  const body = el('div', { class: 'prose' });
  (lesson.sections || []).forEach((section) => {
    body.append(el('h2', { text: section.title || section.id }));
    if (section.body) body.append(el('div', { html: markdown(section.body) }));

    /* Only a countable section can be finished, and only a signed-in student
       has anywhere to record it. Completion is set-true and never toggled
       (A-05), so a finished section has no button at all rather than one that
       would take it back. */
    if (state.me && section.countable !== false) {
      body.append(el('button', {
        class: 'button quiet',
        type: 'button',
        text: txt('Mark as done'),
        onclick: async (event) => {
          const button = event.currentTarget;
          button.disabled = true;
          try {
            await api.complete(courseID, lessonID, section.id);
            button.replaceWith(el('p', { class: 'dim', text: txt('Done') }));
          } catch (e) {
            button.disabled = false;
            button.after(trouble(e));
          }
        },
      }));
    }
  });

  show(
    el('p', {}, [el('a', {
      class: 'dim', href: `#/course/${encodeURIComponent(courseID)}`, text: `← ${txt('Back to the course')}`,
    })]),
    pageTitle(lesson.title),
    body,
  );

  /* Where they were, so "carry on where you left off" sends them here. Opening
     is not finishing — that is what makes this a visit and not a completion. */
  const first = (lesson.sections || [])[0];
  if (state.me && first) api.visit(courseID, lessonID, first.id).catch(() => {});
}

async function dashboard() {
  if (!state.me) { go('#/sign-in'); return; }

  show(pageTitle(txt('Your study')));

  let resume = [];
  let certificates = [];
  try {
    const [r, c] = await Promise.all([api.resume(), api.certificates()]);
    resume = (r && r.resume) || [];
    certificates = (c && c.certificates) || [];
  } catch (e) {
    show(pageTitle(txt('Your study')), trouble(e));
    return;
  }

  show(
    pageTitle(txt('Your study')),
    el('h2', { text: txt('Carry on where you left off') }),
    resume.length ? el('div', { class: 'grid' }, resume.map((where) => {
      const course = state.courses.find((c) => c.id === where.course);
      return el('a', {
        class: 'card',
        href: `#/course/${encodeURIComponent(where.course)}/${encodeURIComponent(where.lesson)}`,
      }, [
        el('h3', { text: course ? course.name : where.course }),
        el('p', { class: 'dim', text: where.section }),
      ]);
    })) : el('p', { class: 'empty', text: txt('You have not started anything yet.') }),

    el('h2', { text: txt('Your certificates') }),
    certificates.length
      ? el('div', { class: 'grid' }, certificates.map(certificateCard))
      : el('p', { class: 'empty', text: txt('A certificate arrives when you pass an exam.') }),
  );
}

function certificateCard(certificate) {
  return el('a', { class: 'card', href: `/verify/${encodeURIComponent(certificate.code)}` }, [
    el('h3', { text: certificate.title }),
    el('p', { class: 'dim', text: certificate.school }),
    el('p', { class: 'mono dim', text: grouped(certificate.code) }),
  ]);
}

/* The code as it is printed, in fours. The server answers with this too; it is
   computed here as well so a list of certificates does not need a request per
   row to know how to show one. */
function grouped(code) {
  return String(code).replace(/(.{4})(?=.)/g, '$1-');
}

async function certificates() {
  if (!state.me) { go('#/sign-in'); return; }

  try {
    const answer = await api.certificates();
    const held = (answer && answer.certificates) || [];
    show(
      pageTitle(txt('Your certificates')),
      held.length
        ? el('div', { class: 'grid' }, held.map(certificateCard))
        : el('p', { class: 'empty', text: txt('A certificate arrives when you pass an exam.') }),
    );
  } catch (e) {
    show(pageTitle(txt('Your certificates')), trouble(e));
  }
}

/* THE PUBLIC ONE. It asks for nothing and it is reached by somebody who has no
   account here and does not want one. */
async function verify(code) {
  show(pageTitle(txt('Verify a certificate')));

  try {
    const answer = await api.verify(code);
    const c = answer.certificate;
    show(
      pageTitle(txt('Verify a certificate')),
      el('div', { class: 'certificate' }, [
        el('p', { class: 'dim', text: txt('This certificate is genuine.') }),
        el('p', { class: 'who', text: c.name }),
        el('p', { text: c.title }),
        el('p', { class: 'dim', text: `${c.school} · ${new Date(c.issued_at).toLocaleDateString()}` }),
        el('p', { class: 'code', text: answer.code_as_printed || grouped(c.code) }),
      ]),
    );
  } catch (e) {
    /* A code that certifies nothing is a RESULT, not an error page — it is what
       somebody checking a false claim came here to find out. It reads the same
       for a code that never existed and one that has been erased, which is
       deliberate: answering differently would say a certificate had been
       there. */
    if (e instanceof ApiError && e.status === 404) {
      show(
        pageTitle(txt('Verify a certificate')),
        el('div', { class: 'notice bad', role: 'status' }, [
          el('p', { text: txt('No certificate has that code.') }),
        ]),
      );
      return;
    }
    show(pageTitle(txt('Verify a certificate')), trouble(e));
  }
}

function signIn() {
  show(pageTitle(txt('Sign in')), credentialsForm({
    submit: txt('Sign in'),
    withName: false,
    action: (email, password) => api.signIn(email, password),
    otherHref: '#/sign-up',
    otherText: txt('Create an account'),
  }));
}

function signUp() {
  show(pageTitle(txt('Create an account')), credentialsForm({
    submit: txt('Create an account'),
    withName: true,
    action: (email, password, name) => api.signUp(email, password, name),
    otherHref: '#/sign-in',
    otherText: txt('I already have an account'),
  }));
}

function credentialsForm({ submit, withName, action, otherHref, otherText }) {
  const why = el('p', { class: 'why', id: 'form-why', role: 'alert' });
  const email = el('input', { type: 'email', id: 'email', autocomplete: 'email', required: true });
  const password = el('input', {
    type: 'password', id: 'password', required: true,
    autocomplete: withName ? 'new-password' : 'current-password',
  });
  const name = el('input', { type: 'text', id: 'name', autocomplete: 'name' });

  const form = el('form', {
    class: 'form',
    onsubmit: async (event) => {
      event.preventDefault();
      why.textContent = '';
      try {
        await action(email.value, password.value, withName ? name.value : undefined);
        await loadMe();
        go('#/dashboard');
      } catch (e) {
        why.textContent = (e instanceof ApiError && e.message) ? txt(e.message) : txt('That did not work.');
        email.focus();
      }
    },
  }, [
    el('div', { class: 'field' }, [el('label', { for: 'email', text: txt('E-mail') }), email]),
    el('div', { class: 'field' }, [el('label', { for: 'password', text: txt('Password') }), password]),
    withName ? el('div', { class: 'field' }, [
      el('label', { for: 'name', text: txt('Your name') }), name,
      /* Said here rather than at the moment it stops them: a certificate
         carries a name, and finding that out after passing an exam is finding
         it out at the worst moment. */
      el('p', { class: 'dim', text: txt('This is the name that goes on your certificates.') }),
    ]) : null,
    why,
    el('button', { class: 'button', type: 'submit', text: submit }),
    el('p', {}, [el('a', { class: 'dim', href: otherHref, text: otherText })]),
  ]);

  email.setAttribute('aria-describedby', 'form-why');
  password.setAttribute('aria-describedby', 'form-why');
  return form;
}

/* ---------- the sidebar ---------- */

function drawSidebar(current) {
  const body = document.querySelector('#sidebar-body');
  body.textContent = '';

  const courses = filtered(state.courses);
  if (!courses.length) {
    body.append(el('p', { class: 'dim', text: txt('Nothing here yet.') }));
    return;
  }

  const group = el('div', { class: 'side-group' }, [
    el('p', { class: 'side-title', text: txt('Courses') }),
  ]);

  courses.forEach((course) => {
    group.append(el('a', {
      class: 'side-link',
      href: `#/course/${encodeURIComponent(course.id)}`,
      'aria-current': current === course.id ? 'page' : null,
    }, [
      el('span', { text: course.name }),
      /* Said here as well as on the card, because this is the list somebody
         navigates from: a link that leads to a paywall should look like one
         BEFORE it is clicked. The word rather than a glyph — a padlock is a
         picture a screen reader has to be told the meaning of, and the meaning
         is one short word. */
      course.locked ? el('span', { class: 'side-lock', text: txt('Subscription') }) : null,
    ]));
  });

  body.append(group);
}

/* ---------- the router ---------- */

function go(hash) {
  if (location.hash === hash) route();
  else location.hash = hash;
}

async function route() {
  /* The printed address, which is a path and not a fragment. */
  if (location.pathname.startsWith('/verify/')) {
    await verify(decodeURIComponent(location.pathname.slice('/verify/'.length)));
    focusScreen();
    return;
  }

  const parts = (location.hash.replace(/^#\/?/, '') || '').split('/').filter(Boolean).map(decodeURIComponent);

  switch (parts[0]) {
    case undefined:            await catalogue(); break;
    case 'course':
      if (parts[2]) await lessonPage(parts[1], parts[2]);
      else if (parts[1]) await coursePage(parts[1]);
      else await catalogue();
      break;
    case 'dashboard':          await dashboard(); break;
    case 'certificates':       await certificates(); break;
    case 'sign-in':            signIn(); break;
    case 'sign-up':            signUp(); break;
    default:
      /* An address nobody wrote. It says so rather than showing an empty
         screen, which is what a router with a silent default produces. */
      show(pageTitle(txt('Not found')), el('p', {
        class: 'dim', text: txt('There is nothing at that address.'),
      }), el('p', {}, [el('a', { class: 'button', href: '#/', text: txt('Back to the courses') })]));
  }

  drawSidebar(parts[0] === 'course' ? parts[1] : null);
  closeSidebar();
  focusScreen();
}

/* A fragment router changes the page without a page load, so nothing moves
   focus and nothing is announced. Both are done here — but NOT ON THE FIRST
   SCREEN.

   The difference matters and it was found by trying it. After a navigation,
   moving focus into the content is right: without it a keyboard user's next Tab
   carries on from wherever they were in the chrome (WCAG 2.4.3). On the FIRST
   render there has been no navigation — the browser has just loaded the page,
   focus is at the top of the document, and moving it into the content puts the
   skip link and the whole chrome BEHIND the user. Tab then goes to the first
   course card and the skip link cannot be reached going forwards at all, which
   is precisely the thing the skip link exists to fix. */
let landed = false;

function focusScreen() {
  if (!landed) { landed = true; return; }
  const main = screen();
  main.focus({ preventScroll: true });
  window.scrollTo({ top: 0, behavior: 'instant' });
}

/* ---------- the chrome ---------- */

function closeSidebar() {
  document.querySelector('#sidebar').classList.remove('is-open');
  document.querySelector('#menu-button').setAttribute('aria-expanded', 'false');
}

function wireChrome() {
  document.querySelector('#menu-button').addEventListener('click', (event) => {
    const sidebar = document.querySelector('#sidebar');
    const open = sidebar.classList.toggle('is-open');
    event.currentTarget.setAttribute('aria-expanded', String(open));
  });

  document.querySelector('#theme-button').addEventListener('click', () => {
    const root = document.documentElement;
    const next = root.dataset.theme === 'light' ? 'dark' : 'light';
    root.dataset.theme = next;
    try { localStorage.setItem('codeschool-theme', next); } catch (e) { /* private mode */ }
  });

  /* Both pickers, one behaviour: a click opens, a click anywhere else closes,
     and Escape closes — the last of which is the one everybody forgets and the
     one a keyboard user needs to get out without tabbing through the menu. */
  document.querySelectorAll('.picker').forEach((picker) => {
    const button = picker.querySelector('.picker-button');
    button.addEventListener('click', () => {
      const open = !picker.classList.contains('is-open');
      document.querySelectorAll('.picker').forEach((p) => p.classList.remove('is-open'));
      picker.classList.toggle('is-open', open);
      button.setAttribute('aria-expanded', String(open));
    });
  });
  document.addEventListener('click', (event) => {
    if (event.target.closest('.picker')) return;
    document.querySelectorAll('.picker').forEach((p) => {
      p.classList.remove('is-open');
      p.querySelector('.picker-button').setAttribute('aria-expanded', 'false');
    });
  });
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    document.querySelectorAll('.picker.is-open').forEach((p) => {
      p.classList.remove('is-open');
      p.querySelector('.picker-button').setAttribute('aria-expanded', 'false');
      p.querySelector('.picker-button').focus();
    });
    closeSidebar();
  });

  const search = document.querySelector('#search');
  const input = document.querySelector('#search-input');
  search.addEventListener('submit', (event) => event.preventDefault());
  input.addEventListener('input', () => {
    state.query = input.value;
    drawSidebar();
    if (!location.hash || location.hash === '#/' || location.hash === '#') catalogue();
  });

  document.querySelector('#sign-out').addEventListener('click', async () => {
    try { await api.signOut(); } catch (e) { /* the cookie may already be gone */ }
    state.me = null;
    drawAccount();
    go('#/');
  });
}

function drawAccount() {
  const link = document.querySelector('#sign-in-link');
  const account = document.querySelector('#account');

  if (state.me) {
    link.hidden = true;
    account.hidden = false;
    document.querySelector('#account-name').textContent = state.me.name || state.me.email;
  } else {
    link.hidden = false;
    account.hidden = true;
  }
}

async function loadMe() {
  try {
    state.me = await api.me();
  } catch (e) {
    state.me = null;   // not signed in, which is half of this platform's traffic
  }
  drawAccount();
}

/* ---------- start ---------- */

async function start() {
  mapTexts();
  applyTexts();
  buildLanguagePicker(() => { drawSidebar(); route(); });
  wireChrome();

  /* The school's name in the chrome, and the account, before the first screen —
     both are chrome that would otherwise appear a beat late and move the
     layout under somebody's cursor. */
  try {
    state.school = await api.school();
    document.querySelector('#school-name').textContent = state.school.name;
    document.title = state.school.name;
  } catch (e) { /* the shell stands without it */ }

  await loadMe();

  try {
    const answer = await api.courses();
    state.courses = (answer && answer.courses) || [];
  } catch (e) { /* every screen below reports its own trouble */ }

  window.addEventListener('hashchange', route);
  await route();
}

/* Exposed for the interface-string checker, which drives a real browser and
   asks the page which of its own sentences have no translation. It is the
   runtime's own answer rather than a second implementation that could disagree
   with it about what counts as a string. */
window.__missingTranslations = missingTranslations;

start();
