package billing_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"sync"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/billing"
)

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("SCHOOLING_TEST_DATABASE_URL")
	if url == "" {
		t.Skip("set SCHOOLING_TEST_DATABASE_URL to run the tests that need a database")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		t.Fatalf("opening the test database: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func student(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:16]+"@example.tld").Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

/*
price seeds one row of the platform's price series, and answers that row's id.

	IT IS A REAL ROW AND NOT AN INVENTED UUID, because `subscriptions.price_id`
	is a foreign key — which is the point of the column. A test that could point
	a subscription at a price nobody ever published would be testing something
	the database does not allow.
*/
func price(t *testing.T, pool *pgxpool.Pool, cents int) uuid.UUID {
	t.Helper()
	/* A SCOPE OF ITS OWN AND NOT 'all'. What this needs is a real row to point a
	   subscription at; what it must not do is publish a platform price, because
	   `plan_prices` is append-only and global — a helper that wrote the offer
	   would change what every other suite reads and could never take it back. */
	var row uuid.UUID
	if err := pool.QueryRow(context.Background(), `
		INSERT INTO plan_prices (scope, term_months, cents, currency)
		VALUES ($1, $2, $3, 'BRL') RETURNING id
	`, "test-ledger-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:12],
		billing.TermAnnual, cents).Scan(&row); err != nil {
		t.Fatalf("seeding a price: %v", err)
	}
	return row
}

// A unique provider reference per call, so tests do not collide on the
// idempotency index the way two runs of the same suite otherwise would.
func ref() string { return "evt_" + strings.ReplaceAll(uuid.NewString(), "-", "") }

func paid(t *testing.T, l *billing.Ledger, account uuid.UUID, cents int64) billing.Entry {
	t.Helper()
	entry, err := l.Record(context.Background(), billing.Entry{
		AccountID: account,
		Kind:      billing.KindPayment,
		Amount:    billing.MustNew(cents, billing.BRL),
		Source:    "gateway",
		SourceRef: ref(),
	})
	if err != nil {
		t.Fatalf("recording a payment of %d cents: %v", cents, err)
	}
	return entry
}

// THE ONE THAT MATTERS MOST. A gateway retries a webhook whenever it does not
// hear back in time — every one of them does, by design — so the same payment
// arriving twice is the normal case. Recorded twice, it would double a person's
// balance and, once subscriptions read this, extend their access for a payment
// they made once.
func TestTheSamePaymentArrivingTwiceIsRecordedOnce(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)

	event := billing.Entry{
		AccountID: account,
		Kind:      billing.KindPayment,
		Amount:    billing.MustNew(119900, billing.BRL),
		Source:    "gateway",
		SourceRef: ref(),
	}

	first, err := ledger.Record(context.Background(), event)
	if err != nil {
		t.Fatalf("the first delivery: %v", err)
	}

	again, err := ledger.Record(context.Background(), event)
	if !errors.Is(err, billing.ErrAlreadyRecorded) {
		t.Fatalf("the second delivery gave %v, want ErrAlreadyRecorded", err)
	}
	if again.ID != first.ID {
		t.Errorf("the retry answered entry %s and the first wrote %s — a handler that "+
			"treats a retry as a success needs the entry that already exists", again.ID, first.ID)
	}

	balance, err := ledger.Balance(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if balance.Cents() != 119900 {
		t.Errorf("after the same payment twice the balance is %s, want R$1.199,00", balance)
	}
}

// AND CONCURRENTLY, because that is how a retry actually arrives: the gateway
// gave up waiting on the first delivery, which is still running. A check-then-
// insert would let both through here and only here.
func TestTwoDeliveriesOfOnePaymentAtOnceStillRecordItOnce(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)

	event := billing.Entry{
		AccountID: account,
		Kind:      billing.KindPayment,
		Amount:    billing.MustNew(9990, billing.BRL),
		Source:    "gateway",
		SourceRef: ref(),
	}

	const deliveries = 8
	var wg sync.WaitGroup
	written := make([]error, deliveries)
	for i := range deliveries {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, written[i] = ledger.Record(context.Background(), event)
		}()
	}
	wg.Wait()

	accepted := 0
	for i, err := range written {
		switch {
		case err == nil:
			accepted++
		case errors.Is(err, billing.ErrAlreadyRecorded):
		default:
			t.Errorf("delivery %d failed with something other than a duplicate: %v", i, err)
		}
	}
	if accepted != 1 {
		t.Errorf("%d of %d simultaneous deliveries were written; exactly one should be",
			accepted, deliveries)
	}

	balance, err := ledger.Balance(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if balance.Cents() != 9990 {
		t.Errorf("the balance is %s after one payment delivered %d times", balance, deliveries)
	}
}

// A REFUND IS A NEW ROW, NEVER AN EDIT. The table refuses UPDATE and DELETE by
// trigger, so the only correction available is the one that leaves both halves
// visible.
func TestAHistoryCannotBeEditedOrDeleted(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	payment := paid(t, ledger, account, 119900)

	if _, err := pool.Exec(context.Background(),
		`UPDATE ledger_entries SET amount_cents = 1 WHERE id = $1`, payment.ID); err == nil {
		t.Error("a ledger entry was edited")
	}
	if _, err := pool.Exec(context.Background(),
		`DELETE FROM ledger_entries WHERE id = $1`, payment.ID); err == nil {
		t.Error("a ledger entry was deleted")
	}
}

// A REVERSAL UNDOES WHAT IT POINTS AT, and the balance says so.
func TestARefundIsARowThatPointsAtThePaymentItRefunds(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	payment := paid(t, ledger, account, 119900)

	refund, err := ledger.Record(context.Background(), billing.Entry{
		AccountID: account,
		Kind:      billing.KindRefund,
		Amount:    billing.MustNew(-119900, billing.BRL),
		Reverses:  &payment.ID,
		Source:    "gateway",
		SourceRef: ref(),
		Memo:      "asked for it back within the week",
	})
	if err != nil {
		t.Fatalf("recording a refund: %v", err)
	}
	if refund.Reverses == nil || *refund.Reverses != payment.ID {
		t.Error("the refund does not point at the payment it refunds")
	}

	balance, err := ledger.Balance(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if !balance.IsZero() {
		t.Errorf("after a full refund the balance is %s, want nothing", balance)
	}

	// And both halves are still there, which is what "append-only" buys.
	entries, err := ledger.Of(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 2 {
		t.Errorf("the ledger holds %d rows after a payment and a refund, want both", len(entries))
	}
}

// NOTHING IS REFUNDED TWICE. Without this, a hundred reais could be given back
// twice over and the balance would say we took money off somebody who had paid
// us nothing.
func TestAPaymentCannotBeRefundedForMoreThanItWas(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	payment := paid(t, ledger, account, 10000)

	part := func(cents int64) error {
		_, err := ledger.Record(context.Background(), billing.Entry{
			AccountID: account,
			Kind:      billing.KindRefund,
			Amount:    billing.MustNew(cents, billing.BRL),
			Reverses:  &payment.ID,
			Source:    "gateway",
			SourceRef: ref(),
		})
		return err
	}

	// Partial refunds are a real thing and are allowed up to the whole.
	if err := part(-4000); err != nil {
		t.Fatalf("a partial refund: %v", err)
	}
	if err := part(-6000); err != nil {
		t.Fatalf("the rest of it: %v", err)
	}

	// And one cent more is not.
	if err := part(-1); !errors.Is(err, billing.ErrNotAReversal) {
		t.Errorf("refunding a cent beyond the payment gave %v, want ErrNotAReversal", err)
	}

	balance, err := ledger.Balance(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if !balance.IsZero() {
		t.Errorf("the balance is %s after a payment refunded in two parts", balance)
	}
}

// AND NOT CONCURRENTLY EITHER. Two refunds of the same payment, arriving
// together, would each read the payment as un-refunded without the lock.
func TestTwoRefundsOfOnePaymentAtOnceCannotBothWin(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	payment := paid(t, ledger, account, 10000)

	const attempts = 6
	var wg sync.WaitGroup
	results := make([]error, attempts)
	for i := range attempts {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, results[i] = ledger.Record(context.Background(), billing.Entry{
				AccountID: account,
				Kind:      billing.KindRefund,
				Amount:    billing.MustNew(-10000, billing.BRL),
				Reverses:  &payment.ID,
				Source:    "gateway",
				SourceRef: ref(),
			})
		}()
	}
	wg.Wait()

	won := 0
	for _, err := range results {
		if err == nil {
			won++
		}
	}
	if won != 1 {
		t.Errorf("%d of %d simultaneous full refunds were written; exactly one can be",
			won, attempts)
	}

	balance, err := ledger.Balance(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if !balance.IsZero() {
		t.Errorf("the balance is %s after one payment refunded once", balance)
	}
}

// A REVERSAL THAT DOES NOT REVERSE IS REFUSED. Each of these would pass a
// foreign key and mean nothing.
func TestSomethingThatDoesNotUndoWhatItPointsAtIsRefused(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	payment := paid(t, ledger, account, 10000)
	missing := uuid.New()

	for _, c := range []struct {
		name  string
		entry billing.Entry
		want  error
	}{
		{"the same sign, so it adds instead of undoing", billing.Entry{
			AccountID: account, Kind: billing.KindRefund,
			Amount: billing.MustNew(10000, billing.BRL), Reverses: &payment.ID,
		}, billing.ErrNotAReversal},
		{"another currency", billing.Entry{
			AccountID: account, Kind: billing.KindRefund,
			Amount: billing.MustNew(-10000, billing.USD), Reverses: &payment.ID,
		}, billing.ErrNotAReversal},
		{"more than the payment was", billing.Entry{
			AccountID: account, Kind: billing.KindRefund,
			Amount: billing.MustNew(-10001, billing.BRL), Reverses: &payment.ID,
		}, billing.ErrNotAReversal},
		{"an entry that is not there", billing.Entry{
			AccountID: account, Kind: billing.KindRefund,
			Amount: billing.MustNew(-10000, billing.BRL), Reverses: &missing,
		}, billing.ErrNoSuchEntry},
	} {
		c.entry.Source, c.entry.SourceRef = "gateway", ref()

		if _, err := ledger.Record(context.Background(), c.entry); !errors.Is(err, c.want) {
			t.Errorf("%s: gave %v, want %v", c.name, err, c.want)
		}
	}
}

// AN ENTRY THAT IS NOT ONE never reaches the table. Zero is the interesting
// case: a movement of nothing is not a movement, and a row saying it happened
// is a line on a statement that cannot be explained.
func TestAnEntryThatIsNotOneIsRefused(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)

	for _, c := range []struct {
		name  string
		entry billing.Entry
	}{
		{"no account", billing.Entry{
			Kind: billing.KindPayment, Amount: billing.MustNew(100, billing.BRL), Source: "gateway"}},
		{"a kind nothing knows", billing.Entry{
			AccountID: account, Kind: "vanished",
			Amount: billing.MustNew(100, billing.BRL), Source: "gateway"}},
		{"no amount at all", billing.Entry{
			AccountID: account, Kind: billing.KindPayment, Source: "gateway"}},
		{"nothing moved", billing.Entry{
			AccountID: account, Kind: billing.KindPayment,
			Amount: billing.MustNew(0, billing.BRL), Source: "gateway"}},
		{"nothing says where it came from", billing.Entry{
			AccountID: account, Kind: billing.KindPayment,
			Amount: billing.MustNew(100, billing.BRL)}},
	} {
		if _, err := ledger.Record(context.Background(), c.entry); !errors.Is(err, billing.ErrBadEntry) {
			t.Errorf("%s: gave %v, want ErrBadEntry", c.name, err)
		}
	}
}

// A MANUAL ADJUSTMENT HAS NO PROVIDER REFERENCE, and two of them are not
// duplicates of each other. The idempotency index is partial for exactly this.
func TestTwoManualAdjustmentsAreNotDuplicatesOfEachOther(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)

	for i := range 2 {
		if _, err := ledger.Record(context.Background(), billing.Entry{
			AccountID: account,
			Kind:      billing.KindAdjustment,
			Amount:    billing.MustNew(500, billing.BRL),
			Source:    billing.SourceManual,
			Memo:      "goodwill",
		}); err != nil {
			t.Fatalf("adjustment %d: %v", i+1, err)
		}
	}

	balance, err := ledger.Balance(context.Background(), account)
	if err != nil {
		t.Fatal(err)
	}
	if balance.Cents() != 1000 {
		t.Errorf("two adjustments of R$5,00 came to %s", balance)
	}
}

// TWO CURRENCIES ON ONE ACCOUNT HAVE NO SINGLE BALANCE. Somebody who paid in
// reais and later abroad is a real person, and answering with one of the two
// numbers would be worse than refusing.
func TestAnAccountWithTwoCurrenciesHasNoOneBalance(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	paid(t, ledger, account, 119900)

	if _, err := ledger.Record(context.Background(), billing.Entry{
		AccountID: account,
		Kind:      billing.KindPayment,
		Amount:    billing.MustNew(9900, billing.USD),
		Source:    "gateway",
		SourceRef: ref(),
	}); err != nil {
		t.Fatalf("a payment in dollars: %v", err)
	}

	if _, err := ledger.Balance(context.Background(), account); !errors.Is(err, billing.ErrMixedCurrencies) {
		t.Errorf("an account with reais and dollars answered a balance: %v", err)
	}
}

// THE LEDGER OUTLIVES THE PERSON, and that is the arrangement rather than an
// oversight: the record that money changed hands cannot be deleted on request,
// and the identity that makes it somebody's can. After an erasure the row is
// still there and joins to nobody.
func TestErasingSomebodyLeavesTheMoneyAndTakesThePerson(t *testing.T) {
	pool := testPool(t)
	ledger := billing.NewLedger(pool)
	account := student(t, pool)
	paid(t, ledger, account, 119900)

	if _, err := pool.Exec(context.Background(),
		`DELETE FROM accounts WHERE id = $1`, account); err != nil {
		t.Fatalf("erasing the account: %v — a foreign key here would make erasure "+
			"impossible for anybody who ever paid", err)
	}

	var left int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM ledger_entries WHERE account_id = $1`, account).Scan(&left); err != nil {
		t.Fatal(err)
	}
	if left != 1 {
		t.Errorf("%d ledger rows survived the erasure, want the payment to still be there", left)
	}

	var joined int
	if err := pool.QueryRow(context.Background(), `
		SELECT count(*) FROM ledger_entries e JOIN accounts a ON a.id = e.account_id
		WHERE e.account_id = $1
	`, account).Scan(&joined); err != nil {
		t.Fatal(err)
	}
	if joined != 0 {
		t.Errorf("the surviving row still joins to a person (%d rows)", joined)
	}
}
