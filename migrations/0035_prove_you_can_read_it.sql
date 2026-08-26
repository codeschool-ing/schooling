-- Prove you can read it.
--
-- # A COLUMN HAS BEEN WAITING SINCE 0004
--
-- `accounts.email_verified_at` was added with a comment saying it is here
-- because adding it after there are accounts means guessing which of the
-- existing ones were verified. That was right, and then nothing ever wrote it.
-- The personal-data export reads it, so a person who asks for everything this
-- platform holds about them receives a field that has never had a value; and
-- `analysis/funnel.go` carries a step it cannot count, saying so out loud.
--
-- This is what writes it: a token that was sent to an address, and came back.
--
-- # THE TOKEN IS STORED AS A HASH, LIKE EVERY OTHER SECRET HERE
--
-- Session tokens and recovery codes are already kept this way, for the reason
-- that applies here too: a table somebody can read is a table somebody can use.
-- What is in the link is thirty-two random bytes; what is in this row is their
-- SHA-256, and the primary key is the hash because looking one up is the only
-- read this table has.
--
-- # IT REMEMBERS WHICH ADDRESS IT WAS SENT TO
--
-- `email` is not a copy of `accounts.email` kept for convenience — it is the
-- address the message actually went to, and redemption compares the two. A
-- token issued for ana@example.com must not verify an account that has since
-- become ana@somewhere-else.com, because the person who proved they could read
-- the mail proved it about the first address and nobody has proved anything
-- about the second. Changing an address is not built yet; this is the half of
-- it that cannot be added afterwards, for `email_verified_at`'s own reason.
--
-- # SPENT RATHER THAN DELETED
--
-- A redeemed row stays, with a timestamp. Deleting it would make "this link was
-- already used" and "this link never existed" the same answer — and those are a
-- person clicking twice and a person holding a forgery, which is the one
-- distinction a support conversation needs.
--
-- # AND A RESEND ADDS RATHER THAN REPLACES
--
-- This is deliberately the opposite of `IssueRecoveryCodes`, which replaces the
-- set. Reissuing recovery codes means "I think the old ones are compromised",
-- so the old ones must stop working. Asking for the confirmation mail again
-- means "the first one did not arrive" — and invalidating the first would break
-- the link in the message that was slow rather than lost, which is the message
-- most likely to be sitting in the inbox when the second arrives.
--
-- Nothing is swept. The expiry bounds how long a row can be used, and the rows
-- themselves are small, one per sign-up and per resend. A janitor would be a
-- scheduled job to delete a few thousand rows a year.

-- +goose Up

CREATE TABLE account_email_confirmations (
    -- SHA-256 of the token in the link. The link's own bytes are never here.
    token_hash bytea PRIMARY KEY,

    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- The address the message went to, which redemption compares against the
    -- account's current one. See the note above.
    email text NOT NULL CHECK (email <> '' AND email = lower(email)),

    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,

    -- Null until somebody follows the link. Never cleared.
    spent_at timestamptz,

    -- An expiry that is not after the issue is a row that was born unusable,
    -- and the caller that wrote it had its arithmetic backwards.
    CONSTRAINT confirmation_expires_after_it_is_made CHECK (expires_at > created_at)
);

-- The one read besides the primary key: everything outstanding for an account,
-- which is what a resend and a person's own record both ask for.
CREATE INDEX account_email_confirmations_by_account
    ON account_email_confirmations (account_id, created_at DESC);

-- What it holds about a person, said where somebody reading the schema with
-- psql and no Go can see it: the address itself, and not a hash of one.
COMMENT ON TABLE account_email_confirmations IS 'personal-data: identifying';

-- +goose Down

DROP TABLE account_email_confirmations;
