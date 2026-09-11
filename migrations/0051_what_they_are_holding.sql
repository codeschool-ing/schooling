-- What kind of thing the person was on, as a fifth dimension of an event.
--
-- # WHY IT IS ON THE EVENT AND NOT ON THE VISITOR
--
-- `visitors` already carries first touch — where somebody came from the first
-- time, never overwritten — and a device column there would answer "what did
-- they ARRIVE on". That is one real question and it is not the one worth the
-- column: people arrive on a phone in a queue and study on a laptop in the
-- evening, which the schema has said out loud since `0002` ("a person arrives
-- on a phone, subscribes on a laptop, and both are them").
--
-- On the event it answers "what were they on WHEN they did this", which is the
-- question behind every use of it: whether the drill is finished as often on a
-- phone, whether the exam is ever sat on one, whether the arrivals that convert
-- are the ones on a keyboard.
--
-- It is also the only place that gets `synthetic` and the school for free.
-- Every aggregate on this platform excludes the seeded population by default
-- (K-11) and is scoped to one school; a breakdown read straight from `visitors`
-- could do neither, because that table has neither column — so it would be the
-- one report here counting a different population from all the others, with
-- both numbers correct by their own definition and neither reconcilable.
--
-- # FOUR WORDS, AND THE FOURTH IS NOT A GAP
--
-- `phone`, `tablet`, `computer`, `unknown`. The words live in
-- `internal/platform/device`, where a test holds them, for the reason no closed
-- list lives in a schema: a CHECK naming them here would be a second copy to
-- keep in step.
--
-- `unknown` is a real answer and will be a large share of the rows. Only
-- Chromium sends the hints this is read from; the page reports one for
-- everybody else, and a browser doing neither is honestly unknown. A screen
-- that folded that row into the largest bucket would be reporting Chromium and
-- calling it the audience.
--
-- # AND IT IS DELIBERATELY COARSE
--
-- Three shapes and a shrug, and there is no way in the code to record more:
-- no model, no screen size, no operating system version. That is not modesty,
-- it is what keeps this column out of fingerprint territory — granularity is
-- the thing that turns a dimension into an identifier, and the table it would
-- identify people in is the one that survives their erasure orphaned.
--
-- The existing rows are `unknown` and that is not a guess: they were written
-- before anything looked, so nothing was known about them.

-- +goose Up

-- NOT NULL WITH A DEFAULT, LIKE ITS FOUR NEIGHBOURS. A caller that does not
-- know says so with a word rather than leaving a blank that reads the same as
-- having forgotten — which is the rule the four dimensions above it already
-- carry, enforced the same way.
ALTER TABLE events ADD COLUMN device text NOT NULL DEFAULT 'unknown'
    CHECK (device <> '');

-- THE BREAKDOWN'S INDEX, and it is partial for the reason the seeded index is:
-- every aggregate reads the real population, and a read that says so can use an
-- index that holds only those rows.
CREATE INDEX events_by_school_and_device
    ON events (tenant_id, device, occurred_at DESC) WHERE NOT synthetic;

-- +goose Down

DROP INDEX events_by_school_and_device;
ALTER TABLE events DROP COLUMN device;
