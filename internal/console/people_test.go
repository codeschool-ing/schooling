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
	// why is what the actor typed. It was read off the request body and
	// dropped until the seam grew a parameter for it.
	why string
}

type fakes struct {
	person  console.Person
	held    map[string][]map[string]any
	erased  []uuid.UUID
	entries []recorded

	/* What a listing answers, and what it was ASKED. The `look` is kept because
	   a cursor read off the address bar and then dropped is how paging becomes a
	   screen that shows the first page for ever — and nothing about the answer
	   would say so. */
	page    []console.Person
	look    console.Look
	listErr error
	unwired bool

	findErr   error
	heldErr   error
	eraseErr  error
	recordErr error

	role uuid.UUID // the actor, and whether one is present at all
	may  bool      // whether that actor may erase
}

/*
fakePage is what this suite calls a full page.

	IT IS THREE AND NOT FIFTY. What the handler does with it is one comparison —
	a page of exactly this many gets a cursor after it and a shorter one does
	not — so the number only has to be large enough for "full" and "short" to be
	different, and small enough that a test can write out both.
*/
const fakePage = 3

func (f *fakes) handler() http.Handler {
	var list func(context.Context, console.Look) ([]console.Person, error)
	if !f.unwired {
		list = func(_ context.Context, look console.Look) ([]console.Person, error) {
			f.look = look
			if f.listErr != nil {
				return nil, f.listErr
			}
			return f.page, nil
		}
	}

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
			List: list,
			// The console decides whether there is a next page by comparing
			// against this, and it is wired from `identity.Page` in `cmd/api`.
			Page: fakePage,

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
			subject console.Subject, what console.Changed, why, _ string) error {
			if f.recordErr != nil {
				return f.recordErr
			}
			f.entries = append(f.entries, recorded{action, actor, actorLabel, subject, what, why})
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

// A WHOLE ADDRESS, OR NOTHING — on THIS route.
//
// K-22 was amended and a listing exists now, one route along and with an audit
// entry per page. This one did not change and must not: a lookup that quietly
// started matching prefixes would be the listing without any of the four things
// that make the listing defensible, reached by the route that records nothing.
// The refusal for an empty address is what says which of the two this is.
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

/*
TestTheReasonForAnErasureIsRecorded.

	IT WAS READ AND DROPPED. The handler decoded a `reason` off the request body
	and used it for nothing: `console.Record` had no parameter for one, so
	`audit_log.reason` — a column that has existed since the table did, and that
	the history screen already draws — was an empty string on every entry the
	console had ever written.

	An operator explaining the one act that cannot be undone was typing into
	nothing, and the screen showed them a field that implied otherwise.
*/
func TestTheReasonForAnErasureIsRecorded(t *testing.T) {
	f := seeded()

	got := ask(t, f.handler(), http.MethodPost,
		"/console/api/v1/people/"+f.person.ID.String()+"/erase",
		`{"email":"sam@example.tld","reason":"they asked, ticket 812"}`)
	if got.Code != http.StatusNoContent {
		t.Fatalf("it answered %d, want 204", got.Code)
	}
	if len(f.entries) != 1 {
		t.Fatalf("it wrote %d entries", len(f.entries))
	}
	if f.entries[0].why != "they asked, ticket 812" {
		t.Errorf("the entry's reason reads %q", f.entries[0].why)
	}
}

// AND AN EXPORT CARRIES NONE, which is not an omission: nobody is asked for
// one, and a sentence invented here would be this console describing its own
// behaviour rather than an actor explaining themselves.
func TestAnExportRecordsNoReasonBecauseNobodyIsAskedForOne(t *testing.T) {
	f := seeded()

	ask(t, f.handler(), http.MethodGet,
		"/console/api/v1/people/"+f.person.ID.String()+"/export", "")
	if len(f.entries) != 1 {
		t.Fatalf("it wrote %d entries", len(f.entries))
	}
	if f.entries[0].why != "" {
		t.Errorf("the export invented a reason: %q", f.entries[0].why)
	}
}

/* ---------- the listing, which is K-22 amended ---------- */

func someone(name, email string) console.Person {
	return console.Person{
		ID: uuid.New(), Name: name, Email: email, CreatedAt: time.Now(),
	}
}

// listed asks for a page and decodes it.
func listed(t *testing.T, f *fakes, query string) (int, map[string]any) {
	t.Helper()
	rec := ask(t, f.handler(), http.MethodGet, "/console/api/v1/people/list"+query, "")

	var body map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &body)
	return rec.Code, body
}

/*
TestEveryPageOfALLListingIsRecorded is the whole of the amendment.

	K-22 refused a listing because an audit cannot tell browsing from working.
	What replaced "never" is that it does not have to tell one read from
	another: the entry says what was searched for and how many came back, and
	forty of those in an afternoon is a shape. An entry that carried neither
	would leave the decision with nothing behind it.
*/
func TestEveryPageOfAListingIsRecorded(t *testing.T) {
	f := seeded()
	f.page = []console.Person{someone("Ana", "ana@example.tld")}

	if code, _ := listed(t, f, "?q=ana"); code != http.StatusOK {
		t.Fatalf("a listing answered %d", code)
	}
	if len(f.entries) != 1 {
		t.Fatalf("%d entries were written for one page", len(f.entries))
	}

	entry := f.entries[0]
	if entry.action != "personal-data.listed" {
		t.Errorf("the entry says %q", entry.action)
	}
	if entry.subject.Kind != "people" {
		t.Errorf("the subject is %q, and an entry filed against an account would be filed "+
			"against whoever happened to come back first", entry.subject.Kind)
	}

	what, ok := entry.what.Before.(map[string]any)
	if !ok {
		t.Fatalf("the entry carries %T", entry.what.Before)
	}
	if what["query"] != "ana" {
		t.Errorf("the entry says the query was %v — without it the entry reads "+
			"\"somebody listed people\", which cannot distinguish the two things it exists "+
			"to distinguish", what["query"])
	}
	if what["returned"] != 1 {
		t.Errorf("the entry says %v came back, and the count is the number a review reads",
			what["returned"])
	}
}

/*
TestAListingThatCouldNotBeRecordedIsNotAnswered.

	The rows are in the process and have reached nobody. Handing them over after
	failing to write the entry would be a listing this console cannot see, which
	is the entire objection K-22 raised — so the failure of the audit is the
	failure of the read.
*/
func TestAListingThatCouldNotBeRecordedIsNotAnswered(t *testing.T) {
	f := seeded()
	f.page = []console.Person{someone("Ana", "ana@example.tld")}
	f.recordErr = errors.New("the audit is not writable")

	code, body := listed(t, f, "?q=ana")
	if code != http.StatusServiceUnavailable {
		t.Fatalf("a listing nobody could record answered %d", code)
	}
	if _, present := body["people"]; present {
		t.Fatal("the rows were handed over anyway, so a listing happened that this console " +
			"has no record of")
	}
}

/*
TestNothingSearchedForIsEverybodyAndSaysSoInTheLog.

	"Who signed up this week" is a legitimate question with no search term in
	it, so an empty query is not refused. It is the BROADEST read this route
	does, which makes it the one an entry must not record as a blank — a missing
	value and a deliberate one look identical in a log.
*/
func TestNothingSearchedForIsEverybodyAndSaysSoInTheLog(t *testing.T) {
	f := seeded()
	f.page = []console.Person{someone("Ana", "ana@example.tld")}

	if code, _ := listed(t, f, ""); code != http.StatusOK {
		t.Fatalf("an empty search answered %d, and it is a real question", code)
	}

	what := f.entries[0].what.Before.(map[string]any)
	if what["query"] != "everybody" {
		t.Errorf("an empty search is recorded as %v", what["query"])
	}
}

/*
TestTheEntryCarriesTheQueryAndNeverTheResults.

	The uncomfortable half, held by a test. Storing what was typed is what makes
	the entry worth writing; storing what came back would make the audit a copy
	of the list — an append-only one, which is the failure `erase` avoids by
	recording counts and never the person.
*/
func TestTheEntryCarriesTheQueryAndNeverTheResults(t *testing.T) {
	f := seeded()
	f.page = []console.Person{someone("Ana", "ana@example.tld"), someone("Bo", "bo@example.tld")}

	if code, _ := listed(t, f, "?q=example"); code != http.StatusOK {
		t.Fatalf("a listing answered %d", code)
	}

	written, err := json.Marshal(f.entries[0].what)
	if err != nil {
		t.Fatalf("marshalling the entry: %v", err)
	}
	for _, leaked := range []string{"ana@example.tld", "bo@example.tld", "Ana", "Bo"} {
		if strings.Contains(string(written), leaked) {
			t.Fatalf("the entry names somebody who came back (%q): %s", leaked, written)
		}
	}
}

/*
TestAShortPageIsTheLastOne.

	A full page is not proof there is another — the next query can come back
	empty — but a short page IS proof there is not. That is the half worth
	acting on: the screen draws no button rather than one that leads nowhere.
*/
func TestAShortPageIsTheLastOne(t *testing.T) {
	f := seeded()
	f.page = []console.Person{someone("Ana", "ana@example.tld")}

	_, body := listed(t, f, "")
	if _, present := body["before"]; present {
		t.Fatal("a page shorter than a full one offered a cursor after it")
	}

	full := seeded()
	for i := 0; i < fakePage; i++ {
		full.page = append(full.page, someone("Ana", "ana@example.tld"))
	}
	_, body = listed(t, full, "")
	if _, present := body["before"]; !present {
		t.Fatal("a full page offered no cursor, so everybody past the first page is " +
			"reachable by nothing")
	}
}

/*
TestACursorReachesTheStore.

	Paging that reads a cursor and drops it is a screen that shows the first page
	for ever, and nothing about the answer says so — every page looks like a
	page. What is checked is that both halves arrived: `created_at` is not
	unique, so a cursor missing its id would put two accounts made in the same
	millisecond on both pages or on neither.
*/
func TestACursorReachesTheStore(t *testing.T) {
	f := seeded()
	at := time.Now().Add(-time.Hour).UTC()
	id := uuid.New()

	code, _ := listed(t, f, "?before="+at.Format(time.RFC3339Nano)+"&beforeId="+id.String())
	if code != http.StatusOK {
		t.Fatalf("a listing with a cursor answered %d", code)
	}
	if !f.look.Before.Equal(at) || f.look.BeforeID != id {
		t.Fatalf("the store was asked for %v/%v, and the address bar said %v/%v",
			f.look.Before, f.look.BeforeID, at, id)
	}
}

/*
TestANonsenseCursorIsTheFirstPageAndNotAnError.

	Somebody edited an address bar, or a bookmark went stale. The honest answer
	to a cursor that means nothing is the top of the list; a 400 would be this
	screen breaking on a link somebody saved.
*/
func TestANonsenseCursorIsTheFirstPageAndNotAnError(t *testing.T) {
	f := seeded()

	code, _ := listed(t, f, "?before=yesterday&beforeId=nobody")
	if code != http.StatusOK {
		t.Fatalf("a broken cursor answered %d", code)
	}
	if !f.look.Before.IsZero() || f.look.BeforeID != uuid.Nil {
		t.Fatalf("a broken cursor reached the store as %v/%v", f.look.Before, f.look.BeforeID)
	}
}

/*
TestADeploymentThatCannotListSaysSo.

	The dangerous answer here is an empty page, because "nobody matches" is what
	an operator would read — about a platform full of people. It is also the
	answer a nil seam gives if nothing checks for one.
*/
func TestADeploymentThatCannotListSaysSo(t *testing.T) {
	f := seeded()
	f.unwired = true

	code, _ := listed(t, f, "?q=ana")
	if code != http.StatusNotImplemented {
		t.Fatalf("a deployment with no listing wired answered %d", code)
	}
	if len(f.entries) != 0 {
		t.Fatal("an entry was written for a read that never happened")
	}
}

/*
TestTheListingSaysWhatItIsFor.

	"Named" is one of the four conditions the amendment rests on, and it is the
	only one that reaches somebody BEFORE they type. It comes from the server
	because it describes a rule the server enforces; a copy in an interface is a
	copy that can drift from what is actually true.
*/
func TestTheListingSaysWhatItIsFor(t *testing.T) {
	f := seeded()
	f.page = []console.Person{someone("Ana", "ana@example.tld")}

	_, body := listed(t, f, "?q=ana")
	if said, _ := body["about"].(string); said == "" {
		t.Fatal("the listing does not say what it is for, so the stated purpose the " +
			"amendment rests on exists only in a document")
	}
}
