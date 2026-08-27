-- An address can be changed.
--
-- # THE ROOM WITH NO WAY OUT
--
-- `0037` gave the platform a suppression list, and v0.11.0 gave the banner a
-- sentence for it: your address refused our mail, so we stopped writing to it.
-- True, useful, and a dead end — because nothing on this platform could change
-- an address. The person told exactly what was wrong could do nothing about it.
--
-- It gets worse on the day confirmation gates paying, which is the plan: an
-- address that refuses our mail would then stop somebody from buying, from a
-- screen that explains why and offers no remedy. This is the remedy, and it has
-- to exist first.
--
-- # THE ADDRESS CHANGES WHEN THE NEW ONE IS PROVED, NOT WHEN IT IS TYPED
--
-- A row here is a change that has not happened yet. `accounts.email` keeps the
-- old address until somebody follows the link that went to the new one — so a
-- typo is a link nobody can click rather than an account nobody can reach, and
-- the failure mode of this feature is "nothing happened" instead of "your
-- account now belongs to an address that does not exist".
--
-- # WHY THIS IS NOT `account_email_confirmations` WITH A COLUMN
--
-- That table's redemption carries a condition `0035` describes as the half of
-- an address change that cannot be added afterwards:
--
--     AND lower(a.email) = c.email
--
-- A token issued for one address must not confirm another. A change is the one
-- operation that deliberately does the opposite — the link proves the address
-- WRITTEN ON IT, and that address then becomes the account's. Merging the two
-- would mean loosening that condition and telling the two cases apart by a
-- flag, in the statement where being wrong means a stale link moving somebody's
-- account to an address they abandoned.
--
-- So: two tables, and the old condition is not touched. The cost is a second
-- copy of the token-and-expiry machinery. The benefit is that the guard which
-- cannot be added later also cannot be weakened later.
--
-- A useful accident falls out of it. The confirmation link already sitting in
-- the OLD inbox stops working the moment the address changes, because its own
-- condition stops matching — the existing guard does the right thing here
-- without knowing this feature exists.
--
-- # WHAT IT HOLDS ABOUT A PERSON
--
-- The address itself, not a hash: redemption has to WRITE it onto the account,
-- so it cannot be one-way. That makes this `identifying`, like the confirmations
-- table beside it, and it goes with the account by cascade.

-- +goose Up

CREATE TABLE account_email_changes (
    -- SHA-256 of the token in the link. The link's own bytes are never here.
    token_hash bytea PRIMARY KEY,

    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- The address being moved TO, which is not the account's yet and may never
    -- be. Lowercased on the way in, for the reason `accounts.email` is.
    email text NOT NULL CHECK (email <> '' AND email = lower(email)),

    created_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz NOT NULL,

    -- Null until somebody follows the link. Never cleared, for the reason the
    -- confirmations table gives: deleting it makes "already used" and "never
    -- existed" the same answer, and those are a double click and a forgery.
    spent_at timestamptz,

    CONSTRAINT change_expires_after_it_is_made CHECK (expires_at > created_at)
);

-- TWO READS, AND THE SECOND IS THE INTERESTING ONE. Showing somebody what is
-- outstanding needs this; so does the cap on how many of these an account may
-- ask for in an hour, which is what stops an authenticated session from being a
-- way to post mail to strangers under this platform's name.
CREATE INDEX account_email_changes_by_account
    ON account_email_changes (account_id, created_at DESC);

-- What it holds about a person, said where somebody reading the schema with
-- psql and no Go can see it: an address, and not a hash of one — because
-- redemption has to write it onto the account.
COMMENT ON TABLE account_email_changes IS 'personal-data: identifying';

-- +goose Down

DROP TABLE account_email_changes;
