-- What comes back from the post.
--
-- # SENDING WITHOUT LISTENING IS HOW A NEW DOMAIN BURNS ITS OWN REPUTATION
--
-- The platform started sending in v0.9.0 and has been deaf ever since. An
-- address that refuses us permanently — the mailbox is gone, the server
-- blocklists us, the person pressed "this is spam" — goes on being written to,
-- and every attempt after the first is a mark against the domain with the
-- providers that decide whether ANYBODY else's mail arrives.
--
-- One address nobody can reach costs one person a confirmation link. A hundred
-- attempts at it costs every future student their inbox.
--
-- # IT HOLDS A HASH AND NOT AN ADDRESS, AND THAT IS THE WHOLE DESIGN
--
-- A suppression list is the one record that has to survive an erasure. Somebody
-- asks to be forgotten, we delete the row, they sign up again with the same
-- address a month later — and we write to a mailbox that already refused us,
-- for the same reason as the first time.
--
-- Keeping the address instead would be keeping a person's data after they asked
-- us not to. The two obligations look irreconcilable and are not: what this
-- table has to answer is "may I write to THIS address", and a SHA-256 answers
-- it exactly. It cannot be read back into a list of addresses, it cannot be
-- searched for anybody, and it survives an erasure while holding nothing that
-- was erased.
--
-- Session tokens, recovery codes and confirmation links are all kept this way.
-- This is the same arrangement pointed at a different problem.
--
-- # ONLY WHAT IS PERMANENT
--
-- Three reasons, and every one of them means the same thing operationally:
-- never write to this address again.
--
--   hard_bounce  the address does not exist, or the domain does not
--   blocked      the receiving side refuses us for this address
--   complaint    the person marked us as spam
--
-- A SOFT BOUNCE IS NOT HERE AND MUST NOT BE. It is a mailbox that is full or a
-- server that is having an afternoon — the Proton outage of 27 August 2026,
-- which held every message to a whole provider for two hours, would have
-- suppressed every address on it. The platform punishing itself for somebody
-- else's cooling failure is the exact mistake this column excludes.
--
-- # NOTHING TAKES A ROW OUT YET
--
-- A person whose mailbox is fixed should be able to be reachable again, and
-- there is no path for that today. It is a decision about who may ask and how
-- it is proved, and inventing one here would be inventing it in the dark. What
-- exists is the row, its reason and when — which is everything such a path
-- would need.

-- +goose Up

CREATE TABLE mail_suppressions (
    -- SHA-256 of the address, lowercased and trimmed before hashing. The
    -- primary key, because looking one up is the only read this table has.
    address_hash bytea PRIMARY KEY,

    -- Why we stopped. All three mean the same refusal; which one is a support
    -- conversation rather than a decision, so the FIRST is kept and later
    -- events only bump the count below.
    reason text NOT NULL CHECK (reason IN ('hard_bounce', 'blocked', 'complaint')),

    first_seen_at timestamptz NOT NULL DEFAULT now(),

    -- A provider retries a webhook it did not hear back from, so the same event
    -- arriving twice is the normal case rather than the exception. These two
    -- make a repeat visible instead of invisible.
    last_seen_at timestamptz NOT NULL DEFAULT now(),
    times        integer NOT NULL DEFAULT 1 CHECK (times > 0)
);

-- What it holds about a person, said where somebody with psql and no Go can
-- read it: a hash and never an address, which is what lets it outlive an
-- erasure without holding anything that was erased.
COMMENT ON TABLE mail_suppressions IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE mail_suppressions;
