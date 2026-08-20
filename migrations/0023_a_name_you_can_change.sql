-- A readable name that is free to change, beside an id that is not.
--
-- # WHAT THIS SEPARATES
--
-- A course was `statistics` — one string doing two jobs. It was the address a
-- student shared, the name a reviewer read in a pull request, AND the thing
-- every durable record pointed at: a progress row, a note, an answer given on
-- an exam. Renaming it meant moving somebody's work.
--
-- So it becomes two. `id` is opaque and permanent (`co-cbwm5kwa`); `slug` is
-- the readable name and is free to change. Tracks and sections get the same
-- pair, for the same reason.
--
-- LESSONS AND EXERCISES GET NO SLUG. Neither is ever addressed — a lesson is
-- reached by its position in a course and an exercise is never reached at all —
-- so a second, readable name would be a column nobody reads. The lesson ids
-- keep the random half they were given in 0022 and change prefix from `t-` to
-- `le-`, so that `tr-`, `co-`, `le-` and `se-` are told apart at a glance
-- rather than by counting characters.
--
-- # WHAT IT DOES NOT BUY
--
-- A link that survives a rename. The address carries the slug, so changing one
-- still breaks a bookmark exactly as before. What changes is that the student's
-- WORK no longer moves with it — and that is the half that cannot be repaired
-- afterwards, because a broken link is a 404 somebody reports and a detached
-- progress row is a screen that looks fine and is wrong.

-- +goose Up

/* THE SLUG IS NOT UNIQUE-CONSTRAINED HERE, and that is deliberate rather than
   an omission. `content/` is the source of truth and `validate-content` refuses
   two courses with one slug before a single row is written — the check belongs
   where the fix is, which is the file. A constraint here would fail the load
   job halfway through instead, with the mirror in neither state.

   It is indexed because every catalogue request resolves an address through
   it. */
ALTER TABLE catalog_tracks   ADD COLUMN slug text NOT NULL DEFAULT '';
ALTER TABLE catalog_courses  ADD COLUMN slug text NOT NULL DEFAULT '';
ALTER TABLE catalog_sections ADD COLUMN slug text NOT NULL DEFAULT '';

CREATE INDEX catalog_tracks_by_slug  ON catalog_tracks  (tenant_id, slug);
CREATE INDEX catalog_courses_by_slug ON catalog_courses (tenant_id, slug);

COMMENT ON COLUMN catalog_courses.slug IS
    'the readable name, used in an address; free to change — the id is not';

-- # AND THE TRANSLATED TOPICS STOP JOINING BY POSITION
--
-- `catalog_course_text.topics` was a `text[]` matched to the English topics by
-- index. Insert a topic and every translation after it describes the one
-- before, in perfect Portuguese — nothing malformed, nothing thrown, and a
-- student reading the wrong heading over the right lesson.
--
-- It is the join this schema forbids everywhere else, and it survived because
-- until 0022 a topic had no id to key it by. Now it has one.

CREATE TABLE catalog_course_topic_text (
    tenant_id uuid NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    course_id text NOT NULL,
    topic_id  text NOT NULL,
    locale    text NOT NULL,
    title     text NOT NULL,

    PRIMARY KEY (tenant_id, course_id, topic_id, locale)
);

COMMENT ON TABLE catalog_course_topic_text IS 'personal-data: none';

ALTER TABLE catalog_course_text DROP COLUMN topics;

-- +goose Down

ALTER TABLE catalog_course_text ADD COLUMN topics text[];
DROP TABLE catalog_course_topic_text;

DROP INDEX catalog_courses_by_slug;
DROP INDEX catalog_tracks_by_slug;

ALTER TABLE catalog_sections DROP COLUMN slug;
ALTER TABLE catalog_courses  DROP COLUMN slug;
ALTER TABLE catalog_tracks   DROP COLUMN slug;
