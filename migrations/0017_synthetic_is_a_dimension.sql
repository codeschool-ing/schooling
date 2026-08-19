-- Whether the person an event is about is a real one.
--
-- # WHY IT IS A DIMENSION AND NOT A JOIN
--
-- Synthetic students are excluded from every aggregate by default (K-11), and
-- events carry their dimensions denormalised rather than joining for them
-- (K-04). This is where those two rules meet, and it belongs to Fase 0's list
-- for the usual reason: an event emitted without it cannot grow one afterwards.
--
-- Joining to `accounts` instead fails twice over. Half the funnel is visitors
-- who have no account at all, so there would be nothing to join to — and
-- erasing a person deletes the account row on purpose, which would turn every
-- event they left behind from "a real student" into "unknown" retroactively.
-- A report that changes when somebody asks to be forgotten is not a report.
--
-- # THE DEFAULT IS `false` AND THAT IS THE SAFE DIRECTION
--
-- An event that arrives without saying is counted as real. The wrong answer is
-- a seeded student inflating a cohort, and the way to get that wrong is to
-- default to "real" for something seeded — which is exactly why the seeder
-- writes the flag itself rather than relying on a default. Every row that
-- exists today predates any synthetic population, so `false` is not a guess.

-- +goose Up

ALTER TABLE events ADD COLUMN synthetic boolean NOT NULL DEFAULT false;

-- THE REPORTING INDEXES GAIN THE FILTER RATHER THAN A SECOND SET. Every
-- aggregate excludes synthetic by default, so the default read is the one that
-- has to be fast — and an index that served both would be an index that serves
-- the rare case at the cost of the common one.
DROP INDEX events_by_school_and_time;
CREATE INDEX events_by_school_and_time ON events (tenant_id, occurred_at DESC)
    WHERE NOT synthetic;

DROP INDEX events_by_name_and_time;
CREATE INDEX events_by_name_and_time ON events (name, occurred_at DESC)
    WHERE NOT synthetic;

-- And one that does not filter, for the screen that turns the switch on. It is
-- narrow on purpose: including synthetic students is a deliberate act with a
-- banner on it, not a thing anybody does by accident.
CREATE INDEX events_by_school_including_synthetic
    ON events (tenant_id, occurred_at DESC) WHERE synthetic;

-- +goose Down

DROP INDEX events_by_school_including_synthetic;

DROP INDEX events_by_name_and_time;
CREATE INDEX events_by_name_and_time ON events (name, occurred_at DESC);

DROP INDEX events_by_school_and_time;
CREATE INDEX events_by_school_and_time ON events (tenant_id, occurred_at DESC);

ALTER TABLE events DROP COLUMN synthetic;
