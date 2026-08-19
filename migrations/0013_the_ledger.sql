-- Every movement of money, and none of them editable.
--
-- # WHAT THIS RECORDS, AND WHAT IT DELIBERATELY DOES NOT
--
-- It records money that MOVED: a payment received, a refund sent, a chargeback
-- taken back. One row per movement, signed from our side — positive is money
-- that came in, negative is money that went out — so the sum over an account is
-- what that person has net paid.
--
-- It does not record what somebody OWES. That is the subscription's business:
-- access is computed from the subscription and never from a payment record, so
-- a ledger that also tried to be a receivables system would be a second place
-- the paywall could be read from, and the two would disagree on the day one of
-- them was wrong.
--
-- # WHY NOT DOUBLE ENTRY
--
-- Because the second side would be a constant. Double entry earns its ceremony
-- when money moves BETWEEN accounts that both have to balance — splits to a
-- third party, payouts to a school, a payables ledger. All three were removed
-- from this system before it was built: one owner, no marketplace, no
-- school-to-platform billing. What is left is one counterparty and one bank
-- side, and a journal with an implicit contra account is that, written honestly.
--
-- The properties double entry is usually wanted FOR are here without it: rows
-- cannot be edited or deleted, a correction is a new row, and every reversal
-- points at what it reverses.
--
-- # NO tenant_id, ON PURPOSE
--
-- One login for the whole platform, and one subscription covering every school
-- (N-01, N-02). Money is owed by a person to the platform, not to a school, and
-- a tenant_id here would be a column with nothing to put in it — or worse,
-- something plausible, which is how a per-school subscription gets built by
-- accident.

-- +goose Up

CREATE TABLE ledger_entries (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- NO FOREIGN KEY, for the same reason `events` and `practice_review` have
    -- none: this row outlives the person.
    --
    -- Erasing somebody deletes the rows that give a uuid a meaning, which
    -- leaves these joinable to nobody. That is the only arrangement that
    -- satisfies both obligations at once — a record that money changed hands is
    -- a tax obligation and the other half of a bank statement, and it cannot be
    -- deleted on request; the person's identity can, and is.
    --
    -- A foreign key would force the choice the other way: ON DELETE CASCADE
    -- would destroy accounting records on an erasure, and RESTRICT would make
    -- erasure fail for anybody who ever paid us, which is the population that
    -- most obviously has the right to ask.
    account_id uuid NOT NULL,

    -- What kind of movement it was. A closed list, because a kind this code
    -- does not know is a row nothing can report on, and "other" is where a
    -- reporting system goes to stop being one.
    kind text NOT NULL CHECK (kind IN ('payment', 'refund', 'chargeback', 'adjustment')),

    -- THE AMOUNT IS CENTS AND THE COLUMN IS bigint. Not numeric, not money —
    -- numeric would accept a fraction of a cent from a driver that thought it
    -- was being helpful, and PostgreSQL's own `money` type carries a locale's
    -- decimal places as a server setting.
    --
    -- Signed: positive came in, negative went out. Zero is not a movement.
    amount_cents bigint NOT NULL CHECK (amount_cents <> 0),

    currency text NOT NULL CHECK (currency IN ('BRL', 'USD')),

    -- What it reverses, when it reverses something. A refund points at the
    -- payment it refunds; a payment points at nothing.
    --
    -- It is a real foreign key so that a reversal of a row that is not there is
    -- impossible, and the sign and currency rules — a reversal is the opposite
    -- sign, in the same currency, and never more than what is left un-reversed
    -- — are enforced in Go, inside the transaction that writes it, because they
    -- are an aggregate over sibling rows rather than a property of one.
    reverses uuid REFERENCES ledger_entries(id) ON DELETE RESTRICT,

    -- WHO SAID SO, AND UNDER WHICH REFERENCE. `source` is the payment provider
    -- or `manual`; `source_ref` is that provider's own id for the event.
    --
    -- This pair is what makes a webhook idempotent, and the guard is the unique
    -- index below rather than a table somebody remembers to check first. A
    -- gateway retries a webhook whenever it does not hear back in time — every
    -- one of them does, by design — so the same payment arriving twice is the
    -- normal case and not the exception. Read as a check-then-insert it is a
    -- race; written as a constraint on the row the money is on, the second
    -- insert loses and there is no code path around it.
    source     text NOT NULL CHECK (source <> ''),
    source_ref text,

    -- Free-form, for a human reading a row a year later.
    memo text NOT NULL DEFAULT '',

    occurred_at timestamptz NOT NULL DEFAULT now()
);

-- One entry per provider event. Partial, because a manual adjustment has no
-- provider reference and several of them are not a duplicate of each other.
CREATE UNIQUE INDEX ledger_entries_by_source_ref
    ON ledger_entries (source, source_ref) WHERE source_ref IS NOT NULL;

-- A person's own history, newest first, which is how it is read on a screen.
CREATE INDEX ledger_entries_by_account
    ON ledger_entries (account_id, occurred_at DESC);

-- What has already been reversed, which is the question asked before every
-- reversal is written.
CREATE INDEX ledger_entries_by_reversed
    ON ledger_entries (reverses) WHERE reverses IS NOT NULL;

COMMENT ON TABLE ledger_entries IS 'personal-data: pseudonymous';

-- Append-only, by the same trigger as the events and the audit. A correction is
-- a new row with the other sign, which is what `reverses` is for.
CREATE TRIGGER ledger_entries_are_append_only
    BEFORE UPDATE OR DELETE ON ledger_entries
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

-- +goose Down

DROP TABLE ledger_entries;
