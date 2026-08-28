package billing_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/billing"
)

func store(t *testing.T) (*billing.Store, *pgxpool.Pool) {
	t.Helper()
	pool := testPool(t)
	return billing.NewStore(pool), pool
}

// THE POOL IS A PARAMETER BECAUSE THE PRICE IS A REAL ROW. `price_id` is a
// foreign key — an invented uuid would be testing something the database does
// not allow — so every subscription these tests begin needs a school and a
// published price behind it.
func begun(t *testing.T, s *billing.Store, pool *pgxpool.Pool, account uuid.UUID,
	model billing.Model, months int) billing.Held {

	t.Helper()
	held, err := s.Begin(context.Background(), account, "", model,
		price(t, pool, 49000), day(0), months, nil)
	if err != nil {
		t.Fatalf("beginning a %s subscription: %v", model, err)
	}
	return held
}

// SOMEBODY WHO HAS NEVER PAID OPENS NOTHING, and that is not an error — it is
// the ordinary state of most people. They see the free tier, which is the first
// course of every track and needs no subscription at all.
func TestSomebodyWithNoSubscriptionOpensNothingAndThatIsNotAnError(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)

	open, err := s.Opens(context.Background(), account, day(0))
	if err != nil {
		t.Fatalf("asking the paywall about somebody with no subscription: %v", err)
	}
	if open {
		t.Error("an account that has never paid opens a paid course")
	}

	if _, err := s.Of(context.Background(), account, "", day(0)); !errors.Is(err, billing.ErrNoSubscription) {
		t.Errorf("reading it gave %v, want ErrNoSubscription", err)
	}
}

// PAYING OPENS THE DOOR, and the whole of the decision is the state.
func TestPayingOpensAPaidCourse(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelRecurring, 1)

	open, err := s.Opens(context.Background(), account, day(1))
	if err != nil {
		t.Fatal(err)
	}
	if !open {
		t.Error("a paid subscription does not open a paid course")
	}
}

// READING SETTLES, so a cancellation whose period ran out reads as ended
// without anything having had to run at midnight. A paywall that depended on a
// nightly job would leave a window every night in which somebody kept access
// they had stopped paying for.
func TestAPeriodThatRanOutClosesTheDoorWithNoJobHavingRun(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelRecurring, 1)

	if _, err := s.Advance(context.Background(), account, "",
		billing.EventCancelled, day(5), time.Time{}, nil); err != nil {
		t.Fatalf("cancelling: %v", err)
	}

	open, err := s.Opens(context.Background(), account, day(20))
	if err != nil {
		t.Fatal(err)
	}
	if !open {
		t.Error("a cancellation cut access inside the period that was paid for")
	}

	// The day the period ends, with nothing having run in between.
	open, err = s.Opens(context.Background(), account, day(31))
	if err != nil {
		t.Fatal(err)
	}
	if open {
		t.Error("a cancelled subscription still opens a course after its paid period, " +
			"which means the paywall is waiting for a job to notice")
	}
}

// AND THE JOB MAKES THE ROW MATCH. Reading settles in memory so the answer is
// always truthful; this is what makes a query for "who is active" mean
// something, so a report is not counting cancellations that ended weeks ago.
func TestSettlingBringsTheRowUpToDateAndIsSafeToRunTwice(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelInstalments, 12)

	moved, err := s.Settle(context.Background(), day(366))
	if err != nil {
		t.Fatalf("settling: %v", err)
	}
	if moved < 1 {
		t.Fatalf("settling moved %d subscriptions past their term, want at least the one", moved)
	}

	var state string
	if err := pool.QueryRow(context.Background(),
		`SELECT state FROM subscriptions WHERE account_id = $1`, account).Scan(&state); err != nil {
		t.Fatal(err)
	}
	if state != "expired" {
		t.Errorf("the row says %q after settling, want expired", state)
	}

	// Twice changes nothing, so a job that runs late or runs again is harmless.
	before := transitions(t, pool, account)
	if _, err := s.Settle(context.Background(), day(400)); err != nil {
		t.Fatalf("settling again: %v", err)
	}
	if after := transitions(t, pool, account); after != before {
		t.Errorf("settling twice wrote %d transitions where the first wrote %d",
			after-before, before)
	}
}

func transitions(t *testing.T, pool *pgxpool.Pool, account uuid.UUID) int {
	t.Helper()
	var n int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM subscription_events WHERE account_id = $1`, account).Scan(&n); err != nil {
		t.Fatal(err)
	}
	return n
}

// THE HISTORY IS WHY SOMEBODY WAS LOCKED OUT. A mutable row alone would have
// overwritten the only evidence, and "it became suspended" is not an answer to
// a student who says they were paying.
func TestEveryTransitionIsWrittenDownWithBothSides(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelRecurring, 1)

	for _, e := range []billing.Event{billing.EventPaymentFailed, billing.EventRetriesExhausted} {
		if _, err := s.Advance(context.Background(), account, "", e, day(31), time.Time{}, nil); err != nil {
			t.Fatalf("%q: %v", e, err)
		}
	}

	history, err := s.History(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if len(history) != 3 {
		t.Fatalf("the history has %d lines, want the payment and the two that followed", len(history))
	}

	// Newest first.
	if history[0].Event != billing.EventRetriesExhausted ||
		history[0].From != billing.StateGrace || history[0].To != billing.StateSuspended {
		t.Errorf("the last line is %q, %s → %s — it should say the retries ran out and "+
			"that it came from grace", history[0].Event, history[0].From, history[0].To)
	}
	if history[2].From != "none" {
		t.Errorf("the first line came from %q; a subscription starts from nowhere and the "+
			"log should say so in a word rather than a null", history[2].From)
	}
}

// A LEDGER ROW CAN BE POINTED AT, which is what ties "you lost access" to
// "this payment failed" without either table having to know the other's shape.
func TestATransitionCanNameTheMoneyThatCausedIt(t *testing.T) {
	s, pool := store(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)

	payment := paid(t, ledger, account, 119900)
	if _, err := s.Begin(context.Background(), account, "",
		billing.ModelInstalments, price(t, pool, 119900), day(0), 12,
		&payment.ID); err != nil {
		t.Fatalf("beginning against a payment: %v", err)
	}

	history, err := s.History(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if len(history) != 1 || history[0].LedgerEntryID == nil {
		t.Fatalf("the opening line does not name the payment that bought it: %+v", history)
	}
	if *history[0].LedgerEntryID != payment.ID {
		t.Errorf("it names %s and the payment was %s", *history[0].LedgerEntryID, payment.ID)
	}
}

// PAYING AGAIN REUSES THE ROW. It is the same person with the same progress,
// which is what "recovery restores access with progress intact" means — and a
// second subscription row would leave two answers to "what are they paying
// for".
func TestPayingAfterALapseReusesTheSameSubscription(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	first := begun(t, s, pool, account, billing.ModelInstalments, 12)

	if _, err := s.Settle(context.Background(), day(366)); err != nil {
		t.Fatal(err)
	}

	/* THE RENEWAL IS SOLD AT A NEW PRICE AND THE ROW KEEPS THE OLD ONE.

	   This is the whole point of the column: the school raised its price
	   between the two payments, and somebody who already bought must not be
	   moved onto the new number by the act of paying again. */
	raised := price(t, pool, 59000)
	again, err := s.Begin(context.Background(), account, "",
		billing.ModelInstalments, raised, day(400), 12, nil)
	if err != nil {
		t.Fatalf("a new sale after the term ran out: %v", err)
	}
	if again.ID != first.ID {
		t.Errorf("the renewal made a new subscription (%s, was %s)", again.ID, first.ID)
	}
	if again.State != billing.StateActive {
		t.Errorf("the renewal left it %s", again.State)
	}
	if again.PriceID != first.PriceID {
		t.Errorf("paying again moved the subscription onto the new price (%s, was %s)",
			again.PriceID, first.PriceID)
	}
	if again.PriceID == raised {
		t.Error("the renewal was charged at the price the school raised to")
	}

	var count int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM subscriptions WHERE account_id = $1`, account).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Errorf("there are %d subscription rows for one person", count)
	}
}

// AN EVENT LANDS ON THE SUBSCRIPTION AS IT ACTUALLY IS. A payment arriving on a
// cancellation whose period ran out three weeks ago is a revival, and without
// settling first it would be applied to a state that is only true on paper.
func TestAnEventIsAppliedToTheSettledStateAndNotTheStoredOne(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelRecurring, 1)

	if _, err := s.Advance(context.Background(), account, "",
		billing.EventCancelled, day(5), time.Time{}, nil); err != nil {
		t.Fatal(err)
	}

	// Nothing has settled the row: it still says cancelled. The payment arrives
	// three weeks after the period ended.
	if _, err := s.Advance(context.Background(), account, "",
		billing.EventPaid, day(51), day(81), nil); err != nil {
		t.Fatalf("paying after a lapsed cancellation: %v", err)
	}

	history, err := s.History(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if history[0].From != billing.StateEnded {
		t.Errorf("the payment was recorded as coming from %s; the period had run out three "+
			"weeks earlier, so it came from ended", history[0].From)
	}
}

// NOTHING RENEWS AN INSTALMENT PLAN ON ITS OWN, so the job that tells people
// has to find them. A recurring subscription is never in that list.
func TestOnlyInstalmentPlansTurnUpAsNeedingRenewal(t *testing.T) {
	s, pool := store(t)
	const notice = 30 * 24 * time.Hour

	instalments := student(t, pool)
	begun(t, s, pool, instalments, billing.ModelInstalments, 12)
	recurring := student(t, pool)
	begun(t, s, pool, recurring, billing.ModelRecurring, 12)

	found, err := s.Renewing(context.Background(), day(340), notice)
	if err != nil {
		t.Fatal(err)
	}

	sawInstalments, sawRecurring := false, false
	for _, held := range found {
		switch held.AccountID {
		case instalments:
			sawInstalments = true
		case recurring:
			sawRecurring = true
		}
	}
	if !sawInstalments {
		t.Error("the instalment plan inside the notice window was not flagged for renewal")
	}
	if sawRecurring {
		t.Error("a recurring subscription was flagged for a renewal it does not need")
	}

	// And two months out, neither.
	early, err := s.Renewing(context.Background(), day(300), notice)
	if err != nil {
		t.Fatal(err)
	}
	for _, held := range early {
		if held.AccountID == instalments {
			t.Error("it was flagged two months before the term ends")
		}
	}
}

// THE PAYWALL IS NOT A COLUMN SOMEBODY CAN FLIP. There is no state a write to
// this table can produce that opens a course except by being one the state
// machine recognises — and the schema refuses the rest outright.
func TestAStateTheMachineDoesNotKnowCannotBeWritten(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelRecurring, 1)

	for _, state := range []string{"vip", "comped", "", "ACTIVE"} {
		if _, err := pool.Exec(context.Background(),
			`UPDATE subscriptions SET state = $2 WHERE account_id = $1`, account, state); err == nil {
			t.Errorf("the state %q was written to a subscription", state)
		}
	}

	// And the one that is real still works, so the check above is a distinction
	// rather than a table nothing can be written to.
	if _, err := s.Advance(context.Background(), account, "",
		billing.EventCancelled, day(5), time.Time{}, nil); err != nil {
		t.Fatalf("cancelling: %v", err)
	}
}

// AN ERASURE TAKES THE SUBSCRIPTION AND LEAVES THE HISTORY. The state means
// nothing once there is nobody; the log sits beside the ledger rows it explains
// and is what lets a dispute be reconstructed a year later.
func TestErasingSomebodyTakesTheSubscriptionAndLeavesItsHistory(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	begun(t, s, pool, account, billing.ModelRecurring, 1)

	if _, err := pool.Exec(context.Background(),
		`DELETE FROM accounts WHERE id = $1`, account); err != nil {
		t.Fatalf("erasing an account with a subscription: %v — an append-only log that "+
			"cascaded would make this impossible for everybody who ever subscribed", err)
	}

	var subscriptions int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM subscriptions WHERE account_id = $1`, account).Scan(&subscriptions); err != nil {
		t.Fatal(err)
	}
	if subscriptions != 0 {
		t.Errorf("%d subscriptions survived the erasure", subscriptions)
	}

	if left := transitions(t, pool, account); left == 0 {
		t.Error("the history went with the person; it is what explains the money beside it")
	}
}

// A SUBSCRIPTION HAS TO SAY WHAT IT WAS SOLD AT, and it is refused before a
// transaction rather than by the column. Both would fail; only one says which
// argument was missing, and the caller that gets it wrong has just taken
// somebody's money.
func TestASubscriptionWithoutAPriceIsRefused(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)

	_, err := s.Begin(context.Background(), account, "", billing.ModelRecurring,
		uuid.Nil, day(0), 1, nil)
	if !errors.Is(err, billing.ErrNoPrice) {
		t.Errorf("beginning without a price answered %v, want ErrNoPrice", err)
	}
}

// AND THE PRICE COMES BACK WHEN THE SUBSCRIPTION IS READ, which is what makes
// it useful: a renewal run reads the row and charges what it says rather than
// what the school charges today.
func TestTheSubscriptionCarriesItsPriceBackOutOfTheDatabase(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)

	sold := price(t, pool, 49000)
	begun, err := s.Begin(context.Background(), account, "", billing.ModelRecurring,
		sold, day(0), 1, nil)
	if err != nil {
		t.Fatalf("beginning: %v", err)
	}
	if begun.PriceID != sold {
		t.Fatalf("it was begun at %s and says %s", sold, begun.PriceID)
	}

	read, err := s.Of(context.Background(), account, "", day(1))
	if err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if read.PriceID != sold {
		t.Errorf("read back it says %s, want %s", read.PriceID, sold)
	}
}

/*
TestPayingBeforeTheTermEndsAddsToItRatherThanReplacingIt is the case a
subscriber reaches by doing something reasonable.

	NOTHING STOPS SOMEBODY BUYING AGAIN. `Checkouts.Open` asks whether the
	address is confirmed and whether the method can be split; it does not ask
	whether they already have a subscription, and the screen offers the form to
	anybody signed in. So an early renewal — locking a price in, or simply not
	wanting to think about it again — is a purchase this platform accepts.

	AND IT USED TO SHORTEN THE SUBSCRIPTION. `Begin` was handed a date the caller
	had computed as `now + term`, so somebody twelve months into two years who
	bought another year moved their end date from twenty-four months out to
	twelve. They paid twice and came away with less.

	IT IS A STORE TEST AND NOT A `subscription.Advance` ONE, which is where this
	was first written and was the wrong layer: the pure function is handed a
	date and can only use it. What has to be right is the arithmetic, and the
	arithmetic needs the row's current end — so it belongs inside the
	transaction that locks it, and so does the test.
*/
func TestPayingBeforeTheTermEndsAddsToItRatherThanReplacingIt(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	ctx := context.Background()

	first := begun(t, s, pool, account, billing.ModelInstalments, 12)

	// A second year, bought while the first still has months to run.
	again, err := s.Begin(ctx, account, "", billing.ModelInstalments,
		price(t, pool, 69000), day(0), 12, nil)
	if err != nil {
		t.Fatalf("paying again before the term ended: %v", err)
	}

	want := first.PaidThrough.AddDate(0, 12, 0)
	if d := again.PaidThrough.Sub(want); d > time.Minute || d < -time.Minute {
		t.Errorf("a year bought on top of a year running left access to %s, want %s"+
			" — a second payment must never move the end date closer",
			again.PaidThrough.Format(time.DateOnly), want.Format(time.DateOnly))
	}
	if !again.PaidThrough.After(first.PaidThrough) {
		t.Error("paying again did not extend anything")
	}
}

/*
AND A LAPSED ONE STARTS FROM TODAY, which is the other half of the same rule.

	Somebody whose term ran out three months ago and pays now buys twelve months
	from today, not twelve from the day it lapsed — anything else charges them
	for a quarter they could not study. The rule is "the later of the two", and
	this is the branch where today is the later one.
*/
func TestPayingAfterItLapsedStartsFromTodayAndNotFromTheLapse(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	ctx := context.Background()

	// Begun thirteen months ago for a year, so it ran out about a month back.
	if _, err := s.Begin(ctx, account, "", billing.ModelInstalments,
		price(t, pool, 49000), day(-400), 12, nil); err != nil {
		t.Fatalf("beginning: %v", err)
	}

	again, err := s.Begin(ctx, account, "", billing.ModelInstalments,
		price(t, pool, 69000), day(0), 12, nil)
	if err != nil {
		t.Fatalf("paying after the lapse: %v", err)
	}

	want := day(0).AddDate(0, 12, 0)
	if d := again.PaidThrough.Sub(want); d > time.Minute || d < -time.Minute {
		t.Errorf("a lapsed subscription that paid again runs to %s, want %s",
			again.PaidThrough.Format(time.DateOnly), want.Format(time.DateOnly))
	}
}
