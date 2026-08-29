-- Every knob this platform has, in one table, with the set of names closed
-- somewhere else.
--
-- # THIS IS THE TABLE K-13 SPENT THREE PARAMETERS REFUSING
--
-- `internal/console/writes.go` opens by naming it and turning it down:
--
--     The shape that suggests itself is a `system_parameters` table — a name, a
--     value, a screen that edits any row of it. That is precisely what K-13
--     exists to refuse: a configuration surface grows to fill the space it is
--     given (…) Build the registry and the next value somebody wants to make
--     settable costs one INSERT and no argument.
--
-- That paragraph is right about the danger and wrong about where the fence
-- goes, and the difference is the whole of this migration.
--
-- # THE FENCE IS THE DECLARATION, NOT THE ABSENCE OF A TABLE
--
-- What K-13 actually protects is that a knob costs an argument. Three tables
-- for three parameters delivered that by making the mechanism expensive — which
-- worked while there were three, and stops working the moment the platform
-- wants fifteen: the cost of a migration per knob is paid by whoever is tired
-- enough to stop writing the sentence.
--
-- So the cost moves to where it belongs. A row here means nothing on its own:
-- `internal/platform/setting` holds the closed set of names, each with the unit
-- it is counted in, the bounds it must sit inside, the value it falls back to,
-- and the sentence saying what it decides — and a name absent from that set is
-- refused on the way in and ignored on the way out. Adding a knob still costs a
-- declaration and an argument. It no longer costs a table.
--
-- # WHY THE VALUE IS TEXT
--
-- Because the alternative is a column per type and a nullable set of them, and
-- a row whose meaning depends on which column is not null. The declaration
-- knows the type — that is what a declaration is for — so the column stores
-- what was typed and the reader parses against the shape that was declared. A
-- value that does not parse is a value the write refused, so the only way to
-- get one in here is by hand, and the reader falls back to the default and says
-- so out loud rather than guessing.
--
-- # REPLACED, AND THE AUDIT IS THE HISTORY
--
-- None of these is money. A price and a discount are dated series because K-14
-- asks that a March invoice stays explicable in November; what a pass mark was
-- in March is answered by `exam_attempts`, which records the mark each attempt
-- was judged by, and what a viewing lifetime was is answered by the viewing's
-- own expiry. The values that needed dating already have their own tables.
--
-- What is left is answered by the audit entry, which records both sides, who,
-- and when — for every write, because this console records before it acts
-- (K-01).

-- +goose Up

CREATE TABLE settings (
    -- THE NAME IS THE KEY AND IT IS NOT FREE TEXT, however much this column
    -- looks like it. `setting.Declared` is the closed set; a row whose name is
    -- not in it cannot be written through any route this platform has, and is
    -- ignored on the way out. The CHECK here is the shape of a name rather than
    -- the list of them: keeping the list in two places is keeping it in one and
    -- a half.
    name text PRIMARY KEY CHECK (name ~ '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$'),

    -- WHAT SOMEBODY TYPED, as they typed it. See the header for why this is one
    -- text column rather than a column per type.
    value text NOT NULL CHECK (length(trim(value)) > 0),

    -- WHEN IT LAST MOVED, so a screen can say how long this has been the
    -- answer. Who and why are the audit's; this is here so the list does not
    -- have to join to it to show an age.
    set_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE settings IS 'personal-data: none';

-- +goose Down

DROP TABLE settings;
