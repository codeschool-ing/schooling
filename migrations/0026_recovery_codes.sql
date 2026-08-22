-- A way back in that is not the authenticator app.
--
-- THE SIGN-IN SCREEN HAS BEEN PROMISING THIS SINCE THE SECOND FACTOR SHIPPED:
--
--     "Enter the code from your authenticator app, or a recovery code."
--
-- There were no recovery codes. Nothing issued one, no table held one, and the
-- present path only ever verified TOTP. A screen that asks for something the
-- system cannot accept is worse than one that does not offer it: the person
-- locked out reads the sentence, believes there is a way back, and looks for a
-- code that was never made.
--
-- WHY A TABLE AND NOT A KIND IN `account_credentials`. That table is keyed
-- `(account_id, kind)` — one secret per kind, by design, so that a second way in
-- is a row rather than a migration. Recovery codes are TEN rows per account,
-- each independently spendable, and the fact that one was spent is the
-- interesting part. A JSON array in a `secret` column would be all three
-- properties given up at once: no single-use marking, no per-code timestamps,
-- and a rewrite of the whole set to burn one.
--
-- HASHED, LIKE A SESSION TOKEN AND NOT LIKE A PASSWORD. A code is fifty bits
-- this system generated, not something a person chose and reused elsewhere —
-- there is nothing to guess, so SHA-256 is right and argon2id would be a
-- second's work to verify a code nobody can brute-force anyway. The same
-- argument `sessions.token_hash` already makes.
--
-- A SPENT CODE IS KEPT RATHER THAN DELETED. "Somebody used a recovery code at
-- 03:12" is exactly the sort of thing asked after an incident, and a deleted
-- row answers it with silence. The row holds no secret afterwards — the hash
-- was never reversible — so keeping it costs nothing a person could object to.

-- +goose Up

CREATE TABLE account_recovery_codes (
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- SHA-256 of the code, upper-cased with its separator removed. The code
    -- itself exists in exactly one place after it is issued: wherever the
    -- person put it.
    code_hash bytea NOT NULL,

    created_at timestamptz NOT NULL DEFAULT now(),

    -- Null until it is spent, and never cleared. Reissuing replaces the set
    -- rather than reviving a code.
    used_at timestamptz,

    PRIMARY KEY (account_id, code_hash)
);

-- The only query that matters on the way in: is there an unspent code for this
-- account with this hash. Partial, because a spent code is history rather than
-- a candidate.
CREATE INDEX account_recovery_codes_unspent
    ON account_recovery_codes (account_id)
    WHERE used_at IS NULL;

-- Pseudonymous and not identifying: an account id and a hash. It says nothing
-- about a person once the identity rows it points at are gone, which is the
-- distinction `0002` draws and the export path is built from.
COMMENT ON TABLE account_recovery_codes IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE account_recovery_codes;
