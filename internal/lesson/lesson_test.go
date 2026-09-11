package lesson_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/lesson"
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

// The catalogue as the one question this module asks it. A fake is honest here:
// what is under test is what this package does with the answer.
func mayOpen(_ context.Context, courseID string) (bool, error) {
	return courseID != "paid-course", nil
}

func nothingWithdrawn(context.Context, uuid.UUID) (map[lesson.Item]bool, error) {
	return nil, nil
}

func school(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"lesson-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:9]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

type seed struct {
	id      string
	course  string
	lesson  string
	exam    bool
	kind    string
	payload string
}

func questions(t *testing.T, pool *pgxpool.Pool, tenant uuid.UUID, qs ...seed) {
	t.Helper()
	for _, q := range qs {
		if _, err := pool.Exec(context.Background(), `
			INSERT INTO catalog_exercises
				(tenant_id, id, course_id, lesson_id, section_id, exam, version, type,
				 drillable, prompt, payload)
			VALUES ($1, $2, $3, $4, 'roles', $5, 1, $6, false, 'Which one?', $7::jsonb)
		`, tenant, q.id, q.course, q.lesson, q.exam, q.kind, q.payload); err != nil {
			t.Fatalf("seeding %s: %v", q.id, err)
		}
	}
}

func quiz(id string) string {
	return `{"id":"` + id + `","version":1,"type":"quiz","prompt":"Which one?","choices":[` +
		`{"text":"the client, since it did the asking","correct":true,"why":"Whoever asks is the client."},` +
		`{"text":"the server, since that is what it is","correct":false,"why":"Its part in the other exchange does not carry over."},` +
		`{"text":"both, since it holds two exchanges","correct":false,"why":"Two roles across two exchanges, one part in each."}]}`
}

func store(pool *pgxpool.Pool) *lesson.Store {
	return lesson.NewStore(pool, mayOpen, nothingWithdrawn)
}

func TestALessonsQuestionsComeBackWithoutTheirKeys(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant, seed{"ex-one", "free-course", "le-one", false, "quiz", quiz("ex-one")})

	got, err := store(pool).Questions(ctx, tenant, "free-course", "le-one", "en")
	if err != nil {
		t.Fatalf("reading the questions: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("want 1 question, got %d", len(got))
	}

	// THE POINT OF THE WHOLE ROUTE. A lesson's questions served with their
	// answers in them is an assessment you pass by reading the response.
	shown := string(got[0].Shown)
	for _, leak := range []string{`"correct"`, `"why"`} {
		if strings.Contains(shown, leak) {
			t.Errorf("the presented question carries %s:\n%s", leak, shown)
		}
	}
}

func TestAnExamQuestionIsNotAmongALessonsQuestions(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant,
		seed{"ex-lesson", "free-course", "le-two", false, "quiz", quiz("ex-lesson")},
		// An exam question that names a lesson, which is the shape that would
		// leak the paper if the route trusted the lesson id alone.
		seed{"ex-paper", "free-course", "le-two", true, "quiz", quiz("ex-paper")})

	got, err := store(pool).Questions(ctx, tenant, "free-course", "le-two", "en")
	if err != nil {
		t.Fatalf("reading the questions: %v", err)
	}
	for _, q := range got {
		if q.ExerciseID == "ex-paper" {
			t.Fatal("an exam question was served as one of the lesson's")
		}
	}
	if len(got) != 1 {
		t.Fatalf("want only the lesson's own question, got %d", len(got))
	}
}

func TestAnExamQuestionCannotBeAnsweredThroughThisRoute(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant, seed{"ex-sealed", "free-course", "le-three", true, "quiz", quiz("ex-sealed")})

	_, err := store(pool).Answered(ctx, tenant, "ex-sealed", nil, chose(0), "en")
	if !errors.Is(err, lesson.ErrIsAnExamQuestion) {
		t.Fatalf("want ErrIsAnExamQuestion, got %v", err)
	}
}

func TestACourseThePlanDoesNotOpenIsRefusedRatherThanServed(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant, seed{"ex-paid", "paid-course", "le-four", false, "quiz", quiz("ex-paid")})

	if _, err := store(pool).Questions(ctx, tenant, "paid-course", "le-four", "en"); !errors.Is(err, lesson.ErrLocked) {
		t.Fatalf("reading: want ErrLocked, got %v", err)
	}
	if _, err := store(pool).Answered(ctx, tenant, "ex-paid", nil, chose(0), "en"); !errors.Is(err, lesson.ErrLocked) {
		t.Fatalf("answering: want ErrLocked, got %v", err)
	}
}

// A WITHDRAWN QUESTION IS LEFT OUT OF THE SET AND REFUSED IF ANSWERED, and the
// asymmetry is deliberate: a lesson with one question fewer is a shorter
// section, while a screen fetched before the sweep still holds the question and
// must not be given a verdict from a key the school has stopped standing behind.
func TestAWithdrawnQuestionIsLeftOutAndRefusedIfAnswered(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant,
		seed{"ex-good", "free-course", "le-five", false, "quiz", quiz("ex-good")},
		seed{"ex-bad", "free-course", "le-five", false, "quiz", quiz("ex-bad")})

	out := func(context.Context, uuid.UUID) (map[lesson.Item]bool, error) {
		return map[lesson.Item]bool{{ExerciseID: "ex-bad", Version: 1}: true}, nil
	}
	s := lesson.NewStore(pool, mayOpen, out)

	got, err := s.Questions(ctx, tenant, "free-course", "le-five", "en")
	if err != nil {
		t.Fatalf("reading the questions: %v", err)
	}
	if len(got) != 1 || got[0].ExerciseID != "ex-good" {
		t.Fatalf("the withdrawn question was served: %+v", got)
	}

	if _, err := s.Answered(ctx, tenant, "ex-bad", nil, chose(0), "en"); !errors.Is(err, lesson.ErrWithdrawn) {
		t.Fatalf("want ErrWithdrawn, got %v", err)
	}
}

// THE ANSWER IS GIVEN IN THE FRAME THE STUDENT SAW. Without the permutation,
// a correct answer to a shuffled question is marked against a question nobody
// was shown — which is the failure that is invisible until it is a wrong mark.
func TestACorrectAnswerSurvivesTheShuffle(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant, seed{"ex-shuf", "free-course", "le-six", false, "quiz", quiz("ex-shuf")})

	s := store(pool)
	got, err := s.Questions(ctx, tenant, "free-course", "le-six", "en")
	if err != nil {
		t.Fatalf("reading the questions: %v", err)
	}
	q := got[0]

	// Where the correct option ended up, found the way a student finds it:
	// by knowing the material, which here is knowing its text.
	var shown struct {
		Choices []struct {
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(q.Shown, &shown); err != nil {
		t.Fatalf("reading the presented question: %v", err)
	}
	at := -1
	for i, c := range shown.Choices {
		if strings.HasPrefix(c.Text, "the client") {
			at = i
		}
	}
	if at < 0 {
		t.Fatal("the correct option is not among the ones shown")
	}

	marked, err := s.Answered(ctx, tenant, "ex-shuf", q.Perm, chose(at), "en")
	if err != nil {
		t.Fatalf("answering: %v", err)
	}
	if !marked.Correct {
		t.Fatalf("the right answer was marked wrong; perm=%v, chose %d", q.Perm, at)
	}
}

func TestAWrongAnswerComesBackWithTheReasonRatherThanOnlyAVerdict(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	tenant := school(t, pool)
	questions(t, pool, tenant, seed{"ex-why", "free-course", "le-seven", false, "quiz", quiz("ex-why")})

	s := store(pool)
	got, err := s.Questions(ctx, tenant, "free-course", "le-seven", "en")
	if err != nil {
		t.Fatalf("reading the questions: %v", err)
	}
	q := got[0]

	var shown struct {
		Choices []struct {
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(q.Shown, &shown); err != nil {
		t.Fatalf("reading the presented question: %v", err)
	}
	wrong := -1
	for i, c := range shown.Choices {
		if strings.HasPrefix(c.Text, "the server") {
			wrong = i
		}
	}
	if wrong < 0 {
		t.Fatal("the wrong option under test is not among the ones shown")
	}

	marked, err := s.Answered(ctx, tenant, "ex-why", q.Perm, chose(wrong), "en")
	if err != nil {
		t.Fatalf("answering: %v", err)
	}
	if marked.Correct {
		t.Fatal("a wrong answer was marked right")
	}
	// A-10: the `why` is the deliverable. A lesson that said "wrong" and
	// stopped would spend the best teaching moment it gets on nothing.
	if marked.Why == "" {
		t.Error("the wrong answer came back with no reason")
	}
	if marked.Reveal.Expected == nil {
		t.Error("the wrong answer came back with no key to compare against")
	}
}

// A-10 HELD BY THE SOURCE RATHER THAN BY A PARAGRAPH.
//
// This package must write nothing: no score, no attempt, no schedule. A test
// that answered a question and then looked for rows could only look in the
// tables somebody thought of, and the damage would be done by a table nobody
// thought of. A scan for the verbs is the check that cannot be outgrown — the
// same reason the practice suite proves decayed strength never reaches a
// progress bar by reading source rather than by querying.
func TestThisPackageWritesNothing(t *testing.T) {
	for _, name := range []string{"lesson.go", "http.go"} {
		body, err := os.ReadFile(filepath.Join(".", name)) //nolint:gosec // this package's own source, by name
		if err != nil {
			t.Fatalf("reading %s: %v", name, err)
		}
		text := strings.ToUpper(string(body))
		for _, verb := range []string{"INSERT INTO", "UPDATE ", "DELETE FROM", "POOL.EXEC"} {
			if strings.Contains(text, verb) {
				t.Errorf("%s contains %q — A-10 says a lesson's questions keep no score, "+
					"and nothing here may write", name, verb)
			}
		}
	}
}

// chose is one answer to a `quiz`, in the shape the grader decodes.
//
// IT IS `{"chose":[n]}` AND NOT `n`, which is the whole of what CI found: a
// bare number is a well-formed JSON document that `choiceAnswer` cannot read,
// so every test that answered a question came back with ErrBadAnswer instead
// of a verdict. There is no database in the environment these were written in,
// so the first run of them was the one on the server.
func chose(at int) json.RawMessage {
	return json.RawMessage(fmt.Sprintf(`{"chose":[%d]}`, at))
}
