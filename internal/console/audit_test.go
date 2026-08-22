package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The console's history routes, against a fake.

   WHAT IS CHECKED HERE IS THE SCREEN'S HALF. `internal/audit` holds the queries
   against a real Postgres — ordering, the two filters, and a page boundary that
   neither repeats a row nor loses one. What this file holds is what the console
   decides on top of them: that a list never carries the two states, that a
   question with no index behind it is refused rather than answered slowly, and
   that a page says what it was narrowed to.

   THE FAKE'S ROWS CARRY `before` AND `after` ON PURPOSE. "The list does not
   serve them" proves nothing against a fixture that never had them — the same
   trap the people fixtures fell into, where the audit was proved not to name a
   person whose name was never in the rows. */

type historyFake struct {
	deeds []console.Deed
	asked console.Ask
	err   error
}

func (f *historyFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewHistoryHandler(console.History{
		Page: func(_ context.Context, ask console.Ask) ([]console.Deed, error) {
			f.asked = ask
			if f.err != nil {
				return nil, f.err
			}
			return f.deeds, nil
		},
		One: func(_ context.Context, id int64) (console.Deed, error) {
			for _, d := range f.deeds {
				if d.ID == id {
					return d, nil
				}
			}
			return console.Deed{}, console.ErrNoEntry
		},
	}).Routes(mux)
	return mux
}

func deeds(n int) []console.Deed {
	at := time.Date(2026, 8, 22, 9, 0, 0, 0, time.UTC)
	out := make([]console.Deed, 0, n)
	for i := range n {
		out = append(out, console.Deed{
			ID:          int64(1000 + i),
			OccurredAt:  at.Add(-time.Duration(i) * time.Minute),
			ActorID:     uuid.MustParse("11111111-1111-4111-8111-111111111111"),
			ActorKind:   "staff",
			ActorLabel:  "Ada Lovelace <ada@example.tld>",
			Action:      "personal-data.export",
			SubjectKind: "account",
			SubjectID:   "22222222-2222-4222-8222-222222222222",
			// The two states, present in every fixture row.
			Before: json.RawMessage(`{"email":"sam@example.tld"}`),
			After:  json.RawMessage(`{"email":"sam@example.tld"}`),
		})
	}
	return out
}

func get(t *testing.T, h http.Handler, path string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	return rec
}

// THE LIST IS METADATA AND THE ENTRY IS THE WHOLE THING.
//
// `before` and `after` are the personal data in this table — for an account
// they are a name and an address — and a page of fifty would hand a browser
// fifty people's details to render six words of each. It is the same shape as
// the personal-data screen: counts on the list, contents only when somebody
// asks for exactly one.
func TestTheListDoesNotCarryTheTwoStates(t *testing.T) {
	f := &historyFake{deeds: deeds(3)}
	rec := get(t, f.handler(), "/console/api/v1/audit")

	if rec.Code != http.StatusOK {
		t.Fatalf("the list answered %d, want 200", rec.Code)
	}
	body := rec.Body.String()
	for _, leaked := range []string{"sam@example.tld", `"before"`, `"after"`} {
		if strings.Contains(body, leaked) {
			t.Errorf("the list carries %s — a page of fifty entries is a page of fifty "+
				"people's details, sent to render six words of each", leaked)
		}
	}
	if !strings.Contains(body, "personal-data.export") {
		t.Error("the list does not carry the action, which is what it is for")
	}
}

func TestOneEntryCarriesThem(t *testing.T) {
	f := &historyFake{deeds: deeds(3)}
	rec := get(t, f.handler(), "/console/api/v1/audit/1000")

	if rec.Code != http.StatusOK {
		t.Fatalf("the entry answered %d, want 200", rec.Code)
	}
	var body struct {
		Before json.RawMessage `json:"before"`
		After  json.RawMessage `json:"after"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the entry: %v", err)
	}
	if len(body.Before) == 0 || len(body.After) == 0 {
		t.Error("one entry does not carry what the value was before and after, " +
			"which is the question an audit exists to answer")
	}
}

func TestAnUnknownEntryIsNotFound(t *testing.T) {
	f := &historyFake{deeds: deeds(1)}
	for _, path := range []string{"/console/api/v1/audit/999999", "/console/api/v1/audit/nonsense"} {
		if rec := get(t, f.handler(), path); rec.Code != http.StatusNotFound {
			t.Errorf("%s answered %d, want 404", path, rec.Code)
		}
	}
}

// A QUESTION WITH NO INDEX BEHIND IT IS REFUSED, NOT ANSWERED SLOWLY (K-21).
//
// Free text through `before`/`after`, a filter on `action`, a date range: each
// is a sequential scan of a table that only grows, so each works on the day it
// is written and stops working in the year nobody is watching. The refusal says
// which questions this screen does ask, because a 400 that does not is just a
// wall.
func TestTheQuestionsWithNoIndexAreRefused(t *testing.T) {
	f := &historyFake{deeds: deeds(1)}

	for _, query := range []string{"q=erase", "search=ada", "action=personal-data.erase",
		"from=2026-01-01", "to=2026-12-31"} {
		rec := get(t, f.handler(), "/console/api/v1/audit?"+query)
		if rec.Code != http.StatusBadRequest {
			t.Errorf("?%s answered %d, want 400", query, rec.Code)
		}
		if !strings.Contains(rec.Body.String(), "newest first") {
			t.Errorf("?%s was refused without saying what this screen does ask", query)
		}
	}
}

// AND HALF A SUBJECT IS REFUSED FOR THE SAME REASON. The index leads with the
// kind, so an id on its own does not narrow anything — it reads the table.
func TestHalfASubjectIsRefused(t *testing.T) {
	f := &historyFake{deeds: deeds(1)}

	for _, query := range []string{"subject=22222222-2222-4222-8222-222222222222", "subjectKind=account"} {
		if rec := get(t, f.handler(), "/console/api/v1/audit?"+query); rec.Code != http.StatusBadRequest {
			t.Errorf("?%s answered %d, want 400", query, rec.Code)
		}
	}

	rec := get(t, f.handler(),
		"/console/api/v1/audit?subjectKind=account&subject=22222222-2222-4222-8222-222222222222")
	if rec.Code != http.StatusOK {
		t.Fatalf("a whole subject answered %d, want 200", rec.Code)
	}
	if f.asked.SubjectKind != "account" {
		t.Errorf("the kind did not reach the query: %q", f.asked.SubjectKind)
	}
}

// A PAGE SAYS WHAT IT WAS NARROWED TO (K-18).
//
// The console crosses schools, so every number and every list on it is about
// some scope — and one that does not state it is one whose reader supplies it,
// usually the wrong one. The sentence is built where the query is, not on the
// screen: a scope assembled from the address bar can disagree with the rows
// underneath it.
func TestAPageSaysWhatItWasNarrowedTo(t *testing.T) {
	f := &historyFake{deeds: deeds(1)}

	for query, want := range map[string]string{
		"": "every action, every school",
		"actor=11111111-1111-4111-8111-111111111111": "one actor, every school",
		"subjectKind=account&subject=x":              "one account, every school",
	} {
		rec := get(t, f.handler(), "/console/api/v1/audit?"+query)
		var body struct {
			Scope string `json:"scope"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("reading the page: %v", err)
		}
		if body.Scope != want {
			t.Errorf("?%s said %q, want %q", query, body.Scope, want)
		}
	}
}

// A FULL PAGE OFFERS THE NEXT ONE AND A SHORT PAGE DOES NOT.
//
// And the marker is the last row, so it cannot drift: an entry written between
// two pages of an append-only table read newest-first would shift every row
// after it, which is exactly how an offset shows one row twice and loses
// another.
func TestOnlyAFullPageOffersAnother(t *testing.T) {
	short := &historyFake{deeds: deeds(3)}
	if next := pageNext(t, short.handler(), "/console/api/v1/audit"); next != "" {
		t.Errorf("a short page offered another: %q", next)
	}

	full := &historyFake{deeds: deeds(50)}
	next := pageNext(t, full.handler(), "/console/api/v1/audit")
	if next == "" {
		t.Fatal("a full page offered nothing to continue with")
	}

	// And it is accepted back, unchanged, as the next page's `after`.
	rec := get(t, full.handler(), "/console/api/v1/audit?after="+next)
	if rec.Code != http.StatusOK {
		t.Fatalf("the marker came back as %d, want 200", rec.Code)
	}
	last := deeds(50)[49]
	if full.asked.AfterID != last.ID {
		t.Errorf("the marker carried id %d, want %d", full.asked.AfterID, last.ID)
	}
	if full.asked.AfterTime == nil || !full.asked.AfterTime.Equal(last.OccurredAt) {
		t.Errorf("the marker carried %v, want %v", full.asked.AfterTime, last.OccurredAt)
	}
}

func TestARubbishMarkerIsRefused(t *testing.T) {
	f := &historyFake{deeds: deeds(1)}
	for _, marker := range []string{"nonsense", "123", "abc.1", "123.xyz"} {
		rec := get(t, f.handler(), "/console/api/v1/audit?after="+marker)
		if rec.Code != http.StatusBadRequest {
			t.Errorf("?after=%s answered %d, want 400", marker, rec.Code)
		}
	}
}

func pageNext(t *testing.T, h http.Handler, path string) string {
	t.Helper()
	rec := get(t, h, path)
	if rec.Code != http.StatusOK {
		t.Fatalf("%s answered %d, want 200", path, rec.Code)
	}
	var body struct {
		Next string `json:"next"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the page: %v", err)
	}
	return body.Next
}

func TestAFailedReadIsNotAnEmptyPage(t *testing.T) {
	f := &historyFake{err: fmt.Errorf("the database is not there")}
	rec := get(t, f.handler(), "/console/api/v1/audit")

	if rec.Code == http.StatusOK {
		t.Error("a history that could not be read answered 200 with no entries, " +
			"which reads on the screen as nothing having happened")
	}
}
