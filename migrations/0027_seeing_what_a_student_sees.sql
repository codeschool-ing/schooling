-- A session that is somebody looking at a student's screens, rather than the
-- student using them.
--
-- # THREE RESTRAINTS THAT SHIP TOGETHER OR NOT AT ALL (K-02)
--
-- Audited, time-limited, and with a visible banner. It is the most useful
-- support tool there is and the most classic breach vector, and each restraint
-- covers what the other two do not: the audit answers afterwards, the expiry
-- bounds the damage of a machine left unlocked, and the banner is the only one
-- that works while it is happening.
--
-- These columns are the second and, through `viewed_by`, the first. The third
-- is the interface's, and it reads what is written here.
--
-- # WHY IT IS A SESSION ROW AND NOT A TABLE OF ITS OWN
--
-- Because it IS a session: the school's interface has to answer it exactly as
-- it answers the student, or it is not showing what the student sees. Every
-- property a viewing needs — an expiry, a revocation, a last-seen — is already
-- on this table and already respected by the one place that verifies a token.
-- A parallel table would be a second thing to expire and a second thing to
-- forget to revoke.
--
-- # AND WHY IT IS BOUND TO ONE SCHOOL
--
-- The cookie it travels in is host-only, so a browser would not send it to
-- another school anyway. `viewing_tenant` is the same rule written where a
-- copied cookie cannot argue with it: a viewing opened on `code` is refused on
-- `math` by the server rather than by the absence of a cookie.
--
-- # `redeemed_at` MAKES THE HANDOFF LINK SINGLE-USE
--
-- The console runs on its own host and cannot set a cookie for a school's, so
-- the token crosses in a URL the operator follows once. A URL is the worst
-- place a credential can be — history, referrers, a pasted link in a chat — so
-- this one stops working the moment it has been used, which is seconds after it
-- is made. What survives the redemption is a cookie, which is where it belongs.

-- +goose Up

ALTER TABLE sessions
    -- Null on every ordinary session, and the whole of what makes this one
    -- different. `SET NULL` rather than `CASCADE`: erasing the operator must not
    -- delete a student's session, and an entry saying "viewed by somebody who no
    -- longer exists" is still true.
    ADD COLUMN viewed_by uuid REFERENCES accounts(id) ON DELETE SET NULL,

    -- Which school's screens this may be used on.
    ADD COLUMN viewing_tenant uuid REFERENCES tenants(id) ON DELETE RESTRICT,

    -- When the handoff link was spent. Null means it has not been.
    ADD COLUMN redeemed_at timestamptz;

-- THE THREE ARRIVE TOGETHER OR NOT AT ALL, which is K-02 in the shape a
-- database can hold: a viewing session with no school to be used on, or a school
-- with nobody accountable for it, is a row that should not be writable.
ALTER TABLE sessions
    ADD CONSTRAINT sessions_a_viewing_is_whole
    CHECK ((viewed_by IS NULL) = (viewing_tenant IS NULL));

-- "What has this operator looked at", which is the question the audit answers
-- from the other side and this one answers from the session. Partial, because
-- almost every row here is an ordinary session and none of them is ever the
-- answer.
CREATE INDEX sessions_viewings ON sessions (viewed_by, created_at DESC)
    WHERE viewed_by IS NOT NULL;

-- +goose Down

DROP INDEX sessions_viewings;
ALTER TABLE sessions DROP CONSTRAINT sessions_a_viewing_is_whole;
ALTER TABLE sessions
    DROP COLUMN redeemed_at,
    DROP COLUMN viewing_tenant,
    DROP COLUMN viewed_by;
