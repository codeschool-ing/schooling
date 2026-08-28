package billing_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/billing"
)

/*
The purchase history: what somebody has bought, as a list they can read.

	THE CLAIM IS THAT IT IS THE CHECKOUT AND NOT THE LEDGER. Those two look alike
	and are not — an instalment plan is ONE sale collected several times, and the
	ledger is keyed by the charge — which is why the first test here buys in
	three parts and insists on seeing one line.
*/

// sold opens a checkout and has the gateway answer it with a charge. What it
// does NOT do is pay it: the ledger row and the subscription are the caller's,
// because half these tests are about the rows that never got that far.
func sold(t *testing.T, pool *pgxpool.Pool, account, price uuid.UUID,
	cents int, method billing.Method, instalments int, charge string) billing.Intent {

	t.Helper()
	ctx := context.Background()
	buys := billing.NewCheckouts(pool, anybody)

	intent, err := buys.Open(ctx, account, "", price, cents, "BRL", method, instalments, "asaas")
	if err != nil {
		t.Fatalf("opening a checkout: %v", err)
	}
	// THE CHARGED ONE AND NOT THE OPENED ONE. `Open` answers a row with no
	// charge on it yet, and the join this file is about hangs off that column.
	charged, err := buys.Charged(ctx, intent.ID, charge, "https://pay.example.tld/"+charge)
	if err != nil {
		t.Fatalf("charging it: %v", err)
	}
	return charged
}

// TestAPurchaseIsTheSaleAndNotEachInstalmentOfIt is the shape the ledger cannot
// give. Three payments of R$ 363,33 are one purchase of R$ 1.090,00, and a
// student reading three prices they never agreed to is a support message.
func TestAPurchaseIsTheSaleAndNotEachInstalmentOfIt(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, price := student(t, pool), anOffer(t, pool)
	ledger := billing.NewLedger(pool)
	buys := billing.NewCheckouts(pool, anybody)

	intent := sold(t, pool, account, price, listed, billing.MethodCard, 3, "pay_"+short())

	// Three collections of the one authorisation, each a ledger row of its own —
	// which is what `Settlement.paid` writes, and what this must NOT count.
	for i, part := range []int{19667, 19667, 19666} {
		if _, err := ledger.Record(ctx, billing.Entry{
			AccountID: account, Kind: billing.KindPayment,
			Amount:    money(t, part),
			Source:    "asaas",
			SourceRef: intent.ChargeID + "-" + string(rune('a'+i)),
		}); err != nil {
			t.Fatalf("recording instalment %d: %v", i+1, err)
		}
	}

	bought, err := buys.Purchases(ctx, account)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(bought) != 1 {
		t.Fatalf("a plan collected in three parts reads as %d purchases", len(bought))
	}
	if bought[0].Cents != listed {
		t.Errorf("the sale reads as %d and they agreed to %d", bought[0].Cents, listed)
	}
	if bought[0].Instalments != 3 {
		t.Errorf("it reads as %d instalments", bought[0].Instalments)
	}
	if bought[0].Method != billing.MethodCard {
		t.Errorf("it reads as paid by %s", bought[0].Method)
	}
}

/*
TestAPurchaseCarriesWhatWasChargedAndWhatWasOnTheShelf.

	BOTH NUMBERS OR THE DISCOUNT IS UNEXPLAINABLE. A Pix sale is charged at five
	per cent under the listed price, so a history showing only what was charged
	leaves somebody comparing R$ 560,50 against a R$ 590,00 offer with no way to
	tell whether they were overcharged or given something.
*/
func TestAPurchaseCarriesWhatWasChargedAndWhatWasOnTheShelf(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, price := student(t, pool), anOffer(t, pool)
	buys := billing.NewCheckouts(pool, anybody)

	const charged = 56050 // `listed` less the five per cent a Pix payment gets
	sold(t, pool, account, price, charged, billing.MethodPix, 1, "pay_"+short())

	bought, err := buys.Purchases(ctx, account)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(bought) != 1 {
		t.Fatalf("one purchase reads as %d", len(bought))
	}
	if bought[0].Cents != charged {
		t.Errorf("it says %d was charged and it was %d", bought[0].Cents, charged)
	}
	if bought[0].Listed != listed {
		t.Errorf("it says the offer was %d and it was %d", bought[0].Listed, listed)
	}
	if bought[0].TermMonths != 12 {
		t.Errorf("it says the term was %d months", bought[0].TermMonths)
	}
	if bought[0].Currency != "BRL" {
		t.Errorf("it says the currency is %q", bought[0].Currency)
	}
}

/*
TestAPurchaseSaysWhereItLeftTheTerm, which is the answer somebody came for.

	"WHAT DID THAT PAYMENT BUY ME" IS THE QUESTION, and it is three tables away:
	the subscription event knows the ledger row that caused it, the ledger row
	knows the charge the money came on, and the charge is what the checkout was
	answered with. Each of the three was written by whoever knew it, and this is
	the read that puts them back together.
*/
func TestAPurchaseSaysWhereItLeftTheTerm(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, price := student(t, pool), anOffer(t, pool)
	buys := billing.NewCheckouts(pool, anybody)
	ledger := billing.NewLedger(pool)
	plans := billing.NewStore(pool)

	intent := sold(t, pool, account, price, listed, billing.MethodPix, 1, "pay_"+short())

	entry, err := ledger.Record(ctx, billing.Entry{
		AccountID: account, Kind: billing.KindPayment, Amount: money(t, listed),
		Source: "asaas", SourceRef: intent.ChargeID,
	})
	if err != nil {
		t.Fatalf("recording the payment: %v", err)
	}
	held, err := plans.Begin(ctx, account, "", billing.ModelInstalments,
		price, day(0), 12, &entry.ID)
	if err != nil {
		t.Fatalf("opening the subscription: %v", err)
	}

	bought, err := buys.Purchases(ctx, account)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(bought) != 1 {
		t.Fatalf("one purchase reads as %d", len(bought))
	}
	if bought[0].PaidThrough == nil {
		t.Fatal("the purchase does not say what it bought — nothing joined the term to it")
	}
	if !bought[0].PaidThrough.Equal(held.PaidThrough) {
		t.Errorf("the purchase says access runs to %s and it runs to %s",
			bought[0].PaidThrough.Format(time.DateOnly), held.PaidThrough.Format(time.DateOnly))
	}
}

/*
TestACheckoutNOBODYPAIDIsStillInTheHistory.

	THE ROWS THAT WENT NOWHERE ARE THE ONES PEOPLE WRITE IN ABOUT. "I tried to
	subscribe and nothing happened" is a checkout that stopped at `opened`; "I
	have a Pix code, is it still good" is one at `charged`. A history of
	successes answers neither, and the second one still has the address to send
	them back to.
*/
func TestACheckoutNOBODYPAIDIsStillInTheHistory(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, price := student(t, pool), anOffer(t, pool)
	buys := billing.NewCheckouts(pool, anybody)

	sold(t, pool, account, price, listed, billing.MethodPix, 1, "pay_"+short())

	bought, err := buys.Purchases(ctx, account)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(bought) != 1 {
		t.Fatalf("an unpaid checkout reads as %d purchases, want the one", len(bought))
	}
	if bought[0].Stage != billing.StageCharged {
		t.Errorf("it reads as %q", bought[0].Stage)
	}
	if bought[0].PaidThrough != nil {
		t.Errorf("a checkout nobody paid says it bought access to %s", bought[0].PaidThrough)
	}
	if bought[0].InvoiceURL == "" {
		t.Error("no address came back, so a screen cannot send somebody back to the code " +
			"they were given")
	}
	if _, spent := bought[0].Spent(); spent {
		t.Error("a checkout nobody paid counts as money spent")
	}
}

// NEWEST FIRST, because a history is read from the top and the line somebody
// wants is nearly always the last thing that happened.
func TestTheHistoryIsNewestFirst(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, price := student(t, pool), anOffer(t, pool)
	buys := billing.NewCheckouts(pool, anybody)

	first := sold(t, pool, account, price, listed, billing.MethodPix, 1, "pay_"+short())
	// A second, a moment later. The column defaults to now() and the two would
	// otherwise be ordered by whatever the index felt like.
	if _, err := pool.Exec(ctx,
		`UPDATE checkout_intents SET created_at = now() - interval '400 days' WHERE id = $1`,
		first.ID); err != nil {
		t.Fatal(err)
	}
	second := sold(t, pool, account, price, listed, billing.MethodCard, 6, "pay_"+short())

	bought, err := buys.Purchases(ctx, account)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(bought) != 2 {
		t.Fatalf("two purchases read as %d", len(bought))
	}
	if bought[0].ID != second.ID {
		t.Error("the history starts with the older purchase")
	}
	if bought[1].ID != first.ID {
		t.Error("the older purchase is not at the bottom")
	}
}

// SOMEBODY ELSE'S PURCHASES ARE NOT IN IT, which is the assertion worth having
// on any read keyed by an account: a join that lost its WHERE would pass every
// other test in this file.
func TestOnlyTheirOwnPurchasesComeBack(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	price := anOffer(t, pool)
	buys := billing.NewCheckouts(pool, anybody)

	mine, theirs := student(t, pool), student(t, pool)
	sold(t, pool, mine, price, listed, billing.MethodPix, 1, "pay_"+short())
	sold(t, pool, theirs, price, listed, billing.MethodPix, 1, "pay_"+short())

	bought, err := buys.Purchases(ctx, mine)
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if len(bought) != 1 {
		t.Fatalf("one person's history has %d purchases in it", len(bought))
	}
}

// SOMEBODY WHO HAS BOUGHT NOTHING GETS AN EMPTY LIST AND NOT A NIL, so the
// answer serialises as `[]` rather than as `null` — a screen cannot tell the
// second from a version that does not send the field.
func TestNoPurchasesIsAnEmptyListAndNotNothing(t *testing.T) {
	pool := testPool(t)
	buys := billing.NewCheckouts(pool, anybody)

	bought, err := buys.Purchases(context.Background(), student(t, pool))
	if err != nil {
		t.Fatalf("reading the history: %v", err)
	}
	if bought == nil {
		t.Error("it came back nil, which is `null` on the wire")
	}
	if len(bought) != 0 {
		t.Errorf("somebody who has bought nothing has %d purchases", len(bought))
	}
}

// anybody is the confirmation gate, always yes. These tests are about reading
// what was bought and not about who may start buying — that is checkout_test's.
func anybody(context.Context, uuid.UUID) (bool, error) { return true, nil }

func money(t *testing.T, cents int) billing.Money {
	t.Helper()
	m, err := billing.New(int64(cents), "BRL")
	if err != nil {
		t.Fatalf("%d is not money: %v", cents, err)
	}
	return m
}

// short is a charge id nobody else in this suite will produce. The unique index
// on (provider, provider_charge_id) is partial and real, so two tests sharing a
// literal would fail whichever ran second.
func short() string { return uuid.NewString()[:18] }
