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

func askToday(t *testing.T, today console.Today) (int, map[string]any) {
	t.Helper()
	mux := http.NewServeMux()
	console.NewTodayHandler(today).Routes(mux)

	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/console/api/v1/today", nil))

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, rec.Body.String())
	}
	return rec.Code, body
}

func counts(t *testing.T, body map[string]any) map[string]float64 {
	t.Helper()
	out := map[string]float64{}
	list, _ := body["findings"].([]any)
	for _, one := range list {
		f, ok := one.(map[string]any)
		if !ok {
			t.Fatalf("a finding is not an object: %#v", one)
		}
		kind, _ := f["kind"].(string)
		if kind == "" {
			t.Fatalf("a finding came back with no `kind`: %#v — the screen keys every "+
				"sentence off that word and draws nothing without it", f)
		}
		n, ok := f["count"].(float64)
		if !ok {
			t.Fatalf("%q came back with no `count`: %#v", kind, f)
		}
		out[kind] = n
	}
	return out
}

/*
THE ANSWER IS SPELLED THE WAY THE SCREEN READS IT.

	This is the regression test for a defect that shipped to a browser and was
	found by opening it: `Finding` was marshalled straight to JSON with no tags,
	so the fields went out as `Kind`, `Count` and `Where` while the screen read
	`kind` and `count`. Every row drew "undefined — undefined".

	IT RENDERED PERFECTLY AND SAID NOTHING, which is the failure this console is
	written against and the reason a body type with tags is the shape every
	other answer here already uses. A Go test asserting on the struct would have
	passed; this asserts on the bytes.
*/
func TestTheFindingsAreSpelledTheWayTheScreenReadsThem(t *testing.T) {
	code, body := askToday(t, console.Today{
		Condemned: func(context.Context) (int, error) { return 2, nil },
	})
	if code != http.StatusOK {
		t.Fatalf("it answered %d", code)
	}

	list, ok := body["findings"].([]any)
	if !ok || len(list) != 1 {
		t.Fatalf("findings came back as %#v", body["findings"])
	}
	one, _ := list[0].(map[string]any)

	for _, name := range []string{"kind", "count", "where"} {
		if _, there := one[name]; !there {
			t.Errorf("the finding has no %q — the screen reads that name and draws "+
				"`undefined` without it. It came back as %#v", name, one)
		}
	}
}

// A FINDING THAT IS NOT TRUE IS ABSENT, not a zero. A column of zeroes is a
// wall of things to read on a screen whose whole purpose is that it is empty
// when nothing is wrong.
func TestNothingWrongIsAnEmptyListAndNotZeroes(t *testing.T) {
	_, body := askToday(t, console.Today{
		Condemned: func(context.Context) (int, error) { return 0, nil },
		Waiting:   func(context.Context) (int, error) { return 0, nil },
		Operators: func(context.Context) ([]console.Operator, error) {
			return []console.Operator{whole()}, nil
		},
	})

	list, ok := body["findings"].([]any)
	if !ok {
		t.Fatalf("findings came back as %#v, and an empty list is not nil", body["findings"])
	}
	if len(list) != 0 {
		t.Errorf("a platform with nothing wrong produced %d findings: %#v", len(list), list)
	}
	if said, _ := body["nothing_to_do"].(string); said == "" {
		t.Error("an empty screen came back with nothing saying why it is empty, and " +
			"`nothing is wrong` and `this failed to load` look identical")
	}
}

/*
A READER THAT FAILS IS A FINDING AND NOT A DEAD SCREEN.

	Four questions are asked and any can fail. Refusing the whole page because
	one table was unreachable would hide the three findings that did arrive — on
	the one screen whose job is to say what is wrong. So the failure is carried
	as its own line, because a missing line and a line that is zero are
	different facts.
*/
func TestAReaderThatFailsBecomesItsOwnFinding(t *testing.T) {
	code, body := askToday(t, console.Today{
		Condemned: func(context.Context) (int, error) { return 3, nil },
		Waiting: func(context.Context) (int, error) {
			return 0, fmt.Errorf("the reports table is not there")
		},
	})
	if code != http.StatusOK {
		t.Fatalf("one unreadable finding answered %d and took the whole screen with it", code)
	}

	got := counts(t, body)
	if got["questions-still-asked"] != 3 {
		t.Errorf("the finding that DID arrive is %v, want 3 — a reader that failed "+
			"hid the ones that worked", got["questions-still-asked"])
	}
	if got["could-not-be-checked"] != 1 {
		t.Errorf("the failure came back as %v, want one — a screen that silently "+
			"reported nothing would read as a platform with nothing wrong",
			got["could-not-be-checked"])
	}
}

// SOMEBODY WHO LEFT IS NOT A FINDING. A revoked role has no access to review,
// and counting it would put a permanent number on this screen that no action
// can ever clear — which is how a screen teaches people to ignore it.
func TestARevokedRoleIsNotSomethingToAttendTo(t *testing.T) {
	gone := time.Now().UTC()
	left := whole()
	left.RevokedAt = &gone
	left.SecondFactor = false
	left.LastOpenedConsole = nil

	_, body := askToday(t, console.Today{
		Operators: func(context.Context) ([]console.Operator, error) {
			return []console.Operator{left}, nil
		},
	})

	got := counts(t, body)
	if got["roles-without-a-second-factor"] != 0 || got["roles-never-used"] != 0 {
		t.Errorf("somebody who left produced findings: %v", got)
	}
}

// THE TWO ROSTER FINDINGS ARE FACTS AND NOT THRESHOLDS. A role with no second
// factor opens nothing; a role never used is access nobody is missing. Neither
// needs a number to decide it, which is what keeps this screen free of a bar
// somebody has to know about (K-16).
func TestTheRosterFindingsAreCounted(t *testing.T) {
	noFactor := whole()
	noFactor.SecondFactor = false

	unused := whole()
	unused.LastOpenedConsole = nil

	_, body := askToday(t, console.Today{
		Operators: func(context.Context) ([]console.Operator, error) {
			return []console.Operator{whole(), noFactor, unused}, nil
		},
	})

	got := counts(t, body)
	if got["roles-without-a-second-factor"] != 1 {
		t.Errorf("roles without a second factor came back %v, want 1", got)
	}
	if got["roles-never-used"] != 1 {
		t.Errorf("roles never used came back %v, want 1", got)
	}
}

/*
THE LAST RUN DECIDES, AND NOT THE HISTORY.

	"Did it work last night" is a question about the most recent attempt: a job
	that failed on Tuesday and has run every night since is a job that is fine,
	and a screen counting failures would keep reporting Tuesday for ever.
*/
func TestOnlyTheLastRunOfAJobIsAFinding(t *testing.T) {
	_, body := askToday(t, console.Today{
		Jobs: console.Jobs{
			Names: func(context.Context) ([]string, error) { return []string{"analyse"}, nil },
			Latest: func(_ context.Context, _ string, _ int) ([]console.Run, error) {
				// Newest first, and the newest one worked.
				return []console.Run{
					{Job: "analyse", Outcome: "ok"},
					{Job: "analyse", Outcome: "failed"},
				}, nil
			},
		},
	})

	if got := counts(t, body)["jobs-that-failed"]; got != 0 {
		t.Errorf("a job whose last run worked came back as %v failures — an older "+
			"failure would be reported for ever", got)
	}
}

// AND A JOB THAT CAN BE STARTED AND HAS NEVER RUN IS A FINDING. `Names` reads
// what has recorded a run, so a job that never has does not appear there at
// all: either it was just deployed or the scheduler has never fired, and both
// want a person.
func TestAJobThatHasNeverRunIsAFinding(t *testing.T) {
	_, body := askToday(t, console.Today{
		Jobs: console.Jobs{
			Names:     func(context.Context) ([]string, error) { return []string{"analyse"}, nil },
			Latest:    func(_ context.Context, _ string, _ int) ([]console.Run, error) { return nil, nil },
			Startable: []string{"analyse", "settle"},
		},
	})

	if got := counts(t, body)["jobs-that-never-ran"]; got != 1 {
		t.Errorf("a startable job with no runs came back as %v, want 1", got)
	}
}

// whole is somebody with a role, a second factor and a console they have opened
// — the row that is not a finding.
func whole() console.Operator {
	seen := time.Now().UTC()
	return console.Operator{
		AccountID: uuid.New(), Name: "Somebody", Email: "somebody@example.tld",
		Role: "operator", GrantedAt: seen,
		SecondFactor: true, LastOpenedConsole: &seen,
	}
}
