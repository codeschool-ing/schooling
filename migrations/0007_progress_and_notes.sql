-- What a student has done, where they were, and what they wrote down.
--
-- COMPLETION IS SET-TRUE AND NEVER TOGGLED (A-05). There is no column here that
-- can go back to false and no path that un-completes anything: finishing a
-- section is a fact about the past, and a progress bar that moves backwards for
-- somebody who did nothing wrong is the most demoralising thing a study
-- platform can do. Mastery decays — that is `practice_state`, a different table
-- for a different question, and it never reaches a progress bar.
--
-- THE PRIVACY BOUNDARY THAT MATTERS IS BETWEEN STUDENTS, and it is `account_id`
-- (P-05). Every table here carries one and every query leads with it after the
-- tenant. Row-level security is deliberately absent, so this is enforced by the
-- code and by the tests that hold the code to it — not by the database noticing
-- afterwards.
--
-- THESE ROWS BELONG TO THE PERSON AND GO WHEN THEY DO. Unlike events and
-- reviews, which survive an erasure orphaned so the statistics stay whole,
-- progress answers only "what has this person done" — nothing aggregate is
-- computed from it (K-03 puts statistics in the event stream). So it has a real
-- foreign key and it cascades.

-- +goose Up

CREATE TABLE section_progress (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    course_id  text NOT NULL,
    lesson_id  text NOT NULL,
    section_id text NOT NULL,

    -- The only column, and it has no companion that could contradict it. There
    -- is no `completed boolean` because a boolean can be set to false.
    completed_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, account_id, course_id, lesson_id, section_id)
);

-- "How far through this course am I", which is the question every screen asks.
CREATE INDEX section_progress_by_course
    ON section_progress (tenant_id, account_id, course_id);

-- WHERE THEY WERE, one row per course rather than one per student.
--
-- A single pointer per student would send somebody who paused a mathematics
-- course to open a programming one straight back into mathematics, which is the
-- opposite of resuming.
CREATE TABLE resume_pointer (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    course_id  text NOT NULL,

    lesson_id  text NOT NULL,
    section_id text NOT NULL,
    at         timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, account_id, course_id)
);

-- Reading it across courses is "carry on where you left off" on the dashboard.
CREATE INDEX resume_pointer_recent
    ON resume_pointer (tenant_id, account_id, at DESC);

-- What the student wrote down.
--
-- ONE NOTE PER SECTION, replaced rather than appended. A note is a person's own
-- margin, and versioning somebody's margin would mean deciding what to show
-- them, which is a product nobody asked for.
CREATE TABLE notes (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    course_id  text NOT NULL,
    lesson_id  text NOT NULL,
    section_id text NOT NULL,

    body       text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, account_id, course_id, lesson_id, section_id)
);

CREATE INDEX notes_by_course ON notes (tenant_id, account_id, course_id);

COMMENT ON TABLE section_progress IS 'personal-data: pseudonymous';
COMMENT ON TABLE resume_pointer   IS 'personal-data: pseudonymous';
-- Identifying, unlike the other two: a note is free text a person wrote, and
-- what somebody puts in their own margin is not for this schema to assume.
COMMENT ON TABLE notes            IS 'personal-data: identifying';

-- +goose Down

DROP TABLE notes;
DROP TABLE resume_pointer;
DROP TABLE section_progress;
