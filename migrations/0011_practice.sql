-- Where a student is with each question they are drilling.
--
-- # THIS IS NOT PROGRESS, AND THE DIFFERENCE IS THE WHOLE POINT
--
-- `section_progress` answers "what have I done", is set-true and never toggled,
-- and is what a progress bar reads. This answers "how well do I still know
-- this", and it DECAYS: a card that was strong in March is due again in June
-- because that is what remembering does.
--
-- The two must never be joined onto one number. A progress bar that fell
-- because a student did not drill is the most demoralising thing a study
-- platform can do — they did nothing wrong, and the screen tells them they went
-- backwards. `0007_progress_and_notes.sql` says the same thing from the other
-- side, and a test holds the boundary rather than a convention.
--
-- # ONE ROW PER CARD, AND THE HISTORY IS SOMEWHERE ELSE
--
-- SM-2 keeps its whole state in three numbers, so this table is small and is
-- overwritten in place. `practice_review` — written since Fase 0, before there
-- was anything to review — is the append-only log beside it, and it carries the
-- values from BEFORE each answer as well as after. That is what lets a better
-- scheduler be fitted later by replaying what was known at each point, rather
-- than argued about.
--
-- So: this row can be recomputed from that log, and the log cannot be recovered
-- from this row. Which is why one refuses UPDATE and the other does not.
--
-- # DUE IS A DATE
--
-- SM-2's intervals are in days. A due *timestamp* would make a card not due at
-- 14:31 and due at 14:32, which is a distinction no student could see the sense
-- of and which turns "what is due today" into a question about clocks. The day
-- is the honest granularity, and it is the school's day rather than UTC's —
-- which is a decision for whoever adds a time zone to an account, and until
-- then the platform's.
--
-- # IT BELONGS TO THE PERSON AND GOES WHEN THEY DO
--
-- Nothing aggregate is computed from it: statistics come from the event stream
-- (K-03) and the fitting history is `practice_review`, which survives orphaned.
-- So this has a real foreign key and it cascades, exactly as progress does.

-- +goose Up

CREATE TABLE practice_state (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- By id, without the version. A question that is edited is the same card:
    -- the student is still learning that idea, and resetting their schedule
    -- because a typo was fixed would punish them for our edit. WHICH version
    -- they answered is recorded per answer, in practice_review.
    exercise_id text NOT NULL CHECK (exercise_id <> ''),

    -- SM-2's three numbers, and the names it uses for them.
    --
    -- `ease` has a floor of 1.3 in the algorithm; the constraint is wider on
    -- purpose, so that a scheduler bug shows up as a wrong number to look at
    -- rather than as a write that fails somewhere unrelated.
    interval_days int          NOT NULL CHECK (interval_days >= 0),
    ease          numeric(4,2) NOT NULL CHECK (ease BETWEEN 1.0 AND 5.0),
    repetition    int          NOT NULL CHECK (repetition >= 0),

    -- How many times it has been forgotten after being learnt. Not derivable
    -- from the three above — a lapse resets them — and it is the number that
    -- says "this one is hard for this person" rather than "this one is new".
    lapses int NOT NULL DEFAULT 0 CHECK (lapses >= 0),

    due_on           date        NOT NULL,
    last_reviewed_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, account_id, exercise_id)
);

-- "What is due for me today", which is the only question the queue asks. It
-- leads with the tenant and the account like every other index here, and
-- `due_on` last so a range scan over one student's cards is one lookup.
CREATE INDEX practice_state_due ON practice_state (tenant_id, account_id, due_on);

COMMENT ON TABLE practice_state IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE practice_state;
