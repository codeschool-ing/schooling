-- The five that cannot wait.
--
-- They cost almost nothing now and are IMPOSSIBLE later — not expensive,
-- impossible, because history cannot be reconstructed and an action already
-- taken cannot grow a column retroactively. There is no practice screen, no
-- console and no account table yet; these tables are here anyway, because the
-- day any of those arrives is the day it starts writing rows that will be
-- missing a column nobody can fill in afterwards.
--
-- WHAT THE DATABASE ENFORCES, and what it deliberately does not:
--
--   * The dimensions on an event are NOT NULL with a non-empty CHECK. Not to be
--     tidy — because the whole value of the event stream is that a report can
--     ask "which plan were they on when this happened", and a row that answers
--     with a blank is a hole that no later migration can fill.
--
--   * Three tables refuse UPDATE and DELETE outright, by trigger. Append-only
--     as an arrangement is a comment; append-only as a trigger is a guarantee,
--     and the difference matters on the day somebody fixes data by hand.
--
--   * There is NO foreign key to accounts, because there is no accounts table
--     yet. When there is one, these columns still will not gain a key: an event
--     survives the erasure of the account it names, on purpose. See below.
--
-- HOW ERASURE WORKS HERE, because it is the decision the rest depends on.
-- These tables hold no names, no addresses and no e-mail — they hold uuids.
-- Erasing a person deletes the rows that give those uuids a meaning (the
-- identity rows, and the link between a visitor and an account), which leaves
-- the event and review rows pointing at nothing and joinable to nobody. The
-- statistics survive; the person does not appear in them. That is why the
-- append-only trigger can be absolute: nothing in the erase path ever needs to
-- update or delete one of these rows.

-- +goose Up

/* ---------- one function, three tables ---------- */

-- Raising rather than returning NULL: a BEFORE trigger that returns NULL
-- silently discards the row, and "the delete did nothing and said nothing" is
-- the failure mode this is here to prevent, not a milder version of it.
CREATE FUNCTION refuse_to_change_history() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION
        '% is append-only: % is refused. A correction is a new row, never an edit to an old one.',
        TG_TABLE_NAME, TG_OP
        USING ERRCODE = 'restrict_violation';
END;
$$;

/* ---------- 1. the visitor, who exists before the account ---------- */

-- The first step of the funnel happens before a student exists. Linking a
-- visitor to an account after signup requires the visitor to have HAD an
-- identity at the time of the visit — issued now, or that period is
-- permanently unanswerable.
CREATE TABLE visitors (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    first_seen_at timestamptz NOT NULL DEFAULT now(),
    last_seen_at  timestamptz NOT NULL DEFAULT now(),

    -- FIRST TOUCH, AND ONLY FIRST TOUCH. These are never overwritten on a
    -- later visit. The question they answer is "where did this person come
    -- from", and the answer is the first time, not the most recent — which
    -- after signup is always the site itself.
    first_tenant_id uuid REFERENCES tenants(id) ON DELETE RESTRICT,
    first_path      text NOT NULL DEFAULT '',
    first_referrer  text NOT NULL DEFAULT '',
    utm_source      text NOT NULL DEFAULT '',
    utm_medium      text NOT NULL DEFAULT '',
    utm_campaign    text NOT NULL DEFAULT '',
    country         text NOT NULL DEFAULT 'unknown',
    locale          text NOT NULL DEFAULT 'unknown'
);

-- MANY VISITORS PER ACCOUNT, not one. A person arrives on a phone, subscribes
-- on a laptop, and both are them. A single visitor_id column on an account
-- would record whichever device signed up and silently discard the one the
-- funnel actually started on.
CREATE TABLE account_visitors (
    account_id uuid NOT NULL,
    visitor_id uuid NOT NULL REFERENCES visitors(id) ON DELETE CASCADE,
    linked_at  timestamptz NOT NULL DEFAULT now(),

    PRIMARY KEY (account_id, visitor_id)
);

CREATE INDEX account_visitors_by_visitor ON account_visitors (visitor_id);

/* ---------- 2. events, with their dimensions carried, not joined ---------- */

CREATE TABLE events (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at timestamptz NOT NULL DEFAULT now(),
    name        text NOT NULL CHECK (name <> ''),

    -- Who, as far as anything here knows: two uuids and no name.
    --
    -- NEITHER IS A FOREIGN KEY, and that is what makes erasure possible at all.
    -- A key with ON DELETE SET NULL would try to update this row when a visitor
    -- is deleted, and the append-only trigger below would refuse — leaving a
    -- schema where the legal obligation and the immutability guarantee cannot
    -- both hold. They point at nothing afterwards, which is exactly the
    -- intended end state: the statistics survive and the person is not in them.
    visitor_id uuid,
    account_id uuid,

    -- THE DIMENSIONS, COPIED AT EMISSION. Storing only account_id makes "which
    -- plan were they on when they finished this" unanswerable, because the plan
    -- has since changed. Every one is NOT NULL and non-empty, so a caller that
    -- does not know says so with a word — 'none', 'unknown' — rather than
    -- leaving a blank that reads the same as having forgotten.
    -- RESTRICT, not SET NULL. A denormalised copy exists so that it survives
    -- the thing it was copied from changing — and nulling the id underneath it
    -- would leave a row naming a school that the same row says is absent. A
    -- school with history is deactivated, never deleted; the database refusing
    -- is how that stays true rather than being a habit.
    tenant_id   uuid REFERENCES tenants(id) ON DELETE RESTRICT,
    school_slug text NOT NULL,
    plan        text NOT NULL CHECK (plan <> ''),
    country     text NOT NULL CHECK (country <> ''),
    locale      text NOT NULL CHECK (locale <> ''),

    payload    jsonb NOT NULL DEFAULT '{}'::jsonb,
    request_id text NOT NULL DEFAULT '',

    -- The school dimension is the one that can legitimately be absent: an event
    -- at the platform's own address belongs to no school. Absent means BOTH are
    -- absent — a row can never claim a school it cannot name, nor name one it
    -- does not claim.
    CONSTRAINT events_school_dimension_is_whole
        CHECK ((tenant_id IS NULL) = (school_slug = ''))
);

-- Reports are "this school, this period" and "this person, in order", and both
-- lead with the column that narrows most.
CREATE INDEX events_by_school_and_time  ON events (tenant_id, occurred_at DESC);
CREATE INDEX events_by_name_and_time    ON events (name, occurred_at DESC);
CREATE INDEX events_by_account          ON events (account_id, occurred_at DESC) WHERE account_id IS NOT NULL;
CREATE INDEX events_by_visitor          ON events (visitor_id, occurred_at DESC) WHERE visitor_id IS NOT NULL;

CREATE TRIGGER events_are_append_only
    BEFORE UPDATE OR DELETE ON events
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

/* ---------- 3. the review log, before there is anything to review ---------- */

-- SM-2 does not need this table; it keeps its state in one row per card. A
-- better scheduler later does need it, and it needs history to fit its
-- parameters against — history that only exists if it was being written all
-- along. The cost of writing it now is one insert per answer.
CREATE TABLE practice_review (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reviewed_at timestamptz NOT NULL DEFAULT now(),

    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    account_id uuid NOT NULL,

    -- By id, and with the version answered. A question the statistics later
    -- flag gets replaced, and without the version December's apple is compared
    -- against March's orange.
    exercise_id      text NOT NULL CHECK (exercise_id <> ''),
    exercise_version int  NOT NULL CHECK (exercise_version > 0),
    section_id       text NOT NULL DEFAULT '',

    correct    boolean  NOT NULL,
    -- SM-2's 0..5, derived from correctness and time rather than asked of the
    -- student. A person rating their own recall rates their mood.
    quality    smallint NOT NULL CHECK (quality BETWEEN 0 AND 5),
    elapsed_ms int      NOT NULL CHECK (elapsed_ms >= 0),

    -- BOTH SIDES OF THE SCHEDULER'S STATE. A later scheduler is fitted by
    -- replaying what was known before each answer and comparing what it would
    -- have chosen with what happened; the "before" columns are what make that
    -- replay possible, and they are the ones nobody thinks to store.
    interval_before   int NOT NULL,
    interval_after    int NOT NULL,
    ease_before       numeric(4,2) NOT NULL,
    ease_after        numeric(4,2) NOT NULL,
    repetition_before int NOT NULL,
    repetition_after  int NOT NULL,

    -- Which scheduler produced the "after" values, so a run of rows from a
    -- different one is distinguishable rather than silently mixed in.
    scheduler text NOT NULL DEFAULT 'sm2' CHECK (scheduler <> '')
);

CREATE INDEX practice_review_by_student  ON practice_review (tenant_id, account_id, reviewed_at DESC);
CREATE INDEX practice_review_by_exercise ON practice_review (exercise_id, reviewed_at DESC);

CREATE TRIGGER practice_review_is_append_only
    BEFORE UPDATE OR DELETE ON practice_review
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

/* ---------- 4. the audit, with a name against every action ---------- */

CREATE TABLE audit_log (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at timestamptz NOT NULL DEFAULT now(),

    -- THE ACTOR IS NOT NULLABLE, and that is the whole table. Two people
    -- operate this; an entry that cannot say which of them is a log, not an
    -- audit.
    actor_id   uuid NOT NULL,
    actor_kind text NOT NULL CHECK (actor_kind IN ('staff', 'system')),
    -- Denormalised for the same reason the event dimensions are: people are
    -- renamed and people leave, and an audit entry that reads
    -- "deleted account, actor 9f2c…" a year later is not an answer.
    actor_label text NOT NULL CHECK (actor_label <> ''),

    -- Null for a platform-wide action, which is a real thing an owner does.
    tenant_id uuid REFERENCES tenants(id) ON DELETE RESTRICT,

    action       text NOT NULL CHECK (action <> ''),
    subject_kind text NOT NULL CHECK (subject_kind <> ''),
    subject_id   text NOT NULL DEFAULT '',

    -- What it looked like on each side. Null on a creation and a deletion
    -- respectively, which is the difference between "did not change" and "was
    -- not there".
    before jsonb,
    after  jsonb,

    reason     text NOT NULL DEFAULT '',
    request_id text NOT NULL DEFAULT ''
);

CREATE INDEX audit_log_by_time    ON audit_log (occurred_at DESC);
CREATE INDEX audit_log_by_actor   ON audit_log (actor_id, occurred_at DESC);
CREATE INDEX audit_log_by_subject ON audit_log (subject_kind, subject_id, occurred_at DESC);
CREATE INDEX audit_log_by_school  ON audit_log (tenant_id, occurred_at DESC) WHERE tenant_id IS NOT NULL;

CREATE TRIGGER audit_log_is_append_only
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_history();

/* ---------- 5. every table says whether it holds personal data ---------- */

-- The classification lives on the table itself, as a comment, and a test
-- compares it against the registry the export and erase paths are built from.
-- A new table with no classification fails that test, and so does one whose
-- classification and registry entry disagree — which is the point: "somebody
-- remembers to wire it up" is exactly the arrangement that turns into
-- archaeology at twice this size, with the statutory clock running.
--
-- Three classes and no more:
--
--   none          nothing about a person is in it
--   pseudonymous  identifiers, and no name — meaningless once the identity
--                 rows they point at are gone
--   identifying   a name, an address, an e-mail: something that is a person
--                 without needing to be joined to anything
COMMENT ON TABLE tenants           IS 'personal-data: none';
COMMENT ON TABLE tenant_domains    IS 'personal-data: none';
COMMENT ON TABLE schema_migrations IS 'personal-data: none';
COMMENT ON TABLE visitors          IS 'personal-data: pseudonymous';
COMMENT ON TABLE account_visitors  IS 'personal-data: pseudonymous';
COMMENT ON TABLE events            IS 'personal-data: pseudonymous';
COMMENT ON TABLE practice_review   IS 'personal-data: pseudonymous';
-- Identifying, not pseudonymous: `actor_label` is a person's name, written
-- there on purpose so the entry still reads as an answer after they have left.
COMMENT ON TABLE audit_log         IS 'personal-data: identifying';

-- +goose Down

DROP TABLE audit_log;
DROP TABLE practice_review;
DROP TABLE events;
DROP TABLE account_visitors;
DROP TABLE visitors;
DROP FUNCTION refuse_to_change_history;
