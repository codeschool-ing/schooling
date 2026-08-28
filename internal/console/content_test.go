package console_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The reported-content queue, against fakes.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether the row is written
   is `report`'s test against a real Postgres. What this file holds is the four
   things that go wrong at this layer and are invisible from either side of it:
   that the queue names nobody, that a decision nobody could record is a
   decision that did not happen, that a read-only role cannot answer a student,
   and that two operators in the queue at once do not both get to decide. */

var errRefused = errors.New("refused")
var errSettled = errors.New("already settled")
var errGone = errors.New("not there")

type queueFake struct {
	schools []console.School
	rows    []console.Report
	entries []recorded

	settled  []string
	failLog  bool
	failOpen bool

	// What the store answers when a settle is attempted.
	answer error

	mayNot bool
}

func (f *queueFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewContentHandler(
		console.Schools{
			All: func(context.Context) ([]console.School, error) { return f.schools, nil },
		},
		console.Reports{
			Open: func(context.Context, uuid.UUID) ([]console.Report, error) {
				if f.failOpen {
					return nil, fmt.Errorf("the database is not there")
				}
				return f.rows, nil
			},
			About: func(_ context.Context, id uuid.UUID) (console.Report, uuid.UUID, error) {
				for _, one := range f.rows {
					if one.ID == id {
						return one, f.schools[0].ID, nil
					}
				}
				return console.Report{}, uuid.Nil, errGone
			},
			Settle: func(_ context.Context, _, _ uuid.UUID, verdict string) error {
				if f.answer != nil {
					return f.answer
				}
				f.settled = append(f.settled, verdict)
				return nil
			},
			Verdicts:       []string{"fixed", "no-change", "noted"},
			Refused:        func(err error) bool { return errors.Is(err, errRefused) },
			AlreadySettled: func(err error) bool { return errors.Is(err, errSettled) },
			NotThere:       func(err error) bool { return errors.Is(err, errGone) },
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

func aQueue() *queueFake {
	school := console.School{
		ID:   uuid.MustParse("55555555-5555-4555-8555-555555555555"),
		Slug: "code", Name: "Programming",
	}
	return &queueFake{
		schools: []console.School{school},
		rows: []console.Report{{
			ID:        uuid.MustParse("66666666-6666-4666-8666-666666666666"),
			CourseID:  "web-fundamentals",
			LessonID:  "selectors",
			SectionID: "specificity",
			Reason:    "answer",
			Note:      "the key says B and the working shows C",
			// Old enough that a screen has something to say about the wait.
			ReportedAt: time.Now().Add(-72 * time.Hour),
		}},
	}
}

func (f *queueFake) queue(t *testing.T) (int, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/console/api/v1/schools/"+f.schools[0].ID.String()+"/reports", nil))

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, rec.Body.String())
	}
	return rec.Code, body
}

func (f *queueFake) settle(t *testing.T, id, verdict string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPost,
		"/console/api/v1/reports/"+id+"/settle",
		strings.NewReader(`{"verdict":"`+verdict+`"}`)))
	return rec
}

/*
K-22 AT THE ONE PLACE IT IS EASIEST TO BREAK BY BEING HELPFUL.

A person is found by an exact address and never listed. A queue of complaints
naming who made each one is a list of people to browse, and it is the obvious
thing to add the first time somebody asks "who reported this". The type has no
field for it — this is the check that the JSON has not grown one either.
*/
func TestTheQueueNamesNobody(t *testing.T) {
	f := aQueue()

	code, body := f.queue(t)
	if code != http.StatusOK {
		t.Fatalf("reading the queue answered %d: %v", code, body)
	}

	/* THE ROWS AND NOT THE WHOLE ANSWER. The answer also carries the sentence
	   SAYING that a report is shown without its reporter, and a scan over the
	   body would fail on the explanation of the rule it is checking. What must
	   contain nothing about a person is the data. */
	rows, _ := body["reports"].([]any)
	data, err := json.Marshal(rows)
	if err != nil {
		t.Fatal(err)
	}
	for _, word := range []string{"account", "email", "@", "reporter", "reported_by"} {
		if strings.Contains(string(data), word) {
			t.Errorf("a report carries %q, and it is shown without its reporter "+
				"(K-22): %s", word, data)
		}
	}

	if len(rows) != 1 {
		t.Fatalf("one report is open and %d came back", len(rows))
	}
	one, _ := rows[0].(map[string]any)
	if one["note"] != "the key says B and the working shows C" {
		t.Errorf("the words the student wrote did not survive: %v", one["note"])
	}
}

// THE VERDICTS COME FROM THE STORE, so the screen offers what will be accepted
// rather than its own copy of the list — the same rule as a threshold.
func TestTheQueueCarriesTheVerdictsItWillAccept(t *testing.T) {
	f := aQueue()
	_, body := f.queue(t)

	got, _ := body["verdicts"].([]any)
	if len(got) != 3 {
		t.Fatalf("three verdicts exist and %d came back: %v", len(got), body["verdicts"])
	}
	if got[0] != "fixed" {
		t.Errorf("the first verdict came back as %v", got[0])
	}
}

/*
THE ENTRY IS WRITTEN FIRST, AND A FAILURE TO WRITE IT IS A REFUSAL.

Here that is stronger than the usual rule. The report itself is deleted when the
person who wrote it is erased, so the audit entry is the ONLY lasting record
that a section was ever complained about — a settle that wrote the row and then
failed to record it would erase the complaint and keep no trace of the decision.
*/
func TestADecisionNobodyCouldRecordIsNotMade(t *testing.T) {
	f := aQueue()
	f.failLog = true

	rec := f.settle(t, f.rows[0].ID.String(), "fixed")
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("a settle whose entry could not be written answered %d: %s",
			rec.Code, rec.Body.String())
	}
	if len(f.settled) != 0 {
		t.Errorf("the report was settled anyway: %v", f.settled)
	}
}

// AND THE ENTRY NAMES THE SECTION RATHER THAN A UUID. An audit line reading
// "settled a report" is a line nobody can use in the conversation it exists for.
func TestTheEntryNamesWhatWasDecidedAndAboutWhat(t *testing.T) {
	f := aQueue()

	rec := f.settle(t, f.rows[0].ID.String(), "fixed")
	if rec.Code != http.StatusOK {
		t.Fatalf("settling answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 1 {
		t.Fatalf("one entry was expected and %d were written", len(f.entries))
	}

	e := f.entries[0]
	if e.action != "content.report.settled" {
		t.Errorf("the entry says the action was %q", e.action)
	}
	if !strings.Contains(e.subject.ID, "web-fundamentals") ||
		!strings.Contains(e.subject.ID, "specificity") {
		t.Errorf("the subject does not name the section: %q", e.subject.ID)
	}
	before, after := fmt.Sprint(e.what.Before), fmt.Sprint(e.what.After)
	if !strings.Contains(before, "answer") {
		t.Errorf("the entry does not say what was reported: %q", before)
	}
	if !strings.Contains(after, "fixed") {
		t.Errorf("the entry does not say what was decided: %q", after)
	}
}

// ANSWERING A STUDENT IS NOT A THING A READ-ONLY ROLE DOES. Read-only opened
// the door so that a console nobody can look at is not a console nobody checks;
// it does not carry a decision somebody else is waiting on.
func TestReadOnlyCannotSettleAReport(t *testing.T) {
	f := aQueue()
	f.mayNot = true

	rec := f.settle(t, f.rows[0].ID.String(), "fixed")
	if rec.Code != http.StatusForbidden {
		t.Fatalf("a read-only settle answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 0 {
		t.Errorf("a refused settle wrote %d audit entries", len(f.entries))
	}
}

// TWO OPERATORS IN THE QUEUE AT ONCE IS THE ORDINARY WAY THIS HAPPENS. The
// first decision stands, and the second is told so — rather than being answered
// with the failure that means the database is down.
func TestASecondDecisionIsRefusedAndSaysWhy(t *testing.T) {
	f := aQueue()
	f.answer = errSettled

	rec := f.settle(t, f.rows[0].ID.String(), "fixed")
	if rec.Code != http.StatusConflict {
		t.Fatalf("settling one somebody else had settled answered %d: %s",
			rec.Code, rec.Body.String())
	}
}

// A REPORT THAT IS NOT THERE IS A 404 AND NOT AN OUTAGE, and it is decided
// before anything is written — an audit entry about a report nobody has is an
// entry that makes the history wrong in the direction nobody checks.
func TestSettlingAReportThatIsNotThereRecordsNothing(t *testing.T) {
	f := aQueue()

	rec := f.settle(t, uuid.New().String(), "fixed")
	if rec.Code != http.StatusNotFound {
		t.Fatalf("settling a report nobody has answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 0 {
		t.Errorf("it wrote %d audit entries about a report that does not exist", len(f.entries))
	}
}

// A READ THAT FAILED IS NOT AN EMPTY QUEUE. Nothing to answer is the state this
// screen is meant to be in most of the time, and it looks exactly like a
// database that did not reply.
func TestAQueueReadThatFailedIsNotAnEmptyQueue(t *testing.T) {
	f := aQueue()
	f.failOpen = true

	code, body := f.queue(t)
	if code != http.StatusServiceUnavailable {
		t.Fatalf("a read that failed answered %d: %v", code, body)
	}
}

/*
A VERDICT THAT IS NOT A WORD WRITES NOTHING AT ALL.

The rule in this package is record first, because a thing done with nobody
accountable for it is worse than an entry for a thing that then failed. This is
the case that rule does not cover: a nonsense verdict cannot succeed, so
recording it first only puts "settled as banana" into a history that never
erases. The first version of this handler did exactly that.
*/
func TestANonsenseVerdictIsRefusedBeforeItIsRecorded(t *testing.T) {
	f := aQueue()

	rec := f.settle(t, f.rows[0].ID.String(), "banana")
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("a verdict that is not a word answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 0 {
		t.Errorf("it wrote %d audit entries about a decision that was refused", len(f.entries))
	}
	if len(f.settled) != 0 {
		t.Errorf("it settled the report anyway: %v", f.settled)
	}
}
