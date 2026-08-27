package billing

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

/*
A purchase being attempted, from the click to the money.

# WHY THIS EXISTS AT ALL

A webhook from the gateway carries their ids and nothing else. `0042` says the
rest; what this file adds is the order of operations, which is the half a schema
cannot enforce: the row is written BEFORE the gateway is called, so that the id
it carries already exists when the charge does.

# THE CONFIRMATION GATE IS HERE, AND THAT PLACEMENT WAS GOT WRONG ONCE

ROADMAP.md records it: confirmation is required to START a payment and never to
finish one. The obvious home is `Begin`, and `Begin` is called once a payment
has already SUCCEEDED — a guard there refuses the subscription of somebody who
has just been charged, and the honest response at that point is a refund rather
than a refusal. That version was proposed, approved, and caught while reading
the code.

So it is here, at the one door money goes through. It is a collaborator rather
than a call into `identity`, because modules talk through function types wired
in `cmd` — and it is REQUIRED rather than optional, so a second caller cannot
arrive without it.

# WHAT IT DOES NOT GATE

Signing in, studying, the free first course of every track, the exams, the
notes. One provider's outage held every message to its users for two hours on
27 August 2026; a platform whose front door depends on mail delivery is a
platform a stranger's cooling failure can close.
*/

// ErrNotConfirmed is somebody trying to buy from an address they have not
// proved. It is the only thing on this platform that confirmation gates.
var ErrNotConfirmed = errors.New("billing: this address has not been confirmed")

// ErrNoIntent is a checkout nobody opened.
var ErrNoIntent = errors.New("billing: no such checkout")

// ErrNotOpen is a checkout being taken somewhere it cannot go from where it is.
var ErrNotOpen = errors.New("billing: that checkout is not waiting for a charge")

// ErrNoMethod is a way of paying this platform does not sell. Debit is the one
// somebody will reach for, and the gateway does not offer it.
var ErrNoMethod = errors.New("billing: that is not a way to pay here")

// ErrNotSplittable is instalments asked for on Pix, which is paid once.
var ErrNotSplittable = errors.New("billing: only a card payment can be split")

// Method is how a checkout is being paid.
type Method string

const (
	// MethodPix is one payment, settled in seconds, at the lowest fee this
	// platform is offered.
	MethodPix Method = "pix"
	// MethodCard is a card, split by the issuer into `Instalments` or not.
	MethodCard Method = "card"
)

/*
Stage is how far a purchase got, and it is a different word from `State` on
purpose.

	`State` in this package is the SUBSCRIPTION's, and access is computed from it
	(K-15). Nothing here opens anything. The two were briefly the same identifier
	and the compiler refused, which was the good outcome: they are two answers to
	two questions about the same person on the same day, and a screen that
	confused them would tell somebody they are paid up because their checkout
	reached the gateway.
*/
type Stage string

const (
	// StageOpened is written, gateway not yet asked.
	StageOpened Stage = "opened"
	// StageCharged is a charge the payer can go and pay.
	StageCharged Stage = "charged"
	// StagePaid is money received and the subscription started.
	StagePaid Stage = "paid"
	// StageAbandoned is a charge that expired, was deleted, or was never paid.
	StageAbandoned Stage = "abandoned"
)

/*
Intent is one attempt to buy.

	`Cents` IS WHAT WAS ASKED FOR AND `PriceID` IS WHAT IT WAS SOLD UNDER, and
	they differ the moment a discount exists. Renewal charges the price and not
	this amount — see ROADMAP.md, which draws the same line for interest.
*/
type Intent struct {
	ID        uuid.UUID
	AccountID uuid.UUID
	Scope     string
	PriceID   uuid.UUID

	Cents    int
	Currency string

	Method      Method
	Instalments int

	Provider   string
	ChargeID   string
	InvoiceURL string
	Stage      Stage
}

/*
Confirmed answers whether an account may start a payment.

	IT IS A FUNCTION TYPE AND NOT A CALL INTO `identity`, because `internal`
	modules do not import each other — `cmd` wires this to whatever knows. It is
	the same arrangement `notify.Barred` uses, for the same reason.

	AN ERROR IS A NO. A checkout that opened because the confirmation lookup was
	unavailable is a payment taken on a guess, and the guess costs a refund. This
	is the opposite of `notify.mayWrite`, where an error is a yes, and the two
	are opposite deliberately: not writing to somebody is a nuisance, and
	charging somebody who could not be checked is money.
*/
type Confirmed func(ctx context.Context, accountID uuid.UUID) (bool, error)

// Checkouts is the store over the two tables `0042` adds.
type Checkouts struct {
	pool      *pgxpool.Pool
	confirmed Confirmed
}

// NewCheckouts is the store. `confirmed` is required: a nil one would make the
// gate a thing every caller has to remember.
func NewCheckouts(pool *pgxpool.Pool, confirmed Confirmed) *Checkouts {
	return &Checkouts{pool: pool, confirmed: confirmed}
}

/*
Open records what somebody is trying to buy, before anybody is asked for money.

	IT IS THE GATE. Confirmation is checked here and nowhere later, and a
	checkout is the only thing on this platform it stops.

	THE ROW IS THE RECEIPT FOR A CLICK. Nothing has been charged when this
	returns; what exists is an id, which the caller then hands to the gateway as
	its own reference. Several `opened` rows for one person are ordinary — a slow
	connection and a second click make two — and only one of them will ever carry
	a charge.
*/
func (c *Checkouts) Open(ctx context.Context, accountID uuid.UUID, scope string,
	priceID uuid.UUID, cents int, currency string,
	method Method, instalments int, provider string) (Intent, error) {

	if scope == "" {
		scope = ScopeEverything
	}
	if instalments < 1 {
		instalments = 1
	}
	switch {
	case accountID == uuid.Nil:
		return Intent{}, ErrNoSubscription
	case priceID == uuid.Nil:
		return Intent{}, ErrNoPrice
	case cents <= 0:
		return Intent{}, fmt.Errorf("%w: %d", ErrNotAPrice, cents)
	case !isCurrency(currency):
		return Intent{}, fmt.Errorf("%w: %q", ErrNotAPrice, currency)
	case method != MethodPix && method != MethodCard:
		return Intent{}, fmt.Errorf("%w: %q", ErrNoMethod, method)
	case method == MethodPix && instalments > 1:
		return Intent{}, ErrNotSplittable
	case strings.TrimSpace(provider) == "":
		return Intent{}, fmt.Errorf("%w: a checkout has to say which gateway it is at",
			ErrNoMethod)
	}

	if c.confirmed == nil {
		/* A STORE BUILT WITHOUT THE GATE REFUSES EVERYTHING. It is a wiring
		   mistake rather than a request anybody got wrong, and the alternative
		   — charging on with no check — is the failure this whole arrangement
		   exists to make impossible. */
		return Intent{}, fmt.Errorf("%w: nothing was wired to answer it", ErrNotConfirmed)
	}
	ok, err := c.confirmed(ctx, accountID)
	if err != nil {
		return Intent{}, fmt.Errorf("%w: it could not be checked: %w", ErrNotConfirmed, err)
	}
	if !ok {
		return Intent{}, ErrNotConfirmed
	}

	out := Intent{
		AccountID: accountID, Scope: scope, PriceID: priceID,
		Cents: cents, Currency: currency,
		Method: method, Instalments: instalments,
		Provider: provider, Stage: StageOpened,
	}
	if err := c.pool.QueryRow(ctx, `
		INSERT INTO checkout_intents
			(account_id, scope, price_id, cents, currency, method, instalments, provider)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`, accountID, scope, priceID, cents, currency, string(method), instalments, provider,
	).Scan(&out.ID); err != nil {
		return Intent{}, fmt.Errorf("billing: opening a checkout: %w", err)
	}
	return out, nil
}

/*
Charged records that the gateway now has a charge for this checkout.

	IT REFUSES A SECOND ONE. The unique index would too, from a different
	direction — this says which checkout, and it says it before a person has been
	given two invoices for the same purchase.
*/
func (c *Checkouts) Charged(ctx context.Context, id uuid.UUID,
	chargeID, invoiceURL string) (Intent, error) {

	if strings.TrimSpace(chargeID) == "" {
		return Intent{}, fmt.Errorf("%w: with no charge to record", ErrNotOpen)
	}

	tag, err := c.pool.Exec(ctx, `
		UPDATE checkout_intents
		   SET provider_charge_id = $2, invoice_url = $3,
		       stage = 'charged', updated_at = now()
		 WHERE id = $1 AND stage = 'opened'
	`, id, chargeID, invoiceURL)
	if err != nil {
		return Intent{}, fmt.Errorf("billing: recording a charge: %w", err)
	}
	if tag.RowsAffected() == 0 {
		/* EITHER IT IS NOT THERE OR IT HAS MOVED ON, and the two are told apart
		   by reading rather than guessed at — "no such checkout" and "that one
		   already has a charge" send a caller to different places. */
		if _, err := c.ByID(ctx, id); err != nil {
			return Intent{}, err
		}
		return Intent{}, ErrNotOpen
	}
	return c.ByID(ctx, id)
}

// Settled records that a charge was paid. It is idempotent: a webhook delivered
// twice is the normal case, not the exception.
func (c *Checkouts) Settled(ctx context.Context, id uuid.UUID) (Intent, error) {
	if _, err := c.pool.Exec(ctx, `
		UPDATE checkout_intents SET stage = 'paid', updated_at = now()
		 WHERE id = $1 AND stage <> 'paid'
	`, id); err != nil {
		return Intent{}, fmt.Errorf("billing: settling a checkout: %w", err)
	}
	return c.ByID(ctx, id)
}

// Abandoned records that a charge will not be paid — expired, deleted, or
// overdue past the point of waiting. It leaves a paid one alone: an event
// arriving late must not undo money that arrived.
func (c *Checkouts) Abandoned(ctx context.Context, id uuid.UUID) (Intent, error) {
	if _, err := c.pool.Exec(ctx, `
		UPDATE checkout_intents SET stage = 'abandoned', updated_at = now()
		 WHERE id = $1 AND stage <> 'paid'
	`, id); err != nil {
		return Intent{}, fmt.Errorf("billing: abandoning a checkout: %w", err)
	}
	return c.ByID(ctx, id)
}

// ByID reads one checkout.
func (c *Checkouts) ByID(ctx context.Context, id uuid.UUID) (Intent, error) {
	return c.one(ctx, `WHERE id = $1`, id)
}

/*
ByCharge finds the checkout a gateway charge belongs to.

	IT IS THE WEBHOOK'S OTHER WAY IN. An event carries our reference — the id —
	which is the first way; this is for the deliveries that carry only theirs,
	and for reading what is true when an event is doubted.
*/
func (c *Checkouts) ByCharge(ctx context.Context, provider, chargeID string) (Intent, error) {
	return c.one(ctx, `WHERE provider = $1 AND provider_charge_id = $2`, provider, chargeID)
}

func (c *Checkouts) one(ctx context.Context, where string, args ...any) (Intent, error) {
	var out Intent
	var chargeID, invoiceURL *string
	err := c.pool.QueryRow(ctx, `
		SELECT id, account_id, scope, price_id, cents, currency, method, instalments,
		       provider, provider_charge_id, invoice_url, stage
		  FROM checkout_intents `+where, args...,
	).Scan(&out.ID, &out.AccountID, &out.Scope, &out.PriceID, &out.Cents, &out.Currency,
		&out.Method, &out.Instalments, &out.Provider, &chargeID, &invoiceURL, &out.Stage)

	if errors.Is(err, pgx.ErrNoRows) {
		return Intent{}, ErrNoIntent
	}
	if err != nil {
		return Intent{}, fmt.Errorf("billing: reading a checkout: %w", err)
	}
	if chargeID != nil {
		out.ChargeID = *chargeID
	}
	if invoiceURL != nil {
		out.InvoiceURL = *invoiceURL
	}
	return out, nil
}

// ---------- who somebody is at a gateway ----------

/*
RememberCustomer stores the handle a gateway answered with, and nothing else.

	THE TAX ID IS NOT AN ARGUMENT HERE, DELIBERATELY. Charging in Brazil needs a
	CPF or CNPJ; this platform sends one and keeps none, so what crosses into the
	database is the opaque string the gateway gave back. A signature that took
	the number would be an invitation to store it.

	IT IS AN UPSERT because the same person buying a second time must not make a
	second handle — the gateway would then hold two customers for one payer, and
	a webhook naming either would be right.
*/
func (c *Checkouts) RememberCustomer(ctx context.Context, accountID uuid.UUID,
	provider, customerID string) error {

	if strings.TrimSpace(provider) == "" || strings.TrimSpace(customerID) == "" {
		return fmt.Errorf("%w: a handle needs a gateway and a string", ErrNoMethod)
	}
	if _, err := c.pool.Exec(ctx, `
		INSERT INTO payment_customers (account_id, provider, customer_id)
		VALUES ($1, $2, $3)
		ON CONFLICT (account_id, provider) DO UPDATE SET customer_id = EXCLUDED.customer_id
	`, accountID, provider, customerID); err != nil {
		return fmt.Errorf("billing: remembering a customer: %w", err)
	}
	return nil
}

// ErrNoCustomer is somebody who has never paid at this gateway. It is not a
// failure — it is the ordinary state of anybody buying for the first time.
var ErrNoCustomer = errors.New("billing: this account has no customer at that gateway")

// CustomerOf answers the handle, so a second purchase does not ask for a tax id
// that the gateway already holds.
func (c *Checkouts) CustomerOf(ctx context.Context, accountID uuid.UUID,
	provider string) (string, error) {

	var out string
	err := c.pool.QueryRow(ctx, `
		SELECT customer_id FROM payment_customers
		 WHERE account_id = $1 AND provider = $2
	`, accountID, provider).Scan(&out)

	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNoCustomer
	}
	if err != nil {
		return "", fmt.Errorf("billing: reading a customer: %w", err)
	}
	return out, nil
}
