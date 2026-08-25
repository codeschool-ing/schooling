-- Truncating is changing history too.
--
-- # THE GUARANTEE HAD A HOLE AND IT WAS THE OBVIOUS ONE
--
-- Six tables carry `events_are_append_only` and its siblings: a row-level
-- `BEFORE UPDATE OR DELETE` trigger that raises. It is what makes "a correction
-- is a new row, never an edit to an old one" a fact about the database rather
-- than a habit.
--
-- POSTGRES DOES NOT FIRE ROW TRIGGERS ON `TRUNCATE`. It is a separate event,
-- with its own trigger kind, and a statement that empties an append-only table
-- entirely was therefore the one edit the guard allowed. The strongest possible
-- change to history went through the gap left for the weakest.
--
-- It was found while writing `cmd/reset`, which needed to empty exactly these
-- tables — and could have done so without the schema noticing. A tool that gets
-- its way by walking through a hole in a guarantee teaches the next reader that
-- the guarantee is decorative.
--
-- # THE TRIGGER IS PER STATEMENT AND NOT PER ROW
--
-- `TRUNCATE` has no rows to offer, which is the point of it. `FOR EACH
-- STATEMENT` is the only form available and it is the right one: what is being
-- refused is the statement.
--
-- # AND `cmd/reset` DISABLES THESE BY NAME
--
-- Deliberately, and inside its transaction. Emptying this platform's history
-- before it has any students is a legitimate thing to do exactly once; doing it
-- by finding a gap would be the same act with nothing written down. Turning a
-- named guard off in one place, in code somebody can read, is the difference.

-- +goose Up

-- +goose StatementBegin
CREATE FUNCTION refuse_to_empty_history() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION
        '% is append-only: TRUNCATE is refused. Emptying it is `cmd/reset`, which disables this trigger by name and says why.',
        TG_TABLE_NAME
        USING ERRCODE = 'restrict_violation';
END;
$$;
-- +goose StatementEnd

CREATE TRIGGER events_are_not_emptied
    BEFORE TRUNCATE ON events
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

CREATE TRIGGER practice_review_is_not_emptied
    BEFORE TRUNCATE ON practice_review
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

CREATE TRIGGER audit_log_is_not_emptied
    BEFORE TRUNCATE ON audit_log
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

CREATE TRIGGER ledger_entries_are_not_emptied
    BEFORE TRUNCATE ON ledger_entries
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

CREATE TRIGGER subscription_events_are_not_emptied
    BEFORE TRUNCATE ON subscription_events
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

CREATE TRIGGER school_prices_are_not_emptied
    BEFORE TRUNCATE ON school_prices
    FOR EACH STATEMENT EXECUTE FUNCTION refuse_to_empty_history();

-- +goose Down

DROP TRIGGER school_prices_are_not_emptied ON school_prices;
DROP TRIGGER subscription_events_are_not_emptied ON subscription_events;
DROP TRIGGER ledger_entries_are_not_emptied ON ledger_entries;
DROP TRIGGER audit_log_is_not_emptied ON audit_log;
DROP TRIGGER practice_review_is_not_emptied ON practice_review;
DROP TRIGGER events_are_not_emptied ON events;
DROP FUNCTION refuse_to_empty_history;
