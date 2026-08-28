package console_test

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/console"
	"github.com/google/uuid"
)

/* One person's movements, at the console's own layer.

   WHAT IS CHECKED HERE is what this console decides: that an id belonging to
   nobody is a 404 and an empty ledger is a 200, that the sign survives the
   crossing, and that the net is summed per currency rather than refused.
   Whether the rows are the right rows is `billing`'s test against a real
   Postgres.

   THE SIGN IS THE ONE WORTH A TEST OF ITS OWN. `Money` carries direction in it
   — a refund is a payment with the other sign — and a translation that took the
   magnitude "because the screen shows the direction anyway" would put a refund
   on the wrong side of the first total anybody added up. */

type ledgerFake struct {
	rows    []console.Movement
	noSuch  bool
	failing bool
}

func (f *ledgerFake) handler() http.Handler {
	mux := http.NewServeMux()
	console.NewLedgerHandler(
		console.People{
			ByID: func(_ context.Context, id uuid.UUID) (console.Person, error) {
				if f.noSuch {
					return console.Person{}, console.ErrNoPerson
				}
				return console.Person{ID: id, Name: "Ada Lovelace", Email: "ada@example.tld"}, nil
			},
		},
		func(context.Context, uuid.UUID) ([]console.Movement, error) {
			if f.failing {
				return nil, fmt.Errorf("the database is not there")
			}
			return f.rows, nil
		},
	).Routes(mux)
	return mux
}

func (f *ledgerFake) read(t *testing.T) (*httptest.ResponseRecorder, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	f.handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet,
		"/console/api/v1/people/"+uuid.NewString()+"/ledger", nil))

	var body map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &body)
	return rec, body
}

func aMovement(kind string, cents int, currency string) console.Movement {
	return console.Movement{
		ID: uuid.New(), Kind: kind, Cents: cents, Currency: currency,
		Source: "asaas", SourceRef: "pay_" + kind, At: time.Now(),
	}
}

// THE SIGN CROSSES INTACT, and the amounts come through as the ledger holds
// them: cents, signed, with the currency beside each one.
func TestTheSignSurvivesTheCrossing(t *testing.T) {
	f := &ledgerFake{rows: []console.Movement{
		aMovement("payment", 69000, "BRL"),
		aMovement("refund", -69000, "BRL"),
	}}

	rec, body := f.read(t)
	if rec.Code != http.StatusOK {
		t.Fatalf("reading a ledger answered %d: %s", rec.Code, rec.Body.String())
	}

	rows, _ := body["movements"].([]any)
	if len(rows) != 2 {
		t.Fatalf("two movements came back as %d", len(rows))
	}
	back, _ := rows[1].(map[string]any)
	if back["cents"] != float64(-69000) {
		t.Errorf("the refund crossed as %v, and money going back is negative", back["cents"])
	}
}

/*
THE NET IS PER CURRENCY AND IS NOT REFUSED.

`billing.Balance` answers `ErrMixedCurrencies` for an account with movements in
two, and that is right for a number somebody acts on — it refuses rather than
picking one. It is wrong for a screen, whose job is to show what is there. So
this groups, and an account that paid in reais and then moved abroad gets two
numbers instead of an error where a total should be.
*/
func TestTheNetIsPerCurrencyRatherThanRefused(t *testing.T) {
	f := &ledgerFake{rows: []console.Movement{
		aMovement("payment", 69000, "BRL"),
		aMovement("refund", -20000, "BRL"),
		aMovement("payment", 4900, "USD"),
	}}

	_, body := f.read(t)
	net, _ := body["net"].([]any)
	if len(net) != 2 {
		t.Fatalf("two currencies netted to %d rows", len(net))
	}

	got := map[string]float64{}
	for _, one := range net {
		row, _ := one.(map[string]any)
		currency, _ := row["currency"].(string)
		cents, _ := row["cents"].(float64)
		got[currency] = cents
	}
	if got["BRL"] != 49000 {
		t.Errorf("the reais net to %v and should net to 49000", got["BRL"])
	}
	if got["USD"] != 4900 {
		t.Errorf("the dollars net to %v", got["USD"])
	}
}

/*
NOTHING IS A 200 AND NOBODY IS A 404, and the two must not look alike.

Nearly every person on this platform has never paid anything, so an empty
ledger is the ordinary state and an error would make the ordinary case look
like a failure. An id that belongs to nobody is a different fact entirely, and
`record.go` draws the same line for the same reason.
*/
func TestNothingIsNotTheSameAsNobody(t *testing.T) {
	empty := &ledgerFake{}
	rec, body := empty.read(t)
	if rec.Code != http.StatusOK {
		t.Fatalf("an empty ledger answered %d", rec.Code)
	}
	rows, ok := body["movements"].([]any)
	if !ok || len(rows) != 0 {
		t.Errorf("an empty ledger came back as %v, and it has to be a list", body["movements"])
	}

	gone := &ledgerFake{noSuch: true}
	if rec, _ := gone.read(t); rec.Code != http.StatusNotFound {
		t.Errorf("an id belonging to nobody answered %d", rec.Code)
	}
}

// AND THE SENTENCE THAT SAYS WHY THIS IS NOT THE PURCHASE TABLE travels with
// the rows. Somebody comparing the two totals will look for the explanation on
// the screen rather than in a comment, and an instalment plan is one purchase
// and several rows here.
func TestTheAnswerSaysItIsNotThePurchases(t *testing.T) {
	f := &ledgerFake{rows: []console.Movement{aMovement("payment", 69000, "BRL")}}

	_, body := f.read(t)
	said, _ := body["not_the_purchases"].(string)
	if said == "" {
		t.Error("the answer carries no sentence distinguishing it from the purchase table")
	}
}

// A LEDGER THAT COULD NOT BE READ IS A 503 AND NOT AN EMPTY ONE. An empty table
// under a heading is a person who has never paid; a database that did not
// answer is a screen that must not claim so.
func TestALedgerThatCouldNotBeReadDoesNotLookEmpty(t *testing.T) {
	f := &ledgerFake{failing: true}

	if rec, _ := f.read(t); rec.Code != http.StatusServiceUnavailable {
		t.Errorf("an unreadable ledger answered %d", rec.Code)
	}
}
