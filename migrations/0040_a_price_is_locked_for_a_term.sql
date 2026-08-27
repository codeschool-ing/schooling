-- A price is locked for a term, and not for ever.
--
-- # A COMMENT IN THIS DATABASE CONTRADICTS THE DOCUMENT THAT BINDS US
--
-- `0036` set this on the column, and it is in production:
--
--     'The school_prices row in force when this was bought. Renewals charge it,
--      not whatever is current.'
--
-- The terms of use say the opposite, and have since before that migration was
-- written. `internal/legal/documents/terms.en.md`, under *Paying*:
--
--     "The price you subscribe at is the price you keep. A price change applies
--      to new subscriptions AND TO RENEWALS, never retroactively to one that is
--      running.
--
--      If we do change a price, we will tell you at least 30 days before it
--      takes effect, and you can cancel before it does. We will not raise a
--      price more than once in any twelve months."
--
-- Both cannot be true. The terms are the document a person could act against,
-- so the terms are right and the column comment is wrong — and it is wrong in
-- the direction that would have been discovered by a subscriber, years from
-- now, being charged something the schema had quietly promised they would not.
--
-- # WHAT ACTUALLY WENT WRONG, WHICH IS SUBTLER THAN A WRONG SENTENCE
--
-- K-14 says money parameters are effective-dated and never overwritten, and
-- illustrates it: "whoever already subscribed keeps the price they bought at".
--
-- That illustration is doing two jobs and only one of them is right. WITHIN A
-- TERM it is exactly right and it is the whole reason `price_id` exists: what
-- somebody agreed to cannot change under them while they are paying it, and a
-- March invoice has to stay explicable in November. AT RENEWAL it is a
-- different claim — that the price is theirs for ever — and nobody decided
-- that. It arrived as a reading of an example.
--
-- The core of K-14 is untouched: a price is a row with a validity period rather
-- than a mutable field. That is what makes either policy explicable afterwards,
-- and it is why this migration changes a sentence and not a schema.
--
-- # WHAT RENEWAL WILL DO, WRITTEN BEFORE ANYTHING DOES IT
--
-- Charge the price in force AT THE MOMENT OF RENEWAL, with the notice and the
-- limits the terms already promise. `price_id` keeps meaning what it always
-- meant — the offer this subscription was taken under — which is what answers
-- "why was this person charged 490 when the site says 590" for the term they
-- bought. It stops meaning "and for every term after it".
--
-- Nothing is charging anything yet: `billing.Begin` has no caller and there is
-- no gateway. That is the reason this is a comment and not an incident, and it
-- is also the reason to fix it now — the next person to write the renewal would
-- have read the column and done what it said.

-- +goose Up

COMMENT ON COLUMN subscriptions.price_id IS
    'The school_prices row this subscription was bought under, which is what '
    'explains its own term. Renewal charges the price in force at the time of '
    'renewal — see the terms of use, which promise 30 days notice and at most '
    'one rise in twelve months. Superseded 0036, which said the opposite.';

-- +goose Down

COMMENT ON COLUMN subscriptions.price_id IS
    'The school_prices row in force when this was bought. Renewals charge it, '
    'not whatever is current.';
