-- A track's own sequence, which is not the same thing as a prerequisite.
--
-- A course's `requires` names ONLY what a student has to know first. That is
-- what lets one course sit in twelve tracks without dragging five hundred hours
-- behind it, and conflating the two cost eighteen false edges in the
-- predecessor.
--
-- What is left over is real and still has to be said: "in THIS track, this one
-- comes after that one". It is a property of the track, not of the course, so
-- it lives beside the track's order rather than beside the course.
--
-- A TARGET IS EITHER A STEP OR A COURSE, and both are needed: a fork has no id
-- to point at, so the only way to say "after the fork" is its position; and a
-- course before a fork does have an id, which survives a reordering where a
-- position does not. Exactly one of the two columns is filled, which the check
-- constraint holds to.
--
-- Left out, the graph does not lose an edge — it draws the WRONG one, because
-- it falls back to the previous step for a course with no prerequisite inside
-- the track. Nothing looks broken, which is why this is a table and not a
-- convention.

-- +goose Up

CREATE TABLE catalog_track_links (
    tenant_id      uuid    NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    track_id       text    NOT NULL,
    course_id      text    NOT NULL,
    position       integer NOT NULL,   -- the order the file wrote them in
    target_course  text    NOT NULL DEFAULT '',
    target_step    integer,

    PRIMARY KEY (tenant_id, track_id, course_id, position),

    CONSTRAINT catalog_track_links_one_target CHECK (
        (target_step IS NULL) <> (target_course = '')
    )
);

-- +goose Down

DROP TABLE catalog_track_links;
