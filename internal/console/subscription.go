package console

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
What an operator can DO about a subscription, as opposed to read.

# THE CONSOLE COULD SEE EVERYTHING AND CHANGE NOTHING

The record screen learned to show what somebody is paying for and everything
they have ever bought. It could not act on any of it. So every conversation
that ends in "we will sort that out for you" ended, in fact, at a SQL client —
which is the same power with no audit, no second rank, and no record of who did
it or why.

Three things happen here. A fourth — asking the gateway for a refund — is not
in this file, because it is the only one that moves real money out of a real
account, and it belongs with the code that talks to the gateway.

	extend    give time nobody paid for: an outage, a fortnight lost to support
	cancel    stop the renewal notices; the paid term is still honoured
	adjust    a line in the ledger for money that moved outside the gateway

# EACH ONE ASKS WHY, AND WILL NOT PROCEED WITHOUT AN ANSWER

`before` and `after` say what changed and can never say what for. Two dates do
not explain sixty free days, and an amount does not explain itself at all. The
reason is required by the handler rather than encouraged by the screen, because
a field a form asks for politely is a field that is empty in the rows that
matter.

# AND EACH IS RECORDED BEFORE IT IS DONE

`plan.go`'s rule, and it is the right way round: a change nobody can account for
is worse than a change that did not happen. If the audit write fails, the act is
refused and the operator is told so — the alternative is a history that omits
exactly the events somebody went looking for.

# WHAT IS DELIBERATELY NOT HERE

GIVING A SUBSCRIPTION TO SOMEBODY WHO HAS NEVER HAD ONE. `extend` adds to a term
that exists; it cannot conjure one, because a subscription has to say what it
was sold at and there is no honest number for one nobody bought. Comping a
person is an offer priced at zero, which is a different thing and should look
like one.

CHANGING WHAT SOMEBODY PAYS. There is one price series for the platform (N-02,
`0041`), and a per-person price is the arbitrage that decision exists to
prevent. An operator who wants to charge one person less writes an adjustment,
which says out loud that it is a one-off.
*/

/*
ErrNotAllowedThere is a change the billing rules will not make — cancelling
something that is already over, most of all.

	IT IS NOT `ErrRefused`, which this package already has and which belongs to
	the audit screen: that one is a QUESTION the console will not ask the
	database. This is an ANSWER from the state machine, arriving after the
	question was perfectly reasonable, and the two land on an operator's screen
	as different sentences.

	IT IS A 400 AND NOT A 500. The rules refusing is not a fault to log at
	three in the morning; it is the system telling somebody that the thing they
	asked for does not apply to this subscription, which is information they can
	act on.
*/
var ErrNotAllowedThere = errors.New("console: the billing rules refuse that")

/*
Subscriptions is what this package may not import.

	`billing` owns the state machine and the ledger, and a console that imported
	it would be the module boundary broken by the package with the best excuse
	(X-02). So it names three functions and `cmd/api` says who provides them —
	the same arrangement `Records` and `Plan` use.

	EACH ANSWERS THE NEW STANDING, not just an error. The screen redraws from
	what comes back rather than asking again, so an operator sees the row they
	just changed and not the row as it was when the page loaded.
*/
type Subscriptions struct {
	/* Held is what they have now, read before every change so the audit entry
	   can name what it replaced.

	   IT IS THE SAME FUNCTION `Records.Holding` IS. One reading of a
	   subscription, wired once in `cmd/api` and handed to both — a second
	   would be a second answer to "what does this person hold", and the two
	   screens showing different ones is how an operator ends up arguing with a
	   student about a date. */
	Held func(ctx context.Context, accountID uuid.UUID) (Holding, error)

	// Extend adds days to a term that already exists, and answers what it
	// became.
	Extend func(ctx context.Context, accountID uuid.UUID, days int) (Holding, error)

	// Cancel stops the renewal notices and honours the paid term.
	Cancel func(ctx context.Context, accountID uuid.UUID) (Holding, error)

	// Adjust writes one line in the ledger. `cents` is signed: a credit to the
	// student is negative, because the ledger counts what they paid us.
	Adjust func(ctx context.Context, accountID uuid.UUID, cents int, currency, memo string) error
}

// SubscriptionHandler is the three writes.
type SubscriptionHandler struct {
	people People
	subs   Subscriptions
	record Record
	label  Label
	who    func(ctx context.Context) (uuid.UUID, bool)

	// mayChange is the second rank, as `mayErase` is on the people screen.
	// Read-only opened the door; giving away months and writing money into the
	// ledger is not a thing a read-only role does.
	mayChange func(ctx context.Context) bool
}

func NewSubscriptionHandler(people People, subs Subscriptions, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	mayChange func(ctx context.Context) bool,
) *SubscriptionHandler {
	return &SubscriptionHandler{
		people: people, subs: subs, record: record, label: label,
		who: who, mayChange: mayChange,
	}
}

func (h *SubscriptionHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /console/api/v1/people/{id}/subscription/extend", h.extend)
	mux.HandleFunc("POST /console/api/v1/people/{id}/subscription/cancel", h.cancel)
	mux.HandleFunc("POST /console/api/v1/people/{id}/ledger/adjustment", h.adjust)
}

/*
mostDays is the ceiling on one grant.

	A CEILING AND NOT A CONFIRMATION DIALOGUE. The mistake this exists for is a
	typed zero — 3650 where 365 was meant, or 60 where 6 was — and a dialogue
	asking "are you sure" is answered yes by the same reflex that typed the
	number. Ten years of access given by a slipped finger is not recoverable by
	anything except another grant in the opposite direction, which does not
	exist.

	A YEAR IS THE MOST ANY CONVERSATION NEEDS. Somebody who genuinely means to
	give more than that can do it twice, and the second entry in the audit is
	the record that they meant it.
*/
const mostDays = 366

// mostCents is the ceiling on one adjustment, in either direction. The same
// argument: the error this catches is an amount typed in reais where the field
// wants cents, which is a hundredfold and lands here.
const mostCents = 5_000_00

type askedFor struct {
	// Why is required on every one of these. See the file header.
	Why string `json:"why"`

	Days int `json:"days"`

	Cents    int    `json:"cents"`
	Currency string `json:"currency"`
}

// read is the body, the rank, the person, and the reason — the four things
// every route here needs before it may do anything.
func (h *SubscriptionHandler) read(w http.ResponseWriter, r *http.Request) (Person, askedFor, bool) {
	if !h.mayChange(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"changing what somebody holds asks for an operator")
		return Person{}, askedFor{}, false
	}

	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such person")
		return Person{}, askedFor{}, false
	}

	var in askedFor
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return Person{}, askedFor{}, false
	}
	in.Why = strings.TrimSpace(in.Why)
	if in.Why == "" {
		web.Fail(w, http.StatusBadRequest, "no_reason",
			"say why: this is written down, and a change nobody can account for is "+
				"worse than one that did not happen")
		return Person{}, askedFor{}, false
	}

	/* THE PERSON IS READ BEFORE ANYTHING IS DONE TO THEM, so an id belonging to
	   nobody is a 404 rather than a change written against a uuid. */
	person, err := h.people.ByID(r.Context(), id)
	switch {
	case errors.Is(err, ErrNoPerson):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such person")
		return Person{}, askedFor{}, false
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a person", "error", err, "account", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return Person{}, askedFor{}, false
	}
	return person, in, true
}

// wrote records the act. It answers false having already written the refusal,
// exactly as `PeopleHandler.wrote` does and for the same reason.
func (h *SubscriptionHandler) wrote(w http.ResponseWriter, r *http.Request,
	action string, subject uuid.UUID, what Changed, why string) bool {

	actor, ok := h.who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return false
	}

	name, email, err := h.label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return false
	}

	if err := h.record(r.Context(), actor, strings.TrimSpace(name+" <"+email+">"), action,
		Subject{Kind: "account", ID: subject.String()}, what, why,
		web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a change to a subscription",
			"error", err, "action", action)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return false
	}
	return true
}

/*
extend gives time nobody paid for.

	THE ENTRY NAMES BOTH DATES AND NOT THE NUMBER OF DAYS. "60 days" a year
	later is a quantity somebody has to do arithmetic on against a term they no
	longer have in front of them; "ran to 3 March, now runs to 2 May" is the
	fact, and it is what a person reviewing this actually wants to see.
*/
func (h *SubscriptionHandler) extend(w http.ResponseWriter, r *http.Request) {
	person, in, ok := h.read(w, r)
	if !ok {
		return
	}
	if in.Days < 1 || in.Days > mostDays {
		web.Fail(w, http.StatusBadRequest, "not_a_term",
			"give between one day and a year — more than that is two grants and "+
				"two lines in the history saying you meant it")
		return
	}

	/* WHAT IT WAS, READ BEFORE THE CHANGE so the entry can name it. A failure
	   here is a refusal: an entry whose `before` is a guess is worse than no
	   entry, because it reads as a fact. */
	was, ok := h.holding(w, r, person, "nothing_to_extend",
		"they have no subscription to extend. Giving somebody a term is not this — "+
			"it has to say what it was sold at, and there is no honest answer for one "+
			"nobody bought")
	if !ok {
		return
	}

	if !h.wrote(w, r, "subscription.extended", person.ID, Changed{
		Before: runsTo(was.PaidThrough),
		After:  runsTo(plus(was.PaidThrough, in.Days)),
	}, in.Why) {
		return
	}

	held, err := h.subs.Extend(r.Context(), person.ID, in.Days)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("extending a subscription",
			"error", err, "account", person.ID, "days", in.Days)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}
	web.JSON(w, http.StatusOK, shownHolding(held))
}

/*
cancel stops the renewal notices.

	IT DOES NOT TAKE ACCESS AWAY AND THE ANSWER SAYS SO. Every purchase here is
	a term bought outright, so a cancellation honours what was paid for and ends
	when it ends — which surprises people who expect "cancel" to mean "stop
	now". What actually changes today is that nothing will write to them about
	renewing, and that is worth having: the alternative is somebody who has said
	they are leaving being reminded twice more that they are about to.
*/
func (h *SubscriptionHandler) cancel(w http.ResponseWriter, r *http.Request) {
	person, in, ok := h.read(w, r)
	if !ok {
		return
	}

	was, ok := h.holding(w, r, person, "nothing_to_cancel",
		"they have no subscription to cancel")
	if !ok {
		return
	}

	if !h.wrote(w, r, "subscription.cancelled", person.ID, Changed{
		Before: was.State,
		After:  "cancelled, honoured to " + runsTo(was.PaidThrough),
	}, in.Why) {
		return
	}

	held, err := h.subs.Cancel(r.Context(), person.ID)
	switch {
	case errors.Is(err, ErrNotAllowedThere):
		/* THE RECORD STANDS AND THE CHANGE DID NOT, which is the honest way
		   round: the entry says an operator asked, and this says the billing
		   rules would not. A cancellation of something already over is the case
		   — and an operator reading "it is already ended" has their answer. */
		web.Fail(w, http.StatusBadRequest, "refused", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("cancelling a subscription",
			"error", err, "account", person.ID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}
	web.JSON(w, http.StatusOK, shownHolding(held))
}

/*
adjust writes one line in the ledger for money that moved outside the gateway.

	IT IS THE ESCAPE HATCH AND IT IS SUPPOSED TO LOOK LIKE ONE. Everything the
	other routes do is a shape this system understands; this is the one that
	says "something happened that none of those describe" — a bank transfer, a
	write-off, a goodwill credit, an amount keyed wrongly by somebody once.

	THE SIGN IS THE CALLER'S AND THE SCREEN EXPLAINS IT. The ledger counts what
	a student paid us, so a credit TO them is negative. Getting that backwards
	is the mistake this route can least afford, which is why the entry names the
	direction in words as well as in a number.

	NOTHING IS TOLD TO THE GATEWAY. No money moves because of this row: it
	records that money moved, somewhere else, and an adjustment written in the
	belief that it would refund somebody would be a lie in the books AND a
	student still out of pocket. The refund route is what asks the gateway.
*/
func (h *SubscriptionHandler) adjust(w http.ResponseWriter, r *http.Request) {
	person, in, ok := h.read(w, r)
	if !ok {
		return
	}

	currency := strings.ToUpper(strings.TrimSpace(in.Currency))
	switch {
	case in.Cents == 0:
		web.Fail(w, http.StatusBadRequest, "nothing_moved",
			"an adjustment of nothing is not a correction")
		return
	case in.Cents > mostCents || in.Cents < -mostCents:
		web.Fail(w, http.StatusBadRequest, "too_much",
			"that is more than one adjustment should be. If it is right, it is two")
		return
	case len(currency) != 3:
		web.Fail(w, http.StatusBadRequest, "not_a_currency", "say which currency, in three letters")
		return
	}

	if !h.wrote(w, r, "ledger.adjusted", person.ID, Changed{
		After: direction(in.Cents) + " " + money(abs(in.Cents), currency),
	}, in.Why) {
		return
	}

	/* THE REASON IS THE MEMO TOO, and it is the one place in this file where
	   the same sentence is written twice on purpose. The audit answers "who
	   did this and why"; the ledger answers "what is this row" to somebody
	   reading the books who has no reason to know a console exists. */
	if err := h.subs.Adjust(r.Context(), person.ID, in.Cents, currency, in.Why); err != nil {
		if errors.Is(err, ErrNotAllowedThere) {
			web.Fail(w, http.StatusBadRequest, "refused", err.Error())
			return
		}
		web.LoggerFrom(r.Context()).Error("writing an adjustment",
			"error", err, "account", person.ID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the change was recorded and then could not be written, which is a defect — "+
				"the history now says something happened that did not")
		return
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"cents":     in.Cents,
		"currency":  currency,
		"direction": direction(in.Cents),
	})
}

/*
holding is what they have now, or a refusal already written.

	A SUBSCRIPTION NOBODY HAS IS A 400 AND NOT A 404. The person exists — they
	were just read — and the route was reached correctly; what is missing is the
	thing being changed, and "no such person" would send an operator looking for
	a typo in an id they pasted from the screen in front of them.

	AN EMPTY STATE IS HOW `holdingOf` SAYS NOBODY EVER SUBSCRIBED. It answers a
	zero value rather than an error, because on the record screen that is the
	ordinary case and not a fault; here it is the one thing that stops a change,
	so it is turned into a refusal at the boundary rather than being carried
	further in as a shape every caller has to remember to check.
*/
func (h *SubscriptionHandler) holding(w http.ResponseWriter, r *http.Request,
	person Person, code, say string) (Holding, bool) {

	held, err := h.subs.Held(r.Context(), person.ID)
	switch {
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a subscription before changing it",
			"error", err, "account", person.ID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return Holding{}, false
	case held.State == "":
		web.Fail(w, http.StatusBadRequest, code, say)
		return Holding{}, false
	}
	return held, true
}

/* ---------- saying it in words ---------- */

// direction is which way the money went, spelled out. The sign alone is the
// thing an operator gets backwards at four in the afternoon.
func direction(cents int) string {
	if cents < 0 {
		return "credited to them"
	}
	return "charged to them"
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

// runsTo is a date in the audit, and `never` for a subscription with none —
// which cannot happen through these routes and would be a silent zero if it
// ever did.
func runsTo(when *time.Time) string {
	if when == nil {
		return "never"
	}
	return when.Format(time.DateOnly)
}

func plus(when *time.Time, days int) *time.Time {
	if when == nil {
		return nil
	}
	/* FROM THE LATER OF TODAY AND THE END, which is the store's rule and is
	   copied here only to NAME it in the entry. The store does the arithmetic
	   that counts, inside the transaction that locks the row; this is the
	   prediction, and the two agreeing is what the handler's test holds. */
	from := *when
	if now := time.Now(); from.Before(now) {
		from = now
	}
	moved := from.AddDate(0, 0, days)
	return &moved
}
