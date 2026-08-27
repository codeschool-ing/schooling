-- A subscription remembers what it was bought at.
--
-- # HALF OF THIS SHIPPED IN 0030 AND THE OTHER HALF IS HERE
--
-- That migration turned the price into a SERIES: `school_prices`, append-only
-- by the same trigger as the ledger, with `effective_from`. It replaced
-- `tenants.plan_price_cents`, a column that could be overwritten — and the
-- moment one was, "why was this person charged 490 when the site says 590"
-- stopped being answerable.
--
-- What it could not do alone is the other side of that sentence. A subscription
-- knows its model, its scope, its state and the date access runs to. It does
-- not know WHICH price it was sold at, so a school raising its price silently
-- raises it for everybody who already bought — or forces a renewal to guess by
-- comparing dates, which is exactly the deduction 0030 went to the trouble of
-- removing.
--
-- # IT IS NOT NULL, AND THAT IS ONLY POSSIBLE TODAY
--
-- Nothing creates a subscription: there is no payment gateway, `cmd/seed` does
-- not write one, and `billing.Begin` has no caller outside its own tests. The
-- table is empty, so the column can be required rather than optional.
--
-- A YEAR FROM NOW IT COULD NOT BE. Adding it to a table with rows means either
-- a nullable column that half the code has to check, or backfilling a guess —
-- and a guess about what somebody was charged is the one guess this schema
-- exists to prevent. `email_verified_at` was added early for the same reason
-- and this is that lesson applied on purpose rather than in hindsight.
--
-- So the guard below REFUSES rather than backfills. If a deployment somewhere
-- has subscriptions, this migration stops and says what to decide; it does not
-- invent a price for them.
--
-- # WHICH ROW, GIVEN THAT A SUBSCRIPTION COVERS EVERY SCHOOL
--
-- One subscription covers every school today (N-02) and `scope` says `all`.
-- Prices, meanwhile, are per school — `school_prices.tenant_id` — because that
-- is where a person sees an offer and decides to pay.
--
-- So the row this points at is THE ONE THAT WAS IN FORCE AT THE SCHOOL WHERE
-- THE PURCHASE HAPPENED. It is not a second decision: it is the only price the
-- platform has, it is the number the person actually read, and `tenant_id` on
-- the row records which door they came in by without a second column here.
--
-- When `scope` narrows to a school (N-03), this stops needing that sentence and
-- simply means what it says.

-- +goose Up

-- +goose StatementBegin
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM subscriptions) THEN
        RAISE EXCEPTION
            'subscriptions already has rows, and this migration will not invent '
            'a price for them. Decide what each one was sold at, write it, and '
            'then make the column NOT NULL — a backfilled guess about what '
            'somebody was charged is the thing school_prices exists to prevent.';
    END IF;
END
$$;
-- +goose StatementEnd

ALTER TABLE subscriptions
    ADD COLUMN price_id uuid NOT NULL REFERENCES school_prices(id);

COMMENT ON COLUMN subscriptions.price_id IS
    'The school_prices row in force when this was bought. Renewals charge it, '
    'not whatever is current.';

-- "Who is still on the old price", which is the question a school asks the day
-- after it raises one — and the question a renewal run answers per row.
-- Postgres does not index a foreign key on its own.
CREATE INDEX subscriptions_by_price ON subscriptions (price_id);

-- +goose Down

DROP INDEX subscriptions_by_price;
ALTER TABLE subscriptions DROP COLUMN price_id;
