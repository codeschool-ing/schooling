-- A school for the browser suites to look at, until there is content instead.
--
-- THE TEST NEEDS SOMETHING NON-TRIVIAL OR IT PROVES NOTHING. A straight line of
-- courses is routed correctly by a version of the router with the detour ripped
-- out — the case that separates a working router from a broken one is a line
-- that has to get PAST something, and that needs a fork block beside the path
-- and a level a shortcut skips.
--
-- So this is not a minimal fixture. It is the smallest one where the answer is
-- not the same either way, which was checked by removing the detour and
-- watching eight lines run through cards.
--
-- It goes away when `content/` has a school in it: the suites read whatever the
-- API offers, and real content is strictly better than this.
--
-- IT TAKES ITS SCHOOL AS A PARAMETER, because two callers want it under two
-- names: the browser suites want `graphtest` at `code.example.tld`, and
-- `docker compose` wants `code` at `code.localhost` so that somebody can open
-- the thing in a browser. One fixture with a variable beats two files that
-- drift apart, and a default would be a caller forgetting to pass it and
-- seeding the wrong school silently.
--
--     psql ... -v slug=graphtest -v host=code.example.tld -f fixture.sql
--
-- THE ACCESSIBILITY PASS NEEDS MORE THAN THE GRAPH DOES. It opens a lesson and
-- an exam paper, and a screen with nothing on it is a screen that passes
-- without being checked — so the lesson prose and one question of every
-- answerable type are here too. The exam is the densest screen in the
-- interface: six questions, every one of them a control with a label.

/* A SCHOOL THAT IS NOT CODESCHOOL.ING IN ANY OF ITS DETAILS, deliberately.
   Everything the interface used to have written into it is set here to
   something else, so that a value which crept back in is visible rather than
   correct by coincidence.

   The accent is green and not the palette's blue, which is what puts
   `ui/app/accent.js` under the accessibility pass: axe reads every screen in
   both themes, so an accent applied unreadably fails there. It cannot pass at
   this value on both pages — no colour can, see that file — so the light theme
   exercises the correction and the dark one exercises the plain application.

   The site and the price are set for the same reason: the account menu's link
   and the invitation's amount were a competitor's address and one school's
   `R$ 490` until they came from here. */
INSERT INTO tenants (slug, name, accent, site, plan_price_cents, plan_currency)
VALUES (:'slug', 'Programming', '#14a06a', 'https://example.tld', 32000, 'EUR')
ON CONFLICT (slug) DO UPDATE SET
  accent = EXCLUDED.accent, site = EXCLUDED.site,
  plan_price_cents = EXCLUDED.plan_price_cents,
  plan_currency = EXCLUDED.plan_currency;

INSERT INTO tenant_domains (host, tenant_id)
SELECT :'host', id FROM tenants WHERE slug = :'slug'
ON CONFLICT (host) DO UPDATE SET tenant_id = EXCLUDED.tenant_id;

INSERT INTO catalog_courses (tenant_id, id, name, category, level, hours, summary)
SELECT t.id, v.cid, v.name, 'Front-end', 'beginner', v.hours, v.summary
FROM tenants t, (VALUES
  ('web-fundamentals', 'Web Fundamentals',   40, 'How a browser and a server talk.'),
  ('html-css',         'HTML & CSS',         60, 'Structure and appearance.'),
  ('javascript',       'JavaScript',         60, 'The language of the browser.'),
  ('react-ts',         'React + TypeScript', 80, 'Components and the state between them.'),
  ('angular',          'Angular',            80, 'The other one.'),
  ('testing',          'Testing',            40, 'What to check.'),
  ('deploy',           'Shipping it',        30, 'From your machine to somebody else''s.')
) AS v(cid, name, hours, summary)
WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_course_requires (tenant_id, course_id, requires_id)
SELECT t.id, v.c, v.r FROM tenants t, (VALUES
  ('html-css',   'web-fundamentals'),
  ('javascript', 'html-css'),
  ('react-ts',   'javascript'),
  ('angular',    'javascript'),
  -- `testing` needs javascript and NOT the framework, so its arrow skips the
  -- fork's level and has to get past the fork block to arrive. That edge is the
  -- one this whole fixture exists for.
  ('testing',    'javascript'),
  ('deploy',     'testing')
) AS v(c, r)
WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_tracks (tenant_id, id, name, goal, outcome, position)
SELECT id, 'frontend', 'Front-end Development',
       'Build and ship an interface that other people use.',
       'Junior Front-end Developer', 0
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_track_forks (tenant_id, track_id, position, choice, note)
SELECT id, 'frontend', 3, 'the framework', 'Either one; the ideas transfer.'
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_track_courses (tenant_id, track_id, position, course_id)
SELECT t.id, 'frontend', v.p, v.c FROM tenants t, (VALUES
  (0, 'web-fundamentals'), (1, 'html-css'), (2, 'javascript'), (4, 'testing'), (5, 'deploy')
) AS v(p, c)
WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_track_courses
  (tenant_id, track_id, position, option_name, option_position, course_position, course_id)
SELECT t.id, 'frontend', 3, v.o, v.op, 0, v.c FROM tenants t, (VALUES
  ('React + TypeScript', 0, 'react-ts'),
  ('Angular',            1, 'angular')
) AS v(o, op, c)
WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;

/* AND ONE EDGE THAT NO PREREQUISITE PRODUCES.

   `deploy` requires `testing` and nothing else: what to check is knowledge, and
   a course about shipping does not need React to be understood. In THIS track
   it still comes after the fork — you ship the thing you built — and that is a
   property of the track rather than of the course, which is the whole of why
   `catalog_track_links` exists.

   It is here rather than only in the unit tests because it is an edge that has
   to be DRAWN: from the fork at level three, past the `testing` card, down to
   `deploy`. A link that survives the database and then routes through a card is
   still a bug, and this is the suite that can see it.

   The other target shape — a course id rather than a step number — is covered
   by `internal/catalog`'s own fixture; there is no honest place for one here,
   and a redundant link written only to exercise a column would be a fixture
   lying about what a track says. */
INSERT INTO catalog_track_links
  (tenant_id, track_id, course_id, position, target_step)
SELECT id, 'frontend', 'deploy', 0, 3
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

/* ---------- a lesson to read ---------- */

/* A COURSE HAS TO NAME ITS TOPICS, and a lesson is a topic somebody wrote.

   The interface builds a course's lessons from its topics, so a lesson row the
   course does not list is a lesson no screen can reach: it falls back to the
   placeholder a course nobody has written yet is drawn with. This fixture
   seeded the row and not the topic, and the bundle reported all seven courses
   as unwritten while the screen the accessibility pass calls "a lesson" was a
   placeholder that passed happily.

   IT WAS PATCHED HERE BY MAKING TWO STRINGS EQUAL — an `UPDATE ... SET topics =
   ARRAY['Client and server']` beside a lesson titled `Client and server` — and
   that patch is the whole argument for `catalog_course_topics`. The join was
   the title text, so keeping it working meant keeping two sentences identical
   in two places by hand. It is an id now, and the title beside it is free. */
INSERT INTO catalog_course_topics (tenant_id, course_id, position, topic_id, title)
SELECT id, 'web-fundamentals', 0, 't-4mzk8p2r', 'Client and server'
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_lessons (tenant_id, course_id, id, title, position)
SELECT id, 'web-fundamentals', 't-4mzk8p2r', 'Client and server', 0
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_sections (tenant_id, course_id, lesson_id, id, kind, position)
SELECT id, 'web-fundamentals', 't-4mzk8p2r', 'roles', 'reading', 0
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_prose (tenant_id, course_id, lesson_id, section_id, locale, title, body)
SELECT id, 'web-fundamentals', 't-4mzk8p2r', 'roles', 'en', 'The two roles',
$prose$The words **client** and **server** name a moment, not a machine.

Whoever asks is the client. Whoever answers is the server.

- the browser asks
- the server answers

```
browser -> server -> database
```
$prose$
FROM tenants WHERE slug = :'slug'
ON CONFLICT DO NOTHING;

/* ---------- an exam to sit ----------

   One question of every type the interface can render, because the exam screen
   is where the controls are and a paper of three quizzes would leave the
   ordering buttons, the matching selects and the cloze inputs unchecked. */

INSERT INTO catalog_exercises (tenant_id, id, course_id, exam, version, type, prompt, payload)
SELECT t.id, q.eid, 'web-fundamentals', true, 1, q.kind, q.prompt, q.payload::jsonb
FROM tenants t, (VALUES
  ('fx-quiz', 'quiz', 'A web server queries a database. At that instant, what is it?',
   '{"id":"fx-quiz","version":1,"type":"quiz","prompt":"A web server queries a database. At that instant, what is it?","choices":[{"text":"The database''s client","correct":true},{"text":"Still only a server"},{"text":"Neither, until the query finishes"}]}'),
  ('fx-multi', 'multiple-choice', 'Which of these are things a client does?',
   '{"id":"fx-multi","version":1,"type":"multiple-choice","prompt":"Which of these are things a client does?","choices":[{"text":"Asks for a resource","correct":true},{"text":"Opens the connection","correct":true},{"text":"Listens on a port"}]}'),
  ('fx-order', 'ordering', 'Put the steps of a request in order.',
   '{"id":"fx-order","version":1,"type":"ordering","prompt":"Put the steps of a request in order.","items":["The browser resolves the name","It opens a connection","It sends the request","The server answers"]}'),
  ('fx-match', 'matching', 'Match each status code to what it means.',
   '{"id":"fx-match","version":1,"type":"matching","prompt":"Match each status code to what it means.","pairs":[{"left":"200","right":"Here it is"},{"left":"404","right":"No such thing"},{"left":"500","right":"I broke"}]}'),
  ('fx-cloze', 'cloze', 'Complete the sentence.',
   '{"id":"fx-cloze","version":1,"type":"cloze","prompt":"Whoever asks is the ___ and whoever answers is the ___.","blanks":[{"accept":["client"],"ignore_case":true,"ignore_accents":false},{"accept":["server"],"ignore_case":true,"ignore_accents":false}]}'),
  ('fx-numeric', 'numeric', 'How many milliseconds are there in a second?',
   '{"id":"fx-numeric","version":1,"type":"numeric","prompt":"How many milliseconds are there in a second?","value":1000,"tolerance":0,"unit":"ms"}'),
  /* Out of place in a course about the web, and it is here anyway: the exam
     screen is the only place this control is drawn, and a control axe never
     opens is a control nothing checks. */
  ('fx-expression', 'expression-answer', 'A request takes t milliseconds each way. Write the round trip.',
   '{"id":"fx-expression","version":1,"type":"expression-answer","prompt":"A request takes t milliseconds each way. Write the round trip.","accept":"2*t","variables":[{"name":"t","from":1,"to":500}]}')
) AS q(eid, kind, prompt, payload)
WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;

/* ---------- a picture to label ----------

   The exam paper is the only screen that renders a question, so this is what
   makes `labelling` reachable at all — and what gives the accessibility pass a
   radio group with a picture behind it to look at.

   THE BYTES ARE HERE RATHER THAN A PATH. There is no content directory beside
   a `scratch` container, the offline bundle has no network, and a diagram that
   fails to load is a question nobody can answer. Three bands, 240x120, in the
   brand's colours: small enough to read in a diff as base64, real enough to be
   a picture a browser draws. */

INSERT INTO catalog_images (tenant_id, course_id, name, media_type, bytes)
SELECT id, 'web-fundamentals', 'request.png', 'image/png', decode(
  'iVBORw0KGgoAAAANSUhEUgAAAPAAAAB4CAIAAABD1OhwAAAA/klEQVR42u3SAQ0AMAzDsHEZ'
  'hME5fx7n0doQosyDICMBhgZDg6HB0BgaDA2GBkODoTE0GBoMDYYGQ2NoMDQYGgwNhsbQYGgw'
  'NBgaDI2hwdBgaDA0GBpDg6HB0GBoMDSGBkODocHQlA99EMTQGBoMDYYGQ2NoMDQYGgwNhsbQ'
  'YGgwNBgaDI2hwdBgaDA0GBpDg6HB0GBoMDSGBkODocHQYGgMDYYGQ4OhwdAYGgwNhgZD0z70'
  'QhBDY2gwNBgaDI2hwdBgaDA0GBpDg6HB0GBoMDSGBkODocHQYGgMDYYGQ4OhwdAYGgwNhgZD'
  'g6ExNBgaDA2GBkNjaDA0GBoMTbkP4tfNBGrZdKcAAAAASUVORK5CYII=', 'base64')
FROM tenants WHERE slug = :'slug'
ON CONFLICT (tenant_id, course_id, name) DO UPDATE SET bytes = EXCLUDED.bytes;

INSERT INTO catalog_exercises (tenant_id, id, course_id, exam, version, type, prompt, payload)
SELECT t.id, 'fx-label', 'web-fundamentals', true, 1, 'labelling',
       'Put each name on the band that plays that part.',
       '{"id":"fx-label","version":1,"type":"labelling","image":"request.png",'
       '"prompt":"Put each name on the band that plays that part.","labels":['
       '{"text":"The browser","x":0.5,"y":0.17,"radius":0.14},'
       '{"text":"The server","x":0.5,"y":0.5,"radius":0.14},'
       '{"text":"The database","x":0.5,"y":0.83,"radius":0.14}]}'::jsonb
FROM tenants t WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;

/* ---------- something to drill ----------

   The exam questions above are `exam = true` and are NOT drillable: an
   exam-only question that could be drilled would tell a student what is on the
   paper. So the practice screen needs its own, and these are it — the same
   shapes, in a lesson rather than on an exam.

   Two, because a queue of one never exercises "next question". */

INSERT INTO catalog_exercises
  (tenant_id, id, course_id, lesson_id, section_id, exam, version, type,
   drillable, prompt, payload)
SELECT t.id, q.eid, 'web-fundamentals', 't-4mzk8p2r', 'roles', false, 1, q.kind,
       true, q.prompt, q.payload::jsonb
FROM tenants t, (VALUES
  ('dr-quiz', 'quiz', 'Who is the client in an exchange?',
   '{"id":"dr-quiz","version":1,"type":"quiz","prompt":"Who is the client in an exchange?","choices":[{"text":"Whoever asks","correct":true,"why":"The roles belong to the moment, not the machine."},{"text":"Whoever answers"},{"text":"Whichever machine is smaller"}]}'),
  ('dr-order', 'ordering', 'Put the steps of a request in order.',
   '{"id":"dr-order","version":1,"type":"ordering","prompt":"Put the steps of a request in order.","items":["The browser resolves the name","It opens a connection","It sends the request","The server answers"]}')
) AS q(eid, kind, prompt, payload)
WHERE t.slug = :'slug'
ON CONFLICT DO NOTHING;
