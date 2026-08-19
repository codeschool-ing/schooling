// Package practice is drilling, and when a card comes back.
//
// # IT IS NOT PROGRESS, AND THE SEPARATION IS LOAD-BEARING
//
// `internal/progress` answers "what have I done": set-true, never toggled, and
// what a progress bar reads. This answers "how well do I still know this", and
// it DECAYS — a card strong in March is due again in June, because that is what
// remembering does.
//
// The two must never meet in one number. A bar that fell because somebody did
// not drill would tell a student they went backwards when they did nothing
// wrong (A-05). Nothing here is readable by that module and nothing there reads
// this; the module graph makes it so, and a test says so by name.
//
// # THE STUDENT IS NEVER ASKED HOW WELL THEY REMEMBERED
//
// SM-2 wants a 0..5 self-rating. This derives it from whether the answer was
// right and how long it took (A-04) — see sm2.go. A person rating their own
// recall rates their mood, and the schedule would follow how the day is going.
//
// # ONE PERSON'S CARDS ARE ONE PERSON'S
//
// Every query leads with the tenant and the account. Row-level security is
// deliberately absent (P-05), so that boundary is this code and the tests that
// hold it to it.
//
// # THE QUEUE DOES NOT CROSS SCHOOLS YET, AND THAT IS NOT AN OVERSIGHT
//
// The roadmap asks for one that does. It cannot be built here: a request
// arrives on a school's own host and is scoped to that school by the middleware
// before this package sees it, so a cross-school queue needs the PLATFORM's own
// address — which needs the domain, which is not decided. Building it as a
// query that quietly ignored the tenant would be building the thing whose
// absence the tenancy test exists to guarantee.
//
// What is here is the same queue within one school. The day there is a platform
// address, the change is a second entry point over the same rows, not a
// different scheduler.
package practice

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotDrillable is an exercise that exists and is not for drilling.
//
// IT IS CHECKED RATHER THAN TRUSTED. `drillable` is a property of the question
// — an exam-only question drilled would leak which questions are on the paper,
// and a question that is not worth repeating would fill a queue somebody has to
// get through.
var ErrNotDrillable = errors.New("practice: that exercise is not one to drill")

// ErrLocked is a course this student may not open. A card in one is not
// answerable for the same reason its lesson is not readable.
var ErrLocked = errors.New("practice: that course is not open to this student")

// MayOpen answers whether this student may open the course an exercise belongs
// to. It is a callback because the catalogue is another module and modules meet
// in `cmd/` (X-02) — and it is the SAME shape progress uses, so `cmd/api` hands
// both the one closure rather than keeping two spellings of one question.
//
// It takes no school: the closure reads it from the context, where the tenant
// middleware put it, which is the arrangement that keeps every module from
// having its own idea of which school a request is for.
type MayOpen func(ctx context.Context, courseID string) (bool, error)

type Store struct {
	pool *pgxpool.Pool
	may  MayOpen

	// The clock, so a test can say what day it is. A queue is entirely about
	// dates, and one that could only be tested by waiting until tomorrow would
	// not be tested.
	now func() time.Time
}

func NewStore(pool *pgxpool.Pool, may MayOpen) *Store {
	return &Store{pool: pool, may: may, now: time.Now}
}

// Card is one question in the queue, with where the student is on it.
type Card struct {
	ExerciseID string `json:"exercise"`
	CourseID   string `json:"course"`
	LessonID   string `json:"lesson,omitempty"`
	Type       string `json:"type"`

	// Where it is in the schedule. Shown because a queue that says nothing about
	// why a card is in it is a queue nobody trusts.
	Interval int `json:"interval_days"`
	Lapses   int `json:"lapses"`

	// Absent for a card nobody has answered yet, which is a different thing from
	// one due today.
	DueOn string `json:"due_on,omitempty"`
	New   bool   `json:"new,omitempty"`
}

/* ---------- the queue ---------- */

// Due answers what this student should practise now, in one school.
//
// TWO KINDS OF CARD, IN THIS ORDER. What is due comes first, oldest first,
// because a card overdue by a month is the one at most risk of being lost; then
// questions never answered, so a queue is never empty for somebody who has
// worked through today's.
//
// A LOCKED COURSE CONTRIBUTES NOTHING. The door is checked here rather than at
// the answer, because a queue that offered a card and then refused it would be
// a paywall discovered one question at a time.
func (s *Store) Due(ctx context.Context, tenantID, accountID uuid.UUID, limit int) ([]Card, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	today := s.today()

	rows, err := s.pool.Query(ctx, `
		SELECT e.id, e.course_id, e.lesson_id, e.type,
		       coalesce(p.interval_days, 0), coalesce(p.lapses, 0),
		       p.due_on
		FROM catalog_exercises e
		LEFT JOIN practice_state p
		       ON p.tenant_id = e.tenant_id
		      AND p.exercise_id = e.id
		      AND p.account_id = $2
		WHERE e.tenant_id = $1
		  AND e.drillable
		  AND (p.due_on IS NULL OR p.due_on <= $3)
		-- Due before new, and the longest overdue first. A null due date sorts
		-- last, which is what puts the unseen cards behind the ones at risk.
		ORDER BY p.due_on ASC NULLS LAST, e.id
	`, tenantID, accountID, today)
	if err != nil {
		return nil, fmt.Errorf("practice: reading the queue: %w", err)
	}
	defer rows.Close()

	var queue []Card
	// The door is asked about once per course rather than once per card: a
	// student's queue is a handful of courses and hundreds of questions.
	open := map[string]bool{}

	for rows.Next() {
		var c Card
		var due *time.Time
		if err := rows.Scan(&c.ExerciseID, &c.CourseID, &c.LessonID, &c.Type,
			&c.Interval, &c.Lapses, &due); err != nil {
			return nil, fmt.Errorf("practice: reading the queue: %w", err)
		}

		allowed, asked := open[c.CourseID]
		if !asked {
			allowed, err = s.may(ctx, c.CourseID)
			if err != nil {
				return nil, err
			}
			open[c.CourseID] = allowed
		}
		if !allowed {
			continue
		}

		if due == nil {
			c.New = true
		} else {
			c.DueOn = due.Format(time.DateOnly)
		}

		queue = append(queue, c)
		if len(queue) == limit {
			break
		}
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("practice: reading the queue: %w", err)
	}
	return queue, nil
}

/* ---------- answering one ---------- */

// Answered records an answer and schedules the card again.
//
// BOTH WRITES OR NEITHER. The log and the state are one fact in two tables: a
// state advanced without its log entry is a schedule that cannot be refitted
// later, and a log entry without the state is a card that comes back tomorrow
// having been answered today. One transaction.
//
// `elapsed` is how long the student took, which with correctness is the whole
// input to the quality — see sm2.go.
func (s *Store) Answered(ctx context.Context, tenantID, accountID uuid.UUID,
	exerciseID string, correct bool, elapsed time.Duration) (State, error) {

	courseID, version, sectionID, drillable, err := s.exercise(ctx, tenantID, exerciseID)
	if err != nil {
		return State{}, err
	}
	if !drillable {
		return State{}, ErrNotDrillable
	}

	allowed, err := s.may(ctx, courseID)
	if err != nil {
		return State{}, err
	}
	if !allowed {
		return State{}, ErrLocked
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return State{}, fmt.Errorf("practice: recording an answer: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	before, err := s.stateIn(ctx, tx, tenantID, accountID, exerciseID)
	if err != nil {
		return State{}, err
	}

	quality := Quality(correct, elapsed)
	after := After(before, quality)
	due := Due(s.now(), after)

	if _, err := tx.Exec(ctx, `
		INSERT INTO practice_state
			(tenant_id, account_id, exercise_id,
			 interval_days, ease, repetition, lapses, due_on, last_reviewed_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, now())
		ON CONFLICT (tenant_id, account_id, exercise_id) DO UPDATE SET
			interval_days = EXCLUDED.interval_days,
			ease          = EXCLUDED.ease,
			repetition    = EXCLUDED.repetition,
			lapses        = EXCLUDED.lapses,
			due_on        = EXCLUDED.due_on,
			last_reviewed_at = EXCLUDED.last_reviewed_at
	`, tenantID, accountID, exerciseID,
		after.Interval, after.Ease, after.Repetition, after.Lapses, due); err != nil {
		return State{}, fmt.Errorf("practice: writing the state of %q: %w", exerciseID, err)
	}

	/* THE LOG CARRIES BOTH SIDES. The `before` columns are the ones nobody
	   thinks to store and the only ones that make a later scheduler fittable:
	   it is fitted by replaying what was known at each answer and comparing
	   what it would have chosen against what happened. Written since Fase 0,
	   for this. */
	if _, err := tx.Exec(ctx, `
		INSERT INTO practice_review
			(tenant_id, account_id, exercise_id, exercise_version, section_id,
			 correct, quality, elapsed_ms,
			 interval_before, interval_after, ease_before, ease_after,
			 repetition_before, repetition_after, scheduler)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	`, tenantID, accountID, exerciseID, version, sectionID,
		correct, quality, elapsed.Milliseconds(),
		before.Interval, after.Interval, before.Ease, after.Ease,
		before.Repetition, after.Repetition, Scheduler); err != nil {
		return State{}, fmt.Errorf("practice: writing the review of %q: %w", exerciseID, err)
	}

	if err := tx.Commit(ctx); err != nil {
		return State{}, fmt.Errorf("practice: recording an answer: %w", err)
	}
	return after, nil
}

// State reads where a student is on one card, or a new one if they have never
// answered it.
func (s *Store) State(ctx context.Context, tenantID, accountID uuid.UUID,
	exerciseID string) (State, error) {
	return s.stateIn(ctx, s.pool, tenantID, accountID, exerciseID)
}

// The reader both paths share. `rows` is a pool or a transaction, so the read
// inside `Answered` sees the transaction it is going to write in.
type rows interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func (s *Store) stateIn(ctx context.Context, q rows, tenantID, accountID uuid.UUID,
	exerciseID string) (State, error) {

	var out State
	err := q.QueryRow(ctx, `
		SELECT interval_days, ease, repetition, lapses
		FROM practice_state
		WHERE tenant_id = $1 AND account_id = $2 AND exercise_id = $3
	`, tenantID, accountID, exerciseID).Scan(&out.Interval, &out.Ease, &out.Repetition, &out.Lapses)

	if errors.Is(err, pgx.ErrNoRows) {
		// Never answered is not an error and not a zero state: a card with no
		// ease would multiply every interval to nothing.
		return New(), nil
	}
	if err != nil {
		return State{}, fmt.Errorf("practice: reading the state of %q: %w", exerciseID, err)
	}
	return out, nil
}

// ErrNoSuchExercise is a question this school does not have. It is checked
// rather than trusted: a client inventing ids could otherwise fill the review
// log with rows naming nothing, and that log is what a later scheduler is
// fitted against.
var ErrNoSuchExercise = errors.New("practice: no such exercise in this school")

func (s *Store) exercise(ctx context.Context, tenantID uuid.UUID, exerciseID string) (
	courseID string, version int, sectionID string, drillable bool, err error) {

	err = s.pool.QueryRow(ctx, `
		SELECT course_id, version, section_id, drillable
		FROM catalog_exercises
		WHERE tenant_id = $1 AND id = $2
	`, tenantID, exerciseID).Scan(&courseID, &version, &sectionID, &drillable)

	if errors.Is(err, pgx.ErrNoRows) {
		return "", 0, "", false, ErrNoSuchExercise
	}
	if err != nil {
		return "", 0, "", false, fmt.Errorf("practice: reading the exercise %q: %w", exerciseID, err)
	}
	return courseID, version, sectionID, drillable, nil
}

// today is the day the queue is asked about, in the platform's own reckoning.
//
// A DATE AND NOT A MOMENT. SM-2's intervals are days, and a due timestamp would
// make a card not due at 14:31 and due at 14:32 — a distinction no student
// could see the sense of. Whose midnight it is becomes a real question when an
// account carries a time zone; until then it is the platform's, said here so
// the place to change it is one line.
func (s *Store) today() time.Time {
	n := s.now().UTC()
	return time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, time.UTC)
}
