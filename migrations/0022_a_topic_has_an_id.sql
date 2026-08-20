-- A topic is a thing, not a sentence.
--
-- # WHAT THE IDENTITY OF A LESSON USED TO BE
--
-- `catalog_courses.topics` was `text[]` — the technical contents of a course, in
-- order, as prose. The interface treats one of those entries AS a lesson, and it
-- found the lesson it belongs to by looking the sentence up:
--
--     topics[ix]  (a sentence)  ->  the lesson whose TITLE is that sentence
--                               ->  that lesson's id  ->  progress, notes, exams
--
-- Both ends were the title text, and the lesson's own id was the title
-- slugified — twenty-seven of the twenty-eight written lessons are exactly
-- `slug(title)`, and the twenty-eighth only differs because it was truncated at
-- sixty characters.
--
-- So rewording a topic moved a student's work out from under them. The lookup
-- misses, the regenerated lesson lands under a new slug, and every progress row
-- points at a lesson id nothing serves any more. No error, no log: the screen
-- shows a lesson nobody has started.
--
-- IT STOPPED BEING A HAZARD AND BECAME A CERTAINTY the moment the plan for this
-- catalogue became "the tracks, courses and topics are settled; the lesson
-- content and the exercises are scaffolding and will be written again to a
-- higher standard". Rewriting the words is the plan. The words cannot be the
-- identity.
--
-- # AND `lessons` NAMED DIRECTORIES THAT NOTHING TIED TO A TOPIC
--
-- `course.json` also carries `lessons`, a list of directory names. It is a
-- SUBSET of the topics — `javascript` declares twenty-two topics and has four
-- written, which are topics 0, 1, 3 and 5 — so the two were never paired by
-- position. What tied them together was that a directory happened to be named
-- `slug(title)` and the interface looked the lesson up by the title itself.
--
-- Nothing checked that correspondence, in either direction: a lesson whose
-- title no topic lists is a lesson no screen can reach, and it draws the
-- placeholder for a course nobody has written. That was met once already, in
-- the browser fixture, and patched there by making the two strings equal.
--
-- One table ends it. The id is declared, the title hangs off it, and `lessons`
-- names topic ids — which the validator now holds it to.

-- +goose Up

CREATE TABLE catalog_course_topics (
    tenant_id uuid    NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    course_id text    NOT NULL,
    position  integer NOT NULL,   -- the order the course declares them in
    topic_id  text    NOT NULL,
    title     text    NOT NULL,

    PRIMARY KEY (tenant_id, course_id, topic_id),

    -- The declared order is unique too: two topics at the same position is a
    -- course with no answer to "which comes first".
    UNIQUE (tenant_id, course_id, position)
);

-- What it holds about a person, said to somebody reading the schema with psql
-- and no Go. It is a table of contents and it is about nobody; the registry in
-- internal/privacy says the same thing, and a test holds the two to each other.
COMMENT ON TABLE catalog_course_topics IS 'personal-data: none';

COMMENT ON COLUMN catalog_course_topics.topic_id IS
    'the lesson id this topic becomes; declared in the file, never derived from the title';

-- The old column goes. Keeping it would leave two answers to what a course
-- contains, and the one that is only a title is the one that caused this.
ALTER TABLE catalog_courses DROP COLUMN topics;

-- +goose Down

ALTER TABLE catalog_courses ADD COLUMN topics text[] NOT NULL DEFAULT '{}';
DROP TABLE catalog_course_topics;
