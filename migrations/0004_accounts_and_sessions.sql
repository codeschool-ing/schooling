-- Who a student is, and how the server knows it is still them.
--
-- ONE ACCOUNT FOR THE WHOLE PLATFORM (N-01). There is no tenant_id on any table
-- here, and that is the decision rather than an omission: a person who studies
-- programming and mathematics is one person with one password, and the
-- subscription covering both is what makes that true (N-02). The privacy
-- boundary that matters is between STUDENTS, and that is `account_id` — which
-- is why it is the column every school-scoped table joins on.
--
-- THE SIGN-IN METHOD IS A ROW, NOT A COLUMN. `account_credentials` has a kind,
-- so adding a second way in later — an identity provider, a passkey — is a new
-- kind of row rather than a migration of the accounts table with a nullable
-- password column left behind in it. E-mail and password is what can be built
-- and tested today; the other two candidates both need infrastructure that is
-- still undecided.
--
-- A SESSION STORES A HASH AND NEVER THE TOKEN. The value in the cookie exists
-- in exactly one place, the browser. A database that is read — by a backup that
-- leaked, by a query somebody ran — hands over nothing that can be replayed.

-- +goose Up

CREATE TABLE accounts (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email      text NOT NULL CHECK (email <> '' AND email = lower(email)),
    name       text NOT NULL DEFAULT '',
    created_at timestamptz NOT NULL DEFAULT now(),

    -- Null until they prove they can read it. Nothing gates on this yet, and
    -- the column is here because adding it after there are accounts means
    -- guessing which of the existing ones were verified.
    email_verified_at timestamptz,

    -- SYNTHETIC STUDENTS ARE FLAGGED FROM THE FIRST ONE (K-11). The cohort and
    -- funnel screens are built before there is a population to make them
    -- legible, which means they are built against invented students — and an
    -- aggregate that cannot separate those is a first real cohort born
    -- polluted, with no way to clean it afterwards.
    synthetic boolean NOT NULL DEFAULT false,

    -- Their own, as opposed to the locale of the request they happen to be
    -- making. Denormalised onto events at emission like every other dimension.
    locale  text NOT NULL DEFAULT 'unknown' CHECK (locale <> ''),
    country text NOT NULL DEFAULT 'unknown' CHECK (country <> '')
);

-- Case-insensitively unique. Somebody who signed up as Ana@example.com and
-- comes back as ana@example.com is the same person, and a second account is a
-- support conversation rather than an error they can see.
CREATE UNIQUE INDEX accounts_by_email ON accounts (lower(email));

-- Every aggregate excludes synthetic students by default, so the index that
-- serves those aggregates excludes them too.
CREATE INDEX accounts_real_by_creation ON accounts (created_at DESC) WHERE NOT synthetic;

CREATE TABLE account_credentials (
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- One row per kind, so a second way in is a row rather than a migration.
    kind text NOT NULL CHECK (kind IN ('password', 'totp')),

    -- What it is depends on the kind, and in no case is it reversible to
    -- something that can be presented: an argon2id hash, or a TOTP secret that
    -- only ever produces six digits.
    secret text NOT NULL CHECK (secret <> ''),

    created_at timestamptz NOT NULL DEFAULT now(),
    -- A password changed is a fact somebody asks about after an incident.
    updated_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (account_id, kind)
);

CREATE TABLE sessions (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- SHA-256 of the token, never the token. See the header.
    token_hash bytea NOT NULL UNIQUE,

    created_at   timestamptz NOT NULL DEFAULT now(),
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    expires_at   timestamptz NOT NULL,

    -- Set rather than deleted, so "signed out at" survives and a session that
    -- was revoked can be told from one that never existed.
    revoked_at timestamptz,

    -- No IP address anywhere (K-05): an aggregated country carries far lighter
    -- obligations than an address, and the address answers no question this
    -- system asks. The user agent stays, because "which device was that" is
    -- the question a person actually asks about their own sessions.
    user_agent text NOT NULL DEFAULT ''
);

-- Listing a person's own sessions, which is what a security screen shows.
CREATE INDEX sessions_by_account ON sessions (account_id, created_at DESC);

-- Sweeping the expired ones. Partial, because a session that is already
-- revoked is not waiting to be cleaned up.
CREATE INDEX sessions_live_by_expiry ON sessions (expires_at) WHERE revoked_at IS NULL;

-- The link from a person to the browsers they arrived in could not have a key
-- until now, because there was no accounts table for it to point at. It gets
-- one here rather than later: a link naming an account nobody has is a funnel
-- number that counts somebody twice, and it is exactly the kind of row a
-- fixture leaves behind.
--
-- CASCADE, because this link is the one row that turns a visitor id back into a
-- person — so it has to go when the person does. `events` and `practice_review`
-- still carry no key by design: they are append-only, and severing them is what
-- erasure means. See 0002.
ALTER TABLE account_visitors
    ADD CONSTRAINT account_visitors_account_exists
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE;

COMMENT ON TABLE accounts            IS 'personal-data: identifying';
COMMENT ON TABLE account_credentials IS 'personal-data: identifying';
COMMENT ON TABLE sessions            IS 'personal-data: pseudonymous';

-- +goose Down

ALTER TABLE account_visitors DROP CONSTRAINT account_visitors_account_exists;
DROP TABLE sessions;
DROP TABLE account_credentials;
DROP TABLE accounts;
