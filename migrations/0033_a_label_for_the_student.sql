-- `my` is a label no school may take.
--
-- # IT IS THE STUDENT'S OWN ADDRESS
--
-- `my.<platform domain>` is where a student is asked the one question a
-- school's host cannot be asked: what is due everywhere they practise. A
-- request at `code.` is scoped to that school before any module sees it —
-- which is what makes every query in this platform safe to write — so crossing
-- schools is a second address rather than a flag on a route.
--
-- The word says whose it is rather than what happens there, and that is the
-- point: an account crosses every school and almost nothing else does (N-01).
-- `code.` is a school's, `console.` is an operator's, and this one is the
-- person's.
--
-- # IT WAS GOING TO BE `app` AND THE DOMAIN DECIDED OTHERWISE
--
-- `app` is already on the list — since `0003_reserved_labels.sql`, where it was
-- reserved for "this platform's own, and every convention's" — and it was the
-- obvious choice while the domain was `schooling.lab.aleogr.dev`. On
-- `schooling.app` it reads `app.schooling.app`, which is a stutter nobody would
-- type twice. The label moved and `app` stays reserved: taking a name off this
-- list is strictly worse than leaving one on.
--
-- # AND IT GOES ON BEFORE THE ADDRESS ANSWERS ANYWHERE
--
-- Which is the whole point, and `0003` says what the alternative costs: a
-- school created at a name the platform later wants, discovered when somebody
-- adds the address the school already took, and fixed by renaming a school that
-- students have bookmarked — "the one kind of change this project has already
-- decided it will not make quietly".
--
-- A CHECK constraint cannot be extended, only replaced. Postgres validates the
-- new one against every existing row as it is added, so a school already called
-- `my` would fail this migration rather than be silently grandfathered. That is
-- the right way round: there is no such school today, and if there ever were, a
-- failed deploy is a better answer than an address collision nobody sees.

-- +goose Up

ALTER TABLE tenants DROP CONSTRAINT tenants_slug_is_not_reserved;

ALTER TABLE tenants ADD CONSTRAINT tenants_slug_is_not_reserved CHECK (
    slug NOT IN (
        'admin',   -- kept: a name once reserved is not worth releasing
        'api',     -- this platform's own, and every convention's
        'app',     -- kept, for the same reason, though the student's is `my`
        'auth',    -- sign-in, if it is ever separated out
        'cdn',     -- where a provider expects to put a record
        'console', -- where the staff console ended up living
        'docs',    -- where a person looks for an explanation
        'mail',    -- where a provider expects to put a record
        'my',      -- the student's own, across every school they are in
        'static',  -- assets, if they ever leave the binary
        'status',  -- where a person looks when the rest is down
        'www'      -- what a browser silently tries
    )
);

-- +goose Down

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
