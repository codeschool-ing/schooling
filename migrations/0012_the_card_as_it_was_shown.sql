-- What a card looked like when it was put in front of somebody.
--
-- # WHY THIS HAS TO BE KEPT AT ALL
--
-- A question is PRESENTED rather than sent: the key removed, and where the
-- order IS the answer, shuffled. `internal/grade` hands back the permutation it
-- used, and the answer arrives expressed in the frame the student saw — so
-- without that permutation the answer cannot be mapped back, and grading it
-- would mark correct work wrong.
--
-- An exam keeps it on the attempt. Practice has no attempt: a card is drawn,
-- answered, and that is the whole transaction.
--
-- # WHY NOT RECOMPUTE IT FROM A SEED
--
-- The obvious alternative is to derive the shuffle from something stable — the
-- account, the exercise, the day — and reproduce it when the answer arrives. It
-- does not work: anything the server can derive from those the client can
-- derive too, and for an `ordering` question the permutation IS the answer. It
-- would need a per-deployment secret to be safe, which is one more thing to
-- configure, rotate and get wrong. A signed token the client carries is the
-- same objection with an extra step: the same secret.
--
-- # WHY NOT A COLUMN ON practice_state
--
-- Because a row there means "this card has a schedule", and every column on it
-- is NOT NULL for that reason. A card somebody merely LOOKED at has no
-- schedule: writing one would put an interval, an ease and a due date against a
-- question nobody has answered, and "new" would stop meaning never answered.
-- The semantics are worth more than the table.
--
-- # IT IS A DRAFT, NOT A RECORD
--
-- One row per student per card, replaced every time that card is drawn. Nothing
-- reads it after the answer is graded, and nothing is lost if it is deleted: the
-- worst case is a student being asked to draw the card again. The history that
-- matters is `practice_review`, which is append-only and beside it.
--
-- So it is not append-only, it has no trigger, and it goes when the person does.

-- +goose Up

CREATE TABLE practice_drawn (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    exercise_id text NOT NULL CHECK (exercise_id <> ''),

    -- The version that was shown. A question edited between the draw and the
    -- answer is a different question, and grading the new one against an answer
    -- to the old is how a student is marked wrong for our edit.
    exercise_version int NOT NULL CHECK (exercise_version > 0),

    -- perm[i] is the ORIGINAL position of the item shown at i. Reading it the
    -- other way round is the mistake that marks correct answers wrong for
    -- everybody at once — `internal/grade` says so where it builds one.
    --
    -- An empty array is a question with nothing to shuffle, which is different
    -- from a card that was never drawn: that is the absence of the row.
    perm int[] NOT NULL,

    drawn_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, account_id, exercise_id)
);

COMMENT ON TABLE practice_drawn IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE practice_drawn;
