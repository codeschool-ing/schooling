-- A price is the platform's, and it says what it buys.
--
-- # THE QUESTION 0030 PARKED, ANSWERED WITH THE GATEWAY IN HAND
--
-- That migration ends with a paragraph headed WHAT THIS DOES NOT YET HOLD, and
-- the sentence in it is this one:
--
--     a subscription is platform-wide (N-02) while a price is a school's, so
--     the row a subscriber "bought at" is the offer they were SHOWN rather than
--     a property of what they hold. That is a decision to make with the gateway
--     in hand, and guessing at it now would put a column on `subscriptions`
--     that the person wiring the payment has to argue with.
--
-- The gateway is in hand. This is that decision.
--
-- # ONE SUBSCRIPTION AND TWO PRICES IS AN ARBITRAGE, NOT A DETAIL
--
-- N-02 sells one subscription that opens every school. `school_prices` charged
-- for it per school. With one school that was invisible. With two priced
-- differently it decides the price by WHICH LINK SOMEBODY CLICKED: if `code.`
-- asks 590 and `math.` asks 390, the rational purchase is through `math.`, and
-- it opens `code.` as well. That is not a loophole somebody has to find — it is
-- the dominant move, available to anybody who reads both pages.
--
-- `0036` did the honest thing available to it, pointing `subscriptions.price_id`
-- at "the price in force at the school where the purchase happened". That is
-- correct bookkeeping and it is not a defence: it records which door they came
-- in by, at the number that door displayed.
--
-- So the price rises to what it prices. `tenant_id` becomes `scope`, spelled
-- exactly as `subscriptions.scope` is — `'all'` today, a school's id on the day
-- N-03 narrows. Then "which price applies to this subscription" is two columns
-- being equal, rather than a rule somebody has to remember; and when scope does
-- narrow, both halves already speak the same word.
--
-- # AND A PRICE WITHOUT A TERM CANNOT PRICE THREE PRODUCTS
--
-- The plan is annual, biennial and (abroad) monthly. One number per scope
-- cannot say which of those it is. `term_months` is what one purchase buys, as
-- a NUMBER rather than a name, because it is arithmetic before it is a label:
-- `paid_through` is this many months on, and a name would need a table in Go
-- mapping it back to the number the date is computed from. A quarterly offer,
-- if it ever exists, is then a row rather than a migration.
--
-- THE MIGRATED ROWS ARE 12 AND THAT IS NOT A GUESS. The interface has been
-- quoting this price with `cycle: 'per year'` since before it was a table —
-- `ui/assets/plans.js` still says so. The number on the screen was annual; this
-- writes down what it already meant.
--
-- # CURRENCY IS STILL NOT PART OF THE KEY, DELIBERATELY
--
-- A series is per (scope, term), and a change of currency is a new row in it —
-- which is what `0030` chose and said why: "a change of currency is dated like
-- a change of number, they are the same kind of event to anybody reading an old
-- invoice". Selling the same term in BRL and in USD at once is a real thing and
-- it arrives with the international gateway, together with the question of how
-- a visitor is assigned one. Widening the key before that is inventing an
-- answer to a question nobody has asked yet, and the same discipline that
-- deferred THIS migration defers that one.
--
-- # WHY A NEW TABLE RATHER THAN FIVE ALTERS
--
-- `school_prices` is append-only by trigger, so filling two new columns would
-- have to disable the guard that is the whole point of the table. Building the
-- new shape and copying into it never lifts it. The ids are carried across, so
-- `subscriptions.price_id` keeps pointing at the same row rather than at a copy
-- of it.
--
-- # AND IT REFUSES RATHER THAN GUESSES
--
-- Collapsing several schools' series into one is only meaningful if they say
-- the same thing. If they disagree, this migration stops and says so, exactly
-- as `0036` stops rather than inventing a price for a subscription. A number
-- somebody was charged is the one thing this table exists not to make up.

-- +goose Up

-- +goose StatementBegin
DO $$
DECLARE
    shapes integer;
BEGIN
    SELECT count(*) INTO shapes FROM (
        SELECT DISTINCT array_agg((cents, currency, effective_from)
                                  ORDER BY effective_from, cents, currency) AS series
        FROM school_prices
        GROUP BY tenant_id
    ) s;

    IF shapes > 1 THEN
        RAISE EXCEPTION
            'the schools do not all charge the same thing, and this migration '
            'will not pick a winner. One subscription opens every school '
            '(N-02), so one of these numbers is what the platform charges. '
            'Decide which, write it as a new row at every school, and run this '
            'again — the old rows stay either way, which is what the series is '
            'for.';
    END IF;
END
$$;
-- +goose StatementEnd

CREATE TABLE plan_prices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- WHAT THIS PRICE COVERS, in the same word `subscriptions.scope` uses:
    -- 'all' while one subscription opens every school (N-02), a school's id on
    -- the day that narrows (N-03). The two columns are compared, so they are
    -- spelled the same on purpose.
    --
    -- It is text and not a foreign key for that reason: 'all' is not a row in
    -- `tenants` and never will be.
    scope text NOT NULL DEFAULT 'all' CHECK (scope <> ''),

    -- HOW LONG ONE PURCHASE BUYS, in months. Twelve is the annual plan, 24 the
    -- biennial, 1 the monthly one abroad. A number because `paid_through` is
    -- computed from it and a name would only have to be turned back into one.
    term_months integer NOT NULL CHECK (term_months > 0),

    -- IN CENTS, like every other amount in this repository: a price in a float
    -- is a price that is 489.99999 on some machine. Above zero, because "no
    -- price" is no row.
    cents integer NOT NULL CHECK (cents > 0),

    -- ISO 4217, which is three letters and is what Intl.NumberFormat wants. It
    -- is per row rather than part of the key, so a change of currency is dated
    -- like a change of number — they are the same kind of event to anybody
    -- reading an old invoice.
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),

    effective_from timestamptz NOT NULL DEFAULT now()
);

-- "What does a year cost right now", which is asked on every request that draws
-- the offer. Descending, so the row in force is the first one the index
-- reaches; the term is in the key because a page asks for one product and not
-- for the whole catalogue.
CREATE INDEX plan_prices_in_force
    ON plan_prices (scope, term_months, effective_from DESC);

-- APPEND-ONLY, BY THE SAME TRIGGER AS THE LEDGER, THE EVENTS AND THE AUDIT.
-- That is the whole point of this table: a price that can be edited is a price
-- that explains nothing, and a mistake is corrected by dating a new row rather
-- than by making the old one say something else.
CREATE TRIGGER plan_prices_are_append_only
    BEFORE UPDATE OR DELETE ON plan_prices
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

-- And not emptied either, for `0034`'s reason: truncating is changing history
-- with a bigger hammer.
CREATE TRIGGER plan_prices_are_not_emptied
    BEFORE TRUNCATE ON plan_prices
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

COMMENT ON TABLE plan_prices IS 'personal-data: none';

-- THE SERIES CARRIES OVER WITH ITS IDS. `DISTINCT ON` because the schools all
-- said the same thing — the guard above refused otherwise — so one school's
-- series IS the platform's, and the first id for each dated row is the one
-- `subscriptions.price_id` may already point at.
INSERT INTO plan_prices (id, scope, term_months, cents, currency, effective_from)
SELECT DISTINCT ON (effective_from, cents, currency)
       id, 'all', 12, cents, currency, effective_from
FROM school_prices
ORDER BY effective_from, cents, currency, id;

-- The foreign key moves with the rows. It is dropped and remade rather than
-- edited because that is the only way Postgres offers.
ALTER TABLE subscriptions
    DROP CONSTRAINT subscriptions_price_id_fkey,
    ADD CONSTRAINT subscriptions_price_id_fkey
        FOREIGN KEY (price_id) REFERENCES plan_prices(id);

COMMENT ON COLUMN subscriptions.price_id IS
    'The plan_prices row this subscription was bought under, which is what '
    'explains its own term. Renewal charges the price in force at the time of '
    'renewal — see the terms of use, which promise 30 days notice and at most '
    'one rise in twelve months. Superseded 0036, which said the opposite.';

DROP TABLE school_prices;

-- +goose Down

CREATE TABLE school_prices (
    id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    cents     integer NOT NULL CHECK (cents > 0),
    currency  text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    effective_from timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX school_prices_in_force
    ON school_prices (tenant_id, effective_from DESC);

CREATE TRIGGER school_prices_are_append_only
    BEFORE UPDATE OR DELETE ON school_prices
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

CREATE TRIGGER school_prices_are_not_emptied
    BEFORE TRUNCATE ON school_prices
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

COMMENT ON TABLE school_prices IS 'personal-data: none';

-- EVERY SCHOOL GETS THE PLATFORM'S SERIES BACK, which is the only reading of
-- the data that loses nothing. One of them keeps the original ids so that
-- `subscriptions.price_id` still resolves; the others get fresh ones, because
-- an id cannot be in two rows.
INSERT INTO school_prices (id, tenant_id, cents, currency, effective_from)
SELECT CASE WHEN t.first THEN p.id ELSE gen_random_uuid() END,
       t.id, p.cents, p.currency, p.effective_from
FROM plan_prices p
CROSS JOIN (
    SELECT id, row_number() OVER (ORDER BY slug) = 1 AS first FROM tenants
) t
WHERE p.scope = 'all';

ALTER TABLE subscriptions
    DROP CONSTRAINT subscriptions_price_id_fkey,
    ADD CONSTRAINT subscriptions_price_id_fkey
        FOREIGN KEY (price_id) REFERENCES school_prices(id);

DROP TABLE plan_prices;
