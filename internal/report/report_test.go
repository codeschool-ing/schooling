package report_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/report"
)

/* Saying something is wrong with the material, against a real Postgres.

   THE RULES THAT ONLY EXIST IN THE SCHEMA ARE CHECKED HERE and nowhere else:
   one open report per person per section, a settled one being settled twice,
   and the coordinates having to name something. Each of them is a partial
   index or a constraint, and none of them can be exercised against a fake. */

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

// The catalogue this store is checked against. It answers for one section and
// refuses everything else, which is exactly the shape the real closure has —
// and it means "no such section" is tested rather than assumed.
const (
	course  = "web-fundamentals"
	lesson  = "selectors"
	section = "specificity"
)

// The one exercise this store's catalogue knows about, and where it lives. It
// is deliberately in a DIFFERENT section from the one above: a test that put
// both in the same place could not tell "the exercise was located" from "the
// section was used".
const (
	exercise        = "ex-specificity-3"
	exerciseSection = "cascade"
	exerciseVersion = 4
)

func aStore(t *testing.T, pool *pgxpool.Pool) *report.Store {
	t.Helper()
	return report.NewStore(pool,
		func(_ context.Context, _ uuid.UUID, c, l, s string) (bool, error) {
			return c == course && l == lesson && s == section, nil
		},
		func(_ context.Context, _ uuid.UUID, id string) (string, string, string, int, error) {
			if id != exercise {
				return "", "", "", 0, nil
			}
			return course, lesson, exerciseSection, exerciseVersion, nil
		},
	)
}

// A school and a person to hang the rows on. No catalogue rows: what the store
// knows about the catalogue arrives through `Knows`, which is the whole reason
// that seam exists.
func aSchool(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	slug := "rep-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:10]
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

func aStudent(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	email := strings.ReplaceAll(uuid.NewString(), "-", "")[:16] + "@example.tld"
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO accounts (email, name) VALUES ($1, 'Ada') RETURNING id`,
		email).Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

func aReport(school, student uuid.UUID) report.New {
	return report.New{
		School: school, Account: student,
		CourseID: course, LessonID: lesson, SectionID: section,
		Reason: report.ReasonAnswer, Note: "the key says B and the working shows C",
	}
}

func TestAReportReachesTheQueue(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	one, already, err := store.Make(ctx, aReport(school, student))
	if err != nil {
		t.Fatalf("making a report: %v", err)
	}
	if already {
		t.Error("the first report of a section came back as one that was already there")
	}

	queue, err := store.Open(ctx, school)
	if err != nil {
		t.Fatalf("reading the queue: %v", err)
	}
	if len(queue) != 1 || queue[0].ID != one.ID {
		t.Fatalf("the queue holds %d reports and not the one just made: %+v", len(queue), queue)
	}
	if queue[0].Note != "the key says B and the working shows C" {
		t.Errorf("the words the student wrote did not survive: %q", queue[0].Note)
	}
}

/*
A SECOND REPORT OF THE SAME SECTION IS THE FIRST ONE, AND SAYS SO.

Somebody who clicks twice, or comes back a week later still annoyed, has not
found a second defect — and a queue one person can put the same complaint in
repeatedly is a queue whose length stops meaning anything. What must NOT happen
is the second call overwriting the first note: what they wrote when they first
noticed is the report.
*/
func TestASecondReportOfTheSameSectionIsTheFirstOne(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	first, _, err := store.Make(ctx, aReport(school, student))
	if err != nil {
		t.Fatalf("making a report: %v", err)
	}

	second := aReport(school, student)
	second.Reason = report.ReasonUnclear
	second.Note = ""
	again, already, err := store.Make(ctx, second)
	if err != nil {
		t.Fatalf("reporting the same section again: %v", err)
	}
	if !already {
		t.Error("the second report of one section did not say it was already there")
	}
	if again.ID != first.ID {
		t.Errorf("it made a second row: %v then %v", first.ID, again.ID)
	}
	if again.Note != first.Note {
		t.Errorf("the second call overwrote what was first written: %q", again.Note)
	}

	queue, err := store.Open(ctx, school)
	if err != nil {
		t.Fatal(err)
	}
	if len(queue) != 1 {
		t.Errorf("one section was reported twice and the queue holds %d", len(queue))
	}
}

// AND ONCE IT IS SETTLED THEY MAY SAY IT AGAIN, which is the right behaviour
// for a fix that did not work. The unique index is partial for exactly this.
func TestASettledSectionCanBeReportedAgain(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)
	operator := aStudent(t, pool)

	first, _, err := store.Make(ctx, aReport(school, student))
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Settle(ctx, first.ID, operator, report.VerdictFixed); err != nil {
		t.Fatalf("settling: %v", err)
	}

	again, already, err := store.Make(ctx, aReport(school, student))
	if err != nil {
		t.Fatalf("reporting a settled section again: %v", err)
	}
	if already || again.ID == first.ID {
		t.Error("reporting a section that was settled did not open a new report")
	}
}

// COORDINATES THAT NAME NOTHING DO NOT REACH THE QUEUE. The interface only ever
// sends what it drew, so a report that fails this is a stale tab or somebody
// with a terminal — and an operator should not spend an afternoon looking for a
// section that does not exist.
func TestAReportAboutNothingIsRefused(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	made := aReport(school, student)
	made.SectionID = "a-section-nobody-wrote"
	if _, _, err := store.Make(ctx, made); !errors.Is(err, report.ErrNoSuchSection) {
		t.Errorf("a report about nothing answered %v", err)
	}

	queue, err := store.Open(ctx, school)
	if err != nil {
		t.Fatal(err)
	}
	if len(queue) != 0 {
		t.Errorf("it reached the queue anyway: %+v", queue)
	}
}

// A WORD THAT IS NOT ON THE LIST IS REFUSED, and the sentence says what the
// list is — the caller can fix this by sending something else, which is what
// `ErrRefused` means.
func TestAReasonThatIsNotOnTheListIsRefused(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	made := aReport(school, student)
	made.Reason = "annoying"
	_, _, err := store.Make(ctx, made)
	if !errors.Is(err, report.ErrRefused) {
		t.Fatalf("an unknown reason answered %v", err)
	}
	if !strings.Contains(err.Error(), report.ReasonAnswer) {
		t.Errorf("the refusal does not say what the list is: %v", err)
	}
}

// AND A NOTE OVER THE LIMIT. The database carries the same number as a check,
// so this is the pair of them agreeing rather than the Go half alone.
func TestANoteOverTheLimitIsRefused(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	made := aReport(school, student)
	made.Note = strings.Repeat("x", report.NoteLimit+1)
	if _, _, err := store.Make(ctx, made); !errors.Is(err, report.ErrRefused) {
		t.Errorf("a note of %d characters answered %v", report.NoteLimit+1, err)
	}
}

/*
SETTLING IS ONCE.

The audit entry names what was decided, so a row that could be re-settled would
be a history saying two different things happened and a table agreeing with only
the later one. Two operators working the same queue is the ordinary way this
comes up rather than a defect, so the second is told what happened instead of
being told nothing did.
*/
func TestAReportIsSettledOnce(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)
	operator := aStudent(t, pool)

	one, _, err := store.Make(ctx, aReport(school, student))
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Settle(ctx, one.ID, operator, report.VerdictFixed); err != nil {
		t.Fatalf("settling: %v", err)
	}
	if err := store.Settle(ctx, one.ID, operator, report.VerdictNoChange); !errors.Is(
		err, report.ErrAlreadySettled) {
		t.Errorf("settling a settled report answered %v", err)
	}

	// And what it says is the FIRST decision.
	back, err := store.One(ctx, one.ID)
	if err != nil {
		t.Fatal(err)
	}
	if back.Verdict != report.VerdictFixed {
		t.Errorf("the second decision overwrote the first: %q", back.Verdict)
	}

	queue, err := store.Open(ctx, school)
	if err != nil {
		t.Fatal(err)
	}
	if len(queue) != 0 {
		t.Errorf("a settled report is still in the queue: %+v", queue)
	}
}

// A REPORT NOBODY HAS IS NOT THE SAME ANSWER AS ONE SOMEBODY SETTLED. They are
// different sentences to an operator, and answering both as "that did not work"
// is how a queue teaches people to reload and try again for no reason.
func TestSettlingAReportThatIsNotThereSaysSo(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)

	err := store.Settle(context.Background(), uuid.New(), uuid.New(), report.VerdictFixed)
	if !errors.Is(err, report.ErrNoSuchReport) {
		t.Errorf("settling a report nobody has answered %v", err)
	}
}

/*
THE QUEUE IS ONE SCHOOL'S, AND A STUDENT'S OWN LIST IS ONE PERSON'S.

Both boundaries in one test, because both are a WHERE clause and a missing
WHERE clause is the same defect twice: an operator of one school reading
another's complaints, and a student being shown somebody else's.
*/
func TestTheQueueIsOneSchoolsAndTheListIsOnePersons(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()

	mine, theirs := aSchool(t, pool), aSchool(t, pool)
	me, them := aStudent(t, pool), aStudent(t, pool)

	if _, _, err := store.Make(ctx, aReport(mine, me)); err != nil {
		t.Fatal(err)
	}
	if _, _, err := store.Make(ctx, aReport(theirs, them)); err != nil {
		t.Fatal(err)
	}

	queue, err := store.Open(ctx, mine)
	if err != nil {
		t.Fatal(err)
	}
	if len(queue) != 1 {
		t.Fatalf("one school's queue holds %d reports", len(queue))
	}

	list, err := store.Mine(ctx, mine, me)
	if err != nil {
		t.Fatal(err)
	}
	if len(list) != 1 {
		t.Fatalf("this student reported one section and their list holds %d", len(list))
	}

	nothing, err := store.Mine(ctx, mine, them)
	if err != nil {
		t.Fatal(err)
	}
	if len(nothing) != 0 {
		t.Errorf("a student was shown %d of somebody else's reports", len(nothing))
	}
}

/*
ERASING THE PERSON TAKES THEIR WORDS WITH THEM.

The registry says this table cascades, and the reason is that `note` is a
sentence somebody wrote. A row that outlived its author would be their words
kept after they asked to be forgotten — and it would be in the console's queue,
which is where somebody would read them.
*/
func TestErasingTheStudentTakesTheReport(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	if _, _, err := store.Make(ctx, aReport(school, student)); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, `DELETE FROM accounts WHERE id = $1`, student); err != nil {
		t.Fatalf("erasing the student: %v", err)
	}

	queue, err := store.Open(ctx, school)
	if err != nil {
		t.Fatal(err)
	}
	if len(queue) != 0 {
		t.Errorf("an erased student's words are still in the queue: %+v", queue)
	}
}

/* ---------- which question, and not only which section ---------- */

/*
THE EXERCISE BRINGS ITS OWN COORDINATES.

A drilled card carries an exercise and no path — its queue spans courses — so
the client sends one field and the store reads the rest. That is not a
convenience: a browser that told us where a question lives would be a browser
whose copy of the catalogue can be older than ours, and a stale tab would file a
report against a section the question has since left.
*/
func TestReportingAQuestionFindsWhereItLives(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	one, already, err := store.Make(ctx, report.New{
		School: school, Account: student,
		ExerciseID: exercise,
		Reason:     report.ReasonAnswer,
		Note:       "it marks B and the working gives C",
	})
	if err != nil {
		t.Fatalf("reporting a question: %v", err)
	}
	if already {
		t.Error("the first report of a question came back as one already there")
	}
	if one.CourseID != course || one.SectionID != exerciseSection {
		t.Errorf("the report landed at %s / %s / %s", one.CourseID, one.LessonID, one.SectionID)
	}
	if one.ExerciseID != exercise {
		t.Errorf("which question is %q", one.ExerciseID)
	}
	if one.Version != exerciseVersion {
		t.Errorf("the version is %d — a key fixed last week and a report from last month "+
			"are about different questions with one id", one.Version)
	}
}

// THE CLIENT'S COORDINATES ARE IGNORED WHEN IT NAMES A QUESTION. Whatever a
// stale tab believes about where the exercise lives, the catalogue decides.
func TestAQuestionsCoordinatesComeFromTheCatalogueAndNotTheCaller(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	one, _, err := store.Make(ctx, report.New{
		School: school, Account: student,
		// A section that exists, and is not this exercise's.
		CourseID: course, LessonID: lesson, SectionID: section,
		ExerciseID: exercise,
		Reason:     report.ReasonAnswer,
	})
	if err != nil {
		t.Fatal(err)
	}
	if one.SectionID != exerciseSection {
		t.Errorf("the caller's section won: %q", one.SectionID)
	}
}

/*
TWO BAD QUESTIONS IN ONE ASSESSMENT ARE TWO REPORTS.

The unique index used to key on the section alone. An assessment is a section,
so the second question a student found would have read as a duplicate of the
first — silently, with a message thanking them for something they had already
said. That is the exact failure this feature exists to prevent, arriving through
its own guard.
*/
func TestTwoQuestionsInOneSectionAreTwoReports(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	// A store whose catalogue knows two exercises, both in one section.
	store := report.NewStore(pool,
		func(context.Context, uuid.UUID, string, string, string) (bool, error) {
			return true, nil
		},
		func(_ context.Context, _ uuid.UUID, id string) (string, string, string, int, error) {
			return course, lesson, exerciseSection, 1, nil
		},
	)

	first, _, err := store.Make(ctx, report.New{
		School: school, Account: student,
		ExerciseID: "ex-one", Reason: report.ReasonAnswer,
	})
	if err != nil {
		t.Fatal(err)
	}
	second, already, err := store.Make(ctx, report.New{
		School: school, Account: student,
		ExerciseID: "ex-two", Reason: report.ReasonAnswer,
	})
	if err != nil {
		t.Fatalf("reporting a second question in the same section: %v", err)
	}
	if already || second.ID == first.ID {
		t.Error("the second question in one section read as a duplicate of the first")
	}

	// And the same question twice is still one report.
	if _, again, err := store.Make(ctx, report.New{
		School: school, Account: student,
		ExerciseID: "ex-one", Reason: report.ReasonUnclear,
	}); err != nil || !again {
		t.Errorf("reporting one question twice answered %v, already=%v", err, again)
	}
}

// A QUESTION THIS SCHOOL DOES NOT HAVE IS ITS OWN REFUSAL, and not the
// section's — they are different sentences to whoever sent it.
func TestReportingAQuestionNobodyHasSaysSo(t *testing.T) {
	pool := testPool(t)
	store := aStore(t, pool)
	school, student := aSchool(t, pool), aStudent(t, pool)

	_, _, err := store.Make(context.Background(), report.New{
		School: school, Account: student,
		ExerciseID: "ex-nobody-wrote-this", Reason: report.ReasonAnswer,
	})
	if !errors.Is(err, report.ErrNoSuchExercise) {
		t.Errorf("a question nobody has answered %v", err)
	}
}

/*
AN EXERCISE THE CATALOGUE CANNOT PLACE IS STILL REPORTABLE.

`catalog_exercises` carries a section for almost every exercise and not for
every one. Refusing those would close this channel for exactly the questions a
student meets most often in the drill — so the report is written with the
course and the question, and the path it does not know is left blank rather
than guessed at.
*/
func TestAQuestionWithNoSectionIsStillReportable(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	school, student := aSchool(t, pool), aStudent(t, pool)

	store := report.NewStore(pool,
		func(context.Context, uuid.UUID, string, string, string) (bool, error) {
			return false, nil
		},
		func(_ context.Context, _ uuid.UUID, id string) (string, string, string, int, error) {
			// A course, and nothing else the catalogue can say.
			return course, "", "", 2, nil
		},
	)

	one, _, err := store.Make(ctx, report.New{
		School: school, Account: student,
		ExerciseID: "ex-loose", Reason: report.ReasonAnswer,
	})
	if err != nil {
		t.Fatalf("a question with no section was refused: %v", err)
	}
	if one.SectionID != "" || one.LessonID != "" {
		t.Errorf("a path was invented: %s / %s", one.LessonID, one.SectionID)
	}
	if one.CourseID != course {
		t.Errorf("the course was lost: %q", one.CourseID)
	}
}
