-- What a student says is wrong with the material, and what was done about it.
--
-- # THE SECOND THING BETWEEN A WRONG ANSWER KEY AND A STUDENT
--
-- The material is written by a machine and there is no human reviewer (C-14).
-- Until now the only thing standing between a wrong answer key and somebody
-- studying was `validate-catalog`, which checks what can be checked mechanically
-- — that the key parses, that the ids join, that the grader accepts its own
-- answer. It cannot know that the accepted answer is the wrong one.
--
-- The person who does know is the student, and they had nowhere to say it. This
-- is that channel, and it is the only one in the system where a fact about the
-- content flows back UPWARDS.
--
-- # IT IS A SECTION, NOT AN EXERCISE — TODAY
--
-- The coordinates are the same three the rest of the student's rows use:
-- course, lesson, section. An assessment IS a section, so "the answer to
-- question three is wrong" has somewhere to land; what it does not have yet is
-- a way to name WHICH question.
--
-- That is deliberate rather than forgotten. The exercise card is drawn by one
-- renderer shared by the assessment, the drill and the exam, so a control put
-- there appears in the middle of a timed paper — and whether a student may stop
-- and write during an exam is a question of its own rather than a copy of this
-- one. The column that would carry it does not exist yet either, for the reason
-- the whole schema works this way: a nullable column nothing writes is a column
-- every reader has to guess about.
--
-- # THE ROW GOES WHEN THE PERSON DOES
--
-- `note` is a sentence somebody wrote in their own words, which is exactly what
-- the erase path exists to remove — `notes` goes for the same reason, and this
-- is no different for being about our content instead of theirs. It cascades.
--
-- What must NOT be lost when it goes is the operational fact, and that is why
-- settling one writes an audit entry (K-01): the queue is somebody's words and
-- goes with them, and "this question was withdrawn, by whom, when" is the
-- platform's own record and stays.

-- +goose Up

CREATE TABLE content_reports (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    course_id  text NOT NULL CHECK (course_id <> ''),
    lesson_id  text NOT NULL CHECK (lesson_id <> ''),
    section_id text NOT NULL CHECK (section_id <> ''),

    -- WHAT IS WRONG, FROM A CLOSED LIST. Free text alone would make the queue
    -- unsortable and every report a paragraph to read before knowing whether it
    -- is urgent; a wrong answer key and a broken video are not the same job.
    -- The words themselves live in Go, where a test holds them.
    reason text NOT NULL CHECK (reason <> ''),

    -- AND IN THEIR OWN WORDS, WHICH IS THE HALF THAT IS ACTIONABLE. "The answer
    -- key says B" is a fix; "answer" alone is a hunt. Bounded, because an
    -- unbounded text field reachable by anybody with an account is a place to
    -- put a megabyte.
    note text NOT NULL DEFAULT '' CHECK (length(note) <= 500),

    reported_at timestamptz NOT NULL DEFAULT now(),

    -- The operator's end of it. Null all the way across means still open.
    settled_at timestamptz,
    settled_by uuid REFERENCES accounts(id) ON DELETE SET NULL,
    verdict    text NOT NULL DEFAULT '',

    -- SETTLED MEANS DECIDED, and a decision has a word. A row with a time and
    -- no verdict is a report somebody closed without saying what they found,
    -- which is the state that makes a queue stop being trusted.
    --
    -- `settled_by` IS NOT IN THIS RULE, because it is allowed to become null:
    -- the operator who settled it may themselves be erased later, and an entry
    -- saying "settled by somebody who no longer exists" is still true. Who it
    -- was is in the audit, which does not erase.
    CONSTRAINT content_reports_settled_is_decided
        CHECK ((settled_at IS NULL) = (verdict = ''))
);

-- THE QUEUE, which is the only read this table exists for: one school's open
-- reports, oldest first. Partial, because a settled report is history and every
-- row here eventually becomes one.
CREATE INDEX content_reports_open ON content_reports (tenant_id, reported_at)
    WHERE settled_at IS NULL;

-- ONE OPEN REPORT PER PERSON PER SECTION. Not a rate limit — it is what makes
-- the control idempotent: somebody who clicks twice, or who comes back a week
-- later still annoyed, should not put the same complaint in the queue twice.
-- Once it is settled they may report it again, which is the right behaviour for
-- a fix that did not work.
CREATE UNIQUE INDEX content_reports_one_open_each
    ON content_reports (tenant_id, account_id, course_id, lesson_id, section_id)
    WHERE settled_at IS NULL;

-- IDENTIFYING AND NOT PSEUDONYMOUS, which is the registry's word for the same
-- decision `notes` makes: what somebody puts in a free-text box is not for a
-- schema comment to assume. The two have to agree — a test compares this line
-- against `privacy.Registry` — and the one that is wrong decides what an export
-- contains. This said `pseudonymous` first, against a registry that said
-- otherwise, which is exactly the disagreement that test exists to catch.
COMMENT ON TABLE content_reports IS 'personal-data: identifying';

-- +goose Down

DROP TABLE content_reports;
