package billing

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/google/uuid"
)

/*
Turning a payment into access, which is the only thing that ever does.

# THREE WRITES AND THEY ARE NOT INTERCHANGEABLE

	the ledger    that money moved, append-only, keyed by the CHARGE
	the checkout  how far this purchase got
	the plan      what the person may open

They are done in that order and each is idempotent on its own, because the
event that drives them arrives more than once by design. A payment produces
`PAYMENT_CONFIRMED` and then `PAYMENT_RECEIVED`, and both mean it was paid.

# THE LEDGER IS KEYED BY THE CHARGE AND NEVER BY THE EVENT

This is the one place where using the obvious key would be wrong. Each delivery
carries its own event id, so keying on that would write TWO payment rows for one
payment — the accounts would say a student paid twice and the ledger would be
the thing that lied. The charge is what money is attached to, so the charge is
the key, and the second event finds the row already there.

# ONLY THE FIRST PAYMENT OF A CHECKOUT BUYS A TERM

An instalment plan is one authorisation the issuer collects six times, and each
collection is a payment with an id of its own. All six belong to the purchase;
only the first bought anything. So the term is extended when the checkout MOVES
to paid, and a later instalment records its money and extends nothing — which is
what stops six instalments becoming six years.

# WHAT THE AMOUNT IS, AND WHERE IT COMES FROM

From the checkout, which is what this platform asked for — not from the event.
Their number is a decimal on a wire and this system counts in cents; the
conversion exists in exactly one place, in the provider's own package, and
nothing here needs it. What we asked for is also the more useful fact: it is the
figure the person agreed to.
*/

// Settlement writes what a payment event means.
type Settlement struct {
	checkouts *Checkouts
	prices    *Prices
	ledger    *Ledger
	plans     *Store

	// provider is whose events these are, recorded on every ledger row so that
	// "where did this money come from" is answerable without a join.
	provider string

	log *slog.Logger
}

func NewSettlement(checkouts *Checkouts, prices *Prices, ledger *Ledger, plans *Store,
	provider string, log *slog.Logger) *Settlement {

	return &Settlement{
		checkouts: checkouts, prices: prices, ledger: ledger, plans: plans,
		provider: provider, log: log,
	}
}

/*
Apply acts on one event about one charge.

	IT FINDS THE PURCHASE BY OUR REFERENCE FIRST. The charge carries the
	checkout's id because we put it there; falling back to the provider's own id
	covers the events that arrive without it — the later instalments of a plan,
	and anything raised outside this platform.
*/
func (s *Settlement) Apply(ctx context.Context, what outcome, reference, chargeID string) error {
	intent, err := s.find(ctx, reference, chargeID)
	if err != nil {
		return err
	}

	switch what {
	case outcomePaid:
		return s.paid(ctx, intent, chargeID)
	case outcomeGone:
		/* A CHARGE THAT WILL NOT BE PAID CHANGES NOTHING BUT THE PURCHASE. No
		   subscription was started, so there is nothing to end — and a paid
		   checkout is left alone, because an overdue arriving after a payment
		   must not take away what the payment bought. */
		_, err := s.checkouts.Abandoned(ctx, intent.ID)
		return err
	case outcomeRefunded:
		return s.reverse(ctx, intent, chargeID, KindRefund, EventRefunded)
	case outcomeChargedBack:
		return s.reverse(ctx, intent, chargeID, KindChargeback, EventChargedBack)
	}
	return fmt.Errorf("billing: nothing to do for %q", what)
}

func (s *Settlement) find(ctx context.Context, reference, chargeID string) (Intent, error) {
	if id, err := uuid.Parse(reference); err == nil {
		one, err := s.checkouts.ByID(ctx, id)
		if err == nil {
			return one, nil
		}
		if !errors.Is(err, ErrNoIntent) {
			return Intent{}, err
		}
	}
	return s.checkouts.ByCharge(ctx, s.provider, chargeID)
}

func (s *Settlement) paid(ctx context.Context, intent Intent, chargeID string) error {
	amount, err := New(int64(intent.Cents), Currency(intent.Currency))
	if err != nil {
		return fmt.Errorf("billing: what was charged is not money: %w", err)
	}

	/* 1. THE LEDGER, KEYED BY THE CHARGE. A second event about the same payment
	   finds this row already written and is told so, which is the whole of the
	   idempotency and is enforced by an index rather than by a check. */
	entry, err := s.ledger.Record(ctx, Entry{
		AccountID: intent.AccountID,
		Kind:      KindPayment,
		Amount:    amount,
		Source:    s.provider,
		SourceRef: chargeID,
	})
	/* `ErrAlreadyRecorded` IS THE SUCCESS THIS IS BUILT FOR, and it comes back
	   holding the row that is already there. The ledger's own comment says so —
	   "what lets a webhook handler treat a retry as the success it is" — and the
	   first version of this file treated it as a failure, which answered 500 to
	   the second of the two events every payment produces and would have stopped
	   the queue on every single sale. */
	if err != nil && !errors.Is(err, ErrAlreadyRecorded) {
		return fmt.Errorf("billing: recording a payment: %w", err)
	}

	// 2. THE PURCHASE. `first` is false when this charge is a later instalment,
	// or when the same event has already been acted on.
	settled, first, err := s.checkouts.Settled(ctx, intent.ID)
	if err != nil {
		return err
	}
	if !first {
		return nil
	}

	// 3. WHAT THEY MAY OPEN. Only on the move to paid, for the reason the
	// package comment gives: six instalments are one term.
	price, err := s.prices.ByID(ctx, settled.PriceID)
	if err != nil {
		return fmt.Errorf("billing: reading what this bought: %w", err)
	}

	now := time.Now()
	/* THE TERM RUNS FROM TODAY AND NOT FROM THE CHARGE'S DATE. A Pix paid three
	   days after the checkout was opened buys twelve months from the day it was
	   paid — anything else charges somebody for days they could not study. */
	paidThrough := now.AddDate(0, price.TermMonths, 0)

	held, err := s.plans.Begin(ctx, settled.AccountID, settled.Scope,
		/* EVERY PURCHASE HERE IS AN INSTALMENT PLAN IN THE SENSE THAT MATTERS:
		   a term is bought and at its end there is a new sale. Nothing on this
		   platform creates a subscription AT the gateway yet, so there is no
		   charge for us to see fail, which is exactly what `ModelRecurring`
		   would promise and could not keep. */
		ModelInstalments, settled.PriceID, now, paidThrough, &entry.ID)
	if err != nil {
		return fmt.Errorf("billing: opening what was paid for: %w", err)
	}

	s.log.Info("a payment opened a subscription",
		"account", settled.AccountID, "checkout", settled.ID,
		"term_months", price.TermMonths, "paid_through", held.PaidThrough)
	return nil
}

/*
reverse is money going back, by agreement or by dispute.

	THE LEDGER ROW IS THE SAME SHAPE AND THE SUBSCRIPTION EVENT IS NOT. Both cut
	access at once; they mean opposite things about the person, and an operator
	needs to know which conversation to have.

	IT DOES NOT CARE WHETHER THE SUBSCRIPTION IS THERE. A refund on a purchase
	that never opened one is a refund, and the money still has to be recorded.
*/
func (s *Settlement) reverse(ctx context.Context, intent Intent, chargeID string,
	kind Kind, event Event) error {

	amount, err := New(int64(intent.Cents), Currency(intent.Currency))
	if err != nil {
		return fmt.Errorf("billing: what was charged is not money: %w", err)
	}

	/* THE REFERENCE IS THE CHARGE AND THE KIND, TOGETHER. A payment and its
	   refund are two movements of the same money on the same charge, so keying
	   the reversal on the charge alone would collide with the payment it
	   reverses — and the index that exists to stop a double payment would stop
	   the refund instead. */
	if _, err := s.ledger.Record(ctx, Entry{
		AccountID: intent.AccountID,
		Kind:      kind,
		Amount:    amount.Neg(),
		Source:    s.provider,
		SourceRef: chargeID + ":" + string(kind),
	}); err != nil && !errors.Is(err, ErrAlreadyRecorded) {
		return fmt.Errorf("billing: recording money going back: %w", err)
	}

	switch _, err := s.plans.Advance(ctx, intent.AccountID, intent.Scope,
		event, time.Now(), time.Time{}, nil); {
	case errors.Is(err, ErrNoSubscription):
		// Money back on a purchase that never opened anything. Recorded above,
		// and there is nothing to close.
		s.log.Warn("money went back on a purchase with no subscription",
			"account", intent.AccountID, "checkout", intent.ID, "kind", kind)
		return nil
	case errors.Is(err, ErrNotFromHere):
		// It is already over. A second refund event, or one arriving after a
		// chargeback closed the same subscription.
		return nil
	case err != nil:
		return fmt.Errorf("billing: closing what was paid back: %w", err)
	}

	s.log.Info("money went back and access closed",
		"account", intent.AccountID, "checkout", intent.ID, "kind", kind)
	return nil
}
