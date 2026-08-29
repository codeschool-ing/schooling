package analysis

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Where the statistics are kept, and the job that recomputes them.
//
// # THE ROWS ARE A CACHE AND THE STREAM IS THE TRUTH
//
// Everything here is derived from `events` and can be dropped and rebuilt. It
// is stored because the answer is expensive and the question is asked on a
// screen — a discrimination index computed across every answer on every page
// load is a report that gets slower as the platform gets more useful.
//
// That is also why it is overwritten in place rather than appended to: a
// history of what the statistics said last Tuesday is a history of our
// arithmetic, and the history that matters is the answers themselves.

// Answers is where the answers come from, defined here and satisfied elsewhere.
//
// THE MODULE THAT INTERPRETS THE STREAM DOES NOT READ IT. `internal/event` owns
// those rows and hands them over as they are; this package decides what they
// mean. `cmd/` is what joins the two, which is the rule (X-02) and also the
// reason neither has to know about the other.
type Answers func(ctx context.Context, tenantID uuid.UUID, since time.Time) ([]Answer, error)

// Schools is which schools to run over, for the same reason: this package must
// not reach into the one that owns them.
type Schools func(ctx context.Context) ([]uuid.UUID, error)

// Store reads and writes the rollup, and takes questions out of circulation.
type Store struct {
	pool    *pgxpool.Pool
	answers Answers
	schools Schools

	// Where an administrative action is recorded. Nil until WithAudit, and the
	// quarantine path refuses rather than proceeding without one — see the
	// comment on `record`.
	audit Audit

	// The stream's readers. Nil until WithStream, and the reports that need
	// them refuse rather than answering something built from nothing.
	reached Reached
	monthly Monthly
	origins Origins
	links   Links

	// How many answers a question needs before this store says anything about
	// it. Nil until WithMinimumSample, and nil is the number `MinimumSample`
	// ships with — see `enough`.
	minimum func(ctx context.Context) int
}

/*
WithMinimumSample is the store reading its threshold from the registry.

	A SEPARATE CALL for the reason `WithStream` and `WithAudit` are: nothing
	that only reads a cohort or a funnel needs it, and a constructor demanding
	it would be a constructor somebody passes nil to. The difference from those
	two is that a nil here is not a refusal — it is the shipped number, because
	an un-wired threshold should compute the analysis this package has always
	computed rather than compute none.
*/
func (s *Store) WithMinimumSample(minimum func(ctx context.Context) int) *Store {
	out := *s
	out.minimum = minimum
	return &out
}

/*
enough is the threshold in force, bounded by the declaration however it is
wired.

	A VALUE OUTSIDE THE FENCE IS THE SHIPPED ONE. `setting.Store` refuses one on
	the way in and ignores one on the way out, so a value arriving here means
	`cmd` is answering something the declaration would not accept — and the
	failure that would follow is the quiet kind: a threshold of two makes this
	platform quarantine questions on the evidence of two people, and every
	screen would look exactly as it does now.
*/
func (s *Store) enough(ctx context.Context) int {
	if s.minimum == nil {
		return MinimumSample.Fallback
	}
	if got := s.minimum(ctx); MinimumSample.Valid(got) == nil {
		return got
	}
	return MinimumSample.Fallback
}

// WithStream is the store with the readers that go to the event stream.
//
// A separate call rather than constructor arguments, for the reason WithAudit
// is one: item analysis needs none of them, and a constructor that demanded all
// of them would be a constructor somebody passes nil to.
//
// `links` is shared by all three on purpose. It is what turns two identities
// into one person, and a report that folded them differently from another would
// put two irreconcilable totals on two screens of the same console.
func (s *Store) WithStream(reached Reached, monthly Monthly, origins Origins, links Links) *Store {
	out := *s
	out.reached, out.monthly, out.origins, out.links = reached, monthly, origins, links
	return &out
}

func NewStore(pool *pgxpool.Pool, answers Answers, schools Schools) *Store {
	return &Store{pool: pool, answers: answers, schools: schools}
}

// Run recomputes the statistics for every school and answers how many questions
// it wrote a verdict for.
//
// # IT LOOKS AT EVERYTHING, EVERY TIME
//
// `since` narrows the window rather than resuming from where the last run
// stopped. A resumable job would have to merge new answers into stored counts,
// and a merge is where a double-counted event lands — the one failure that
// would make a verdict wrong in the direction of quarantining a question nobody
// complained about. Recomputing from the stream cannot double-count, because
// the stream is what it counts.
//
// The window exists so that a question edited a year ago is not judged forever
// on answers to the version before it. Pass the zero time to look at everything.
func (s *Store) Run(ctx context.Context, since time.Time, now time.Time) (int, error) {
	schools, err := s.schools(ctx)
	if err != nil {
		return 0, fmt.Errorf("analysis: finding the schools to run over: %w", err)
	}

	written := 0
	for _, school := range schools {
		n, err := s.runOne(ctx, school, since, now)
		if err != nil {
			return written, err
		}
		written += n
	}
	return written, nil
}

func (s *Store) runOne(ctx context.Context, school uuid.UUID, since, now time.Time) (int, error) {
	answers, err := s.answers(ctx, school, since)
	if err != nil {
		return 0, fmt.Errorf("analysis: reading the answers of %s: %w", school, err)
	}
	if len(answers) == 0 {
		return 0, nil
	}

	grouped, err := Group(answers, s.enough(ctx))
	if err != nil {
		return 0, fmt.Errorf("analysis: %s: %w", school, err)
	}

	// ONE TRANSACTION PER SCHOOL. A run that failed halfway would otherwise
	// leave a console showing yesterday's verdict for half the questions and
	// today's for the rest, with nothing saying which was which.
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return 0, fmt.Errorf("analysis: writing the statistics of %s: %w", school, err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	for _, one := range grouped {
		if _, err := tx.Exec(ctx, `
			INSERT INTO item_statistics
				(tenant_id, exercise_id, version, type, attempts, correct, difficulty,
				 discrimination, strong_group, weak_group, verdict, minimum_sample,
				 first_answer, last_answer, computed_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
			ON CONFLICT (tenant_id, exercise_id, version) DO UPDATE SET
				type = EXCLUDED.type,
				attempts = EXCLUDED.attempts,
				correct = EXCLUDED.correct,
				difficulty = EXCLUDED.difficulty,
				discrimination = EXCLUDED.discrimination,
				strong_group = EXCLUDED.strong_group,
				weak_group = EXCLUDED.weak_group,
				verdict = EXCLUDED.verdict,
				minimum_sample = EXCLUDED.minimum_sample,
				first_answer = EXCLUDED.first_answer,
				last_answer = EXCLUDED.last_answer,
				computed_at = EXCLUDED.computed_at
		`, school, one.ExerciseID, one.Version, one.Type, one.Attempts, one.Correct,
			one.Difficulty, one.Discrimination, one.StrongGroup, one.WeakGroup,
			string(one.Verdict), one.MinimumSample, one.FirstAnswer, one.LastAnswer, now,
		); err != nil {
			return 0, fmt.Errorf("analysis: writing %s v%d: %w", one.ExerciseID, one.Version, err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, fmt.Errorf("analysis: writing the statistics of %s: %w", school, err)
	}
	return len(grouped), nil
}

// ComputedAt answers when this school's rollup was last written, and whether it
// ever was.
//
// A SCREEN OF STATISTICS WITH NO "AS OF" GOES STALE IN SILENCE. These rows are
// a cache of a job that runs on a schedule; if that job has been failing for a
// week, every number on the console is a week old and looks exactly like a
// number from this morning. When the rows were made is the one thing that cannot
// be read off the rows, so it is asked for separately.
//
// THE MAX IS THE RUN AND NOT A MIXTURE: `runOne` writes a school's whole rollup
// in one transaction with one `now`, so every row of a school carries the same
// instant and the newest of them is the last run.
//
// `false` IS "THE JOB HAS NEVER RUN HERE", which is not the same as a school
// with no questions. The second is an answer and the first is the absence of
// one — the distinction the funnel makes with `Measured`, for the same reason.
func (s *Store) ComputedAt(ctx context.Context, tenantID uuid.UUID) (time.Time, bool, error) {
	var at *time.Time
	if err := s.pool.QueryRow(ctx, `
		SELECT max(computed_at) FROM item_statistics WHERE tenant_id = $1
	`, tenantID).Scan(&at); err != nil {
		return time.Time{}, false,
			fmt.Errorf("analysis: reading when the statistics were made: %w", err)
	}
	if at == nil {
		return time.Time{}, false, nil
	}
	return *at, true, nil
}

// Of answers one school's statistics, worst first.
//
// THE ORDER IS THE POINT OF THE SCREEN. A console listing every question in id
// order is a console nobody reads to the bottom, and the row that matters is
// the one that says a key is inverted.
func (s *Store) Of(ctx context.Context, tenantID uuid.UUID) ([]Statistics, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT exercise_id, version, type, attempts, correct, difficulty,
		       discrimination, strong_group, weak_group, verdict, minimum_sample,
		       first_answer, last_answer
		FROM item_statistics
		WHERE tenant_id = $1
		ORDER BY
			CASE verdict
				WHEN 'inverted' THEN 0
				WHEN 'weak' THEN 1
				WHEN 'too-easy' THEN 2
				WHEN 'fine' THEN 3
				ELSE 4
			END,
			discrimination, exercise_id, version
	`, tenantID)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading the statistics: %w", err)
	}
	return scan(rows)
}

// Flagged is only what somebody has to act on. It is a separate query rather
// than a filter over Of, because "show me everything" and "show me what is
// broken" are different screens and the second is the one a job reads.
func (s *Store) Flagged(ctx context.Context, tenantID uuid.UUID) ([]Statistics, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT exercise_id, version, type, attempts, correct, difficulty,
		       discrimination, strong_group, weak_group, verdict, minimum_sample,
		       first_answer, last_answer
		FROM item_statistics
		WHERE tenant_id = $1 AND verdict = $2
		ORDER BY discrimination, exercise_id, version
	`, tenantID, string(VerdictInverted))
	if err != nil {
		return nil, fmt.Errorf("analysis: reading what is flagged: %w", err)
	}
	return scan(rows)
}

func scan(rows pgx.Rows) ([]Statistics, error) {
	defer rows.Close()

	var out []Statistics
	for rows.Next() {
		var one Statistics
		var verdict string
		if err := rows.Scan(&one.ExerciseID, &one.Version, &one.Type, &one.Attempts,
			&one.Correct, &one.Difficulty, &one.Discrimination, &one.StrongGroup,
			&one.WeakGroup, &verdict, &one.MinimumSample,
			&one.FirstAnswer, &one.LastAnswer); err != nil {
			return nil, fmt.Errorf("analysis: reading the statistics: %w", err)
		}
		one.Verdict = Verdict(verdict)
		out = append(out, one)
	}
	return out, rows.Err()
}
