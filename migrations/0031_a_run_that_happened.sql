-- That a job ran, and how it went.
--
-- # THE FAILURE THIS EXISTS FOR IS THE SILENT ONE
--
-- The nightly analysis now runs on a schedule. What nothing answers is whether
-- it ran LAST night: the console shows when the rollup was last written, which
-- is a good signal and the wrong one — a job that failed at 03:10 and a job
-- somebody disabled in March look identical through it, and so does a job that
-- ran fine and found nothing to change.
--
-- `computed_at` says when the work last SUCCEEDED. This says when it was last
-- ATTEMPTED, which is the question asked at 09:00 by somebody wondering whether
-- to trust the screen.
--
-- # THE ROW IS WRITTEN AT THE START AND FINISHED AT THE END
--
-- Writing it only on the way out would record every outcome except the one with
-- no other trace. A job killed for running too long, a container out of memory,
-- an instance withdrawn mid-run: each of those writes nothing at all, and the
-- table would say the last run was the night before — which is exactly the lie
-- `computed_at` already tells.
--
-- So a run that never finished leaves a row that says so. It stays `running`
-- forever and the console reads a `running` row older than a few hours as what
-- it is: started, and never seen again.
--
-- # IT IS FROZEN ONCE IT HAS FINISHED
--
-- The same trigger shape as a handed-in exam, and for the same reason: a
-- finished run is a fact about a night, and a second write to it is either a
-- bug or a rewrite of history. UPDATE only — deleting old rows is housekeeping
-- and this table is the one place that has to be prunable without ceremony.
--
-- # ONE JOB TODAY, AND THE COLUMN IS STILL `job`
--
-- `cmd/analyse` is the only thing on a schedule. `migrate` and `load` are gates
-- the deploy waits for, so their failure stops a release in front of somebody
-- rather than in the dark, and they are not here.
--
-- The name is a column anyway, because the alternative is a table called
-- `analysis_runs` that has to be renamed the first time anything else runs at
-- night — and this is a log of attempts, not a model of a job system. What is
-- NOT here is a queue, a scheduler, a retry count or a lock: none of those has
-- a second producer to justify it, and Cloud Scheduler already owns the clock.

-- +goose Up

CREATE TABLE job_runs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Which job. Free text rather than an enum: adding one should not need a
    -- migration, and a name this table does not recognise is still a run that
    -- happened.
    job text NOT NULL CHECK (job <> ''),

    -- What was running. A run is only comparable to another run of the same
    -- code, and "it started failing" is usually "it started failing after a
    -- deploy" — which is unanswerable without this.
    version text NOT NULL DEFAULT '',

    started_at  timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,

    -- `running` is the state a row is BORN in, and the one that means something
    -- went wrong if it is still true tomorrow.
    outcome text NOT NULL DEFAULT 'running'
        CHECK (outcome IN ('running', 'ok', 'failed')),

    -- What it did, or what went wrong — one sentence the job writes for itself.
    -- Deliberately not columns: a schema with `questions_withdrawn` in it is a
    -- schema that has opinions about which job is running, and the second job
    -- either leaves them null or is misdescribed by them.
    detail text NOT NULL DEFAULT '',

    -- FINISHED MEANS DECIDED. A row with an end and no outcome, or an outcome
    -- and no end, is a state nothing writes and everything reading has to guess
    -- about.
    CONSTRAINT job_runs_finished_is_decided
        CHECK ((finished_at IS NULL) = (outcome = 'running'))
);

-- "How did this job go, most recently" — the only read there is, and the one
-- the console makes on every load of the screen.
CREATE INDEX job_runs_by_job ON job_runs (job, started_at DESC);

CREATE FUNCTION refuse_to_change_a_finished_run() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.finished_at IS NOT NULL THEN
        RAISE EXCEPTION
            'that run finished at %: it cannot be changed. A re-run is a new row.',
            OLD.finished_at
            USING ERRCODE = 'restrict_violation';
    END IF;
    RETURN NEW;
END;
$$;

-- UPDATE ONLY, like the exam's. Deletion is how old rows are pruned, and a
-- trigger that refused it would make this table the one thing in the schema
-- that grows for ever.
CREATE TRIGGER job_runs_are_frozen_once_finished
    BEFORE UPDATE ON job_runs
    FOR EACH ROW EXECUTE FUNCTION refuse_to_change_a_finished_run();

COMMENT ON TABLE job_runs IS 'personal-data: none';

-- +goose Down

DROP TABLE job_runs;
DROP FUNCTION refuse_to_change_a_finished_run();
