// Package exam is sitting one: drawing a paper, keeping it, and marking it.
//
// # WITHOUT A HUMAN REVIEWER, THE EXAM IS THE ONLY ASSERTION THAT ANYBODY KNOWS
// # ANYTHING
//
// Every other signal this platform has is about effort: sections finished,
// lessons opened, days in a row. The exam is the one moment the system says the
// student knows the material, and a certificate rests on it (A-08). So it is
// built to be defensible rather than convenient, and the three properties below
// are what that means.
//
// # ONE: THE PAPER IS SEALED WHEN IT IS DRAWN
//
// Every question is copied into the attempt at the moment it is drawn — what
// the student is shown, the permutation behind it, and the question as it was
// written. Nothing is read back out of the catalogue afterwards.
//
// The catalogue is a mirror of files and the load job rewrites it on every
// content deploy (C-01). Without the copy, a student who started an exam before
// a deploy is marked against questions they never saw, or against a question
// that no longer exists — and the failure is silent, because both halves look
// perfectly consistent on their own.
//
// # TWO: ONE OPEN ATTEMPT AT A TIME
//
// Starting an exam that is already open resumes it. This is not a convenience
// for the student whose browser crashed; it is the integrity of the exam. If a
// second start drew a second paper, the way to pass would be to start, read,
// abandon and start again until the questions are ones you like — and every one
// of those draws is an ordinary-looking row that no report would ever flag. A
// partial unique index in the schema is what actually enforces it, because a
// check in a handler loses to two taps at once.
//
// # THREE: NOTHING KNOWS THE RESULT UNTIL THE PAPER IS HANDED IN
//
// Answers may be changed until submission, because that is what sitting an exam
// is, and `correct` stays null the whole time. Grading happens once, at
// submission, over the sealed questions. There is no moment where a row in the
// database holds the result of a question the student is still looking at, so
// there is no endpoint that could leak one.
//
// # WHAT THIS PACKAGE DOES NOT DO
//
// It does not decide whether the student may sit the exam — that is the
// paywall, and it arrives as a callback because the catalogue is another module
// and modules meet in cmd/. It does not issue certificates. And it does not cap
// the number of attempts: a cap is a product decision nobody has made, and
// inventing one here would be the wrong place to make it.
package exam

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

// PassMark is the share of an exam's questions a student has to get right,
// in whole percent.
//
// IT LIVES IN CODE AND A TEST HOLDS IT (K-13). Only something without a right
// answer becomes a configurable parameter; a pass mark somebody can move from a
// console is a certificate that means whatever it meant on the day, and the
// first time it is lowered there is no record of what the old one was. Every
// attempt records the mark it was judged by, so moving this constant later
// changes what a NEW attempt has to reach and nothing about an old one.
const PassMark = 70

// QuestionsPerAttempt is how long a paper is when the pool is longer.
//
// A pool smaller than this is asked in full — which is the normal case for a
// course exam, and it is not a lesser exam for it. Drawing is what stops a pool
// of two hundred from being memorised one attempt at a time.
const QuestionsPerAttempt = 20

// Scope is which kind of exam. The course exam issues a certificate; the track
// exam is the final (A-08).
type Scope string

const (
	ScopeCourse Scope = "course"
	ScopeTrack  Scope = "track"
)

// The errors a caller distinguishes. Everything else is an internal failure and
// arrives wrapped.
var (
	// ErrNoSuchExam is a course or a track with no exam questions. It is not an
	// empty paper: an exam with no questions would be passed by everybody at
	// once, so there is no such thing as one.
	ErrNoSuchExam = errors.New("exam: there is no exam for that")

	// ErrLocked is a student who may not sit it. The same 402 the catalogue and
	// progress give, for the same reason: it is a purchase, not a permission.
	ErrLocked = errors.New("exam: that exam is not open to this student")

	// ErrNoSuchAttempt covers both "no such attempt" and "not this student's".
	// ONE ERROR ON PURPOSE: distinguishing them tells a stranger which attempt
	// ids exist, and there is nothing a student can do with either answer that
	// they cannot do with the same one.
	ErrNoSuchAttempt = errors.New("exam: no such attempt")

	// ErrHandedIn is an attempt that is over. The schema refuses it too, with a
	// trigger; this is the same rule said early enough to be a decent reply.
	ErrHandedIn = errors.New("exam: that exam was handed in and cannot be changed")

	// ErrNoSuchQuestion is a position that is not on the paper.
	ErrNoSuchQuestion = errors.New("exam: that question is not on this paper")

	// ErrBadAnswer is an answer that is not shaped like an answer to its
	// question — a client fault, and distinct from a student being wrong.
	ErrBadAnswer = errors.New("exam: that is not an answer to that question")
)

// MaySit answers whether this student may sit this exam.
//
// It is a callback because the answer belongs to the catalogue and to billing,
// and this module may import neither. For a course it is whether the course is
// open; for a track it is whether every course in it is.
type MaySit func(ctx context.Context, scope Scope, id string) (bool, error)

// Item is one exercise at one version, which is the unit a quarantine applies
// to: a new version is a different question.
//
// It is `Item` and not `Question` because `Question` here is the thing a
// student holds, with its prompt and its answer — and item analysis calls this
// one an item, which is where the word comes from.
type Item struct {
	ExerciseID string
	Version    int
}

// Quarantined answers which questions are out of circulation in this school.
//
// A callback for the same reason MaySit is: the answer belongs to the module
// that reads how people answered, and this one may not import it. `cmd/` joins
// them.
//
// IT ANSWERS A SET AND NOT ONE QUESTION. The draw already holds the whole pool
// and the marking holds the whole paper, so asking once is both cheaper and
// more correct — a lookup per question could include one and exclude the next
// under a quarantine written in between.
type Quarantined func(ctx context.Context, tenantID uuid.UUID) (map[Item]bool, error)

type Store struct {
	pool   *pgxpool.Pool
	maySit MaySit

	// Which questions are out of circulation. Nil is "none", which is what an
	// exam looks like before anything has been measured — and it is the safe
	// default, because the failure it produces is a question that keeps being
	// asked rather than an exam that cannot be sat.
	quarantined Quarantined
}

func NewStore(pool *pgxpool.Pool, maySit MaySit, quarantined Quarantined) *Store {
	return &Store{pool: pool, maySit: maySit, quarantined: quarantined}
}

// outOfCirculation is the set, or an empty one when nothing is wired in.
func (s *Store) outOfCirculation(ctx context.Context, tenantID uuid.UUID) (map[Item]bool, error) {
	if s.quarantined == nil {
		return nil, nil
	}
	return s.quarantined(ctx, tenantID)
}

// Question is one question as the student holds it.
//
// THERE IS NO FIELD HERE FOR THE ANSWER KEY, and that is deliberate rather than
// incidental: the row this is read from has one, in a column called `sealed`,
// and the only query in the repository that names that column is the one that
// grades a submission.
type Question struct {
	Position   int    `json:"position"`
	ExerciseID string `json:"exercise"`
	Version    int    `json:"version"`
	Type       string `json:"type"`

	// Shown is the question with its answer removed and, where the order is the
	// answer, shuffled.
	Shown json.RawMessage `json:"question"`

	// Answer is what the student gave, echoed back so a reopened paper shows
	// their own work. Absent while unanswered.
	Answer json.RawMessage `json:"answer,omitempty"`

	// Correct is null until the paper is handed in. A pointer rather than a
	// bool, so "not marked yet" and "marked wrong" are different things all the
	// way to the client.
	Correct *bool `json:"correct,omitempty"`
}

// Paper is an attempt and everything on it.
type Paper struct {
	AttemptID uuid.UUID  `json:"attempt"`
	Scope     Scope      `json:"scope"`
	ScopeID   string     `json:"exam"`
	StartedAt time.Time  `json:"started_at"`
	HandedIn  *time.Time `json:"handed_in_at,omitempty"`

	Questions []Question `json:"questions"`

	// PassMark is the share this paper has to reach, in whole percent, and it is
	// here rather than only on the Result.
	//
	// THE SCREEN SAYS "MINIMUM TO PASS" BEFORE A SINGLE QUESTION IS ANSWERED, and
	// until this field existed the only place that number appeared was on the
	// result — after the exam, when it is too late to be the rule somebody was
	// told. So the interface held a `PASS_MARK = 70` of its own and showed that,
	// which is two copies of one decision: move this constant and an exam is
	// marked at the new number while being described as the old one.
	//
	// It is on every paper, handed in or not, so no screen ever has to guess.
	PassMark int `json:"pass_mark"`

	// Absent until it is handed in.
	Result *Result `json:"result,omitempty"`
}

// Result is the mark.
type Result struct {
	Score    int  `json:"score"`
	Of       int  `json:"of"`
	PassMark int  `json:"pass_mark"`
	Passed   bool `json:"passed"`
}

// Summary is one line of a student's exam history.
type Summary struct {
	AttemptID uuid.UUID  `json:"attempt"`
	Scope     Scope      `json:"scope"`
	ScopeID   string     `json:"exam"`
	StartedAt time.Time  `json:"started_at"`
	HandedIn  *time.Time `json:"handed_in_at,omitempty"`
	Result    *Result    `json:"result,omitempty"`
}

/* ---------- starting ---------- */

// Start opens an attempt, or answers the one that is already open.
//
// `resumed` says which of the two happened, so the caller counts a start once
// rather than once per reload.
func (s *Store) Start(ctx context.Context, tenantID, accountID uuid.UUID,
	scope Scope, scopeID, locale string) (paper *Paper, resumed bool, err error) {

	if scope != ScopeCourse && scope != ScopeTrack {
		return nil, false, fmt.Errorf("%w: %q is not a kind of exam", ErrNoSuchExam, scope)
	}

	open, err := s.maySit(ctx, scope, scopeID)
	if err != nil {
		return nil, false, fmt.Errorf("exam: deciding whether %s %q is open: %w", scope, scopeID, err)
	}
	if !open {
		return nil, false, ErrLocked
	}

	// The open attempt, if there is one. Read before the draw so that the
	// ordinary case — a student coming back to a paper — costs one query.
	if id, found, err := s.openAttempt(ctx, tenantID, accountID, scope, scopeID); err != nil {
		return nil, false, err
	} else if found {
		paper, err := s.Attempt(ctx, tenantID, accountID, id)
		return paper, true, err
	}

	id, err := s.draw(ctx, tenantID, accountID, scope, scopeID, locale)
	if errors.Is(err, errAlreadyOpen) {
		// TWO TAPS AT ONCE, and the partial unique index caught the second. The
		// first one's paper is the answer — which is the whole point of the
		// index, so this is a resume and not a failure.
		id, found, err := s.openAttempt(ctx, tenantID, accountID, scope, scopeID)
		if err != nil {
			return nil, false, err
		}
		if !found {
			return nil, false, errors.New("exam: an attempt was open and then was not")
		}
		paper, err := s.Attempt(ctx, tenantID, accountID, id)
		return paper, true, err
	}
	if err != nil {
		return nil, false, err
	}

	paper, err = s.Attempt(ctx, tenantID, accountID, id)
	return paper, false, err
}

func (s *Store) openAttempt(ctx context.Context, tenantID, accountID uuid.UUID,
	scope Scope, scopeID string) (uuid.UUID, bool, error) {

	var id uuid.UUID
	err := s.pool.QueryRow(ctx, `
		SELECT id FROM exam_attempts
		WHERE tenant_id = $1 AND account_id = $2 AND scope = $3 AND scope_id = $4
		  AND submitted_at IS NULL
	`, tenantID, accountID, scope, scopeID).Scan(&id)

	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, false, nil
	}
	if err != nil {
		return uuid.Nil, false, fmt.Errorf("exam: looking for an open attempt: %w", err)
	}
	return id, true, nil
}

// errAlreadyOpen is the unique index in exam_attempts, recognised rather than
// reported. It is internal: Start turns it into a resume.
var errAlreadyOpen = errors.New("exam: an attempt is already open")

// pooled is one question as it comes out of the catalogue, on its way onto a
// paper. `payload` is the whole question, answer key included.
type pooled struct {
	id      string
	version int
	kind    string
	payload json.RawMessage
}

// draw builds a paper and writes it, in one transaction.
// THE PAPER IS DRAWN IN ONE LANGUAGE AND STAYS IN IT. The questions are copied
// onto the attempt, so a student who changes language halfway through keeps the
// paper they were given — which is what a paper is. It is also what keeps the
// mark honest: the answer is graded against the payload stored WITH the
// attempt, and a paper that could change under a student mid-exam would be a
// question rewritten between reading it and answering it.
func (s *Store) draw(ctx context.Context, tenantID, accountID uuid.UUID,
	scope Scope, scopeID, locale string) (uuid.UUID, error) {

	pool, err := s.pool.Query(ctx, `
		SELECT e.id, e.version, e.type, coalesce(t.payload, e.payload)
		FROM catalog_exercises e
		LEFT JOIN catalog_exercise_text t
		       ON t.tenant_id = e.tenant_id AND t.exercise_id = e.id AND t.locale = $4
		WHERE e.tenant_id = $1 AND e.exam
		  AND e.course_id = $2 AND e.track_id = $3
		ORDER BY e.id
	`, tenantID, courseOf(scope, scopeID), trackOf(scope, scopeID), locale)
	if err != nil {
		return uuid.Nil, fmt.Errorf("exam: reading the pool of %s %q: %w", scope, scopeID, err)
	}

	var questions []pooled
	for pool.Next() {
		var q pooled
		if err := pool.Scan(&q.id, &q.version, &q.kind, &q.payload); err != nil {
			pool.Close()
			return uuid.Nil, fmt.Errorf("exam: reading the pool of %s %q: %w", scope, scopeID, err)
		}
		questions = append(questions, q)
	}
	pool.Close()
	if err := pool.Err(); err != nil {
		return uuid.Nil, fmt.Errorf("exam: reading the pool of %s %q: %w", scope, scopeID, err)
	}
	if len(questions) == 0 {
		return uuid.Nil, fmt.Errorf("%w: %s %q has no questions", ErrNoSuchExam, scope, scopeID)
	}

	// WHAT IS OUT OF CIRCULATION NEVER REACHES A PAPER. A question the strong
	// students fail is one we already know is broken, and every student who
	// meets it after that is being marked on our mistake.
	out, err := s.outOfCirculation(ctx, tenantID)
	if err != nil {
		return uuid.Nil, fmt.Errorf("exam: reading what is out of circulation: %w", err)
	}
	if len(out) > 0 {
		kept := questions[:0]
		for _, q := range questions {
			if !out[Item{ExerciseID: q.id, Version: q.version}] {
				kept = append(kept, q)
			}
		}
		questions = kept
	}

	// AND AN EXAM WITH NOTHING LEFT REFUSES RATHER THAN SETTING AN EMPTY PAPER.
	// A student handed a paper of nothing would pass it — the score is out of
	// what was asked — and a certificate would follow. It is a loud failure on
	// purpose: it means a whole pool was quarantined, which is a content
	// emergency and not a thing to absorb quietly.
	if len(questions) == 0 {
		return uuid.Nil, fmt.Errorf(
			"%w: every question of %s %q is out of circulation", ErrNoSuchExam, scope, scopeID)
	}

	// ONE SOURCE OF RANDOMNESS FOR THE WHOLE PAPER: which questions are drawn
	// and how each is shuffled. Seeded from crypto/rand by NewShuffler, because
	// a paper whose draw can be reproduced is a paper somebody who has already
	// sat the exam can map their answers onto.
	rnd := grade.NewShuffler()

	order := make([]int, len(questions))
	for i := range order {
		order[i] = i
	}
	rnd.Shuffle(len(order), func(i, j int) { order[i], order[j] = order[j], order[i] })
	if len(order) > QuestionsPerAttempt {
		order = order[:QuestionsPerAttempt]
	}

	drawn := make([]pooled, len(order))
	shown := make([]grade.Presented, len(order))
	for at, from := range order {
		q := questions[from]
		presented, err := grade.Present(q.kind, q.payload, rnd)
		if err != nil {
			// A question nothing knows how to redact must not reach a student
			// with its answer attached, and there is no half-safe way to serve
			// it. The content checks refuse a type with no grader, so reaching
			// here means the catalogue and this build disagree — which is worth
			// failing the whole draw over rather than quietly asking one
			// question fewer.
			return uuid.Nil, fmt.Errorf("exam: %s %q cannot be sat: the question %q is a %q: %w",
				scope, scopeID, q.id, q.kind, err)
		}
		drawn[at], shown[at] = q, presented
	}

	var attemptID uuid.UUID
	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		err := tx.QueryRow(ctx, `
			INSERT INTO exam_attempts (tenant_id, account_id, scope, scope_id)
			VALUES ($1, $2, $3, $4) RETURNING id
		`, tenantID, accountID, scope, scopeID).Scan(&attemptID)
		if err != nil {
			if isUniqueViolation(err) {
				return errAlreadyOpen
			}
			return fmt.Errorf("exam: opening an attempt: %w", err)
		}

		for at := range drawn {
			perm := shown[at].Perm
			if perm == nil {
				perm = []int{}
			}
			if _, err := tx.Exec(ctx, `
				INSERT INTO exam_answers
					(attempt_id, position, exercise_id, exercise_version, type,
					 shown, perm, sealed)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			`, attemptID, at, drawn[at].id, drawn[at].version, drawn[at].kind,
				[]byte(shown[at].Shown), perm, []byte(drawn[at].payload)); err != nil {
				return fmt.Errorf("exam: writing question %d of a paper: %w", at, err)
			}
		}
		return nil
	})
	if err != nil {
		return uuid.Nil, err
	}
	return attemptID, nil
}

// isUniqueViolation recognises the partial index that keeps one attempt open.
// By SQLSTATE and through an interface, so that recognising it does not mean
// importing the driver's error type into a package that has no other reason to
// know which driver this is.
func isUniqueViolation(err error) bool {
	var pg interface{ SQLState() string }
	return errors.As(err, &pg) && pg.SQLState() == "23505"
}

// A question hangs off a course or off a track, and exactly one of the two
// columns is set. These two say which, so the query above is one query rather
// than two nearly identical ones.
func courseOf(scope Scope, id string) string {
	if scope == ScopeCourse {
		return id
	}
	return ""
}

func trackOf(scope Scope, id string) string {
	if scope == ScopeTrack {
		return id
	}
	return ""
}

/* ---------- answering ---------- */

// Answer records what a student gave for one question, replacing whatever was
// there.
//
// THE ANSWER IS STORED IN THE FRAME THE STUDENT SAW IT IN — against the
// shuffled choices, not the original ones. Restoring it is grading's job, and
// storing the restored form would mean an export handing somebody back an
// answer expressed against a question they were never shown.
//
// It is checked for shape now rather than at submission. A client sending
// nonsense should hear about it while the student can still do something, and
// an answer that could not be read at marking time would be indistinguishable
// from a wrong one.
func (s *Store) Answer(ctx context.Context, tenantID, accountID, attemptID uuid.UUID,
	position int, answer json.RawMessage) error {

	return pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		// FOR UPDATE, so that answering and handing in cannot interleave. Without
		// it an answer can land between the marking of a paper and the freezing
		// of the attempt, and the score no longer explains the rows it came from.
		var submitted *time.Time
		err := tx.QueryRow(ctx, `
			SELECT submitted_at FROM exam_attempts
			WHERE id = $1 AND tenant_id = $2 AND account_id = $3
			FOR UPDATE
		`, attemptID, tenantID, accountID).Scan(&submitted)
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNoSuchAttempt
		}
		if err != nil {
			return fmt.Errorf("exam: reading an attempt: %w", err)
		}
		if submitted != nil {
			return ErrHandedIn
		}

		var kind string
		var perm []int
		err = tx.QueryRow(ctx, `
			SELECT type, perm FROM exam_answers WHERE attempt_id = $1 AND position = $2
		`, attemptID, position).Scan(&kind, &perm)
		if errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("%w: position %d", ErrNoSuchQuestion, position)
		}
		if err != nil {
			return fmt.Errorf("exam: reading a question: %w", err)
		}

		if _, err := grade.Restore(kind, answer, perm); err != nil {
			return fmt.Errorf("%w: %w", ErrBadAnswer, err)
		}

		if _, err := tx.Exec(ctx, `
			UPDATE exam_answers SET answer = $3, answered_at = now()
			WHERE attempt_id = $1 AND position = $2
		`, attemptID, position, []byte(answer)); err != nil {
			return fmt.Errorf("exam: recording an answer: %w", err)
		}
		return nil
	})
}

/* ---------- handing in ---------- */

// Submit marks a paper.
//
// `marked` says whether this call was the one that did it. A second submission
// answers the same paper rather than failing, because handing in twice is a
// double tap and not an attack — but the caller must not count it twice, and
// nothing about the attempt moves the second time.
//
// AN UNANSWERED QUESTION IS WRONG, not an error and not excluded. A paper
// marked out of the questions somebody chose to attempt would let a student
// answer the one they were sure of and score a hundred percent.
func (s *Store) Submit(ctx context.Context, tenantID, accountID, attemptID uuid.UUID) (
	paper *Paper, marked bool, err error) {

	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		var submitted *time.Time
		err := tx.QueryRow(ctx, `
			SELECT submitted_at FROM exam_attempts
			WHERE id = $1 AND tenant_id = $2 AND account_id = $3
			FOR UPDATE
		`, attemptID, tenantID, accountID).Scan(&submitted)
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNoSuchAttempt
		}
		if err != nil {
			return fmt.Errorf("exam: reading an attempt: %w", err)
		}
		if submitted != nil {
			return nil // already marked; `marked` stays false
		}

		// READ ONCE, OUTSIDE THE MARKING. The set is what it was at the moment
		// this paper was handed in, so every question on it is judged against
		// the same answer to "is this still asked".
		out, err := s.outOfCirculation(ctx, tenantID)
		if err != nil {
			return fmt.Errorf("exam: reading what is out of circulation: %w", err)
		}

		score, of, err := mark(ctx, tx, attemptID, out)
		if err != nil {
			return err
		}

		// Exact, in integers. See PassMark: a student sitting exactly on the
		// mark must not pass or fail depending on how a ratio rounded.
		passed := score*100 >= PassMark*of

		if _, err := tx.Exec(ctx, `
			UPDATE exam_attempts
			SET submitted_at = now(), score = $2, of = $3, pass_mark = $4, passed = $5
			WHERE id = $1
		`, attemptID, score, of, PassMark, passed); err != nil {
			return fmt.Errorf("exam: handing in an attempt: %w", err)
		}
		marked = true
		return nil
	})
	if err != nil {
		return nil, false, err
	}

	paper, err = s.Attempt(ctx, tenantID, accountID, attemptID)
	return paper, marked, err
}

// mark grades every question of a paper and writes the results back.
//
// It is where `sealed` is read, and it is the only place in the repository that
// reads it. A question is graded against the payload stored WITH THE ATTEMPT,
// never against the catalogue — see the package comment.
func mark(ctx context.Context, tx pgx.Tx, attemptID uuid.UUID,
	out map[Item]bool) (score, of int, err error) {

	rows, err := tx.Query(ctx, `
		SELECT position, exercise_id, exercise_version, type, perm, sealed, answer
		FROM exam_answers WHERE attempt_id = $1 ORDER BY position
	`, attemptID)
	if err != nil {
		return 0, 0, fmt.Errorf("exam: reading a paper to mark it: %w", err)
	}

	type judged struct {
		position int
		correct  bool

		// counts is false for a question that was taken out of circulation
		// between this paper being set and it being handed in.
		counts bool
	}
	var results []judged

	for rows.Next() {
		var position, version int
		var exercise, kind string
		var perm []int
		var sealed, answer []byte

		if err := rows.Scan(&position, &exercise, &version, &kind, &perm, &sealed, &answer); err != nil {
			rows.Close()
			return 0, 0, fmt.Errorf("exam: reading a paper to mark it: %w", err)
		}

		correct, err := judge(kind, sealed, answer, perm)
		if err != nil {
			rows.Close()
			return 0, 0, err
		}
		results = append(results, judged{
			position: position,
			correct:  correct,
			counts:   !out[Item{ExerciseID: exercise, Version: version}],
		})
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, 0, fmt.Errorf("exam: reading a paper to mark it: %w", err)
	}

	// A QUARANTINED QUESTION IS STILL MARKED AND DOES NOT COUNT.
	//
	// Marked, because the paper is a record of what was asked and what was
	// answered, and a blank where a mark should be would make an attempt
	// unreadable afterwards. Not counted, because it comes out of the
	// denominator: nobody should fail on a question we have admitted is broken,
	// and dropping it from the score is the only remedy that does not require
	// guessing what they would have answered.
	//
	// It leaves two students with the same paper scored out of different totals
	// when a quarantine lands between their submissions. That is right: the
	// second one was marked on a question we had already withdrawn, and the
	// alternative is marking them on it anyway to keep a number tidy.
	for _, r := range results {
		if _, err := tx.Exec(ctx, `
			UPDATE exam_answers SET correct = $3 WHERE attempt_id = $1 AND position = $2
		`, attemptID, r.position, r.correct); err != nil {
			return 0, 0, fmt.Errorf("exam: writing a mark: %w", err)
		}
		if !r.counts {
			continue
		}
		of++
		if r.correct {
			score++
		}
	}

	// EVERY QUESTION ON THE PAPER WITHDRAWN. Scoring out of zero is a division
	// nobody can defend, and the paper cannot be marked — so it says so rather
	// than answering nought out of nought, which reads as a fail.
	if of == 0 {
		return 0, 0, fmt.Errorf(
			"exam: every question on this paper is out of circulation, so it cannot be marked")
	}
	return score, of, nil
}

// judge is one question.
//
// THE TWO KINDS OF FAILURE ARE SEPARATED HERE, and the split is the whole
// function. An answer the grader will not read is a wrong answer — that is the
// student's problem and the paper carries on. A question the grader does not
// understand is this system being broken, and marking it wrong would quietly
// fail every student sitting that exam. So the first is a mark and the second
// stops the submission.
func judge(kind string, sealed, answer []byte, perm []int) (bool, error) {
	if len(answer) == 0 {
		return false, nil // unanswered
	}

	restored, err := grade.Restore(kind, answer, perm)
	if err != nil {
		if errors.Is(err, grade.ErrUnknownType) {
			return false, fmt.Errorf("exam: marking a %q: %w", kind, err)
		}
		return false, nil
	}

	result, err := grade.Grade(kind, sealed, restored)
	if err != nil {
		if errors.Is(err, grade.ErrBadAnswer) {
			return false, nil
		}
		return false, fmt.Errorf("exam: marking a %q: %w", kind, err)
	}
	return result.Correct, nil
}

/* ---------- reading ---------- */

// Attempt answers one paper, with every question as the student holds it.
//
// THE COLUMNS ARE NAMED AND `sealed` IS NOT AMONG THEM. This is the query a
// student's request reaches; selecting * here would put every answer key on the
// wire, and it is the kind of change that looks like tidying.
func (s *Store) Attempt(ctx context.Context, tenantID, accountID, attemptID uuid.UUID) (*Paper, error) {
	var p Paper
	var result Result
	var score, of, passMark *int
	var passed *bool

	err := s.pool.QueryRow(ctx, `
		SELECT id, scope, scope_id, started_at, submitted_at, score, of, pass_mark, passed
		FROM exam_attempts WHERE id = $1 AND tenant_id = $2 AND account_id = $3
	`, attemptID, tenantID, accountID).Scan(
		&p.AttemptID, &p.Scope, &p.ScopeID, &p.StartedAt, &p.HandedIn,
		&score, &of, &passMark, &passed)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNoSuchAttempt
	}
	if err != nil {
		return nil, fmt.Errorf("exam: reading an attempt: %w", err)
	}

	if p.HandedIn != nil && score != nil && of != nil && passMark != nil && passed != nil {
		result = Result{Score: *score, Of: *of, PassMark: *passMark, Passed: *passed}
		p.Result = &result
	}

	/* THE MARK THIS PAPER IS HELD TO, and which of two numbers that is depends
	   on whether it has been handed in.

	   A HANDED-IN PAPER CARRIES THE MARK IT WAS JUDGED BY, off its own row. That
	   is the reason the column exists: moving `PassMark` changes what a NEW
	   attempt has to reach and nothing about an old one, and a paper from March
	   shown beside today's constant would be a result explaining itself with a
	   number nobody applied to it.

	   AN OPEN PAPER CARRIES THE CURRENT ONE, because that is what it will be
	   judged by when it is handed in. */
	if p.Result != nil {
		p.PassMark = p.Result.PassMark
	} else {
		p.PassMark = PassMark
	}

	rows, err := s.pool.Query(ctx, `
		SELECT position, exercise_id, exercise_version, type, shown, answer, correct
		FROM exam_answers WHERE attempt_id = $1 ORDER BY position
	`, attemptID)
	if err != nil {
		return nil, fmt.Errorf("exam: reading a paper: %w", err)
	}
	defer rows.Close()

	p.Questions = []Question{}
	for rows.Next() {
		var q Question
		var shown, answer []byte
		if err := rows.Scan(&q.Position, &q.ExerciseID, &q.Version, &q.Type,
			&shown, &answer, &q.Correct); err != nil {
			return nil, fmt.Errorf("exam: reading a paper: %w", err)
		}
		q.Shown = shown
		if len(answer) > 0 {
			q.Answer = answer
		}
		p.Questions = append(p.Questions, q)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("exam: reading a paper: %w", err)
	}
	return &p, nil
}

// History is every exam this student has sat, most recent first.
func (s *Store) History(ctx context.Context, tenantID, accountID uuid.UUID) ([]Summary, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, scope, scope_id, started_at, submitted_at, score, of, pass_mark, passed
		FROM exam_attempts WHERE tenant_id = $1 AND account_id = $2
		ORDER BY started_at DESC
	`, tenantID, accountID)
	if err != nil {
		return nil, fmt.Errorf("exam: reading a student's exams: %w", err)
	}
	defer rows.Close()

	out := []Summary{}
	for rows.Next() {
		var s Summary
		var score, of, passMark *int
		var passed *bool
		if err := rows.Scan(&s.AttemptID, &s.Scope, &s.ScopeID, &s.StartedAt, &s.HandedIn,
			&score, &of, &passMark, &passed); err != nil {
			return nil, fmt.Errorf("exam: reading a student's exams: %w", err)
		}
		if score != nil && of != nil && passMark != nil && passed != nil {
			s.Result = &Result{Score: *score, Of: *of, PassMark: *passMark, Passed: *passed}
		}
		out = append(out, s)
	}
	return out, rows.Err()
}

// Passed answers whether this student has ever passed this exam, and on which
// paper.
//
// EVER, not most recently. A pass is a fact about a day somebody knew the
// material, and an exam sat again out of curiosity and failed does not unmake
// it — the same reason a finished section never un-finishes (A-05). It is the
// question a certificate asks.
//
// THE PAPER IT ANSWERS WITH IS THE FIRST ONE. A certificate points at the
// attempt that earned it, and the earliest pass is the one that did — a later
// one is a student sitting it again, not the moment they qualified.
func (s *Store) Passed(ctx context.Context, tenantID, accountID uuid.UUID,
	scope Scope, scopeID string) (attempt uuid.UUID, passed bool, err error) {

	err = s.pool.QueryRow(ctx, `
		SELECT id FROM exam_attempts
		WHERE tenant_id = $1 AND account_id = $2 AND scope = $3 AND scope_id = $4 AND passed
		ORDER BY submitted_at LIMIT 1
	`, tenantID, accountID, scope, scopeID).Scan(&attempt)

	if errors.Is(err, pgx.ErrNoRows) {
		return uuid.Nil, false, nil
	}
	if err != nil {
		return uuid.Nil, false, fmt.Errorf("exam: asking whether %s %q was passed: %w",
			scope, scopeID, err)
	}
	return attempt, true, nil
}
