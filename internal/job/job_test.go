package job_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/job"
)

/* That a job ran, against a real Postgres.

   THE ROWS THIS FILE IS ABOUT ARE THE ONES NOBODY WRITES ON PURPOSE. A run that
   succeeded records itself; a run that failed records itself; the row that
   matters most is the one left behind by a process that was killed, and no line
   of code writes it — it is what remains when the closing write never happens.
   Every test below is a way of asking whether that row survives being read. */

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

// A name unique to each test: this table is not truncated between them and
// `Latest` is scoped by job, so a shared name would make one test read
// another's runs.
func aJob(t *testing.T) string {
	t.Helper()
	return "test-" + strings.ReplaceAll(t.Name(), "/", "-")
}

func TestARunThatSucceededSaysWhatItDid(t *testing.T) {
	store := job.NewStore(testPool(t))
	ctx := context.Background()
	name := aJob(t)

	id, err := store.Started(ctx, name, "v1.2.3")
	if err != nil {
		t.Fatalf("starting: %v", err)
	}
	if err := store.Finished(ctx, id, nil, "9 question(s) measured"); err != nil {
		t.Fatalf("finishing: %v", err)
	}

	last, err := store.Last(ctx, name)
	if err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if last.Outcome != job.OK {
		t.Errorf("a run that returned no error is %q", last.Outcome)
	}
	if last.FinishedAt == nil {
		t.Error("it has no end")
	}
	if last.Detail != "9 question(s) measured" {
		t.Errorf("what it said about itself is %q", last.Detail)
	}
	if last.Version != "v1.2.3" {
		t.Errorf("which build ran is %q — 'it started failing after a deploy' is "+
			"unanswerable without it", last.Version)
	}
}

// THE ERROR DECIDES THE OUTCOME, so a call site cannot record `ok` beside a
// failure — which is the way a table of outcomes ends up disagreeing with what
// happened.
func TestARunThatFailedCannotBeRecordedAsFine(t *testing.T) {
	store := job.NewStore(testPool(t))
	ctx := context.Background()
	name := aJob(t)

	id, err := store.Started(ctx, name, "v1")
	if err != nil {
		t.Fatal(err)
	}
	// The caller passes a detail as if all were well; the error is what counts.
	if err := store.Finished(ctx, id, errors.New("the stream is not there"),
		"7 question(s) measured"); err != nil {
		t.Fatalf("finishing: %v", err)
	}

	last, err := store.Last(ctx, name)
	if err != nil {
		t.Fatal(err)
	}
	if last.Outcome != job.Failed {
		t.Errorf("a run that returned an error is %q", last.Outcome)
	}
	if !strings.Contains(last.Detail, "the stream is not there") {
		t.Errorf("what went wrong is not in the row: %q", last.Detail)
	}
	if !strings.Contains(last.Detail, "7 question(s)") {
		t.Errorf("what it managed before failing was dropped: %q", last.Detail)
	}
}

/*
THE ROW NOBODY WRITES.

A job killed between its two writes leaves this: a row that still says
`running`, hours later. It is the only trace such a run will ever leave, and
reading it as "busy" would make the most serious failure the platform can have
look like the healthiest state on the screen.
*/
func TestARunThatNeverFinishedIsAdriftAndNotBusy(t *testing.T) {
	pool := testPool(t)
	store := job.NewStore(pool)
	ctx := context.Background()
	name := aJob(t)

	id, err := store.Started(ctx, name, "v1")
	if err != nil {
		t.Fatal(err)
	}
	// Nothing closes it, and it is backdated to the morning after.
	if _, err := pool.Exec(ctx,
		`UPDATE job_runs SET started_at = now() - interval '9 hours' WHERE id = $1`,
		id); err != nil {
		t.Fatalf("backdating: %v", err)
	}

	last, err := store.Last(ctx, name)
	if err != nil {
		t.Fatal(err)
	}
	if last.Outcome != job.Running {
		t.Fatalf("a run nothing closed is %q", last.Outcome)
	}
	if !last.Adrift(time.Now()) {
		t.Error("a run open for nine hours is not adrift — the one failure with no other " +
			"trace reads as a healthy job")
	}

	// AND A RUN THAT REALLY IS BUSY IS NOT ADRIFT. Without this the check above
	// passes for a rule that simply calls everything unfinished dead.
	fresh, err := store.Started(ctx, name+"-busy", "v1")
	if err != nil {
		t.Fatal(err)
	}
	busy, err := store.Last(ctx, name+"-busy")
	if err != nil {
		t.Fatal(err)
	}
	if busy.ID != fresh {
		t.Fatalf("read back the wrong run")
	}
	if busy.Adrift(time.Now()) {
		t.Error("a run that started a moment ago is already adrift")
	}
}

// A FINISHED RUN IS A FACT ABOUT A NIGHT. The database refuses a second write
// to it, the same way it refuses one to a handed-in exam — a re-run is a new
// row, and a row that could be rewritten would make this table a record of
// whatever was written last.
func TestAFinishedRunCannotBeChanged(t *testing.T) {
	pool := testPool(t)
	store := job.NewStore(pool)
	ctx := context.Background()
	name := aJob(t)

	id, err := store.Started(ctx, name, "v1")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Finished(ctx, id, nil, "done"); err != nil {
		t.Fatal(err)
	}

	// Through the store: the second call says so rather than silently winning.
	if err := store.Finished(ctx, id, errors.New("second thoughts"), ""); err == nil {
		t.Error("a finished run was closed a second time")
	}

	// And underneath it, where somebody with psql would be.
	if _, err := pool.Exec(ctx,
		`UPDATE job_runs SET outcome = 'failed' WHERE id = $1`, id); err == nil {
		t.Error("a finished run was edited — the table then records whatever was written last")
	}
}

// A JOB THAT HAS NEVER RUN IS A STATE AND NOT A FAILURE. Before the first
// night that is every job there is, and it is exactly the state this platform
// was in for as long as nothing was scheduled.
func TestAJobThatHasNeverRunSaysSo(t *testing.T) {
	store := job.NewStore(testPool(t))

	if _, err := store.Last(context.Background(), aJob(t)); !errors.Is(err, job.ErrNoRuns) {
		t.Errorf("a job with no runs answered %v", err)
	}
}

// NEWEST FIRST, AND ONE JOB'S RUNS ARE ONE JOB'S. Both are a clause in the same
// query, and a missing one would show last night's failure under a job that is
// fine.
func TestTheRunsAreOneJobsAndNewestFirst(t *testing.T) {
	store := job.NewStore(testPool(t))
	ctx := context.Background()
	mine, theirs := aJob(t), aJob(t)+"-other"

	for _, detail := range []string{"first", "second", "third"} {
		id, err := store.Started(ctx, mine, "v1")
		if err != nil {
			t.Fatal(err)
		}
		if err := store.Finished(ctx, id, nil, detail); err != nil {
			t.Fatal(err)
		}
	}
	id, err := store.Started(ctx, theirs, "v1")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Finished(ctx, id, nil, "somebody else's"); err != nil {
		t.Fatal(err)
	}

	runs, err := store.Latest(ctx, mine, 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(runs) != 3 {
		t.Fatalf("three runs were recorded and %d came back", len(runs))
	}
	if runs[0].Detail != "third" {
		t.Errorf("the newest run is %q", runs[0].Detail)
	}
	for _, r := range runs {
		if r.Detail == "somebody else's" {
			t.Error("another job's run is in this job's history")
		}
	}
}

// WHAT A JOB SAYS ABOUT ITSELF MUST NEVER BE WHY ITS RUN GOES UNRECORDED. An
// error with a stack trace in it is trimmed rather than refused.
func TestATooLongDetailIsTrimmedAndNotRefused(t *testing.T) {
	store := job.NewStore(testPool(t))
	ctx := context.Background()
	name := aJob(t)

	id, err := store.Started(ctx, name, "v1")
	if err != nil {
		t.Fatal(err)
	}
	if err := store.Finished(ctx, id, nil, strings.Repeat("x", job.DetailLimit*3)); err != nil {
		t.Fatalf("a long detail refused the whole row: %v", err)
	}

	last, err := store.Last(ctx, name)
	if err != nil {
		t.Fatal(err)
	}
	if n := len([]rune(last.Detail)); n > job.DetailLimit {
		t.Errorf("the detail is %d characters and the limit is %d", n, job.DetailLimit)
	}
	if last.Outcome != job.OK {
		t.Errorf("the run is %q — the row was lost to its own sentence", last.Outcome)
	}
}
