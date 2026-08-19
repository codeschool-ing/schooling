-- What is in a course, said before the course is written.
--
-- A catalogue is mostly ANNOUNCEMENTS: a course exists as a name, a duration
-- and a promise long before anybody has written a lesson of it. Until now the
-- mirror could carry the promise only as one line of `summary`, and the two
-- lists that actually say what somebody would learn had nowhere to live.
--
-- `syllabus` is the commercial read — five to seven lines, what the student
-- takes away. `topics` is the complete technical list, for somebody who has
-- already decided. Both are optional and both are ordered, which is why they
-- are arrays rather than a table: the order is the content, a row per line
-- would need a position column to preserve it, and nothing ever queries one
-- line of a syllabus on its own.

-- +goose Up

ALTER TABLE catalog_courses
    ADD COLUMN syllabus text[] NOT NULL DEFAULT '{}',
    ADD COLUMN topics   text[] NOT NULL DEFAULT '{}';

-- The mirror is derived and the load job rewrites it whole, so there is nothing
-- to backfill: the next load fills these from `content/`.

-- +goose Down

ALTER TABLE catalog_courses
    DROP COLUMN syllabus,
    DROP COLUMN topics;
