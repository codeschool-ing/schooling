-- What a student thinks of a course, a track, or this place.
--
-- # THE COMPLAINT THAT HAD NOWHERE TO GO
--
-- `content_reports` is a channel for a DEFECT: this key is wrong, this video
-- does not play, I cannot follow this sentence. It is precise and it is narrow,
-- and the two most useful things a student can tell us do not fit in it — that
-- a course is thin, and that a course is padded. Neither is a defect of any
-- section. Both are a judgement about the whole, and until now the only way one
-- reached us was somebody writing in.
--
-- # STARS ARE THE INVITATION AND THE PAIRS ARE THE ANSWER
--
-- A 1-to-5 on its own says THAT something is wrong and never WHAT, which makes
-- it a number to worry about rather than a number to act on. So the row carries
-- both: one star rating, which is the whole contract with somebody who does not
-- want to be asked anything, and four opposed pairs that are each a real
-- question with a direction — did anything get left out, is it padded, was it
-- interesting, was it pitched right.
--
-- THE FOUR ARE NULLABLE AND THE STARS ARE NOT. That is the design in the
-- schema: the second layer is optional in the interface, so a column that
-- demanded it would be an interface lying about what it asks. A null here means
-- "not asked or not answered" and is the common case by construction.
--
-- # ONE OPINION PER PERSON PER SUBJECT, AND IT IS EDITABLE
--
-- The opposite decision from `content_reports`, which takes one report per
-- person per section and treats the second as the first. A report is an event —
-- this thing is broken, at this moment. A rating is a STATE: what somebody
-- currently thinks. Somebody who returns after the course was rewritten should
-- be able to say it is better now, and a table that recorded both would have to
-- be asked which one counts.
--
-- So the unique index is the whole of it and the write is an upsert. What that
-- costs is history, and `rated_version` is the reason it costs little: the row
-- says which release it was given against, so a course rewritten between two
-- releases can be compared to itself even though nobody kept the old number.
--
-- # WHY THE VERSION IS THE RELEASE AND NOT A CATALOGUE GENERATION
--
-- There is no generation to record. `cmd/load` writes the mirror from
-- `content/` in one transaction and prunes what the files no longer carry; it
-- does not stamp what it wrote, and a number invented here to describe it would
-- be a number nothing else in the system agrees with.
--
-- The release tag is the one honest answer available: `content/` ships in this
-- repository, `cmd/load` reads that tree, and the binary serving the student
-- knows its own tag. "dev" for every build that is not a release, which is the
-- same admission `build` makes everywhere else — a wrong version answers with
-- confidence, which is worse than answering nothing.
--
-- IT IS THE SERVER'S AND NEVER THE CLIENT'S. A version offered by a browser is
-- a version a stale tab is holding, and this column exists precisely to compare
-- across releases.
--
-- # WHAT THE SUBJECT IS
--
-- Three kinds in one table rather than three tables, because everything about
-- them is the same: the stars, the pairs, the person, the release, the upsert,
-- the console read. What differs is one word and what the id points at.
--
-- The platform is the reason the id can be empty. "What do you think of this
-- place" names nothing in the catalogue — there is one platform — and a table
-- that demanded an id would have to invent one for it. The check below holds
-- the shape: a course and a track name something, the platform does not.
--
-- # PSEUDONYMOUS, WHICH IS THE DECISION `notes` AND `content_reports` DID NOT GET
--
-- Both of those are `identifying`, because what somebody puts in a free-text box
-- is not for a schema comment to assume. This table has no box. Five small
-- integers and a word from a closed list cannot carry a name, an address or a
-- confession, and that is not a hope about how people use it — it is a CHECK
-- constraint.
--
-- Which is also the argument for not adding a comment field later. The moment
-- one exists this becomes `content_reports` under another name, and the reason
-- to keep them apart is that a defect gets fixed and an opinion gets counted.

-- +goose Up

CREATE TABLE ratings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,

    -- `course`, `track` or `platform`. The words live in Go, where a test holds
    -- them, for the reason no list lives in a schema: a CHECK listing them here
    -- would be a second copy to keep in step.
    subject_kind text NOT NULL CHECK (subject_kind <> ''),

    -- Empty for the platform, and only for the platform.
    subject_id text NOT NULL DEFAULT '',

    CONSTRAINT ratings_platform_names_nothing
        CHECK ((subject_kind = 'platform') = (subject_id = '')),

    -- THE ONE ANSWER THAT IS NOT OPTIONAL. A row exists because somebody tapped
    -- a star; everything below it is what they chose to add afterwards.
    stars smallint NOT NULL CHECK (stars BETWEEN 1 AND 5),

    -- THE FOUR PAIRS, each 1..5 with a direction, each null until answered.
    --
    -- They read low-to-high as the sentence beside them does, and the interface
    -- is what says which end is which — a schema that encoded "5 is good" would
    -- be wrong for two of these four, because neither end of `pace` or `depth`
    -- is the good one. Too easy and too hard are both misses, and the useful
    -- reading is the distribution's shape rather than its mean.
    --
    --   completeness  1 = something was left out    5 = nothing was missing
    --   padding       1 = it is padded              5 = it is direct
    --   interest      1 = it did not interest me    5 = it interested me
    --   depth         1 = too easy                  5 = too hard
    completeness smallint CHECK (completeness BETWEEN 1 AND 5),
    padding      smallint CHECK (padding      BETWEEN 1 AND 5),
    interest     smallint CHECK (interest     BETWEEN 1 AND 5),
    depth        smallint CHECK (depth        BETWEEN 1 AND 5),

    -- Which release of the material this was given against. The server's, from
    -- `build.Current()`; "dev" on every build nobody tagged.
    rated_version text NOT NULL DEFAULT 'dev' CHECK (rated_version <> ''),

    rated_at   timestamptz NOT NULL DEFAULT now(),
    changed_at timestamptz
);

-- ONE OPINION PER PERSON PER SUBJECT. The upsert target, and the whole reason
-- a second visit changes a mind rather than stuffing a ballot.
CREATE UNIQUE INDEX ratings_one_each
    ON ratings (tenant_id, account_id, subject_kind, subject_id);

-- THE CONSOLE'S READ: one school's ratings of one subject. Every aggregate the
-- console draws is a scan of this, and the distribution is the point of it —
-- a mean of 3 from everybody saying 3 and a mean of 3 from half saying 1 are
-- two different problems, and only one of them is urgent.
CREATE INDEX ratings_by_subject ON ratings (tenant_id, subject_kind, subject_id);

-- PSEUDONYMOUS. Five bounded integers, a word from a closed list and a release
-- tag. There is no free text here and the CHECK constraints are why that is a
-- fact rather than an expectation. It still cascades with the account: the row
-- is about our material, but WHOSE opinion it is belongs to them.
COMMENT ON TABLE ratings IS 'personal-data: pseudonymous';

-- +goose Down

DROP TABLE ratings;
