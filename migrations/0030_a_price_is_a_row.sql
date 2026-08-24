-- What the subscription costs at a school, as a series of dated rows.
--
-- # A PRICE IS NOT A FIELD (K-14)
--
-- It was one. `tenants.plan_price_cents` was set once and could be overwritten,
-- which reads as harmless and is the one shape a money parameter may not have:
-- the moment it is changed, "why was this person charged 490 when the site says
-- 590" stops being answerable. The column holds today's number and today's
-- number is the only thing it has ever held.
--
-- What money needs is the opposite property. A March invoice has to stay
-- explicable in November, and that means the OFFER has to be as much a matter
-- of record as the payment. `ledger_entries` has been append-only since it
-- existed, so what somebody actually paid is already unforgeable; this is the
-- other half of the same sentence, and until now it was the half that could be
-- edited.
--
-- # ONE COLUMN CARRIES BOTH MEANINGS
--
-- `effective_from` is when this price started applying AND, for a price set
-- from the console, when it was set. They are the same moment and there is no
-- second column claiming otherwise — a `set_at` beside it would be a value that
-- can disagree with its neighbour, and the pair would then need a rule about
-- which one a report believes.
--
-- It also means a price dated into the future is already representable. Nothing
-- sets one today and the console does not offer it, because a scheduled rise is
-- a second state to test for a feature nobody has asked for — but the column
-- means the right thing if that day comes, rather than having to be widened.
--
-- # NO PRICE IS NO ROWS
--
-- The column used zero for "not set", which made a free school and an unpriced
-- one the same number. Here a school with no rows has no offer, and the
-- invitation says what the subscription opens without claiming a figure — which
-- is what the interface already did with the zero.
--
-- # WHO SET IT IS NOT HERE
--
-- It is in the audit, where it is for the accent and for everything else the
-- console changes (K-01). A copy on this row would be a second answer to "who",
-- and the one that does not erase is the audit's.
--
-- # WHAT THIS DOES NOT YET HOLD
--
-- "A subscriber keeps the price they bought at." The series makes it possible to
-- say what the offer WAS on the day somebody took it, and nothing yet ties a
-- subscription to the row it was bought under. Two reasons it is not added here
-- rather than one: nothing would read it — there is no gateway, so no renewal
-- charges anything — and a subscription is platform-wide (N-02) while a price
-- is a school's, so the row a subscriber "bought at" is the offer they were
-- SHOWN rather than a property of what they hold. That is a decision to make
-- with the gateway in hand, and guessing at it now would put a column on
-- `subscriptions` that the person wiring the payment has to argue with.

-- +goose Up

CREATE TABLE school_prices (
    id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,

    -- IN CENTS, like every other amount in this repository: a price in a float
    -- is a price that is 489.99999 on some machine. Above zero, because "no
    -- price" is no row.
    cents integer NOT NULL CHECK (cents > 0),

    -- ISO 4217, which is three letters and is what Intl.NumberFormat wants. It
    -- is per row rather than per school, so a change of currency is dated like
    -- a change of number — they are the same kind of event to anybody reading
    -- an old invoice.
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),

    effective_from timestamptz NOT NULL DEFAULT now()
);

-- "What is the price at this school right now", which is asked on every request
-- that draws the offer. Descending, so the row in force is the first one the
-- index reaches.
CREATE INDEX school_prices_in_force
    ON school_prices (tenant_id, effective_from DESC);

-- APPEND-ONLY, BY THE SAME TRIGGER AS THE LEDGER, THE EVENTS AND THE AUDIT.
-- That is the whole point of this table: a price that can be edited is a price
-- that explains nothing, and a mistake is corrected by dating a new row rather
-- than by making the old one say something else.
CREATE TRIGGER school_prices_are_append_only
    BEFORE UPDATE OR DELETE ON school_prices
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

COMMENT ON TABLE school_prices IS 'personal-data: none';

-- THE COLUMN'S VALUE BECOMES THE FIRST ROW, dated to when the school was made
-- rather than to now. Dating it to now would say the price began today, which
-- is the one thing this table exists not to say — and the true date is not
-- knowable, because the column that held it kept no history. The school's own
-- creation is the earliest moment the price can have applied from, so it is the
-- honest floor rather than a guess dressed as a fact.
INSERT INTO school_prices (tenant_id, cents, currency, effective_from)
SELECT id, plan_price_cents, plan_currency, created_at
FROM tenants
WHERE plan_price_cents > 0;

-- AND THE COLUMNS GO, in the same migration that fills the table. Left in place
-- they would be a second thing claiming to hold the price — which is exactly
-- the failure `school.json`'s accent was deleted for: two places holding one
-- value is how the wrong one gets edited.
ALTER TABLE tenants
    DROP CONSTRAINT tenants_plan_currency_is_iso,
    DROP CONSTRAINT tenants_plan_price_is_not_negative,
    DROP COLUMN plan_currency,
    DROP COLUMN plan_price_cents;

-- +goose Down

ALTER TABLE tenants
    ADD COLUMN plan_price_cents integer NOT NULL DEFAULT 0,
    ADD COLUMN plan_currency    text    NOT NULL DEFAULT 'BRL';

UPDATE tenants t SET
    plan_price_cents = p.cents,
    plan_currency    = p.currency
FROM (
    SELECT DISTINCT ON (tenant_id) tenant_id, cents, currency
    FROM school_prices
    WHERE effective_from <= now()
    ORDER BY tenant_id, effective_from DESC
) p
WHERE p.tenant_id = t.id;

ALTER TABLE tenants
    ADD CONSTRAINT tenants_plan_price_is_not_negative CHECK (plan_price_cents >= 0),
    ADD CONSTRAINT tenants_plan_currency_is_iso CHECK (plan_currency ~ '^[A-Z]{3}$');

DROP TABLE school_prices;
