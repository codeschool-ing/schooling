-- Where a video's script lives, and the version a piece of prose carries.
--
-- # THE BOOLEAN COULD NOT NAME A VIDEO
--
-- `catalog_sections.video` said one was there and nothing about which. C-18
-- versions a rendering and puts it at `vd-<id>/v<version>/<locale>.mp4`, an
-- event records the version a student watched, and C-20 makes the spoken
-- script authored source — none of which has anything to hold while the
-- answer is `true`. A section carries as many videos as it needs, so this is a
-- table and not three more columns.
--
-- NOTHING READS IT YET. The player is phase 6 and may want a shape this does
-- not have. It is written now for one reason: `cmd/load` would otherwise parse
-- a script out of `content/` and drop it, which is the same silent success the
-- front-matter parser was just corrected for. Accepting a field and storing it
-- nowhere is worse than refusing it.
--
-- # AND THE PROSE GETS A VERSION
--
-- C-25 compares two generations of a text by what a reading event recorded, and
-- that only works if the prose carried a number from the FIRST release. Added
-- afterwards, the first generation of every section has no baseline and the
-- comparison the version exists for is lost exactly where the material changes
-- most. The catalogue is empty today, which is why this costs nothing now and
-- would cost a rewrite of every file later.
--
-- A translation declares the version it translated, so a `.pt.md` that says 3
-- while the English says 4 is a STALE TRANSLATION THAT SAYS SO. Today `ls`
-- shows that the file exists and never that it has gone behind.
--
-- # WHAT IS DELIBERATELY NOT SOLVED HERE
--
-- `catalog_sections.duration` stays a formatted string, written by the loader
-- from the sum of its videos' seconds. It is a rendering summary produced by
-- the single writer inside the same transaction as the rows it summarises, so
-- it is not a second source of truth — but the FORMAT belongs in the interface
-- and not in a column, and moving it is phase 6's, with the player that will
-- read these seconds directly.

-- +goose Up

ALTER TABLE catalog_prose
    ADD COLUMN version int NOT NULL DEFAULT 0;

-- Zero means a file that declared none, which the content check refuses. The
-- default exists so the column can be NOT NULL on a table that is empty today
-- and would otherwise need a backfilled guess about material nobody wrote.
COMMENT ON COLUMN catalog_prose.version IS
    'The prose version a reading event records (C-25). 0 is a file that declared none.';

CREATE TABLE catalog_videos (
    tenant_id  uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    course_id  text NOT NULL,
    lesson_id  text NOT NULL,
    section_id text NOT NULL,

    id      text NOT NULL,
    version int  NOT NULL CHECK (version >= 1),

    -- The narration this was rendered from, and what the student reads back as
    -- the transcript. One string rather than two, for as long as the rendering
    -- says what the script says.
    script text NOT NULL CHECK (script <> ''),

    -- Seconds, not "08 min". A number is what a milestone is computed against
    -- (K-23); a formatted string is what a screen prints.
    seconds int NOT NULL CHECK (seconds > 0),

    -- The languages that EXIST, which is not the ones wanted. Uneven arrival is
    -- the ordinary state and not an error (C-19).
    locales text[] NOT NULL DEFAULT '{}',

    position int NOT NULL,

    PRIMARY KEY (tenant_id, course_id, lesson_id, section_id, id)
);

-- UNIQUE ACROSS THE SCHOOL, because the object key carries no course, lesson or
-- section. Two renderings sharing an id are two files at one address, and the
-- second upload wins in silence.
CREATE UNIQUE INDEX catalog_videos_id_is_the_address
    ON catalog_videos (tenant_id, id);

CREATE INDEX catalog_videos_by_section
    ON catalog_videos (tenant_id, course_id, lesson_id, section_id, position);

-- +goose Down

DROP TABLE catalog_videos;
ALTER TABLE catalog_prose DROP COLUMN version;
