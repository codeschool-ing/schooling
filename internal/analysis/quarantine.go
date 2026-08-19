package analysis

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// Taking a question out of circulation, and putting it back.
//
// # WHY THIS IS AUTOMATIC AND THE ALTERNATIVE IS NOT
//
// A flagged question is one the strong students fail: a wrong key, an inverted
// answer, an ambiguous prompt. Left in the pool it keeps being asked, and every
// student who meets it is marked on a question we already know is broken.
//
// Waiting for a person to act on a list is the same as not acting, because the
// list is read on the days somebody remembers to read it. Two people run this
// platform. So the job does it, and the recovery is what is made easy rather
// than the prevention: releasing is one call, and fixing the question releases
// it without anybody calling anything.
//
// # THE SAFETY IS THE THRESHOLD, NOT A PERSON
//
// Nothing is quarantined below the minimum sample, and nothing is quarantined
// for being hard — only for being inverted, which is the one verdict that
// cannot be a property of a good question. Both are decided in this package and
// tested there.

// ErrNotQuarantined is a release for something that is not out of circulation.
var ErrNotQuarantined = errors.New("analysis: that question is not quarantined")

// Audit is how an administrative action is recorded, defined here and satisfied
// by the module that owns the log. Taking a question out of a course is an
// administrative action whether a person or a job did it (K-01).
type Audit func(ctx context.Context, action string, tenantID uuid.UUID,
	exerciseID string, version int, before, after any, reason string) error

// Question is one exercise at one version — the unit a quarantine applies to.
//
// A NEW VERSION IS A DIFFERENT QUESTION, which is what makes fixing one the
// ordinary way out: the quarantine on version 1 does not match version 2, and
// nobody has to remember to release anything.
type Question struct {
	ExerciseID string
	Version    int
}

// The actions, as they appear in the audit log. Words rather than an enum
// because the log is read by a person and an entry saying `2` is not an answer.
const (
	ActionQuarantined = "question.quarantined"
	ActionReleased    = "question.released"
)

// WithAudit is the store with somewhere to record what it did.
//
// It is a separate call rather than a constructor argument because reading the
// statistics needs no audit, and a reader that had to be handed one would be a
// reader somebody passes nil to.
func (s *Store) WithAudit(record Audit) *Store {
	out := *s
	out.audit = record
	return &out
}

// InForce answers which questions are out of circulation in one school.
//
// A SET RATHER THAN A QUESTION PER QUESTION. The exam draw already holds the
// whole pool and the practice queue holds the whole queue; asking once and
// filtering beats a lookup per row, and more importantly it is one moment in
// time — a per-question check could include a question and then exclude the
// next one under a quarantine written in between.
func (s *Store) InForce(ctx context.Context, tenantID uuid.UUID) (map[Question]bool, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT exercise_id, version FROM question_quarantine
		WHERE tenant_id = $1 AND released_at IS NULL
	`, tenantID)
	if err != nil {
		return nil, fmt.Errorf("analysis: reading what is out of circulation: %w", err)
	}
	defer rows.Close()

	out := map[Question]bool{}
	for rows.Next() {
		var q Question
		if err := rows.Scan(&q.ExerciseID, &q.Version); err != nil {
			return nil, fmt.Errorf("analysis: reading what is out of circulation: %w", err)
		}
		out[q] = true
	}
	return out, rows.Err()
}

// Sweep quarantines everything currently flagged in one school and answers what
// it took out.
//
// It is idempotent: a question already out of circulation is left alone rather
// than quarantined again, so a job that runs twice writes one audit entry and
// not two.
func (s *Store) Sweep(ctx context.Context, tenantID uuid.UUID, now time.Time) ([]Question, error) {
	flagged, err := s.Flagged(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	inForce, err := s.InForce(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	var taken []Question
	for _, one := range flagged {
		q := Question{ExerciseID: one.ExerciseID, Version: one.Version}
		if inForce[q] {
			continue
		}
		if err := s.Quarantine(ctx, tenantID, one, now); err != nil {
			return taken, err
		}
		taken = append(taken, q)
	}
	return taken, nil
}

// Quarantine takes one question out of circulation, with the numbers that
// decided it.
//
// IT REFUSES A VERDICT THAT IS NOT FLAGGED. Quarantining is the strongest thing
// this system does on its own — it removes a question from a course without
// anybody looking — so the one caller that could widen it is refused rather
// than trusted. A question that is merely hard, merely easy, or below the
// sample cannot be quarantined by this path at all.
func (s *Store) Quarantine(ctx context.Context, tenantID uuid.UUID,
	one Statistics, now time.Time) error {

	if !one.Verdict.Flagged() {
		return fmt.Errorf("analysis: %s v%d is %q, which is not something to quarantine",
			one.ExerciseID, one.Version, one.Verdict)
	}

	tag, err := s.pool.Exec(ctx, `
		INSERT INTO question_quarantine
			(tenant_id, exercise_id, version, quarantined_at, verdict, attempts,
			 discrimination, minimum_sample)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (tenant_id, exercise_id, version) DO UPDATE SET
			quarantined_at = EXCLUDED.quarantined_at,
			verdict = EXCLUDED.verdict,
			attempts = EXCLUDED.attempts,
			discrimination = EXCLUDED.discrimination,
			minimum_sample = EXCLUDED.minimum_sample,
			released_at = NULL,
			released_why = ''
		WHERE question_quarantine.released_at IS NOT NULL
	`, tenantID, one.ExerciseID, one.Version, now, string(one.Verdict),
		one.Attempts, one.Discrimination, one.MinimumSample)
	if err != nil {
		return fmt.Errorf("analysis: quarantining %s v%d: %w", one.ExerciseID, one.Version, err)
	}
	if tag.RowsAffected() == 0 {
		// Already out of circulation. Not an error, and not an audit entry: a
		// job that ran twice did not do anything twice.
		return nil
	}

	return s.record(ctx, ActionQuarantined, tenantID, one.ExerciseID, one.Version,
		nil,
		map[string]any{
			"verdict": string(one.Verdict), "attempts": one.Attempts,
			"discrimination": one.Discrimination, "minimum_sample": one.MinimumSample,
		},
		fmt.Sprintf("the strong students got it right less often than the weak ones "+
			"(index %.2f over %d attempts, minimum sample %d)",
			one.Discrimination, one.Attempts, one.MinimumSample))
}

// Release puts a question back, with a reason.
//
// THE REASON IS REQUIRED. Releasing is the one action here that overrides the
// numbers, and an override with no reason is indistinguishable a year later
// from somebody having clicked the wrong row.
func (s *Store) Release(ctx context.Context, tenantID uuid.UUID,
	q Question, now time.Time, why string) error {

	if why == "" {
		return errors.New("analysis: releasing a question needs a reason — it overrides " +
			"the numbers, and an override nobody explained is one nobody can check")
	}

	var was struct {
		verdict        string
		attempts       int
		discrimination float64
	}
	err := s.pool.QueryRow(ctx, `
		UPDATE question_quarantine SET released_at = $4, released_why = $5
		WHERE tenant_id = $1 AND exercise_id = $2 AND version = $3 AND released_at IS NULL
		RETURNING verdict, attempts, discrimination
	`, tenantID, q.ExerciseID, q.Version, now, why,
	).Scan(&was.verdict, &was.attempts, &was.discrimination)

	if errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("%w: %s v%d", ErrNotQuarantined, q.ExerciseID, q.Version)
	}
	if err != nil {
		return fmt.Errorf("analysis: releasing %s v%d: %w", q.ExerciseID, q.Version, err)
	}

	return s.record(ctx, ActionReleased, tenantID, q.ExerciseID, q.Version,
		map[string]any{
			"verdict": was.verdict, "attempts": was.attempts,
			"discrimination": was.discrimination,
		},
		nil, why)
}

// record writes the audit entry, and says so loudly when it cannot.
//
// A QUARANTINE THAT WAS NOT AUDITED IS A QUESTION THAT VANISHED FROM A COURSE
// WITH NOTHING SAYING WHY. The write above has already happened by the time
// this runs, so the error is wrapped rather than swallowed and the caller
// decides — but there is no path here that treats "the audit failed" as fine.
func (s *Store) record(ctx context.Context, action string, tenantID uuid.UUID,
	exerciseID string, version int, before, after any, reason string) error {

	if s.audit == nil {
		return fmt.Errorf("analysis: %s of %s v%d was not audited: this store was built "+
			"without one, and taking a question out of a course is an administrative action",
			action, exerciseID, version)
	}
	if err := s.audit(ctx, action, tenantID, exerciseID, version, before, after, reason); err != nil {
		return fmt.Errorf("analysis: recording %s of %s v%d: %w", action, exerciseID, version, err)
	}
	return nil
}
