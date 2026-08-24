// Package report is how a student says that something in the material is
// wrong, and how somebody answers.
//
// # THE ONLY PLACE A FACT ABOUT THE CONTENT FLOWS UPWARDS
//
// Everything else in this system reads the catalogue: the lesson screen, the
// grader, the certificate. The material is written by a machine and there is no
// human reviewer (C-14), so what stands between a wrong answer key and a
// student is `validate-catalog` — which checks that the key parses, that the
// ids join, and that the grader accepts its own answer. It cannot know that the
// accepted answer is the wrong one.
//
// The person who knows that is the student. This is the channel, and until it
// existed the only way a wrong key came back was somebody writing in.
//
// # IT IMPORTS NO OTHER MODULE
//
// Whose account, which school, and whether those coordinates name anything real
// all arrive as functions the caller supplies. `internal/architecture_test.go`
// enforces that, and the shape is the same one the console uses.
package report

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

var (
	// ErrNoSuchSection is a report whose coordinates name nothing in this
	// school's catalogue.
	ErrNoSuchSection = errors.New("report: no such section")

	// ErrNoSuchExercise is a report against a question this school does not
	// have. Its own sentinel rather than `ErrNoSuchSection`, because the two
	// are different sentences to the person who sent it.
	ErrNoSuchExercise = errors.New("report: no such exercise")

	// ErrNoSuchReport is a settle for a report that is not there.
	ErrNoSuchReport = errors.New("report: no such report")

	// ErrAlreadySettled is a second decision on one report. It is an error and
	// not a silent overwrite: the first decision is the one the audit named.
	ErrAlreadySettled = errors.New("report: that report was already settled")

	// ErrRefused wraps everything a caller can fix by sending something else —
	// an unknown reason, a note over the limit, a missing coordinate.
	//
	// ONE SENTINEL AND NOT ONE PER RULE, which is `identity`'s shape: three
	// sentinels nobody ever branches on individually is three names to keep in
	// step with three sentences. What the handler needs to know is whether the
	// person can fix it, and the sentence says which part.
	ErrRefused = errors.New("report: refused")
)

/*
THE CLOSED LIST OF THINGS THAT CAN BE WRONG (K-13 in the shape a queue needs).

A free-text category makes every report a paragraph to read before knowing
whether it is urgent, and makes the queue unsortable — a wrong answer key and a
missing video are not the same job and must not arrive looking alike. Five
words, and `other` exists so that the list being closed does not mean somebody
with a real problem has nowhere to put it.

They live here and not in the interface, for the reason no threshold lives in an
interface: a screen with its own copy of a list keeps offering the old one.
*/
const (
	// ReasonAnswer is the one this whole feature is for.
	ReasonAnswer = "answer"
	// ReasonWrong is the prose stating something untrue.
	ReasonWrong = "wrong"
	// ReasonBroken is a video that does not play, an image that is not there,
	// a link that leads nowhere.
	ReasonBroken = "broken"
	// ReasonUnclear is material a person cannot follow. It is not a defect and
	// it is the most valuable thing on this list, because nothing else in the
	// platform can measure it.
	ReasonUnclear = "unclear"
	// ReasonOther is the escape, and it is last on purpose.
	ReasonOther = "other"
)

// Reasons is the list, in the order a person is offered it.
var Reasons = []string{ReasonAnswer, ReasonWrong, ReasonBroken, ReasonUnclear, ReasonOther}

/*
AND THE CLOSED LIST OF WAYS ONE ENDS.

Same argument from the other side. "Settled" with no word for what was found is
the state that makes a queue stop being read: a fixed report and one that was
looked at and was fine are opposite outcomes, and a report closed as neither
teaches the next person that closing means nothing.
*/
const (
	// VerdictFixed is the content changed.
	VerdictFixed = "fixed"
	// VerdictNoChange is somebody looked and the material is right.
	VerdictNoChange = "no-change"
	// VerdictNoted is real, understood, and not being fixed now. It is honest
	// where closing it as `no-change` would be a lie and leaving it open
	// forever would be a queue nobody can clear.
	VerdictNoted = "noted"
)

// Verdicts is the list, in the order an operator is offered it.
var Verdicts = []string{VerdictFixed, VerdictNoChange, VerdictNoted}

// Known answers whether a word is on a list. Written once and used for both,
// because two copies of "is this in the slice" is one copy that gets a special
// case added to it.
func Known(list []string, word string) bool {
	for _, one := range list {
		if one == word {
			return true
		}
	}
	return false
}

// NoteLimit is how much a student may write. Long enough for "the key says B
// and the working shows C", short enough that the field is not a place to put a
// megabyte. The database carries the same number as a check, because a limit
// enforced only by the code that happens to be in front of it is not a limit.
const NoteLimit = 500

// New is a report as the student makes it.
//
// IT NAMES A SECTION OR AN EXERCISE. A section report carries its own
// coordinates; an exercise report carries only the exercise, and the store
// resolves the rest from the catalogue — a client that sent both would be a
// client whose copy of where a question lives can disagree with ours.
type New struct {
	School  uuid.UUID
	Account uuid.UUID

	// The section, for a report about the prose.
	CourseID  string
	LessonID  string
	SectionID string

	// The exercise, for a report about a question. When this is set the three
	// above are ignored and filled in from the catalogue.
	ExerciseID string
	Version    int

	Reason string
	Note   string
}

// Report is one row, as the console reads it.
type Report struct {
	ID      uuid.UUID
	School  uuid.UUID
	Account uuid.UUID

	CourseID  string
	LessonID  string
	SectionID string

	// Empty on a report about a section. When it is set, it is the question the
	// student was looking at — and the version, because a key fixed last week
	// and a report from last month are about different questions with one id.
	ExerciseID string
	Version    int

	Reason     string
	Note       string
	ReportedAt time.Time

	SettledAt *time.Time
	SettledBy *uuid.UUID
	Verdict   string
}

// Knows answers whether these coordinates name a section of this school's
// catalogue.
//
// IT IS A FUNCTION BECAUSE THIS PACKAGE MAY NOT IMPORT `catalog`, and it is
// CHECKED because a queue full of coordinates nobody can resolve is a queue
// nobody reads. The interface only ever sends what it drew, so a report that
// fails this is a stale tab or somebody with a terminal — neither of which
// should be able to write a row an operator then has to investigate.
type Knows func(ctx context.Context, school uuid.UUID, course, lesson, section string) (bool, error)

// Where an exercise lives, which is what turns "question three is wrong" into
// coordinates an operator can open a file at.
//
// IT ANSWERS THE PATH RATHER THAN A BOOLEAN, unlike `Knows` above, and the
// difference is which side holds the truth. A section report is made from a
// screen that already knows where it is; an exercise arrives from a drill queue
// that spans courses, so asking the client where the question lives would be
// asking it to tell us something we hold.
//
// A BLANK SECTION IS AN ANSWER AND NOT A FAILURE. `catalog_exercises` carries
// one for almost every exercise and not for every one, and refusing the rest
// would close this channel for exactly the questions a student meets most.
type Locate func(ctx context.Context, school uuid.UUID, exercise string) (
	course, lesson, section string, version int, err error)

type Store struct {
	pool   *pgxpool.Pool
	knows  Knows
	locate Locate
}

func NewStore(pool *pgxpool.Pool, knows Knows, locate Locate) *Store {
	return &Store{pool: pool, knows: knows, locate: locate}
}

// Make records a report.
//
// A SECOND REPORT OF THE SAME SECTION BY THE SAME PERSON IS THE FIRST ONE.
// Somebody who clicks twice, or comes back a week later still annoyed, has not
// found a second defect — and a queue that lets one person put the same
// complaint in it repeatedly is a queue whose length stops meaning anything.
// The unique index says so and this reads the existing row back, so the caller
// can tell the person their report is already in rather than answering an error
// that reads as "it did not work".
func (s *Store) Make(ctx context.Context, in New) (Report, bool, error) {
	in.Reason = strings.TrimSpace(in.Reason)
	in.Note = strings.TrimSpace(in.Note)

	if !Known(Reasons, in.Reason) {
		return Report{}, false, fmt.Errorf("%w: %q is not something this knows how to be "+
			"wrong — say one of %s", ErrRefused, in.Reason, strings.Join(Reasons, ", "))
	}
	if len([]rune(in.Note)) > NoteLimit {
		return Report{}, false, fmt.Errorf("%w: that note is %d characters and the limit "+
			"is %d", ErrRefused, len([]rune(in.Note)), NoteLimit)
	}
	/* A REPORT POINTS AT ONE OF TWO THINGS, and which one decides where the
	   coordinates come from. An exercise brings its own — read from the
	   catalogue, so a client cannot tell us where a question lives — and a
	   section arrives already knowing, from a screen that is standing in it. */
	in.ExerciseID = strings.TrimSpace(in.ExerciseID)
	if in.ExerciseID != "" {
		course, lesson, section, version, err := s.locate(ctx, in.School, in.ExerciseID)
		if err != nil {
			return Report{}, false, fmt.Errorf("report: finding an exercise: %w", err)
		}
		if course == "" {
			return Report{}, false, ErrNoSuchExercise
		}
		in.CourseID, in.LessonID, in.SectionID = course, lesson, section

		/* THE VERSION IS THE CATALOGUE'S AND NOT THE CLIENT'S. What a student
		   was looking at is what is published, and a number they send is a
		   number a stale tab is holding — which would put a report against a
		   version of the question that is not the one anybody can open. */
		in.Version = version
	} else {
		if in.CourseID == "" || in.LessonID == "" || in.SectionID == "" {
			return Report{}, false, fmt.Errorf(
				"%w: a report names a course, a lesson and a section, or an exercise",
				ErrRefused)
		}

		there, err := s.knows(ctx, in.School, in.CourseID, in.LessonID, in.SectionID)
		if err != nil {
			return Report{}, false, fmt.Errorf("report: checking the coordinates: %w", err)
		}
		if !there {
			return Report{}, false, ErrNoSuchSection
		}
	}

	/* ON CONFLICT DOES NOTHING AND THEN THE ROW IS READ. `DO UPDATE` would
	   let the second click overwrite the first note, which is the wrong way
	   round: what the person wrote when they first noticed is the report, and
	   an empty second submission must not erase it. */
	// The version travels as a pointer so that "no exercise" is a null rather
	// than a zero — the constraint refuses one without the other, and a zero
	// would read as version nought of a question nobody named.
	var version *int
	if in.ExerciseID != "" {
		v := in.Version
		version = &v
	}

	var out Report
	var back *int
	err := s.pool.QueryRow(ctx, `
		INSERT INTO content_reports
			(tenant_id, account_id, course_id, lesson_id, section_id,
			 exercise_id, exercise_version, reason, note)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT DO NOTHING
		RETURNING id, tenant_id, account_id, course_id, lesson_id, section_id,
		          exercise_id, exercise_version, reason, note, reported_at
	`, in.School, in.Account, in.CourseID, in.LessonID, in.SectionID,
		in.ExerciseID, version, in.Reason, in.Note).Scan(
		&out.ID, &out.School, &out.Account, &out.CourseID, &out.LessonID,
		&out.SectionID, &out.ExerciseID, &back, &out.Reason, &out.Note, &out.ReportedAt)
	if back != nil {
		out.Version = *back
	}

	if errors.Is(err, pgx.ErrNoRows) {
		again, err := s.openOne(ctx, in)
		return again, true, err
	}
	if err != nil {
		return Report{}, false, fmt.Errorf("report: recording a report: %w", err)
	}
	return out, false, nil
}

// openOne is the report that was already there, read back so the person is told
// what they said rather than that something went wrong.
func (s *Store) openOne(ctx context.Context, in New) (Report, error) {
	var out Report
	var back *int
	err := s.pool.QueryRow(ctx, `
		SELECT id, tenant_id, account_id, course_id, lesson_id, section_id,
		       exercise_id, exercise_version, reason, note, reported_at
		FROM content_reports
		WHERE tenant_id = $1 AND account_id = $2 AND course_id = $3
		  AND lesson_id = $4 AND section_id = $5 AND exercise_id = $6
		  AND settled_at IS NULL
	`, in.School, in.Account, in.CourseID, in.LessonID, in.SectionID,
		in.ExerciseID).Scan(
		&out.ID, &out.School, &out.Account, &out.CourseID, &out.LessonID,
		&out.SectionID, &out.ExerciseID, &back, &out.Reason, &out.Note, &out.ReportedAt)
	if back != nil {
		out.Version = *back
	}
	if err != nil {
		return Report{}, fmt.Errorf("report: reading a report back: %w", err)
	}
	return out, nil
}

// Open is one school's queue, oldest first.
//
// OLDEST FIRST AND NOT NEWEST, which is the opposite of every other list in
// this console. A queue is worked through rather than watched: newest-first
// buries the report that has been waiting three weeks under the one that
// arrived this morning, and the one that has been waiting is the one that has
// been failing somebody the longest.
func (s *Store) Open(ctx context.Context, school uuid.UUID) ([]Report, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, tenant_id, account_id, course_id, lesson_id, section_id,
		       exercise_id, exercise_version, reason, note, reported_at
		FROM content_reports
		WHERE tenant_id = $1 AND settled_at IS NULL
		ORDER BY reported_at
	`, school)
	if err != nil {
		return nil, fmt.Errorf("report: reading the queue: %w", err)
	}
	defer rows.Close()

	var out []Report
	for rows.Next() {
		var one Report
		var version *int
		if err := rows.Scan(&one.ID, &one.School, &one.Account, &one.CourseID,
			&one.LessonID, &one.SectionID, &one.ExerciseID, &version,
			&one.Reason, &one.Note, &one.ReportedAt); err != nil {
			return nil, fmt.Errorf("report: reading the queue: %w", err)
		}
		if version != nil {
			one.Version = *version
		}
		out = append(out, one)
	}
	return out, rows.Err()
}

// Mine is what one student has reported and not had answered yet, so that the
// interface can draw a section they have already spoken about as already
// spoken about — rather than inviting them to say it again and then telling
// them they already had.
//
// IT IS SCOPED TO THE ACCOUNT AND THE SCHOOL, both, and neither is optional.
// The account is the privacy boundary that matters between students (P-05);
// the school is the one that keeps a person studying two subjects from seeing
// one queue.
func (s *Store) Mine(ctx context.Context, school, account uuid.UUID) ([]Report, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, course_id, lesson_id, section_id, exercise_id,
		       reason, note, reported_at
		FROM content_reports
		WHERE tenant_id = $1 AND account_id = $2 AND settled_at IS NULL
		ORDER BY reported_at
	`, school, account)
	if err != nil {
		return nil, fmt.Errorf("report: reading a student's reports: %w", err)
	}
	defer rows.Close()

	var out []Report
	for rows.Next() {
		one := Report{School: school, Account: account}
		if err := rows.Scan(&one.ID, &one.CourseID, &one.LessonID, &one.SectionID,
			&one.ExerciseID, &one.Reason, &one.Note, &one.ReportedAt); err != nil {
			return nil, fmt.Errorf("report: reading a student's reports: %w", err)
		}
		out = append(out, one)
	}
	return out, rows.Err()
}

// One is a single report, which the console reads before it settles one so that
// the audit entry can name what was decided about what.
func (s *Store) One(ctx context.Context, id uuid.UUID) (Report, error) {
	var out Report
	var version *int
	err := s.pool.QueryRow(ctx, `
		SELECT id, tenant_id, account_id, course_id, lesson_id, section_id,
		       exercise_id, exercise_version, reason, note, reported_at,
		       settled_at, settled_by, verdict
		FROM content_reports WHERE id = $1
	`, id).Scan(&out.ID, &out.School, &out.Account, &out.CourseID, &out.LessonID,
		&out.SectionID, &out.ExerciseID, &version, &out.Reason, &out.Note,
		&out.ReportedAt, &out.SettledAt, &out.SettledBy, &out.Verdict)

	if errors.Is(err, pgx.ErrNoRows) {
		return Report{}, ErrNoSuchReport
	}
	if err != nil {
		return Report{}, fmt.Errorf("report: reading a report: %w", err)
	}
	if version != nil {
		out.Version = *version
	}
	return out, nil
}

// Settle closes one report with a verdict.
//
// IT REFUSES A SECOND DECISION rather than overwriting the first. The audit
// entry names what was decided, so a row that could be re-settled would be a
// history saying two different things happened and a table agreeing with only
// the later one.
func (s *Store) Settle(ctx context.Context, id, by uuid.UUID, verdict string) error {
	if !Known(Verdicts, verdict) {
		return fmt.Errorf("%w: %q is not a way to settle a report — say one of %s",
			ErrRefused, verdict, strings.Join(Verdicts, ", "))
	}

	tag, err := s.pool.Exec(ctx, `
		UPDATE content_reports
		SET settled_at = now(), settled_by = $2, verdict = $3
		WHERE id = $1 AND settled_at IS NULL
	`, id, by, verdict)
	if err != nil {
		return fmt.Errorf("report: settling a report: %w", err)
	}
	if tag.RowsAffected() == 1 {
		return nil
	}

	// Nothing moved: either it is not there, or somebody settled it first. The
	// two are different answers to the operator, so they are told apart rather
	// than reported as one failure.
	if _, err := s.One(ctx, id); err != nil {
		return err
	}
	return ErrAlreadySettled
}
