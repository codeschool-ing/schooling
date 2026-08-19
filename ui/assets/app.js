/* ==========================================================================
   Schooling — the study interface

   THE ROUTES ARE FRAGMENTS. `#/course/web-fundamentals`, never
   `/course/web-fundamentals`, and that is not a preference: the offline bundle
   is one file opened from `file://`, where there is no server to fall back to
   and the History API simply does not work. That bet has been collected —
   `tools/bundle` writes the file and this is the client that runs inside it,
   unchanged, rather than a second one written to read it.

   The one exception is `/verify/<code>`, which is PRINTED ON A CERTIFICATE and
   typed by somebody checking a stranger's claim. A `#` in an address that is
   read off paper is a support conversation, so the server serves the shell for
   that path and the router reads the code out of `location.pathname`.

   NOTHING HERE KNOWS A TOKEN. The session is an HttpOnly cookie on the same
   origin (P-03); this file cannot read it and does not try.

   `offline` COMES FROM api.js AND IS NOT A NETWORK STATE. It is true only in a
   bundle opened from `file://`, and the screens branch on it BEFORE they act:
   a form that cannot be sent is not shown at all, because refusing at the last
   moment is not the same as saying so at the first.
   ========================================================================== */

import { api, ApiError, offline, asset } from './api.js';
import { render as markdown } from './markdown.js';
import { build, answerable } from './question.js';
import { buildGraph, routeEdges } from './graph.js';
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
  /* `no-server` is what the offline copy answers for everything the school
     owns. It is not a fault to report — nothing went wrong and retrying will
     not help — so it gets the explanation rather than a red box, and every
     screen gets it without each one having to know. */
  if (error instanceof ApiError && error.code === 'no-server') return onlyTheSchoolCanDoThat();

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
      body.append(el('h2', {}, [el('a', {
        href: `#/track/${encodeURIComponent(track.id)}`, text: track.name,
      })]));
      if (track.goal) body.append(el('p', { class: 'dim', text: track.goal }));
      body.append(el('p', {}, [el('a', {
        class: 'dim', href: `#/track/${encodeURIComponent(track.id)}`,
        text: `${txt('See the whole track')} →`,
      })]));
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

    /* The exam, and only when there is one — the catalogue says so, rather
       than this screen offering a button that sometimes answers 404. Not
       gated on finishing the course: the exam is what asserts that somebody
       knows the material, and insisting they click through every section
       first would be asserting that they sat through it. */
    course.exam && !course.locked ? el('div', { class: 'exam-invite' }, [
      el('h2', { text: txt('The exam') }),
      el('p', { class: 'dim', text: txt('Pass it and the certificate is yours.') }),
      state.me
        ? el('a', {
          class: 'button',
          href: `#/exam/course/${encodeURIComponent(course.id)}`,
          text: txt('Sit the exam'),
        })
        : el('a', { class: 'button quiet', href: '#/sign-in',
          text: offline ? txt('The exam needs the school') : txt('Sign in to sit it') }),
    ]) : null,
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

/* ---------- a track, drawn ----------

   THE LAYOUT IS CSS AND THE EDGES ARE MEASURED FROM IT. The cards go into a
   grid of columns, the browser lays them out, and only then are the lines
   drawn — from the boxes the browser produced rather than from positions this
   file guessed. It is why the drawing survives a different font, a longer
   course name and a narrower window: none of those are things the router has
   to be told about, because it reads them off the result.

   Which also means the edges are redrawn on a resize, and that they cannot be
   drawn before the cards are on the page. */

let redrawGraph = null;

async function trackPage(id) {
  let track;
  try {
    track = await api.track(id);
  } catch (e) {
    show(pageTitle(txt('Track')), trouble(e));
    return;
  }

  const chosen = {};   // fork index -> which option the student is looking at
  const board = el('div', { class: 'graph' }, [
    // The lines go behind the cards, and take no pointer events: an edge is a
    // picture of a relationship, not something to click.
    el('div', { class: 'graph-canvas' }, [svgLayer()]),
  ]);

  function draw() {
    const graph = buildGraph(track, state.courses, chosen);
    const canvas = board.querySelector('.graph-canvas');

    /* WHICH WAY THE TRACK RUNS IS DECIDED BY THE ROOM THERE IS. A track of
       seven levels laid out left to right needs about eighteen hundred pixels;
       on a phone held upright there are four hundred, and what you get is a
       drawing you read by dragging sideways, one card at a time, which is not
       reading it at all. Flowing downwards it is a column, which is the shape a
       phone has.

       The router serves both from one axis — see graph.js — so this is a class
       and a boolean rather than a second implementation. */
    const down = window.innerWidth < 900;
    board.classList.toggle('flows-down', down);

    canvas.textContent = '';
    canvas.append(svgLayer());

    graph.columns.forEach((column) => {
      canvas.append(el('div', { class: 'graph-column' }, column.map((node) => nodeCard(node))));
    });

    /* Twice, and the second is not paranoia: the first pass runs before the
       browser has settled the layout, so the boxes it measures are the right
       shape in the wrong place. The frame after is when they are real. */
    routeEdges(canvas, graph, down);
    requestAnimationFrame(() => routeEdges(canvas, graph, down));

    /* AND AGAIN WHEN THE FONTS LAND. They are asked for with `display=swap`, so
       the first layout is the fallback's and the second is the real one — a
       card that was one line becomes two and everything below it moves. The
       cards move with it because the browser lays them out again; the lines do
       not, because nothing re-runs the router. Until this, a visitor on a slow
       connection got arrows pointing at where the cards had been. */
    document.fonts.ready.then(() => {
      if (canvas.isConnected) routeEdges(canvas, graph, down);
    });
  }

  function nodeCard(node) {
    if (node.kind === 'finish') {
      return el('div', { class: 'node finish', 'data-node': node.id }, [
        el('span', { text: txt('Finish') }),
      ]);
    }

    if (node.kind === 'fork') {
      const options = node.step.options || [];
      return el('div', { class: 'node fork', 'data-node': node.id }, [
        el('p', { class: 'fork-choice', text: node.step.choice || txt('Choose one') }),
        node.step.note ? el('p', { class: 'dim', text: node.step.note }) : null,
        el('div', { class: 'fork-options' }, options.map((option, i) => el('button', {
          type: 'button',
          class: 'fork-option' + ((chosen[node.index] || 0) === i ? ' on' : ''),
          'aria-pressed': String((chosen[node.index] || 0) === i),
          text: option.name,
          /* Choosing a branch redraws the whole track, because which courses
             are on it changes what the graph IS — not merely which card is
             highlighted. */
          onclick: () => { chosen[node.index] = i; draw(); },
        }))),
      ]);
    }

    const course = state.courses.find((c) => c.id === node.id);
    return el('a', {
      class: 'node course' + (course && course.locked ? ' is-locked' : ''),
      'data-node': node.id,
      href: `#/course/${encodeURIComponent(node.id)}`,
    }, [
      el('span', { class: 'node-name', text: course ? course.name : node.id }),
      course && course.hours ? el('span', { class: 'dim node-hours', text: `${course.hours} h` }) : null,
    ]);
  }

  show(
    pageTitle(track.name, track.goal),
    track.outcome ? el('p', { class: 'dim', text: `${txt('Leads to')}: ${track.outcome}` }) : null,
    board,
    track.exam ? el('div', { class: 'exam-invite' }, [
      el('h2', { text: txt('The final') }),
      el('p', { class: 'dim', text: txt('The exam for the whole track.') }),
      state.me
        ? el('a', {
          class: 'button', href: `#/exam/track/${encodeURIComponent(track.id)}`,
          text: txt('Sit the final'),
        })
        : el('a', { class: 'button quiet', href: '#/sign-in',
          text: offline ? txt('The exam needs the school') : txt('Sign in to sit it') }),
    ]) : null,
  );

  draw();

  /* Redrawn when the window changes size, because the columns rewrap and every
     box the router measured has moved. One listener, replaced on each
     navigation rather than accumulated. */
  redrawGraph = draw;
}

function svgLayer() {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('class', 'graph-edges');
  svg.setAttribute('aria-hidden', 'true');
  return svg;
}

/* ---------- sitting an exam ----------

   THE PAPER IS THE SERVER'S. This screen draws what it was given, records each
   answer as it is made, and hands in. It keeps no copy of the questions, works
   out no marks, and has no idea which answer is right — the whole point of the
   server presenting a question rather than sending it is that the client
   cannot know, so a client that tried to be clever here would be a client that
   had been given the key.

   EVERY ANSWER IS SENT AS IT IS MADE, not collected and posted at the end. A
   student who closes the tab, loses the connection or runs out of battery has
   answered the questions they answered; a paper that only existed in a
   JavaScript variable would lose all of them. It is also what makes resuming
   real: starting again returns the same attempt with the same answers on it. */

async function examPage(scope, id) {
  if (!state.me) { go('#/sign-in'); return; }

  show(pageTitle(txt('Exam')));

  let paper;
  try {
    const answer = await api.startExam(scope, id);
    paper = answer.paper;
  } catch (e) {
    show(pageTitle(txt('Exam')), trouble(e));
    return;
  }

  drawPaper(paper);
}

function drawPaper(paper) {
  /* A paper that is already marked is a result, not a form. Reaching this by
     starting an exam cannot produce one — the server would have drawn a fresh
     attempt — but reaching it by opening an attempt directly can. */
  if (paper.result) { drawResult(paper); return; }

  const controls = [];
  const unanswerable = paper.questions.filter((q) => !answerable(q.type));

  const form = el('form', {
    class: 'paper',
    onsubmit: (event) => event.preventDefault(),
  }, paper.questions.map((question, index) => {
    const name = `q-${paper.attempt}-${question.position}`;
    /* Where this course's pictures live. Only `labelling` asks, and it asks for
       a file name rather than building a path — see question.js. */
    const pictures = (file) => (paper.scope === 'course' && paper.exam
      ? asset(`/api/v1/courses/${encodeURIComponent(paper.exam)}/images/${encodeURIComponent(file)}`)
      : '');

    const built = build(question.type, question.question, name, question.answer, pictures);
    controls.push({ question, built, saved: null });

    const saved = el('span', { class: 'saved dim', 'aria-live': 'polite' });

    /* Recorded on the way past: changing a control sends it. The reply says
       nothing about whether it was right — the paper is not marked until it is
       handed in — so all this can report is that it was written down. */
    built.node.addEventListener('change', async () => {
      const answer = built.read();
      if (!answer) return;
      saved.textContent = txt('Saving…');
      try {
        await api.answer(paper.attempt, question.position, answer);
        saved.textContent = txt('Saved');
      } catch (e) {
        saved.textContent = (e instanceof ApiError && e.message) ? txt(e.message) : txt('Not saved');
      }
    });

    return el('section', { class: 'question' }, [
      el('div', { class: 'question-head' }, [
        el('span', { class: 'dim mono', text: `${index + 1} / ${paper.questions.length}` }),
        saved,
      ]),
      /* No heading here: the prompt is the fieldset's legend, which is what
         ties it to the controls. A heading saying the same sentence would be
         that sentence read out twice. */
      built.node,
    ]);
  }));

  const handIn = el('button', {
    class: 'button', type: 'button', text: txt('Hand in'),
    onclick: async (event) => {
      const button = event.currentTarget;

      /* ONCE, AND SAID OUT LOUD FIRST. Handing in is the end of the attempt:
         the answers freeze, the paper is marked, and there is no way back to
         it. A confirmation is not friction here, it is the difference between
         an exam and a form. */
      if (!window.confirm(txt('Hand in this exam? You cannot change your answers afterwards.'))) {
        return;
      }
      button.disabled = true;

      /* Whatever is on screen and not yet sent — a text box somebody typed in
         and never left. Without this, the last answer of a paper is the one
         most likely to be lost. */
      for (const { question, built } of controls) {
        const answer = built.read();
        if (!answer) continue;
        try {
          await api.answer(paper.attempt, question.position, answer);
        } catch (e) { /* it will be marked as whatever did reach the server */ }
      }

      try {
        const answer = await api.handIn(paper.attempt);
        drawResult(answer.paper);
      } catch (e) {
        button.disabled = false;
        button.after(trouble(e));
      }
    },
  });

  show(
    pageTitle(examTitle(paper), txt('Answers are saved as you make them.')),
    unanswerable.length ? el('div', { class: 'notice bad', role: 'note' }, [
      el('p', {
        text: `${unanswerable.length} ${txt('questions on this paper cannot be answered here yet.')}`,
      }),
    ]) : null,
    form,
    el('div', { class: 'hand-in' }, [handIn]),
  );
}

function drawResult(paper) {
  const result = paper.result || { score: 0, of: 0, pass_mark: 0, passed: false };
  const share = result.of ? Math.round((result.score / result.of) * 100) : 0;

  show(
    pageTitle(examTitle(paper)),
    el('div', { class: `result ${result.passed ? 'passed' : 'failed'}` }, [
      el('p', { class: 'verdict', text: result.passed ? txt('Passed') : txt('Not passed') }),
      el('p', { class: 'score mono', text: `${result.score} / ${result.of}` }),
      /* The threshold is shown beside the number it produced (K-16). A score
         with no mark beside it is a number somebody has to be told the meaning
         of, and "70%" answers the only question they have. */
      el('p', { class: 'dim', text: `${share}% · ${txt('pass mark')} ${result.pass_mark}%` }),
    ]),

    result.passed
      ? el('p', {}, [el('a', { class: 'button', href: '#/certificates', text: txt('Your certificates') })])
      : el('p', { class: 'dim', text: txt('You can sit this exam again.') }),

    el('h2', { text: txt('Your answers') }),
    el('ol', { class: 'marked' }, paper.questions.map((question) => el('li', {
      class: question.correct ? 'right' : 'wrong',
    }, [
      el('span', { class: 'mark', 'aria-hidden': 'true', text: question.correct ? '✓' : '✗' }),
      /* The word as well as the glyph: a tick is a picture, and the result of
         an exam is not something to say only in pictures. */
      el('span', { class: 'visually-hidden', text: question.correct ? txt('Right') : txt('Wrong') }),
      el('span', { text: (question.question && question.question.prompt) || '' }),
    ]))),
  );
}

/* An attempt read by its own address: what a paper looks like after it was
   handed in, and how somebody gets back to one they left open. */
async function attemptPage(id) {
  if (!state.me) { go('#/sign-in'); return; }

  show(pageTitle(txt('Exam')));
  try {
    const answer = await api.attempt(id);
    drawPaper(answer.paper);
  } catch (e) {
    show(pageTitle(txt('Exam')), trouble(e));
  }
}

/* An address nobody wrote. It says so rather than showing an empty screen,
   which is what a router with a silent default produces. */
function notFound() {
  show(
    pageTitle(txt('Not found')),
    el('p', { class: 'dim', text: txt('There is nothing at that address.') }),
    el('p', {}, [el('a', { class: 'button', href: '#/', text: txt('Back to the courses') })]),
  );
}

function examTitle(paper) {
  const course = state.courses.find((c) => c.id === paper.exam);
  return `${txt('Exam')}: ${course ? course.name : paper.exam}`;
}

async function dashboard() {
  if (!state.me) { go('#/sign-in'); return; }

  show(pageTitle(txt('Your study')));

  let resume = [];
  let certificates = [];
  let attempts = [];
  try {
    const [r, c, a] = await Promise.all([api.resume(), api.certificates(), api.attempts()]);
    resume = (r && r.resume) || [];
    certificates = (c && c.certificates) || [];
    attempts = (a && a.attempts) || [];
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

    /* An open attempt first, because it is the only thing on this screen with
       a deadline attached to it — the paper is drawn and waiting. */
    attempts.length ? el('div', {}, [
      el('h2', { text: txt('Your exams') }),
      el('ul', { class: 'attempts' }, attempts.map((attempt) => {
        const course = state.courses.find((c) => c.id === attempt.exam);
        const name = course ? course.name : attempt.exam;
        return el('li', {}, [
          el('a', { href: `#/attempt/${encodeURIComponent(attempt.attempt)}`, text: name }),
          attempt.result
            ? el('span', {
              class: attempt.result.passed ? 'tag free' : 'tag locked',
              text: attempt.result.passed
                ? `${txt('Passed')} · ${attempt.result.score}/${attempt.result.of}`
                : `${txt('Not passed')} · ${attempt.result.score}/${attempt.result.of}`,
            })
            : el('span', { class: 'tag', text: txt('Still open') }),
        ]);
      })),
    ]) : null,

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

/* WHAT THE OFFLINE COPY SAYS INSTEAD OF A FORM IT CANNOT SEND.
   Everything that needs the school arrives here: signing in, the dashboard,
   certificates — the screens that are a record of a student, which a copy of a
   file does not have. It names what DOES work, because "unavailable" on its own
   reads as broken and this is not broken. */
function onlyTheSchoolCanDoThat() {
  return el('div', { class: 'notice', role: 'status' }, [
    el('p', { text: txt('This is the offline copy of this school.') }),
    el('p', { class: 'dim', text: txt('Courses, tracks and lessons are all here and need no connection. Signing in, your progress and exams live with the school, so they are not.') }),
    el('p', {}, [el('a', { class: 'button quiet', href: '#/', text: txt('Back to the courses') })]),
  ]);
}

function signIn() {
  if (offline) { show(pageTitle(txt('Sign in')), onlyTheSchoolCanDoThat()); return; }

  show(pageTitle(txt('Sign in')), credentialsForm({
    submit: txt('Sign in'),
    withName: false,
    action: (email, password) => api.signIn(email, password),
    otherHref: '#/sign-up',
    otherText: txt('Create an account'),
  }));
}

function signUp() {
  if (offline) { show(pageTitle(txt('Create an account')), onlyTheSchoolCanDoThat()); return; }

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

  // Whatever screen comes next, it is not the graph until it says so.
  redrawGraph = null;

  switch (parts[0]) {
    case undefined:            await catalogue(); break;
    case 'course':
      if (parts[2]) await lessonPage(parts[1], parts[2]);
      else if (parts[1]) await coursePage(parts[1]);
      else await catalogue();
      break;
    case 'exam':
      /* The scope is one of two words and it comes from the address, so it is
         checked here rather than passed through: an invented one would reach
         the API as a path segment nobody wrote. */
      if ((parts[1] === 'course' || parts[1] === 'track') && parts[2]) {
        await examPage(parts[1], parts[2]);
      } else {
        await notFound();
      }
      break;
    case 'attempt':
      if (parts[1]) await attemptPage(parts[1]);
      else await notFound();
      break;
    case 'track':
      if (parts[1]) await trackPage(parts[1]);
      else await catalogue();
      break;
    case 'dashboard':          await dashboard(); break;
    case 'certificates':       await certificates(); break;
    case 'sign-in':            signIn(); break;
    case 'sign-up':            signUp(); break;
    default:
      await notFound();
  }

  drawSidebar(parts[0] === 'course' ? parts[1] : null);
  closeSidebar();
  focusScreen();
}

/* The graph is the one screen that has to be redrawn when the window changes
   size: its lines are measured off boxes the browser placed, and every one of
   them moves. Cleared on every navigation, so a resize on the catalogue does
   not run a redraw against a track that is no longer on the page. */
window.addEventListener('resize', () => {
  if (redrawGraph) redrawGraph();
});

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

  /* No door where there is no room behind it. The offline copy keeps the
     sign-in SCREEN — a bookmark or an old link still lands there and gets an
     explanation — but it does not put a button in the chrome inviting somebody
     to try. */
  if (offline) {
    link.hidden = true;
    account.hidden = true;
    return;
  }

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
