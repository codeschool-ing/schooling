-- What somebody is paying for, and the record of how it got that way.
--
-- # ONE ROW OF STATE, ONE LOG BESIDE IT
--
-- The same arrangement as `practice_state` and `practice_review`: the current
-- state is overwritten in place, and every transition that produced it is
-- appended to a log that cannot be edited.
--
-- Both halves are needed and neither is the other. The paywall reads the state
-- on every request and has to be one indexed lookup, not a fold over a history.
-- And when somebody says "I was locked out on Tuesday and I had paid", the
-- answer is in the log — a mutable row alone would have overwritten the only
-- evidence of what happened.
--
-- # ONE SUBSCRIPTION PER ACCOUNT PER SCOPE, AND IT IS REUSED
--
-- A lapsed subscription that pays again becomes active on the SAME row. It is
-- not a new subscription: the person is the same, their progress is the same,
-- and "recovery restores access with progress intact" is the shape of that.
-- The history of it is the log, which is why the row can be reused without
-- losing anything.
--
-- `scope` is 'all' today and exists because N-03 says so: one subscription
-- covers every school, and the column is what lets that narrow later without a
-- migration on a table with money attached to it.
--
-- # NO tenant_id, ON PURPOSE
--
-- One login for the whole platform, one subscription covering every school
-- (N-01, N-02). A tenant_id here would be a column with nothing to put in it,
-- or worse something plausible — which is how a per-school subscription gets
-- built by accident.

-- +goose Up

CREATE TABLE subscriptions (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- CASCADE here and not on ledger_entries, and the difference is the point.
    -- A subscription says whether somebody may study; it means nothing once
    -- there is nobody. A ledger row says money changed hands, which is a tax
    -- obligation and outlives the person as an orphan.

    -- 'all', or a school slug. See N-03.
    scope text NOT NULL DEFAULT 'all' CHECK (scope <> ''),

    -- WHICH OF THE TWO MACHINES. An instalment plan is one authorisation split
    -- by the issuer: we are paid once, there is no monthly charge for us to see
    -- fail, and so it has no grace and no suspension. Recurring has both. They
    -- are different state machines rather than one with a flag — see
    -- internal/billing/subscription.go.
    model text NOT NULL CHECK (model IN ('recurring', 'instalments')),

    -- The closed list. A state not on it cannot be written, and a state this
    -- code does not recognise opens nothing — the paywall defaults closed.
    state text NOT NULL CHECK (state IN
        ('active', 'grace', 'suspended', 'cancelled', 'expired', 'ended')),

    -- The date access runs to. It is part of the state rather than a detail
    -- beside it: two transitions are the passage of time reaching it.
    paid_through timestamptz NOT NULL,

    started_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- One per account per scope, which is what makes "the subscription" a thing
-- rather than a query somebody has to sort.
CREATE UNIQUE INDEX subscriptions_by_account ON subscriptions (account_id, scope);

-- The two questions a job asks: who has lapsed, and who needs telling that
-- their term is nearly over.
CREATE INDEX subscriptions_by_paid_through ON subscriptions (paid_through)
    WHERE state IN ('active', 'cancelled');

COMMENT ON TABLE subscriptions IS 'personal-data: pseudonymous';

/* ---------- and how it got there ---------- */

-- APPEND-ONLY MEANS NO FOREIGN KEY TO EITHER, and the two facts are the same
-- fact: the trigger below refuses DELETE, so a cascade from the subscription or
-- the account would not tidy these rows away — it would make erasing a person
-- fail outright, on everybody who ever subscribed.
--
-- So this holds ids and no keys, like `events` and `practice_review`. After an
-- erasure the rows are still there and join to nobody, next to the ledger rows
-- they explain — which is what lets a dispute be reconstructed a year later
-- without the person being in it.
CREATE TABLE subscription_events (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id uuid NOT NULL,
    account_id      uuid NOT NULL,

    -- BOTH SIDES OF THE TRANSITION, not just the new one. "It became suspended"
    -- does not say whether the retries ran out or somebody was suspended from
    -- active by mistake, and that is exactly the question asked when a student
    -- says they were locked out while paying.
    event      text NOT NULL CHECK (event <> ''),
    from_state text NOT NULL CHECK (from_state <> ''),
    to_state   text NOT NULL CHECK (to_state <> ''),

    -- The ledger row that caused it, when money did. Nullable because a
    -- cancellation and an elapsed term are not payments.
    --
    -- This one IS a real key, and it can be: a ledger row is never deleted —
    -- the trigger on it refuses — so the reference can never be left dangling
    -- and never blocks anything.
    ledger_entry_id uuid REFERENCES ledger_entries(id) ON DELETE RESTRICT,

    occurred_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX subscription_events_by_subscription
    ON subscription_events (subscription_id, occurred_at DESC);

COMMENT ON TABLE subscription_events IS 'personal-data: pseudonymous';

CREATE TRIGGER subscription_events_are_append_only
    BEFORE UPDATE OR DELETE ON subscription_events
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

-- +goose Down

DROP TABLE subscription_events;
DROP TABLE subscriptions;
