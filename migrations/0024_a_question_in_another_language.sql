-- A question in another language.
--
-- # THE ONE THING IN THE CATALOGUE THAT WAS ENGLISH ONLY
--
-- A track has `catalog_track_text`, a course has `catalog_course_text`, a
-- topic got `catalog_course_topic_text` in 0023 and prose has been per-locale
-- since 0006. A question had nothing: the prompt, the options and the reasons
-- an option is wrong reached a Portuguese student in English, on the one screen
-- where reading precisely is the whole task.
--
-- # A WHOLE PAYLOAD PER LOCALE, NOT A DIFF
--
-- The row holds the complete question as it reads in that language, written by
-- `cmd/load` from `exercises.<locale>.json` merged field by field over the
-- English (C-11). The alternative — storing only what differs and merging it in
-- whoever serves a question — is the same merge done in every reader, and the
-- day one of them forgets is the day a screen is half translated.
--
-- It costs a copy of each question per language. That is the right trade: a
-- question is a few kilobytes, there are five languages, and what it buys is
-- that the grader, the presenter and the offline bundle all take ONE payload
-- and never ask which language they are in.
--
-- # WHAT DECIDES AN ANSWER IS NOT IN THE TRANSLATION
--
-- `correct`, `accept`, `value`, `tolerance`, the coordinates of a label: none
-- of them is reachable from a translation file, which is enforced where the
-- translation is read rather than here — `catalog.ExerciseText` declares the
-- translatable fields and no others, so the merge cannot write a key nobody
-- listed. A translation that could reach the key would mark the same answer
-- differently in two languages, and nobody would find it: both screens read
-- fine on their own.

-- +goose Up

CREATE TABLE catalog_exercise_text (
    tenant_id   uuid NOT NULL REFERENCES tenants (id) ON DELETE RESTRICT,
    exercise_id text NOT NULL,
    locale      text NOT NULL,

    -- The same two the base row keeps as columns, for the same reason: a list
    -- of questions is read without opening a payload.
    prompt text NOT NULL,
    hint   text NOT NULL DEFAULT '',

    -- The whole question in this language, ready to grade and to present.
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,

    PRIMARY KEY (tenant_id, exercise_id, locale)
);

COMMENT ON TABLE catalog_exercise_text IS 'personal-data: none';

COMMENT ON COLUMN catalog_exercise_text.payload IS
    'the complete question in this locale — what nobody translated is the English';

-- +goose Down

DROP TABLE catalog_exercise_text;
