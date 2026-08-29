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

// Discount is one row of the discount series, as the console shows it.
//
// IT IS BASIS POINTS AND NOT A PERCENTAGE, all the way to the screen. The
// arithmetic that applies it speaks this unit, the audit entry records it, and
// a conversion in the middle is the one place a rate could arrive at the
// browser meaning something else. The screen divides by a hundred to draw it
// and multiplies to send it, in one function each, and says so.
type Discount struct {
	Method      string
	BasisPoints int
	From        time.Time
}

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

	/* ---------- and what comes off for paying a cheaper way ----------

	   IT IS ON `Plan` AND NOT ON A SEAM OF ITS OWN, because it is the same
	   subject: what this platform asks for a subscription. The screen draws
	   both, one write records both the same way, and a second struct would be
	   two things to wire for one question.

	   THE SHAPE IS THE PRICE'S EXACTLY — appended, dated, answering what it
	   replaced — for the reason `0045` gives: a rate that was live for a
	   fortnight and sold nothing leaves no trace in any sale, and that
	   fortnight is what somebody asks about. */

	// SetDiscount appends a rate for a method and answers the one it replaces.
	// A zero `was` is a method that had no discount, which is a real state.
	SetDiscount func(ctx context.Context, method string, basisPoints int) (was Discount, err error)

	// DiscountInForce is what comes off right now, read before the write so the
	// audit entry can name both sides. A zero is a method nobody has discounted
	// — which is not an error: it is sold at the price.
	DiscountInForce func(ctx context.Context, method string) (Discount, error)

	// Discounts is the whole series, newest first, every method together.
	Discounts func(ctx context.Context) ([]Discount, error)

	// RefusedDiscount is a rate the caller can fix by sending another: nothing
	// off, more than half off, a method this platform does not take.
	RefusedDiscount func(error) bool
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
	mux.HandleFunc("PUT /console/api/v1/plan/discount", h.setDiscount)
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
		/* NO REASON ON THIS ONE YET, and it is the write that most deserves
		   one — "why is the year twenty reais dearer since June" is exactly
		   the question this log should answer. The screen does not ask for a
		   sentence, and inventing one here would be the console explaining a
		   decision it did not make. Adding the field to that form is a change
		   to that screen and belongs with it. */
		"",
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

/*
SETTING A DISCOUNT IS APPENDING TO A SERIES, exactly as a price is.

	SAVING THE SAME RATE AGAIN IS STILL A NEW ROW, for the price's reason: it
	records that this is still what we take off, as of today, and a series that
	dropped the repeats could not tell that from a rate nobody has touched.

	THE CEILING IS NOT HERE. `billing.MostBasisPoints` is a fence against a typed
	digit — 5000 where 500 was meant — and a fence somebody can move from a
	screen is a fence in the way rather than a fence. The store refuses and its
	sentence comes back verbatim.
*/
func (h *PlanHandler) setDiscount(w http.ResponseWriter, r *http.Request) {
	if !h.maySet(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"changing what comes off a payment asks for an operator")
		return
	}

	var asked struct {
		Method      string `json:"method"`
		BasisPoints int    `json:"basisPoints"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<10)).Decode(&asked); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}
	method := strings.ToLower(strings.TrimSpace(asked.Method))

	actor, label, ok := acting(w, r, h.who, h.label)
	if !ok {
		return
	}

	was, err := h.plan.DiscountInForce(r.Context(), method)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the discount in force",
			"error", err, "method", method)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	if err := h.record(r.Context(), actor, label,
		"plan.discount.changed",
		/* THE SUBJECT IS THE METHOD, as a price's is the term: it is the whole
		   of what distinguishes one of these rows from another while the scope
		   stays `all`. */
		Subject{Kind: "plan", ID: method},
		Changed{Before: rate(was.BasisPoints), After: rate(asked.BasisPoints)},
		// No reason asked for, as on the price beside it — and the same comment
		// applies: it is a change to that form rather than to this handler.
		"",
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a discount change", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return
	}

	before, err := h.plan.SetDiscount(r.Context(), method, asked.BasisPoints)
	switch {
	case h.plan.RefusedDiscount != nil && h.plan.RefusedDiscount(err):
		web.Fail(w, http.StatusBadRequest, "not_a_discount", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("setting the discount", "error", err, "method", method)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}
	if before.BasisPoints != was.BasisPoints {
		web.LoggerFrom(r.Context()).Warn("a discount moved under a change",
			"method", method,
			"recorded_before", rate(was.BasisPoints),
			"actually_was", rate(before.BasisPoints))
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"method":      method,
		"basisPoints": asked.BasisPoints,
	})
}

/*
A RATE AS THE AUDIT RECORDS IT, in basis points and saying so. The entry is

	read a year later beside a checkout row, and "500" alone is a number somebody
	has to be told the unit of — the same argument `money` beside it makes for
	writing cents in cents.
*/
func rate(basisPoints int) string {
	if basisPoints <= 0 {
		return "nothing"
	}
	return strconv.Itoa(basisPoints) + " basis points"
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
	/* AND THE DISCOUNTS, IN THE SAME ANSWER. They are the same subject — what
	   this platform asks for a subscription — drawn on the same screen, and two
	   requests for one page would be two chances to draw half of an offer.

	   A FAILURE HERE COSTS THE DISCOUNTS AND NOT THE PRICES. Somebody opening
	   this screen is nearly always here about a price; refusing the whole page
	   because a second series could not be read would be trading the answer for
	   the footnote. It comes back absent and the screen says it could not read
	   them. */
	off, err := h.plan.Discounts(r.Context())
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the discounts", "error", err)
		off = nil
	}
	discounts := make([]map[string]any, 0, len(off))
	for _, one := range off {
		discounts = append(discounts, map[string]any{
			"method":      one.Method,
			"basisPoints": one.BasisPoints,
			"from":        one.From,
		})
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"prices":    out,
		"discounts": discounts,

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
