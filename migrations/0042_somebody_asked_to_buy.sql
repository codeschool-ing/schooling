-- Somebody asked to buy, and the gateway has to be able to say who.
--
-- # A WEBHOOK ARRIVES HOLDING THEIR IDS AND NOTHING ELSE
--
-- An event about a payment names a charge — `pay_zea0d0i0xe51tc34` — and a
-- customer, and both are the gateway's own strings. Nothing in that tells this
-- platform whose subscription it is, which price it was sold under, or what
-- term it bought. Without a row written BEFORE the charge exists, the honest
-- answer to "what did this payment buy" is a guess from the amount.
--
-- So `checkout_intents` is written first, its id travels to the gateway as
-- `externalReference`, and it comes back on the charge and on every event about
-- it. The webhook then names a row here rather than only one there.
--
-- # THE ROW EXISTS BEFORE THE GATEWAY IS CALLED, AND THAT ORDER IS THE POINT
--
-- Calling first and recording afterwards has one failure mode and it is the bad
-- one: the charge is created, the write fails, and there is now a payable
-- invoice belonging to nobody. Recording first fails the other way — a row in
-- `opened` that never became a charge, which is a person who clicked and saw an
-- error, and is evidence rather than a liability.
--
-- # WHAT IS CHARGED IS NOT THE PRICE, AND BOTH ARE HERE
--
-- `price_id` is the offer taken; `cents` is what we actually asked for. They
-- differ the moment a Pix discount exists — five per cent off R$ 590 is
-- R$ 560,50 — and they would differ again if instalments ever carried interest.
-- ROADMAP.md draws this line already: renewal charges the PRICE and not the
-- amount paid, because a discount is a property of one purchase and interest is
-- a cost of it, and a renewal that confused either would bill the wrong number
-- with total confidence.
--
-- The term is NOT copied here. It is on the price row, one join away, and a
-- second copy is a second answer to "how long did this buy".
--
-- # AND WHO THEY ARE AT THE GATEWAY IS A TABLE OF ITS OWN
--
-- Charging in Brazil requires the payer's CPF or CNPJ — the gateway refuses to
-- create a charge for a customer without one, which the sandbox said in as many
-- words. This platform collects it, sends it, and DOES NOT KEEP IT. What stays
-- is `payment_customers`: an account, a provider, and the opaque handle that
-- provider answered with. The identifying number lives where it is legally
-- required, which is at the processor, and on this side there is a string that
-- means nothing anywhere else.
--
-- It is a table rather than a column on `accounts` for two reasons. A person
-- paying from abroad will have a handle at a different provider, and one column
-- cannot hold two. And `accounts` belongs to identity, which has no business
-- knowing that a payment gateway exists.
--
-- THE PRIVACY NOTICE SAYS THIS IN BOTH LANGUAGES, and it says it now rather
-- than when a screen first asks for a number. That was going to be deferred —
-- "publish it when it is true" — and a test refused: a table that holds
-- personal data and is not accounted for in the policy fails the build. The
-- test is right. The obligation attaches to the table existing, not to the
-- first row landing in it.
--
-- # WHAT ERASURE DOES TO EACH OF THEM
--
-- The link goes and the transaction stays, which is the arrangement
-- `ledger_entries` already uses and for the same two obligations at once.
--
-- `payment_customers` is DELETED: it is the join between a person and a
-- processor, nothing legally obliges us to keep it, and a row that survived
-- would be a way to find them again. Note what it cannot do — deleting our row
-- does not delete their customer at the gateway, which holds the tax id under
-- its own retention rules.
--
-- `checkout_intents` is ORPHANED, so `account_id` carries NO foreign key here
-- for the reason the ledger's does not. A chargeback can arrive months after
-- somebody has gone, and "what was this payment for" has to stay answerable —
-- but the identity that makes it theirs is deleted, which leaves these rows
-- joinable to nobody.

-- +goose Up

CREATE TABLE payment_customers (
    -- NO FOREIGN KEY IS MISSING HERE: this one cascades on purpose, because
    -- erasing the person is exactly when this row should stop existing.
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- Which gateway this handle is at. One person will have two the day the
    -- international provider ships, which is why this is half of the key.
    provider text NOT NULL CHECK (provider <> ''),

    -- Their string for this person. Opaque, and deliberately the only thing
    -- kept: the CPF that had to be sent to create it is not here.
    customer_id text NOT NULL CHECK (customer_id <> ''),

    created_at timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (account_id, provider)
);

-- "Whose is this customer id", which is the read a webhook does when an event
-- carries a customer and no reference of ours.
CREATE UNIQUE INDEX payment_customers_by_handle
    ON payment_customers (provider, customer_id);

COMMENT ON TABLE payment_customers IS 'personal-data: pseudonymous';

CREATE TABLE checkout_intents (
    -- THIS ID IS WHAT THE GATEWAY CARRIES BACK. It goes out as
    -- `externalReference` and returns on the charge and on every event about
    -- it, which is why it is generated here rather than taken from them.
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- NO FOREIGN KEY, so that erasing the person leaves this row pointing at
    -- nothing rather than deleting it. See the header.
    account_id uuid NOT NULL,

    -- What the subscription would cover, in the word `subscriptions.scope` and
    -- `plan_prices.scope` both use.
    scope text NOT NULL DEFAULT 'all' CHECK (scope <> ''),

    -- The offer taken. NOT NULL: a purchase that cannot say which price it was
    -- made under is the thing `plan_prices` exists to prevent.
    price_id uuid NOT NULL REFERENCES plan_prices(id),

    -- WHAT WE ACTUALLY ASKED FOR, which is the price less any discount. See the
    -- header: this is not a denormalised copy, it is a different fact.
    cents integer NOT NULL CHECK (cents > 0),
    currency text NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),

    -- How it is being paid. There is no debit: the gateway does not sell it.
    method text NOT NULL CHECK (method IN ('pix', 'card')),

    -- How the issuer splits it, which changes nothing about what the platform
    -- is owed. One is a single payment and is the only value Pix may have.
    instalments integer NOT NULL DEFAULT 1 CHECK (instalments >= 1),
    CONSTRAINT pix_is_not_split CHECK (method = 'card' OR instalments = 1),

    provider text NOT NULL CHECK (provider <> ''),

    -- Null until the gateway has been asked. A row that stays this way is
    -- somebody who clicked and got an error, and it is kept for that reason.
    provider_charge_id text,

    -- Where the payer goes. Theirs, and null for the same window.
    invoice_url text,

    /* HOW FAR THIS PURCHASE GOT.

       `opened`    written, gateway not yet asked
       `charged`   the gateway has a charge and the payer has somewhere to go
       `paid`      a payment event settled it and the subscription was started
       `abandoned` the charge expired, was deleted, or was never paid

       IT IS `stage` AND NOT `state`, and the difference in the word is the
       point: `subscriptions.state` is what access is computed from (K-15) and
       nothing here opens anything. They are two answers to two questions about
       the same person on the same day, and a screen that confused them would
       tell somebody they are paid up because their checkout reached the
       gateway. */
    stage text NOT NULL DEFAULT 'opened'
        CHECK (stage IN ('opened', 'charged', 'paid', 'abandoned')),

    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- ONE ROW PER CHARGE, WHICH IS WHERE THE WEBHOOK LANDS. Partial, because
-- `opened` rows have no charge yet and several of them are ordinary — somebody
-- clicking twice on a slow connection makes two, and only one becomes a charge.
CREATE UNIQUE INDEX checkout_intents_by_charge
    ON checkout_intents (provider, provider_charge_id)
    WHERE provider_charge_id IS NOT NULL;

-- "What has this person tried to buy", which the account screen asks and a
-- person disputing something asks louder.
CREATE INDEX checkout_intents_by_account
    ON checkout_intents (account_id, created_at DESC);

COMMENT ON TABLE checkout_intents IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE checkout_intents;
DROP TABLE payment_customers;
