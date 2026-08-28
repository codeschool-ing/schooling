package console

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/google/uuid"
)

/* Where the money actually moved, for one person.

   # THE CONSOLE COULD WRITE TO THE LEDGER AND NOT READ IT

   `POST /console/api/v1/people/{id}/ledger/adjustment` is the escape hatch: one
   line for money that moved outside the gateway — a bank transfer, a write-off,
   a goodwill credit, an amount keyed wrongly once. `writes.go` says it is
   supposed to look like an escape hatch, and it does.

   What it did NOT do was appear anywhere afterwards. An operator could write a
   row into an append-only table, correctly, and then have no way of seeing it
   short of a SQL client — which means no way of checking they typed the sign the
   right way round, and no way of noticing they had already made the same
   correction last week. A write with no read is a write nobody can review.

   # AND IT IS NOT THE PURCHASE HISTORY, WHICH IS THE WHOLE POINT

   `record.go` already says this about `Purchase`, and it is the sentence that
   decides the shape of this screen:

       An instalment plan is one sale collected several times and the ledger is
       keyed by the charge, so the biennial bought in three parts is three rows
       there and one line here. An operator adding up ledger rows to answer
       "what did they pay" would get the right total by luck and the wrong story
       every time.

   So the two are drawn as two different questions and neither is offered as a
   substitute for the other. The purchases answer WHAT THEY BOUGHT. This answers
   WHERE THE MONEY WENT, keyed by the charge, including the reversals and the
   corrections that no purchase ever had.

   # A READ, AND THEREFORE NOT IN `writes.go`

   That list is what this console can CHANGE. Nothing here changes anything, so
   there is no entry to argue for — and the argument that would have been made
   for it is on the adjustment, which is already there.

   # ITS OWN ROUTE RATHER THAN A FIELD ON THE RECORD

   The record is one request on purpose: "a person on the telephone is not read
   out in instalments". This stays out of it for a different reason than cost.
   The adjustment writes a row IMMEDIATELY — unlike a refund, which arrives with
   a webhook — so the screen has to be able to re-read this and nothing else
   after a change. Folded into the record it would be either a stale block or a
   second whole-record request to refresh one table.
*/

// Movement is one line of the ledger, as the console shows it.
type Movement struct {
	ID uuid.UUID

	// Kind is payment, refund, chargeback or adjustment. It is a string here
	// rather than a type of its own: this package cannot import the one that
	// owns the vocabulary, and a second copy of a closed list is a second list.
	Kind string

	// Cents is signed, and the sign carries direction: a payment is positive
	// and money going back is negative. Currency travels with it, because an
	// account can have movements in more than one.
	Cents    int
	Currency string

	// Reversed is true when this row undoes another. It is not the same as a
	// negative amount — a manual credit is negative and undoes nothing — and
	// the screen says which, because "we sent it back" and "we wrote it off"
	// are different conversations with the same person.
	Reversed bool

	/* Source is the provider, or "manual". SourceRef is that provider's own id,
	   and it is here for the reason `Purchase.ChargeID` is: it is what somebody
	   reads out to the processor's support desk. */
	Source    string
	SourceRef string

	// Memo is what a person typed when they wrote the line by hand, and is
	// empty for everything a gateway caused.
	Memo string

	At time.Time
}

// Ledger is what this package may not import: `billing` owns the rows.
type Ledger func(ctx context.Context, accountID uuid.UUID) ([]Movement, error)

// LedgerHandler is one person's movements.
type LedgerHandler struct {
	people People
	ledger Ledger
}

func NewLedgerHandler(people People, ledger Ledger) *LedgerHandler {
	return &LedgerHandler{people: people, ledger: ledger}
}

func (h *LedgerHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/people/{id}/ledger", h.ledgerOf)
}

func (h *LedgerHandler) ledgerOf(w http.ResponseWriter, r *http.Request) {
	id, ok := subject(w, r)
	if !ok {
		return
	}

	// THE PERSON FIRST AND BY ID, as the record does: a ledger for an id that
	// belongs to nobody is a 404, and an empty ledger is what nearly everybody
	// has. Those two must not look alike.
	if _, err := h.people.ByID(r.Context(), id); err != nil {
		if errors.Is(err, ErrNoPerson) {
			web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such person")
			return
		}
		web.LoggerFrom(r.Context()).Error("reading a person", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	rows, err := h.ledger(r.Context(), id)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading a ledger", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]map[string]any, 0, len(rows))
	for _, one := range rows {
		out = append(out, map[string]any{
			"id":        one.ID.String(),
			"kind":      one.Kind,
			"cents":     one.Cents,
			"currency":  one.Currency,
			"reversed":  one.Reversed,
			"source":    one.Source,
			"sourceRef": one.SourceRef,
			"memo":      one.Memo,
			"at":        one.At,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"movements": out,

		/* NET PER CURRENCY, COMPUTED HERE AND NOT ON THE SCREEN. It is one sum
		   and it is money, and the rule this repository already follows is that
		   money is counted in integer cents by the side that has them. Handing a
		   browser a list to add up is handing it the one arithmetic nobody wants
		   done twice with two answers.

		   PER CURRENCY BECAUSE AN ACCOUNT CAN HAVE TWO. `billing.Balance`
		   refuses such an account rather than picking one, which is right for a
		   number somebody acts on — and wrong for a screen, whose job is to show
		   what is there. So this groups instead of refusing. */
		"net": netOf(rows),

		// WHY THIS IS NOT THE PURCHASE TABLE, said where somebody comparing the
		// two totals will look for it.
		"not_the_purchases": "A purchase is one sale; this is every movement of money. An " +
			"instalment plan is one purchase and several rows here, so adding these up " +
			"answers what we received rather than what they bought.",
	})
}

// netOf sums the movements by currency, in the order the currencies first
// appear — so an account with one currency, which is nearly all of them, gets
// one number and no sorting to explain.
func netOf(rows []Movement) []map[string]any {
	order := make([]string, 0, 2)
	sum := map[string]int{}
	for _, one := range rows {
		if _, seen := sum[one.Currency]; !seen {
			order = append(order, one.Currency)
		}
		sum[one.Currency] += one.Cents
	}

	out := make([]map[string]any, 0, len(order))
	for _, currency := range order {
		out = append(out, map[string]any{"cents": sum[currency], "currency": currency})
	}
	return out
}
