package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* The student record, against fakes.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether a subscription is
   read correctly is `billing`'s test, against a real Postgres, and the same for
   progress, exams and certificates. What this file holds is the shape the
   console puts them in: that a school somebody has never touched is left out,
   that the answer says what it is scoped to, that an id belonging to nobody is
   a 404 rather than an empty page, and that a sitting never carries anything
   that would let an operator become the person they are looking at. */

var (
	somebody = uuid.MustParse("33333333-3333-4333-8333-333333333333")
	code     = console.School{ID: uuid.New(), Slug: "code", Name: "Programming"}
	math     = console.School{ID: uuid.New(), Slug: "math", Name: "Mathematics"}
)

type recordFake struct {
	person     console.Person
	found      bool
	sittings   []console.Sitting
	at         map[string]console.AtSchool
	holding    console.Holding
	refundable bool
	err        error
}

func (f *recordFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewRecordHandler(
		console.People{
			ByID: func(_ context.Context, id uuid.UUID) (console.Person, error) {
				if !f.found || id != f.person.ID {
					return console.Person{}, console.ErrNoPerson
				}
				return f.person, nil
			},
		},
		console.Records{
			Schools: func(context.Context) ([]console.School, error) {
				if f.err != nil {
					return nil, f.err
				}
				return []console.School{code, math}, nil
			},
			Sittings: func(context.Context, uuid.UUID) ([]console.Sitting, error) {
				return f.sittings, nil
			},
			At: func(_ context.Context, s console.School, _ uuid.UUID) (console.AtSchool, error) {
				return f.at[s.Slug], nil
			},
			Holding: func(context.Context, uuid.UUID) (console.Holding, error) {
				return f.holding, nil
			},
		},
		// This deployment has a gateway, so the screen may draw a refund
		// control. `TestARecordSaysWhetherAnythingCanBeSentBack` holds both.
		f.refundable,
	).Routes(mux)
	return mux
}

func aRecord() *recordFake {
	yesterday := time.Now().Add(-24 * time.Hour)
	paid := time.Now().Add(300 * 24 * time.Hour)
	return &recordFake{
		found:      true,
		refundable: true,
		person:     console.Person{ID: somebody, Name: "Sam Oliveira", Email: "sam@example.tld"},
		sittings: []console.Sitting{
			{ID: uuid.New(), CreatedAt: yesterday, ExpiresAt: time.Now().Add(time.Hour),
				UserAgent: "a browser"},
			{ID: uuid.New(), CreatedAt: yesterday, ExpiresAt: yesterday, UserAgent: "an old one"},
		},
		at: map[string]console.AtSchool{
			"code": {
				Plan: "annual", State: "active", PaidThrough: &paid,
				Courses:      []console.Course{{CourseID: "co-1", Sections: 4}},
				Certificates: []console.Given{{Code: "CS-1", Title: "Web", IssuedAt: yesterday}},
			},
			// `math` is left at its zero value on purpose: somebody who has
			// never touched a school.
		},
	}
}

// A SCHOOL SOMEBODY HAS NEVER TOUCHED IS LEFT OUT.
//
// Drawing every school with four empty tables is a screen where the answer is
// buried in the part that says nothing — and with a school per subject, most of
// this platform will be that for most people.
func TestASchoolWithNothingInItIsLeftOut(t *testing.T) {
	f := aRecord()
	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")

	if rec.Code != http.StatusOK {
		t.Fatalf("the record answered %d, want 200", rec.Code)
	}

	var body struct {
		Schools []struct {
			School string `json:"school"`
		} `json:"schools"`
		Scope string `json:"scope"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the record: %v", err)
	}

	if len(body.Schools) != 1 || body.Schools[0].School != "code" {
		t.Errorf("the record carries %d schools, want only the one they have anything at",
			len(body.Schools))
	}
	// AND IT SAYS WHAT IT IS SCOPED TO (K-18). One account crosses every school,
	// so a record that did not say so would be read as being about the school
	// whose name is nearest.
	if body.Scope != "every school" {
		t.Errorf("the record says its scope is %q", body.Scope)
	}
}

// A SITTING SAYS HOW MANY AND SINCE WHEN, NEVER HOW TO BECOME SOMEBODY.
//
// The session token's hash is in the same row and is not in the shape this
// package defines — so this is a test that the shape stays that way, which is
// the only moment it is cheap to hold.
func TestASittingCarriesNothingThatCouldBeUsed(t *testing.T) {
	f := aRecord()
	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	body := rec.Body.String()

	for _, leaked := range []string{"token", "hash", "secret"} {
		if strings.Contains(strings.ToLower(body), leaked) {
			t.Errorf("the record carries %q", leaked)
		}
	}

	var out struct {
		Sittings []struct {
			Live bool `json:"live"`
		} `json:"sittings"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("reading the record: %v", err)
	}
	if len(out.Sittings) != 2 {
		t.Fatalf("the record carries %d sittings, want 2", len(out.Sittings))
	}
	// One is live and one expired yesterday. A screen that could not tell them
	// apart would report somebody as signed in on every browser they ever used.
	if !out.Sittings[0].Live || out.Sittings[1].Live {
		t.Errorf("live was computed as %v and %v, want true and false",
			out.Sittings[0].Live, out.Sittings[1].Live)
	}
}

// AN ID THAT BELONGS TO NOBODY IS A 404 AND NOT AN EMPTY RECORD.
//
// An empty record is what somebody who has done nothing looks like, and a
// screen must not show the same thing for "this person has nothing" and "there
// is no such person".
func TestARecordForNobodyIsNotFound(t *testing.T) {
	f := aRecord()
	f.found = false

	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	if rec.Code != http.StatusNotFound {
		t.Errorf("a record for nobody answered %d, want 404", rec.Code)
	}

	rec = get(t, f.handler(), "/console/api/v1/people/not-an-id/record")
	if rec.Code != http.StatusNotFound {
		t.Errorf("a record for a malformed id answered %d, want 404", rec.Code)
	}
}

// AND A READ THAT FAILED IS NOT A PERSON WITH NOTHING.
func TestAFailedRecordIsNotAnEmptyOne(t *testing.T) {
	f := aRecord()
	f.err = fmt.Errorf("the database is not there")

	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	if rec.Code == http.StatusOK {
		t.Error("a record that could not be read answered 200, which reads on the " +
			"screen as somebody who has nothing")
	}
}

/*
TestTheRecordCarriesWhatTheyArePayingForAndEveryPurchase.

	IT IS BESIDE THE SCHOOLS AND NOT INSIDE ONE. A subscription covers every
	school (N-02), so the answer sits at the top level of the record — and the
	per-school fields above it are empty for everybody, which is why this
	section had to exist at all rather than be read out of `schools`.

	AND THE PURCHASES ARE NOT THE LEDGER. One line per SALE, whatever number of
	instalments it was collected in: an operator adding up ledger rows to answer
	"what did they pay" gets the right total by luck and the wrong story every
	time.
*/
func TestTheRecordCarriesWhatTheyArePayingForAndEveryPurchase(t *testing.T) {
	f := aRecord()
	through := time.Now().Add(300 * 24 * time.Hour)
	f.holding = console.Holding{
		State: "active", Opens: true, Model: "instalments",
		PaidThrough: &through,
		Price:       &console.Price{TermMonths: 24, Cents: 109000, Currency: "BRL"},
		Purchases: []console.Purchase{
			{
				ID: uuid.New(), Stage: "paid",
				Cents: 109000, Listed: 109000, Currency: "BRL", TermMonths: 24,
				Method: "card", Instalments: 3, PaidThrough: &through,
			},
			{
				ID: uuid.New(), Stage: "charged",
				Cents: 65550, Listed: 69000, Currency: "BRL", TermMonths: 12,
				Method: "pix", Instalments: 1,
				InvoiceURL: "https://pay.example.tld/abc",
			},
		},
	}

	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
	if rec.Code != http.StatusOK {
		t.Fatalf("the record answered %d, want 200", rec.Code)
	}

	var body struct {
		Holding *struct {
			State string `json:"state"`
			Opens bool   `json:"opens"`
			Price *struct {
				Cents int `json:"cents"`
			} `json:"price"`
			Purchases []struct {
				Stage       string `json:"stage"`
				Cents       int    `json:"cents"`
				Listed      int    `json:"listed"`
				Instalments int    `json:"instalments"`
				InvoiceURL  string `json:"invoiceUrl"`
				PaidThrough string `json:"paidThrough"`
			} `json:"purchases"`
		} `json:"holding"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the record: %v", err)
	}
	if body.Holding == nil {
		t.Fatalf("the record says nothing about what they are paying for: %s", rec.Body.String())
	}
	if body.Holding.State != "active" || !body.Holding.Opens {
		t.Errorf("it reads as %q, opens=%v", body.Holding.State, body.Holding.Opens)
	}
	if body.Holding.Price == nil || body.Holding.Price.Cents != 109000 {
		t.Errorf("the price came back as %+v", body.Holding.Price)
	}

	if len(body.Holding.Purchases) != 2 {
		t.Fatalf("two purchases read as %d", len(body.Holding.Purchases))
	}

	// A PLAN SPLIT THREE WAYS IS ONE LINE, at the price of the sale.
	if body.Holding.Purchases[0].Instalments != 3 ||
		body.Holding.Purchases[0].Cents != 109000 {
		t.Errorf("the instalment plan reads as %d× %d",
			body.Holding.Purchases[0].Instalments, body.Holding.Purchases[0].Cents)
	}

	// AND THE UNPAID PIX IS STILL THERE, with the address to send them back to
	// and no term, because it bought nothing.
	unpaid := body.Holding.Purchases[1]
	if unpaid.Stage != "charged" {
		t.Errorf("the unpaid checkout reads as %q", unpaid.Stage)
	}
	if unpaid.Listed-unpaid.Cents != 3450 {
		t.Errorf("the discount reads as %d and it was 3450", unpaid.Listed-unpaid.Cents)
	}
	if unpaid.InvoiceURL == "" {
		t.Error("no address came back, so an operator cannot give them their code again")
	}
	if unpaid.PaidThrough != "" {
		t.Errorf("a checkout nobody paid says it bought access to %s", unpaid.PaidThrough)
	}
}

// SOMEBODY WHO HAS NEVER BOUGHT ANYTHING HAS NO SECTION AT ALL, rather than an
// empty one. A block headed "subscription" with nothing under it reads as a
// screen that failed to load, and an operator would go looking.
func TestARecordWithNoPurchasesLeavesTheSectionOut(t *testing.T) {
	f := aRecord()
	rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("reading the record: %v", err)
	}
	if _, has := body["holding"]; has {
		t.Errorf("somebody who has bought nothing has a subscription section: %v", body["holding"])
	}
}

/*
TestARecordSaysWhetherAnythingCanBeSentBack.

	THE REFUND ROUTE IS NOT ALWAYS THERE. It is mounted only where there is a
	gateway key, so on a deployment without one the button would answer 404 —
	and a control that always fails is worse than one that is not drawn. The
	screen cannot know that by itself, and asking it to find out by trying is
	asking an operator to find out by telling a student their money is on its
	way.
*/
func TestARecordSaysWhetherAnythingCanBeSentBack(t *testing.T) {
	for _, can := range []bool{true, false} {
		f := aRecord()
		f.refundable = can

		rec := get(t, f.handler(), "/console/api/v1/people/"+somebody.String()+"/record")
		var body struct {
			Refundable bool `json:"refundable"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("reading the record: %v", err)
		}
		if body.Refundable != can {
			t.Errorf("a deployment with refundable=%v answered %v", can, body.Refundable)
		}
	}
}
