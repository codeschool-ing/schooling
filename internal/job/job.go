// Package job records that something ran on a schedule, and how it went.
//
// # IT IS A LOG OF ATTEMPTS AND NOT A JOB SYSTEM
//
// There is no queue here, no lock, no retry count and no scheduler. Cloud
// Scheduler owns the clock and `infra/scheduler.tf` says when; what was missing
// was any answer at all to "did it run last night", and that is the whole of
// what this package adds.
//
// The distinction matters because the shape that suggests itself — a `jobs`
// table with a state machine and a worker — is a body of infrastructure with
// one producer. `cmd/analyse` is the only thing on a schedule; `migrate` and
// `load` are gates a deploy waits for, so their failure stops a release in
// front of somebody rather than in the dark.
//
// # WHY `computed_at` WAS NOT ENOUGH
//
// The console already showed when the item-analysis rollup was last written,
// which is a good signal and answers a different question. It says when the
// work last SUCCEEDED. A job that failed at 03:10, a job somebody disabled in
// March, and a job that ran perfectly and found nothing to change are three
// different situations that all look like a stale `computed_at`.
package job

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// The names of the jobs that record themselves. One today, and it is a constant
// so that the writer and every reader spell it the same way — a screen filtering
// on `"analyse"` against a job that calls itself `"analysis"` is a screen that
// shows an empty history of a job that runs nightly.
const Analyse = "analyse"

// Settle is the sweeper that brings lapsed subscriptions up to date. A second
// name, added when a second thing went on the clock — see `cmd/settle`.
const Settle = "settle"

// Outcome is how a run ended, or that it has not.
type Outcome string

const (
	// Running is the state a row is born in. Still true tomorrow, it is the
	// most useful row in the table: a job that was killed, ran out of memory or
	// had its instance withdrawn writes nothing on the way out, and this is the
	// only trace it leaves.
	Running Outcome = "running"

	// OK is a run that finished its work.
	OK Outcome = "ok"

	// Failed is a run that returned an error. What went wrong is in Detail.
	Failed Outcome = "failed"
)

// DetailLimit is how much a job may write about itself. Long enough for a
// sentence and a count, short enough that an error with a stack trace in it
// does not become the row. The database does not carry this one: a job writing
// too much is our own code rather than anything a stranger sends, so the cost
// of a check in two places is not worth the third place it would have to be
// kept in step.
const DetailLimit = 500

// Run is one attempt, as the console reads it.
type Run struct {
	ID      uuid.UUID
	Job     string
	Version string

	StartedAt  time.Time
	FinishedAt *time.Time

	Outcome Outcome
	Detail  string
}

// Took is how long it ran, or how long it has been running.
//
// IT TAKES `now` RATHER THAN READING A CLOCK, because the interesting case is a
// run that never finished and the interesting question about it is "how long
// ago" — which is a number a test has to be able to fix.
func (r Run) Took(now time.Time) time.Duration {
	if r.FinishedAt != nil {
		return r.FinishedAt.Sub(r.StartedAt)
	}
	return now.Sub(r.StartedAt)
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Started opens a row for a run that is about to happen.
//
// IT IS CALLED BEFORE THE WORK AND NOT AFTER. Recording only on the way out
// would capture every outcome except the one with no other trace — and that one
// is the reason this table exists.
//
// A FAILURE TO RECORD IS NOT A FAILURE TO RUN, which is the opposite of the
// console's rule and right for the opposite reason. There, an action nobody can
// account for must not happen. Here, the work is a nightly analysis that
// withdraws broken questions from in front of students: refusing to do it
// because a bookkeeping row could not be written would trade the thing that
// matters for the record of it. The caller logs and carries on.
func (s *Store) Started(ctx context.Context, name, version string) (uuid.UUID, error) {
	if strings.TrimSpace(name) == "" {
		return uuid.Nil, errors.New("job: a run has a name")
	}

	var id uuid.UUID
	err := s.pool.QueryRow(ctx, `
		INSERT INTO job_runs (job, version) VALUES ($1, $2) RETURNING id
	`, name, version).Scan(&id)
	if err != nil {
		return uuid.Nil, fmt.Errorf("job: recording the start of %q: %w", name, err)
	}
	return id, nil
}

// Finished closes the row, with the error if there was one.
//
// THE ERROR DECIDES THE OUTCOME rather than the caller passing a word. A call
// site that had to say both would eventually say `OK` beside a non-nil error —
// on the retry path, or in the branch somebody added in a hurry — and a table
// of outcomes that disagrees with what happened is worse than no table.
func (s *Store) Finished(ctx context.Context, id uuid.UUID, failure error, detail string) error {
	outcome := OK
	if failure != nil {
		outcome = Failed
		if detail == "" {
			detail = failure.Error()
		} else {
			detail = detail + " — " + failure.Error()
		}
	}

	if n := []rune(detail); len(n) > DetailLimit {
		// Trimmed rather than refused: what a job says about itself must never
		// be the reason its run goes unrecorded.
		detail = string(n[:DetailLimit-1]) + "…"
	}

	tag, err := s.pool.Exec(ctx, `
		UPDATE job_runs SET finished_at = now(), outcome = $2, detail = $3
		WHERE id = $1 AND finished_at IS NULL
	`, id, string(outcome), detail)
	if err != nil {
		return fmt.Errorf("job: recording the end of a run: %w", err)
	}
	if tag.RowsAffected() != 1 {
		// Either the row is gone or it was already closed. Both mean this call
		// is the second one, and the first is the one that happened.
		return fmt.Errorf("job: that run was already finished, or is not there")
	}
	return nil
}

// Latest is the most recent runs of one job, newest first.
func (s *Store) Latest(ctx context.Context, name string, limit int) ([]Run, error) {
	if limit <= 0 {
		limit = 10
	}

	rows, err := s.pool.Query(ctx, `
		SELECT id, job, version, started_at, finished_at, outcome, detail
		FROM job_runs WHERE job = $1 ORDER BY started_at DESC LIMIT $2
	`, name, limit)
	if err != nil {
		return nil, fmt.Errorf("job: reading the runs of %q: %w", name, err)
	}
	defer rows.Close()

	var out []Run
	for rows.Next() {
		var one Run
		var outcome string
		if err := rows.Scan(&one.ID, &one.Job, &one.Version, &one.StartedAt,
			&one.FinishedAt, &outcome, &one.Detail); err != nil {
			return nil, fmt.Errorf("job: reading the runs of %q: %w", name, err)
		}
		one.Outcome = Outcome(outcome)
		out = append(out, one)
	}
	return out, rows.Err()
}

// Names is every job that has ever recorded a run.
//
// READ RATHER THAN DECLARED, so the screen shows what has actually happened.
// A list in Go would be a list of what somebody remembered to add, and the row
// it fails to name is the row somebody is looking for.
func (s *Store) Names(ctx context.Context) ([]string, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT DISTINCT job FROM job_runs ORDER BY job`)
	if err != nil {
		return nil, fmt.Errorf("job: reading which jobs have run: %w", err)
	}
	defer rows.Close()

	var out []string
	for rows.Next() {
		var one string
		if err := rows.Scan(&one); err != nil {
			return nil, fmt.Errorf("job: reading which jobs have run: %w", err)
		}
		out = append(out, one)
	}
	return out, rows.Err()
}

// ErrNoRuns is a job nothing has ever recorded. It is a state and not a
// failure: before the first night, that is every job there is.
var ErrNoRuns = errors.New("job: nothing has run")

// Last is the single most recent run, which is what a screen leads with.
func (s *Store) Last(ctx context.Context, name string) (Run, error) {
	runs, err := s.Latest(ctx, name, 1)
	if err != nil {
		return Run{}, err
	}
	if len(runs) == 0 {
		return Run{}, ErrNoRuns
	}
	return runs[0], nil
}

/*
ADRIFT IS HOW LONG A RUN MAY SAY `running` BEFORE IT IS BELIEVED DEAD.

There is a right answer and it follows from the two spans either side of it: the
analysis takes seconds to minutes, and the next attempt is twenty-four hours
away. An hour is far past anything the work does and far short of the next run,
so a row still open after one is a job that vanished rather than a job that is
busy — and nothing is gained by making that a setting (K-13).

IT IS NOT A STATE IN THE DATABASE. Nothing sweeps these rows into `failed`,
because a sweep would need something to run it — which is the machinery this
whole package declines to build — and because a row rewritten by a janitor
stops being a record of what the job itself said. The reader decides, with the
constant beside it on the screen (K-16).
*/
const Adrift = time.Hour

// Adrift answers whether this run has been open too long to believe.
func (r Run) Adrift(now time.Time) bool {
	return r.Outcome == Running && now.Sub(r.StartedAt) > Adrift
}
