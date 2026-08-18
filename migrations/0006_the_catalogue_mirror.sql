-- The catalogue, as a mirror of the files.
--
-- THE FILES ARE THE SOURCE OF TRUTH AND THESE TABLES ARE DERIVED (C-01). Every
-- row here was written by the load job from `content/`, and the load job is the
-- only thing that writes them — the console reads and never writes (C-07). A
-- test scans the source for anybody else writing to a `catalog_` table, because
-- "only the load job writes it" is otherwise an arrangement, and the first
-- console screen that fixes a typo directly is the moment the files stop being
-- the truth.
--
-- WHY MIRROR AT ALL, when the files are right there. A student's request must
-- not touch a filesystem: the container is immutable, a query joins the
-- catalogue to their progress, and the console counts things. Reading Markdown
-- per request to answer "which courses are published" is the shape of system
-- that works until it has students.
--
-- NO JSONB FOR STRUCTURE. A track's forks are rows, not a document, because the
-- question "which tracks show this course" is asked by the graph screen, by the
-- prerequisite check and by the console — and a jsonb column answers it with a
-- scan and a hand-written path expression. The only jsonb here is an exercise's
-- payload, whose shape genuinely varies by type.
--
-- PRUNING IS DELETION, and it is safe for one reason: nothing a student did
-- points at these rows with a foreign key. `practice_review.exercise_id` is
-- text and deliberately unkeyed (see 0002), so a question that leaves the
-- catalogue leaves the history behind intact and orphaned — which is the same
-- decision, for the same reason, as erasure.

-- +goose Up

/* ---------- tracks ---------- */

CREATE TABLE catalog_tracks (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    id        text NOT NULL,

    name    text NOT NULL,
    goal    text NOT NULL DEFAULT '',
    outcome text NOT NULL DEFAULT '',

    -- The track whose courses this one may assume the student has taken. Text
    -- rather than a key: it is checked before anything is written, and a key
    -- would make the order of the load's inserts a constraint.
    continues text NOT NULL DEFAULT '',

    position int NOT NULL,

    PRIMARY KEY (tenant_id, id)
);

-- A fork's prose. One row per forking step; a step with a single course has no
-- row here at all.
CREATE TABLE catalog_track_forks (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    track_id  text NOT NULL,
    position  int  NOT NULL,

    choice text NOT NULL,
    note   text NOT NULL DEFAULT '',

    PRIMARY KEY (tenant_id, track_id, position)
);

-- Every course a track contains, flattened.
--
-- `option_name` is empty for a plain step and named for a fork's branch, which
-- is what lets one query answer both "render this track" and "which tracks show
-- this course" without a second representation to disagree with the first.
CREATE TABLE catalog_track_courses (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    track_id  text NOT NULL,

    position        int  NOT NULL, -- the step
    option_name     text NOT NULL DEFAULT '',
    option_position int  NOT NULL DEFAULT 0,
    course_position int  NOT NULL DEFAULT 0,

    course_id text NOT NULL,

    PRIMARY KEY (tenant_id, track_id, position, option_position, course_position)
);

CREATE INDEX catalog_track_courses_by_course ON catalog_track_courses (tenant_id, course_id);

/* ---------- courses ---------- */

CREATE TABLE catalog_courses (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    id        text NOT NULL,

    name          text NOT NULL,
    category      text NOT NULL DEFAULT '',
    level         text NOT NULL DEFAULT '',
    hours         int  NOT NULL DEFAULT 0,
    summary       text NOT NULL DEFAULT '',
    prerequisites text NOT NULL DEFAULT '',

    -- A course being written is not a course a student can find. It is a column
    -- rather than a directory, so publishing is a changed line rather than a
    -- move that loses the file's history.
    draft boolean NOT NULL DEFAULT false,

    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX catalog_courses_published ON catalog_courses (tenant_id, id) WHERE NOT draft;

-- What a student has to KNOW first, which is not the same as what comes before
-- it in a track. Conflating the two cost 18 false edges once.
CREATE TABLE catalog_course_requires (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    course_id  text NOT NULL,
    requires_id text NOT NULL,

    PRIMARY KEY (tenant_id, course_id, requires_id)
);

/* ---------- lessons, sections and their prose ---------- */

CREATE TABLE catalog_lessons (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    course_id text NOT NULL,
    id        text NOT NULL,

    title    text NOT NULL,
    position int  NOT NULL,

    PRIMARY KEY (tenant_id, course_id, id)
);

CREATE TABLE catalog_sections (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    course_id text NOT NULL,
    lesson_id text NOT NULL,
    id        text NOT NULL,

    kind     text NOT NULL,
    video    boolean NOT NULL DEFAULT false,
    duration text NOT NULL DEFAULT '',

    -- Separate from kind, so progress semantics are never inferred from what a
    -- section IS.
    countable boolean NOT NULL DEFAULT true,

    position int NOT NULL,

    PRIMARY KEY (tenant_id, course_id, lesson_id, id)
);

-- The prose, one row per section per locale.
--
-- A missing translation is a MISSING ROW rather than an empty one, so the
-- server falls back field by field and a section translated in its title but
-- not its body keeps the English body instead of losing the title too (C-11).
CREATE TABLE catalog_prose (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    course_id text NOT NULL,
    lesson_id text NOT NULL,
    section_id text NOT NULL,
    locale    text NOT NULL,

    title text NOT NULL DEFAULT '',
    body  text NOT NULL,

    PRIMARY KEY (tenant_id, course_id, lesson_id, section_id, locale)
);

/* ---------- exercises ---------- */

CREATE TABLE catalog_exercises (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    id        text NOT NULL,

    course_id text NOT NULL,
    -- Empty for an exam, which belongs to a course and to no lesson.
    lesson_id  text NOT NULL DEFAULT '',
    section_id text NOT NULL DEFAULT '',
    exam       boolean NOT NULL DEFAULT false,

    version    int  NOT NULL CHECK (version > 0),
    type       text NOT NULL,
    difficulty text NOT NULL DEFAULT '',
    drillable  boolean NOT NULL DEFAULT false,

    prompt text NOT NULL,
    hint   text NOT NULL DEFAULT '',

    -- THE ONLY JSONB HERE, and it earns it: a `quiz` has choices, a `code` has
    -- test cases, a `numeric` has a unit and a tolerance. A column per type
    -- would be a table that is mostly null and a migration per new type.
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,

    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX catalog_exercises_by_section
    ON catalog_exercises (tenant_id, course_id, lesson_id, section_id);

COMMENT ON TABLE catalog_tracks         IS 'personal-data: none';
COMMENT ON TABLE catalog_track_forks    IS 'personal-data: none';
COMMENT ON TABLE catalog_track_courses  IS 'personal-data: none';
COMMENT ON TABLE catalog_courses        IS 'personal-data: none';
COMMENT ON TABLE catalog_course_requires IS 'personal-data: none';
COMMENT ON TABLE catalog_lessons        IS 'personal-data: none';
COMMENT ON TABLE catalog_sections       IS 'personal-data: none';
COMMENT ON TABLE catalog_prose          IS 'personal-data: none';
COMMENT ON TABLE catalog_exercises      IS 'personal-data: none';

-- +goose Down

DROP TABLE catalog_exercises;
DROP TABLE catalog_prose;
DROP TABLE catalog_sections;
DROP TABLE catalog_lessons;
DROP TABLE catalog_course_requires;
DROP TABLE catalog_courses;
DROP TABLE catalog_track_courses;
DROP TABLE catalog_track_forks;
DROP TABLE catalog_tracks;
