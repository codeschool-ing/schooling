-- The two numbers the SM-2 quality was derived from, recorded on the row they
-- produced.
--
-- # THE FILE THEY CAME FROM SAID THIS WOULD BE NEEDED
--
-- `internal/practice/sm2.go` has always been explicit that ten seconds and
-- forty-five are not measurements:
--
--     THE THRESHOLDS ARE A FIRST GUESS AND ARE MEANT TO BE FITTED (…) this is
--     exactly why `practice_review` has been written since Fase 0, with the
--     values from BEFORE each answer as well as after: the numbers below can be
--     fitted against real history rather than argued about, and the fitting
--     needs history that only exists if it was being recorded all along.
--
-- And then, in the next sentence, the thing that stopped being true today:
--
--     Changing them is a change to `scheduler` in that log too, so a run of rows
--     from a different one is distinguishable rather than silently mixed in.
--
-- That worked while changing them meant a deployment: somebody editing the
-- constants was somebody editing the file, and the file told them to rename the
-- scheduler in the same diff. `0046` makes them settable from a console, where
-- there is no diff and nobody to read the instruction — so the guarantee has to
-- move out of a comment and into a column.
--
-- # WHY THE THRESHOLDS AND NOT A VERSION
--
-- A version number would be a name for the pair, which is one more thing to
-- keep true and one that says nothing to whoever is doing the fitting. What a
-- fit actually needs is the boundaries the quality was computed against, and
-- those are two integers. Stored, they answer the question directly, and a
-- scheduler renamed or not is beside the point.
--
-- This is `exam_attempts.pass_mark` and `item_statistics.minimum_sample` for the
-- third time: a judgement made against a number that can move has to carry the
-- number it was made against, or the history stops explaining itself the moment
-- somebody moves it.
--
-- # WHY THE BACKFILL IS NOT A GUESS
--
-- Every row that exists was judged by 10s and 45s, because those were constants
-- and nothing could set anything else. The default is the truth about the past
-- rather than an assumption about it.

-- +goose Up

ALTER TABLE practice_review
    -- WHAT COUNTED AS ANSWERED WITHOUT HESITATION, in milliseconds, matching
    -- `elapsed_ms` beside it so a fit compares two integers in one unit rather
    -- than remembering which column is which.
    ADD COLUMN quick_ms int NOT NULL DEFAULT 10000 CHECK (quick_ms > 0),

    -- AND WHAT COUNTED AS ANSWERED AFTER THINKING. Above it the answer was
    -- right and slow, which SM-2 reads as a card that is nearly forgotten.
    ADD COLUMN considered_ms int NOT NULL DEFAULT 45000 CHECK (considered_ms > 0);

-- THE ORDER OF THE TWO IS PART OF THE MEANING, and a row where they crossed
-- would make `Quality` unreadable — the "quick" band would swallow the
-- "considered" one and the middle grade would be unreachable. Go refuses this
-- before it gets here; the constraint is what makes it true of every row rather
-- than of every row this version wrote.
ALTER TABLE practice_review
    ADD CONSTRAINT practice_review_thresholds_are_ordered
    CHECK (quick_ms < considered_ms);

-- +goose Down

ALTER TABLE practice_review
    DROP CONSTRAINT practice_review_thresholds_are_ordered,
    DROP COLUMN considered_ms,
    DROP COLUMN quick_ms;
