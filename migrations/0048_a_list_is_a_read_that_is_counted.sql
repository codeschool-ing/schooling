-- The indexes a screen that lists people needs, and the extension one of them
-- rests on.
--
-- # THIS MIGRATION EXISTS BECAUSE K-22 WAS AMENDED
--
-- `docs/PLAN.md` said a person is found by an exact address and never listed.
-- The argument was that browsing personal data is precisely what an audit
-- cannot tell from working — which is true of ONE read and false of a hundred,
-- and that difference is the amendment. See the decision itself and
-- `internal/console/people.go` for the whole of it; what belongs here is the
-- half a schema can hold.
--
-- # WHY AN EXTENSION AND NOT A PREFIX
--
-- K-21 says a console screen asks only what an index sustains, and the query a
-- support conversation actually makes is a substring: somebody writes in from
-- an address nobody can reproduce exactly, and what is remembered is a fragment
-- of it, or a surname. `LIKE 'ana%'` is servable by a b-tree and answers a
-- different question — it finds people whose address STARTS with what you
-- remember, which is not what anybody remembers.
--
-- So `pg_trgm`, which is what Postgres has for this, and a GIN index per column
-- that makes `ILIKE '%…%'` an index scan rather than a walk of the table. The
-- alternative was to ship the prefix and call it search, which is the shape of
-- a capability being trimmed to fit the index that was already there.
--
-- IT IS AVAILABLE WHERE THIS RUNS. Cloud SQL for Postgres supports `pg_trgm`,
-- and the role this platform connects as is created with `gcloud sql users
-- create` — which makes it a member of `cloudsqlsuperuser`, the role that may
-- create an extension from that supported list. If that is ever untrue, this
-- migration fails LOUDLY and before a revision is served: the release gates the
-- new container on `schooling-migrate` finishing, so the failure is a release
-- that does not happen rather than a screen that quietly scans a table.
--
-- # AND WHY BOTH COLUMNS
--
-- The address identifies and the name is what somebody signs an e-mail with.
-- A search over one of them sends whoever is answering that e-mail back to
-- guessing the other, which is the state this screen exists to end.

-- +goose Up

-- IF NOT EXISTS because a local stack, a test database and a restored backup
-- can each already have it, and a migration that fails on being run against a
-- database that is already right is a migration that makes restoring harder.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

/* THE INDEXES ARE ON `lower(...)` BECAUSE THE QUERY IS. `accounts_by_email` is
   already unique on `lower(email)` — an address is a person and not a string,
   so Ana@ and ana@ are one — and a search that lowered one side only would
   miss the row it was looking at. */
CREATE INDEX accounts_email_words ON accounts USING gin (lower(email) gin_trgm_ops);
CREATE INDEX accounts_name_words ON accounts USING gin (lower(name) gin_trgm_ops);

/* AND THE ONE THE UNFILTERED LIST WALKS, which is not the index that was here.
   `accounts_real_by_creation` is partial — `WHERE NOT synthetic` — because
   every aggregate excludes seeded students (K-11). This screen does not: an
   operator about to erase a seeded person has to be able to see one, and a list
   that hid them would be a screen whose emptiness means two different things.

   KEYSET AND NOT OFFSET, so the pages are stable while people are signing up.
   `(created_at, id)` is the whole order — `created_at` alone is not unique, and
   two accounts made in the same millisecond would put one of them on both pages
   or on neither. */
CREATE INDEX accounts_by_creation ON accounts (created_at DESC, id DESC);

-- +goose Down

DROP INDEX accounts_by_creation;
DROP INDEX accounts_name_words;
DROP INDEX accounts_email_words;

/* THE EXTENSION IS NOT DROPPED. It is a database-wide object and something else
   may have come to depend on it by the time anybody rolls this back; dropping
   it would take those with it. An unused extension costs nothing. */
