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

/* The funnel screen's half of the contract, against fakes.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether the arithmetic is
   right is `analysis`'s test, and whether the SQL counts the right rows is
   `event`'s against a real Postgres. What this file holds is the part in
   between, and it is almost entirely about ONE hazard: that the population a
   request asked for and the population the answer is about are the same one. */

type funnelFake struct {
	schools []console.School

	// What the seam was actually asked for, on the last call.
	askedFor string
	askedAt  time.Time
	fail     bool
}

func (f *funnelFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewUnderstandHandler(
		console.Schools{
			All: func(context.Context) ([]console.School, error) { return f.schools, nil },
		},
		func(_ context.Context, _ uuid.UUID, since time.Time,
			counting string) ([]console.Step, error) {

			f.askedFor, f.askedAt = counting, since
			if f.fail {
				return nil, fmt.Errorf("the stream is not there")
			}
			return []console.Step{
				{Label: "Arrived", People: 12, Measured: true},
				{Label: "Subscribed", Measured: false, Why: "there is no gateway yet"},
			}, nil
		},
	).Routes(mux)
	return mux
}

// `school_test.go` has an `aSchool` of its own and it returns that file's fake,
// so this one is named for what it is: the row, not the harness around it.
func oneSchool() console.School {
	return console.School{ID: uuid.New(), Slug: "code", Name: "Programming"}
}

func askFunnel(t *testing.T, f *funnelFake, school uuid.UUID, query string) (int, map[string]any) {
	t.Helper()
	r := httptest.NewRequest(http.MethodGet,
		"/console/api/v1/schools/"+school.String()+"/funnel"+query, nil)
	w := httptest.NewRecorder()
	f.handler().ServeHTTP(w, r)

	var body map[string]any
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, w.Body.String())
	}
	return w.Code, body
}

// THE DEFAULT IS REAL PEOPLE, and it is the default in the request rather than
// only in the SQL. A screen opened with no opinion is a screen about the
// platform's actual students (K-11).
func TestAskingNothingCountsRealPeople(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}}

	code, body := askFunnel(t, f, school.ID, "")
	if code != http.StatusOK {
		t.Fatalf("asking for a school's funnel answered %d: %v", code, body)
	}
	if f.askedFor != "real" {
		t.Errorf("a request with no population read %q", f.askedFor)
	}
	if body["counting"] != "real" {
		t.Errorf("the answer says it counted %v", body["counting"])
	}
	if body["banner"] != "" {
		t.Errorf("real people need no banner, and one came back: %v", body["banner"])
	}
}

// THE HAZARD THIS WHOLE FILE IS ABOUT. The word travels to the reader AND comes
// back on the answer, so a screen cannot draw one population under a heading
// naming another.
func TestThePopulationAskedForIsTheOneReadAndTheOneReportedBack(t *testing.T) {
	school := oneSchool()

	for _, who := range []string{"real", "seeded", "everybody"} {
		f := &funnelFake{schools: []console.School{school}}
		code, body := askFunnel(t, f, school.ID, "?counting="+who)
		if code != http.StatusOK {
			t.Fatalf("%q answered %d: %v", who, code, body)
		}
		if f.askedFor != who {
			t.Errorf("asked for %q and the seam was told %q", who, f.askedFor)
		}
		if body["counting"] != who {
			t.Errorf("asked for %q and the answer says %v", who, body["counting"])
		}

		// And the two that are not the truth say so on the answer, not on the
		// screen — a banner the interface holds is a banner that can be shown
		// over the wrong numbers.
		banner, _ := body["banner"].(string)
		if who == "real" && banner != "" {
			t.Errorf("real people came back with a banner: %q", banner)
		}
		if who != "real" && banner == "" {
			t.Errorf("%q came back with nothing saying the numbers are not about "+
				"real people", who)
		}
	}
}

// A WORD IT DOES NOT KNOW IS A REFUSAL AND NOT A QUIET FALLBACK.
//
// The stream answers `everbody` with real people, which is right for SQL and
// wrong for a screen: the chart would be real students under a switch reading
// "including the seeded population". Nothing may be read at all in that case.
func TestAMisspeltPopulationIsRefusedRatherThanAnswered(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}}

	code, body := askFunnel(t, f, school.ID, "?counting=everbody")
	if code != http.StatusBadRequest {
		t.Fatalf("a misspelt population answered %d: %v", code, body)
	}
	if f.askedFor != "" {
		t.Errorf("it was refused and the funnel was read anyway, as %q", f.askedFor)
	}
}

// The window is a whole number of days, and a negative one is somebody meaning
// something. Answering it with thirty days, or with everything, is a guess
// dressed as an answer.
func TestTheWindowIsDaysAndANegativeOneIsRefused(t *testing.T) {
	school := oneSchool()

	f := &funnelFake{schools: []console.School{school}}
	if code, body := askFunnel(t, f, school.ID, "?days=30"); code != http.StatusOK {
		t.Fatalf("thirty days answered %d: %v", code, body)
	}
	if f.askedAt.IsZero() {
		t.Error("`days=30` read since the beginning")
	}

	for _, bad := range []string{"?days=-30", "?days=soon", "?days=1.5"} {
		f := &funnelFake{schools: []console.School{school}}
		if code, body := askFunnel(t, f, school.ID, bad); code != http.StatusBadRequest {
			t.Errorf("%q answered %d: %v", bad, code, body)
		}
	}

	// Nothing and zero are the same question, and both mean everything.
	for _, all := range []string{"", "?days=0"} {
		f := &funnelFake{schools: []console.School{school}}
		if code, _ := askFunnel(t, f, school.ID, all); code != http.StatusOK {
			t.Errorf("%q answered %d", all, code)
		}
		if !f.askedAt.IsZero() {
			t.Errorf("%q read from %v rather than the beginning", all, f.askedAt)
		}
	}
}

// AN ID BELONGING TO NOBODY IS A 404 AND NOT EIGHT ZEROES, which would read as
// a school everybody left.
func TestASchoolThatDoesNotExistIsNotAnEmptyFunnel(t *testing.T) {
	f := &funnelFake{schools: []console.School{oneSchool()}}

	code, _ := askFunnel(t, f, uuid.New(), "")
	if code != http.StatusNotFound {
		t.Errorf("a school nobody has answered %d", code)
	}
	if f.askedFor != "" {
		t.Error("the funnel was read for a school that does not exist")
	}
}

// A step nothing emits keeps saying so all the way to the browser. Flattened to
// a zero on the way out it would report a missing feature as the worst drop-off
// on the screen.
func TestAnUnmeasuredStepStaysUnmeasuredInTheAnswer(t *testing.T) {
	school := oneSchool()
	f := &funnelFake{schools: []console.School{school}}

	code, body := askFunnel(t, f, school.ID, "")
	if code != http.StatusOK {
		t.Fatalf("answered %d", code)
	}

	steps, ok := body["steps"].([]any)
	if !ok || len(steps) != 2 {
		t.Fatalf("the answer carries %v", body["steps"])
	}
	last, _ := steps[1].(map[string]any)
	if last["measured"] != false {
		t.Errorf("an unmeasured step came back as %v", last["measured"])
	}
	if last["why"] == nil || last["why"] == "" {
		t.Error("an unmeasured step came back with nothing saying what is missing")
	}
}
