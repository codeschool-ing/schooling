-- The certificate, and the page anybody can check it on.
--
-- # A CERTIFICATE IS A STATEMENT MADE ON A DAY
--
-- Everything it says is captured when it is issued: the student's name, the
-- title of what they passed, the school. None of it is read live. A course can
-- be renamed or removed from the catalogue entirely — the load job prunes what
-- the files no longer carry — and a certificate that read its title live would
-- silently start naming something else, or nothing.
--
-- That is the same decision, for the same reason, as `audit_log.actor_label`.
--
-- # THE CODE IS THE WHOLE HANDLE, SO IT HAS TO BE UNGUESSABLE
--
-- Verification takes no account and no session: somebody hiring reads a code
-- off a document and types it in. That means the code is the only thing
-- standing between a stranger and the fact that a named person studied a named
-- subject — so it is eighty bits from crypto/rand, not a sequence number and
-- not anything derived from the student.
--
-- It is unique across the platform rather than per school, because a code that
-- meant two different certificates would make verification ambiguous, and the
-- person checking has no way to tell which one they are looking at.
--
-- # IT GOES WHEN THE PERSON GOES
--
-- A certificate carries a name and is readable by anybody holding its code.
-- Keeping one after an erasure request would mean publishing the name of
-- somebody who asked to be forgotten, so it cascades with the account and the
-- verification page answers exactly the same way it does for a code that never
-- existed. Answering differently would say that a certificate was once there,
-- which is the fact being erased.
--
-- # WHAT IT DOES NOT CARRY
--
-- No score. The attempt it rests on has one, and the certificate points at the
-- attempt — but the public page asserts that the student passed, and the mark
-- they passed by is between them and the school. A verification page that
-- published a score would be a verification page that ranks people.

-- +goose Up

CREATE TABLE certificates (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- What a stranger types in. Stored canonically — upper case, no
    -- separators — and normalised on the way in, so a code read off a document
    -- and typed with dashes finds its certificate.
    code text NOT NULL CHECK (code <> ''),

    scope    text NOT NULL CHECK (scope IN ('course', 'track')),
    scope_id text NOT NULL CHECK (scope_id <> ''),

    -- The paper it rests on. Not for the score — for the question "which
    -- questions was this earned on", which is the one that matters the day a
    -- question is found to be broken.
    attempt_id uuid NOT NULL REFERENCES exam_attempts(id) ON DELETE CASCADE,

    -- Captured, never read live. See the top of this file.
    --
    -- A CERTIFICATE WITH NO NAME ON IT ASSERTS NOTHING, so there is no such
    -- thing: an account with no name has passed the exam — that is on the
    -- attempt — and can be issued its certificate the moment it has one.
    student_name text NOT NULL CHECK (student_name <> ''),
    title        text NOT NULL CHECK (title <> ''),
    school_name  text NOT NULL CHECK (school_name <> ''),

    issued_at timestamptz NOT NULL DEFAULT now()
);

-- ONE PER STUDENT PER EXAM. Passing twice does not produce a second document,
-- and the index is what says so rather than a check somebody has to remember.
CREATE UNIQUE INDEX certificates_one_per_exam
    ON certificates (tenant_id, account_id, scope, scope_id);

CREATE INDEX certificates_by_student
    ON certificates (tenant_id, account_id, issued_at DESC);

-- Platform-wide, deliberately. See the top of this file.
CREATE UNIQUE INDEX certificates_by_code ON certificates (code);

-- A certificate never changes. Deletion is how an erasure removes one, so the
-- trigger is on UPDATE alone — the same shape, for the same reason, as the one
-- on a handed-in exam.
CREATE FUNCTION refuse_to_change_a_certificate() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION
        'a certificate is a statement made on a day and cannot be edited: % is refused. '
        'Something that needs to change is a new certificate, or none.',
        TG_OP
        USING ERRCODE = 'restrict_violation';
END;
$$;

CREATE TRIGGER certificates_are_never_edited
    BEFORE UPDATE ON certificates
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_a_certificate();

COMMENT ON TABLE certificates IS 'personal-data: identifying';

-- +goose Down

DROP TABLE certificates;
DROP FUNCTION refuse_to_change_a_certificate();
