-- Four purchases for one account, so the history table has something in it.
--
-- # WHY THIS IS A FIXTURE AND NOT A SEQUENCE THE SUITE PERFORMS
--
-- Every other state `a11y-test` measures is reached the way a person reaches
-- it: it signs up through the form, presses the button that starts a second
-- factor, chooses the card to make the instalment select appear. That is
-- deliberate and it is why the suite finds real defects — a state nobody can
-- reach from the screen is a state nobody has to be able to read.
--
-- A purchase cannot be reached that way. Buying needs a confirmed address, a
-- gateway key, and a payment somebody actually makes; the suite has no mail to
-- confirm with, and a check that waited for a Pix to clear would be a check
-- that never ran. The alternative to seeding is measuring the empty table,
-- which is the shape with no rows in it — and the rows are the whole thing.
--
-- # FOUR, BECAUSE THE FOUR DRAW DIFFERENTLY
--
--   paid, in one       the ordinary line, and a Pix discount to strike through
--   paid, in twelve    the split, which is the widest cell in the table
--   charged            dimmed, no date, and an address to finish paying at
--   paid, two days ago the seven-day withdrawal notice above the table
--
-- An `abandoned` row draws as `charged` does without the link, so it is the one
-- shape not seeded: it would add a row and no arrangement.
--
-- # IT IS KEYED BY ADDRESS AND NOT BY ID
--
-- The suite makes a new account every run and knows its address, not its id.
--
--   psql "$SCHOOLING_DATABASE_URL" -v ON_ERROR_STOP=1 -v email=... -f bought.sql

\set ON_ERROR_STOP on

-- THE PRICES ARE THE FIXTURE'S AND ARE NOT SEEDED HERE. `graph-test/fixture.sql`
-- publishes the platform's two terms and this file runs after it; publishing a
-- second set would append to an append-only series that every other suite
-- reads, and could not be taken back.
INSERT INTO checkout_intents
    (account_id, scope, price_id, cents, currency, method, instalments,
     provider, provider_charge_id, invoice_url, stage, created_at, updated_at)
SELECT a.id, 'all',
       -- THE ONE IN FORCE FOR THAT TERM, and not just any row: `plan_prices` is
       -- append-only and effective-dated (K-14), so a term has as many rows as
       -- it has ever had prices and `console-test` adds more as it runs.
       (SELECT p.id FROM plan_prices p
         WHERE p.scope = 'all' AND p.term_months = v.months
         ORDER BY p.effective_from DESC LIMIT 1),
       v.cents, 'BRL', v.method, v.instalments,
       'fixture', 'fx_' || v.tag || '_' || substr(a.id::text, 1, 8),
       'https://example.tld/pay/' || v.tag,
       v.stage, now() - v.ago, now() - v.ago
FROM (VALUES
    -- A year in Pix, four years ago: 69000 less the five per cent a Pix payment
    -- gets, so the table has a listed price to strike through.
    ('a', 12, 65550,  'pix',  1,  'paid',    interval '1460 days'),
    -- Two years on a card in twelve, three years ago.
    ('b', 24, 109000, 'card', 12, 'paid',    interval '1095 days'),
    -- And a Pix opened last week that nobody has paid.
    ('c', 12, 65550,  'pix',  1,  'charged', interval '7 days'),
    /* AND ONE PAID TWO DAYS AGO WHOSE EVENT HAS NOT ARRIVED.

       It is what opens the seven-day withdrawal notice, which is the only
       thing on that screen with its own colours and its own deadline and
       which nothing else here would draw — the two paid rows above are years
       old and the window on them shut long ago.

       AND IT IS A REAL STATE RATHER THAN A CONVENIENT ONE. A payment whose
       webhook has not landed is paid at the gateway and unknown here:
       delivery is Sequential, so one stuck event holds up every student
       behind it. Two days is a long outage and a fixture depicts a shape, but
       the shape is one this platform can have — and it is why the paywall
       checks further down still see a student with no access. */
    ('d', 12, 65550,  'pix',  1,  'paid',    interval '2 days')
) AS v(tag, months, cents, method, instalments, stage, ago)
JOIN accounts a ON a.email = :'email'
WHERE NOT EXISTS (
    SELECT 1 FROM checkout_intents c
    WHERE c.account_id = a.id AND c.provider = 'fixture'
);

/* ---------- and one of them records what it bought ----------

   THE TWO PAID ROWS DRAW DIFFERENTLY AND BOTH ARE REAL. A purchase says what
   it bought by way of the ledger row it produced and the subscription event
   that row caused; `0043` is what put the date on that event, so every sale
   made before it — including this platform's first two, in production — has a
   stage of `paid` and nothing to join.

   Seeding only the joined kind would have hidden the case that matters. The
   first version of the screen fell through to the stage word and told somebody
   their fully paid year was "not finished"; this fixture is what showed it.

   So: the card plan below gets the whole chain, and the older Pix keeps
   nothing — one row with a date, one row that has to say it does not have one.

   # AND THE TERM IT BUYS HAS ALREADY RUN OUT, WHICH IS NOT A DETAIL

   The subscription is seeded three years back for twenty-four months, so it
   expired a year ago and opens nothing. That is deliberate twice over.

   It has to. The suite measures the paywall on the same student a few checks
   later — a lesson behind the wall, a course behind the wall — and an active
   subscription makes both of those screens the ones without a wall on them.
   Seeding a live term turned two checks into failures that said the invite
   never arrived, which was true: there was nothing to invite anybody to.

   And it is the better state anyway. Expired is when somebody actually opens
   this screen: the courses stopped and nobody said why. It draws the facts,
   the table, AND the button back to subscribing, which is three things at once
   where a live subscription would have drawn two. */

WITH bought AS (
    SELECT c.id, c.account_id, c.cents, c.currency, c.provider, c.provider_charge_id,
           c.price_id, c.created_at
    FROM checkout_intents c
    JOIN accounts a ON a.id = c.account_id AND a.email = :'email'
    WHERE c.provider = 'fixture' AND c.provider_charge_id LIKE 'fx_b_%'
), money AS (
    INSERT INTO ledger_entries (account_id, kind, amount_cents, currency, source, source_ref)
    SELECT account_id, 'payment', cents, currency, provider, provider_charge_id
    FROM bought
    ON CONFLICT DO NOTHING
    RETURNING id, account_id
), plan AS (
    INSERT INTO subscriptions (account_id, scope, model, state, paid_through, price_id, started_at)
    -- `expired` and not `active`: see the header. The term ran out a year ago.
    SELECT b.account_id, 'all', 'instalments', 'expired',
           b.created_at + interval '24 months', b.price_id, b.created_at
    FROM bought b
    ON CONFLICT (account_id, scope) DO NOTHING
    RETURNING id, account_id, paid_through, price_id, started_at
)
INSERT INTO subscription_events
    (subscription_id, account_id, event, from_state, to_state, ledger_entry_id,
     price_id, paid_through, occurred_at)
-- The line as it was written the day it was PAID, which is why `to_state` is
-- active here and the row above says expired: the term ran out afterwards, and
-- an append-only log does not go back and change what happened.
SELECT p.id, p.account_id, 'paid', 'none', 'active', m.id,
       p.price_id, p.paid_through, p.started_at
FROM plan p JOIN money m ON m.account_id = p.account_id;
