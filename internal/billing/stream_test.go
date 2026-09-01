package billing_test

import (
	"context"
	"testing"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/billing"
)

/*
What a subscription's life is counted as.

	# WHY THESE ARE WRITTEN AGAINST A REAL DATABASE

	The emission happens AFTER the commit, on purpose — see `WithStream` — so a
	fake store would be testing the ordering of two things it invented. What has
	to hold is that the row is there and the count followed it, and that is only
	true of a store that really committed.

	# AND WHY A RECORDER RATHER THAN THE EVENT STORE

	`billing` may not import `event` (X-02). The callback is the boundary, so a
	slice of what came through it is exactly what the wiring in `cmd/` would
	have been handed.
*/
type counted struct {
	name    string
	account uuid.UUID
	payload map[string]any
}

func recorder() (billing.Emit, *[]counted) {
	var got []counted
	return func(_ context.Context, name string, account uuid.UUID,
		payload map[string]any) {

		got = append(got, counted{name: name, account: account, payload: payload})
	}, &got
}

// STARTING IS COUNTED ONCE, and it is the event the funnel's last step reads.
func TestStartingASubscriptionIsCounted(t *testing.T) {
	s, pool := store(t)
	emit, got := recorder()
	s = s.WithStream(emit)

	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)

	if len(*got) != 1 {
		t.Fatalf("starting a subscription emitted %d events, want one: %v", len(*got), *got)
	}
	if (*got)[0].name != billing.EventStarted {
		t.Errorf("starting emitted %q, want %q", (*got)[0].name, billing.EventStarted)
	}
	if (*got)[0].account != account {
		t.Errorf("it was counted against %s, want %s", (*got)[0].account, account)
	}
}

/*
A RENEWAL IS NOT A SECOND START, which is the distinction the funnel depends on.

	Counted as a start, one subscriber would enter the "began paying" figure once
	a year — and a cohort grouped by subscription start would move them forward
	into a younger intake every time they paid, quietly shrinking the old
	cohorts and inflating the new ones.
*/
func TestRenewingIsCountedAsARenewalAndNotAStart(t *testing.T) {
	s, pool := store(t)
	emit, got := recorder()
	s = s.WithStream(emit)

	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)
	begun(t, s, pool, account, billing.ModelInstalments, 12) // the same row, paid again

	if len(*got) != 2 {
		t.Fatalf("two payments emitted %d events, want two: %v", len(*got), *got)
	}
	if (*got)[0].name != billing.EventStarted {
		t.Errorf("the first payment emitted %q, want %q", (*got)[0].name, billing.EventStarted)
	}
	if (*got)[1].name != billing.EventRenewed {
		t.Errorf("the second payment emitted %q, want %q — a subscription is reused, "+
			"and counting the renewal as a start would report one person twice",
			(*got)[1].name, billing.EventRenewed)
	}
}

/*
An ending is counted, and it says why.

	THE REASON IS THE PAYLOAD AND NOT THE NAME. Cancelled, refunded, charged
	back and elapsed are four endings, and minting a name for each would put
	four strings into an append-only stream that a report has to keep
	understanding forever — see `stream.go`. What every report actually asks is
	when somebody stopped.
*/
func TestAnEndingIsCountedWithItsReason(t *testing.T) {
	s, pool := store(t)
	emit, got := recorder()
	s = s.WithStream(emit)

	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)

	if _, err := s.Advance(context.Background(), account, "",
		billing.EventRefunded, day(1), day(0), nil); err != nil {
		t.Fatalf("refunding: %v", err)
	}

	if len(*got) != 2 {
		t.Fatalf("a start and a refund emitted %d events, want two: %v", len(*got), *got)
	}
	last := (*got)[1]
	if last.name != billing.EventEnded {
		t.Fatalf("refunding emitted %q, want %q", last.name, billing.EventEnded)
	}
	if got := last.payload["reason"]; got != string(billing.EventRefunded) {
		t.Errorf("the ending says its reason is %v, want %q", got, billing.EventRefunded)
	}
}

/*
A TRANSITION THAT DID NOT CLOSE ACCESS IS NOT AN ENDING.

	Cancelling runs to the end of the term that was paid for — `Opens` says a
	cancelled subscription still opens a course, and the whole point of that is
	that somebody who cancels in March keeps what they bought until December.
	Counted as an ending here, every report of "when people stop" would be a
	report of when people give NOTICE, which is a different question and months
	out. `subscription_events` records the cancellation either way; this stream
	deliberately records less.
*/
func TestGivingNoticeIsNotCountedAsAnEnding(t *testing.T) {
	s, pool := store(t)
	emit, got := recorder()
	s = s.WithStream(emit)

	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)

	held, err := s.Advance(context.Background(), account, "",
		billing.EventCancelled, day(1), day(0), nil)
	if err != nil {
		t.Fatalf("cancelling: %v", err)
	}
	if !billing.Opens(held.Subscription) {
		t.Fatal("cancelling closed access immediately, so this test is no longer " +
			"about what it says it is about")
	}

	if len(*got) != 1 {
		t.Errorf("a start and a cancellation emitted %d events, want only the start: %v",
			len(*got), *got)
	}
}

// A STORE WITH NO STREAM WRITES SUBSCRIPTIONS AND COUNTS NOTHING, which is what
// every other test in this package builds and what a deployment without the
// wiring would do. Silence, and not a panic on a nil callback.
func TestAStoreWithNoStreamStillWritesSubscriptions(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)

	held := begun(t, s, pool, account, billing.ModelInstalments, 12)
	if !billing.Opens(held.Subscription) {
		t.Error("a subscription begun without a stream to count it does not open a course")
	}
}

/*
A TERM RUNNING OUT IS COUNTED, AND IT IS THE ORDINARY WAY ONE ENDS HERE.

	Every other ending arrives as something somebody DID — a cancellation, a
	refund, a chargeback — and goes through `Advance`. A term simply elapsing is
	nobody doing anything: the state machine settles it in memory on every read,
	so the fact exists long before any row says so, and the sweep is what turns
	it into a moment.

	IT MATTERS BECAUSE IT IS MOST OF THEM. An instalment plan does not renew
	itself (N-08), so on this platform the common ending is this one — and a
	stream that recorded only the dramatic endings would describe a platform
	almost nobody ever leaves.

	The sweeper had no caller at all until `cmd/settle`, which is a separate
	defect and the reason this test is worth having: it holds the emission, and
	`cmd/settle` holds that something runs it.
*/
func TestATermRunningOutIsCountedBySweepingIt(t *testing.T) {
	s, pool := store(t)
	emit, got := recorder()
	s = s.WithStream(emit)

	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)

	// Long after the term: `day(400)` is past twelve months from `day(0)`.
	moved, err := s.Settle(context.Background(), day(400))
	if err != nil {
		t.Fatalf("settling: %v", err)
	}
	if moved < 1 {
		t.Fatal("the sweep moved nothing, and a twelve-month term is over by day 400")
	}

	var endings []counted
	for _, one := range *got {
		if one.name == billing.EventEnded && one.account == account {
			endings = append(endings, one)
		}
	}
	if len(endings) != 1 {
		t.Fatalf("sweeping emitted %d endings for this account, want one: %v", len(endings), *got)
	}
	if reason := endings[0].payload["reason"]; reason != "elapsed" {
		t.Errorf("the ending says its reason is %v, want %q — a term running out is not "+
			"a cancellation and a report reading this has to tell them apart",
			reason, "elapsed")
	}
}

// AND SWEEPING TWICE COUNTS IT ONCE. The sweep is idempotent by design — "safe
// to run at any time and any number of times" — and an emitter that fired on
// every pass would put an ending into an append-only stream every night for the
// rest of the platform's life, for one subscription that ended once.
func TestSweepingTwiceCountsTheEndingOnce(t *testing.T) {
	s, pool := store(t)
	emit, got := recorder()
	s = s.WithStream(emit)

	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)

	for i := 0; i < 2; i++ {
		if _, err := s.Settle(context.Background(), day(400)); err != nil {
			t.Fatalf("settling, pass %d: %v", i+1, err)
		}
	}

	endings := 0
	for _, one := range *got {
		if one.name == billing.EventEnded && one.account == account {
			endings++
		}
	}
	if endings != 1 {
		t.Errorf("two sweeps emitted %d endings for one subscription that ended once", endings)
	}
}
