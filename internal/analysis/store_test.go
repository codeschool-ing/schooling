package analysis_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/analysis"
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

func school(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"items-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:10]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

// A store whose answers are the ones handed to it, so what is under test is
// what this module does with them. The stream's own tests cover the reading.
func storeOver(t *testing.T, pool *pgxpool.Pool, of map[uuid.UUID][]analysis.Answer) *analysis.Store {
	t.Helper()
	return analysis.NewStore(pool,
		func(_ context.Context, id uuid.UUID, since time.Time) ([]analysis.Answer, error) {
			var out []analysis.Answer
			for _, a := range of[id] {
				if a.AnsweredAt.Before(since) {
					continue
				}
				out = append(out, a)
			}
			return out, nil
		},
		func(context.Context) ([]uuid.UUID, error) {
			ids := make([]uuid.UUID, 0, len(of))
			for id := range of {
				ids = append(ids, id)
			}
			return ids, nil
		},
	)
}

// THE JOB WRITES A VERDICT AND THE CONSOLE READS IT BACK. Everything else here
// checks an edge; this checks the loop closes.
func TestARunWritesWhatTheAnswersCameTo(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)

	broken := paper(20, 0, 20, 20) // inverted
	for i := range broken {
		broken[i].ExerciseID = "broken"
	}
	good := paper(20, 18, 20, 4)
	for i := range good {
		good[i].ExerciseID = "good"
	}

	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: append(broken, good...)})

	written, err := store.Run(context.Background(), time.Time{}, time.Now().UTC())
	if err != nil {
		t.Fatalf("running: %v", err)
	}
	if written != 2 {
		t.Fatalf("the run wrote %d question(s), want 2", written)
	}

	all, err := store.Of(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 2 {
		t.Fatalf("reading back gave %d row(s)", len(all))
	}

	// WORST FIRST. A console listing in id order is one nobody reads to the
	// bottom, and the row that matters is the one saying a key is inverted.
	if all[0].ExerciseID != "broken" || all[0].Verdict != analysis.VerdictInverted {
		t.Errorf("the first row is %s (%s); the inverted question should lead",
			all[0].ExerciseID, all[0].Verdict)
	}

	flagged, err := store.Flagged(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if len(flagged) != 1 || flagged[0].ExerciseID != "broken" {
		t.Errorf("what is flagged is %v; only the inverted question is something to act on", flagged)
	}
}

// THE THRESHOLD IS STORED, NOT LOOKED UP (K-16). A verdict computed under a
// minimum of thirty and later displayed beside a constant that says fifty would
// be a row explaining itself with the wrong number.
func TestTheStoredRowSaysWhatItWasMeasuredAgainst(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 18, 20, 4)})

	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	all, err := store.Of(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 1 {
		t.Fatalf("%d rows", len(all))
	}
	if all[0].MinimumSample != analysis.MinimumSample {
		t.Errorf("the row says the minimum sample was %d", all[0].MinimumSample)
	}
	if all[0].StrongGroup == 0 || all[0].WeakGroup == 0 {
		t.Errorf("the groups behind the index were not stored: %d and %d",
			all[0].StrongGroup, all[0].WeakGroup)
	}
}

// RUNNING IT AGAIN OVERWRITES RATHER THAN ACCUMULATES. The rows are a cache of
// what the stream says; a second run that doubled every count would be a job
// nobody could run twice, which is the one property a scheduled job needs.
func TestRunningTwiceLeavesTheSameNumbers(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 18, 20, 4)})

	for range 3 {
		if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
			t.Fatal(err)
		}
	}

	all, err := store.Of(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 1 {
		t.Fatalf("three runs left %d rows for one question", len(all))
	}
	if all[0].Attempts != 40 {
		t.Errorf("after three runs the question has %d attempts, want the 40 it was answered",
			all[0].Attempts)
	}
}

// A VERDICT THAT CHANGES IS REPLACED, NOT ADDED TO. The fix for an inverted key
// is a new version of the question, but a threshold moving or more answers
// arriving changes the verdict of the version that is already there — and a
// console showing both would be a console showing yesterday's finding as
// current.
func TestAVerdictThatChangesReplacesTheOldOne(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)

	answers := map[uuid.UUID][]analysis.Answer{id: paper(20, 0, 20, 20)} // inverted
	store := storeOver(t, pool, answers)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	// The same question, answered the way a working one is.
	answers[id] = paper(20, 18, 20, 4)
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	all, err := store.Of(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 1 {
		t.Fatalf("%d rows for one question and one version", len(all))
	}
	if all[0].Verdict != analysis.VerdictFine {
		t.Errorf("the verdict is still %q after the answers changed", all[0].Verdict)
	}
}

// ONE SCHOOL'S QUESTIONS ARE NOT ANOTHER'S. The unit of a report is a school,
// and a console showing a row from a school nobody is looking at is a leak of
// what is being taught somewhere else.
func TestTheStatisticsOfOneSchoolStayInIt(t *testing.T) {
	pool := testPool(t)
	first, second := school(t, pool), school(t, pool)

	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{
		first:  paper(20, 18, 20, 4),
		second: paper(20, 0, 20, 20),
	})
	if _, err := store.Run(context.Background(), time.Time{}, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	flagged, err := store.Flagged(context.Background(), first)
	if err != nil {
		t.Fatal(err)
	}
	if len(flagged) != 0 {
		t.Errorf("the first school has %d flagged question(s); the broken one is the "+
			"second school's", len(flagged))
	}

	if flagged, err = store.Flagged(context.Background(), second); err != nil {
		t.Fatal(err)
	}
	if len(flagged) != 1 {
		t.Errorf("the second school has %d flagged question(s), want its one", len(flagged))
	}
}

// A WINDOW LEAVES OLD ANSWERS OUT. A question edited eighteen months ago should
// not be judged forever on answers to the version before it.
func TestAnswersOlderThanTheWindowAreNotCounted(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)

	old := paper(20, 0, 20, 20) // inverted, and long ago
	for i := range old {
		old[i].AnsweredAt = time.Now().UTC().AddDate(-2, 0, 0)
	}
	recent := paper(20, 18, 20, 4)
	for i := range recent {
		recent[i].AnsweredAt = time.Now().UTC()
	}

	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: append(old, recent...)})

	since := time.Now().UTC().AddDate(-1, 0, 0)
	if _, err := store.Run(context.Background(), since, time.Now().UTC()); err != nil {
		t.Fatal(err)
	}

	all, err := store.Of(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 1 {
		t.Fatalf("%d rows", len(all))
	}
	if all[0].Attempts != 40 {
		t.Errorf("%d attempts were counted; only the 40 inside the window should be",
			all[0].Attempts)
	}
	if all[0].Verdict != analysis.VerdictFine {
		t.Errorf("the verdict is %q — the answers to the old version are still deciding it",
			all[0].Verdict)
	}
}

// A school nobody has sat an exam in is not an error and not a row.
func TestASchoolWithNoAnswersWritesNothing(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)
	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: nil})

	written, err := store.Run(context.Background(), time.Time{}, time.Now().UTC())
	if err != nil {
		t.Fatalf("running over a school with no answers: %v", err)
	}
	if written != 0 {
		t.Errorf("it wrote %d row(s) for a school where nobody has sat anything", written)
	}
}

// A ROLLUP THAT WAS NEVER MADE AND ONE THAT FOUND NOTHING LOOK IDENTICAL IN THE
// ROWS AND ARE DIFFERENT PROBLEMS.
//
// The first is broken machinery — a nightly job that has been failing, whose
// numbers on a console look exactly like this morning's. The second is a school
// nobody has answered anything in, which is an answer. A screen cannot tell them
// apart without being told, so the reading says which.
func TestWhenTheStatisticsWereMadeAndWhetherEverWere(t *testing.T) {
	pool := testPool(t)
	id := school(t, pool)

	store := storeOver(t, pool, map[uuid.UUID][]analysis.Answer{id: paper(20, 18, 20, 4)})

	if _, computed, err := store.ComputedAt(context.Background(), id); err != nil {
		t.Fatal(err)
	} else if computed {
		t.Error("a school the job has never run over says it has statistics")
	}

	now := time.Now().UTC().Truncate(time.Second)
	if _, err := store.Run(context.Background(), time.Time{}, now); err != nil {
		t.Fatalf("running: %v", err)
	}

	at, computed, err := store.ComputedAt(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if !computed {
		t.Fatal("the job ran and the school still says nothing has been computed")
	}
	if !at.Equal(now) {
		t.Errorf("the rollup says it was made at %v, and the run was at %v", at, now)
	}

	// A SECOND RUN MOVES IT, which is the whole point: the number a console
	// shows is how old its numbers are, and a date that stuck at the first run
	// would say a healthy job had stopped.
	later := now.Add(24 * time.Hour)
	if _, err := store.Run(context.Background(), time.Time{}, later); err != nil {
		t.Fatalf("running again: %v", err)
	}
	if at, _, err := store.ComputedAt(context.Background(), id); err != nil {
		t.Fatal(err)
	} else if !at.Equal(later) {
		t.Errorf("after a second run it still says %v, want %v", at, later)
	}

	// AND IT IS ONE SCHOOL'S ANSWER. A max over every school would report a
	// platform where one school is analysed nightly and another has been
	// failing for a month as though both were current.
	other := school(t, pool)
	if _, computed, err := store.ComputedAt(context.Background(), other); err != nil {
		t.Fatal(err)
	} else if computed {
		t.Error("a school with no rows of its own reported another school's run")
	}
}
