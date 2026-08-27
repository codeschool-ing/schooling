package console

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/google/uuid"
)

/* What the platform charges, and the series that explains it.

   # THIS WAS ON THE SCHOOL SCREEN AND IT WAS IN THE WRONG PLACE

   `PUT /console/api/v1/schools/{id}/price` set a price at ONE school, because
   `school_prices` was keyed by school. One subscription opens every school
   (N-02), so those two facts together let somebody buy through the cheapest
   page and open all of them — `0041` moves the table to the platform and says
   why at length.

   The screen follows the table. There is no per-school price to edit, so there
   is no per-school form: setting a price is a platform write, and leaving a
   field labelled "price" on a school's page would be a control whose effect is
   somewhere other than where it appears.

   # A TERM IS PART OF THE PRICE NOW

   The plan is annual, biennial and — abroad — monthly, so "the price" is no
   longer one number. Every write here names the term it prices, and the series
   comes back with all of them interleaved: a person looking at that table wants
   to see that the year moved and the two years did not, which is a comparison
   three separate tables cannot be asked for.

   # AND IT IS AUDITED WITH BOTH SIDES, LIKE EVERY OTHER WRITE

   The entry is written FIRST and names what was there and what replaced it. A
   price nobody can account for is worse than a price nobody changed.
*/

// Price is one row of the platform's series, as the console shows it.
type Price struct {
	TermMonths int
	Cents      int
	Currency   string
	From       time.Time
}

// Plan is what this package may not import: `billing` owns the rows.
type Plan struct {
	// Set APPENDS a price for a term and answers the one it replaces (K-14). It
	// is not the accent's shape and must not become it: a colour is overwritten
	// because nothing has to be explained about the old one a year later, and a
	// price is a series because a March invoice has to stay explicable in
	// November.
	//
	// A zero `was` is a term that had no price before, which is a real state
	// rather than a failure.
	Set func(ctx context.Context, termMonths, cents int, currency string) (was Price, err error)

	// InForce is what one term costs right now, which the handler reads before
	// it writes so that the audit entry can name both sides. A zero is a term
	// nobody has priced.
	InForce func(ctx context.Context, termMonths int) (Price, error)

	// Series is the whole of it, newest first, every term together.
	Series func(ctx context.Context) ([]Price, error)

	// Refused is a price the caller can fix by sending another: not a number,
	// not a currency, not a term. `billing` builds the sentence and this package
	// may not import its errors, so the predicate travels instead.
	Refused func(error) bool
}

// PlanHandler reads and writes what the platform charges.
type PlanHandler struct {
	plan   Plan
	record Record
	label  Label
	who    func(ctx context.Context) (uuid.UUID, bool)

	// maySet is the second rank, as the school screen has one: read-only opened
	// the door, and deciding what everybody pays is not a thing a read-only role
	// does.
	maySet func(ctx context.Context) bool
}

func NewPlanHandler(plan Plan, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	maySet func(ctx context.Context) bool,
) *PlanHandler {
	return &PlanHandler{plan: plan, record: record, label: label, who: who, maySet: maySet}
}

func (h *PlanHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /console/api/v1/plan/prices", h.prices)
	mux.HandleFunc("PUT /console/api/v1/plan/price", h.setPrice)
}

/*
SETTING A PRICE IS APPENDING TO A SERIES, AND THE HANDLER SAYS SO.

The accent handler refuses a write that changes nothing. This one does the
opposite on purpose: a price identical to the one in force is STILL WRITTEN.
Pressing save twice on a colour is somebody clicking; re-confirming a price is a
fact about the offer — "this is still what we ask, as of today" — and a series
that dropped the repeats could not tell that apart from a price nobody has
touched since January.
*/
func (h *PlanHandler) setPrice(w http.ResponseWriter, r *http.Request) {
	if !h.maySet(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"changing what the platform charges asks for an operator")
		return
	}

	var asked struct {
		TermMonths int    `json:"termMonths"`
		Cents      int    `json:"cents"`
		Currency   string `json:"currency"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&asked); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}
	currency := strings.ToUpper(strings.TrimSpace(asked.Currency))

	actor, label, ok := acting(w, r, h.who, h.label)
	if !ok {
		return
	}

	// What is in force, so the entry can name what this replaced. A term nobody
	// has priced comes back as a zero, which `money` writes as "nothing".
	was, err := h.plan.InForce(r.Context(), asked.TermMonths)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the price in force",
			"error", err, "term_months", asked.TermMonths)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	if err := h.record(r.Context(), actor, label,
		"plan.price.changed",
		Subject{Kind: "plan", ID: term(asked.TermMonths)},
		Changed{
			Before: money(was.Cents, was.Currency),
			After:  money(asked.Cents, currency),
		},
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a price change", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	before, err := h.plan.Set(r.Context(), asked.TermMonths, asked.Cents, currency)
	switch {
	case h.plan.Refused != nil && h.plan.Refused(err):
		web.Fail(w, http.StatusBadRequest, "not_a_price", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("setting the plan's price",
			"error", err, "term_months", asked.TermMonths)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}
	if before.Cents != was.Cents || before.Currency != was.Currency {
		// Somebody else priced it between the read and the write, so the entry
		// above names a `before` that was already gone. The series still holds
		// the truth — that is what it is for — and this is the line that says
		// where to look.
		web.LoggerFrom(r.Context()).Warn("a price moved under a change",
			"term_months", asked.TermMonths,
			"recorded_before", money(was.Cents, was.Currency),
			"actually_was", money(before.Cents, before.Currency))
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"termMonths": asked.TermMonths,
		"cents":      asked.Cents,
		"currency":   currency,
	})
}

// prices is the series, which is the half of K-14 a single number cannot show.
func (h *PlanHandler) prices(w http.ResponseWriter, r *http.Request) {
	rows, err := h.plan.Series(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the plan's prices", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	out := make([]map[string]any, 0, len(rows))
	for _, one := range rows {
		out = append(out, map[string]any{
			"termMonths": one.TermMonths,
			"cents":      one.Cents,
			"currency":   one.Currency,
			"from":       one.From,
		})
	}
	web.JSON(w, http.StatusOK, map[string]any{
		"prices": out,

		// WHY THERE IS NO WAY TO EDIT ONE, said where somebody looking for the
		// button will find it.
		"append_only": "A price is never edited. Changing what the platform charges writes a " +
			"new row dated from today, and the old one stays — a March invoice has to stay " +
			"explicable in November.",
	})
}

// term is the scope of one price change, as the audit names it: the number of
// months, because that is the whole of what distinguishes one plan from another
// while the scope stays `all`.
func term(months int) string {
	switch months {
	case 1:
		return "monthly"
	case 12:
		return "annual"
	case 24:
		return "biennial"
	}
	return strconv.Itoa(months) + " months"
}
