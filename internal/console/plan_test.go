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

/* What the platform charges, at the console's own layer.

   THESE TESTS MOVED WITH THE FEATURE. They were `school_test.go`'s, against
   `PUT /schools/{id}/price`, when `school_prices` was keyed by school. `0041`
   moved the table to the platform because one subscription opens every school
   (N-02), and the rules being checked did not change: a price is appended and a
   colour is replaced; a change nobody could record did not happen; a read-only
   role cannot set one; the series comes back whole.

   What is new is the TERM. There is no longer one price, so every write names
   how many months it buys, and the entry says which of them moved.

   WHAT IS CHECKED HERE IS WHAT THE CONSOLE DECIDES. Whether the row lands in
   the right table is `billing`'s test against a real Postgres. */

type planFake struct {
	// The series this fake has been made to write, and whether it refuses. A
	// price is APPENDED, so the fake appends too — a fake that replaced would
	// let a test pass that the real store would fail.
	priced  []console.Price
	cutting []console.Discount
	entries []recorded

	refusePrice    bool
	refuseDiscount bool
	failSet        bool
	failLog        bool
	mayNot         bool
}

var errNotAPrice = errors.New("not a price")
var errNotADiscount = errors.New("not a discount")

func (f *planFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewPlanHandler(
		console.Plan{
			Set: func(_ context.Context, termMonths, cents int, currency string) (
				console.Price, error) {

				if f.refusePrice {
					return console.Price{}, errNotAPrice
				}
				if f.failSet {
					return console.Price{}, fmt.Errorf("the database is not there")
				}
				was := f.inForce(termMonths)
				f.priced = append(f.priced, console.Price{
					TermMonths: termMonths, Cents: cents,
					Currency: currency, From: time.Now(),
				})
				return was, nil
			},
			InForce: func(_ context.Context, termMonths int) (console.Price, error) {
				return f.inForce(termMonths), nil
			},
			Series: func(context.Context) ([]console.Price, error) { return f.priced, nil },
			Refused: func(err error) bool {
				return errors.Is(err, errNotAPrice)
			},

			/* THE DISCOUNTS, APPENDED LIKE THE PRICES BY A FAKE THAT ALSO
			   APPENDS. A fake that replaced would let a test pass that the real
			   store — and the whole argument for dating this — would fail. */
			SetDiscount: func(_ context.Context, method string, basisPoints int) (
				console.Discount, error) {

				if f.refuseDiscount {
					return console.Discount{}, errNotADiscount
				}
				was := f.discountInForce(method)
				f.cutting = append(f.cutting, console.Discount{
					Method: method, BasisPoints: basisPoints, From: time.Now(),
				})
				return was, nil
			},
			DiscountInForce: func(_ context.Context, method string) (console.Discount, error) {
				return f.discountInForce(method), nil
			},
			Discounts: func(context.Context) ([]console.Discount, error) { return f.cutting, nil },
			RefusedDiscount: func(err error) bool {
				return errors.Is(err, errNotADiscount)
			},
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

// inForce is the newest row for a term, which is what the real store answers.
func (f *planFake) inForce(termMonths int) console.Price {
	var newest console.Price
	for _, one := range f.priced {
		if one.TermMonths == termMonths {
			newest = one
		}
	}
	return newest
}

// discountInForce is the newest row for a method, which is what the real store
// answers.
func (f *planFake) discountInForce(method string) console.Discount {
	var newest console.Discount
	for _, one := range f.cutting {
		if one.Method == method {
			newest = one
		}
	}
	return newest
}

func (f *planFake) discount(t *testing.T, body string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPut,
		"/console/api/v1/plan/discount", strings.NewReader(body)))
	return rec
}

func (f *planFake) price(t *testing.T, body string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodPut,
		"/console/api/v1/plan/price", strings.NewReader(body)))
	return rec
}

/*
A PRICE IS APPENDED AND A COLOUR IS REPLACED, AND THE DIFFERENCE IS THE FEATURE.

Saving the same price twice writes two rows. On the accent that would be a log
of somebody's clicking and the handler refuses it; here it is the answer to
"was this re-confirmed in March, or has nobody touched it since January" — and a
handler that copied the accent's short-circuit would have destroyed exactly the
thing K-14 asks for, while looking like consistency.
*/
func TestSavingTheSamePriceAgainIsStillANewRow(t *testing.T) {
	f := &planFake{}

	for i := range 2 {
		rec := f.price(t, `{"termMonths":12,"cents":49000,"currency":"BRL"}`)
		if rec.Code != http.StatusOK {
			t.Fatalf("setting a price the %d time answered %d: %s", i+1, rec.Code, rec.Body.String())
		}
	}
	if len(f.priced) != 2 {
		t.Errorf("the same price saved twice wrote %d rows", len(f.priced))
	}
	if len(f.entries) != 2 {
		t.Errorf("two price changes wrote %d audit entries", len(f.entries))
	}
}

// THE ENTRY IS IN CENTS AND NAMES BOTH SIDES. It is read a year later beside a
// ledger row, and the ledger is in cents — a formatted amount would be the one
// place in this system where money is a decimal string.
func TestThePriceEntryNamesBothSidesInCents(t *testing.T) {
	f := &planFake{}

	if rec := f.price(t, `{"termMonths":12,"cents":49000,"currency":"BRL"}`); rec.Code != http.StatusOK {
		t.Fatalf("setting a price answered %d: %s", rec.Code, rec.Body.String())
	}
	if rec := f.price(t, `{"termMonths":12,"cents":59000,"currency":"BRL"}`); rec.Code != http.StatusOK {
		t.Fatalf("raising a price answered %d: %s", rec.Code, rec.Body.String())
	}

	if len(f.entries) != 2 {
		t.Fatalf("two changes wrote %d entries", len(f.entries))
	}
	first, second := f.entries[0], f.entries[1]
	if first.action != "plan.price.changed" {
		t.Errorf("the entry says the action was %q", first.action)
	}
	if got := fmt.Sprint(first.what.Before); got != "none" {
		t.Errorf("a term that had no price recorded %q as its before", got)
	}
	if got := fmt.Sprint(second.what.Before); got != "49000 BRL cents" {
		t.Errorf("the second change recorded %q as its before", got)
	}
	if got := fmt.Sprint(second.what.After); got != "59000 BRL cents" {
		t.Errorf("the second change recorded %q as its after", got)
	}
}

// AND IT SAYS WHICH TERM MOVED. With three products under one scope, an entry
// naming only the amounts would be a change nobody can attribute — "590 became
// 690" is two different decisions depending on whether it bought a year or two.
func TestThePriceEntryNamesTheTerm(t *testing.T) {
	f := &planFake{}

	for _, one := range []struct {
		body string
		want string
	}{
		{`{"termMonths":1,"cents":4900,"currency":"BRL"}`, "monthly"},
		{`{"termMonths":12,"cents":59000,"currency":"BRL"}`, "annual"},
		{`{"termMonths":24,"cents":99000,"currency":"BRL"}`, "biennial"},
		{`{"termMonths":3,"cents":19000,"currency":"BRL"}`, "3 months"},
	} {
		if rec := f.price(t, one.body); rec.Code != http.StatusOK {
			t.Fatalf("setting %s answered %d: %s", one.body, rec.Code, rec.Body.String())
		}
		last := f.entries[len(f.entries)-1]
		if last.subject.Kind != "plan" {
			t.Errorf("the entry's subject is a %q", last.subject.Kind)
		}
		if last.subject.ID != one.want {
			t.Errorf("a term of %s was recorded as %q", one.body, last.subject.ID)
		}
	}
}

// A TERM IS PRICED ON ITS OWN. Raising the year does not touch the two years,
// and an entry that named the wrong `before` would be the first sign that they
// share a row somewhere they should not.
func TestOneTermsPriceDoesNotMoveAnother(t *testing.T) {
	f := &planFake{}

	for _, body := range []string{
		`{"termMonths":12,"cents":59000,"currency":"BRL"}`,
		`{"termMonths":24,"cents":99000,"currency":"BRL"}`,
		`{"termMonths":12,"cents":69000,"currency":"BRL"}`,
	} {
		if rec := f.price(t, body); rec.Code != http.StatusOK {
			t.Fatalf("setting %s answered %d: %s", body, rec.Code, rec.Body.String())
		}
	}

	last := f.entries[len(f.entries)-1]
	if got := fmt.Sprint(last.what.Before); got != "59000 BRL cents" {
		t.Errorf("raising the year recorded %q as its before, which is the other term's", got)
	}
}

// A CHANGE NOBODY COULD RECORD IS NOT MADE, which is the same rule the accent
// follows — and it matters more here, because the row it would have written
// cannot be deleted afterwards.
func TestAPriceNobodyCouldRecordIsNotWritten(t *testing.T) {
	f := &planFake{failLog: true}

	rec := f.price(t, `{"termMonths":12,"cents":49000,"currency":"BRL"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("a price whose entry could not be written answered %d: %s",
			rec.Code, rec.Body.String())
	}
	if len(f.priced) != 0 {
		t.Errorf("it wrote %d price rows anyway", len(f.priced))
	}
}

// SETTING A PRICE IS NOT A THING A READ-ONLY ROLE DOES, for the reason setting
// a colour is not: read-only opened the door so the console can be looked at.
func TestReadOnlyCannotSetAPrice(t *testing.T) {
	f := &planFake{mayNot: true}

	rec := f.price(t, `{"termMonths":12,"cents":49000,"currency":"BRL"}`)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("a read-only price answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.priced) != 0 || len(f.entries) != 0 {
		t.Errorf("a refused price wrote %d rows and %d entries", len(f.priced), len(f.entries))
	}
}

// A PRICE THE STORE REFUSES IS THE CALLER'S TO FIX, and it comes back as one
// rather than as an outage — the sentence names which half was wrong.
func TestAPriceTheStoreRefusesIsABadRequest(t *testing.T) {
	f := &planFake{refusePrice: true}

	rec := f.price(t, `{"termMonths":12,"cents":0,"currency":"BRL"}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("a refused price answered %d: %s", rec.Code, rec.Body.String())
	}
}

// AND THE SERIES COMES BACK WHOLE, oldest rows included, every term together. A
// screen that could only see the newest would be the mutable column again with
// extra steps.
func TestTheSeriesKeepsWhatWasReplaced(t *testing.T) {
	f := &planFake{}

	for _, cents := range []string{"49000", "59000"} {
		body := `{"termMonths":12,"cents":` + cents + `,"currency":"BRL"}`
		if rec := f.price(t, body); rec.Code != http.StatusOK {
			t.Fatalf("setting %s answered %d: %s", cents, rec.Code, rec.Body.String())
		}
	}

	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/console/api/v1/plan/prices", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("reading the series answered %d: %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v", err)
	}
	rows, _ := body["prices"].([]any)
	if len(rows) != 2 {
		t.Errorf("two prices were set and the series holds %d", len(rows))
	}
	if body["append_only"] == nil || body["append_only"] == "" {
		t.Error("the series does not say why there is no way to edit one")
	}
}

/* ---------- what comes off, which is the price's shape asked differently ----------

   THE ASSERTIONS THAT MATTER ARE THE ONES THAT DIFFER. Appended, recorded before
   it happens, refused below operator — those are the price's and they are held
   there. What is checked here is what a discount does that a price does not.
*/

// APPENDED, LIKE THE PRICE. The whole reason `0045` is a table rather than a
// column is that the rate live for a fortnight that sold nothing leaves no
// trace in any sale — so a save that replaced would destroy the only record of
// it while looking like consistency with the accent beside it.
func TestSavingADiscountKeepsTheOneBefore(t *testing.T) {
	f := &planFake{}

	for _, points := range []int{500, 700} {
		rec := f.discount(t, fmt.Sprintf(`{"method":"pix","basisPoints":%d}`, points))
		if rec.Code != http.StatusOK {
			t.Fatalf("setting %d answered %d: %s", points, rec.Code, rec.Body.String())
		}
	}
	if len(f.cutting) != 2 {
		t.Errorf("two rates wrote %d rows", len(f.cutting))
	}
	if len(f.entries) != 2 {
		t.Errorf("two rate changes wrote %d audit entries", len(f.entries))
	}
}

/*
THE ENTRY IS IN BASIS POINTS AND SAYS SO, and names both sides.

It is read a year later beside a checkout row, and "500" alone is a number
somebody has to be told the unit of — the same argument the price's entry makes
for writing cents in cents. The first rate for a method replaced NOTHING, and
the entry says that word rather than a zero nobody can tell from a rate.
*/
func TestTheDiscountEntryNamesBothSidesInBasisPoints(t *testing.T) {
	f := &planFake{}

	if rec := f.discount(t, `{"method":"pix","basisPoints":500}`); rec.Code != http.StatusOK {
		t.Fatalf("the first rate answered %d: %s", rec.Code, rec.Body.String())
	}
	first := f.entries[0]
	if first.what.Before != "nothing" {
		t.Errorf("the first rate says it replaced %v", first.what.Before)
	}
	if first.what.After != "500 basis points" {
		t.Errorf("the entry records %v, which does not say the unit", first.what.After)
	}
	// THE SUBJECT IS THE METHOD, as a price's is the term: it is the whole of
	// what distinguishes one of these rows from another while the scope is 'all'.
	if first.subject.ID != "pix" {
		t.Errorf("the subject is %q", first.subject.ID)
	}
}

// WHAT THE STORE REFUSES COMES BACK AS THE STORE'S OWN SENTENCE. The ceiling is
// there and not here — a fence somebody can move from a screen is a fence in the
// way — so this package has to be able to pass the refusal through without
// importing the error that carries it.
func TestARefusedDiscountAnswersWithTheReason(t *testing.T) {
	f := &planFake{refuseDiscount: true}

	rec := f.discount(t, `{"method":"pix","basisPoints":9000}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("a refused rate answered %d: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "not a discount") {
		t.Errorf("the store's sentence did not reach the caller: %s", rec.Body.String())
	}
}

// A READ-ONLY ROLE MAY LOOK AND NOT SET, like every other parameter here.
func TestAReadOnlyRoleCannotChangeWhatComesOff(t *testing.T) {
	f := &planFake{mayNot: true}

	rec := f.discount(t, `{"method":"pix","basisPoints":500}`)
	if rec.Code != http.StatusForbidden {
		t.Fatalf("a read-only role answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.cutting) != 0 || len(f.entries) != 0 {
		t.Error("a refused role wrote something")
	}
}

/*
THE DISCOUNTS TRAVEL WITH THE PRICES, in one answer.

They are the same subject drawn on the same screen, and two requests for one
page would be two chances to draw half of an offer — a screen showing a price
and no discount is a screen quoting the wrong number to whoever reads it.
*/
func TestTheSeriesAnswerCarriesBothPricesAndDiscounts(t *testing.T) {
	f := &planFake{}

	if rec := f.price(t, `{"termMonths":12,"cents":69000,"currency":"BRL"}`); rec.Code != http.StatusOK {
		t.Fatal(rec.Body.String())
	}
	if rec := f.discount(t, `{"method":"pix","basisPoints":500}`); rec.Code != http.StatusOK {
		t.Fatal(rec.Body.String())
	}

	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/console/api/v1/plan/prices", nil))

	var body map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("the answer is not JSON: %v", err)
	}
	if rows, _ := body["prices"].([]any); len(rows) != 1 {
		t.Errorf("the answer carries %d prices", len(rows))
	}
	if rows, _ := body["discounts"].([]any); len(rows) != 1 {
		t.Errorf("the answer carries %d discounts, and the screen draws both", len(rows))
	}
}
