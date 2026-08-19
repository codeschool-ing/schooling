-- Questions taken out of circulation.
--
-- # WHY IT IS NOT A COLUMN ON THE QUESTION
--
-- `catalog_exercises` is a mirror of the files in `content/`, written by the
-- load job and by nothing else (C-01, C-07). A quarantine flag there would be
-- overwritten by the next load — and worse, it would be a fact about our
-- OBSERVATION of a question living in a table that is supposed to be a copy of
-- what somebody wrote. The content is what the file says; whether we have
-- stopped asking it is ours.
--
-- Keeping it separate also means a reload cannot silently release a quarantine,
-- and that a question deleted from the files leaves its quarantine behind
-- harmlessly rather than taking it with it.
--
-- # IT IS KEYED BY VERSION, AND THAT IS THE RELEASE MECHANISM
--
-- A new version of a question is a different question. Quarantining `alg-3` at
-- version 1 says nothing about version 2 — so the ordinary way out of
-- quarantine is to fix the question, which produces a version the quarantine
-- does not match. Nobody has to remember to release anything.
--
-- Explicit release exists for the other case: we looked, and the numbers were
-- wrong about it.
--
-- # THE HISTORY IS THE AUDIT LOG
--
-- One row per question and version, with `released_at` saying whether it is
-- current. Every transition is an audit entry — actor, before, after — because
-- taking a question out of a course is an administrative action whether a
-- person or a job did it, and `audit_log` is where those are answered from.

-- +goose Up

CREATE TABLE question_quarantine (
    tenant_id   uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    exercise_id text NOT NULL CHECK (exercise_id <> ''),
    version     int  NOT NULL CHECK (version > 0),

    quarantined_at timestamptz NOT NULL DEFAULT now(),

    -- WHY, IN THE NUMBERS THAT DECIDED IT. A row saying only "quarantined" is
    -- one nobody can argue with, and the first thing anybody asks about a
    -- question that vanished from a course is what it was measured at.
    verdict        text NOT NULL CHECK (verdict <> ''),
    attempts       int  NOT NULL CHECK (attempts >= 0),
    discrimination real NOT NULL,
    minimum_sample int  NOT NULL CHECK (minimum_sample > 0),

    -- Null while it is out of circulation. A row that is here and released is
    -- kept rather than deleted: "this was quarantined in March and put back"
    -- is a question somebody will ask.
    released_at timestamptz,
    released_why text NOT NULL DEFAULT '',

    PRIMARY KEY (tenant_id, exercise_id, version)
);

-- What the draw asks on every exam and every practice queue: which questions
-- in this school are out of circulation right now.
CREATE INDEX question_quarantine_in_force
    ON question_quarantine (tenant_id, exercise_id, version)
    WHERE released_at IS NULL;

COMMENT ON TABLE question_quarantine IS 'personal-data: none';

-- +goose Down

DROP TABLE question_quarantine;
