package billing_test

import (
	"errors"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/billing"
)

func day(n int) time.Time {
	return time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC).AddDate(0, 0, n)
}

func started(t *testing.T, model billing.Model, through time.Time) billing.Subscription {
	t.Helper()
	s, err := billing.Start(model, through)
	if err != nil {
		t.Fatalf("starting a %s subscription: %v", model, err)
	}
	return s
}

// THE LINE THIS FILE EXISTS TO DRAW. A card instalment plan is one
// authorisation split by the issuer: we are paid once, and what the customer
// sees as twelve monthly lines is between them and their bank. There is no
// instalment for us to see fail, so an instalment plan must not have a
// suspension path — and the way to guarantee that is to refuse the event rather
// than to leave a state nothing reaches.
func TestAnInstalmentPlanCannotHaveAPaymentFail(t *testing.T) {
	plan := started(t, billing.ModelInstalments, day(365))

	for _, e := range []billing.Event{
		billing.EventPaymentFailed,
		billing.EventRetriesExhausted,
	} {
		after, err := billing.Advance(plan, e, day(30), time.Time{})
		if !errors.Is(err, billing.ErrNotThisModel) {
			t.Errorf("%q on an instalment plan gave %v, want ErrNotThisModel", e, err)
		}
		if after != plan {
			t.Errorf("%q moved an instalment plan to %s", e, after.State)
		}
	}

	// And a recurring subscription receives both, which is what makes the
	// refusal above a distinction rather than a blanket ban.
	recurring := started(t, billing.ModelRecurring, day(30))
	if _, err := billing.Advance(recurring, billing.EventPaymentFailed, day(30), time.Time{}); err != nil {
		t.Errorf("a recurring charge failing: %v", err)
	}
}

// A DECLINED CARD DOES NOT LOCK ANYBODY OUT ON THE DAY. Most declines are a
// bank flagging a routine transaction, and the retry schedule exists because
// most of them recover. Access is cut when the retries run out, not before.
func TestGraceKeepsAStudentStudyingAndSuspensionDoesNot(t *testing.T) {
	s := started(t, billing.ModelRecurring, day(30))

	s, err := billing.Advance(s, billing.EventPaymentFailed, day(30), time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if s.State != billing.StateGrace {
		t.Fatalf("a failed charge left it %s, want grace", s.State)
	}
	if !billing.Opens(s) {
		t.Error("a student was locked out on the day their card was declined")
	}

	s, err = billing.Advance(s, billing.EventRetriesExhausted, day(37), time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if s.State != billing.StateSuspended {
		t.Fatalf("the retries running out left it %s, want suspended", s.State)
	}
	if billing.Opens(s) {
		t.Error("a suspended subscription still opens a paid course")
	}
}

// AND RECOVERY BRINGS IT BACK. This is half of what the phase is done when:
// paying after a suspension restores access, on the same subscription, with
// nothing about progress touched — progress was never conditioned on paying,
// only access was.
func TestPayingAfterASuspensionRestoresAccess(t *testing.T) {
	s := started(t, billing.ModelRecurring, day(30))
	for _, e := range []billing.Event{billing.EventPaymentFailed, billing.EventRetriesExhausted} {
		var err error
		if s, err = billing.Advance(s, e, day(30), time.Time{}); err != nil {
			t.Fatal(err)
		}
	}

	s, err := billing.Advance(s, billing.EventPaid, day(40), day(70))
	if err != nil {
		t.Fatalf("paying after a suspension: %v", err)
	}
	if s.State != billing.StateActive {
		t.Errorf("it is %s after paying, want active", s.State)
	}
	if !s.PaidThrough.Equal(day(70)) {
		t.Errorf("it is paid through %s, want the date the payment bought", s.PaidThrough)
	}
	if !billing.Opens(s) {
		t.Error("a recovered subscription does not open a course")
	}
}

// CANCELLING HONOURS WHAT WAS PAID FOR. Cutting access the moment somebody
// cancels is taking money for a period and not delivering it.
func TestCancellingRunsToTheEndOfThePaidPeriod(t *testing.T) {
	s := started(t, billing.ModelRecurring, day(30))

	s, err := billing.Advance(s, billing.EventCancelled, day(10), time.Time{})
	if err != nil {
		t.Fatal(err)
	}
	if !billing.Opens(s) {
		t.Error("a cancellation cut access on the day it was made")
	}
	if !s.PaidThrough.Equal(day(30)) {
		t.Errorf("cancelling moved the paid-through date to %s", s.PaidThrough)
	}

	// A week before the period ends, nothing has changed.
	if settled := billing.Settle(s, day(23)); settled.State != billing.StateCancelled {
		t.Errorf("it became %s before the period was over", settled.State)
	}

	// And on the day it does.
	settled := billing.Settle(s, day(30))
	if settled.State != billing.StateEnded {
		t.Errorf("the paid period elapsed and it is %s, want ended", settled.State)
	}
	if billing.Opens(settled) {
		t.Error("a cancelled subscription still opens a course after its period ran out")
	}
}

// MONEY COMING BACK CUTS ACCESS AT ONCE, from wherever it was. A refunded month
// somebody keeps studying is a month given away; a chargeback is money we no
// longer have.
func TestARefundOrAChargebackEndsItImmediately(t *testing.T) {
	for _, e := range []billing.Event{billing.EventRefunded, billing.EventChargedBack} {
		for _, model := range []billing.Model{billing.ModelRecurring, billing.ModelInstalments} {
			s := started(t, model, day(365))

			after, err := billing.Advance(s, e, day(10), time.Time{})
			if err != nil {
				t.Fatalf("%q on a %s subscription: %v", e, model, err)
			}
			if after.State != billing.StateEnded {
				t.Errorf("%q on a %s subscription left it %s, want ended", e, model, after.State)
			}
			if billing.Opens(after) {
				t.Errorf("%q left a %s subscription still opening courses", e, model)
			}
			if !after.PaidThrough.Equal(day(10)) {
				t.Errorf("%q left the paid-through date at %s rather than the day it happened",
					e, after.PaidThrough)
			}
		}
	}
}

// A refund and a chargeback are separate events even though both cut access at
// once, because they mean opposite things about the person — one is an
// agreement and the other is a dispute. Recording them as one thing would leave
// an operator unable to tell which conversation to have.
func TestARefundAndAChargebackAreNotTheSameEvent(t *testing.T) {
	if billing.EventRefunded == billing.EventChargedBack {
		t.Error("a refund and a chargeback are the same value, so nothing downstream " +
			"can tell an agreement from a dispute")
	}
}

// AN INSTALMENT TERM ENDS BY RUNNING OUT, and that is not a failure of
// anything: there is no next charge to attempt, because the renewal is a new
// sale (N-08).
func TestAnInstalmentTermExpiresWhenItIsOver(t *testing.T) {
	plan := started(t, billing.ModelInstalments, day(365))

	if settled := billing.Settle(plan, day(364)); settled.State != billing.StateActive {
		t.Errorf("it expired a day early, as %s", settled.State)
	}

	settled := billing.Settle(plan, day(365))
	if settled.State != billing.StateExpired {
		t.Errorf("the term ran out and it is %s, want expired", settled.State)
	}
	if billing.Opens(settled) {
		t.Error("an expired term still opens a course")
	}

	// And a new sale starts it again, on the same subscription.
	renewed, err := billing.Advance(settled, billing.EventPaid, day(366), day(731))
	if err != nil {
		t.Fatalf("the new sale: %v", err)
	}
	if renewed.State != billing.StateActive || !billing.Opens(renewed) {
		t.Errorf("a renewal left it %s", renewed.State)
	}
}

// A RECURRING SUBSCRIPTION DOES NOT EXPIRE BY ELAPSING. Its next charge either
// arrives or fails — and one that quietly expired because a webhook was late
// would cut off a paying student for our own outage.
func TestARecurringSubscriptionIsNotCutOffByALateWebhook(t *testing.T) {
	s := started(t, billing.ModelRecurring, day(30))

	settled := billing.Settle(s, day(45))
	if settled.State != billing.StateActive {
		t.Errorf("a fortnight past the renewal date it is %s — nothing arrived, which is "+
			"a reason to retry rather than to lock somebody out", settled.State)
	}
	if !billing.Opens(settled) {
		t.Error("a paying student lost access because a webhook was late")
	}
}

// NOTHING RENEWS AN INSTALMENT PLAN ON ITS OWN, so somebody has to be told
// before it lapses. The screen and the reminder ask the same function, because
// two implementations of "is it nearly over" would disagree in the one week
// that matters.
func TestAnInstalmentPlanIsFlaggedForRenewalBeforeItLapses(t *testing.T) {
	const notice = 30 * 24 * time.Hour
	plan := started(t, billing.ModelInstalments, day(365))

	if billing.Renewing(plan, day(300), notice) {
		t.Error("it was flagged for renewal two months out")
	}
	if !billing.Renewing(plan, day(340), notice) {
		t.Error("it was not flagged for renewal inside the notice window")
	}

	// A recurring subscription is never flagged: it renews itself.
	recurring := started(t, billing.ModelRecurring, day(365))
	if billing.Renewing(recurring, day(360), notice) {
		t.Error("a recurring subscription was flagged for a renewal it does not need")
	}
}

// AN IMPOSSIBLE TRANSITION IS REFUSED, NOT IGNORED. A payment failing on
// something nobody is charging means the caller has lost track of which
// subscription it is holding, and swallowing it would leave the state unable to
// explain its own history.
func TestATransitionThatCannotHappenIsRefused(t *testing.T) {
	ended, err := billing.Advance(
		started(t, billing.ModelRecurring, day(30)), billing.EventRefunded, day(5), time.Time{})
	if err != nil {
		t.Fatal(err)
	}

	for _, c := range []struct {
		name  string
		from  billing.Subscription
		event billing.Event
		want  error
	}{
		{"a charge failing on something already over", ended,
			billing.EventPaymentFailed, billing.ErrNotFromHere},
		{"retries running out on something nobody was retrying",
			started(t, billing.ModelRecurring, day(30)),
			billing.EventRetriesExhausted, billing.ErrNotFromHere},
		{"refunding something already refunded", ended,
			billing.EventRefunded, billing.ErrNotFromHere},
		{"cancelling something already over", ended,
			billing.EventCancelled, billing.ErrNotFromHere},
		{"an event nothing knows", started(t, billing.ModelRecurring, day(30)),
			billing.Event("vanished"), billing.ErrUnknownEvent},
		{"a model nothing knows",
			billing.Subscription{Model: "barter", State: billing.StateActive},
			billing.EventPaid, billing.ErrNotThisModel},
	} {
		after, err := billing.Advance(c.from, c.event, day(50), day(80))
		if !errors.Is(err, c.want) {
			t.Errorf("%s: gave %v, want %v", c.name, err, c.want)
		}
		if after != c.from {
			t.Errorf("%s: it moved anyway, to %s", c.name, after.State)
		}
	}
}

// THE PAYWALL DEFAULTS CLOSED. A state this code does not know opens nothing —
// the same direction as an unrecognised plan, and for the same reason: a
// paywall that opens on an unrecognised input is a paywall with a list of ways
// around it that nobody has finished writing.
func TestAStateNothingRecognisesOpensNothing(t *testing.T) {
	for _, state := range []billing.State{"", "trialling", "vip", "unknown", "ACTIVE"} {
		if billing.Opens(billing.Subscription{Model: billing.ModelRecurring, State: state}) {
			t.Errorf("the state %q opened a paid course", state)
		}
	}

	// And the zero value, which is what a subscription nobody has is.
	if billing.Opens(billing.Subscription{}) {
		t.Error("an empty subscription opened a paid course")
	}
}

// Opens NEVER LOOKS AT A CLOCK, and that is deliberate: a cancelled
// subscription past its period opens nothing because Settle moved it, not
// because Opens compared a date. Two places that both decide access from the
// calendar are two places that can disagree.
func TestWhetherACourseOpensDoesNotDependOnWhenItIsAsked(t *testing.T) {
	cancelled, err := billing.Advance(
		started(t, billing.ModelRecurring, day(30)), billing.EventCancelled, day(5), time.Time{})
	if err != nil {
		t.Fatal(err)
	}

	// The date is long past, and Opens still says yes — because settling is
	// what changes a subscription, and it has not been settled.
	if !billing.Opens(cancelled) {
		t.Error("Opens is reading a clock: an unsettled cancellation stopped opening " +
			"courses on its own, which means access is decided in two places")
	}
}

// A subscription only ever begins with money. There is no free trial (N-10) —
// the free tier is the first course of every track and needs no subscription at
// all — so there is no state here for "signed up but not paying".
func TestASubscriptionOnlyStartsPaid(t *testing.T) {
	for _, model := range []billing.Model{billing.ModelRecurring, billing.ModelInstalments} {
		s := started(t, model, day(30))
		if s.State != billing.StateActive {
			t.Errorf("a %s subscription starts %s, want active", model, s.State)
		}
	}
	if _, err := billing.Start("trial", day(30)); !errors.Is(err, billing.ErrNotThisModel) {
		t.Errorf("a trial was accepted as a kind of subscription: %v", err)
	}
}
