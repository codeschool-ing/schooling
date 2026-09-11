// Package lesson is answering the questions inside a lesson.
//
// # THE THIRD INSTRUMENT, AND THE SMALLEST
//
// `internal/exam` seals a paper and marks it once. `internal/practice`
// schedules a card and brings it back when it is due. This does neither, and
// the reason is A-10: a lesson's questions carry NO MARK. Wrong is marked, the
// option's own `why` says what the misunderstanding was, and the student
// carries on. There is no score to keep and nothing to sit again.
//
// # SO IT STORES NOTHING, WHICH IS A CONSEQUENCE AND NOT A SHORTCUT
//
// The drill writes down the permutation it presented a card with, because the
// answer comes back in the frame the student saw and has to be mapped back —
// and the exam seals the whole paper for the same reason, one step further.
// Both of them must: a drill schedules on the result and an exam is scored on
// it, so a client that could change the mapping could change the outcome.
//
// HERE THERE IS NO OUTCOME. The permutation goes out with the question and
// comes back with the answer, through the client, and a client that sends a
// different one marks its own answer wrongly and gains nothing at all. That is
// only true while A-10 holds. **The day a lesson carries a mark, this has to
// move server-side**, and this paragraph is why the change would be larger than
// it looks.
//
// # AN EXAM QUESTION IS REFUSED HERE
//
// The mirror of the drill's `drillable` guard, and the same reason: a course's
// exam pool lives in the same table, and a route that served "the questions of
// this lesson" without asking would be a route that hands over the paper if an
// exam question ever carried a lesson id. It is checked rather than trusted.
//
// # ONE PERSON'S SCHOOL IS ONE PERSON'S
//
// Every query leads with the tenant. Row-level security is deliberately absent
// (P-05), so that boundary is this code and the tests that hold it to it. The
// paywall and the quarantine arrive as callbacks, because the catalogue is
// another module and modules meet in `cmd/`.
package lesson

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/grade"
)

// MayOpen answers whether this student may open that course. It is the paywall,
// and it is a function because the answer belongs to billing and the question
// belongs here.
type MayOpen func(ctx context.Context, courseID string) (bool, error)

// Item is one version of one question, which is the grain a withdrawal has:
// `C-16` versions a question, so quarantining one must not silently withdraw
// the correction that followed it.
type Item struct {
	ExerciseID string
	Version    int
}

// Quarantined is the set of questions out of circulation in a school.
type Quarantined func(ctx context.Context, tenantID uuid.UUID) (map[Item]bool, error)

var (
	// ErrNoSuchExercise covers both "no such question" and "not in this
	// school". One error on purpose: telling them apart tells a stranger which
	// ids exist.
	ErrNoSuchExercise = errors.New("lesson: no such exercise")

	// ErrIsAnExamQuestion is a question that belongs to a course's exam. It is
	// not a "not found", because it is found and deliberately not served.
	ErrIsAnExamQuestion = errors.New("lesson: that exercise belongs to an exam")

	// ErrLocked is a course this student's plan does not open.
	ErrLocked = errors.New("lesson: that course is not open to this student")

	// ErrWithdrawn is a question taken out of circulation.
	ErrWithdrawn = errors.New("lesson: that question is out of circulation")
)

// Store reads a lesson's questions and marks an answer to one.
type Store struct {
	pool *pgxpool.Pool
	may  MayOpen

	// Nil is "nothing is out of circulation", which is what a school looks like
	// before anything has been measured.
	quarantined Quarantined
}

// NewStore wires the two questions this package cannot answer itself.
func NewStore(pool *pgxpool.Pool, may MayOpen, quarantined Quarantined) *Store {
	return &Store{pool: pool, may: may, quarantined: quarantined}
}

// Question is one question as the student holds it.
//
// THERE IS NO FIELD HERE FOR THE ANSWER KEY. `Shown` is what `grade.Present`
// produced, which is the payload with its answer removed and its order
// shuffled; the key stays in the database until an answer arrives to compare
// it with.
type Question struct {
	ExerciseID string          `json:"exercise"`
	Version    int             `json:"version"`
	Section    string          `json:"section"`
	Type       string          `json:"type"`
	Difficulty string          `json:"difficulty,omitempty"`
	Shown      json.RawMessage `json:"question"`

	// Perm maps a position in the shown form back to the position it had in the
	// file. It goes to the client and comes back with the answer — see the
	// package comment for why that is safe HERE and nowhere else.
	Perm []int `json:"perm,omitempty"`
}

// Marked is one answer, marked.
type Marked struct {
	grade.Result

	// THE KEY, AND ONLY ONCE THERE IS AN ANSWER TO COMPARE IT WITH. A lesson
	// that said "wrong" and stopped would leave a student knowing they do not
	// know, which is the half of the feedback that teaches nothing — and under
	// A-10 the other half is the whole point of the question. It is in the
	// frame the student saw.
	Reveal grade.Reveal `json:"reveal"`
}

type row struct {
	courseID   string
	sectionID  string
	version    int
	kind       string
	difficulty string
	exam       bool
	payload    json.RawMessage
}

// Questions presents every question of one lesson.
//
// IT ANSWERS A SET AND NOT ONE QUESTION, because a lesson screen draws all of
// them at once and asking per question would be one request per question on a
// screen that already knows how many there are.
func (s *Store) Questions(ctx context.Context, tenantID uuid.UUID,
	courseID, lessonID, locale string) ([]Question, error) {

	allowed, err := s.may(ctx, courseID)
	if err != nil {
		return nil, err
	}
	if !allowed {
		return nil, ErrLocked
	}

	out, err := s.outOfCirculation(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	// `NOT e.exam` in the WHERE and not only in a check afterwards: a paper that
	// is never selected cannot be served by a bug further down.
	rows, err := s.pool.Query(ctx, `
		SELECT e.id, e.section_id, e.version, e.type, e.difficulty,
		       coalesce(t.payload, e.payload)
		FROM catalog_exercises e
		LEFT JOIN catalog_exercise_text t
		       ON t.tenant_id = e.tenant_id AND t.exercise_id = e.id AND t.locale = $4
		WHERE e.tenant_id = $1 AND e.course_id = $2 AND e.lesson_id = $3
		  AND NOT e.exam
		ORDER BY e.section_id, e.id
	`, tenantID, courseID, lessonID, locale)
	if err != nil {
		return nil, fmt.Errorf("lesson: reading the questions of %q: %w", lessonID, err)
	}
	defer rows.Close()

	// ONE SOURCE OF RANDOMNESS FOR THE WHOLE SET, seeded from crypto/rand by
	// NewShuffler: the sequence is math/rand and the seed is not, which is the
	// split that keeps a presentation unguessable without pretending a shuffle
	// is a secret.
	rnd := grade.NewShuffler()

	var out2 []Question
	for rows.Next() {
		var id string
		var r row
		if err := rows.Scan(&id, &r.sectionID, &r.version, &r.kind, &r.difficulty, &r.payload); err != nil {
			return nil, fmt.Errorf("lesson: reading a question of %q: %w", lessonID, err)
		}

		// A WITHDRAWN QUESTION IS LEFT OUT RATHER THAN REFUSED. A lesson is not
		// a paper: one question fewer is a shorter section, where an exam with
		// a hole in it would be scored out of the wrong number. `exam.go`
		// refuses for exactly that reason and this does not.
		if out[Item{ExerciseID: id, Version: r.version}] {
			continue
		}

		presented, err := grade.Present(r.kind, r.payload, rnd)
		if err != nil {
			return nil, fmt.Errorf("lesson: presenting %q: %w", id, err)
		}
		out2 = append(out2, Question{
			ExerciseID: id,
			Version:    r.version,
			Section:    r.sectionID,
			Type:       r.kind,
			Difficulty: r.difficulty,
			Shown:      presented.Shown,
			Perm:       presented.Perm,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("lesson: reading the questions of %q: %w", lessonID, err)
	}
	return out2, nil
}

// Answered marks one answer and gives back the key.
//
// THE SERVER DECIDES WHETHER IT WAS RIGHT. The question the client was given
// has no key in it, so "correct" arriving over the wire could only ever be an
// assertion nothing checked. `internal/grade` marks it here, against the
// payload, exactly as an exam and a drill are marked.
//
// NOTHING IS WRITTEN. Under A-10 there is no score to record, and what a wrong
// answer is worth — an observation for `internal/analysis` — is carried by the
// event stream (K-03) rather than by a row here.
func (s *Store) Answered(ctx context.Context, tenantID uuid.UUID,
	exerciseID string, perm []int, answer json.RawMessage, locale string) (Marked, error) {

	r, err := s.exercise(ctx, tenantID, exerciseID, locale)
	if err != nil {
		return Marked{}, err
	}
	if r.exam {
		return Marked{}, ErrIsAnExamQuestion
	}

	allowed, err := s.may(ctx, r.courseID)
	if err != nil {
		return Marked{}, err
	}
	if !allowed {
		return Marked{}, ErrLocked
	}

	// WITHDRAWN IS REFUSED HERE even though `Questions` merely omits it: a
	// screen fetched before a sweep still holds the question, and answering it
	// would produce a verdict from a key the school has stopped standing
	// behind.
	out, err := s.outOfCirculation(ctx, tenantID)
	if err != nil {
		return Marked{}, err
	}
	if out[Item{ExerciseID: exerciseID, Version: r.version}] {
		return Marked{}, ErrWithdrawn
	}

	// THE ANSWER COMES BACK IN THE FRAME THE STUDENT SAW and is mapped through
	// the permutation before anything is compared. Without this step every
	// `ordering` answer is marked against a sequence nobody was shown.
	original, err := grade.Restore(r.kind, answer, perm)
	if err != nil {
		return Marked{}, fmt.Errorf("lesson: restoring the answer to %q: %w", exerciseID, err)
	}
	result, err := grade.Grade(r.kind, r.payload, original)
	if err != nil {
		return Marked{}, fmt.Errorf("lesson: marking %q: %w", exerciseID, err)
	}
	reveal, err := grade.Expected(r.kind, r.payload, perm)
	if err != nil {
		return Marked{}, fmt.Errorf("lesson: revealing %q: %w", exerciseID, err)
	}
	return Marked{Result: result, Reveal: reveal}, nil
}

func (s *Store) exercise(ctx context.Context, tenantID uuid.UUID,
	exerciseID, locale string) (row, error) {

	var r row
	err := s.pool.QueryRow(ctx, `
		SELECT e.course_id, e.section_id, e.version, e.type, e.difficulty, e.exam,
		       coalesce(t.payload, e.payload)
		FROM catalog_exercises e
		LEFT JOIN catalog_exercise_text t
		       ON t.tenant_id = e.tenant_id AND t.exercise_id = e.id AND t.locale = $3
		WHERE e.tenant_id = $1 AND e.id = $2
	`, tenantID, exerciseID, locale).Scan(&r.courseID, &r.sectionID, &r.version,
		&r.kind, &r.difficulty, &r.exam, &r.payload)

	if errors.Is(err, pgx.ErrNoRows) {
		return row{}, ErrNoSuchExercise
	}
	if err != nil {
		return row{}, fmt.Errorf("lesson: reading the exercise %q: %w", exerciseID, err)
	}
	return r, nil
}

// outOfCirculation is the set, or an empty one when nothing is wired in.
func (s *Store) outOfCirculation(ctx context.Context, tenantID uuid.UUID) (map[Item]bool, error) {
	if s.quarantined == nil {
		return nil, nil
	}
	return s.quarantined(ctx, tenantID)
}
