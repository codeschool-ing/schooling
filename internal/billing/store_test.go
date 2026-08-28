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

	/* THE RENEWAL IS SOLD AT A NEW PRICE AND THE ROW MOVES ONTO IT.

	   THIS ASSERTED THE OPPOSITE UNTIL `0043`, from `0036`'s belief that the
	   column froze what somebody bought at — that a renewal charged the stored
	   row rather than whatever is current. `0040` corrected that: the terms of
	   use promise a price change applies to new subscriptions AND TO RENEWALS
	   with thirty days' notice, never retroactively to a term that is running.
	   The store went on writing the old id anyway, because until the account
	   screen existed nothing read it.

	   It is read now, and frozen it quoted the price of a year somebody bought
	   three years ago as the thing they had just paid for.

	   WHAT THE OLD ASSERTION PROTECTED IS STILL PROTECTED, elsewhere and
	   better: the purchase at the old price is a `checkout_intents` row and a
	   line in `subscription_events`, both of which keep their own price and are
	   never rewritten. This column is what a subscription stands at today. */
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
	if again.PriceID != raised {
		t.Errorf("paying again left the subscription on %s, and they bought %s",
			again.PriceID, raised)
	}

	// AND ON THE ROW, not only in the value handed back — which is the half a
	// caller cannot see, and the half every later screen reads.
	var stored uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`SELECT price_id FROM subscriptions WHERE id = $1`, first.ID).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if stored != raised {
		t.Errorf("the stored price is %s and they bought %s", stored, raised)
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

/*
TestSomethingThatIsNotAPurchaseLeavesThePriceAlone is the other half of the one
above, and the half that is easy to lose.

	A REFUND IS NOT A SALE AND HAS NO PRICE. `Advance` carries every event that
	happens TO a subscription — a refund, a chargeback, a cancellation, a term
	running out — and none of them is somebody agreeing to a number. It passes
	`uuid.Nil`, and the write has to read that as "leave it" rather than as a
	value: blanking the column would take away the one fact that explains what a
	person was paying when the money went back.
*/
func TestSomethingThatIsNotAPurchaseLeavesThePriceAlone(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	first := begun(t, s, pool, account, billing.ModelInstalments, 12)

	after, err := s.Advance(context.Background(), account, "",
		billing.EventRefunded, day(30), time.Time{}, nil)
	if err != nil {
		t.Fatalf("refunding: %v", err)
	}
	if after.PriceID != first.PriceID {
		t.Errorf("a refund moved the price to %s (was %s)", after.PriceID, first.PriceID)
	}

	var stored uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`SELECT price_id FROM subscriptions WHERE id = $1`, first.ID).Scan(&stored); err != nil {
		t.Fatal(err)
	}
	if stored != first.PriceID {
		t.Errorf("the stored price became %s after a refund (was %s)", stored, first.PriceID)
	}
}

/*
TestTheLogSaysWhatEachTransitionCostAndWhereItLeftTheTerm.

	THE LOG IS THE ONLY PLACE THE ANSWER SURVIVES. `subscriptions` holds one
	price and one date, both overwritten by the next purchase; somebody asking
	in 2029 what their 2026 renewal bought them is asking about values that row
	stopped holding three payments ago. `0043` put them on the line that recorded
	the transition, where nothing rewrites them.
*/
func TestTheLogSaysWhatEachTransitionCostAndWhereItLeftTheTerm(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	first := begun(t, s, pool, account, billing.ModelInstalments, 12)

	raised := price(t, pool, 59000)
	again, err := s.Begin(context.Background(), account, "",
		billing.ModelInstalments, raised, day(400), 12, nil)
	if err != nil {
		t.Fatalf("a second sale: %v", err)
	}

	lines, err := s.History(context.Background(), account)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(lines) != 2 {
		t.Fatalf("two payments left %d lines in the log", len(lines))
	}

	// Newest first, so the renewal is line zero.
	renewal, opening := lines[0], lines[1]

	for name, line := range map[string]billing.Transition{"the renewal": renewal, "the opening": opening} {
		if line.PriceID == nil {
			t.Fatalf("%s recorded no price", name)
		}
		if line.PaidThrough == nil {
			t.Fatalf("%s recorded no date", name)
		}
	}

	if *renewal.PriceID != raised {
		t.Errorf("the renewal was logged at %s and was sold at %s", *renewal.PriceID, raised)
	}
	/* AND THE OPENING KEPT ITS OWN, which is the property the whole thing is
	   for: the subscription has moved onto the new price, and the line that
	   recorded the old purchase still says what that purchase cost. */
	if *opening.PriceID != first.PriceID {
		t.Errorf("the first sale was logged at %s and was sold at %s",
			*opening.PriceID, first.PriceID)
	}
	if *opening.PriceID == *renewal.PriceID {
		t.Error("both lines were logged at the same price, so the log was rewritten")
	}

	if !renewal.PaidThrough.Equal(again.PaidThrough) {
		t.Errorf("the renewal logged access running to %s and it runs to %s",
			renewal.PaidThrough, again.PaidThrough)
	}
	if !opening.PaidThrough.Equal(first.PaidThrough) {
		t.Errorf("the first sale logged access running to %s and it ran to %s",
			opening.PaidThrough, first.PaidThrough)
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

	/* AND IT IS ON THE ROW. Everything above reads the value `Begin` handed
	   back, which `apply` builds in memory — so all of it passed while the
	   renewal was being rolled back and nothing was written at all. See
	   TestARenewalIsWrittenDownAndNotRolledBack below. */
	stored, err := s.Of(ctx, account, "", day(0))
	if err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if !stored.PaidThrough.Equal(again.PaidThrough) {
		t.Errorf("the answer says access runs to %s and the row says %s",
			again.PaidThrough.Format(time.DateOnly), stored.PaidThrough.Format(time.DateOnly))
	}
}

/*
TestARenewalIsWrittenDownAndNotRolledBack.

	`Begin` OWNS ITS TRANSACTION AND HAS TO END IT. `apply` deliberately does
	not commit — `Advance` needs the read and the write in one, and says so —
	and the branch of `Begin` that renews an existing subscription returned
	`apply`'s value straight out, so the deferred rollback threw the renewal
	away. The subscription kept its old end date and the log got no line.

	IT SURVIVED EVERY TEST THIS FILE HAD, because all of them asserted on the
	`Held` that came back and that value was correct: it is built in memory from
	the state machine, and never re-read. In production it is a renewal that took
	the money, wrote the ledger, marked the checkout paid, and gave nobody a day
	of access.

	SO THIS TEST NEVER LOOKS AT THE RETURN VALUE. Everything it asserts is read
	back out of the database afterwards, which is the only way this class of bug
	is visible at all.
*/
func TestARenewalIsWrittenDownAndNotRolledBack(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	ctx := context.Background()

	begun(t, s, pool, account, billing.ModelInstalments, 12)

	before, err := s.Of(ctx, account, "", day(0))
	if err != nil {
		t.Fatalf("reading the first term: %v", err)
	}
	lines := transitions(t, pool, account)

	if _, err := s.Begin(ctx, account, "", billing.ModelInstalments,
		price(t, pool, 69000), day(0), 12, nil); err != nil {
		t.Fatalf("renewing: %v", err)
	}

	after, err := s.Of(ctx, account, "", day(0))
	if err != nil {
		t.Fatalf("reading it back: %v", err)
	}
	if !after.PaidThrough.After(before.PaidThrough) {
		t.Errorf("the row still says access runs to %s after a second year was paid for — "+
			"the renewal was rolled back", after.PaidThrough.Format(time.DateOnly))
	}

	// AND THE LOG HAS THE LINE, which is the half somebody needs a year later
	// when they ask what that second payment bought them.
	if grew := transitions(t, pool, account) - lines; grew != 1 {
		t.Errorf("the renewal wrote %d lines to the log, want one", grew)
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

/*
TestGrantedTimeIsAddedAndIsNotASale.

	THE CONSOLE NEEDED THIS AND THE STATE MACHINE ALREADY HAD HALF OF IT. An
	operator making good on an outage was, until now, a person with a SQL
	client — and the honest version of that act has two halves the machine could
	not express together: extend the term, and do NOT say it was bought.
*/
func TestGrantedTimeIsAddedAndIsNotASale(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	ctx := context.Background()

	first := begun(t, s, pool, account, billing.ModelInstalments, 12)

	given, err := s.Grant(ctx, account, "", 30, day(0))
	if err != nil {
		t.Fatalf("granting a month: %v", err)
	}

	want := first.PaidThrough.AddDate(0, 0, 30)
	if !given.PaidThrough.Equal(want) {
		t.Errorf("thirty days on top of a running year ended at %s, want %s",
			given.PaidThrough.Format(time.DateOnly), want.Format(time.DateOnly))
	}

	// AND ON THE ROW, because `apply` builds the answer in memory — which is
	// how a renewal was rolled back for as long as the file existed.
	stored, err := s.Of(ctx, account, "", day(0))
	if err != nil {
		t.Fatal(err)
	}
	if !stored.PaidThrough.Equal(given.PaidThrough) {
		t.Errorf("the answer says %s and the row says %s",
			given.PaidThrough.Format(time.DateOnly), stored.PaidThrough.Format(time.DateOnly))
	}

	/* THE LOG SAYS `granted` AND NOT `paid`, which is the half that is easy to
	   lose and impossible to recover. Recorded as a payment, this would be a
	   sale nobody made, counted against revenue a year later by somebody
	   wondering where the money went. */
	lines, err := s.History(ctx, account)
	if err != nil {
		t.Fatal(err)
	}
	if len(lines) != 2 {
		t.Fatalf("a purchase and a grant left %d lines", len(lines))
	}
	if lines[0].Event != billing.EventGranted {
		t.Errorf("the grant was logged as %q", lines[0].Event)
	}
	if lines[0].LedgerEntryID != nil {
		t.Error("the grant names a ledger row, so somewhere it was written down as money")
	}

	// AND NO MONEY MOVED. The ledger is what says it did, and it must be empty.
	var rows int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM ledger_entries WHERE account_id = $1`, account).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Errorf("granting time wrote %d ledger rows", rows)
	}
}

// A GRANT REVIVES A TERM THAT RAN OUT, and starts from today rather than from
// the day it lapsed — the same rule a payment follows, because giving somebody
// thirty days three months after their access stopped must be thirty days they
// can use.
func TestGrantingAfterItLapsedStartsFromToday(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	ctx := context.Background()

	begun(t, s, pool, account, billing.ModelInstalments, 12)
	if _, err := s.Settle(ctx, day(400)); err != nil {
		t.Fatal(err)
	}

	given, err := s.Grant(ctx, account, "", 30, day(500))
	if err != nil {
		t.Fatalf("granting after it lapsed: %v", err)
	}
	if given.State != billing.StateActive {
		t.Errorf("a grant left a lapsed subscription %s", given.State)
	}
	want := day(500).AddDate(0, 0, 30)
	if !given.PaidThrough.Equal(want) {
		t.Errorf("it runs to %s, want thirty days from today (%s)",
			given.PaidThrough.Format(time.DateOnly), want.Format(time.DateOnly))
	}
}

/*
TestGrantingToSomebodyWithNoSubscriptionIsRefused.

	EXTENDING A TERM AND GIVING ONE ARE DIFFERENT ACTS. The second has to say
	what it was sold at — `price_id` is NOT NULL and is what keeps a March
	invoice explicable in November — and there is no honest number for a
	subscription nobody bought. A grant that invented one would put a price in
	the books that nobody agreed to and nobody paid.
*/
func TestGrantingToSomebodyWithNoSubscriptionIsRefused(t *testing.T) {
	s, pool := store(t)

	_, err := s.Grant(context.Background(), student(t, pool), "", 30, day(0))
	if !errors.Is(err, billing.ErrNothingToExtend) {
		t.Errorf("granting to somebody with no subscription gave %v, want ErrNothingToExtend", err)
	}
}

// THE PRICE STAYS WHERE IT IS. A grant is not somebody agreeing to a number,
// and moving the column would rewrite what their running term was sold at with
// nothing to put in its place.
func TestAGrantLeavesThePriceAlone(t *testing.T) {
	s, pool := store(t)
	account := student(t, pool)
	first := begun(t, s, pool, account, billing.ModelInstalments, 12)

	given, err := s.Grant(context.Background(), account, "", 14, day(0))
	if err != nil {
		t.Fatal(err)
	}
	if given.PriceID != first.PriceID {
		t.Errorf("a grant moved the price to %s (was %s)", given.PriceID, first.PriceID)
	}
}
