-- A discount is dated, for the reason a price is.
--
-- # THE CONSTANT WAS RIGHT AND ITS OWN COMMENT SAID WHEN IT WOULD STOP BEING
--
-- `PixDiscountBasisPoints` is five per cent, and `billing/http.go` argued it
-- through K-13 already: the value has no right answer, so the case for setting
-- it from the console is real, and it lost to a different question — whether a
-- March invoice stays explicable in November. The comment ends:
--
--     The day somebody wants to change it without a deploy, it becomes a dated
--     row like the prices — not a column that can be overwritten.
--
-- That day is this one. What follows is that shape.
--
-- # DATED AND NOT REPLACED, THOUGH REPLACED WOULD HAVE BEEN DEFENSIBLE
--
-- Worth writing down, because the easy version of this argument is wrong.
--
-- The March invoice is ALREADY explicable without this table. A checkout stores
-- what was charged and points at the `plan_prices` row it was sold under, so
-- the discount on any past sale is the difference between two recorded numbers.
-- Nothing here is needed to reconstruct it, and a column that could be
-- overwritten would not lose a single answer about money that moved.
--
-- It is dated for the question money does NOT answer: what were we offering in
-- March, on the days nobody bought. A rate that was live for a fortnight and
-- sold nothing leaves no trace at all in `checkout_intents`, and "did the
-- campaign do anything" is exactly the question somebody asks about a fortnight
-- that sold nothing.
--
-- It also costs almost nothing to date it. `plan_prices` is the template, the
-- series is drawn on the same screen, and one shape read twice is cheaper than
-- two shapes that have to be told apart.
--
-- # WHY IT IS NOT A COLUMN ON `plan_prices`
--
-- Because it does not vary with the term. Five per cent off is five per cent
-- off the year and off the two years, and a column would make that a fact
-- repeated per row — three rows to change to move one number, and nothing
-- stopping them from disagreeing. The key here is the METHOD, which is what the
-- discount is actually about.
--
-- # AND WHY THE METHOD IS TEXT
--
-- `billing.Method` is 'pix' or 'card' and the discount exists because a Pix
-- costs this platform less to receive. A second method with its own rate is a
-- row rather than a migration — which is the same argument `plan_prices` makes
-- for `term_months` being a number rather than a name.
--
-- NO DISCOUNT IS NO ROW. Zero is a rate somebody chose and the absence of a row
-- is a method nobody has discounted; the reader falls back to nothing off, and
-- both come to the same charge by two different truths.

-- +goose Up

CREATE TABLE plan_discounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- WHAT THIS COVERS, spelled exactly as `plan_prices.scope` and
    -- `subscriptions.scope` are: 'all' while one subscription opens every
    -- school (N-02), a school's id on the day that narrows (N-03).
    scope text NOT NULL DEFAULT 'all' CHECK (scope <> ''),

    -- WHICH WAY OF PAYING IS CHEAPER TO RECEIVE. `billing.Method`'s vocabulary,
    -- as text, so a third method is a row.
    method text NOT NULL CHECK (method <> ''),

    -- IN BASIS POINTS, which is hundredths of a per cent: 500 is five per cent.
    -- Integer for the reason every amount here is an integer — a rate in a
    -- float is a rate that is 4.9999 on some machine — and the arithmetic that
    -- applies it (`Money.Percent`) already speaks this unit.
    --
    -- ABOVE ZERO AND UNDER A HALF. Zero is "no discount", which is no row; and
    -- a discount over fifty per cent is a typed digit rather than an offer,
    -- which is the mistake this column can least afford. The console refuses
    -- earlier and says why; this is the fence behind it.
    basis_points integer NOT NULL CHECK (basis_points > 0 AND basis_points <= 5000),

    effective_from timestamptz NOT NULL DEFAULT now()
);

-- THE READ IS "THE NEWEST WHOSE DAY HAS COME", per scope and method — the same
-- read `plan_prices` gets and the same index shape, because it is the same
-- question asked about a different number.
CREATE INDEX plan_discounts_in_force
    ON plan_discounts (scope, method, effective_from DESC);

/* APPEND-ONLY, BY THE SAME TRIGGER AS `plan_prices`, THE LEDGER AND THE AUDIT.

   This was missing from the first version of this migration and the omission
   is worth naming rather than quietly correcting: everything else here — the
   header, `console/writes.go`'s entry, the screen — says the discount is
   APPENDED like the price, and a series that can be edited is a series that
   explains nothing. The claim was in the prose and not in the schema, which is
   the shape of a guarantee that holds until the first person who does not know
   about it.

   A mistake is corrected by dating a new row, exactly as it is for a price. */
CREATE TRIGGER plan_discounts_are_append_only
    BEFORE UPDATE OR DELETE ON plan_discounts
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

-- And not emptied either, for `0034`'s reason: truncating is changing history
-- with a bigger hammer.
CREATE TRIGGER plan_discounts_are_not_emptied
    BEFORE TRUNCATE ON plan_discounts
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

COMMENT ON TABLE plan_discounts IS 'personal-data: none';

/* AND THE RATE IN FORCE TODAY, SEEDED, because the interface has been quoting
   five per cent since before this table existed and a deployment that woke up
   charging full price for a Pix would be changing an offer by migrating.

   'all' ALWAYS, PLUS ANY SCOPE THAT HAS A PRICE. The first half is what N-02
   guarantees — one subscription opens every school — and it is what an empty
   database needs: a deployment migrated before anything was priced would
   otherwise seed nothing and start charging full price for a Pix, which is the
   offer changing by migration. The second half is for a deployment that has
   already narrowed (N-03) and prices per school.

   DATED TO THE OLDEST PRICE IT COULD HAVE APPLIED TO, and to now when there is
   none: it did apply then, and a series claiming this rate began with the
   migration would be the one lie a dated table can tell. */
INSERT INTO plan_discounts (scope, method, basis_points, effective_from)
SELECT s.scope, 'pix', 500,
       coalesce((SELECT min(effective_from) FROM plan_prices WHERE scope = s.scope), now())
FROM (SELECT 'all' AS scope UNION SELECT scope FROM plan_prices) AS s;

-- +goose Down

DROP TABLE plan_discounts;
