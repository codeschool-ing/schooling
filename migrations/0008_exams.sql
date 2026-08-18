-- Sitting an exam.
--
-- # AN ATTEMPT IS SEALED WHEN IT IS DRAWN
--
-- Every question a student is asked is written into this table at the moment
-- the paper is drawn: what they were SHOWN, the permutation that produced it,
-- and the question AS IT WAS WRITTEN, answer key included. Nothing about an
-- attempt is read back out of the catalogue afterwards.
--
-- That is not caution, it is the only correct arrangement. The catalogue is a
-- mirror of files and the load job rewrites it whenever content is deployed
-- (C-01) — delete then insert, in one transaction. A student who started an
-- exam ten minutes before a deploy would otherwise be graded against questions
-- that are not the ones they answered, or against a question that no longer
-- exists at all. An exam is a moment; the catalogue is a moving thing.
--
-- It is also what makes `exercise_version` meaningful (C-16): the version and
-- the payload it names are stored together, so the history compares December's
-- apple with December's apple.
--
-- # THE ANSWER KEY IS IN THIS TABLE AND MUST NOT COME OUT OF IT
--
-- `sealed` holds the question with its answer. Exactly one query in the
-- repository selects that column — the one that grades a submission — and every
-- other path names its columns rather than selecting *. A test holds an
-- exported paper up against the same list of tells the presentation tests use.
--
-- # WHAT MAY CHANGE AND WHAT MAY NOT
--
-- An answer may be changed until the paper is handed in, because that is what
-- sitting an exam is. After that the attempt is frozen by a trigger: the score
-- was computed once, from these rows, and a row that can move afterwards makes
-- the score unexplainable.
--
-- Deletion is allowed, and that is the difference between this and the history
-- tables. An attempt answers "what has this person done"; nothing aggregate is
-- computed from it, because statistics come from the event stream (K-03). So it
-- cascades with the account, like progress, and the events it emitted survive
-- orphaned to carry the item analysis.

-- +goose Up

/* ---------- a track has an exam too ---------- */

-- The course exam belongs to a course and the track exam belongs to a track,
-- and neither belongs to a lesson (C-11, A-08). One table with one of the two
-- ids set, rather than a second table that would need every query written
-- twice.
ALTER TABLE catalog_exercises
    ADD COLUMN track_id text NOT NULL DEFAULT '';

-- A question belongs to exactly one of them. Written as a biconditional rather
-- than as two nullable columns and a hope.
ALTER TABLE catalog_exercises
    ADD CONSTRAINT catalog_exercises_belong_somewhere
    CHECK ((course_id <> '') <> (track_id <> ''));

-- And a track's questions are its exam by construction: a track has no lessons
-- of its own, so a track question that is not an exam question is a row nothing
-- could ever serve.
ALTER TABLE catalog_exercises
    ADD CONSTRAINT catalog_exercises_track_questions_are_exams
    CHECK (track_id = '' OR exam);

-- Drawing a paper: every exam question of one course, or of one track.
CREATE INDEX catalog_exercises_exam_pool
    ON catalog_exercises (tenant_id, course_id, track_id) WHERE exam;

/* ---------- the attempt ---------- */

CREATE TABLE exam_attempts (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- Which exam, and it is two columns rather than one string with a prefix in
    -- it, so that "every attempt at this track" is a query and not a LIKE.
    scope    text NOT NULL CHECK (scope IN ('course', 'track')),
    scope_id text NOT NULL CHECK (scope_id <> ''),

    started_at   timestamptz NOT NULL DEFAULT now(),
    submitted_at timestamptz,

    -- The result, and all of it arrives at once or none of it does.
    --
    -- THE PASS MARK IS RECORDED RATHER THAN LOOKED UP. It lives in code, where a
    -- test holds it (K-13) — but an attempt that was passed under one mark must
    -- keep meaning passed if the constant ever moves, or every certificate ever
    -- issued becomes a question about which build was running that day.
    --
    -- Whole percent, and integer, because the comparison that decides a pass is
    -- `score * 100 >= pass_mark * of`. That is exact. The same decision written
    -- as a float is a student on the mark passing or failing depending on how a
    -- ratio rounded, which is not something anybody should have to reason about
    -- twice.
    score     int,
    of        int,
    pass_mark int CHECK (pass_mark IS NULL OR pass_mark BETWEEN 1 AND 100),
    passed    boolean,

    CONSTRAINT exam_attempts_scored_when_submitted CHECK (
        (submitted_at IS NULL) = (score IS NULL)
        AND (submitted_at IS NULL) = (of IS NULL)
        AND (submitted_at IS NULL) = (pass_mark IS NULL)
        AND (submitted_at IS NULL) = (passed IS NULL)
    ),
    CONSTRAINT exam_attempts_score_fits CHECK (
        score IS NULL OR (score >= 0 AND of > 0 AND score <= of)
    )
);

-- ONE OPEN ATTEMPT AT A TIME, per student per exam, and it is an index rather
-- than a check in the handler because it is the whole integrity of an exam.
-- Without it a student starts an attempt, reads the paper, abandons it and
-- starts another until they get questions they like — and every draw is a
-- legitimate-looking row. Starting an exam that is already open resumes it.
CREATE UNIQUE INDEX exam_attempts_one_open
    ON exam_attempts (tenant_id, account_id, scope, scope_id)
    WHERE submitted_at IS NULL;

-- "What has this student sat", for the record screen and for the certificate.
CREATE INDEX exam_attempts_recent
    ON exam_attempts (tenant_id, account_id, started_at DESC);

-- Every attempt at one exam, which is what item analysis reads and what answers
-- "is this exam too hard".
CREATE INDEX exam_attempts_by_exam
    ON exam_attempts (tenant_id, scope, scope_id, started_at DESC);

CREATE FUNCTION refuse_to_change_a_handed_in_exam() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.submitted_at IS NOT NULL THEN
        RAISE EXCEPTION
            'that exam was handed in at %: it cannot be changed. A retake is a new attempt.',
            OLD.submitted_at
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN NEW;
END;
$$;

-- UPDATE only. Deletion is how an erasure removes a person's attempts, and a
-- trigger that refused it would make the erase path fail on anybody who ever
-- sat an exam.
CREATE TRIGGER exam_attempts_are_frozen_once_handed_in
    BEFORE UPDATE ON exam_attempts
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_a_handed_in_exam();

/* ---------- the paper ---------- */

CREATE TABLE exam_answers (
    attempt_id uuid NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,

    -- Position on the paper, which is the student's own frame of reference and
    -- the only one the client ever names.
    position int NOT NULL CHECK (position >= 0),

    exercise_id      text NOT NULL CHECK (exercise_id <> ''),
    exercise_version int  NOT NULL CHECK (exercise_version > 0),
    type             text NOT NULL CHECK (type <> ''),

    -- What went over the wire: the question with its answer removed and, where
    -- the order IS the answer, shuffled.
    shown jsonb NOT NULL,

    -- The permutation that produced it. Shown position -> original position.
    -- Empty for a question with nothing to shuffle.
    perm int[] NOT NULL DEFAULT '{}',

    -- THE QUESTION AS IT WAS WRITTEN, ANSWER KEY INCLUDED. See the top of this
    -- file: it is here so that grading is immune to a catalogue reload, and it
    -- is read by exactly one query in the repository.
    sealed jsonb NOT NULL,

    -- Null until the student answers, and it may be replaced until they hand
    -- in. `correct` stays null until then even so — grading happens once, at
    -- submission, so there is no moment where a row in this table knows the
    -- result of a question the student is still looking at.
    answer      jsonb,
    answered_at timestamptz,
    correct     boolean,

    PRIMARY KEY (attempt_id, position)
);

-- No tenant_id: the attempt carries it, and a copy here would be a second
-- answer to "whose school is this" that could disagree with the first.

-- Item analysis by question, across every attempt.
CREATE INDEX exam_answers_by_exercise
    ON exam_answers (exercise_id, exercise_version);

COMMENT ON TABLE exam_attempts IS 'personal-data: pseudonymous';
COMMENT ON TABLE exam_answers  IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE exam_answers;
DROP TRIGGER exam_attempts_are_frozen_once_handed_in ON exam_attempts;
DROP FUNCTION refuse_to_change_a_handed_in_exam();
DROP TABLE exam_attempts;

DROP INDEX catalog_exercises_exam_pool;
ALTER TABLE catalog_exercises
    DROP CONSTRAINT catalog_exercises_track_questions_are_exams,
    DROP CONSTRAINT catalog_exercises_belong_somewhere,
    DROP COLUMN track_id;
