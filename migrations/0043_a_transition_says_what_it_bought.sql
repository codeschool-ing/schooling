-- What a transition bought, written down beside the fact that it happened.
--
-- # THE LOG SAID WHEN AND NOT WHAT
--
-- `subscription_events` has recorded, since 0014, both sides of every
-- transition and the ledger row that caused it. That answers "why was I locked
-- out on Tuesday" and it is the reason the table exists.
--
-- It does not answer the question a student actually opens their account to
-- ask: what have I bought, over the years, and what did each of those purchases
-- get me? The event says `paid` and the ledger beside it says how much money
-- moved — and for an instalment plan that is ONE INSTALMENT, because the ledger
-- is keyed by the charge and a plan is collected several times. Neither says
-- the term, and neither says the date access then ran to.
--
-- So the two facts that make a line of that history readable are added here.
--
-- # BOTH ARE NULLABLE AND THEY HAVE TO BE
--
-- Rows written before this migration have neither, and there is nothing to
-- backfill them with that would not be a guess. `price_id` could be copied from
-- the subscription, but that is TODAY's price on a row from a year ago — which
-- is the exact confusion this column exists to remove. `paid_through` could be
-- recomputed by folding the terms forward, and would be wrong for anybody whose
-- subscription was ever refunded or cancelled.
--
-- A null here means "written before the log recorded this", which a screen can
-- say. A wrong number means the history lies about a purchase, which is worse
-- than the history being short.
--
-- # NO FOREIGN KEY ON price_id, FOR THE SAME REASON AS THE REST OF THE TABLE
--
-- 0014's header: this table holds ids and no keys, because the trigger below it
-- refuses DELETE and a cascade would make erasing a person fail outright. A
-- price is never deleted either — `plan_prices` is append-only — so the key
-- would never dangle; it is left off because the table's rule is "ids, not
-- keys", and one exception is how a rule stops being a rule.
--
-- `ledger_entry_id` is the exception that already exists, and 0014 argued for
-- it explicitly. Two exceptions is a different table.

-- +goose Up

ALTER TABLE subscription_events
    -- The `plan_prices` row this subscription stood at when the transition
    -- happened. On a `paid` line that is what was just bought; on a
    -- cancellation it is what is being given up.
    ADD COLUMN price_id uuid,

    -- Where the term stood AFTER it. On a payment this is the answer to "what
    -- did that buy me" — the whole point — and it is stored rather than
    -- computed because an early renewal ADDS to the term it finds, so the
    -- arithmetic depends on a row that has since moved on.
    ADD COLUMN paid_through timestamptz;

-- +goose Down

ALTER TABLE subscription_events
    DROP COLUMN price_id,
    DROP COLUMN paid_through;
