package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The jobs screen's half of the contract, against a fake.

   Whether the row is written is `job`'s test against a real Postgres. What this
   file holds is the two things the console decides: that a job which has never
   run is a sentence rather than an empty page, and that the span a row was
   judged against travels with the judgement. */

type jobsFake struct {
	names []string
	runs  map[string][]console.Run
	fail  bool
}

func (f *jobsFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewJobsHandler(console.Jobs{
		Names: func(context.Context) ([]string, error) {
			if f.fail {
				return nil, fmt.Errorf("the database is not there")
			}
			return f.names, nil
		},
		Latest: func(_ context.Context, name string, _ int) ([]console.Run, error) {
			return f.runs[name], nil
		},
		AdriftAfter: time.Hour,
	}).Routes(mux)
	return mux
}

func (f *jobsFake) ask(t *testing.T) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/console/api/v1/jobs", nil))

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, rec.Body.String())
	}
	return rec.Code, body
}

/*
NOTHING HAS RUN IS AN ANSWER, AND IT IS THE ONE PRODUCTION WAS GIVING.

For as long as nothing was scheduled, this is the state the platform was in —
and a screen that drew nothing for it would look exactly like a screen that
failed to load. The sentence comes from the server because it is a statement
about the system rather than about a page.
*/
func TestAPlatformWhereNothingHasRunSaysSo(t *testing.T) {
	f := &jobsFake{}

	code, body := f.ask(t)
	if code != http.StatusOK {
		t.Fatalf("asking answered %d: %v", code, body)
	}
	jobs, _ := body["jobs"].([]any)
	if len(jobs) != 0 {
		t.Fatalf("nothing has run and %d jobs came back", len(jobs))
	}
	if s, _ := body["nothing_yet"].(string); s == "" {
		t.Error("an empty screen with nothing to say is a screen that failed to load")
	}
}

// THE THRESHOLD TRAVELS WITH THE JUDGEMENT (K-16). `adrift` is a verdict, and a
// screen showing one without the span it was judged against keeps saying the
// old span after it moves.
func TestTheAdriftSpanComesBackWithTheRuns(t *testing.T) {
	started := time.Now().Add(-9 * time.Hour)
	f := &jobsFake{
		names: []string{"analyse"},
		runs: map[string][]console.Run{"analyse": {{
			Job: "analyse", Version: "v1", StartedAt: started,
			Outcome: "running", Adrift: true,
		}}},
	}

	_, body := f.ask(t)
	if body["adrift_after_seconds"] != float64(3600) {
		t.Errorf("the span came back as %v", body["adrift_after_seconds"])
	}

	jobs, _ := body["jobs"].([]any)
	one, _ := jobs[0].(map[string]any)
	runs, _ := one["runs"].([]any)
	row, _ := runs[0].(map[string]any)
	if row["adrift"] != true {
		t.Errorf("a run open for nine hours came back as %v", row["adrift"])
	}
	if row["finished_at"] != nil {
		t.Errorf("a run nothing closed has an end: %v", row["finished_at"])
	}
}

// THE OUTCOME IS PASSED THROUGH AND NOT TRANSLATED, so a fourth word would
// arrive on the screen as itself rather than being folded into one of three.
func TestTheOutcomeIsTheStoresOwnWord(t *testing.T) {
	f := &jobsFake{
		names: []string{"analyse"},
		runs: map[string][]console.Run{"analyse": {
			{Job: "analyse", Outcome: "failed", Detail: "the stream is not there"},
		}},
	}

	_, body := f.ask(t)
	jobs, _ := body["jobs"].([]any)
	one, _ := jobs[0].(map[string]any)
	runs, _ := one["runs"].([]any)
	row, _ := runs[0].(map[string]any)

	if row["outcome"] != "failed" {
		t.Errorf("the outcome came back as %v", row["outcome"])
	}
	if row["detail"] != "the stream is not there" {
		t.Errorf("what went wrong did not survive: %v", row["detail"])
	}
}

// A READ THAT FAILED IS NOT A PLATFORM WITH NO JOBS, which is the same shape as
// every other screen here and matters more on this one: the whole point of it
// is to distinguish "nothing ran" from "nothing answered".
func TestAJobsReadThatFailedIsNotAnIdlePlatform(t *testing.T) {
	f := &jobsFake{fail: true}

	code, body := f.ask(t)
	if code != http.StatusServiceUnavailable {
		t.Fatalf("a read that failed answered %d: %v", code, body)
	}
}
