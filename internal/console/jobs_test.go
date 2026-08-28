package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

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

	// What may be started, and whether this deployment can start anything —
	// the two states a laptop and a Cloud Run service are respectively in.
	startable []string
	noRunner  bool

	started []string
	refuse  error
	entries []recorded
	failLog bool
	mayNot  bool
}

func (f *jobsFake) handler() http.Handler {
	mux := http.NewServeMux()

	var start func(context.Context, string) error
	if !f.noRunner {
		start = func(_ context.Context, name string) error {
			if f.refuse != nil {
				return f.refuse
			}
			f.started = append(f.started, name)
			return nil
		}
	}

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
		Startable:   f.startable,
		Start:       start,
	},
		func(_ context.Context, _ uuid.UUID, _, action string,
			subject console.Subject, what console.Changed, _, _ string) error {
			if f.failLog {
				return fmt.Errorf("the audit is not writable")
			}
			f.entries = append(f.entries, recorded{action: action, subject: subject, what: what})
			return nil
		},
		func(context.Context, uuid.UUID) (string, string, error) {
			return "Grace Hopper", "grace@example.tld", nil
		},
		func(context.Context) (uuid.UUID, bool) { return uuid.New(), true },
		func(context.Context) bool { return !f.mayNot },
	).Routes(mux)
	return mux
}

func (f *jobsFake) run(t *testing.T, name string) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPost,
		"/console/api/v1/jobs/"+name+"/run", nil))

	var body map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &body)
	return rec.Code, body
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

/* ---------- starting one ---------- */

func aStartableJob() *jobsFake {
	return &jobsFake{
		names:     []string{"analyse"},
		startable: []string{"analyse"},
		runs: map[string][]console.Run{"analyse": {
			{Job: "analyse", Outcome: "failed", Detail: "the stream is not there"},
		}},
	}
}

// THE ROUND TRIP, AND WHAT IT LEAVES BEHIND. A run started by hand is
// indistinguishable in `job_runs` — the scheduler makes the same call — so the
// audit entry is the only record of who asked, which makes it part of the
// feature rather than a decoration on it.
func TestStartingAJobAsksForItAndSaysWhoAsked(t *testing.T) {
	f := aStartableJob()

	code, body := f.run(t, "analyse")
	if code != http.StatusAccepted {
		t.Fatalf("starting a job answered %d: %v", code, body)
	}
	if len(f.started) != 1 || f.started[0] != "analyse" {
		t.Fatalf("what was started is %v", f.started)
	}
	if s, _ := body["started"].(string); s == "" {
		t.Error("nothing said the run had only been ASKED for — a screen told 'started' " +
			"redraws, finds no new run, and looks broken")
	}

	if len(f.entries) != 1 {
		t.Fatalf("%d audit entries for one start", len(f.entries))
	}
	entry := f.entries[0]
	if entry.action != "job.started" {
		t.Errorf("the entry says %q", entry.action)
	}
	if entry.subject.Kind != "job" || entry.subject.ID != "analyse" {
		t.Errorf("the subject is %v", entry.subject)
	}
	if entry.what.Before != "failed" {
		t.Errorf("the entry says the job was %q before — the state somebody was reacting to "+
			"is what makes the entry readable later", entry.what.Before)
	}
}

/*
A JOB THIS CONSOLE MAY NOT START IS REFUSED BEFORE GOOGLE IS ASKED ANYTHING.

	This is the whole of the safety on this route. `schooling-migrate` and
	`schooling-load` live in the same project behind the same permission, one
	path parameter away, and a handler that passed the name through would be a
	general-purpose Cloud Run trigger wearing a console's clothes.
*/
func TestAJobOutsideTheClosedListIsNeverStarted(t *testing.T) {
	f := aStartableJob()

	code, _ := f.run(t, "migrate")
	if code != http.StatusNotFound {
		t.Fatalf("a job outside the list answered %d", code)
	}
	if len(f.started) != 0 {
		t.Errorf("it was started anyway: %v", f.started)
	}
	if len(f.entries) != 0 {
		t.Error("a refusal wrote an audit entry — the history then says somebody did " +
			"something they were stopped from doing")
	}
}

// A DEPLOYMENT THAT CANNOT START JOBS SAYS SO, and every laptop and CI runner
// is one. The screen draws no button in this state; this is what happens if
// something asks anyway.
func TestWhereNothingCanStartAJobTheRouteSaysSoRatherThanPretending(t *testing.T) {
	f := aStartableJob()
	f.noRunner = true

	code, _ := f.run(t, "analyse")
	if code != http.StatusNotImplemented {
		t.Fatalf("a deployment with no runner answered %d", code)
	}

	_, body := f.ask(t)
	list, _ := body["startable"].([]any)
	if len(list) != 0 {
		t.Errorf("it offered %v as startable with nothing able to start one", list)
	}

	/* AND IT SAYS WHY THERE IS NOTHING TO PRESS. This screen carried that
	   sentence for as long as no job could be started at all, and losing it
	   would leave somebody looking for a button to conclude it was forgotten. */
	if s, _ := body["nothing_to_press"].(string); s == "" {
		t.Error("nothing says why there is no button")
	}
}

// AND THE LIST IS THE SERVER'S. A screen holding its own copy keeps offering
// yesterday's, and the name it then sends is refused — the same rule the
// verdicts and the report reasons follow.
func TestWhatMayBeStartedTravelsWithTheAnswer(t *testing.T) {
	f := aStartableJob()

	_, body := f.ask(t)
	list, _ := body["startable"].([]any)
	if len(list) != 1 || list[0] != "analyse" {
		t.Errorf("the startable list came back as %v", list)
	}
	if s, _ := body["about_starting"].(string); s == "" {
		t.Error("nothing on the answer says what starting one means")
	}
}

/*
A RUN THAT IS ALREADY GOING IS NOT STARTED AGAIN.

	Two analyses at once are two sweeps, and a sweep WITHDRAWS a question — so
	the second writes a second audit entry for one withdrawal. The failure this
	actually catches is somebody pressing twice because nothing appeared to
	change, which is the ordinary way it would happen.
*/
func TestAJobAlreadyRunningIsNotStartedTwice(t *testing.T) {
	f := aStartableJob()
	f.runs["analyse"] = []console.Run{{
		Job: "analyse", Outcome: "running", StartedAt: time.Now().Add(-2 * time.Minute),
	}}

	code, _ := f.run(t, "analyse")
	if code != http.StatusConflict {
		t.Fatalf("a job already running answered %d", code)
	}
	if len(f.started) != 0 {
		t.Errorf("a second run was asked for anyway: %v", f.started)
	}
}

/*
AND AN ADRIFT RUN IS NOT A REASON TO REFUSE.

	Adrift is what a killed job leaves behind — a row that says `running` and
	will say it for ever, because nothing rewrites it. Treating that as "busy"
	would make a job unstartable until somebody edited the database by hand,
	which is the opposite of what a retry button is for: the run that never
	finished is precisely the one somebody is trying to start again.
*/
func TestARunThatIsAdriftDoesNotBlockAStart(t *testing.T) {
	f := aStartableJob()
	f.runs["analyse"] = []console.Run{{
		Job: "analyse", Outcome: "running", Adrift: true,
		StartedAt: time.Now().Add(-9 * time.Hour),
	}}

	code, body := f.run(t, "analyse")
	if code != http.StatusAccepted {
		t.Fatalf("an adrift run blocked a start: %d %v", code, body)
	}
	if len(f.entries) != 1 || f.entries[0].what.Before != "adrift — started and never finished" {
		t.Errorf("the entry does not say what it was reacting to: %v", f.entries)
	}
}

// A READ-ONLY ROLE OPENED THE DOOR AND DOES NOT PRESS THIS. It is the second
// rank the schools and the erase paths have, for the same reason: withdrawing
// questions from circulation is not a thing looking at a screen should do.
func TestAReadOnlyRoleMayLookAtJobsAndNotStartOne(t *testing.T) {
	f := aStartableJob()
	f.mayNot = true

	code, _ := f.run(t, "analyse")
	if code != http.StatusForbidden {
		t.Fatalf("a read-only role answered %d", code)
	}
	if len(f.started) != 0 {
		t.Errorf("it started one anyway: %v", f.started)
	}

	if code, _ := f.ask(t); code != http.StatusOK {
		t.Errorf("a read-only role could not READ the jobs screen: %d", code)
	}
}

// A START NOBODY COULD RECORD IS NOT MADE. The console's rule everywhere, and
// the one place it is cheap to get wrong: the run is the visible thing and the
// entry is the only record of who asked for it.
func TestAStartNobodyCouldRecordIsNotMade(t *testing.T) {
	f := aStartableJob()
	f.failLog = true

	code, _ := f.run(t, "analyse")
	if code != http.StatusServiceUnavailable {
		t.Fatalf("an unwritable audit answered %d", code)
	}
	if len(f.started) != 0 {
		t.Errorf("the job ran with nothing to say who asked: %v", f.started)
	}
}

// AND A START THAT WAS RECORDED AND THEN REFUSED SAYS SO PLAINLY, rather than
// reporting a run that was never asked for. It is the same trade the accent and
// the price handlers make, named in the same words.
func TestAStartThatWasRecordedAndThenRefusedSaysSo(t *testing.T) {
	f := aStartableJob()
	f.refuse = fmt.Errorf("run.jobs.run denied")

	code, body := f.run(t, "analyse")
	if code != http.StatusBadGateway {
		t.Fatalf("a refused start answered %d: %v", code, body)
	}
	if len(f.entries) != 1 {
		t.Errorf("the entry was not written before the attempt: %v", f.entries)
	}
}
