package progress_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/progress"
)

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("SCHOOLING_TEST_DATABASE_URL")
	if url == "" {
		t.Skip("set SCHOOLING_TEST_DATABASE_URL to run the tests that need a database")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		t.Fatalf("opening the test database: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

// The catalogue this module is given, as the two questions it actually asks.
// A fake here is honest: what is under test is what progress does with the
// answers, and the real catalogue's own tests cover the answers themselves.
type catalogue struct {
	open     map[string]bool
	sections map[string]map[string][]string
}

func (c catalogue) mayOpen(_ context.Context, courseID string) (bool, error) {
	return c.open[courseID], nil
}

func (c catalogue) sectionsOf(_ context.Context, courseID string) (map[string][]string, error) {
	return c.sections[courseID], nil
}

func fixture() catalogue {
	return catalogue{
		open: map[string]bool{"web-fundamentals": true, "html-css": false},
		sections: map[string]map[string][]string{
			"web-fundamentals": {"client-and-server": {"roles", "intro", "drill"}},
			"html-css":         {"boxes": {"overview"}},
		},
	}
}

func store(t *testing.T, pool *pgxpool.Pool) *progress.Store {
	t.Helper()
	c := fixture()
	return progress.NewStore(pool, c.mayOpen, c.sectionsOf)
}

// school and student seed the two rows everything here hangs off, under names
// nothing else is using: packages run in parallel against one database.
func school(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"code-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:12]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

func student(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:16]+"@example.tld").Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

// THE ONE THAT MATTERS.
//
// A student may not record progress in a course they cannot open. Without this,
// the paywall is a decoration on the reading path: a client that never asks for
// the lesson can still mark it done, and a certificate then rests on sections
// nobody was entitled to.
func TestALockedCourseCannotBeCompleted(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	_, _, err := s.Complete(ctx, school, student, "html-css", "boxes", "overview")
	if !errors.Is(err, progress.ErrLocked) {
		t.Fatalf("completing a locked course gave %v, want ErrLocked", err)
	}

	// And nothing was written, including the resume pointer — a course somebody
	// cannot open must not turn up in "carry on where you left off".
	done, where, err := s.OfCourse(ctx, school, student, "html-css")
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(done) != 0 || where != nil {
		t.Errorf("a locked course left %d completions and resume=%v behind", len(done), where)
	}

	// Visiting and writing a note are refused for the same reason.
	if err := s.Visit(ctx, school, student, "html-css", "boxes", "overview"); !errors.Is(err, progress.ErrLocked) {
		t.Errorf("visiting a locked course gave %v", err)
	}
	if err := s.SetNote(ctx, school, student, "html-css", "boxes", "overview", "…"); !errors.Is(err, progress.ErrLocked) {
		t.Errorf("writing a note in a locked course gave %v", err)
	}
}

// A section the catalogue does not have is refused. A client that invented ids
// could otherwise finish a three-section course by sending thirty, and every
// count above it would rest on rows naming nothing.
func TestASectionThatDoesNotExistIsRefused(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)

	_, _, err := s.Complete(context.Background(), school, student,
		"web-fundamentals", "client-and-server", "invented")
	if !errors.Is(err, progress.ErrNoSuchSection) {
		t.Errorf("an invented section gave %v, want ErrNoSuchSection", err)
	}
}

// THE SECOND ONE THAT MATTERS.
//
// Completion is set-true and never toggled (A-05). Finishing is a fact about
// the past, and a progress bar that moves backwards for somebody who did
// nothing wrong is the most demoralising thing a study platform can do.
//
// The practical half of that is idempotence: a student on a slow connection
// taps twice, a client retries, a tab is restored. Every one of those leaves
// the same single fact behind, with the FIRST time kept.
func TestCompletingTwiceIsCompletingOnce(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	first, _, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", "roles")
	if err != nil {
		t.Fatalf("the first completion: %v", err)
	}
	if !first {
		t.Error("the first completion did not report itself as the first")
	}
	done, _, err := s.OfCourse(ctx, school, student, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(done) != 1 {
		t.Fatalf("%d completions after one, want 1", len(done))
	}
	when := done[0].CompletedAt

	again, _, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", "roles")
	if err != nil {
		t.Fatalf("the second completion: %v", err)
	}
	if again {
		t.Error("the second tap reported itself as a first completion — every double tap would " +
			"then be counted again, and \"sections completed this month\" would be inflated in " +
			"the direction that flatters")
	}

	done, _, err = s.OfCourse(ctx, school, student, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(done) != 1 {
		t.Errorf("%d completions after tapping twice, want 1", len(done))
	}
	if !done[0].CompletedAt.Equal(when) {
		t.Errorf("the completion time moved from %v to %v — the second tap is not a second "+
			"finishing", when, done[0].CompletedAt)
	}
}

// There is no path that un-completes anything, and the type system is where
// that is enforced: the store has no method for it. This checks the shape of
// the record instead — that what comes back after more work is never less.
func TestProgressOnlyEverGrows(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	seen := 0
	for _, section := range []string{"roles", "intro", "drill"} {
		if _, _, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", section); err != nil {
			t.Fatalf("completing %s: %v", section, err)
		}
		done, _, err := s.OfCourse(ctx, school, student, "web-fundamentals")
		if err != nil {
			t.Fatalf("reading: %v", err)
		}
		if len(done) < seen {
			t.Fatalf("progress went from %d completed sections to %d", seen, len(done))
		}
		seen = len(done)
	}
	if seen != 3 {
		t.Errorf("%d sections completed, want 3", seen)
	}
}

// THE THIRD ONE THAT MATTERS.
//
// The boundary that survives is between STUDENTS (P-05), and row-level security
// is deliberately absent — so it is this code and this test. One student asking
// for a course gets their own rows and none of anybody else's.
func TestOneStudentNeverSeesAnother(t *testing.T) {
	pool := testPool(t)
	s, school := store(t, pool), school(t, pool)
	ana, bruno := student(t, pool), student(t, pool)
	ctx := context.Background()

	if _, _, err := s.Complete(ctx, school, ana, "web-fundamentals", "client-and-server", "roles"); err != nil {
		t.Fatalf("completing: %v", err)
	}
	if err := s.SetNote(ctx, school, ana, "web-fundamentals", "client-and-server", "roles",
		"something Ana wrote"); err != nil {
		t.Fatalf("writing a note: %v", err)
	}

	done, where, err := s.OfCourse(ctx, school, bruno, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(done) != 0 {
		t.Errorf("Bruno can see %d of Ana's completed sections", len(done))
	}
	if where != nil {
		t.Errorf("Bruno resumes where Ana was: %+v", where)
	}

	notes, err := s.Notes(ctx, school, bruno, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading notes: %v", err)
	}
	if len(notes) != 0 {
		t.Errorf("Bruno can read %d of Ana's notes", len(notes))
	}
}

// Opening a section is not finishing it. Recording a visit as progress would
// make a certificate rest on scrolling.
func TestVisitingMovesThePointerAndCompletesNothing(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	if err := s.Visit(ctx, school, student, "web-fundamentals", "client-and-server", "intro"); err != nil {
		t.Fatalf("visiting: %v", err)
	}

	done, where, err := s.OfCourse(ctx, school, student, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(done) != 0 {
		t.Errorf("visiting completed %d sections", len(done))
	}
	if where == nil || where.SectionID != "intro" {
		t.Errorf("the resume pointer is %+v, want the section that was visited", where)
	}
}

// The pointer follows the most recent thing, which is what "carry on where you
// left off" means to a person.
func TestTheResumePointerFollowsTheMostRecentSection(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	for _, section := range []string{"roles", "intro", "drill"} {
		if _, _, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", section); err != nil {
			t.Fatalf("completing %s: %v", section, err)
		}
	}

	where, err := s.Resume(ctx, school, student, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading the pointer: %v", err)
	}
	if where == nil || where.SectionID != "drill" {
		t.Errorf("the pointer is at %+v, want the last section completed", where)
	}

	recent, err := s.Recent(ctx, school, student, 10)
	if err != nil {
		t.Fatalf("reading the recent list: %v", err)
	}
	if len(recent) != 1 || recent[0].CourseID != "web-fundamentals" {
		t.Errorf("the dashboard's list is %+v, want one entry for the course", recent)
	}
}

// A note that is emptied is removed, not stored blank. An export handing
// somebody an empty string for every section they ever opened would answer a
// question nobody asked.
func TestEmptyingANoteRemovesIt(t *testing.T) {
	pool := testPool(t)
	s, school, student := store(t, pool), school(t, pool), student(t, pool)
	ctx := context.Background()

	if err := s.SetNote(ctx, school, student, "web-fundamentals", "client-and-server", "roles",
		"the client is whoever asks"); err != nil {
		t.Fatalf("writing: %v", err)
	}
	notes, err := s.Notes(ctx, school, student, "web-fundamentals")
	if err != nil || len(notes) != 1 {
		t.Fatalf("%d notes after writing one: %v", len(notes), err)
	}

	if err := s.SetNote(ctx, school, student, "web-fundamentals", "client-and-server", "roles",
		"   "); err != nil {
		t.Fatalf("emptying: %v", err)
	}
	notes, err = s.Notes(ctx, school, student, "web-fundamentals")
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if len(notes) != 0 {
		t.Errorf("%d notes after emptying it, want none: %+v", len(notes), notes)
	}
}

// FINISHING THE LAST SECTION FINISHES THE COURSE, and it is announced exactly
// once.
//
// "Finished the free course" is a step of the funnel and nobody clicks it — it
// becomes true when the last section turns. A step that fired again on a repeat
// completion would be a funnel saying more people finished than ever started.
func TestFinishingTheLastSectionFinishesTheCourseOnce(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := school(t, pool), student(t, pool)
	s := store(t, pool)

	sections := []string{"roles", "intro", "drill"}
	finishes := 0

	for _, section := range sections {
		_, finished, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", section)
		if err != nil {
			t.Fatalf("completing %s: %v", section, err)
		}
		if finished {
			finishes++
		}
	}

	if finishes != 1 {
		t.Fatalf("finishing a course of %d sections was announced %d times",
			len(sections), finishes)
	}

	// And completing one of them again does not announce it a second time.
	_, finished, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", sections[0])
	if err != nil {
		t.Fatal(err)
	}
	if finished {
		t.Error("re-completing a section announced the course as finished again")
	}
}

// AND FINISHING PART OF IT FINISHES NOTHING. The denominator is what the course
// contains, not what the student has done — counting their own rows would
// answer "have they finished what they finished", which is true of everybody.
func TestFinishingSomeSectionsDoesNotFinishTheCourse(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := school(t, pool), student(t, pool)
	s := store(t, pool)

	_, finished, err := s.Complete(ctx, school, student, "web-fundamentals", "client-and-server", "roles")
	if err != nil {
		t.Fatal(err)
	}
	if finished {
		t.Error("one section of three finished the course")
	}
}

/* ---------- what the sidebar and the notes screen read ---------- */

// A catalogue with two open courses, which the shared fixture does not have:
// what `Summary` is for is answering about SEVERAL courses at once, and a
// fixture with one open course cannot fail the way this is meant to catch.
func twoOpenCourses(t *testing.T, pool *pgxpool.Pool) *progress.Store {
	t.Helper()
	c := catalogue{
		open: map[string]bool{"web-fundamentals": true, "html-css": true},
		sections: map[string]map[string][]string{
			"web-fundamentals": {"client-and-server": {"roles", "intro", "drill"}},
			"html-css":         {"boxes": {"overview", "padding"}},
		},
	}
	return progress.NewStore(pool, c.mayOpen, c.sectionsOf)
}

// ONE QUERY, ONE ROW PER COURSE TOUCHED. The sidebar puts a count beside every
// course in the school; asking course by course is twenty requests to draw a
// list, which is why this exists at all.
func TestSummaryCountsEachCourseSeparately(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := school(t, pool), student(t, pool)
	s := twoOpenCourses(t, pool)

	for _, section := range []string{"roles", "intro"} {
		if _, _, err := s.Complete(ctx, school, student,
			"web-fundamentals", "client-and-server", section); err != nil {
			t.Fatal(err)
		}
	}
	if _, _, err := s.Complete(ctx, school, student, "html-css", "boxes", "overview"); err != nil {
		t.Fatal(err)
	}

	done, err := s.Summary(ctx, school, student)
	if err != nil {
		t.Fatal(err)
	}

	counted := map[string]int{}
	for _, d := range done {
		counted[d.CourseID] = d.Sections
	}
	if counted["web-fundamentals"] != 2 {
		t.Errorf("two sections of web-fundamentals counted as %d", counted["web-fundamentals"])
	}
	if counted["html-css"] != 1 {
		t.Errorf("one section of html-css counted as %d", counted["html-css"])
	}
}

// A COURSE NOBODY STARTED IS ABSENT, NOT ZERO. This module records what was
// done and does not know how many sections a course has — a row saying "zero of
// something" would be this module answering a question the catalogue owns.
func TestSummarySaysNothingAboutACourseNobodyStarted(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := school(t, pool), student(t, pool)
	s := twoOpenCourses(t, pool)

	if _, _, err := s.Complete(ctx, school, student,
		"web-fundamentals", "client-and-server", "roles"); err != nil {
		t.Fatal(err)
	}

	done, err := s.Summary(ctx, school, student)
	if err != nil {
		t.Fatal(err)
	}
	for _, d := range done {
		if d.CourseID == "html-css" {
			t.Errorf("a course nobody has started is in the summary, as %d sections", d.Sections)
		}
	}
}

// AND ONE STUDENT'S COUNTS ARE ONE STUDENT'S. The same rule the rest of this
// module obeys, checked on the read that goes across every course at once —
// which is the one where a forgotten `account_id` would leak the most.
func TestSummaryNeverCountsAnotherStudent(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school := school(t, pool)
	mine, theirs := student(t, pool), student(t, pool)
	s := twoOpenCourses(t, pool)

	if _, _, err := s.Complete(ctx, school, theirs,
		"web-fundamentals", "client-and-server", "roles"); err != nil {
		t.Fatal(err)
	}

	done, err := s.Summary(ctx, school, mine)
	if err != nil {
		t.Fatal(err)
	}
	if len(done) != 0 {
		t.Errorf("a student who has done nothing has %d courses in their summary", len(done))
	}
}

// A NOTE SAYS WHICH COURSE IT CAME FROM. The screen that lists everything
// somebody wrote is a list across courses, and without this each entry is a
// paragraph with no way back to the page it belongs to.
func TestEveryNoteCarriesItsCourse(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := school(t, pool), student(t, pool)
	s := twoOpenCourses(t, pool)

	if err := s.SetNote(ctx, school, student,
		"web-fundamentals", "client-and-server", "roles", "the two roles"); err != nil {
		t.Fatal(err)
	}
	if err := s.SetNote(ctx, school, student, "html-css", "boxes", "overview", "margins"); err != nil {
		t.Fatal(err)
	}

	notes, err := s.AllNotes(ctx, school, student)
	if err != nil {
		t.Fatal(err)
	}
	if len(notes) != 2 {
		t.Fatalf("two notes in two courses came back as %d", len(notes))
	}

	from := map[string]string{}
	for _, n := range notes {
		if n.CourseID == "" {
			t.Errorf("a note came back naming no course: %q", n.Body)
		}
		from[n.CourseID] = n.Body
	}
	if from["html-css"] != "margins" {
		t.Errorf("the note on html-css came back as %q", from["html-css"])
	}
}

// NEWEST FIRST. A margin is read back while remembering, and what somebody is
// looking for is almost always what they wrote last — a list in catalogue order
// buries it under whichever course happens to sort first.
func TestNotesComeBackNewestFirst(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := school(t, pool), student(t, pool)
	s := twoOpenCourses(t, pool)

	// `html-css` sorts after `web-fundamentals` on neither field this orders by,
	// so a list that came back in catalogue order would put it second.
	if err := s.SetNote(ctx, school, student,
		"web-fundamentals", "client-and-server", "roles", "written first"); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx,
		`UPDATE notes SET updated_at = now() - interval '1 day' WHERE course_id = 'web-fundamentals'`,
	); err != nil {
		t.Fatal(err)
	}
	if err := s.SetNote(ctx, school, student, "html-css", "boxes", "overview", "written last"); err != nil {
		t.Fatal(err)
	}

	notes, err := s.AllNotes(ctx, school, student)
	if err != nil {
		t.Fatal(err)
	}
	if len(notes) != 2 {
		t.Fatalf("two notes came back as %d", len(notes))
	}
	if notes[0].Body != "written last" {
		t.Errorf("the first note is %q, want the one written last", notes[0].Body)
	}
}
