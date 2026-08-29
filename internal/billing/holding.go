package billing

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"

	"github.com/codeschool-ing/schooling/internal/platform/setting"
)

/*
What somebody holds, told to them.

# NOTHING COULD ANSWER THIS UNTIL NOW

This module had exactly one route — `POST /api/v1/checkout` — so a subscription
could be BOUGHT and never READ. The interface learned that somebody had access
the only way it could: by asking for a locked course and being refused. It never
learned what they had, when it ends, or what they paid.

A student who cannot see the term they bought cannot check it against what they
were charged, cannot tell a week before it lapses that it is about to, and has
nowhere to look when a course stops opening. Every one of those becomes a
message to somebody, and this platform has nobody to answer it (N-05).

# IT IS ITS OWN HANDLER AND NOT A ROUTE ON THE OTHER ONE

`Handler` above is mounted only where there is a gateway key, which is right for
buying: "no key, no route — a deployment that cannot take money must offer
nobody a way to try". Reading is not buying. A deployment whose key has been
pulled must still tell its existing subscribers what they hold, and putting this
route behind that condition would take the answer away exactly when it matters
most.

# IT SAYS WHAT WILL HAPPEN, WHICH IS NOT WHAT PEOPLE ASSUME

Every purchase on this platform is `ModelInstalments` — a term is bought, and at
its end there is a new sale. Nothing renews itself, because nothing creates a
subscription at the gateway. Somebody who assumes a subscription renews and
finds it stopped is somebody who lost access without being told, so the answer
carries the model and the screen says the consequence out loud.
*/

// Holding is the read side of a subscription: this handler answers what
// somebody has, and never changes it.
type Holding struct {
	plans  *Store
	prices *Prices

	/* AND THE CHECKOUTS, WHICH ARE THE HISTORY. The subscription says what is
	   true today; a person opening this screen is usually asking about a year
	   they have already paid for, and the state has by then been overwritten
	   several times. `Checkouts` given no `Confirmed` cannot open anything —
	   the same wiring the webhook uses — so this handler can read every
	   purchase and start none. */
	buys *Checkouts

	// who answers which account is asking, wired by `cmd` — the same seam
	// `Handler.payer` uses, without the name and address it does not need.
	who func(context.Context) (uuid.UUID, bool)

	/* support is where somebody writes to use the seven days. Empty is allowed
	   and the screen then names the deadline without an address — see
	   `config.SupportEmail`.

	   IT IS A FUNCTION BECAUSE THE VALUE CAN BE CHANGED WHILE THE PROCESS RUNS.
	   It was a string read once from the environment, which meant the address
	   only moved with a new revision of the service; `0044` puts it in a row an
	   operator sets from the console, and a value captured at start-up would
	   make that form a control whose effect arrives at the next deployment.

	   `cmd` wires the fallback into it — the row, and the environment variable
	   when there is no row — so this package still knows nothing about where
	   the answer came from. It takes a context so the read can be cancelled
	   with the request it belongs to, and it swallows its own failure: a
	   database that cannot answer costs the notice its address, not the
	   screen. */
	support func(context.Context) string

	/* window is how many days somebody has to change their mind, asked per
	   request because `0046` made it a declared parameter. A number captured
	   when this handler was built would tell a buyer one deadline while the
	   terms of use printed another — the two are generated from this one
	   value precisely so that cannot happen. */
	window func(context.Context) int
}

// NewHolding is the read side over the three stores it joins.
func NewHolding(plans *Store, prices *Prices, buys *Checkouts,
	who func(context.Context) (uuid.UUID, bool),
	support func(context.Context) string,
	window func(context.Context) int) *Holding {

	return &Holding{plans: plans, prices: prices, buys: buys, who: who,
		support: support, window: window}
}

// days is the window in force, bounded by the declaration however it is wired.
//
// AN UNWIRED ONE IS SEVEN, which is the statutory minimum and the number this
// package shipped with. It is also the only safe end of the mistake: a
// deployment that forgot to wire this must not publish a window shorter than
// the law gives, and seven is what the law gives.
func (h *Holding) days(ctx context.Context) int {
	if h.window == nil {
		return WithdrawalDays.Fallback
	}
	if got := h.window(ctx); WithdrawalDays.Valid(got) == nil {
		return got
	}
	return WithdrawalDays.Fallback
}

/*
WithdrawalDays is how long somebody has to change their mind.

	ART. 49 OF THE CÓDIGO DE DEFESA DO CONSUMIDOR. A purchase made at a distance
	may be withdrawn from within seven days of contracting, for the whole amount,
	with no reason given. It is not ours to narrow.

	THE OLD COMMENT SAID "IT IS SEVEN BECAUSE THE LAW SAYS SEVEN", AND THAT IS
	HALF OF IT. The law says SEVEN AT LEAST. Nothing stops this platform giving
	fourteen, or thirty; what it may never do is give six. So the statute is the
	FENCE and not the value — `Least` is 7 and no console can move it — and how
	much more than the minimum to offer is a commercial position with no right
	answer, which is exactly K-13's bar. A longer window is a thing a school
	competes on, and it costs whatever the refunds cost.

	THE TERMS OF USE ARE GENERATED FROM THIS, which is the half that makes it
	safe to move. They used to say "sete dias" in words, so a platform that
	offered fourteen would publish a promise of seven and honour something else
	— two numbers for one fact, in the document whose entire job is to be the
	number. `{{withdrawal.days}}` is now substituted at serve time from this
	same value, and `legal` fails a token nothing fills.

	WHAT THE DOCUMENT STILL SAYS IN WORDS is the statute: the Code guarantees
	seven, that is the minimum, and we never offer less. That sentence is true
	at every value this may take, which is what let the number beside it move.

	IT IS COUNTED FROM WHEN THE PURCHASE WAS PAID and not from when the checkout
	was opened. A Pix code paid three days after it was generated is contracted
	on the day it was paid, and counting from the click would quietly eat three
	of somebody's seven.

	AND IT IS COMPUTED HERE RATHER THAN ON THE SCREEN. A deadline worked out in a
	browser is a deadline held by a clock the person can set, and this one has a
	legal meaning. The screen draws what this decides.
*/
var WithdrawalDays = setting.Declared{
	Name:     "billing.withdrawaldays",
	Unit:     setting.Days,
	Least:    7,
	Most:     90,
	Fallback: 7,
	Why: "how long somebody has to change their mind. Art. 49 of the Código de Defesa do " +
		"Consumidor gives seven days for a purchase made at a distance and that is a floor " +
		"rather than an answer — `Least` is 7 so no console can narrow it, and how far above " +
		"the minimum to go is a commercial position: a longer window is something a school " +
		"competes on and it costs whatever the refunds cost. The terms of use print this " +
		"number rather than spelling one out, so the promise and the behaviour cannot part.",
}

func (h *Holding) Routes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/subscription", h.mine)
}

/*
holdingBody is what a subscriber is told.

	THE PRICE IS RESOLVED AND NOT THE ID. `Held.PriceID` is a handle this module
	stores and hands back; a screen cannot draw a UUID. It is looked up here, so
	the amount somebody sees is the row they bought at rather than whatever is
	current — which is the whole reason the column exists.
*/
type holdingBody struct {
	// State is `none` when there is no subscription at all, which is a state the
	// screen draws and not an error. Every other value is the store's own.
	State string `json:"state"`

	// Opens is the paywall's answer, computed here so that no interface has to
	// know which states open anything. `grace` opens and `suspended` does not,
	// and that is not obvious from the name of either.
	Opens bool `json:"opens"`

	Scope string `json:"scope,omitempty"`

	// Model is how it was bought, and it is sent because the CONSEQUENCE differs:
	// an instalment plan ends and a recurring one charges again.
	Model string `json:"model,omitempty"`

	Since       *time.Time `json:"since,omitempty"`
	PaidThrough *time.Time `json:"paidThrough,omitempty"`

	Price *holdingPrice `json:"price,omitempty"`

	/* EVERY PURCHASE THAT REACHED THE GATEWAY — paid, waiting, or given up on.
	   A checkout that never got that far is a click and not a purchase, and
	   `shownPurchases` says why it is left out here and kept in the console.

	   IT IS NEVER OMITTED: a screen that gets no key cannot tell "this person
	   has bought nothing" from "this version does not send it", and an empty
	   array says the first out loud. */
	Purchases []purchaseBody `json:"purchases"`

	/* Withdraw is present ONLY while the seven days are still running, which is
	   the whole design of it: a right somebody still has is worth a sentence on
	   the screen, and a right that has expired is a sentence that invites a
	   message nobody can answer (N-05). Absent means "nothing is owed to you
	   here", and the screen says nothing rather than something useless. */
	Withdraw *withdrawBody `json:"withdraw,omitempty"`
}

/*
withdrawBody is the seven days, while they last.

	IT CARRIES THE DEADLINE AND NOT THE DAYS LEFT. "3 days left" computed here
	is stale the moment the page sits open overnight; a date is true whenever it
	is read, and the screen can count down from it if it wants to.
*/
type withdrawBody struct {
	Until time.Time `json:"until"`

	// Email is empty where the deployment has configured none. The deadline is
	// still worth saying; see `config.SupportEmail`.
	Email string `json:"email,omitempty"`
}

// holdingPrice is what was paid, for how long.
type holdingPrice struct {
	TermMonths int    `json:"termMonths"`
	Cents      int    `json:"cents"`
	Currency   string `json:"currency"`
}

/*
purchaseBody is one line of the history.

	IT SENDS THE LISTED PRICE BESIDE WHAT WAS CHARGED rather than the discount
	between them. The subtraction is presentation — a screen may show "R$ 690,00
	less 5% in Pix" or "you saved R$ 34,50" or neither — and a server that sent
	only the difference would have decided that for it, in a place no designer
	looks.
*/
type purchaseBody struct {
	ID string `json:"id"`

	OpenedAt time.Time `json:"openedAt"`
	MovedAt  time.Time `json:"movedAt"`

	// Stage is `opened`, `charged`, `paid` or `abandoned` — how far it got, and
	// NOT whether it opens anything. See `0042`: that word is the subscription's.
	Stage string `json:"stage"`

	Cents      int    `json:"cents"`
	Listed     int    `json:"listed"`
	Currency   string `json:"currency"`
	TermMonths int    `json:"termMonths"`

	Method      string `json:"method"`
	Instalments int    `json:"instalments"`

	// InvoiceURL is where the payer was sent, and is worth sending back for a
	// `charged` row: it is a Pix code somebody may still be about to pay.
	InvoiceURL string `json:"invoiceUrl,omitempty"`

	// PaidThrough is where the term stood after this purchase, absent when it
	// bought nothing or when it predates the log recording it.
	PaidThrough *time.Time `json:"paidThrough,omitempty"`
}

func (h *Holding) mine(w http.ResponseWriter, r *http.Request) {
	accountID, ok := h.who(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	/* THE HISTORY IS READ FIRST, BECAUSE IT SURVIVES THE ABSENCE OF THE REST.
	   Somebody with no subscription may still have purchases — a Pix code that
	   expired unpaid, a sale that was refunded — and those are exactly the rows
	   they write in about. Reading this after the early return below would have
	   hidden them from the only people who need them. */
	bought, err := h.buys.Purchases(r.Context(), accountID)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading what somebody has bought",
			"error", err, "account", accountID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"could not read your subscription")
		return
	}
	purchases := shownPurchases(bought)
	withdraw := h.withdrawable(r.Context(), bought)

	held, err := h.plans.Of(r.Context(), accountID, ScopeEverything, time.Now())
	switch {
	case errors.Is(err, ErrNoSubscription):
		/* NOBODY HAS BOUGHT ANYTHING, WHICH IS A 200. A 404 here would make the
		   ordinary case — every student who has not subscribed — look like a
		   broken address, and a screen cannot tell one from the other without
		   reading the code that produced it. */
		/* AND THE SEVEN DAYS EVEN HERE. Somebody whose only subscription was
		   refunded has no state and may still be inside the window on a LATER
		   purchase — and somebody who bought minutes ago is in this branch for
		   as long as the webhook takes to arrive. Dropping it would take the
		   right away in exactly the seconds it is newest. */
		web.JSON(w, http.StatusOK, holdingBody{
			State: "none", Purchases: purchases, Withdraw: withdraw})
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a subscription",
			"error", err, "account", accountID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"could not read your subscription")
		return
	}

	body := holdingBody{
		State:     string(held.State),
		Opens:     Opens(held.Subscription),
		Scope:     held.Scope,
		Model:     string(held.Model),
		Purchases: purchases,
		Withdraw:  withdraw,
	}
	if !held.StartedAt.IsZero() {
		body.Since = &held.StartedAt
	}
	if !held.PaidThrough.IsZero() {
		body.PaidThrough = &held.PaidThrough
	}

	/* AND WHAT IT COST, WHEN THE ROW IS STILL THERE. A price is never deleted —
	   the table is append-only — so this failing is a real fault rather than an
	   expected absence. It is logged and the rest of the answer goes out anyway:
	   somebody checking when their access ends should not be told nothing
	   because the amount could not be joined. */
	if held.PriceID != uuid.Nil {
		switch price, err := h.prices.ByID(r.Context(), held.PriceID); {
		case err != nil:
			web.LoggerFrom(r.Context()).Error("reading what a subscription was bought at",
				"error", err, "account", accountID, "price", held.PriceID)
		default:
			body.Price = &holdingPrice{
				TermMonths: price.TermMonths,
				Cents:      price.Cents,
				Currency:   price.Currency,
			}
		}
	}

	web.JSON(w, http.StatusOK, body)
}

/*
withdrawable is the window to change your mind, if it is still running.

	THE NEWEST PAID PURCHASE IS THE ONE THAT COUNTS. Somebody who bought a year
	in March and renewed in December has a fresh window on the December sale,
	and the March one is long gone — so this looks for the latest, not the first.
	`Purchases` answers newest first, so the first paid row is it.

	A REFUNDED PURCHASE OPENS NO WINDOW, and skipping it rather than stopping at
	it is deliberate. A refund does not move the stage — the checkout got all the
	way — so without this the screen would tell somebody who has just used the
	seven days that they have until Tuesday to use them. That is the SUCCESS path
	of this feature reading as though nothing had happened.

	It is skipped and not treated as the end of the search, because the purchase
	under it may be a live one: somebody who renewed, changed their mind about
	the renewal and got it back still holds the term they bought last year, and
	that term's own seven days are long gone anyway.
*/
func (h *Holding) withdrawable(ctx context.Context, bought []Purchase) *withdrawBody {
	for _, p := range bought {
		if p.Stage != StagePaid || p.Refunded {
			continue
		}
		until := p.MovedAt.AddDate(0, 0, h.days(ctx))
		if !time.Now().Before(until) {
			return nil
		}

		/* THE ADDRESS IS READ ONLY WHEN THERE IS A NOTICE TO PUT IT ON, which
		   is why this is here and not beside the other reads above. Almost
		   nobody is inside the seven days, so almost every draw of this screen
		   costs nothing — and the read that does happen is one row by primary
		   key. */
		return &withdrawBody{Until: until, Email: h.support(ctx)}
	}
	return nil
}

// shownPurchases is the list as it goes out. It is never nil: see `Purchases`
// on the body.
func shownPurchases(bought []Purchase) []purchaseBody {
	out := make([]purchaseBody, 0, len(bought))
	for _, p := range bought {
		/* A CLICK THAT NEVER REACHED THE GATEWAY IS NOT A PURCHASE, and showing
		   it to the person who made it was a defect found by the first real card
		   sale on this platform.

		   THE TAX ID IS ASKED FOR AFTER THE ROW IS WRITTEN. `Handler.start`
		   opens the checkout first — because the row carries the confirmed-address
		   gate, and putting the gate anywhere else makes it forgettable — and only
		   then asks the gateway who this person is. Nobody buying for the first
		   time has a customer there yet, so the answer is `tax_id_required`, the
		   screen reveals the CPF field, and the row stays behind at `opened`.

		   That happens to EVERY first purchase. The student then saw two lines an
		   identical minute apart, one of them reading "not finished" beside the
		   one that worked — which looks like a payment that failed and is a
		   message to somebody this platform has nobody to answer with (N-05).

		   THE ROW ITSELF IS KEPT AND IS RIGHT TO BE. `0042` argues it: "somebody
		   who clicked and got an error", and an operator asked "I tried and
		   nothing happened" wants exactly that evidence. So the console shows
		   every row and this shows the ones that became something. The line is
		   whether the gateway was ever told.

		   IT IS THE STAGE AND NOT THE CHARGE ID that decides. They agree today —
		   an `opened` row has no charge — but a paid purchase whose charge id
		   somehow failed to store is a row a student must still see, and keying
		   on the id would hide the one line that matters most. */
		if p.Stage == StageOpened {
			continue
		}

		out = append(out, purchaseBody{
			ID:       p.ID.String(),
			OpenedAt: p.OpenedAt, MovedAt: p.MovedAt,
			Stage:      string(p.Stage),
			Cents:      p.Cents,
			Listed:     p.Listed,
			Currency:   p.Currency,
			TermMonths: p.TermMonths,
			Method:     string(p.Method), Instalments: p.Instalments,
			InvoiceURL: p.InvoiceURL, PaidThrough: p.PaidThrough,
		})
	}
	return out
}
