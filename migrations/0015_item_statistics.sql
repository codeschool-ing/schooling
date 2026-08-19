-- What the answers say about each question.
--
-- # A ROLLUP, NOT A RECORD
--
-- Every row here is derived from the event stream and can be thrown away and
-- recomputed. That is why it is overwritten in place and carries no history:
-- the history is `events`, which is append-only and survives an erasure
-- orphaned, and this is a cache of what the last run of the job made of it.
--
-- It exists because the answer is expensive and the question is asked on a
-- screen. Computing a discrimination index across every answer to every
-- question, every time somebody opens the console, would be a report that gets
-- slower as the platform gets more useful.
--
-- # IT HOLDS NOTHING ABOUT ANYBODY
--
-- Counts and ratios over a QUESTION. There is no account id here and there
-- cannot be one: the unit is the item, and the moment a row could be traced to a
-- person it would be a second copy of what somebody answered, in a table nobody
-- would think to erase.
--
-- # ONE ROW PER VERSION, AND THAT IS THE POINT
--
-- A question that was edited is a different question. Folding the two together
-- would average a wrong key with the fix that corrected it, and the fix would be
-- hidden by the answers given before it — which is the failure this whole thing
-- exists to surface.

-- +goose Up

CREATE TABLE item_statistics (
    tenant_id   uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    exercise_id text NOT NULL CHECK (exercise_id <> ''),
    version     int  NOT NULL CHECK (version > 0),

    -- Denormalised from the question, because a report reads this table alone
    -- and the catalogue is a mirror that the load job prunes.
    type text NOT NULL DEFAULT '',

    attempts int NOT NULL CHECK (attempts >= 0),
    correct  int NOT NULL CHECK (correct >= 0 AND correct <= attempts),

    -- The share who got it right, 0 to 1. Named for what item analysis calls it,
    -- which is the opposite of what the word suggests: a HIGH difficulty is an
    -- EASY question.
    difficulty real NOT NULL CHECK (difficulty >= 0 AND difficulty <= 1),

    -- The strong group's share correct minus the weak group's, -1 to 1. Zero
    -- when it could not be measured, which is why the group sizes are here: a
    -- zero with two empty groups is not a finding.
    discrimination real NOT NULL CHECK (discrimination >= -1 AND discrimination <= 1),
    strong_group   int  NOT NULL DEFAULT 0 CHECK (strong_group >= 0),
    weak_group     int  NOT NULL DEFAULT 0 CHECK (weak_group >= 0),

    -- The closed list, and `insufficient` is a member of it rather than the
    -- absence of one. A screen showing a question with no verdict as though it
    -- had passed is the failure this shape prevents.
    verdict text NOT NULL CHECK (verdict IN
        ('insufficient', 'fine', 'too-easy', 'weak', 'inverted')),

    -- THE THRESHOLD TRAVELS WITH THE NUMBER IT PRODUCED (K-16). Stored rather
    -- than looked up when the row is read: a verdict computed under a minimum
    -- of thirty and displayed beside a constant that now says fifty would be a
    -- row explaining itself with the wrong number.
    minimum_sample int NOT NULL CHECK (minimum_sample > 0),

    first_answer timestamptz NOT NULL,
    last_answer  timestamptz NOT NULL,
    computed_at  timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, exercise_id, version)
);

-- The console's question is "what is wrong in this school", so the index leads
-- with the school and narrows to the rows worth looking at.
CREATE INDEX item_statistics_needing_attention
    ON item_statistics (tenant_id, verdict, last_answer DESC)
    WHERE verdict IN ('inverted', 'weak', 'too-easy');

COMMENT ON TABLE item_statistics IS 'personal-data: none';

-- +goose Down

DROP TABLE item_statistics;
