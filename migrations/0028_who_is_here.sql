-- Where a session was last seen, so that "who is here now" has an answer.
--
-- # PRESENCE IS NOT AN EVENT, AND THAT IS K-06 RATHER THAN A HOLE IN K-03
--
-- Statistics come from the stream and never from current state, because current
-- state has been overwritten. Presence is the one question where being
-- overwritten is the point: nobody asks who was online last March, and the
-- stream could not answer it if they did — that would need an event for
-- LEAVING, which no browser reliably sends. A tab closed by a dying battery
-- emits nothing, so "still here" would be inferred from an absence, which is
-- the same arithmetic as this column and two tables further from it.
--
-- So this is current state, deliberately, and it is the only number in the
-- console that does not come from `events`.
--
-- # WHY IT IS NOT CALLED `tenant_id`
--
-- Because `sessions` is platform-wide (K-18) and has to keep saying so. An
-- account has no school (N-01) and neither does its session; what this records
-- is where the session was last USED, which is a fact about a moment rather
-- than about who the row belongs to. Named `tenant_id` it would join the
-- school-scoped set `tenant/schema_test.go` reads out of the catalogue, and the
-- schema would begin claiming that a session belongs to one school — which is
-- the exact thing N-01 spent the whole account design not claiming.
--
-- # THE HEARTBEAT MOVES FROM AN HOUR TO A MINUTE
--
-- `last_seen_at` has existed since phase 0 and was advanced at most once an
-- hour. That was right for the question it answered — "is this session still in
-- use", asked of a person's own list of sittings, where an hour is precision
-- nobody wants. It cannot answer "is somebody here now": a timestamp allowed to
-- be fifty-nine minutes stale reports an empty platform at its busiest, and
-- reports it confidently.
--
-- K-06 says a minute, and a minute is what `identity.Verify` now writes. The
-- write is still bounded — once per minute per session, not once per request —
-- and it still rides the query that authenticates, so the busiest read path in
-- the system gains no round trip.

-- +goose Up

ALTER TABLE sessions
    -- Null until this session is used on a school's address, and null forever
    -- for a session that only ever opens the console. A request to the
    -- platform's own address does not clear it: see `identity.Verify`, which
    -- coalesces rather than overwrites, so somebody who reads the landing page
    -- between two lessons does not vanish from the school they are studying in.
    ADD COLUMN last_seen_tenant uuid REFERENCES tenants(id) ON DELETE SET NULL;

-- THE PRESENCE READ, WHICH IS THE ONLY QUERY THIS COLUMN EXISTS FOR. It asks
-- for sessions seen since a moment a few minutes ago, so `last_seen_at` leads;
-- the three conditions that never vary live in the WHERE, which keeps the index
-- to the rows that can ever be an answer. Almost every row in this table is a
-- session nobody is using, and none of them is ever counted.
CREATE INDEX sessions_present ON sessions (last_seen_at DESC)
    WHERE revoked_at IS NULL AND viewed_by IS NULL AND last_seen_tenant IS NOT NULL;

-- +goose Down

DROP INDEX sessions_present;
ALTER TABLE sessions DROP COLUMN last_seen_tenant;
