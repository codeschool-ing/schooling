package event_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/event"
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

// school returns one school to emit against, under a name nothing else uses.
//
// NO TRUNCATE. `go test` runs packages in parallel against one database, so
// clearing a shared table deletes another package's rows mid-run, and a fixed
// slug collides on the unique index. Every assertion below is therefore scoped
// to what this test wrote — which is a better assertion anyway.
func school(t *testing.T, pool *pgxpool.Pool) (uuid.UUID, string) {
	t.Helper()

	slug := "code-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`, slug,
	).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id, slug
}

// THE ONE THAT MATTERS.
//
// Every event carries the plan, the school, the country and the locale as they
// were when it happened. The failure this prevents is not an error — it is a
// report that answers with today's plan for something that happened in March,
// confidently and wrongly, which nobody notices.
func TestAnEventCarriesItsDimensions(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	ctx := context.Background()

	account := uuid.New()
	err := event.NewStore(pool).Emit(ctx, event.Event{
		Name:       "course.finished",
		Dimensions: event.ForSchool(id, slug, "annual", "BR", "pt-br", event.Real),
		AccountID:  &account,
		Payload:    map[string]any{"course": "python"},
	})
	if err != nil {
		t.Fatalf("emitting: %v", err)
	}

	// The plan then changes, which is the entire point: the row must not.
	var plan, country, locale, school string
	if err := pool.QueryRow(ctx, `
		SELECT plan, country, locale, school_slug FROM events
		WHERE name = 'course.finished' AND tenant_id = $1
	`, id).Scan(&plan, &country, &locale, &school); err != nil {
		t.Fatalf("reading it back: %v", err)
	}

	if plan != "annual" || country != "BR" || locale != "pt-br" || school != slug {
		t.Errorf("the dimensions did not survive: plan=%q country=%q locale=%q school=%q",
			plan, country, locale, school)
	}
}

// A dimension cannot be left out, and the reason it cannot is the type: there
// are no exported fields, so the only way to build one is a constructor that
// takes every dimension as an argument. This test is what remains to check —
// that a value which is present but empty is refused rather than stored as a
// blank that reads like a value.
func TestADimensionThatIsEmptyIsRefused(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	ctx := context.Background()
	store := event.NewStore(pool)

	for _, c := range []struct {
		what string
		dims event.Dimensions
	}{
		{"no plan", event.ForSchool(id, slug, "", "BR", "pt-br", event.Real)},
		{"no country", event.ForSchool(id, slug, "annual", "", "pt-br", event.Real)},
		{"no locale", event.ForSchool(id, slug, "annual", "BR", "", event.Real)},
		{"no slug beside the id", event.ForSchool(id, "", "annual", "BR", "pt-br", event.Real)},
	} {
		err := store.Emit(ctx, event.Event{Name: "test", Dimensions: c.dims})
		if err == nil {
			t.Errorf("%s: accepted, and the row would answer a report with a blank", c.what)
			continue
		}
		if !strings.Contains(err.Error(), "test") {
			t.Errorf("%s: the error does not name the event: %v", c.what, err)
		}
	}

	// And nothing was written by any of them.
	var count int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM events WHERE tenant_id = $1`, id).Scan(&count); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if count != 0 {
		t.Errorf("%d events were written by calls that should all have been refused", count)
	}
}

// A refused dimension reports every problem at once. A caller fixing them one
// per run is the same waste as a misconfigured deploy that teaches one fact per
// restart.
func TestEveryEmptyDimensionIsReportedTogether(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)

	err := event.NewStore(pool).Emit(context.Background(), event.Event{
		Name:       "test",
		Dimensions: event.ForSchool(id, slug, "", "", "", event.Real),
	})
	if err == nil {
		t.Fatal("an event with three empty dimensions was accepted")
	}
	for _, want := range []string{"plan", "country", "locale"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("%q is missing from the error, so it takes another run to find: %v", want, err)
		}
	}
}

// A platform event belongs to no school, and says so rather than guessing one.
func TestAPlatformEventNamesNoSchool(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	// A platform event has no school to scope the assertion by, so the name is
	// what makes it this test's row.
	name := "visitor.arrived." + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]

	err := event.NewStore(pool).Emit(ctx, event.Event{
		Name:       name,
		Dimensions: event.ForPlatform(event.PlanNone, event.Unknown, "en", event.Real),
	})
	if err != nil {
		t.Fatalf("emitting a platform event: %v", err)
	}

	var tenant *uuid.UUID
	var slug string
	if err := pool.QueryRow(ctx,
		`SELECT tenant_id, school_slug FROM events WHERE name = $1`, name,
	).Scan(&tenant, &slug); err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if tenant != nil || slug != "" {
		t.Errorf("a platform event claimed a school: tenant=%v slug=%q", tenant, slug)
	}
}

// Append-only is a trigger and not an arrangement. The difference shows up on
// the day somebody corrects data by hand, which is the day it matters.
func TestTheEventStreamRefusesToBeEdited(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	ctx := context.Background()

	if err := event.NewStore(pool).Emit(ctx, event.Event{
		Name:       "course.finished",
		Dimensions: event.ForSchool(id, slug, "annual", "BR", "pt-br", event.Real),
	}); err != nil {
		t.Fatalf("emitting: %v", err)
	}

	if _, err := pool.Exec(ctx,
		`UPDATE events SET plan = 'free' WHERE tenant_id = $1`, id); err == nil {
		t.Error("an event was rewritten — history is editable, and every report drawn from " +
			"it is now a claim rather than a record")
	}
	if _, err := pool.Exec(ctx,
		`DELETE FROM events WHERE tenant_id = $1`, id); err == nil {
		t.Error("an event was deleted")
	}

	var count int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM events WHERE tenant_id = $1`, id).Scan(&count); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if count != 1 {
		t.Errorf("%d events survived, want 1", count)
	}
}

// READING THE STREAM BACK, which is the half that had no test until item
// analysis needed one.
//
// The SQL digs the numbers out of a jsonb payload, and every one of those casts
// is a place where a silent mistake lives: a version read as text sorts "10"
// before "9", a missing key becomes a zero that looks like a score. So this
// writes real events and reads them back rather than trusting the query.
func TestTheAnswersToExamQuestionsCanBeReadBack(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	store := event.NewStore(pool)

	answered := func(exercise string, version int, correct bool, score, of int, attempt string) {
		t.Helper()
		if err := store.Emit(context.Background(), event.Event{
			Name:       event.ItemAnswered,
			Dimensions: event.ForSchool(id, slug, "full", "BR", "pt", event.Real),
			Payload: map[string]any{
				"exercise": exercise, "version": version, "type": "quiz",
				"correct": correct, "attempt": attempt, "score": score, "of": of,
			},
		}); err != nil {
			t.Fatalf("emitting: %v", err)
		}
	}

	answered("alpha", 2, true, 9, 10, "one")
	answered("alpha", 2, false, 3, 10, "two")
	answered("beta", 1, true, 9, 10, "one")

	read, err := store.ItemAnswers(context.Background(), id, time.Time{})
	if err != nil {
		t.Fatalf("reading them back: %v", err)
	}
	if len(read) != 3 {
		t.Fatalf("wrote 3 answers and read %d back", len(read))
	}

	first := read[0]
	switch {
	case first.ExerciseID != "alpha":
		t.Errorf("the exercise came back as %q", first.ExerciseID)
	case first.Version != 2:
		t.Errorf("the version came back as %d, not as the number 2", first.Version)
	case first.Type != "quiz":
		t.Errorf("the type came back as %q", first.Type)
	case first.AttemptID != "one":
		t.Errorf("the attempt came back as %q", first.AttemptID)
	case !first.Correct:
		t.Error("a correct answer came back wrong")
	case first.Score != 9 || first.Of != 10:
		t.Errorf("the mark came back as %d/%d", first.Score, first.Of)
	case first.AnsweredAt.IsZero():
		t.Error("the answer came back with no time on it")
	}
	if read[1].Correct {
		t.Error("a wrong answer came back correct")
	}
}

// AN EVENT FROM ANOTHER SCHOOL IS NOT IN THE ANSWER, and neither is one from
// before the window. Both are the same failure — a report counting rows nobody
// asked about — and the second is what keeps a question from being judged
// forever on answers to the version before it.
func TestReadingTheAnswersIsScopedToOneSchoolAndOneWindow(t *testing.T) {
	pool := testPool(t)
	mine, mySlug := school(t, pool)
	theirs, theirSlug := school(t, pool)
	store := event.NewStore(pool)

	payload := map[string]any{
		"exercise": "shared", "version": 1, "type": "quiz",
		"correct": true, "attempt": "a", "score": 5, "of": 10,
	}
	for _, s := range []struct {
		id   uuid.UUID
		slug string
	}{{mine, mySlug}, {theirs, theirSlug}} {
		if err := store.Emit(context.Background(), event.Event{
			Name:       event.ItemAnswered,
			Dimensions: event.ForSchool(s.id, s.slug, "full", "BR", "pt", event.Real),
			Payload:    payload,
		}); err != nil {
			t.Fatal(err)
		}
	}

	read, err := store.ItemAnswers(context.Background(), mine, time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if len(read) != 1 {
		t.Errorf("one school's answers came back as %d rows; the other school's are in it", len(read))
	}

	// And nothing from before the window.
	later, err := store.ItemAnswers(context.Background(), mine, time.Now().UTC().Add(time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if len(later) != 0 {
		t.Errorf("%d answers came back from before the window started", len(later))
	}
}

// AN EVENT OF ANOTHER NAME IS NOT AN ANSWER. The stream carries everything, and
// a reader that matched loosely would fold a sign-up into an item's statistics.
func TestOnlyAnswersComeBackFromTheAnswerReader(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	store := event.NewStore(pool)

	if err := store.Emit(context.Background(), event.Event{
		Name:       "exam.submitted",
		Dimensions: event.ForSchool(id, slug, "full", "BR", "pt", event.Real),
		Payload:    map[string]any{"exercise": "not-an-answer", "version": 1, "correct": true},
	}); err != nil {
		t.Fatal(err)
	}

	read, err := store.ItemAnswers(context.Background(), id, time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if len(read) != 0 {
		t.Errorf("%d rows came back from a stream holding no answers", len(read))
	}
}

// A SCHOOL WITH HISTORY IS FINDABLE WITHOUT ASKING THE MODULE THAT OWNS
// SCHOOLS. It is how a job that runs over all of them knows where to look.
func TestEverySchoolWithHistoryIsListed(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	store := event.NewStore(pool)

	if err := store.Emit(context.Background(), event.Event{
		Name:       "account.created",
		Dimensions: event.ForSchool(id, slug, "none", "BR", "pt", event.Real),
	}); err != nil {
		t.Fatal(err)
	}

	schools, err := store.Schools(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, s := range schools {
		if s == id {
			found = true
		}
	}
	if !found {
		t.Error("a school with an event in the stream was not listed")
	}
}

// A DIMENSION THAT DOES NOT SAY IS REFUSED, like every other one.
//
// The whole point of Dimensions having no exported fields is that a dimension
// cannot be omitted — and a population left blank would be an event that a
// report has to guess about, which is the guess that hides a seeded student
// inside a number about people.
func TestAnEventThatDoesNotSayWhichPopulationIsRefused(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	store := event.NewStore(pool)

	err := store.Emit(context.Background(), event.Event{
		Name:       "account.created",
		Dimensions: event.ForSchool(id, slug, "none", "BR", "pt", event.Population("")),
	})
	if err == nil {
		t.Fatal("an event with no population was written")
	}
	if !strings.Contains(err.Error(), "population") {
		t.Errorf("the refusal does not name the dimension: %v", err)
	}
}

// SYNTHETIC STUDENTS ARE OUT OF EVERY AGGREGATE BY DEFAULT (K-11).
//
// They exist so a cohort screen can be built before there is a population to
// make it legible (K-09). Counted into a report they would be the population —
// and a first real cohort born polluted has no way to be cleaned afterwards.
func TestASeededStudentIsNotInTheReports(t *testing.T) {
	pool := testPool(t)
	id, slug := school(t, pool)
	store := event.NewStore(pool)

	real, seeded := uuid.New(), uuid.New()
	emit := func(name string, who event.Population, account uuid.UUID, payload map[string]any) {
		t.Helper()
		if err := store.Emit(context.Background(), event.Event{
			Name:       name,
			Dimensions: event.ForSchool(id, slug, "full", "BR", "pt", who),
			AccountID:  &account,
			Payload:    payload,
		}); err != nil {
			t.Fatalf("emitting %s: %v", name, err)
		}
	}

	answer := map[string]any{
		"exercise": "shared", "version": 1, "type": "quiz",
		"correct": true, "attempt": "a", "score": 5, "of": 10,
	}
	emit(event.ItemAnswered, event.Real, real, answer)
	emit(event.ItemAnswered, event.Synthetic, seeded, answer)
	emit("account.created", event.Real, real, nil)
	emit("account.created", event.Synthetic, seeded, nil)

	// Item analysis: a seeded student answers at random, and counted in they
	// would drag a real question towards being quarantined.
	answers, err := store.ItemAnswers(context.Background(), id, time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if len(answers) != 1 {
		t.Errorf("item analysis read %d answers; only the real student's counts", len(answers))
	}

	// The funnel: counting seeded students would make it a funnel about the
	// seeder.
	reached, err := store.Reached(context.Background(), id, []string{"account.created"}, time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if len(reached) != 1 {
		t.Errorf("the funnel saw %d people at `account.created`; only the real one counts",
			len(reached))
	}
	if len(reached) == 1 && (reached[0].AccountID == nil || *reached[0].AccountID != real) {
		t.Errorf("the one counted is not the real student")
	}
}
