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
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/grade"
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

// ErrWithdrawn is a card that has been taken out of circulation. It is its own
// error rather than a not-found, because it is a fact about the question and
// not about the student — and the screen says something different for each.
var ErrWithdrawn = errors.New("practice: that question has been withdrawn")

// MayOpen answers whether this student may open the course an exercise belongs
// to. It is a callback because the catalogue is another module and modules meet
// in `cmd/` (X-02) — and it is the SAME shape progress uses, so `cmd/api` hands
// both the one closure rather than keeping two spellings of one question.
//
// It takes no school: the closure reads it from the context, where the tenant
// middleware put it, which is the arrangement that keeps every module from
// having its own idea of which school a request is for.
type MayOpen func(ctx context.Context, courseID string) (bool, error)

// Item is one exercise at one version, which is the unit a quarantine applies
// to: a new version is a different question.
type Item struct {
	ExerciseID string
	Version    int
}

// Quarantined answers which questions are out of circulation in this school. A
// callback for the same reason MayOpen is: the answer belongs to the module
// that reads how people answered, and this one may not import it.
type Quarantined func(ctx context.Context, tenantID uuid.UUID) (map[Item]bool, error)

type Store struct {
	pool *pgxpool.Pool
	may  MayOpen

	// Nil is "nothing is out of circulation", which is what a school looks
	// like before anything has been measured.
	quarantined Quarantined

	// The clock, so a test can say what day it is. A queue is entirely about
	// dates, and one that could only be tested by waiting until tomorrow would
	// not be tested.
	now func() time.Time
}

func NewStore(pool *pgxpool.Pool, may MayOpen, quarantined Quarantined) *Store {
	return &Store{pool: pool, may: may, quarantined: quarantined, now: time.Now}
}

// outOfCirculation is the set, or an empty one when nothing is wired in.
func (s *Store) outOfCirculation(ctx context.Context, tenantID uuid.UUID) (map[Item]bool, error) {
	if s.quarantined == nil {
		return nil, nil
	}
	out, err := s.quarantined(ctx, tenantID)
	if err != nil {
		return nil, fmt.Errorf("practice: reading what is out of circulation: %w", err)
	}
	return out, nil
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
		SELECT e.id, e.version, e.course_id, e.lesson_id, e.type,
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

	// AND WHAT IS OUT OF CIRCULATION IS ASKED ONCE FOR THE WHOLE QUEUE. A card
	// that has been withdrawn is not offered — a drill that asked a question we
	// already know is broken would tell somebody they are wrong about something
	// we got wrong, and then schedule it to come back.
	out, err := s.outOfCirculation(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		var c Card
		var version int
		var due *time.Time
		if err := rows.Scan(&c.ExerciseID, &version, &c.CourseID, &c.LessonID, &c.Type,
			&c.Interval, &c.Lapses, &due); err != nil {
			return nil, fmt.Errorf("practice: reading the queue: %w", err)
		}

		if out[Item{ExerciseID: c.ExerciseID, Version: version}] {
			continue
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

/* ---------- drawing one ---------- */

// Drawn is a question as the student is about to see it: no key in it, and
// shuffled where the order is the answer.
type Drawn struct {
	ExerciseID string          `json:"exercise"`
	Version    int             `json:"version"`
	Type       string          `json:"type"`
	CourseID   string          `json:"course"`
	Shown      json.RawMessage `json:"question"`
}

// Draw presents a card and remembers how it was presented.
//
// THE SHUFFLE HAS TO SURVIVE THE ROUND TRIP. The answer comes back expressed in
// the frame the student saw, and mapping it back needs the permutation that
// produced that frame — so it is written down here and read at grading time.
// See the migration for why it is not derived from a seed.
func (s *Store) Draw(ctx context.Context, tenantID, accountID uuid.UUID,
	exerciseID string) (*Drawn, error) {

	e, err := s.exercise(ctx, tenantID, exerciseID)
	if err != nil {
		return nil, err
	}
	if !e.drillable {
		return nil, ErrNotDrillable
	}

	allowed, err := s.may(ctx, e.courseID)
	if err != nil {
		return nil, err
	}
	if !allowed {
		return nil, ErrLocked
	}

	// WITHDRAWN IS REFUSED HERE TOO, not only left out of the queue. A queue is
	// fetched once and drilled through, so a student holding one from before a
	// sweep would still reach this — and the queue being right is not the same
	// guarantee as the card being answerable.
	out, err := s.outOfCirculation(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	if out[Item{ExerciseID: exerciseID, Version: e.version}] {
		return nil, ErrWithdrawn
	}

	/* A FRESH DRAW EVERY TIME, so the same card is not shuffled the same way on
	   every visit — which would let somebody learn the arrangement rather than
	   the material.

	   `NewShuffler` and not a rand of this package's own: the sequence is
	   math/rand and the SEED is crypto/rand, which is the split that keeps a
	   shuffle unguessable without pretending a shuffle needs a cryptographic
	   generator. It was written for exams and this is the same need. */
	presented, err := grade.Present(e.kind, e.payload, grade.NewShuffler())
	if err != nil {
		return nil, fmt.Errorf("practice: presenting %q: %w", exerciseID, err)
	}

	// `perm` is NOT NULL: nothing to shuffle is an empty array, which is a
	// different thing from a card that was never drawn.
	perm := presented.Perm
	if perm == nil {
		perm = []int{}
	}

	if _, err := s.pool.Exec(ctx, `
		INSERT INTO practice_drawn
			(tenant_id, account_id, exercise_id, exercise_version, perm, drawn_at)
		VALUES ($1, $2, $3, $4, $5, now())
		ON CONFLICT (tenant_id, account_id, exercise_id) DO UPDATE SET
			exercise_version = EXCLUDED.exercise_version,
			perm             = EXCLUDED.perm,
			drawn_at         = EXCLUDED.drawn_at
	`, tenantID, accountID, exerciseID, e.version, perm); err != nil {
		return nil, fmt.Errorf("practice: recording the draw of %q: %w", exerciseID, err)
	}

	return &Drawn{
		ExerciseID: exerciseID, Version: e.version, Type: e.kind,
		CourseID: e.courseID, Shown: presented.Shown,
	}, nil
}

// ErrNotDrawn is an answer to a card this student was never shown.
//
// It is not a security boundary — nothing is awarded for practice, so somebody
// cheating at their own drill cheats nobody. It is what keeps the review log
// interpretable: a row there is an answer to a question somebody actually saw,
// and that log is what a later scheduler is fitted against.
var ErrNotDrawn = errors.New("practice: that card has not been drawn")

/* ---------- answering one ---------- */

// Marked is what an answer came to: the verdict, and where the card goes next.
type Marked struct {
	grade.Result
	State State

	// THE ANSWER, AND ONLY ONCE THERE IS AN ANSWER TO COMPARE IT WITH. A drill
	// that said "wrong" and stopped would leave a student knowing they do not
	// know, which is the half of the feedback that teaches nothing. This is the
	// other half — and it is produced HERE rather than sent with the card,
	// because a card carrying it would be a card whose answer is in the
	// response body.
	//
	// It is in the frame the student saw. See internal/grade/reveal.go.
	Reveal grade.Reveal
}

// Answered marks an answer and schedules the card again.
//
// THE SERVER DECIDES WHETHER IT WAS RIGHT. It was the client's word for one
// commit and that was wrong: a client cannot know — the question it was given
// has no key in it — so "correct" arriving over the wire could only ever have
// been an assertion nothing checked. `internal/grade` marks it here, against
// the payload, exactly as an exam is marked.
//
// THE ANSWER IS IN THE FRAME THE STUDENT SAW and is mapped back through the
// permutation that produced it. Without that step every `ordering` answer is
// marked against the wrong arrangement, and a student who put four steps in
// perfect order is told they are wrong.
//
// BOTH WRITES OR NEITHER. The log and the state are one fact in two tables: a
// state advanced without its log entry is a schedule that cannot be refitted
// later, and a log entry without the state is a card that comes back tomorrow
// having been answered today. One transaction.
func (s *Store) Answered(ctx context.Context, tenantID, accountID uuid.UUID,
	exerciseID string, answer json.RawMessage, elapsed time.Duration) (Marked, error) {

	e, err := s.exercise(ctx, tenantID, exerciseID)
	if err != nil {
		return Marked{}, err
	}
	if !e.drillable {
		return Marked{}, ErrNotDrillable
	}

	allowed, err := s.may(ctx, e.courseID)
	if err != nil {
		return Marked{}, err
	}
	if !allowed {
		return Marked{}, ErrLocked
	}

	// WITHDRAWN IS REFUSED HERE TOO, not only left out of the queue. A queue is
	// fetched once and drilled through, so a student holding one from before a
	// sweep would still reach this — and the queue being right is not the same
	// guarantee as the card being answerable.
	out, err := s.outOfCirculation(ctx, tenantID)
	if err != nil {
		return Marked{}, err
	}
	if out[Item{ExerciseID: exerciseID, Version: e.version}] {
		return Marked{}, ErrWithdrawn
	}

	perm, version, err := s.drawn(ctx, tenantID, accountID, exerciseID)
	if err != nil {
		return Marked{}, err
	}

	original, err := grade.Restore(e.kind, answer, perm)
	if err != nil {
		return Marked{}, fmt.Errorf("%w: %w", ErrBadAnswer, err)
	}

	result, err := grade.Grade(e.kind, e.payload, original)
	if err != nil {
		/* A MALFORMED ANSWER IS NOT A WRONG ONE. Recording it as wrong would
		   move a schedule on the strength of a client's bug, and the student
		   would find a card they never failed coming back tomorrow. */
		return Marked{}, fmt.Errorf("%w: %w", ErrBadAnswer, err)
	}
	correct := result.Correct

	/* WHAT THE ANSWER WAS, for the screen to draw over what they gave. A type
	   with nothing to add answers an empty reveal and the renderer needs
	   nothing — see reveal.go — so this is not an error to be tolerated but a
	   real answer, and only a failure to READ the question is one. */
	revealed, err := grade.Expected(e.kind, e.payload, perm)
	if err != nil {
		return Marked{}, fmt.Errorf("practice: revealing %q: %w", exerciseID, err)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Marked{}, fmt.Errorf("practice: recording an answer: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	before, err := s.stateIn(ctx, tx, tenantID, accountID, exerciseID)
	if err != nil {
		return Marked{}, err
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
		return Marked{}, fmt.Errorf("practice: writing the state of %q: %w", exerciseID, err)
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
	`, tenantID, accountID, exerciseID, version, e.sectionID,
		correct, quality, elapsed.Milliseconds(),
		before.Interval, after.Interval, before.Ease, after.Ease,
		before.Repetition, after.Repetition, Scheduler); err != nil {
		return Marked{}, fmt.Errorf("practice: writing the review of %q: %w", exerciseID, err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Marked{}, fmt.Errorf("practice: recording an answer: %w", err)
	}
	return Marked{Result: result, State: after, Reveal: revealed}, nil
}

// ErrBadAnswer is an answer this question cannot be marked against — the wrong
// shape, the wrong number of blanks, a list of a different length.
//
// IT IS NOT A WRONG ANSWER. Recording it as one would move a schedule on the
// strength of a client's bug: a card the student never failed would come back
// tomorrow, and the review log would carry a failure that never happened.
var ErrBadAnswer = errors.New("practice: that answer cannot be marked")

// drawn reads how this card was last put in front of this student.
func (s *Store) drawn(ctx context.Context, tenantID, accountID uuid.UUID,
	exerciseID string) ([]int, int, error) {

	var perm []int
	var version int
	err := s.pool.QueryRow(ctx, `
		SELECT perm, exercise_version FROM practice_drawn
		WHERE tenant_id = $1 AND account_id = $2 AND exercise_id = $3
	`, tenantID, accountID, exerciseID).Scan(&perm, &version)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, 0, ErrNotDrawn
	}
	if err != nil {
		return nil, 0, fmt.Errorf("practice: reading the draw of %q: %w", exerciseID, err)
	}

	// An empty array is a question with nothing to shuffle. `Restore` wants nil
	// for that, and the round trip through the database cannot preserve the
	// difference — so it is restored here, once, rather than guessed at by
	// every grader.
	if len(perm) == 0 {
		perm = nil
	}
	return perm, version, nil
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

// One question as this package needs it. A struct rather than five return
// values, which is what it was until the payload made it six.
type question struct {
	courseID  string
	version   int
	sectionID string
	kind      string
	drillable bool
	payload   json.RawMessage
}

func (s *Store) exercise(ctx context.Context, tenantID uuid.UUID, exerciseID string) (question, error) {
	var q question
	err := s.pool.QueryRow(ctx, `
		SELECT course_id, version, section_id, type, drillable, payload
		FROM catalog_exercises
		WHERE tenant_id = $1 AND id = $2
	`, tenantID, exerciseID).Scan(&q.courseID, &q.version, &q.sectionID,
		&q.kind, &q.drillable, &q.payload)

	if errors.Is(err, pgx.ErrNoRows) {
		return question{}, ErrNoSuchExercise
	}
	if err != nil {
		return question{}, fmt.Errorf("practice: reading the exercise %q: %w", exerciseID, err)
	}
	return q, nil
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

/* ---------- what the student has answered ---------- */

// Answer is one review, as a report on the student's own work reads it.
//
// IT IS THE LOG AND NOT THE SCHEDULER'S STATE. `practice_state` says when a
// card comes back; this says what happened, every time, and it is append-only
// (A-03) — which is what makes a rate over it a fact rather than a snapshot
// that moves when somebody answers again.
type Answer struct {
	ExerciseID string    `json:"exercise"`
	CourseID   string    `json:"course"`
	SectionID  string    `json:"section,omitempty"`
	Type       string    `json:"type"`
	Correct    bool      `json:"correct"`
	ReviewedAt time.Time `json:"reviewed_at"`
}

// History answers everything one student has answered in one school, newest
// first.
//
// THE TYPE AND THE COURSE COME FROM THE CATALOGUE, joined here rather than
// carried on the log. They are facts about the QUESTION and not about the
// answer: an exercise moved to another lesson is still the same exercise, and a
// report grouped by a course id copied at answer time would be grouping by
// where the question used to live. The log keeps what it alone knows — that
// this person got this version right at this moment.
//
// An exercise the catalogue no longer has drops out of the report rather than
// appearing under a blank heading. The row stays in the log, which is the point
// of an append-only log; what cannot be shown is which course it belonged to.
func (s *Store) History(ctx context.Context, tenantID, accountID uuid.UUID) ([]Answer, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT r.exercise_id, e.course_id, r.section_id, e.type, r.correct, r.reviewed_at
		FROM practice_review r
		JOIN catalog_exercises e
		  ON e.tenant_id = r.tenant_id AND e.id = r.exercise_id
		WHERE r.tenant_id = $1 AND r.account_id = $2
		ORDER BY r.reviewed_at DESC
	`, tenantID, accountID)
	if err != nil {
		return nil, fmt.Errorf("practice: reading what a student has answered: %w", err)
	}
	defer rows.Close()

	out := []Answer{}
	for rows.Next() {
		var a Answer
		if err := rows.Scan(&a.ExerciseID, &a.CourseID, &a.SectionID,
			&a.Type, &a.Correct, &a.ReviewedAt); err != nil {
			return nil, fmt.Errorf("practice: reading what a student has answered: %w", err)
		}
		out = append(out, a)
	}
	return out, rows.Err()
}
