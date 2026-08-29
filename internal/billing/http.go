package billing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/google/uuid"
)

/*
Starting a payment, which is the one door money goes through.

# THE ORDER IS THE WHOLE OF IT

	1. the checkout is OPENED, which is where confirmation is checked
	2. the payer is registered at the gateway, or their handle is remembered
	3. the charge is created, carrying the checkout's id as its own reference
	4. the charge id is written back, and the payer is sent to the invoice

Each step is only reached when the one before it succeeded, and the row exists
before the gateway is called — so the failure of any of them is a checkout
nobody paid rather than an invoice nobody owns.

# THE GATEWAY IS A SET OF FUNCTIONS AND NOT AN IMPORT

`internal` modules do not import each other, and this one deliberately does not
import the provider either: `cmd` wires these to whatever gateway a deployment
has. It is the same arrangement `notify.Barred` and `console.Plan` use, and here
it earns its keep twice over — the second provider is a different wiring rather
than a rewrite of this file, which is exactly what ROADMAP.md asks for by
refusing to draw the abstraction before there are two.

# THE TAX ID PASSES THROUGH AND STOPS

Charging in Brazil needs a CPF or CNPJ. It arrives in the request, it goes to
the gateway, and it is not written down: `RememberCustomer` takes the handle
that comes back and has no argument for the number. The only thing this platform
keeps is a string that means something at one processor and nothing anywhere
else.

A SECOND PURCHASE DOES NOT ASK AGAIN. The handle is looked up first, and the
number is only wanted when there is none — so the field appears once in
somebody's life with us rather than at every renewal.
*/

// Gateway is what `cmd` wires a payment provider into.
type Gateway struct {
	// Name is what the provider is called in a row. It is stored, so it must
	// not change for a provider that already has charges under it.
	Name string

	/* NewCustomer registers a payer and answers the provider's handle.

	   THE TAX ID IS AN ARGUMENT AND IS NOT A FIELD ANYWHERE. It reaches the
	   provider and is dropped; what comes back is what gets written. */
	NewCustomer func(ctx context.Context, name, email, taxID string) (string, error)

	// NewCharge asks for one payment and answers its id and where the payer
	// goes. `reference` is the checkout's id, which comes back on every event.
	NewCharge func(ctx context.Context, in Charge) (id, invoiceURL string, err error)

	/* Refused says whether an error is the caller's to fix rather than an
	   outage. The provider's own words are NOT usable — its codes are generic
	   and its prose is in one language — so this answers a yes or no and the
	   sentence shown is ours. */
	Refused func(error) bool
}

// Charge is what the gateway is asked for.
type Charge struct {
	CustomerID  string
	Reference   string
	Cents       int64
	Currency    string
	Method      Method
	Instalments int
	Due         time.Time
	Describes   string
}

/*
chargeLife is how long a charge stays payable.

	SHORT, BECAUSE IT IS A PERSON WHO JUST CLICKED. Three days covers somebody
	who opens the page, decides to pay tomorrow, and forgets until the day after
	— and it stops short of a Pix code sitting in an inbox for a fortnight, being
	paid, and arriving against a price that has moved.
*/
const chargeLife = 3 * 24 * time.Hour

// Handler starts payments.
type Handler struct {
	checkouts *Checkouts
	prices    *Prices

	/* AND THE DISCOUNTS, WHICH USED TO BE A CONSTANT IN THIS FILE. `0045` makes
	   the rate a dated series like the price, so what comes off a Pix is read
	   here rather than compiled in — see `discount.go` for why it is dated and
	   not simply settable. */
	discounts *Discounts

	gateway Gateway

	// payer is who is buying, in the words the gateway wants. It is a
	// collaborator for the reason everything else here is: `identity` owns the
	// name and the address and this package may not read them.
	payer func(ctx context.Context) (accountID uuid.UUID, name, email string, ok bool)

	/* brand is what a card statement says the money went to.

	   IT IS PASSED IN BECAUSE THIS REPOSITORY HOLDS NO DOMAIN NAMES — see
	   `config.PlatformDomain`, which says it is the one place a domain appears.
	   It was written here as a literal first, which is exactly the drift that
	   comment exists to stop. */
	brand string
}

func NewHandler(checkouts *Checkouts, prices *Prices, discounts *Discounts, gateway Gateway,
	brand string, payer func(context.Context) (uuid.UUID, string, string, bool)) *Handler {

	return &Handler{
		checkouts: checkouts, prices: prices, discounts: discounts, gateway: gateway,
		brand: brand, payer: payer,
	}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/v1/checkout", h.start)
}

func (h *Handler) start(w http.ResponseWriter, r *http.Request) {
	accountID, name, email, ok := h.payer(r.Context())
	if !ok {
		web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
		return
	}

	var asked struct {
		TermMonths  int    `json:"termMonths"`
		Method      string `json:"method"`
		Instalments int    `json:"instalments"`
		TaxID       string `json:"taxId"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<12)).Decode(&asked); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}
	method := Method(strings.ToLower(strings.TrimSpace(asked.Method)))
	if asked.Instalments < 1 {
		asked.Instalments = 1
	}

	// WHAT IT COSTS COMES FROM THE SERIES AND NEVER FROM THE REQUEST. A price in
	// the body is a price the buyer chose.
	price, err := h.prices.InForce(r.Context(), ScopeEverything, asked.TermMonths)
	switch {
	case errors.Is(err, ErrNoOffer):
		web.Fail(w, http.StatusUnprocessableEntity, "no_offer",
			"that term is not for sale")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading the price in force",
			"error", err, "term_months", asked.TermMonths)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	amount, err := New(int64(price.Cents), Currency(price.Currency))
	if err != nil {
		web.LoggerFrom(r.Context()).Error("the price in force is not money",
			"error", err, "price", price.ID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	/* WHAT COMES OFF, READ RATHER THAN COMPILED IN. It was a constant here until
	   `0045`, and its own comment named the condition for it stopping to be one.

	   NO ROW IS NO DISCOUNT AND IS NOT AN ERROR: a method nobody has discounted
	   is sold at the price, which is an ordinary offer rather than a failure.
	   The store answers a zero and this takes nothing off. */
	off, err := h.discounts.InForce(r.Context(), ScopeEverything, method)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading the discount in force",
			"error", err, "method", method)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}
	if off.BasisPoints > 0 {
		less := amount.Percent(int64(off.BasisPoints))
		if amount, err = amount.Sub(less); err != nil {
			web.LoggerFrom(r.Context()).Error("applying the discount", "error", err)
			web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
			return
		}
	}

	// 1. THE ROW FIRST, AND THE GATE WITH IT.
	intent, err := h.checkouts.Open(r.Context(), accountID, ScopeEverything, price.ID,
		int(amount.Cents()), price.Currency, method, asked.Instalments, h.gateway.Name)
	switch {
	case errors.Is(err, ErrNotConfirmed):
		/* THE ONE THING CONFIRMATION GATES, and the sentence says which. It is
		   422 rather than 403: nothing is wrong with the session, and what has
		   to change is a state of the account rather than who is asking. */
		web.Fail(w, http.StatusUnprocessableEntity, "email_unconfirmed",
			"confirm your e-mail address before paying — we sent a link when you signed up, "+
				"and the banner on any page will send another")
		return
	case errors.Is(err, ErrNoMethod), errors.Is(err, ErrNotSplittable),
		errors.Is(err, ErrTooManyInstalments), errors.Is(err, ErrNotAPrice):
		web.Fail(w, http.StatusBadRequest, "not_a_checkout", "that is not a way to pay here")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("opening a checkout", "error", err, "account", accountID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not start that")
		return
	}

	// 2. WHO THEY ARE AT THE GATEWAY, asked for only when it is not known.
	customerID, err := h.customer(r.Context(), accountID, name, email, asked.TaxID)
	switch {
	case errors.Is(err, errNeedsTaxID):
		web.Fail(w, http.StatusUnprocessableEntity, "tax_id_required",
			"paying in Brazil needs a CPF or CNPJ — we pass it to the payment provider "+
				"to issue the charge and do not store it")
		return
	case errors.Is(err, errNotATaxID):
		web.Fail(w, http.StatusBadRequest, "not_a_tax_id",
			"a CPF is eleven digits and a CNPJ is fourteen")
		return
	case h.gateway.Refused != nil && h.gateway.Refused(err):
		/* THEIR REFUSAL, IN OUR WORDS. The provider's own sentence is Portuguese
		   prose behind a generic code, so what reaches the payer is this — and
		   what reaches the log is the error, which carries theirs. */
		web.LoggerFrom(r.Context()).Warn("the gateway refused a payer",
			"error", err, "checkout", intent.ID)
		web.Fail(w, http.StatusUnprocessableEntity, "payer_refused",
			"the payment provider would not accept those details")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("registering a payer",
			"error", err, "checkout", intent.ID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not start that")
		return
	}

	// 3. THE CHARGE, CARRYING OUR ID.
	chargeID, invoiceURL, err := h.gateway.NewCharge(r.Context(), Charge{
		CustomerID:  customerID,
		Reference:   intent.ID.String(),
		Cents:       amount.Cents(),
		Currency:    price.Currency,
		Method:      method,
		Instalments: asked.Instalments,
		Due:         time.Now().Add(chargeLife),
		Describes:   h.describe(asked.TermMonths),
	})
	if err != nil {
		/* THE CHECKOUT STAYS `opened` AND SAYS SO IN THE LOG. It is the row this
		   order of operations exists to leave behind: somebody clicked, nothing
		   was charged, and there is a record of the attempt rather than an
		   invoice belonging to nobody. */
		web.LoggerFrom(r.Context()).Error("creating a charge",
			"error", err, "checkout", intent.ID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the payment could not be started — nothing has been charged")
		return
	}

	// 4. WHAT CAME BACK, WRITTEN DOWN.
	if _, err := h.checkouts.Charged(r.Context(), intent.ID, chargeID, invoiceURL); err != nil {
		/* A CHARGE EXISTS AND THIS DATABASE DOES NOT KNOW ITS ID. The webhook
		   can still find its way home — the charge carries our reference — so
		   this is loud rather than fatal, and the payer is sent to pay. */
		web.LoggerFrom(r.Context()).Error("a charge was created and not recorded",
			"error", err, "checkout", intent.ID, "charge", chargeID)
	}

	web.JSON(w, http.StatusOK, map[string]any{
		"checkoutId": intent.ID,
		"invoiceUrl": invoiceURL,
		"cents":      amount.Cents(),
		"currency":   price.Currency,
	})
}

var (
	errNeedsTaxID = errors.New("billing: a first purchase needs a tax id")
	errNotATaxID  = errors.New("billing: that is not a CPF or CNPJ")
)

/*
customer answers the payer's handle, registering them if this is the first time.

	THE NUMBER IS ONLY ASKED FOR ONCE. A returning buyer already has a handle,
	so the field is absent from every renewal — and a request that carries a tax
	id for somebody who has one is not an error, it is simply not needed.
*/
func (h *Handler) customer(ctx context.Context, accountID uuid.UUID,
	name, email, taxID string) (string, error) {

	switch known, err := h.checkouts.CustomerOf(ctx, accountID, h.gateway.Name); {
	case err == nil:
		return known, nil
	case !errors.Is(err, ErrNoCustomer):
		return "", err
	}

	digits := onlyDigits(taxID)
	if digits == "" {
		return "", errNeedsTaxID
	}
	/* ELEVEN OR FOURTEEN DIGITS, AND THE CHECK DIGITS ARE THEIRS TO VERIFY.
	   This catches the typo — a number with one digit missing — without a round
	   trip. It deliberately does not implement the check-digit algorithm: an
	   implementation of it that is subtly wrong refuses real people, and the
	   gateway is going to run the real one anyway. */
	if len(digits) != 11 && len(digits) != 14 {
		return "", errNotATaxID
	}

	handle, err := h.gateway.NewCustomer(ctx, name, email, digits)
	if err != nil {
		return "", err
	}
	if err := h.checkouts.RememberCustomer(ctx, accountID, h.gateway.Name, handle); err != nil {
		/* THE HANDLE EXISTS AND WE DID NOT KEEP IT. The purchase can go on — the
		   charge only needs the string in hand — and the cost is that the next
		   one asks for the number again. Better than refusing somebody at the
		   moment they decided to pay. */
		web.LoggerFrom(ctx).Error("a payer was registered and not remembered",
			"error", err, "account", accountID)
	}
	return handle, nil
}

func onlyDigits(text string) string {
	var out strings.Builder
	for _, r := range text {
		if r >= '0' && r <= '9' {
			out.WriteRune(r)
		}
	}
	return out.String()
}

/*
describe is what the payer sees on the invoice, in their bank's app or in their
card statement, months later.

	IT IS NOT TRANSLATED AND THAT IS DELIBERATE. This string leaves the platform
	and is rendered by the gateway, a bank and a card issuer, none of which know
	what language the buyer reads — so it says the plainest thing that survives
	that trip, and the screens that DO know the language say the rest.
*/
func (h *Handler) describe(termMonths int) string {
	return fmt.Sprintf("%s — %d months", h.brand, termMonths)
}
