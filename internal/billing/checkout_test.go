package billing_test

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* A purchase being attempted, against a real Postgres.

   THE GATE IS THE SUBJECT OF HALF OF THIS FILE, because its placement was got
   wrong once: it was proposed for `Begin`, approved, and caught while reading
   the code — `Begin` runs after a payment has SUCCEEDED, so a guard there
   refuses the subscription of somebody who has already been charged. These
   tests hold it where it belongs, which is the one door money goes through. */

// confirmed is the collaborator `cmd` wires to identity. Here it answers
// whatever the test needs, including an error, which is the case that matters.
func checkouts(t *testing.T, answer func(uuid.UUID) (bool, error)) (*billing.Checkouts, *pgxpool.Pool) {
	t.Helper()
	pool := testPool(t)
	return billing.NewCheckouts(pool, func(_ context.Context, id uuid.UUID) (bool, error) {
		return answer(id)
	}), pool
}

func confirmed(uuid.UUID) (bool, error) { return true, nil }

/*
anOffer seeds a price to buy under, in a scope of its own so that runs do not
read each other's rows — `plan_prices` is append-only and global.

	THE NUMBER IS FIXED AND IS THE POINT. Every checkout below is opened at
	56050, which is `listed` less the five per cent a Pix payment gets, so "what
	was charged" and "what it was sold under" are never the same number by
	accident.
*/
const listed = 59000

func anOffer(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(), `
		INSERT INTO plan_prices (scope, term_months, cents, currency)
		VALUES ($1, 12, $2, 'BRL') RETURNING id
	`, "test-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:16], listed).Scan(&id); err != nil {
		t.Fatalf("seeding a price: %v", err)
	}
	return id
}

func open(t *testing.T, c *billing.Checkouts, account, price uuid.UUID) (billing.Intent, error) {
	t.Helper()
	return c.Open(context.Background(), account, "", price, 56050, "BRL",
		billing.MethodPix, 1, "asaas")
}

/*
AN UNCONFIRMED ADDRESS CANNOT START A PAYMENT, AND THAT IS ALL IT CANNOT DO.

	The decision is ROADMAP.md's and it is one sentence: confirmation is
	required to START a payment and never to finish one. This is the start.
*/
func TestAnUnconfirmedAddressCannotOpenACheckout(t *testing.T) {
	store, pool := checkouts(t, func(uuid.UUID) (bool, error) { return false, nil })
	account, price := student(t, pool), anOffer(t, pool)

	_, err := open(t, store, account, price)
	if !errors.Is(err, billing.ErrNotConfirmed) {
		t.Fatalf("it answered %v", err)
	}

	var rows int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM checkout_intents WHERE account_id = $1`, account).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Errorf("it wrote %d row(s) for a checkout it refused", rows)
	}
}

/*
AND A CHECK THAT COULD NOT BE MADE IS A NO.

	This is the opposite of `notify.mayWrite`, where a failed lookup means "send
	it anyway", and the two are opposite deliberately. Not writing to somebody
	is a nuisance; charging somebody the platform could not check is money, and
	the apology for it is a refund.
*/
func TestAConfirmationThatCouldNotBeCheckedIsARefusal(t *testing.T) {
	store, pool := checkouts(t, func(uuid.UUID) (bool, error) {
		return false, fmt.Errorf("the database is not there")
	})
	account, price := student(t, pool), anOffer(t, pool)

	if _, err := open(t, store, account, price); !errors.Is(err, billing.ErrNotConfirmed) {
		t.Errorf("it answered %v", err)
	}
}

// AND A STORE NOBODY WIRED THE GATE INTO REFUSES EVERYTHING. It is a mistake in
// `cmd` rather than a request anybody got wrong, and the alternative — charging
// on with no check — is what this whole arrangement exists to prevent.
func TestAStoreWithNoGateRefuses(t *testing.T) {
	pool := testPool(t)
	store := billing.NewCheckouts(pool, nil)
	account, price := student(t, pool), anOffer(t, pool)

	if _, err := open(t, store, account, price); !errors.Is(err, billing.ErrNotConfirmed) {
		t.Errorf("it answered %v", err)
	}
}

/*
THE ROW EXISTS BEFORE THE GATEWAY IS CALLED, AND CARRIES NO CHARGE YET.

	That order is the point of the table. Calling first and recording afterwards
	fails as a payable invoice belonging to nobody; this way round it fails as a
	row nobody paid, which is evidence.
*/
func TestOpeningWritesTheRowAndNoCharge(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)

	one, err := open(t, store, account, price)
	if err != nil {
		t.Fatalf("opening: %v", err)
	}
	if one.ID == uuid.Nil {
		t.Error("it came back with no id, and the id is what the gateway carries")
	}
	if one.Stage != billing.StageOpened {
		t.Errorf("it opened at stage %q", one.Stage)
	}
	if one.ChargeID != "" || one.InvoiceURL != "" {
		t.Errorf("it already has a charge: %q %q", one.ChargeID, one.InvoiceURL)
	}
	if one.Scope != billing.ScopeEverything {
		t.Errorf("its scope is %q", one.Scope)
	}

	// AND WHAT WAS CHARGED IS NOT THE PRICE. 56050 is 590 less the five per
	// cent a Pix payment gets; the price row still says 59000, and renewal
	// charges that. A table that stored only one of the two numbers could not
	// answer both questions.
	if one.Cents != 56050 {
		t.Errorf("it recorded %d as what was asked for", one.Cents)
	}
	var priced int
	if err := pool.QueryRow(context.Background(),
		`SELECT cents FROM plan_prices WHERE id = $1`, one.PriceID).Scan(&priced); err != nil {
		t.Fatal(err)
	}
	if priced != listed {
		t.Errorf("the price it points at says %d", priced)
	}
}

// TWO CLICKS ARE TWO ROWS AND THAT IS ORDINARY. A slow connection makes them,
// and only one will ever carry a charge — which is why the unique index is on
// the charge and not on the person.
func TestTwoClicksAreTwoOpenRows(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)

	first, err := open(t, store, account, price)
	if err != nil {
		t.Fatal(err)
	}
	second, err := open(t, store, account, price)
	if err != nil {
		t.Fatalf("a second click answered %v", err)
	}
	if first.ID == second.ID {
		t.Error("two clicks produced one row, which is a click that did nothing")
	}
}

// WHAT THIS PLATFORM DOES NOT SELL IS REFUSED HERE. Debit is the one somebody
// will reach for, and a split Pix is the other: the bank does not do it, and a
// checkout that took the request would fail at the gateway with the money's
// worth of confusion already on the screen.
func TestWhatIsNotSoldIsRefused(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)
	ctx := context.Background()

	if _, err := store.Open(ctx, account, "", price, listed, "BRL",
		"debit", 1, "asaas"); !errors.Is(err, billing.ErrNoMethod) {
		t.Errorf("debit answered %v", err)
	}
	if _, err := store.Open(ctx, account, "", price, listed, "BRL",
		billing.MethodPix, 6, "asaas"); !errors.Is(err, billing.ErrNotSplittable) {
		t.Errorf("a split Pix answered %v", err)
	}
	if _, err := store.Open(ctx, account, "", price, 0, "BRL",
		billing.MethodCard, 1, "asaas"); !errors.Is(err, billing.ErrNotAPrice) {
		t.Errorf("a charge for nothing answered %v", err)
	}
}

// AND THE DATABASE REFUSES THE SPLIT PIX TOO, from the other side. The check in
// Go says which half was wrong; the constraint is what makes it true of every
// row rather than of every row this code wrote.
func TestTheColumnsRefuseASplitPix(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)
	_ = store

	if _, err := pool.Exec(context.Background(), `
		INSERT INTO checkout_intents
			(account_id, price_id, cents, currency, method, instalments, provider)
		VALUES ($1, $2, 59000, 'BRL', 'pix', 6, 'asaas')
	`, account, price); err == nil {
		t.Error("a Pix payment was split in six")
	}
}

/*
A CHARGE IS RECORDED ONCE, AND A SECOND ATTEMPT SAYS WHY IT WAS REFUSED.

	The unique index would refuse it too, from a different direction. This says
	WHICH checkout, and it says so before somebody holds two invoices for one
	purchase.
*/
func TestACheckoutTakesOneCharge(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)
	ctx := context.Background()

	one, err := open(t, store, account, price)
	if err != nil {
		t.Fatal(err)
	}

	/* THE IDS ARE FRESH EVERY RUN. `pay_first` was written here first and the
	   second run failed on the unique index — nothing empties this table between
	   runs, which is the same trap the price series set earlier. */
	first := "pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]
	second := "pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]

	charged, err := store.Charged(ctx, one.ID, first, "https://pay.example/1")
	if err != nil {
		t.Fatalf("recording a charge: %v", err)
	}
	if charged.Stage != billing.StageCharged {
		t.Errorf("it is at stage %q", charged.Stage)
	}
	if charged.InvoiceURL != "https://pay.example/1" {
		t.Errorf("the payer is sent to %q", charged.InvoiceURL)
	}

	if _, err := store.Charged(ctx, one.ID, second, "https://pay.example/2"); !errors.Is(
		err, billing.ErrNotOpen) {
		t.Errorf("a second charge answered %v", err)
	}

	// AND A CHECKOUT NOBODY OPENED IS A DIFFERENT ANSWER, because "there is no
	// such thing" and "that one has moved on" send a caller to different places.
	if _, err := store.Charged(ctx, uuid.New(), "pay_x", ""); !errors.Is(err, billing.ErrNoIntent) {
		t.Errorf("charging a checkout nobody opened answered %v", err)
	}
}

/*
THE WEBHOOK'S TWO WAYS IN BOTH REACH THE SAME ROW.

	An event carries our reference — the id — which is the first. The second is
	the gateway's own charge id, which is what a delivery that carries only
	theirs has to be resolved by.
*/
func TestACheckoutIsFoundByOurIdAndByTheirs(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)
	ctx := context.Background()

	one, err := open(t, store, account, price)
	if err != nil {
		t.Fatal(err)
	}
	charge := "pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]
	if _, err := store.Charged(ctx, one.ID, charge, ""); err != nil {
		t.Fatal(err)
	}

	byOurs, err := store.ByID(ctx, one.ID)
	if err != nil {
		t.Fatal(err)
	}
	byTheirs, err := store.ByCharge(ctx, "asaas", charge)
	if err != nil {
		t.Fatalf("finding it by their id: %v", err)
	}
	if byOurs.ID != byTheirs.ID {
		t.Errorf("the two ways in found %s and %s", byOurs.ID, byTheirs.ID)
	}
	if _, err := store.ByCharge(ctx, "asaas", "pay_nobody"); !errors.Is(err, billing.ErrNoIntent) {
		t.Errorf("a charge nobody has answered %v", err)
	}
}

/*
SETTLING IS IDEMPOTENT AND A LATE EVENT CANNOT UNDO MONEY.

	At-least-once delivery makes a repeat the normal case rather than the
	exception. And an `OVERDUE` arriving after a `CONFIRMED` — which sequential
	delivery makes unlikely and not impossible — must not turn a paid checkout
	into an abandoned one.
*/
func TestSettlingTwiceIsSettledAndAbandoningAPaidOneIsNot(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)
	ctx := context.Background()

	one, err := open(t, store, account, price)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := store.Charged(ctx, one.ID, "pay_"+one.ID.String()[:8], ""); err != nil {
		t.Fatal(err)
	}

	/* AND `first` IS TRUE EXACTLY ONCE, which is what keeps six instalments of
	   one plan from buying six terms: every one of them settles this checkout
	   and only the one that moved it bought anything. */
	for i := range 2 {
		got, first, err := store.Settled(ctx, one.ID)
		if err != nil {
			t.Fatalf("settling the %d time: %v", i+1, err)
		}
		if got.Stage != billing.StagePaid {
			t.Errorf("after settling it is at %q", got.Stage)
		}
		if want := i == 0; first != want {
			t.Errorf("settling the %d time answered first=%v", i+1, first)
		}
	}

	got, err := store.Abandoned(ctx, one.ID)
	if err != nil {
		t.Fatal(err)
	}
	if got.Stage != billing.StagePaid {
		t.Errorf("a late event took a paid checkout to %q", got.Stage)
	}
}

/*
THE HANDLE IS REMEMBERED AND THE TAX ID IS NOT.

	Charging in Brazil needs a CPF or CNPJ. It is sent to the gateway and kept
	nowhere here: what this table holds is the opaque string they answered with,
	and `RememberCustomer` has no argument for the number — which is deliberate,
	because a signature that took it would be an invitation to store it.
*/
func TestACustomerHandleIsRememberedOnce(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account := student(t, pool)
	ctx := context.Background()

	if _, err := store.CustomerOf(ctx, account, "asaas"); !errors.Is(err, billing.ErrNoCustomer) {
		t.Errorf("somebody who has never paid answered %v", err)
	}

	// FRESH HANDLES, for the reason above: the index on (provider, customer_id)
	// is unique across everybody, so a fixed string passes once and never again.
	one := "cus_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]
	two := "cus_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]

	if err := store.RememberCustomer(ctx, account, "asaas", one); err != nil {
		t.Fatal(err)
	}
	// A SECOND PURCHASE MUST NOT MAKE A SECOND HANDLE, or the gateway holds two
	// customers for one payer and a webhook naming either would be right.
	if err := store.RememberCustomer(ctx, account, "asaas", two); err != nil {
		t.Fatal(err)
	}

	got, err := store.CustomerOf(ctx, account, "asaas")
	if err != nil {
		t.Fatal(err)
	}
	if got != two {
		t.Errorf("the handle is %q", got)
	}

	var rows int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM payment_customers WHERE account_id = $1`, account).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 1 {
		t.Errorf("one person has %d handles at one gateway", rows)
	}
}

/*
ERASING SOMEBODY TAKES THE LINK AND LEAVES THE TRANSACTION.

	Both halves matter and they are opposite on purpose. The handle is the join
	between a person and a company holding their tax id, so it goes. The
	checkout is half of a transaction record — a chargeback can arrive months
	later — so it stays, pointing at an account that no longer exists and
	joinable to nobody.
*/
func TestErasureTakesTheHandleAndLeavesTheCheckout(t *testing.T) {
	store, pool := checkouts(t, confirmed)
	account, price := student(t, pool), anOffer(t, pool)
	ctx := context.Background()

	if _, err := open(t, store, account, price); err != nil {
		t.Fatal(err)
	}
	if err := store.RememberCustomer(ctx, account, "asaas", "cus_"+account.String()[:8]); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Exec(ctx, `DELETE FROM accounts WHERE id = $1`, account); err != nil {
		t.Fatalf("erasing: %v", err)
	}

	var handles, intents int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM payment_customers WHERE account_id = $1`, account).Scan(&handles); err != nil {
		t.Fatal(err)
	}
	if handles != 0 {
		t.Errorf("%d handle(s) survived the person", handles)
	}
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM checkout_intents WHERE account_id = $1`, account).Scan(&intents); err != nil {
		t.Fatal(err)
	}
	if intents != 1 {
		t.Errorf("%d checkout(s) survived, want 1 — a chargeback has to stay answerable", intents)
	}
}
