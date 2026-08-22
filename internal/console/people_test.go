package console_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The console's people routes, against fakes rather than a database.

   THE FAKES ARE THE POINT HERE. What these check is not that an export reads
   the right tables — `internal/privacy` has four tests for that, with a real
   Postgres — but the decisions this package makes ON TOP of it: that a
   read-only role cannot erase, that an erasure without the address is refused,
   that an audit entry that could not be written stops the action, and that
   nothing the audit keeps names the person. A database would not make any of
   those clearer and would hide two of them behind a schema. */

type recorded struct {
	action  string
	actor   uuid.UUID
	label   string
	subject console.Subject
	what    console.Changed
}

type fakes struct {
	person  console.Person
	held    map[string][]map[string]any
	erased  []uuid.UUID
	entries []recorded

	findErr   error
	heldErr   error
	eraseErr  error
	recordErr error

	role uuid.UUID // the actor, and whether one is present at all
	may  bool      // whether that actor may erase
}

func (f *fakes) handler() http.Handler {
	h := console.NewPeopleHandler(
		console.People{
			Find: func(_ context.Context, email string) (console.Person, error) {
				if f.findErr != nil {
					return console.Person{}, f.findErr
				}
				if !strings.EqualFold(strings.TrimSpace(email), f.person.Email) {
					return console.Person{}, console.ErrNoPerson
				}
				return f.person, nil
			},
			Held: func(context.Context, uuid.UUID) (map[string][]map[string]any, error) {
				return f.held, f.heldErr
			},
			Erase: func(_ context.Context, id uuid.UUID) error {
				if f.eraseErr != nil {
					return f.eraseErr
				}
				f.erased = append(f.erased, id)
				return nil
			},
		},
		func(_ context.Context, actor uuid.UUID, actorLabel, action string,
			subject console.Subject, what console.Changed, _ string) error {
			if f.recordErr != nil {
				return f.recordErr
			}
			f.entries = append(f.entries, recorded{action, actor, actorLabel, subject, what})
			return nil
		},
		func(context.Context, uuid.UUID) (string, string, error) {
			return "Alex", "alex@staff.tld", nil
		},
		func(context.Context) (uuid.UUID, bool) { return f.role, f.role != uuid.Nil },
		func(context.Context) bool { return f.may },
	)
	mux := http.NewServeMux()
	h.Routes(mux)
	return mux
}

func seeded() *fakes {
	return &fakes{
		person: console.Person{
			ID: uuid.New(), Name: "Sam", Email: "sam@example.tld", CreatedAt: time.Now(),
		},
		/* THE ROWS CARRY THE PERSON, on purpose: "the audit does not name them"
		   proves nothing against a fake whose contents were anonymous anyway. */
		held: map[string][]map[string]any{
			"accounts": {{"email": "sam@example.tld", "name": "Sam"}},
			"sessions": {{"id": "a"}, {"id": "b"}},
			"notes":    {},
		},
		role: uuid.New(),
		may:  true,
	}
}

func ask(t *testing.T, h http.Handler, method, path string, body string) *httptest.ResponseRecorder {
	t.Helper()
	var r *http.Request
	if body == "" {
		r = httptest.NewRequest(method, path, nil)
	} else {
		r = httptest.NewRequest(method, path, strings.NewReader(body))
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, r)
	return rec
}

// A WHOLE ADDRESS, OR NOTHING (K-22).
//
// There is no listing route and no prefix match, and the refusal for an empty
// address says which of the two this is: a lookup, not a search.
func TestAPersonIsFoundByAWholeAddressOrNotAtAll(t *testing.T) {
	f := seeded()
	h := f.handler()

	if got := ask(t, h, http.MethodGet, "/console/api/v1/people", "").Code; got != http.StatusBadRequest {
		t.Errorf("an empty address answered %d, want 400", got)
	}

	// A prefix of a real address is not a hit. If this ever passes, somebody has
	// made the lookup a search.
	if got := ask(t, h, http.MethodGet, "/console/api/v1/people?email=sam@", "").Code; got != http.StatusNotFound {
		t.Errorf("a partial address answered %d, want 404", got)
	}

	rec := ask(t, h, http.MethodGet, "/console/api/v1/people?email=SAM@example.tld%20", "")
	if rec.Code != http.StatusOK {
		t.Fatalf("the whole address answered %d, want 200", rec.Code)
	}
	var got struct{ Email string }
	if err := json.NewDecoder(rec.Body).Decode(&got); err != nil {
		t.Fatalf("reading the answer: %v", err)
	}
	if got.Email != f.person.Email {
		t.Errorf("found %q, want %q", got.Email, f.person.Email)
	}
}

// WHAT IS HELD IS COUNTED AND NOT SHOWN.
//
// A screen that rendered the rows would be an export nobody recorded. This is
// the check that keeps the cheap route cheap in what it discloses.
func TestWhatIsHeldIsCountedAndNeverShown(t *testing.T) {
	f := seeded()
	rec := ask(t, f.handler(), http.MethodGet,
		"/console/api/v1/people/"+f.person.ID.String()+"/held", "")

	if rec.Code != http.StatusOK {
		t.Fatalf("answered %d, want 200", rec.Code)
	}
	body := rec.Body.String()
	if strings.Contains(body, f.person.Email) || strings.Contains(body, "\"id\":\"a\"") {
		t.Errorf("the answer carried row contents: %s", body)
	}

	var got struct {
		Tables map[string]int
		Total  int
	}
	if err := json.NewDecoder(strings.NewReader(body)).Decode(&got); err != nil {
		t.Fatalf("reading the answer: %v", err)
	}
	if got.Tables["sessions"] != 2 || got.Total != 3 {
		t.Errorf("counts are %v (total %d), want sessions=2 total=3", got.Tables, got.Total)
	}
	if _, ok := got.Tables["notes"]; !ok {
		t.Error("a table with no rows was left out — which cannot be told from one that was forgotten")
	}

	// And reading the counts is not an action worth recording: it discloses
	// nothing. An audit that logged every glance is an audit nobody reads.
	if len(f.entries) != 0 {
		t.Errorf("counting what is held wrote %d audit entries, want none", len(f.entries))
	}
}

// AN EXPORT IS AUDITED (K-20), and the entry carries counts rather than the
// person.
func TestAnExportIsRecordedAndTheRecordDoesNotNameThePerson(t *testing.T) {
	f := seeded()
	rec := ask(t, f.handler(), http.MethodGet,
		"/console/api/v1/people/"+f.person.ID.String()+"/export", "")

	if rec.Code != http.StatusOK {
		t.Fatalf("answered %d, want 200", rec.Code)
	}
	if cd := rec.Header().Get("Content-Disposition"); !strings.Contains(cd, "attachment") {
		t.Errorf("Content-Disposition is %q, want an attachment", cd)
	}

	if len(f.entries) != 1 {
		t.Fatalf("wrote %d audit entries, want exactly one", len(f.entries))
	}
	entry := f.entries[0]
	if entry.action != "personal-data.export" {
		t.Errorf("action %q", entry.action)
	}
	if entry.subject.Kind != "account" || entry.subject.ID != f.person.ID.String() {
		t.Errorf("subject %s %s, want the account", entry.subject.Kind, entry.subject.ID)
	}
	if entry.label != "Alex <alex@staff.tld>" {
		t.Errorf("actor label %q, want the person who did it", entry.label)
	}

	// THE ENTRY IS COUNTS. An audit that recorded the address would make itself
	// the last surviving copy of somebody who asked to be forgotten.
	written, err := json.Marshal(entry.what)
	if err != nil {
		t.Fatalf("encoding what was recorded: %v", err)
	}
	if strings.Contains(string(written), f.person.Email) || strings.Contains(string(written), f.person.Name) {
		t.Errorf("the audit entry names the person: %s", written)
	}
	if !strings.Contains(string(written), `"sessions":2`) {
		t.Errorf("the audit entry does not say how much went: %s", written)
	}
}

// AN ACTION THAT COULD NOT BE RECORDED DID NOT HAPPEN.
//
// Recording after the fact would mean an export that succeeded with no entry is
// an export nobody can see — and being missing when somebody asks is the whole
// failure mode of an audit.
func TestAnActionThatCouldNotBeRecordedDoesNotHappen(t *testing.T) {
	f := seeded()
	f.recordErr = errors.New("the audit is unreachable")
	h := f.handler()

	if got := ask(t, h, http.MethodGet,
		"/console/api/v1/people/"+f.person.ID.String()+"/export", "").Code; got != http.StatusServiceUnavailable {
		t.Errorf("an unrecordable export answered %d, want 503", got)
	}

	body := `{"email":"sam@example.tld"}`
	if got := ask(t, h, http.MethodPost,
		"/console/api/v1/people/"+f.person.ID.String()+"/erase", body).Code; got != http.StatusServiceUnavailable {
		t.Errorf("an unrecordable erasure answered %d, want 503", got)
	}
	if len(f.erased) != 0 {
		t.Error("somebody was erased with no audit entry — which is an erasure nobody can account for")
	}
}

// READ-ONLY OPENED THE DOOR AND STOPS HERE.
func TestReadOnlyCannotErase(t *testing.T) {
	f := seeded()
	f.may = false

	got := ask(t, f.handler(), http.MethodPost,
		"/console/api/v1/people/"+f.person.ID.String()+"/erase", `{"email":"sam@example.tld"}`)

	if got.Code != http.StatusForbidden {
		t.Errorf("answered %d, want 403", got.Code)
	}
	if len(f.erased) != 0 {
		t.Error("a read-only role erased somebody")
	}
	if len(f.entries) != 0 {
		t.Error("a refused erasure was recorded as one")
	}
}

// THE CONFIRMATION IS THE PERSON'S OWN ADDRESS, TYPED.
//
// An erasure one click from a list somebody was scrolling is the accident this
// guards against, and typing the address means having the right person on the
// screen.
func TestErasingNeedsTheAddressAndTheAddressHasToMatch(t *testing.T) {
	f := seeded()
	h := f.handler()
	path := "/console/api/v1/people/" + f.person.ID.String() + "/erase"

	for _, body := range []string{
		`{}`,
		`{"email":""}`,
		`{"email":"somebody@else.tld"}`,
	} {
		if got := ask(t, h, http.MethodPost, path, body).Code; got != http.StatusBadRequest {
			t.Errorf("%s answered %d, want 400", body, got)
		}
	}
	if len(f.erased) != 0 {
		t.Fatal("somebody was erased without their address being typed")
	}

	// The right address, and only now.
	if got := ask(t, h, http.MethodPost, path, `{"email":"sam@example.tld"}`).Code; got != http.StatusNoContent {
		t.Fatalf("the right address answered %d, want 204", got)
	}
	if len(f.erased) != 1 || f.erased[0] != f.person.ID {
		t.Errorf("erased %v, want exactly the person", f.erased)
	}
	if len(f.entries) != 1 || f.entries[0].action != "personal-data.erase" {
		t.Errorf("entries are %v, want one erasure", f.entries)
	}
}

// AN ADDRESS THAT BELONGS TO SOMEBODY ELSE IS NOT A CONFIRMATION.
//
// The one that would matter: two people open in two tabs, and the address typed
// is the other one's. It has to match the person in the path, not merely exist.
func TestAnAddressThatBelongsToSomebodyElseDoesNotConfirm(t *testing.T) {
	f := seeded()

	// A real, findable person — but not the one the path names.
	other := uuid.New()
	got := ask(t, f.handler(), http.MethodPost,
		"/console/api/v1/people/"+other.String()+"/erase", `{"email":"sam@example.tld"}`)

	if got.Code != http.StatusBadRequest {
		t.Errorf("answered %d, want 400 — one person's address confirmed another's erasure", got.Code)
	}
	if len(f.erased) != 0 {
		t.Error("the wrong person was erased")
	}
}
