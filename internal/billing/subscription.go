package billing

import (
	"errors"
	"fmt"
	"time"
)

// The two subscription state machines, as pure functions over a state and a
// thing that happened.
//
// # WHY TWO, AND WHY THAT IS THE WHOLE POINT
//
// Brazil is sold annually or biennially, paid in card instalments (N-08).
// Everywhere else is real recurrence — monthly, annual or biennial (N-09).
// Those look like the same product with a different payment schedule, and they
// are not:
//
// A card instalment plan is ONE AUTHORISATION, split by the issuer. We are paid
// once. What the customer sees as twelve monthly lines is an arrangement
// between them and their bank, and we never learn whether any individual line
// was collected. So there is no monthly payment to fail, nothing to retry, and
// NOTHING TO SUSPEND — a "failed instalment" is not an event this system can
// receive. The subscription runs to the end of the term it was sold for and
// then stops, and the next period is a NEW SALE with its own authorisation.
//
// Real recurrence is the opposite: a charge is attempted every period, it can
// fail, it is retried, and access is eventually cut. Grace and suspension exist
// only here.
//
// Written as one machine with a flag, the instalment plan inherits a grace
// period and a suspension path that its payments cannot trigger — dead states
// on one model, and a bug waiting for somebody to wire an event into them. The
// two are separate because the events they can receive are different, and that
// is what `Advance` enforces: an event a model cannot receive is refused rather
// than ignored.
//
// # THE PAYWALL READS `Opens`, AND NOTHING ELSE
//
// Access is computed from the subscription, never from an enrolment row (K-15).
// `Opens` is the whole of that decision, and it is a function of the state — so
// there is no column to flip, and no way to grant access except by putting a
// subscription into a state that has one.

// Model is which of the two a subscription is.
type Model string

const (
	// ModelRecurring is a charge attempted every period, which can fail.
	ModelRecurring Model = "recurring"
	// ModelInstalments is one authorisation split by the issuer, and paid to us
	// once. Pix on the annual plan is the same shape: paid once, for a term.
	ModelInstalments Model = "instalments"
)

// State is where a subscription is.
//
// A CLOSED LIST, and `Opens` below is exhaustive over it. A state this code
// does not know opens nothing — the same fail-closed direction as an
// unrecognised plan, for the same reason.
type State string

const (
	// StateActive is paid and running.
	StateActive State = "active"

	// StateGrace is a charge that failed and is being retried. Access is still
	// open: cutting somebody off at the first declined card would lock out
	// every student whose bank flagged a routine transaction, and the retry
	// schedule exists precisely because most of those recover.
	//
	// Recurring only.
	StateGrace State = "grace"

	// StateSuspended is the retries having run out. Access is closed and the
	// subscription is not over — a later payment brings it back, with progress
	// intact, which is the recovery half of what this phase is done when.
	//
	// Recurring only.
	StateSuspended State = "suspended"

	// StateCancelled is somebody having asked to stop. Access runs to the end
	// of what they paid for and then ends: cutting immediately would be taking
	// money for a period and not delivering it.
	StateCancelled State = "cancelled"

	// StateExpired is a term that ran out with no renewal. It is the ordinary
	// end of an instalment plan, and it is not a failure of anything.
	StateExpired State = "expired"

	// StateEnded is over, and not coming back on its own. A refund or a
	// chargeback lands here immediately, and so does a cancellation once its
	// paid period elapses.
	StateEnded State = "ended"
)

// Subscription is the state, and the date access runs to.
//
// PaidThrough IS PART OF THE STATE and not a detail beside it: two of the
// transitions below are the passage of time reaching it, and a state machine
// that could not see the date would need somebody to run a job at the right
// minute for a subscription to be correct.
type Subscription struct {
	Model       Model
	State       State
	PaidThrough time.Time
}

// Event is something that happened to a subscription.
type Event string

const (
	// EventPaid is money received for a period, extending PaidThrough. Both
	// models receive it — it is the only event they share, and it is what
	// starts every subscription.
	EventPaid Event = "paid"

	// EventPaymentFailed is a recurring charge declined. Recurring only: an
	// instalment plan has no charge for us to see fail.
	EventPaymentFailed Event = "payment-failed"

	// EventRetriesExhausted is the grace period running out with no payment.
	// Recurring only.
	EventRetriesExhausted Event = "retries-exhausted"

	// EventCancelled is the student asking to stop. Both models: somebody who
	// bought a year in instalments can still say they do not want the next one.
	EventCancelled Event = "cancelled"

	// EventRefunded is money given back by agreement.
	EventRefunded Event = "refunded"

	// EventChargedBack is money taken back by the issuer, in a dispute.
	//
	// It is a separate event from a refund even though both cut access at once,
	// because they mean opposite things about the person: one is an agreement
	// and the other is a dispute, and a system that recorded them as the same
	// thing could not tell an operator which conversation to have.
	EventChargedBack Event = "charged-back"

	/* EventGranted is time given rather than sold — an outage, a support case
	   that took a fortnight, somebody charged for a week they could not study.

	   IT DOES EXACTLY WHAT `EventPaid` DOES, AND IS A DIFFERENT WORD ON PURPOSE.
	   The state machine cannot tell the two apart and should not try: both
	   extend a term, and both revive a subscription that had lapsed. What
	   differs is everything around it — a payment has a ledger row behind it
	   and a grant has none, because no money moved.

	   Recording it as `paid` would have been one word cheaper and would have
	   put a sale in the log that nobody made. A year later, "why is the money
	   short against the terms we sold" would be answered by counting rows that
	   were never money, and nothing would be left to tell the two apart. */
	EventGranted Event = "granted"
)

// Transition is what an event did, or why it could not.
var (
	// ErrNotThisModel is an event that this kind of subscription cannot
	// receive. A failed instalment is the case it exists for: refusing is what
	// keeps somebody from wiring a suspension path into a model that has none.
	ErrNotThisModel = errors.New("billing: that cannot happen to this kind of subscription")

	// ErrNotFromHere is an event that is real for this model and impossible
	// from this state — a payment failing on a subscription that already ended.
	ErrNotFromHere = errors.New("billing: that cannot happen from this state")

	// ErrUnknownEvent is something this does not recognise. It is refused, not
	// ignored: an event nothing handles would leave a subscription in a state
	// its own history does not explain.
	ErrUnknownEvent = errors.New("billing: that is not something that happens to a subscription")
)

// Start is a new subscription, paid through a date.
//
// Every subscription begins with money. There is no free trial (N-10) — the
// free tier is the first course of every track, which needs no subscription at
// all, so there is no state here for "signed up but not paying".
func Start(model Model, paidThrough time.Time) (Subscription, error) {
	if model != ModelRecurring && model != ModelInstalments {
		return Subscription{}, fmt.Errorf("%w: %q", ErrNotThisModel, model)
	}
	return Subscription{Model: model, State: StateActive, PaidThrough: paidThrough}, nil
}

// Advance answers what a subscription becomes when something happens to it.
//
// It is a pure function: no clock, no database, no side effect. `at` is when
// the event happened and `paidThrough` is the new date a payment bought, which
// is ignored by every event except EventPaid.
//
// Time itself is not an event here. What the passage of time does is in Settle,
// because "the paid period elapsed" is a fact about a date rather than
// something that arrives.
func Advance(s Subscription, e Event, at time.Time, paidThrough time.Time) (Subscription, error) {
	if err := receivable(s.Model, e); err != nil {
		return s, err
	}

	// The two that end it, from anywhere it has not already ended. Money coming
	// back cuts access at once — a refunded month that a student keeps studying
	// is a month given away, and a chargeback is money we no longer have.
	if e == EventRefunded || e == EventChargedBack {
		if s.State == StateEnded {
			return s, fmt.Errorf("%w: it is already over", ErrNotFromHere)
		}
		return Subscription{Model: s.Model, State: StateEnded, PaidThrough: at}, nil
	}

	/* A GRANT IS A PAYMENT AS FAR AS THIS FUNCTION IS CONCERNED, and folding it
	   in here is the whole of the difference rather than a shortcut.

	   Time given and time sold do the same thing to access: they extend a term,
	   and they revive a subscription that had lapsed. Writing a second set of
	   arms for `EventGranted` would be writing the same table twice, and the
	   day somebody fixed one of them the other would be the bug.

	   What must NOT be folded is anything outside this file. A grant has no
	   ledger row and the log records its own word — see `EventGranted`. */
	if e == EventGranted {
		e = EventPaid
	}

	switch s.State {
	case StateActive, StateGrace:
		switch e {
		case EventPaid:
			// Out of grace and paid up. This is the recovery the phase is done
			// when: nothing about progress is touched, because progress was
			// never conditioned on the subscription — only access was.
			return Subscription{Model: s.Model, State: StateActive, PaidThrough: paidThrough}, nil
		case EventPaymentFailed:
			return Subscription{Model: s.Model, State: StateGrace, PaidThrough: s.PaidThrough}, nil
		case EventRetriesExhausted:
			if s.State != StateGrace {
				return s, fmt.Errorf("%w: nothing was being retried", ErrNotFromHere)
			}
			return Subscription{Model: s.Model, State: StateSuspended, PaidThrough: s.PaidThrough}, nil
		case EventCancelled:
			// THE PAID PERIOD IS HONOURED. They keep what they bought.
			return Subscription{Model: s.Model, State: StateCancelled, PaidThrough: s.PaidThrough}, nil
		}

	case StateSuspended:
		switch e {
		case EventPaid:
			return Subscription{Model: s.Model, State: StateActive, PaidThrough: paidThrough}, nil
		case EventCancelled:
			// Suspended and then cancelled: there is no paid period left to
			// honour, so it is simply over.
			return Subscription{Model: s.Model, State: StateEnded, PaidThrough: s.PaidThrough}, nil
		}

	case StateCancelled, StateExpired, StateEnded:
		// A LAPSED SUBSCRIPTION THAT PAYS AGAIN IS ACTIVE AGAIN, with the same
		// row and the same account, which is what "recovery restores access
		// with progress intact" means. Everything else is refused: a payment
		// failing on something nobody is charging says the caller has lost
		// track of which subscription it is holding.
		if e == EventPaid {
			return Subscription{Model: s.Model, State: StateActive, PaidThrough: paidThrough}, nil
		}
	}

	return s, fmt.Errorf("%w: %s cannot receive %q", ErrNotFromHere, s.State, e)
}

// Settle is what the passage of time does, and it is separate from Advance
// because it is not an event: nothing arrives, a date is simply now in the
// past.
//
// Two states end by elapsing, and they are the two whose end was already
// decided. A cancellation ends when the period it honoured runs out. An
// instalment term expires when the term is over, because there is no next
// charge — the renewal is a new sale (N-08), which is a new payment rather than
// a transition from here.
//
// A RECURRING SUBSCRIPTION DOES NOT EXPIRE BY ELAPSING. Its next charge either
// arrives, fails, or the provider stops talking to us; a subscription that
// quietly expired the moment a webhook was late would cut off a paying student
// because of our own outage.
func Settle(s Subscription, now time.Time) Subscription {
	if now.Before(s.PaidThrough) {
		return s
	}
	switch {
	case s.State == StateCancelled:
		return Subscription{Model: s.Model, State: StateEnded, PaidThrough: s.PaidThrough}
	case s.State == StateActive && s.Model == ModelInstalments:
		return Subscription{Model: s.Model, State: StateExpired, PaidThrough: s.PaidThrough}
	default:
		return s
	}
}

// Opens answers whether this subscription opens a paid course, and it is the
// whole of that decision.
//
// EXHAUSTIVE, AND THE DEFAULT IS CLOSED. A state this function does not know
// opens nothing — the same direction as an unrecognised plan, for the same
// reason: a paywall that opens on an unrecognised input is a paywall with a
// list of ways around it that nobody has finished writing.
//
// Note what is NOT here: no clock. A cancelled subscription whose period has
// elapsed opens nothing because Settle has moved it to ended, not because this
// function compared a date. Two places that both decide access by looking at
// the calendar are two places that can disagree.
func Opens(s Subscription) bool {
	switch s.State {
	case StateActive, StateGrace, StateCancelled:
		return true
	case StateSuspended, StateExpired, StateEnded:
		return false
	default:
		return false
	}
}

// Renewing answers whether this subscription needs a new sale before it lapses,
// and how long there is.
//
// It is here rather than in a job because it is the same fact the screen and
// the reminder both need, and two implementations of "is it nearly over" would
// disagree in the week that matters. An instalment plan is the case it exists
// for: nothing renews it on its own, so somebody has to be told (N-08).
func Renewing(s Subscription, now time.Time, notice time.Duration) bool {
	if s.Model != ModelInstalments || s.State != StateActive {
		return false
	}
	return !now.Before(s.PaidThrough.Add(-notice))
}

// receivable is which events each model can receive at all, and it is the
// difference between the two machines rather than a detail of them.
func receivable(model Model, e Event) error {
	if model != ModelRecurring && model != ModelInstalments {
		// A subscription whose model this code does not know cannot be advanced
		// at all. The alternative is picking one of the two, and picking
		// recurring would give it a suspension path it may not have.
		return fmt.Errorf("%w: %q is not a kind of subscription", ErrNotThisModel, model)
	}
	switch e {
	// A GRANT IS RECEIVABLE BY BOTH, like a payment and for the same reason: it
	// extends a term, and both machines have one.
	case EventPaid, EventGranted, EventCancelled, EventRefunded, EventChargedBack:
		return nil
	case EventPaymentFailed, EventRetriesExhausted:
		if model == ModelInstalments {
			// The line this file exists to draw. What the customer sees as
			// twelve monthly lines is between them and their bank; we were paid
			// once, and there is nothing here to fail or retry.
			return fmt.Errorf("%w: an instalment plan is one authorisation, so %q "+
				"is not something we can be told about", ErrNotThisModel, e)
		}
		return nil
	default:
		return fmt.Errorf("%w: %q", ErrUnknownEvent, e)
	}
}
