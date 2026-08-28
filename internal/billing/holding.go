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

	// who answers which account is asking, wired by `cmd` — the same seam
	// `Handler.payer` uses, without the name and address it does not need.
	who func(context.Context) (uuid.UUID, bool)
}

// NewHolding is the read side over the two stores it joins.
func NewHolding(plans *Store, prices *Prices,
	who func(context.Context) (uuid.UUID, bool)) *Holding {

	return &Holding{plans: plans, prices: prices, who: who}
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
}

// holdingPrice is what was paid, for how long.
type holdingPrice struct {
	TermMonths int    `json:"termMonths"`
	Cents      int    `json:"cents"`
	Currency   string `json:"currency"`
}

func (h *Holding) mine(w http.ResponseWriter, r *http.Request) {
	accountID, ok := h.who(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	held, err := h.plans.Of(r.Context(), accountID, ScopeEverything, time.Now())
	switch {
	case errors.Is(err, ErrNoSubscription):
		/* NOBODY HAS BOUGHT ANYTHING, WHICH IS A 200. A 404 here would make the
		   ordinary case — every student who has not subscribed — look like a
		   broken address, and a screen cannot tell one from the other without
		   reading the code that produced it. */
		web.JSON(w, http.StatusOK, holdingBody{State: "none"})
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a subscription",
			"error", err, "account", accountID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"could not read your subscription")
		return
	}

	body := holdingBody{
		State: string(held.State),
		Opens: Opens(held.Subscription),
		Scope: held.Scope,
		Model: string(held.Model),
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
