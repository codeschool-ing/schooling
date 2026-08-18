-- The labels a school may not be called.
--
-- WHY THE DATABASE AND NOT ONLY THE APPLICATION. A rule that lives in one Go
-- function holds for every path that goes through that function, and this is
-- exactly the kind of rule that gets bypassed — by a fixture, by a seed script,
-- by somebody inserting a row to unblock themselves at nine on a Friday. The
-- constraint holds for all of them, and `internal/tenant` keeps its copy so the
-- refusal arrives with a sentence rather than as a constraint violation.
--
-- A test proves the two agree, by trying every reserved label against the real
-- database. Two copies of a list are only safe when something compares them.
--
-- THE COST OF GETTING THIS LATE is not a failed insert. A school called `api`
-- works perfectly until the day the platform needs `api.example.tld` for
-- itself — at which point the fix is renaming a school that students have
-- bookmarked, which is the one kind of change this project has already decided
-- it will not make quietly.

-- +goose Up

ALTER TABLE tenants ADD CONSTRAINT tenants_slug_is_not_reserved CHECK (
    slug NOT IN (
        'admin',   -- the console, wherever it ends up living
        'api',     -- this platform's own, and every convention's
        'app',     -- the same
        'auth',    -- sign-in, if it is ever separated out
        'cdn',     -- where a provider expects to put a record
        'docs',    -- where a person looks for an explanation
        'mail',    -- where a provider expects to put a record
        'static',  -- assets, if they ever leave the binary
        'status',  -- where a person looks when the rest is down
        'www'      -- what a browser silently tries
    )
);

-- +goose Down

ALTER TABLE tenants DROP CONSTRAINT tenants_slug_is_not_reserved;
