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
	"github.com/google/uuid"
)

/* Where a student writes to use the seven days, at the console's own layer.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES: that the change is recorded
   before it happens, that it will not happen without a reason, that a read-only
   role cannot make it, and that the screen is told which of the two sources is
   answering. Whether the row lands in one place in Postgres is `billing`'s test
   against a real database.

   THE THIRD STATE IS THE ONE WORTH THE FILE. A row and no row are ordinary; no
   row AND no deployment variable is a platform publishing a right with no way
   to use it, and it has to be distinguishable from both. */

type supportFake struct {
	row      console.Contact
	fallback string
	entries  []recorded

	refuse  bool
	failSet bool
	failLog bool
	mayNot  bool
}

var errNotAnAddress = errors.New("that is not an address somebody could write to")

func (f *supportFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewSupportHandler(
		console.Support{
			Now: func(context.Context) (console.Contact, error) { return f.row, nil },
			Set: func(_ context.Context, email string) (console.Contact, error) {
				if f.refuse {
					return console.Contact{}, errNotAnAddress
				}
				if f.failSet {
					return console.Contact{}, fmt.Errorf("the database is not there")
				}
				was := f.row
				f.row = console.Contact{Email: email, Since: time.Now()}
				return was, nil
			},
			Refused: func(err error) bool { return errors.Is(err, errNotAnAddress) },
		},
		console.Fallback(f.fallback),
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

func (f *supportFake) set(t *testing.T, body string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPut,
		"/console/api/v1/support/contact", strings.NewReader(body)))
	return rec
}

func (f *supportFake) read(t *testing.T) map[string]any {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/console/api/v1/support/contact", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("reading the contact answered %d: %s", rec.Code, rec.Body.String())
	}
	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v", err)
	}
	return body
}

/*
THE THREE STATES ARE THREE DIFFERENT ANSWERS, and the screen draws a different
sentence for each. Collapsing them would make the two that matter invisible:
"the deployment's variable is answering" reads identically to "somebody set this
here" if all you send is the resolved address, and the difference is whether
this console is what decides it.
*/
func TestTheAnswerSaysWhichSourceIsAnswering(t *testing.T) {
	t.Run("a row set here", func(t *testing.T) {
		f := &supportFake{
			row:      console.Contact{Email: "help@example.tld", Since: time.Now()},
			fallback: "deployed@example.tld",
		}
		body := f.read(t)
		if body["email"] != "help@example.tld" {
			t.Errorf("the row is %v", body["email"])
		}
		if body["published"] != "help@example.tld" {
			t.Errorf("the row did not win over the fallback: %v", body["published"])
		}
		if _, has := body["since"]; !has {
			t.Error("a row that was set here has a date and the answer dropped it")
		}
	})

	t.Run("no row, and the deployment answering", func(t *testing.T) {
		f := &supportFake{fallback: "deployed@example.tld"}
		body := f.read(t)
		if body["email"] != "" {
			t.Errorf("a row was invented: %v", body["email"])
		}
		if body["published"] != "deployed@example.tld" {
			t.Errorf("the fallback did not reach the screen: %v", body["published"])
		}
		// NO DATE, because nothing was ever set here. A `since` on this state
		// would date the deployment's variable, which nothing knows.
		if _, has := body["since"]; has {
			t.Errorf("a date was invented for a value nobody set here: %v", body["since"])
		}
	})

	t.Run("nowhere to write at all", func(t *testing.T) {
		f := &supportFake{}
		body := f.read(t)
		if body["published"] != "" {
			t.Errorf("an address was invented: %v", body["published"])
		}
	})
}

/*
RECORDED BEFORE IT HAPPENS, which is K-01 and is the rule every write in this
package follows. The order is what makes the log trustworthy: a change that
could not be recorded did not happen.
*/
func TestAnAddressNobodyCouldRecordIsNotSet(t *testing.T) {
	f := &supportFake{failLog: true, row: console.Contact{Email: "old@example.tld"}}

	rec := f.set(t, `{"email":"new@example.tld","reason":"the old box is closed"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("an unrecordable change answered %d: %s", rec.Code, rec.Body.String())
	}
	if f.row.Email != "old@example.tld" {
		t.Errorf("it was set anyway, and the log does not say so: %s", f.row.Email)
	}
}

// AND THE ENTRY NAMES BOTH SIDES. What was published before this is the whole
// question somebody asks a year later — "which address was on the screen in
// March" — and it is the reason this value does not need a series of its own.
func TestTheEntryNamesWhatWasPublishedBefore(t *testing.T) {
	f := &supportFake{row: console.Contact{Email: "old@example.tld"}}

	if rec := f.set(t,
		`{"email":"new@example.tld","reason":"moved to the shared inbox"}`); rec.Code != http.StatusOK {
		t.Fatalf("setting an address answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 1 {
		t.Fatalf("one change wrote %d entries", len(f.entries))
	}
	one := f.entries[0]
	if one.what.Before != "old@example.tld" || one.what.After != "new@example.tld" {
		t.Errorf("the entry says %v → %v", one.what.Before, one.what.After)
	}
	if one.why != "moved to the shared inbox" {
		t.Errorf("the reason did not reach the log: %q", one.why)
	}
	// THE SUBJECT IS THE PLATFORM. Every other subject in this console is a
	// school, a plan or a person; an entry about the whole deployment that
	// named one of those would read as a change to whoever was on screen.
	if one.subject.Kind != "platform" {
		t.Errorf("the subject is %q", one.subject.Kind)
	}
}

// A FIRST ADDRESS HAS NOTHING BEFORE IT, and the entry says "nothing" rather
// than an empty string — an entry reading " → a@b.c" is one somebody has to
// guess at.
func TestTheFirstAddressSaysThereWasNothing(t *testing.T) {
	f := &supportFake{fallback: "deployed@example.tld"}

	if rec := f.set(t,
		`{"email":"help@example.tld","reason":"taking it over from the deployment"}`); rec.Code != http.StatusOK {
		t.Fatalf("the first address answered %d: %s", rec.Code, rec.Body.String())
	}
	if f.entries[0].what.Before != "nothing" {
		t.Errorf("the entry says the address before it was %v", f.entries[0].what.Before)
	}
}

/*
NO REASON, NO CHANGE.

The price handler records with an empty reason and has a comment saying it is
the write that most deserves one. This one asks, because the answer separates
two changes that look identical afterwards: an address that moved because the
person answering changed, and one that moved because the last was a typo. Only
the second means what was published in between was wrong.
*/
func TestAnAddressWithoutAReasonIsRefused(t *testing.T) {
	f := &supportFake{}

	rec := f.set(t, `{"email":"help@example.tld"}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("a change with no reason answered %d: %s", rec.Code, rec.Body.String())
	}
	if f.row.Email != "" {
		t.Errorf("it was set anyway: %s", f.row.Email)
	}
	if len(f.entries) != 0 {
		t.Errorf("a refused change wrote %d entries", len(f.entries))
	}
}

// WHAT THE STORE REFUSES COMES BACK AS THE STORE'S OWN SENTENCE, because the
// person typing has to be told what is wrong with what they typed — and this
// package may not import the error it is answering.
func TestARefusedAddressAnswersWithTheReason(t *testing.T) {
	f := &supportFake{refuse: true}

	rec := f.set(t, `{"email":"Support <help@example.tld>","reason":"typo"}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("a refused address answered %d: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "not an address") {
		t.Errorf("the store's sentence did not reach the caller: %s", rec.Body.String())
	}
}

// A READ-ONLY ROLE MAY LOOK AND NOT SET, like every other parameter here.
func TestAReadOnlyRoleCannotSayWhereStudentsWrite(t *testing.T) {
	f := &supportFake{mayNot: true}

	rec := f.set(t, `{"email":"help@example.tld","reason":"because"}`)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("a read-only role answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.entries) != 0 {
		t.Errorf("a refused role wrote %d entries", len(f.entries))
	}
	// AND IT CAN STILL READ IT. The rank is on the write; a console that hid
	// the value would make the read-only role unable to answer "where are
	// students told to write", which is the question it exists to answer.
	f.mayNot = true
	f.read(t)
}

/*
A WRITE THAT FAILS AFTER IT WAS RECORDED SAYS SO IN THE ANSWER.

This is the one state this handler cannot make right: the log says an address
changed and it did not. Every other write in this console says the same sentence
for the same reason — a defect named out loud is one somebody goes looking for.
*/
func TestAFailedWriteAfterRecordingSaysItIsADefect(t *testing.T) {
	f := &supportFake{failSet: true}

	rec := f.set(t, `{"email":"help@example.tld","reason":"because"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("a failed write answered %d: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "defect") {
		t.Errorf("the answer does not say the history is now wrong: %s", rec.Body.String())
	}
	if len(f.entries) != 1 {
		t.Errorf("the entry that is now wrong was not written: %d", len(f.entries))
	}
}
