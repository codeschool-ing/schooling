-- Where a school's own site is, and a shape for the colour it is drawn in.
--
-- # THE LINK THAT POINTED AT SOMEBODY ELSE
--
-- The account menu offered "Go to the site" and sent every student of every
-- school to codeschool.ing, because that address was written into the
-- interface when there was one school. A school without a site of its own now
-- has no link rather than a link to a competitor's.
--
-- It is a column and not a convention (`https://<slug>.<platform domain>`)
-- because a school's marketing site is wherever that school put it, which is
-- usually somewhere this platform has never heard of.
--
-- # AND THE COLOUR HAS A SHAPE
--
-- `accent` has been here since the first migration and nothing ever applied it;
-- the interface does now, straight into a custom property. A value that is not
-- a colour would land in a stylesheet, so the shape is checked here rather than
-- hoped for: six hex digits, or empty for "use the palette's".
--
-- WHAT THIS CANNOT CHECK IS WHETHER IT IS READABLE. Contrast depends on the
-- page behind it and there are two of them, so it is measured in the browser —
-- see `ui/app/accent.js`, which keeps the palette's blue for whichever theme
-- the school's colour fails and says so. When a staff console grows a colour
-- picker, that is where somebody should be told before they save it, not after
-- a student cannot read the screen.

-- +goose Up

ALTER TABLE tenants
    ADD COLUMN site text NOT NULL DEFAULT '';

COMMENT ON COLUMN tenants.site IS
    'the school''s own site, linked from the account menu; empty means no link';

ALTER TABLE tenants
    ADD CONSTRAINT tenants_accent_is_a_colour
    CHECK (accent = '' OR accent ~ '^#[0-9a-fA-F]{6}$');

-- # AND WHAT THE SUBSCRIPTION COSTS HERE
--
-- The interface offered every school's students `R$ 490` — one school's price,
-- with one school's currency symbol written into the markup beside it.
--
-- IN CENTS, like every other amount in this repository: a price in a float is a
-- price that is 489.99999 on some machine. Zero means the school has not set
-- one, and the invitation then says what the subscription opens without
-- claiming a number.
--
-- WHAT IS NOT PER SCHOOL is the SHAPE of the offer: the first course of every
-- track free and one yearly subscription for the rest. That is the platform's
-- product decision (N-04, and `assets/plans.js` argues it at length), and a
-- school that wanted a different shape would need a different paywall, not a
-- different row.

ALTER TABLE tenants
    ADD COLUMN plan_price_cents integer NOT NULL DEFAULT 0,
    ADD COLUMN plan_currency    text    NOT NULL DEFAULT 'BRL';

COMMENT ON COLUMN tenants.plan_price_cents IS
    'what the yearly subscription costs at this school, in cents; 0 = not set';

ALTER TABLE tenants
    ADD CONSTRAINT tenants_plan_price_is_not_negative CHECK (plan_price_cents >= 0),
    -- ISO 4217, which is three letters and is what Intl.NumberFormat wants.
    ADD CONSTRAINT tenants_plan_currency_is_iso CHECK (plan_currency ~ '^[A-Z]{3}$');

-- +goose Down

ALTER TABLE tenants
    DROP CONSTRAINT tenants_plan_currency_is_iso,
    DROP CONSTRAINT tenants_plan_price_is_not_negative,
    DROP COLUMN plan_currency,
    DROP COLUMN plan_price_cents;

ALTER TABLE tenants DROP CONSTRAINT tenants_accent_is_a_colour;
ALTER TABLE tenants DROP COLUMN site;
