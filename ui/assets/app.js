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
  tracks: [],        // the tracks, for the sidebar and the chip in the bar
  done: {},          // course id -> countable sections finished
  query: '',         // what is in the search box
};

/* ---------- how far along ----------

   Two numbers, kept apart because two different modules own them: the
   catalogue says how many sections a course HAS, and progress says how many
   this student has FINISHED. Nothing on the server divides one by the other,
   which is why the division is here. */

function doneIn(course) {
  return state.done[course.id] || 0;
}

/* The share of a course that is finished, 0 to 100.
   A course with no countable sections is 0 and not NaN — which is what
   `0 / 0` produces, and what a progress bar then sets its width to. */
function shareOf(course) {
  const of = course.sections || 0;
  if (!of) return 0;
  return Math.min(100, Math.round((doneIn(course) / of) * 100));
}

/* THE THREE STATES A COURSE CAN BE IN, decided in one place. Every screen shows
   this — the dot in the sidebar, the border on the map, the eyebrow on a card —
   and three screens each deciding it from the same two numbers is three chances
   to disagree about what "started" means. */
function stateOf(course) {
  const done = doneIn(course);
  if (course.sections && done >= course.sections) return 'done';
  if (done > 0) return 'current';
  return 'available';
}

/* THE WORDS ARE THE PORTAL'S AND SO ARE THE STATE NAMES. `done`, `current` and
   `available` are what `portal.css` selects on — `.no-current`,
   `[data-state="current"]` — so they are not free to be renamed to something
   this file would have chosen. */
function stateWord(which) {
  if (which === 'done') return txt('completed');
  if (which === 'current') return txt('in progress');
  return txt('available');
}

/* A COURSE'S LEVEL, IN THE READER'S LANGUAGE. `level` is a free string in the
   catalogue rather than a closed set, so this is a map with a fallback and not
   a switch: a level nobody wrote a word for is shown as it was written, which
   is a course card reading `beginner` in a Portuguese sidebar — visible, and
   far better than an empty space where the level was.

   The three keys are literal for the reason `counted` takes translated words:
   `txt(course.level)` translates a variable, which works at runtime and is
   invisible to `tools/check-interface`. It was written that way first, and the
   checker passed on three words that had no Portuguese at all. */
function levelWord(level) {
  return {
    beginner: txt('beginner'),
    intermediate: txt('intermediate'),
    advanced: txt('advanced'),
  }[level] || level;
}

/* A COUNT AND THE THING IT COUNTS, WITH THE RIGHT ENDING ON IT. "1 lessons"
   was on the screen the first time these were drawn, because a number and a
   plural word concatenated is right eleven times out of twelve and wrong on the
   one that says a course has a single lesson.

   IT TAKES THE TWO WORDS ALREADY TRANSLATED, and that is not a style choice.
   `tools/check-interface` finds the strings this interface says by reading the
   source for calls to the translate function — a helper that took the KEYS and
   translated them itself would hide both words from the one check that notices
   a missing translation, and hiding strings from it is how that check quietly
   stops covering whatever somebody added last.

   This paragraph describes the call rather than writing one out, for the same
   reason: a specimen in a comment is indistinguishable from the real thing to a
   tool reading text, and the first draft of this comment added a phantom string
   the checker then demanded a translation for.

   So it is called `counted(n, txt('lesson'), txt('lessons'))`: both keys are
   literal, both are found, and translating both is enforced. Both are needed in
   Portuguese too — `1 seção`, `5 seções`. */
function counted(n, one, many) {
  return `${n} ${n === 1 ? one : many}`;
}

/* `4/50 sections`, the phrase that appears on nearly every screen here. It is
   one function so that the numerator and the denominator can never come from
   different places, which is the way this particular string goes wrong. */
function tally(course) {
  return `${doneIn(course)}/${course.sections || 0} ${txt('sections')}`;
}

/* A bar, with the number it draws said in words for anything that cannot see
   it. A bar with no accessible name is a decoration to a screen reader, and
   this one is carrying the answer to "how far along am I".

   `.bar` / `.bar-fill` and a `<span>`, because that is what the copied
   stylesheet paints and what the portal's own `bar()` emits. This is the piece
   that appears on the most screens, so its shape is the one most worth being
   identical rather than equivalent. */
function bar(share, label) {
  return el('span', {
    class: 'bar',
    role: 'img',
    'aria-label': label || `${share}%`,
  }, [el('span', { class: 'bar-fill', style: `width:${share}%` })]);
}

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

const screen = () => document.querySelector('#content');

/* EVERY SCREEN IS WRAPPED IN `.view`, and that wrapper is not decoration: it
   carries the reading width and the gap between blocks that the copied
   stylesheet puts there. A screen appended straight into `#content` gets
   neither, which reads as that screen having lost its rhythm rather than as a
   missing element.

   A leading string is the screen's own extra class — `screen-course`,
   `view-track` — which is how the portal tells its screens apart. */
function show(...nodes) {
  const extra = typeof nodes[0] === 'string' ? nodes.shift() : '';
  const main = screen();
  main.textContent = '';

  const view = el('div', { class: `view${extra ? ` ${extra}` : ''}` });
  nodes.filter(Boolean).forEach((n) => view.append(n));
  main.append(view);
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
  return el('div', { class: 'cards' }, courses.map(courseCard));
}

/* ONE COURSE CARD, EVERYWHERE, and it is the portal's card down to the order of
   the five lines: state, name, `40h · beginner`, bar, tally. The catalogue, the
   dashboard's next steps and a track's summary all draw it, so three copies
   would be three screens that drift until one of them is the only one still
   saying whether a course is locked. */
function courseCard(course) {
  const which = stateOf(course);

  return el('a', {
    class: `card no-${which}`,
    href: `#/course/${encodeURIComponent(course.id)}`,
  }, [
    /* The state, in words, above the name — read FIRST, because "in progress"
       changes what the name underneath means. `data-state` rather than a class
       of its own: it is what the copied stylesheet colours it by. */
    el('span', {
      class: 'node-state',
      'data-state': which,
      text: course.locked ? txt('subscription') : stateWord(which),
    }),
    el('span', { class: 'card-name', text: course.name }),
    el('span', {
      class: 'card-meta',
      text: [
        course.hours ? `${course.hours}h` : null,
        course.level ? levelWord(course.level) : null,
        /* The free tier is the shop window and is open at every door (N-04), so
           it is said on the card rather than discovered at the paywall. */
        course.free ? txt('free') : null,
      ].filter(Boolean).join(' · '),
    }),
    bar(shareOf(course), `${doneIn(course)} ${txt('of')} ${course.sections || 0}`),
    el('span', { class: 'card-count', text: tally(course) }),
  ]);
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

  const listed = state.courses.find((c) => c.id === course.id);
  const which = listed ? stateOf(listed) : 'available';

  show('screen-course',
    el('header', { class: 'course-head' }, [
      el('span', {
        class: 'node-state',
        'data-state': which,
        text: course.locked ? txt('subscription') : stateWord(which),
      }),
      el('h1', { text: course.name }),
      course.summary ? el('p', { class: 'course-summary', text: course.summary }) : null,
      el('div', { class: 'course-meta' }, [
        course.hours ? el('span', { text: `${course.hours}h` }) : null,
        course.level ? el('span', { text: levelWord(course.level) }) : null,
        el('span', { text: counted((course.lessons || []).length, txt('lesson'), txt('lessons')) }),
      ]),
      state.me && sections.length ? bar(share, `${finished.size} ${txt('of')} ${sections.length}`) : null,
      state.me && sections.length
        ? el('p', {
          class: 'course-count',
          text: `${finished.size}/${sections.length} ${txt('sections completed')}`,
        })
        : null,
    ]),

    course.locked ? el('div', { class: 'notice', role: 'note' }, [
      el('p', { text: txt('This course is part of the subscription.') }),
    ]) : null,

    el('div', { class: 'course-cols' }, [
      el('div', { class: 'course-main' }, [
        el('section', { class: 'block' }, [
          el('div', { class: 'block-top' }, [el('h2', { text: txt('Lessons') })]),
          el('ol', { class: 'lessons' }, (course.lessons || []).map((lesson, i) => {
            const of = lesson.sections.filter((x) => x.countable !== false).length;
            const did = lesson.sections.filter((x) => finished.has(`${lesson.id}/${x.id}`)).length;
            return el('li', {}, [el('a', {
              class: 'lesson-row' + (of && did >= of ? ' done' : ''),
              href: `#/course/${encodeURIComponent(course.id)}/${encodeURIComponent(lesson.id)}`,
            }, [
              el('span', { class: 'lesson-mark', 'aria-hidden': 'true', text: of && did >= of ? '\u2713' : '' }),
              el('span', { class: 'lesson-num', text: String(i + 1).padStart(2, '0') }),
              el('span', { class: 'lesson-tit', text: lesson.title }),
              el('span', {
                class: 'lesson-sections',
                text: counted(lesson.sections.length, txt('section'), txt('sections')),
              }),
              state.me && of ? el('span', { class: 'lesson-prog', text: `${did}/${of}` }) : null,
            ])]);
          })),
        ]),

        course.exam && !course.locked ? examInvite({
          eyebrow: txt('End of the course'),
          title: txt('The exam'),
          facts: txt('Pass it and the certificate is yours.'),
          href: `#/exam/course/${encodeURIComponent(course.id)}`,
          action: txt('Sit the exam'),
        }) : null,
      ]),

      el('aside', { class: 'course-side' }, [
        course.prerequisites ? el('section', { class: 'block' }, [
          el('div', { class: 'block-top' }, [el('h2', { text: txt('Prerequisites') })]),
          el('p', { class: 'prerequisites', text: course.prerequisites }),
        ]) : null,
        (course.requires || []).length ? el('section', { class: 'block' }, [
          el('div', { class: 'block-top' }, [el('h2', { text: txt('After') })]),
          el('div', { class: 'related' }, course.requires.map((need) => {
            const before = state.courses.find((c) => c.id === need);
            return el('a', {
              class: 'link-chip link-before',
              href: `#/course/${encodeURIComponent(need)}`,
              text: before ? before.name : need,
            });
          })),
        ]) : null,
      ]),
    ]),
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

            /* THE COUNT IN THE SIDEBAR IS PART OF THE SAME FACT. Nothing here
               reloads the page — this is a fragment router — so a count read
               once at start-up stays at what it was until somebody presses
               refresh. Marking a section done and watching "4/50" sit there is
               the interface telling somebody their work did not register.

               Counted here rather than re-read from the server: the answer is
               one more than it was, and a request to be told that is a request
               that can fail and leave the number wrong anyway. */
            state.done[courseID] = (state.done[courseID] || 0) + 1;
            drawSidebar(courseID, null);
            drawNavContext();
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
    if (!course) {
      return el('a', {
        class: 'node course-node', 'data-node': node.id,
        href: `#/course/${encodeURIComponent(node.id)}`,
      }, [el('span', { class: 'name', text: node.id })]);
    }

    const which = stateOf(course);
    const of = course.sections || 0;

    /* THE CARD ON THE MAP IS THE PORTAL'S, down to the order of its lines:
       level, state, name, `40h · beginner`, bar, tally. The element around it
       is this repository's — an anchor carrying `.node`, which is what its edge
       router measures and what `tools/graph-test` looks for. */
    return el('a', {
      class: `node course-node node-${which}${course.locked ? ' is-locked' : ''}`,
      'data-node': node.id,
      'data-course': node.id,
      href: `#/course/${encodeURIComponent(node.id)}`,
    }, [
      /* WHICH LEVEL IT IS, counted from the map and not from the catalogue: it
         only means anything in the context of this track, since the same course
         is level two of one and level five of another. */
      el('span', { class: 'order', text: `${txt('level')} ${String(node.level + 1).padStart(2, '0')}` }),
      el('span', {
        class: 'node-state',
        'data-state': which,
        text: course.locked ? txt('subscription') : stateWord(which),
      }),
      el('span', { class: 'name', text: course.name }),
      el('span', {
        class: 'meta',
        text: [
          course.hours ? `${course.hours}h` : null,
          course.level ? levelWord(course.level) : null,
        ].filter(Boolean).join(' · '),
      }),
      of ? el('span', {
        class: 'node-bar',
        role: 'img',
        'aria-label': `${doneIn(course)} ${txt('of')} ${of}`,
      }, [el('span', { class: 'node-bar-fill', style: `width:${shareOf(course)}%` })]) : null,
      of ? el('span', { class: 'node-count', text: tally(course) }) : null,
    ]);
  }

  /* WHAT THE BORDERS MEAN, said in words under the map. Without it the colours
     are a pattern somebody has to guess at, and a guess about which course they
     have finished is the wrong thing to make somebody guess. (WCAG 1.4.1) */
  function key() {
    return el('p', { class: 'graph-legend' }, ['done', 'current', 'available'].map((which) =>
      el('span', { class: `legend-${which}` }, [
        el('span', { class: 'node-state', 'data-state': which, text: stateWord(which) }),
      ])));
  }

  const onIt = coursesOfTrack(track);
  const totalSections = onIt.reduce((n, c) => n + (c.sections || 0), 0);
  const doneSections = onIt.reduce((n, c) => n + doneIn(c), 0);
  const hours = onIt.reduce((n, c) => n + (c.hours || 0), 0);

  show(
    el('h1', { text: track.name }),
    track.goal ? el('p', { class: 'prose', text: track.goal }) : null,

    /* The same block, the same numbers and the same shape as the dashboard's
       summary — `.track-numbers` inside a `.block`, which is what the copied
       stylesheet lays out. Written as its own markup here rather than reusing
       `trackSummary` because this screen shows the hours and the dashboard
       shows the percentage: the reader has already chosen the track, so what is
       worth saying is how much of it there is. */
    el('section', { class: 'block' }, [
      el('div', { class: 'track-numbers' }, [
        el('span', {}, [
          el('b', { text: `${onIt.filter((c) => stateOf(c) === 'done').length}/${onIt.length}` }),
          document.createTextNode(txt('courses on the path')),
        ]),
        hours ? el('span', {}, [
          el('b', { text: `${hours}h` }),
          document.createTextNode(txt('on this path')),
        ]) : null,
        state.me && totalSections ? el('span', {}, [
          el('b', { text: `${doneSections}/${totalSections}` }),
          document.createTextNode(txt('sections')),
        ]) : null,
        track.outcome ? el('span', {}, [
          el('b', { text: '→' }),
          document.createTextNode(track.outcome),
        ]) : null,
      ]),
    ]),

    board,
    key(),
    track.exam ? examInvite({
      eyebrow: txt('End of the track'),
      title: txt('The final'),
      facts: txt('The exam for the whole track.'),
      href: `#/exam/track/${encodeURIComponent(track.id)}`,
      action: txt('Sit the final'),
    }) : null,
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

/* ---------- the two documents ----------

   THEY ARE READABLE BEFORE THERE IS AN ACCOUNT, which is the point of where
   they sit: somebody deciding whether to hand over an e-mail address is exactly
   who needs to read what happens to it. No sign-in, no school, and in the
   offline copy they are baked in like a lesson — a policy that answered "this
   needs the school" would be unpublished for whoever is reading a bundle on a
   train.

   The Markdown goes through the same renderer a lesson uses, so a heading looks
   the same in a policy as in a course and there is one place for it to be
   wrong. */
function legalTitle(document) {
  return document === 'terms' ? txt('Terms of use') : txt('Privacy policy');
}

async function legalPage(document) {
  show(pageTitle(legalTitle(document)));

  let doc;
  try {
    doc = await api.legal(document, contentLocale());
  } catch (e) {
    show(pageTitle(legalTitle(document)), trouble(e));
    return;
  }

  const other = document === 'terms' ? 'privacy' : 'terms';
  show(
    /* The date it took effect is beside the title rather than at the bottom:
       which version somebody is reading is the first thing they need to know
       about a document like this. */
    pageTitle(doc.title, `${txt('In effect since')} ${doc.effective}`),
    el('div', { class: 'prose', html: markdown(doc.body) }),
    el('p', { class: 'legal-other' }, [
      el('a', { class: 'button quiet', href: `#/${other}`, text: legalTitle(other) }),
    ]),
  );
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

/* ---------- drilling ----------

   ONE CARD AT A TIME, and the queue is fetched once. A screen that re-asked
   after every answer would put a round trip between a student and the next
   question, which for a drill — the thing you do twenty of in five minutes —
   is the difference between a habit and a chore.

   THE CLOCK STARTS WHEN THE QUESTION APPEARS AND STOPS WHEN IT IS SENT. It
   decides the quality (A-04), so it has to measure thinking about the question
   rather than the round trip that fetched it.

   AND IT SAYS WHAT IT IS FOR. A queue with a number on it and no explanation is
   a chore somebody is being set; the point is that these are the things they
   are about to forget. */
async function practice() {
  if (!state.me) { go('#/sign-in'); return; }
  if (offline) { show(pageTitle(txt('Practice')), onlyTheSchoolCanDoThat()); return; }

  show(pageTitle(txt('Practice'), txt('The questions you are closest to forgetting.')));

  let queue = [];
  try {
    const answer = await api.practice();
    queue = (answer && answer.cards) || [];
  } catch (e) {
    show(pageTitle(txt('Practice')), trouble(e));
    return;
  }

  if (!queue.length) {
    show(
      pageTitle(txt('Practice'), txt('The questions you are closest to forgetting.')),
      el('div', { class: 'notice', role: 'status' }, [
        el('p', { text: txt('Nothing is due. Come back tomorrow.') }),
        el('p', { class: 'dim', text: txt('A question comes back when you are about to forget it, not on a timetable.') }),
      ]),
    );
    return;
  }

  let at = 0;
  const board = el('div', {});

  /* The count is drawn once and updated in place rather than being part of the
     card, so that moving to the next question does not rebuild the heading —
     which would move focus and lose the place of somebody using a screen
     reader. */
  const counter = el('p', { class: 'dim', 'aria-live': 'polite' });
  const say = () => { counter.textContent = `${at + 1} / ${queue.length}`; };

  show(
    pageTitle(txt('Practice'), txt('The questions you are closest to forgetting.')),
    counter, board,
  );

  async function draw() {
    say();
    board.textContent = '';
    board.append(el('p', { class: 'dim', text: txt('Loading…') }));

    let card;
    try {
      card = await api.drawCard(queue[at].exercise);
    } catch (e) {
      board.textContent = '';
      board.append(trouble(e));
      return;
    }

    if (!answerable(card.type)) {
      /* A type this interface cannot draw is skipped rather than shown as an
         error: the student did nothing, and a queue that stopped at one would
         be a queue nobody could finish. */
      next();
      return;
    }

    const name = `drill-${card.exercise}`;
    const built = build(card.type, card.question, name, null,
      (file) => asset(`/api/v1/courses/${encodeURIComponent(card.course)}/images/${encodeURIComponent(file)}`));

    const started = Date.now();
    const why = el('p', { class: 'why', role: 'alert' });
    const verdict = el('div', {});

    const send = el('button', {
      class: 'button', type: 'submit', text: txt('Answer'),
    });

    const form = el('form', { class: 'paper' }, [built.node, why, el('div', {}, [send]), verdict]);

    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      why.textContent = '';

      const answer = built.read();
      if (!answer) {
        why.textContent = txt('Answer it first.');
        return;
      }

      send.disabled = true;
      let marked;
      try {
        marked = await api.answerCard(card.exercise, answer, Date.now() - started);
      } catch (e) {
        send.disabled = false;
        why.textContent = (e instanceof ApiError && e.message) ? txt(e.message) : txt('That did not work.');
        return;
      }

      send.hidden = true;
      verdict.append(el('div', { class: `notice ${marked.correct ? '' : 'bad'}`, role: 'status' }, [
        el('p', { class: 'verdict', text: marked.correct ? txt('Right') : txt('Wrong') }),
        /* The question's own words for why, never this file's: a client that
           wrote its own feedback would be writing content. */
        marked.why ? el('p', { text: marked.why }) : null,
        el('p', {
          class: 'dim',
          text: `${txt('Back in')} ${marked.interval_days} ${marked.interval_days === 1 ? txt('day') : txt('days')}`,
        }),
      ]));

      const onwards = el('button', {
        class: 'button', type: 'button',
        text: at + 1 < queue.length ? txt('Next question') : txt('Done'),
        onclick: () => next(),
      });
      verdict.append(el('div', {}, [onwards]));
      onwards.focus();
    });

    board.textContent = '';
    board.append(form);
  }

  function next() {
    at += 1;
    if (at >= queue.length) {
      board.textContent = '';
      counter.textContent = '';
      board.append(el('div', { class: 'notice', role: 'status' }, [
        el('p', { text: txt('That is everything due today.') }),
        el('p', {}, [el('a', { class: 'button quiet', href: '#/', text: txt('Back to the courses') })]),
      ]));
      return;
    }
    draw();
  }

  await draw();
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

  /* The pointer carries ids and the card shows words. One request, for the one
     course it points at — see `titlesFor`, which the notes screen uses for the
     same reason. */
  const resumeTitles = resume.length ? await titlesFor([resume[0].course]) : {};
  const track = state.tracks[0];

  show(
    /* THE GREETING IS THE HEADING. It is the one screen that is about the
       person rather than about the school, and "Your study" over somebody's own
       dashboard is a filing-cabinet label. */
    el('h1', { text: state.me.name ? `${txt('Hello')}, ${state.me.name}` : txt('Your study') }),

    /* ONE PLACE TO CARRY ON FROM, AND NOT A GRID OF THEM. A dashboard whose
       first element is a choice of six is a dashboard that asks a question
       instead of answering one — the most recent is what "carry on" means. */
    resume.length ? carryOn(resume[0], resumeTitles[resume[0].course]) : el('div', { class: 'panel' }, [
      el('p', { class: 'eyebrow', text: txt('Start here') }),
      el('h2', { text: txt('You have not started anything yet.') }),
      el('p', { class: 'dim', text: txt('What there is to learn here.') }),
      el('p', {}, [el('a', { class: 'button', href: '#/', text: `${txt('Catalogue')} →` })]),
    ]),

    track ? trackSummary(track) : null,
    nextSteps(),

    /* An open attempt first, because it is the only thing on this screen with
       a deadline attached to it — the paper is drawn and waiting. */
    attempts.length ? el('div', { class: 'panel' }, [
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

/* The last card on a course and on a track. One shape, because they are the
   same offer made about different amounts of material — and a signed-out
   visitor gets the same card with the door named rather than no card at all,
   since "there is an exam and you need an account for it" is information and a
   missing element is not. */
function examInvite({ eyebrow, title, facts, href, action }) {
  return el('div', { class: 'exam-invite' }, [
    el('div', {}, [
      el('p', { class: 'eyebrow quiet', text: eyebrow }),
      el('h2', { text: title }),
      el('p', { class: 'facts' }, [el('span', { text: facts })]),
    ]),
    state.me
      ? el('a', { class: 'button', href, text: `${action} →` })
      : el('a', {
        class: 'button quiet',
        href: '#/sign-in',
        text: offline ? txt('The exam needs the school') : txt('Sign in to sit it'),
      }),
  ]);
}

/* The one thing this screen exists to offer: the way back in.
   The course and the lesson are named because "carry on" with nothing after it
   asks somebody to remember what they were doing. */
function carryOn(where, named = { lessons: {}, sections: {} }) {
  const course = state.courses.find((c) => c.id === where.course);
  const share = course ? shareOf(course) : 0;
  const lesson = named.lessons[where.lesson] || where.lesson;
  const section = named.sections[`${where.lesson}/${where.section}`] || where.section;

  return el('a', {
    class: 'resume',
    href: `#/course/${encodeURIComponent(where.course)}/${encodeURIComponent(where.lesson)}`,
  }, [
    el('span', { class: 'resume-label', text: txt('pick up where you left off') }),
    /* THE BIG LINE IS THE SECTION AND THE SMALL ONE IS WHERE IT SITS. Sending
       somebody back to the top of a four-hour course is sending them back to
       scrolling; the section is the place they actually stopped. */
    el('span', { class: 'resume-lesson', text: section || lesson }),
    el('span', {
      class: 'resume-course',
      text: `${course ? course.name : where.course} · ${lesson}`,
    }),
    course ? bar(share, `${doneIn(course)} ${txt('of')} ${course.sections || 0}`) : null,
    el('span', { class: 'resume-btn btn btn-primary', text: `${txt('Continue')} →` }),
  ]);
}

/* The track, counted. Four numbers and a bar: how much of it is done, how many
   sections that is, how many courses are on it and what it leads to. */
function trackSummary(track) {
  const courses = coursesOfTrack(track);
  const of = courses.reduce((n, c) => n + (c.sections || 0), 0);
  const done = courses.reduce((n, c) => n + doneIn(c), 0);
  const share = of ? Math.round((done / of) * 100) : 0;

  return el('section', { class: 'block' }, [
    el('div', { class: 'block-top' }, [
      el('h2', { text: track.name }),
      el('a', {
        class: 'block-link',
        href: `#/track/${encodeURIComponent(track.id)}`,
        text: `${txt('see the map')} →`,
      }),
    ]),
    el('div', { class: 'track-numbers' }, [
      el('span', {}, [el('b', { text: `${share}%` }), document.createTextNode(txt(' of the track'))]),
      el('span', {}, [el('b', { text: `${done}/${of}` }), document.createTextNode(txt('sections'))]),
      el('span', {}, [
        el('b', { text: String(courses.length) }),
        document.createTextNode(txt('courses on the path')),
      ]),
      track.outcome
        ? el('span', {}, [el('b', { text: '→' }), document.createTextNode(track.outcome)])
        : null,
    ]),
    bar(share, `${share}%`),
  ]);
}

/* WHAT TO DO NEXT, which is a different question from what is unfinished.
   Something already started comes before something not started — finishing a
   course is worth more than opening a fifth one — and a locked course is not
   here at all, because a list of next steps that leads to a paywall is an
   advert wearing a checklist's clothes. */
function nextSteps() {
  const open = state.courses.filter((c) => !c.locked);
  const current = open.filter((c) => stateOf(c) === 'current');
  const fresh = open.filter((c) => stateOf(c) === 'available');
  const next = [...current, ...fresh].slice(0, 4);
  if (!next.length) return null;

  return el('section', { class: 'block' }, [
    el('div', { class: 'block-top' }, [el('h2', { text: txt('Next steps') })]),
    el('div', { class: 'cards' }, next.map(courseCard)),
  ]);
}

/* EVERYTHING SOMEBODY WROTE, IN ONE PLACE. A margin note is written inside one
   section and read back weeks later with no memory of which section that was,
   so each one carries the way back to the page it belongs to. */
/* The lesson and section titles of some courses, keyed by id.
   A course that fails to load is simply absent from the answer — the caller
   falls back to the id, and one course being unreachable must not take a whole
   screen of somebody's notes down with it. */
async function titlesFor(courseIDs) {
  const pairs = await Promise.all(courseIDs.map(async (id) => {
    try {
      const course = await api.course(id);
      const lessons = {};
      const sections = {};
      (course.lessons || []).forEach((lesson) => {
        lessons[lesson.id] = lesson.title || lesson.id;
        (lesson.sections || []).forEach((section) => {
          /* Keyed by BOTH ids: section ids are unique within a lesson and not
             within a course, so `roles` in two lessons is two sections and a
             map keyed on the section alone would show one of them under the
             other's title. */
          sections[`${lesson.id}/${section.id}`] = section.title || section.id;
        });
      });
      return [id, { lessons, sections }];
    } catch (e) {
      return null;
    }
  }));

  return Object.fromEntries(pairs.filter(Boolean));
}

async function notesPage() {
  if (!state.me) { go('#/sign-in'); return; }

  let notes = [];
  try {
    const answer = await api.allNotes();
    notes = (answer && answer.notes) || [];
  } catch (e) {
    show(pageTitle(txt('Your notes')), trouble(e));
    return;
  }

  /* WHERE THE NOTE WAS WRITTEN, IN WORDS. The rows carry ids — `roles`,
     `client-and-server` — because that is what a note is keyed by, and a screen
     showing somebody their own writing under two slugs asks them to remember
     what those slugs meant.

     One request per COURSE that has a note in it, asked for together, rather
     than one per note. A course whose titles cannot be fetched falls back to
     the ids: a slug is worse than a title and much better than a blank. */
  const titles = await titlesFor([...new Set(notes.map((n) => n.course))]);

  /* GROUPED BY COURSE, which is how somebody looks for a note — "the thing I
     wrote in HTML and CSS" — rather than by the day they wrote it. The stream
     arrives newest first and the grouping keeps that order between the groups,
     so the course somebody wrote in last is the one at the top. */
  const byCourse = new Map();
  notes.forEach((note) => {
    if (!byCourse.has(note.course)) byCourse.set(note.course, []);
    byCourse.get(note.course).push(note);
  });

  show('screen-notes',
    el('header', { class: 'view-head' }, [
      el('h1', { text: txt('Your notes') }),
      el('p', { text: counted(notes.length, txt('note'), txt('notes')) }),
    ]),

    ...[...byCourse.entries()].map(([courseID, ofCourse]) => {
      const course = state.courses.find((c) => c.id === courseID);
      const named = titles[courseID] || { lessons: {}, sections: {} };

      return el('section', { class: 'block' }, [
        el('div', { class: 'block-top' }, [
          el('h2', { text: course ? course.name : courseID }),
          el('a', {
            class: 'block-link',
            href: `#/course/${encodeURIComponent(courseID)}`,
            text: `${txt('open the course')} →`,
          }),
        ]),
        ...ofCourse.map((note) => el('article', { class: 'note-item' }, [
          el('a', {
            class: 'note-where',
            href: `#/course/${encodeURIComponent(courseID)}/${encodeURIComponent(note.lesson)}`,
            text: `${named.lessons[note.lesson] || note.lesson} · `
              + `${named.sections[`${note.lesson}/${note.section}`] || note.section} →`,
          }),
          /* The note is the student's own words and is never Markdown: it goes
             in as text, which is also why nothing here touches innerHTML. */
          el('p', { class: 'note-text', text: note.body }),
        ])),
      ]);
    }),
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
        el('div', { class: 'certificate-head' }, [
          el('span', { class: 'brand' }, [
            el('span', { class: 'brand-mark', 'aria-hidden': 'true' }),
            el('span', { class: 'brand-name', text: c.school }),
          ]),
          el('span', { class: 'chip on', text: txt('Genuine') }),
        ]),
        el('p', { class: 'said', text: txt('certifies that') }),
        el('p', { class: 'who', text: c.name }),
        el('p', { class: 'said', text: txt('completed') }),
        el('p', { class: 'what', text: c.title }),
        el('div', { class: 'foot' }, [
          el('span', { class: 'said', text: new Date(c.issued_at).toLocaleDateString() }),
          el('span', { class: 'code', text: answer.code_as_printed || grouped(c.code) }),
        ]),
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
        /* Their counts arrive with them, so the dashboard behind this form is
           drawn with the progress it is about rather than filling in a beat
           later under the cursor. */
        await loadProgress();
        drawNavContext();
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

/* WHERE YOU CAN GO, on every screen. Six entries, the same six always, and
   written here rather than derived from the router: the router knows thirteen
   routes and most of them are somewhere you arrive rather than somewhere you
   choose to go — a lesson, an exam paper, a result.

   The ones that need an account are marked, because a sidebar offering "Your
   certificates" to somebody who is not signed in is a list of disappointments.
   The catalogue is not marked, and that is the point of it. */
/* THE LABELS ARE TRANSLATED HERE, AT THE LITERAL. Writing them as data —
   `label: 'Your track'` — and translating the variable later works, and it
   hides all six from `tools/check-interface`, which reads the source for calls
   to the translator rather than running the page. The first draft did exactly
   that and put `Your track` in the middle of an otherwise Portuguese sidebar;
   the checker reported nothing, because as far as it could see nobody said it.

   A key that reaches the translator through a variable is a key nothing can
   check. */
function places() {
  const track = state.tracks[0];
  return [
    { hash: '#/dashboard', label: txt('Your study'), account: true },
    /* "Your track" is a link to A track, and which one is a fact about the
       school rather than about the student until there is a choice to record.
       Absent when the school has none, rather than pointing at nothing. */
    track
      ? { hash: `#/track/${encodeURIComponent(track.id)}`, label: txt('Your track') }
      : null,
    { hash: '#/', label: txt('Catalogue') },
    { hash: '#/practice', label: txt('Practice'), account: true },
    { hash: '#/notes', label: txt('Your notes'), account: true },
    { hash: '#/certificates', label: txt('Your certificates'), account: true },
  ].filter(Boolean);
}

function drawSidebar(current, where) {
  const rail = document.querySelector('#rail');
  rail.textContent = '';
  rail.setAttribute('aria-label', txt('Navigation'));

  rail.append(el('nav', { class: 'rail-nav' },
    places()
      .filter((place) => state.me || !place.account)
      .map((place) => el('a', {
        class: 'rail-link' + (place.hash === where ? ' on' : ''),
        href: place.hash,
        text: place.label,
        /* THE CLASS IS THE PAINT AND `aria-current` IS THE FACT. `.on` is what
           the copied stylesheet colours; a screen reader is told which link is
           the current page by the attribute, which no stylesheet can express.
           The portal's rail sets only the class, and that is the one thing here
           that deliberately does more than the copy. */
        'aria-current': place.hash === where ? 'page' : null,
      }))));

  const courses = filtered(state.courses);
  if (!courses.length) {
    rail.append(el('p', { class: 'dim', text: txt('Nothing here yet.') }));
    return;
  }

  /* The heading over the list is the TRACK's name when there is one, and the
     word "Courses" when there is not. A student is on one path through the
     school and the list under it is that path; naming it is what turns a
     column of twelve courses into a shape somebody recognises. */
  const track = state.tracks[0];

  rail.append(el('div', { class: 'rail-sec' }, [
    el('span', { class: 'rail-tit', text: track ? track.name : txt('Courses') }),
    el('div', { class: 'rail-courses' }, courses.map((course) => {
      const which = stateOf(course);

      return el('a', {
        class: `rail-course no-${which}`,
        href: `#/course/${encodeURIComponent(course.id)}`,
        'aria-current': current === course.id ? 'page' : null,
      }, [
        /* The mark is a picture of what the count beside it already says, so it
           is hidden from anything that reads the page rather than announced
           twice. What a screen reader gets is the name and the tally.

           `data-state` and not a class, because that is what the copied
           stylesheet selects on. */
        el('span', { class: 'tc-mark', 'data-state': which, 'aria-hidden': 'true' }),
        el('span', { class: 'tc-name', text: course.name }),

        /* Said here as well as on the card, because this is the list somebody
           navigates from: a link that leads to a paywall should look like one
           BEFORE it is clicked. The word rather than a glyph — a padlock is a
           picture a screen reader has to be told the meaning of, and the meaning
           is one short word. */
        course.locked
          ? el('span', { class: 'tc-count', text: txt('Subscription') })
          : el('span', { class: 'tc-count', text: `${doneIn(course)}/${course.sections || 0}` }),
      ]);
    })),
  ]));
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
    case 'practice':           await practice(); break;
    case 'dashboard':          await dashboard(); break;
    case 'notes':              await notesPage(); break;
    case 'certificates':       await certificates(); break;
    case 'sign-in':            signIn(); break;
    case 'sign-up':            signUp(); break;
    case 'terms':              await legalPage('terms'); break;
    case 'privacy':            await legalPage('privacy'); break;
    default:
      await notFound();
  }

  /* The sidebar is told BOTH which course is open and which of the six places
     this is, because they mark different lists and a screen is usually in one
     of them and not the other. A lesson is inside a course, so the course is
     what is marked there — `#/course/x/y` and `#/course/x` are the same place
     as far as somebody looking at the list is concerned. */
  drawSidebar(parts[0] === 'course' ? parts[1] : null, placeOf(parts));
  closeSidebar();
  focusScreen();
}

/* Which of the sidebar's six the address is on, or null for a screen that is
   none of them — a lesson, an exam, a result. Built from the parts rather than
   compared against `location.hash`, so that a track reached from the catalogue
   and the same track reached from the sidebar mark the same entry. */
function placeOf(parts) {
  if (!parts.length) return '#/';
  if (parts[0] === 'track' && parts[1]) return `#/track/${encodeURIComponent(parts[1])}`;
  if (['dashboard', 'practice', 'notes', 'certificates'].includes(parts[0])) return `#/${parts[0]}`;
  return null;
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
  /* Defined in wireChrome, where the veil and the button it belongs to are.
     Guarded because the router runs once before the chrome is wired — the first
     screen is drawn as part of start(), and a drawer nobody has opened yet does
     not need closing. */
  if (window.__closeRail) window.__closeRail();
}

function wireChrome() {
  /* The rail becomes a drawer below the cut, and the veil behind it is both the
     dimming and the way out: a drawer that can only be closed by the same small
     button that opened it is a drawer people leave open. */
  const rail = document.querySelector('#rail');
  const veil = document.querySelector('#rail-veil');
  const railButton = document.querySelector('#rail-btn');

  const closeRail = () => {
    document.body.classList.remove('rail-open');
    veil.hidden = true;
    railButton.setAttribute('aria-expanded', 'false');
  };
  window.__closeRail = closeRail;

  railButton.addEventListener('click', () => {
    const open = document.body.classList.toggle('rail-open');
    veil.hidden = !open;
    railButton.setAttribute('aria-expanded', String(open));
  });
  veil.addEventListener('click', closeRail);
  rail.addEventListener('click', (event) => { if (event.target.closest('a')) closeRail(); });

  document.querySelector('#theme-btn').addEventListener('click', () => {
    const root = document.documentElement;
    const next = root.dataset.theme === 'light' ? 'dark' : 'light';
    root.dataset.theme = next;
    try { localStorage.setItem('codeschool-theme', next); } catch (e) { /* private mode */ }
  });

  /* The two menus, one behaviour: a click opens, a click anywhere else closes,
     and Escape closes — the last of which is the one everybody forgets and the
     one a keyboard user needs to get out without tabbing through the menu. */
  const menus = () => [...document.querySelectorAll('#lang, #account, .ctx-box')];
  const closeMenus = () => menus().forEach((m) => {
    m.classList.remove('is-open');
    m.querySelector('button[aria-haspopup]')?.setAttribute('aria-expanded', 'false');
  });

  document.addEventListener('click', (event) => {
    const trigger = event.target.closest('.lang-btn, .account-btn, .ctx');
    if (trigger) {
      const box = trigger.closest('#lang, #account, .ctx-box');
      const open = !box.classList.contains('is-open');
      closeMenus();
      box.classList.toggle('is-open', open);
      trigger.setAttribute('aria-expanded', String(open));
      if (open) closeRail();
      return;
    }
    /* A click on something INSIDE a menu closes it and lets the click through —
       every entry is a link or a button that does its own work. */
    closeMenus();
  });

  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    document.querySelectorAll('.is-open button[aria-haspopup]').forEach((b) => b.focus());
    closeMenus();
    closeRail();
  });

  /* Search is a field that is not there until it is asked for. A permanent
     input is most of the width of a phone spent on something people use
     rarely — and the icon is a real button with a real name on it, so nothing
     is hidden from anybody navigating by keyboard or by screen reader. */
  const searchButton = document.querySelector('#search-btn');
  searchButton.addEventListener('click', () => {
    const open = !document.body.classList.contains('search-open');
    document.body.classList.toggle('search-open', open);
    searchButton.setAttribute('aria-expanded', String(open));

    if (open) {
      document.querySelector('#search-input').focus();
      return;
    }
    /* Closing it clears the query, because a hidden field that is still
       filtering the catalogue is a school that has lost half its courses with
       nothing on screen saying why. */
    document.querySelector('#search-input').value = '';
    state.query = '';
    drawSidebar();
    route();
  });

  document.querySelector('#search').addEventListener('submit', (e) => e.preventDefault());
  document.querySelector('#search-input').addEventListener('input', (event) => {
    state.query = event.target.value;
    drawSidebar();
    if (!location.hash || location.hash === '#/' || location.hash === '#') catalogue();
  });

  document.querySelector('#account-menu').addEventListener('click', async (event) => {
    if (!event.target.closest('#account-signout')) return;
    try { await api.signOut(); } catch (e) { /* the cookie may already be gone */ }
    state.me = null;
    drawAccount();
    /* Their counts go with them. A rail still showing "12/50" after somebody
       signed out is one person's progress shown to whoever is at the machine
       next. */
    await loadProgress();
    drawNavContext();
    go('#/');
  });
}


function drawAccount() {
  const link = document.querySelector('#sign-in-link');
  const account = document.querySelector('#account');
  const menu = document.querySelector('#account-menu');

  /* No door where there is no room behind it. The offline copy keeps the
     sign-in SCREEN — a bookmark or an old link still lands there and gets an
     explanation — but it does not put a button in the chrome inviting somebody
     to try. */
  if (offline) {
    link.hidden = true;
    account.hidden = true;
    return;
  }

  if (!state.me) {
    link.hidden = false;
    account.hidden = true;
    return;
  }

  const who = state.me.name || state.me.email;
  link.hidden = true;
  account.hidden = false;

  /* The circle carries one letter and the name is beside it in the accessible
     name. `[...who][0]` and not `who[0]`: a name beginning with an emoji or an
     astral character is one code point and two code units, and indexing by code
     unit cuts it in half. */
  document.querySelector('#account-avatar').textContent = who ? [...who][0].toUpperCase() : '·';
  document.querySelector('#account-name').textContent = who;

  menu.textContent = '';
  menu.append(
    el('a', { class: 'account-op', href: '#/dashboard', text: txt('Your study') }),
    el('a', { class: 'account-op', href: '#/certificates', text: txt('Your certificates') }),
    el('button', {
      type: 'button', class: 'account-op account-op-btn', id: 'account-signout',
      text: txt('Sign out'),
    }),
  );
}

/* WHAT THE STUDENT IS IN THE MIDDLE OF, in the bar, on every screen. It is the
   one piece of state worth carrying everywhere: a track is months long, and a
   platform that only shows how far along somebody is on the screen about it
   asks them to go and look.

   IN THE PORTAL THIS IS A SELECTOR and here it is a list of links. Over there
   the student is enrolled in one track and the menu switches which; nothing
   here records an enrolment, so a control that looked like it changed something
   would be a promise this side cannot keep. The menu goes to the maps instead.

   Empty rather than zeroed when nobody is signed in: a chip reading 0% is a
   statement about somebody's effort, and "we do not know yet" is not that
   statement. */
function drawNavContext() {
  const box = document.querySelector('#nav-context');
  box.textContent = '';

  const track = state.tracks[0];
  if (!state.me || !track) return;

  const courses = coursesOfTrack(track);
  const of = courses.reduce((n, c) => n + (c.sections || 0), 0);
  const done = courses.reduce((n, c) => n + doneIn(c), 0);
  const share = of ? Math.round((done / of) * 100) : 0;

  box.append(el('div', { class: 'ctx-box' }, [
    el('button', { type: 'button', class: 'ctx', 'aria-haspopup': 'true', 'aria-expanded': 'false' }, [
      el('span', { class: 'ctx-name', text: track.name }),
      el('span', { class: 'ctx-bar' }, [el('span', { style: `width:${share}%` })]),
      el('span', { class: 'ctx-pct', text: `${share}%` }),
      el('span', { class: 'ctx-arrow', 'aria-hidden': 'true', text: '▾' }),
    ]),
    el('div', { class: 'ctx-menu', role: 'menu' }, [
      el('a', {
        class: 'ctx-op ctx-map',
        href: `#/track/${encodeURIComponent(track.id)}`,
        text: `${txt('see the track map')} →`,
      }),
      ...state.tracks.map((other) => el('a', {
        class: `ctx-op${other.id === track.id ? ' on' : ''}`,
        href: `#/track/${encodeURIComponent(other.id)}`,
        text: other.name,
      })),
    ]),
  ]));
}

async function loadMe() {
  try {
    state.me = await api.me();
  } catch (e) {
    state.me = null;   // not signed in, which is half of this platform's traffic
  }
  drawAccount();
}

/* How far along, in every course, in one request.
   A visitor has no progress and is not asked for any — the endpoint would
   refuse, and a 401 on every page load is noise in a log that somebody will
   one day be reading to find a real one. */
async function loadProgress() {
  state.done = {};
  if (!state.me) return;

  try {
    const answer = await api.summary();
    ((answer && answer.progress) || []).forEach((row) => {
      state.done[row.course] = row.sections;
    });
  } catch (e) { /* the counts are missing; every screen still works without them */ }
}

/* What the student is in the middle of, in the bar, on every screen.
   Hidden rather than zeroed when there is no track or nobody signed in: a chip
   reading 0% is a statement about somebody's effort, and "we do not know yet"

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

  /* THE CATALOGUE AND THE TRACKS TOGETHER, before the first screen. Both are
     read by the sidebar, which is drawn on every navigation — fetching them
     per screen would be the same two requests over and over, and a sidebar
     that filled in a beat late on each one.

     Neither takes the screen down: every screen below reports its own trouble,
     and a sidebar with nothing in it is a worse day rather than a broken
     page. */
  await Promise.all([
    api.courses().then((answer) => { state.courses = (answer && answer.courses) || []; })
      .catch(() => {}),
    api.tracks().then((answer) => { state.tracks = (answer && answer.tracks) || []; })
      .catch(() => {}),
  ]);

  await loadProgress();
  drawNavContext();

  window.addEventListener('hashchange', route);
  await route();
}

/* Exposed for the interface-string checker, which drives a real browser and
   asks the page which of its own sentences have no translation. It is the
   runtime's own answer rather than a second implementation that could disagree
   with it about what counts as a string. */
window.__missingTranslations = missingTranslations;

start();
