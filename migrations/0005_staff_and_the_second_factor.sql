-- Who operates this, and the second factor that is not optional for them.
--
-- STAFF IS A ROW ON AN ACCOUNT, NOT A SEPARATE ACCOUNT. Two people run this
-- platform and both of them are also students of it — they will study their own
-- material, and they will look at a screen and need to know whether they are
-- seeing it as staff or as themselves. One account with a role beside it makes
-- that one question; two accounts makes it a habit of remembering which browser
-- you are in.
--
-- THREE ROLES AND NO MORE (K-01). owner does everything including granting
-- roles; operator changes a student's plan, quarantines a question, reads the
-- audit; read-only sees every screen and writes nothing. A fourth role is a
-- decision about a person, and a role nobody can name the purpose of is a
-- permission nobody can reason about.
--
-- THE SECOND FACTOR IS ENFORCED ON THE SESSION, NOT ON THE ACCOUNT. `sessions`
-- gains `mfa_at`: null means the password was right and the second factor has
-- not been presented yet. That is what makes "mandatory MFA" true rather than
-- intended — an account with a role and a session that never showed a code
-- cannot reach a staff route, and there is no state in between.

-- +goose Up

CREATE TABLE staff (
    account_id uuid PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,

    role text NOT NULL CHECK (role IN ('owner', 'operator', 'read-only')),

    -- Who granted it. Null only for the first owner, who has nobody above
    -- them — every other row answers "who let this person in".
    granted_by uuid REFERENCES accounts(id) ON DELETE SET NULL,
    granted_at timestamptz NOT NULL DEFAULT now(),

    -- Set rather than deleted, so a person who left is distinguishable from a
    -- person who was never staff. Access checks read this; the audit reads the
    -- row for a name months later.
    revoked_at timestamptz
);

CREATE INDEX staff_current ON staff (role) WHERE revoked_at IS NULL;

-- The second factor on a session, which is where "mandatory" becomes a fact.
ALTER TABLE sessions ADD COLUMN mfa_at timestamptz;

COMMENT ON TABLE staff IS 'personal-data: pseudonymous';

-- +goose Down

ALTER TABLE sessions DROP COLUMN mfa_at;
DROP TABLE staff;
