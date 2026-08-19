-- The pictures a course is written around.
--
-- # WHY THEY ARE IN THE DATABASE AND NOT ON A DISK
--
-- The deployed image is a `scratch` container holding one binary. There is no
-- content directory beside it, and there is not meant to be: the files in
-- `content/` are what a person edits and reviews, and the mirror is what the
-- server reads (C-13). A picture that lived only on disk would be a second
-- source of truth with a different deploy story from the question that names
-- it, and the failure would be an image that four-oh-fours on one instance and
-- not on another.
--
-- They are small and there are few of them. A diagram of how a request travels
-- is fifteen kilobytes; the checker refuses anything over half a megabyte, so
-- this table cannot quietly become a photo library. If it ever needs to hold
-- something large, that is a bucket and a URL column, and this comment is where
-- the conversation starts rather than something to design for now.
--
-- # WHY THE BYTES AND NOT A URL
--
-- The same reason the fonts stopped coming from a CDN: the offline bundle is
-- one file with no network, and a picture it cannot fetch is a question a
-- student cannot answer however well they know the material. Bytes here become
-- a data URI there.
--
-- # WHY THE COURSE AND NOT THE LESSON
--
-- The first instinct was the lesson, because that is where the file naturally
-- sits beside the words. It is wrong, and the way to see it is to ask who
-- renders a question: today, only the exam paper. A lesson's exercises are in
-- the model and in this mirror and on no screen at all. So a picture scoped to
-- a lesson would have been a picture no student could ever reach — the type
-- shipped and unreachable, which is worse than not shipped.
--
-- An exam question belongs to a course and to no lesson. Scoping the picture to
-- the course covers it, covers a lesson's exercises for when that screen
-- exists, and lets two lessons share a diagram without a second copy.
--
-- A TRACK exam still has nowhere: a track is one JSON file with no directory to
-- put a picture in. The checker says so by name rather than letting the
-- question through to fail on a screen.
--
-- IT IS NOT ADDRESSED BY A NUMBER. `(tenant, course, name)` is the whole
-- identity, so re-running the load job over an edited picture replaces it
-- rather than leaving two behind.

-- +goose Up

CREATE TABLE catalog_images (
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    course_id text NOT NULL,
    name      text NOT NULL,

    -- Served verbatim, so it is stored rather than guessed at request time. A
    -- sniffed type is a type that changes when the sniffer does.
    media_type text NOT NULL,
    bytes      bytea NOT NULL,

    PRIMARY KEY (tenant_id, course_id, name),

    -- An empty picture is a broken one and the load job should not be able to
    -- write it. The upper bound is the checker's, restated here because the
    -- checker runs on a pull request and this runs on every write.
    CONSTRAINT catalog_images_are_pictures CHECK (
        length(bytes) BETWEEN 1 AND 524288 AND media_type <> ''
    )
);

COMMENT ON TABLE catalog_images IS 'personal-data: none';

-- +goose Down

DROP TABLE catalog_images;
