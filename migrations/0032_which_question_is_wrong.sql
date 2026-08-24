-- Which QUESTION is wrong, not only which section.
--
-- # THE HALF THAT WAS DECLARED MISSING
--
-- `0029_something_here_is_wrong.sql` said it out loud: an assessment IS a
-- section, so "the answer to question three is wrong" had somewhere to land and
-- no way to say WHICH question. It also said why the column was not added
-- then — a nullable column nothing writes is a column every reader has to
-- guess about. Something writes it now.
--
-- # A REPORT POINTS AT ONE OF TWO THINGS
--
-- A section, which is where the prose is, or an exercise, which is where a key
-- can be wrong. The coordinates below carry both because they are not
-- alternatives in practice: an exercise knows its course and its section, and
-- the server fills those in from the catalogue rather than trusting a client
-- to send them. What an operator gets is the path AND the question.
--
-- THE TWO ARE STILL NOT INTERCHANGEABLE, and the constraint says so: a report
-- names a section or an exercise, and one with neither is a row pointing at a
-- course and nothing in it — which is not something anybody can act on.
--
-- # WHY `lesson_id` AND `section_id` STOPPED BEING NON-EMPTY
--
-- Not to make them optional. A drilled card comes out of a queue that spans
-- courses, and `catalog_exercises` carries a section for almost all of them and
-- not for every one. Refusing those reports would mean the one channel by which
-- a wrong answer key comes back is closed for exactly the questions a student
-- meets most often — so a blank is allowed where the catalogue has no answer,
-- and it is honest rather than convenient: the queue then shows the question
-- and no path, which is what is actually known.
--
-- # THE UNIQUE INDEX GAINS THE EXERCISE
--
-- One open report per person per THING. Without the exercise in the key, a
-- student who found two bad questions in one assessment could report one of
-- them — the second would read as a duplicate of the first, which is the
-- failure this whole feature exists to prevent.

-- +goose Up

ALTER TABLE content_reports
    -- Empty means the report is about the section rather than a question in it.
    ADD COLUMN exercise_id text NOT NULL DEFAULT '',

    -- Which version was in front of them. Null when no exercise is named — and
    -- it matters when one is: a key fixed last week and a report from last
    -- month are about different questions with the same id.
    ADD COLUMN exercise_version integer;

-- BY THE NAME POSTGRES GAVE THEM, and deliberately not `IF EXISTS`. A column
-- check written inline is named `<table>_<column>_check`, and if that guess is
-- wrong this migration fails in CI — which is the direction worth failing in.
-- `IF EXISTS` would leave the old constraint standing and refuse a blank
-- section at run time, months later, on the one report the drill exists to
-- collect.
ALTER TABLE content_reports
    DROP CONSTRAINT content_reports_lesson_id_check,
    DROP CONSTRAINT content_reports_section_id_check;

ALTER TABLE content_reports
    ADD CONSTRAINT content_reports_points_at_something
    CHECK (exercise_id <> '' OR (lesson_id <> '' AND section_id <> '')),

    -- A version without a question is a number about nothing, and a question
    -- whose version nobody recorded cannot be told from the one that replaced
    -- it.
    ADD CONSTRAINT content_reports_a_version_belongs_to_a_question
    CHECK ((exercise_id = '') = (exercise_version IS NULL));

DROP INDEX content_reports_one_open_each;

CREATE UNIQUE INDEX content_reports_one_open_each
    ON content_reports (tenant_id, account_id, course_id, lesson_id, section_id, exercise_id)
    WHERE settled_at IS NULL;

-- +goose Down

DROP INDEX content_reports_one_open_each;

CREATE UNIQUE INDEX content_reports_one_open_each
    ON content_reports (tenant_id, account_id, course_id, lesson_id, section_id)
    WHERE settled_at IS NULL;

-- THE DOWN DELETES, and says so. Rows reported against an exercise with no
-- section cannot satisfy the constraint being restored, and a migration that
-- rolls back into a state the schema refuses is a rollback that fails halfway.
-- What is lost is a queue entry; what would be lost otherwise is the ability to
-- roll back at all.
DELETE FROM content_reports WHERE lesson_id = '' OR section_id = '';

ALTER TABLE content_reports
    DROP CONSTRAINT content_reports_a_version_belongs_to_a_question,
    DROP CONSTRAINT content_reports_points_at_something,
    DROP COLUMN exercise_version,
    DROP COLUMN exercise_id;

ALTER TABLE content_reports
    ADD CONSTRAINT content_reports_lesson_id_check CHECK (lesson_id <> ''),
    ADD CONSTRAINT content_reports_section_id_check CHECK (section_id <> '');
