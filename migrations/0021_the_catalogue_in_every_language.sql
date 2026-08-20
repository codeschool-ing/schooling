-- The catalogue in every language a school writes it in.
--
-- # WHERE THE TRANSLATIONS WERE
--
-- In a file that shipped with the interface: `assets/i18n-courses-pt.js`, keyed
-- by course id — codeschool.ing's course ids. It is the portal's file and it
-- was copied along with everything else, which worked exactly as long as this
-- deployment served one school.
--
-- A second school's `python-avancado` is in nobody's dictionary. Its name, its
-- summary and its whole syllabus came out in whatever language they were
-- written in, in every language the student picked — and nothing looked broken,
-- because a missing translation falls back to its key and the key is the
-- English text.
--
-- A course's name is the school's content. It belongs with the course, in the
-- school's own rows, exactly as the prose of a section already does.
--
-- # FIELD BY FIELD, LIKE THE PROSE
--
-- Nothing here is NOT NULL and nothing defaults to the English. A translation
-- carries the fields somebody translated and no others, so a course translated
-- in its name and not its syllabus keeps the English syllabus rather than
-- losing it (C-11). That only works because a missing translation is a missing
-- COLUMN VALUE rather than an empty string, and it is where that distinction is
-- spent.
--
-- # THE FORKS ARE KEYED BY POSITION AND THAT IS A HAZARD
--
-- A fork has no id — it is a step of a track, and the step's identity is where
-- it sits. So its translation is keyed by position, which means inserting a
-- step above one moves it and the translation stays behind, silently pointing
-- at a different fork.
--
-- The predecessor shipped exactly that. The answer is not a different key —
-- there is nothing else to key on — but a check: the validator refuses a
-- translation whose position is not a fork, or whose list of options is a
-- different length from the fork's. Both are what that failure looks like from
-- the outside.

-- +goose Up

CREATE TABLE catalog_course_text (
    tenant_id     uuid NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    course_id     text NOT NULL,
    locale        text NOT NULL,

    name          text,
    summary       text,
    prerequisites text,
    syllabus      text[],
    topics        text[],

    PRIMARY KEY (tenant_id, course_id, locale)
);

COMMENT ON TABLE catalog_course_text IS 'personal-data: none';

CREATE TABLE catalog_track_text (
    tenant_id uuid NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    track_id  text NOT NULL,
    locale    text NOT NULL,

    name      text,
    goal      text,
    outcome   text,

    PRIMARY KEY (tenant_id, track_id, locale)
);

COMMENT ON TABLE catalog_track_text IS 'personal-data: none';

CREATE TABLE catalog_track_fork_text (
    tenant_id uuid    NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    track_id  text    NOT NULL,
    position  integer NOT NULL,
    locale    text    NOT NULL,

    choice    text,
    note      text,
    -- In the fork's own order, so option 0 is option 0 in both languages. The
    -- validator holds the length to the fork's.
    options   text[],

    PRIMARY KEY (tenant_id, track_id, position, locale)
);

COMMENT ON TABLE catalog_track_fork_text IS 'personal-data: none';

-- +goose Down

DROP TABLE catalog_track_fork_text;
DROP TABLE catalog_track_text;
DROP TABLE catalog_course_text;
