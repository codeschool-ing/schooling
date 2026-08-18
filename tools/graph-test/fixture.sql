-- A track for the graph test to draw, until there is content to draw instead.
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
-- It goes away when `content/` has a school in it: the test reads whatever
-- tracks the API offers, and real ones are strictly better than this.

INSERT INTO tenants (slug, name, accent)
VALUES ('graphtest', 'Programming', '#5b8cff')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO tenant_domains (host, tenant_id)
SELECT 'code.example.tld', id FROM tenants WHERE slug = 'graphtest'
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
WHERE t.slug = 'graphtest'
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
WHERE t.slug = 'graphtest'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_tracks (tenant_id, id, name, goal, outcome, position)
SELECT id, 'frontend', 'Front-end Development',
       'Build and ship an interface that other people use.',
       'Junior Front-end Developer', 0
FROM tenants WHERE slug = 'graphtest'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_track_forks (tenant_id, track_id, position, choice, note)
SELECT id, 'frontend', 3, 'the framework', 'Either one; the ideas transfer.'
FROM tenants WHERE slug = 'graphtest'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_track_courses (tenant_id, track_id, position, course_id)
SELECT t.id, 'frontend', v.p, v.c FROM tenants t, (VALUES
  (0, 'web-fundamentals'), (1, 'html-css'), (2, 'javascript'), (4, 'testing'), (5, 'deploy')
) AS v(p, c)
WHERE t.slug = 'graphtest'
ON CONFLICT DO NOTHING;

INSERT INTO catalog_track_courses
  (tenant_id, track_id, position, option_name, option_position, course_position, course_id)
SELECT t.id, 'frontend', 3, v.o, v.op, 0, v.c FROM tenants t, (VALUES
  ('React + TypeScript', 0, 'react-ts'),
  ('Angular',            1, 'angular')
) AS v(o, op, c)
WHERE t.slug = 'graphtest'
ON CONFLICT DO NOTHING;
