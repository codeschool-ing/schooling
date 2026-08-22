-- `console` is a label no school may take.
--
-- The list this joins was written before the console existed and said so:
--
--     'admin',   -- the console, wherever it ends up living
--
-- It ended up living at `console.<platform domain>`, which is the name every
-- other document in this repository uses. So the list gains that one and KEEPS
-- `admin` — taking a name off it is strictly worse than leaving one on, and the
-- comment simply stops being a promise.
--
-- IT GOES ON BEFORE THE CONSOLE ANSWERS ANYWHERE, which is the whole point.
-- `0003_reserved_labels.sql` says what the alternative costs: a school created
-- at a name the platform later wants, discovered when somebody adds the address
-- the school already took, and fixed by renaming a school that students have
-- bookmarked — "the one kind of change this project has already decided it will
-- not make quietly".
--
-- A CHECK constraint cannot be extended, only replaced. Postgres validates the
-- new one against every existing row as it is added, so a school already called
-- `console` would fail this migration rather than be silently grandfathered —
-- which is the right way round: there is no such school today, and if there
-- ever were, a failed deploy is a better answer than an address collision
-- nobody sees.

-- +goose Up

ALTER TABLE tenants DROP CONSTRAINT tenants_slug_is_not_reserved;

ALTER TABLE tenants ADD CONSTRAINT tenants_slug_is_not_reserved CHECK (
    slug NOT IN (
        'admin',   -- kept: a name once reserved is not worth releasing
        'api',     -- this platform's own, and every convention's
        'app',     -- the same
        'auth',    -- sign-in, if it is ever separated out
        'cdn',     -- where a provider expects to put a record
        'console', -- where it ended up living
        'docs',    -- where a person looks for an explanation
        'mail',    -- where a provider expects to put a record
        'static',  -- assets, if they ever leave the binary
        'status',  -- where a person looks when the rest is down
        'www'      -- what a browser silently tries
    )
);

-- +goose Down

ALTER TABLE tenants DROP CONSTRAINT tenants_slug_is_not_reserved;

ALTER TABLE tenants ADD CONSTRAINT tenants_slug_is_not_reserved CHECK (
    slug NOT IN (
        'admin', 'api', 'app', 'auth', 'cdn',
        'docs', 'mail', 'static', 'status', 'www'
    )
);
