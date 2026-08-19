// Package progress is what a student has done and where they were.
//
// # COMPLETION IS SET-TRUE AND NEVER TOGGLED
//
// There is no path here that un-completes anything (A-05). Finishing a section
// is a fact about the past; a progress bar that moves backwards for somebody
// who did nothing wrong is the most demoralising thing a study platform can do.
// Mastery decays and that is a different question, answered by a different
// table, which never reaches a progress bar.
//
// # THE DOOR IS CHECKED ON THE WAY IN
//
// A student may not record progress in a course they cannot open. Without that,
// the paywall is a decoration on the reading path: a client that never asks for
// the lesson can still mark it done, and a certificate then rests on sections
// nobody was entitled to. `MayOpen` is a callback because this module may not
// reach into the one that owns the catalogue — `cmd/api` joins them.
//
// # ONE PERSON'S ROWS ARE ONE PERSON'S
//
// Every query leads with the tenant and the account. Row-level security is
// deliberately absent (P-05), so the boundary between students is this code and
// the tests that hold it — which is why there is a test that asks for somebody
// else's progress and insists on getting none of it.
package progress

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrLocked is a course this student may not open. Recording progress in one is
// refused for the same reason reading it is.
var ErrLocked = errors.New("progress: that course is not open to this student")

// ErrNoSuchSection is a section the catalogue does not have.
//
// IT IS CHECKED RATHER THAN TRUSTED. A client that invented section ids could
// otherwise complete a course that has three sections by sending thirty, and
// every count above it — the progress bar, the certificate, the cohort — would
// be built on rows naming nothing.
var ErrNoSuchSection = errors.New("progress: no such section in that course")

// MayOpen answers whether this student may open a course, and Sections answers
// which sections it has. Both are callbacks for the same reason: the catalogue
// is another module, and modules meet in cmd/.
type (
	MayOpen  func(ctx context.Context, courseID string) (bool, error)
	Sections func(ctx context.Context, courseID string) (map[string][]string, error)
)

type Store struct {
	pool     *pgxpool.Pool
	mayOpen  MayOpen
	sections Sections
}

func NewStore(pool *pgxpool.Pool, mayOpen MayOpen, sections Sections) *Store {
	return &Store{pool: pool, mayOpen: mayOpen, sections: sections}
}

// Where is one student's position in one course.
type Where struct {
	CourseID  string    `json:"course"`
	LessonID  string    `json:"lesson"`
	SectionID string    `json:"section"`
	At        time.Time `json:"at"`
}

// Completed is a section somebody finished.
//
// `CourseID` is empty when the answer is already about one course — the caller
// asked for it and repeating it on every row would be noise. It is filled by
// the read that goes across all of them, where it is the only thing saying
// which course a row belongs to.
type Completed struct {
	CourseID    string    `json:"course,omitempty"`
	LessonID    string    `json:"lesson"`
	SectionID   string    `json:"section"`
	CompletedAt time.Time `json:"completed_at"`
}

// Complete records a finished section and moves the resume pointer to it.
//
// IT IS IDEMPOTENT, and that is not a convenience: a student on a slow
// connection taps twice, a client retries, a tab is restored. Every one of
// those must leave the same single fact behind, and the FIRST completion time
// is the one kept — the second tap is not a second finishing.
//
// IT ANSWERS WHETHER IT WAS THE FIRST TIME, and that is why. Statistics come
// from the event stream (K-03), so a caller that emitted on every call would
// inflate "sections completed this month" by every double tap — quietly, and in
// a direction that flatters. The caller emits only when this says yes.
// IT ALSO ANSWERS WHETHER THAT FINISHED THE COURSE, for the same reason and
// with the same care: "finished the free course" is a step of the funnel, and a
// step that fired every time somebody re-completed a section would be a funnel
// that says more people finish than ever started.
//
// `finished` is true on the completion that turned the last section, and on no
// other — including a later one, when the course is already done.
func (s *Store) Complete(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID, lessonID, sectionID string) (first, finished bool, err error) {

	if err := s.allowed(ctx, courseID, lessonID, sectionID); err != nil {
		return false, false, err
	}

	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `
			INSERT INTO section_progress
				(tenant_id, account_id, course_id, lesson_id, section_id)
			VALUES ($1, $2, $3, $4, $5)
			ON CONFLICT (tenant_id, account_id, course_id, lesson_id, section_id) DO NOTHING
		`, tenantID, accountID, courseID, lessonID, sectionID)
		if err != nil {
			return fmt.Errorf("progress: recording a completed section: %w", err)
		}
		first = tag.RowsAffected() == 1

		// The pointer follows the most recent thing they did, which is what
		// "carry on where you left off" means to a person.
		if _, err := tx.Exec(ctx, `
			INSERT INTO resume_pointer (tenant_id, account_id, course_id, lesson_id, section_id)
			VALUES ($1, $2, $3, $4, $5)
			ON CONFLICT (tenant_id, account_id, course_id) DO UPDATE
				SET lesson_id = EXCLUDED.lesson_id,
				    section_id = EXCLUDED.section_id,
				    at = now()
		`, tenantID, accountID, courseID, lessonID, sectionID); err != nil {
			return fmt.Errorf("progress: moving the resume pointer: %w", err)
		}
		return nil
	})
	if err != nil || !first {
		// Only a completion that changed something can have finished a course.
		// Asking on a repeat would emit the step again for every double tap.
		return first, false, err
	}

	finished, err = s.finishes(ctx, tenantID, accountID, courseID)
	return first, finished, err
}

// finishes answers whether every section of a course is now behind this
// student.
//
// THE DENOMINATOR IS THE CATALOGUE AND NOT THE PROGRESS TABLE. Counting the
// rows somebody has would answer "have they finished what they finished", which
// is true of everybody. It asks the course what it contains, which is also what
// makes a section added to a course un-finish it for the people who were done —
// correctly, because there is now something they have not read.
func (s *Store) finishes(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID string) (bool, error) {

	sections, err := s.sections(ctx, courseID)
	if err != nil {
		return false, fmt.Errorf("progress: reading the sections of %q: %w", courseID, err)
	}

	wanted := 0
	for _, ids := range sections {
		wanted += len(ids)
	}
	if wanted == 0 {
		// A course with no sections is not one anybody can finish, and saying
		// they did would put a step in the funnel that nothing corresponds to.
		return false, nil
	}

	var done int
	if err := s.pool.QueryRow(ctx, `
		SELECT count(*) FROM section_progress
		WHERE tenant_id = $1 AND account_id = $2 AND course_id = $3
	`, tenantID, accountID, courseID).Scan(&done); err != nil {
		return false, fmt.Errorf("progress: counting what is finished in %q: %w", courseID, err)
	}
	return done >= wanted, nil
}

// Visit moves the resume pointer without completing anything.
//
// OPENING A SECTION IS NOT FINISHING IT. Recording a visit as progress would
// make a certificate rest on scrolling, and it is also the difference between
// "carry on where you left off" sending somebody to what they were reading and
// sending them past it.
func (s *Store) Visit(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID, lessonID, sectionID string) error {

	if err := s.allowed(ctx, courseID, lessonID, sectionID); err != nil {
		return err
	}

	_, err := s.pool.Exec(ctx, `
		INSERT INTO resume_pointer (tenant_id, account_id, course_id, lesson_id, section_id)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (tenant_id, account_id, course_id) DO UPDATE
			SET lesson_id = EXCLUDED.lesson_id, section_id = EXCLUDED.section_id, at = now()
	`, tenantID, accountID, courseID, lessonID, sectionID)
	if err != nil {
		return fmt.Errorf("progress: moving the resume pointer: %w", err)
	}
	return nil
}

// allowed checks the door and the section, in that order.
func (s *Store) allowed(ctx context.Context, courseID, lessonID, sectionID string) error {
	open, err := s.mayOpen(ctx, courseID)
	if err != nil {
		return fmt.Errorf("progress: deciding whether %q is open: %w", courseID, err)
	}
	if !open {
		return ErrLocked
	}

	sections, err := s.sections(ctx, courseID)
	if err != nil {
		return fmt.Errorf("progress: reading the sections of %q: %w", courseID, err)
	}
	for _, id := range sections[lessonID] {
		if id == sectionID {
			return nil
		}
	}
	return fmt.Errorf("%w: %s/%s/%s", ErrNoSuchSection, courseID, lessonID, sectionID)
}

// OfCourse answers everything one student has done in one course.
func (s *Store) OfCourse(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID string) ([]Completed, *Where, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT lesson_id, section_id, completed_at
		FROM section_progress
		WHERE tenant_id = $1 AND account_id = $2 AND course_id = $3
		ORDER BY completed_at
	`, tenantID, accountID, courseID)
	if err != nil {
		return nil, nil, fmt.Errorf("progress: reading a student's progress: %w", err)
	}
	defer rows.Close()

	done := []Completed{}
	for rows.Next() {
		var c Completed
		if err := rows.Scan(&c.LessonID, &c.SectionID, &c.CompletedAt); err != nil {
			return nil, nil, fmt.Errorf("progress: reading a student's progress: %w", err)
		}
		done = append(done, c)
	}
	if err := rows.Err(); err != nil {
		return nil, nil, fmt.Errorf("progress: reading a student's progress: %w", err)
	}

	where, err := s.Resume(ctx, tenantID, accountID, courseID)
	if err != nil {
		return nil, nil, err
	}
	return done, where, nil
}

// Resume answers where a student was in a course, or nil if they never started.
func (s *Store) Resume(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID string) (*Where, error) {

	var w Where
	err := s.pool.QueryRow(ctx, `
		SELECT course_id, lesson_id, section_id, at FROM resume_pointer
		WHERE tenant_id = $1 AND account_id = $2 AND course_id = $3
	`, tenantID, accountID, courseID).Scan(&w.CourseID, &w.LessonID, &w.SectionID, &w.At)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("progress: reading the resume pointer: %w", err)
	}
	return &w, nil
}

// Recent answers where a student was, across courses, most recent first. It is
// what the dashboard's "carry on" list is made of.
func (s *Store) Recent(ctx context.Context, tenantID, accountID uuid.UUID, limit int) ([]Where, error) {
	if limit <= 0 || limit > 50 {
		limit = 10
	}

	rows, err := s.pool.Query(ctx, `
		SELECT course_id, lesson_id, section_id, at FROM resume_pointer
		WHERE tenant_id = $1 AND account_id = $2
		ORDER BY at DESC LIMIT $3
	`, tenantID, accountID, limit)
	if err != nil {
		return nil, fmt.Errorf("progress: reading where a student was: %w", err)
	}
	defer rows.Close()

	out := []Where{}
	for rows.Next() {
		var w Where
		if err := rows.Scan(&w.CourseID, &w.LessonID, &w.SectionID, &w.At); err != nil {
			return nil, fmt.Errorf("progress: reading where a student was: %w", err)
		}
		out = append(out, w)
	}
	return out, rows.Err()
}

/* ---------- notes ---------- */

// The longest a note may be. Not a storage concern: a margin that holds an
// essay is a document editor nobody asked this system to be, and the limit is
// what keeps the feature the size it was meant to be.
const noteLimit = 8000

// Note is what a student wrote beside a section.
//
// IT CARRIES ITS COURSE even though the per-course reader was told which course
// it asked about. The screen that lists everything somebody wrote is a list
// across courses, and a note that did not say where it came from would be a
// paragraph with no way back to the page it belongs to.
type Note struct {
	CourseID  string    `json:"course"`
	LessonID  string    `json:"lesson"`
	SectionID string    `json:"section"`
	Body      string    `json:"body"`
	UpdatedAt time.Time `json:"updated_at"`
}

// SetNote replaces a note, or deletes it when it is emptied.
//
// EMPTYING IT DELETES THE ROW rather than storing a blank. A person who clears
// their note has removed it, and an export that handed them back an empty
// string for every section they ever opened would be answering a question
// nobody asked.
func (s *Store) SetNote(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID, lessonID, sectionID, body string) error {

	if err := s.allowed(ctx, courseID, lessonID, sectionID); err != nil {
		return err
	}

	body = strings.TrimSpace(body)
	if len([]rune(body)) > noteLimit {
		return fmt.Errorf("progress: a note is at most %d characters", noteLimit)
	}

	if body == "" {
		_, err := s.pool.Exec(ctx, `
			DELETE FROM notes WHERE tenant_id = $1 AND account_id = $2
			  AND course_id = $3 AND lesson_id = $4 AND section_id = $5
		`, tenantID, accountID, courseID, lessonID, sectionID)
		if err != nil {
			return fmt.Errorf("progress: removing a note: %w", err)
		}
		return nil
	}

	_, err := s.pool.Exec(ctx, `
		INSERT INTO notes (tenant_id, account_id, course_id, lesson_id, section_id, body)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (tenant_id, account_id, course_id, lesson_id, section_id) DO UPDATE
			SET body = EXCLUDED.body, updated_at = now()
	`, tenantID, accountID, courseID, lessonID, sectionID, body)
	if err != nil {
		return fmt.Errorf("progress: writing a note: %w", err)
	}
	return nil
}

// Notes answers everything a student wrote in one course.
func (s *Store) Notes(ctx context.Context, tenantID, accountID uuid.UUID,
	courseID string) ([]Note, error) {

	rows, err := s.pool.Query(ctx, `
		SELECT course_id, lesson_id, section_id, body, updated_at FROM notes
		WHERE tenant_id = $1 AND account_id = $2 AND course_id = $3
		ORDER BY lesson_id, section_id
	`, tenantID, accountID, courseID)
	if err != nil {
		return nil, fmt.Errorf("progress: reading a student's notes: %w", err)
	}
	defer rows.Close()
	return scanNotes(rows)
}

// AllNotes answers everything a student wrote, in every course, newest first.
//
// NEWEST FIRST AND NOT BY COURSE. A margin is written while reading and read
// back while remembering, and what somebody is looking for is almost always the
// thing they wrote last — a list in catalogue order buries it under whichever
// course happens to sort first.
func (s *Store) AllNotes(ctx context.Context, tenantID, accountID uuid.UUID) ([]Note, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT course_id, lesson_id, section_id, body, updated_at FROM notes
		WHERE tenant_id = $1 AND account_id = $2
		ORDER BY updated_at DESC, course_id, lesson_id, section_id
	`, tenantID, accountID)
	if err != nil {
		return nil, fmt.Errorf("progress: reading a student's notes: %w", err)
	}
	defer rows.Close()
	return scanNotes(rows)
}

func scanNotes(rows pgx.Rows) ([]Note, error) {
	out := []Note{}
	for rows.Next() {
		var n Note
		if err := rows.Scan(&n.CourseID, &n.LessonID, &n.SectionID,
			&n.Body, &n.UpdatedAt); err != nil {
			return nil, fmt.Errorf("progress: reading a student's notes: %w", err)
		}
		out = append(out, n)
	}
	return out, rows.Err()
}

/* ---------- how far along, everywhere at once ---------- */

// Everything one student has finished, in every course, in one read.
//
// IT IS THE ROWS AND NOT THE COUNTS. `Summary` answers "how many" per course,
// which is what a list of courses needs; an interface that draws a tick beside
// each SECTION needs to know which ones, and asking course by course is a
// hundred and twenty-two requests to open a page.
//
// The two are separate reads rather than one with a flag, because they are
// asked at different moments and the expensive one should not be paid for the
// cheap question: a rail needs the counts on every navigation, and the ticks
// only when a course is open.
func (s *Store) Completions(ctx context.Context, tenantID, accountID uuid.UUID) ([]Completed, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT course_id, lesson_id, section_id, completed_at
		FROM section_progress
		WHERE tenant_id = $1 AND account_id = $2
		ORDER BY completed_at
	`, tenantID, accountID)
	if err != nil {
		return nil, fmt.Errorf("progress: reading everything a student has finished: %w", err)
	}
	defer rows.Close()

	out := []Completed{}
	for rows.Next() {
		var c Completed
		if err := rows.Scan(&c.CourseID, &c.LessonID, &c.SectionID, &c.CompletedAt); err != nil {
			return nil, fmt.Errorf("progress: reading everything a student has finished: %w", err)
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// Done is how many countable sections a student has finished in one course.
//
// IT IS A NUMERATOR AND NOT A FRACTION. How many sections a course HAS belongs
// to the catalogue, which is another module (X-02) — this one records what was
// done and does not get to say how much there was to do. The screen divides the
// two, which is also why a course somebody has not started is absent here
// rather than present as a zero: nothing was done, and there is nothing to say.
type Done struct {
	CourseID string `json:"course"`
	Sections int    `json:"sections"`
}

// Summary answers, in one query, how far along a student is in every course
// they have touched.
//
// ONE QUERY IS THE WHOLE POINT. The sidebar shows a count beside every course
// in the school, and asking per course is a screen that fires twenty requests
// to draw a list — slow on a laptop, and a small denial of service against our
// own API from a phone on a train.
func (s *Store) Summary(ctx context.Context, tenantID, accountID uuid.UUID) ([]Done, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT course_id, count(*) FROM section_progress
		WHERE tenant_id = $1 AND account_id = $2
		GROUP BY course_id
		ORDER BY course_id
	`, tenantID, accountID)
	if err != nil {
		return nil, fmt.Errorf("progress: counting what a student has done: %w", err)
	}
	defer rows.Close()

	out := []Done{}
	for rows.Next() {
		var d Done
		if err := rows.Scan(&d.CourseID, &d.Sections); err != nil {
			return nil, fmt.Errorf("progress: counting what a student has done: %w", err)
		}
		out = append(out, d)
	}
	return out, rows.Err()
}
