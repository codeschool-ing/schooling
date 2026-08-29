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

	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/codeschool-ing/schooling/internal/platform/setting"
	"github.com/google/uuid"
)

/* Every knob, at the console's own layer.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES — recorded before it
   happens, refused without a reason, refused below operator, and refused for a
   name nothing declares. Whether a row lands once in Postgres, whether a value
   outside the fence is ignored on the way out and what `was` means are
   `internal/platform/setting`'s tests, against a real database.

   THE 404 IS THE ONE WORTH THE FILE. This route takes a parameter's name in the
   path, which is the shape `writes.go` opens by refusing — a screen that edits
   any row of a table of names. What makes it not that is that the name is
   checked against a set closed in Go, and the check has to happen BEFORE the
   audit entry is written: an entry for a change that cannot happen is a history
   saying something was done that was not. */

type knobFake struct {
	now     []setting.Current
	entries []recorded

	refuse  bool
	failSet bool
	failLog bool
	failNow bool
	mayNot  bool
}

var errOutsideTheFence = errors.New("that is outside what this parameter allows")

// aKnob is a declaration shaped like the ones the modules make.
var aKnob = setting.Declared{
	Name:     "billing.instalments",
	Unit:     setting.Count,
	Least:    1,
	Most:     12,
	Fallback: 12,
	Why:      "how far a card sale may be split, which is a commercial position and not a fact",
}

func (f *knobFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewSettingsHandler(
		console.Knobs{
			Now: func(context.Context) ([]setting.Current, error) {
				if f.failNow {
					return nil, fmt.Errorf("the database is not there")
				}
				return f.now, nil
			},
			Set: func(_ context.Context, name string, value int) (int, error) {
				if f.refuse {
					return 0, errOutsideTheFence
				}
				if f.failSet {
					return 0, fmt.Errorf("the database is not there")
				}
				for i, one := range f.now {
					if one.Name != name {
						continue
					}
					was := one.Value
					f.now[i].Value, f.now[i].Set = value, true
					f.now[i].Since = time.Now()
					return was, nil
				}
				return 0, fmt.Errorf("%w: %q", setting.ErrUnknown, name)
			},
			Refused: func(err error) bool {
				return errors.Is(err, errOutsideTheFence) || errors.Is(err, setting.ErrUnknown)
			},
		},
		func(_ context.Context, actor uuid.UUID, label, action string,
			subject console.Subject, what console.Changed, why, _ string) error {

			if f.failLog {
				return fmt.Errorf("the audit is not writable")
			}
			f.entries = append(f.entries, recorded{
				action: action, actor: actor, label: label,
				subject: subject, what: what, why: why,
			})
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

// oneKnob is a fake holding a single declared parameter, unset, on its fallback.
func oneKnob() *knobFake {
	return &knobFake{now: []setting.Current{{Declared: aKnob, Value: aKnob.Fallback}}}
}

func (f *knobFake) set(t *testing.T, name, body string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPut,
		"/console/api/v1/settings/"+name, strings.NewReader(body)))
	return rec
}

func (f *knobFake) read(t *testing.T) []any {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/console/api/v1/settings", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("reading the parameters answered %d: %s", rec.Code, rec.Body.String())
	}
	var body struct {
		Settings []any `json:"settings"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v", err)
	}
	return body.Settings
}

/*
THE ARGUMENT AND THE FENCE TRAVEL WITH THE NUMBER.

`Why` is on the wire because that sentence is the entire cost of the knob
existing (K-13), and a screen showing a box and a number would be spending it
and throwing it away. The bounds are there so the form can say what the limit is
before somebody types rather than only after.
*/
func TestTheAnswerCarriesTheArgumentAndTheFence(t *testing.T) {
	found := oneKnob().read(t)
	if len(found) != 1 {
		t.Fatalf("%d parameters came back, wanted the one declared", len(found))
	}

	got, is := found[0].(map[string]any)
	if !is {
		t.Fatalf("a parameter came back as %T", found[0])
	}
	for _, field := range []string{"name", "unit", "least", "most", "fallback", "why",
		"value", "set"} {

		if _, there := got[field]; !there {
			t.Errorf("the answer has no %q, so the screen cannot draw it", field)
		}
	}
	if got["why"] != aKnob.Why {
		t.Errorf("the argument came back as %v", got["why"])
	}
	if got["set"] != false {
		t.Error("a parameter nobody has set came back as set, so the screen cannot tell " +
			"\"nobody has changed this\" from \"somebody set it back to what it was\"")
	}
}

/*
A NAME NOTHING DECLARES IS A 404, AND NOTHING IS RECORDED.

This is the whole difference between this route and the table `writes.go`
refuses. It is checked BEFORE the entry is written on purpose: an entry for a
change that cannot happen leaves the history saying something was done that was
not, which is the failure every write in this console is ordered to avoid.
*/
func TestANameNothingDeclaresIsRefusedBeforeAnythingIsRecorded(t *testing.T) {
	f := oneKnob()
	rec := f.set(t, "billing.somethingelse", `{"value":6,"reason":"trying it"}`)

	if rec.Code != http.StatusNotFound {
		t.Errorf("an undeclared name answered %d, wanted 404: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 0 {
		t.Errorf("%d entries were written for a change that cannot happen", len(f.entries))
	}
}

// AND THE CHANGE IS RECORDED BEFORE IT HAPPENS, with both sides as numbers.
func TestSettingOneIsRecordedFirstAndNamesBothSides(t *testing.T) {
	f := oneKnob()
	rec := f.set(t, aKnob.Name, `{"value":6,"reason":"the fee bands changed"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("setting it answered %d: %s", rec.Code, rec.Body.String())
	}

	if len(f.entries) != 1 {
		t.Fatalf("%d entries were written", len(f.entries))
	}
	entry := f.entries[0]
	if entry.action != "setting.changed" {
		t.Errorf("the entry names the action %q", entry.action)
	}
	if entry.subject.Kind != "platform" || entry.subject.ID != aKnob.Name {
		t.Errorf("the subject is %+v, wanted the platform named by the parameter", entry.subject)
	}
	/* THE FALLBACK IS THE `before`, not a blank. A parameter nobody has set is
	   answering the number the code shipped with, and that is what the platform
	   was actually doing — an entry reading "nothing → 6" would name the absence
	   of a row rather than the behaviour that changed. */
	if entry.what.Before != "12" || entry.what.After != "6" {
		t.Errorf("the entry says %v → %v, wanted 12 → 6", entry.what.Before, entry.what.After)
	}
	if entry.why != "the fee bands changed" {
		t.Errorf("the reason came through as %q", entry.why)
	}
}

// THE REASON IS REQUIRED, and nothing is recorded without it — a parameter is
// replaced rather than appended, so this log is the whole history of it.
func TestItWillNotMoveWithoutAReason(t *testing.T) {
	f := oneKnob()
	rec := f.set(t, aKnob.Name, `{"value":6}`)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("no reason answered %d, wanted 400", rec.Code)
	}
	if len(f.entries) != 0 {
		t.Errorf("%d entries were written for a change that was refused", len(f.entries))
	}
	if f.now[0].Set {
		t.Error("the value moved without a reason")
	}
}

/*
AND A MISSING VALUE IS NOT A ZERO.

`value` is a pointer for exactly this: an absent field decoding to 0 would be
indistinguishable from somebody asking for zero, and for a parameter whose
`Least` is 1 the two produce different errors from different places. It is
refused here, with the sentence saying there is no way to unset one.
*/
func TestAnAbsentValueIsNotAZero(t *testing.T) {
	f := oneKnob()
	rec := f.set(t, aKnob.Name, `{"reason":"trying it"}`)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("no value answered %d, wanted 400", rec.Code)
	}
	if len(f.entries) != 0 {
		t.Errorf("%d entries were written", len(f.entries))
	}
}

// A READ-ONLY ROLE MAY LOOK AND NOT SET, like every other parameter here. The
// screen hides the form; this is the half that matters.
func TestAReadOnlyRoleCannotMoveAnything(t *testing.T) {
	f := oneKnob()
	f.mayNot = true

	rec := f.set(t, aKnob.Name, `{"value":6,"reason":"the fee bands changed"}`)
	if rec.Code != http.StatusForbidden {
		t.Errorf("a read-only role answered %d, wanted 403", rec.Code)
	}
	if len(f.entries) != 0 {
		t.Errorf("%d entries were written for a refused change", len(f.entries))
	}
}

// A VALUE THE DECLARATION REFUSES IS THE CALLER'S TO FIX, so it is a 400 with
// the store's own sentence rather than a 503 that reads as our fault.
func TestAValueOutsideTheFenceComesBackAsTheCallersToFix(t *testing.T) {
	f := oneKnob()
	f.refuse = true

	rec := f.set(t, aKnob.Name, `{"value":40,"reason":"trying it"}`)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("a refused value answered %d, wanted 400: %s", rec.Code, rec.Body.String())
	}
}

/*
AND A WRITE THAT FAILS AFTER THE ENTRY SAYS SO OUT LOUD.

The order is deliberate everywhere in this console: record, then act. The cost
is this window, and the only honest thing to do inside it is to say that the
history now claims something that did not happen — a 503 with a shrug would
leave somebody to find it themselves, months later, in a log.
*/
func TestAWriteThatFailsAfterTheEntryIsNamedAsADefect(t *testing.T) {
	f := oneKnob()
	f.failSet = true

	rec := f.set(t, aKnob.Name, `{"value":6,"reason":"the fee bands changed"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("a failed write answered %d, wanted 503", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "defect") {
		t.Errorf("the answer does not say the history is now wrong: %s", rec.Body.String())
	}
	if len(f.entries) != 1 {
		t.Errorf("%d entries — the point of this case is that one was already written",
			len(f.entries))
	}
}

// AND AN AUDIT THAT CANNOT BE WRITTEN STOPS THE CHANGE. K-01 is not a log line
// beside the act; it is the thing that has to succeed first.
func TestNothingMovesWhenTheAuditCannotBeWritten(t *testing.T) {
	f := oneKnob()
	f.failLog = true

	rec := f.set(t, aKnob.Name, `{"value":6,"reason":"the fee bands changed"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("an unwritable audit answered %d, wanted 503", rec.Code)
	}
	if f.now[0].Set {
		t.Error("the value moved with nothing recording that it had")
	}
}

/*
AND A READ THAT FAILED IS NOT A REASON TO WRITE ANYWAY.

`set` reads the current value first, so the entry can name both sides and so an
undeclared name is caught before anything is recorded. When that read fails the
handler knows neither — it stops, rather than recording a `before` it guessed at
or skipping the check that makes this route not a table of names.
*/
func TestAFailedReadStopsTheWriteRatherThanGuessing(t *testing.T) {
	f := oneKnob()
	f.failNow = true

	rec := f.set(t, aKnob.Name, `{"value":6,"reason":"the fee bands changed"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("a failed read answered %d, wanted 503", rec.Code)
	}
	if len(f.entries) != 0 {
		t.Errorf("%d entries were written from a read that failed", len(f.entries))
	}
}
