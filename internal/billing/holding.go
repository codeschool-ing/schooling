package billing

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
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
}

// NewHolding is the read side over the three stores it joins.
func NewHolding(plans *Store, prices *Prices, buys *Checkouts,
	who func(context.Context) (uuid.UUID, bool)) *Holding {

	return &Holding{plans: plans, prices: prices, buys: buys, who: who}
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

	/* EVERY PURCHASE, INCLUDING THE ONES THAT ARE NOT SUBSCRIPTIONS. It is
	   never omitted: a screen that gets no key cannot tell "this person has
	   bought nothing" from "this version does not send it", and an empty array
	   says the first out loud. */
	Purchases []purchaseBody `json:"purchases"`
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
	   Somebody with no subscription may still have purchases — a checkout that
	   errored before the gateway, a Pix code that expired unpaid — and those are
	   exactly the rows they write in about. Reading this after the early return
	   below would have hidden them from the only people who need them. */
	bought, err := h.buys.Purchases(r.Context(), accountID)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading what somebody has bought",
			"error", err, "account", accountID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"could not read your subscription")
		return
	}
	purchases := shownPurchases(bought)

	held, err := h.plans.Of(r.Context(), accountID, ScopeEverything, time.Now())
	switch {
	case errors.Is(err, ErrNoSubscription):
		/* NOBODY HAS BOUGHT ANYTHING, WHICH IS A 200. A 404 here would make the
		   ordinary case — every student who has not subscribed — look like a
		   broken address, and a screen cannot tell one from the other without
		   reading the code that produced it. */
		web.JSON(w, http.StatusOK, holdingBody{State: "none", Purchases: purchases})
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

// shownPurchases is the list as it goes out. It is never nil: see `Purchases`
// on the body.
func shownPurchases(bought []Purchase) []purchaseBody {
	out := make([]purchaseBody, 0, len(bought))
	for _, p := range bought {
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
