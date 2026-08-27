package billing_test

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* What the gateway tells us afterwards, against a real Postgres.

   THE TWO CLAIMS HERE ARE ABOUT MONEY BEING COUNTED ONCE AND ABOUT THE QUEUE
   NOT STOPPING. Delivery is at-least-once and sequential: a repeat is the
   normal case, and a non-2xx on an event nobody wanted would hold up every
   payment for every student until somebody noticed. */

const hookToken = "a-token-of-the-length-a-real-one-has-0123456789"

// hookFor is the endpoint over a real database, with a checkout already
// charged and waiting to be paid.
func hookFor(t *testing.T) (http.Handler, *billing.Checkouts, *pgxpool.Pool, billing.Intent, string) {
	t.Helper()
	pool := testPool(t)
	account := student(t, pool)
	price := anOffer(t, pool)

	store := billing.NewCheckouts(pool, func(context.Context, uuid.UUID) (bool, error) {
		return true, nil
	})
	ctx := context.Background()

	one, err := store.Open(ctx, account, "", price, 56050, "BRL", billing.MethodPix, 1, "asaas")
	if err != nil {
		t.Fatalf("opening a checkout: %v", err)
	}
	charge := "pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]
	if one, err = store.Charged(ctx, one.ID, charge, "https://pay.example/x"); err != nil {
		t.Fatalf("charging it: %v", err)
	}

	/* THE SETTLEMENT'S OWN STORE HAS NO GATE, exactly as `cmd` wires it: a
	   webhook may settle a purchase and must never be able to open one. */
	settle := billing.NewSettlement(
		billing.NewCheckouts(pool, nil), billing.NewPrices(pool),
		billing.NewLedger(pool), billing.NewStore(pool), "asaas",
		slog.New(slog.DiscardHandler),
	)
	return billing.Hook(hookToken, settle, slog.New(slog.DiscardHandler)),
		store, pool, one, charge
}

func deliver(t *testing.T, h http.Handler, token, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodPost, "/hooks/pay", strings.NewReader(body))
	if token != "" {
		req.Header.Set("asaas-access-token", token)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

// captured keeps the last line written, so a test can assert the LEVEL and not
// only that something was said.
type captured struct {
	level   slog.Level
	message string
}

func (c *captured) Enabled(context.Context, slog.Level) bool { return true }
func (c *captured) WithAttrs([]slog.Attr) slog.Handler       { return c }
func (c *captured) WithGroup(string) slog.Handler            { return c }

func (c *captured) Handle(_ context.Context, r slog.Record) error {
	c.level, c.message = r.Level, r.Message
	return nil
}

func event(name, reference, charge string) string {
	return fmt.Sprintf(
		`{"id":"evt_%s","event":%q,"payment":{"id":%q,"externalReference":%q,"status":"CONFIRMED"}}`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:12], name, charge, reference)
}

// A WRONG TOKEN IS A 401 AND CHANGES NOTHING. There is no signature over the
// body, so this token is the whole of what stands between the endpoint and
// anybody who finds it — and what an open one buys is a subscription nobody
// paid for.
func TestAPaymentEventWithoutTheTokenIsRefused(t *testing.T) {
	api, _, _, one, charge := hookFor(t)

	for _, token := range []string{"", "not-the-token"} {
		rec := deliver(t, api, token, event("PAYMENT_CONFIRMED", one.ID.String(), charge))
		if rec.Code != http.StatusUnauthorized {
			t.Errorf("a %q token answered %d", token, rec.Code)
		}
	}
}

/*
ONE PAYMENT IS ONE LEDGER ROW, HOWEVER MANY EVENTS SAY SO.

	A payment produces `PAYMENT_CONFIRMED` and then `PAYMENT_RECEIVED`, and both
	mean it was paid. Keying the ledger on the EVENT would write two payment
	rows for one payment and the accounts would say a student paid twice — so it
	is keyed on the charge, and this is the test that fails if that changes.
*/
func TestTwoEventsAboutOnePaymentAreOneLedgerRow(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	for _, name := range []string{"PAYMENT_CONFIRMED", "PAYMENT_RECEIVED"} {
		rec := deliver(t, api, hookToken, event(name, one.ID.String(), charge))
		if rec.Code != http.StatusOK {
			t.Fatalf("%s answered %d: %s", name, rec.Code, rec.Body.String())
		}
	}

	var rows int
	if err := pool.QueryRow(context.Background(), `
		SELECT count(*) FROM ledger_entries WHERE account_id = $1 AND kind = 'payment'
	`, one.AccountID).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 1 {
		t.Errorf("one payment wrote %d ledger rows", rows)
	}
}

/*
AND IT OPENS A SUBSCRIPTION FOR THE TERM THE PRICE SAYS, ONCE.

	The second event settles nothing new, so the term is not extended twice —
	which is the same guard that keeps six instalments of one plan from buying
	six years.
*/
func TestAPaymentOpensOneTerm(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	for range 3 {
		rec := deliver(t, api, hookToken, event("PAYMENT_CONFIRMED", one.ID.String(), charge))
		if rec.Code != http.StatusOK {
			t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
		}
	}

	plans := billing.NewStore(pool)
	held, err := plans.Of(context.Background(), one.AccountID, one.Scope, time.Now())
	if err != nil {
		t.Fatalf("reading the subscription: %v", err)
	}
	if !billing.Opens(held.Subscription) {
		t.Errorf("a paid subscription is at %q and opens nothing", held.State)
	}

	// TWELVE MONTHS AND NOT THIRTY-SIX. `anOffer` prices the annual term, and
	// three deliveries of one event must buy one year.
	months := time.Until(held.PaidThrough).Hours() / 24 / 30
	if months < 11 || months > 13 {
		t.Errorf("three events bought %.0f months", months)
	}
}

/*
AN EVENT NOTHING ACTS ON IS A 200, AND THAT IS THE RULE THE QUEUE IMPOSES.

	Delivery is sequential and a failure stops the queue. Answering an error to
	`PAYMENT_BANK_SLIP_VIEWED` — somebody looking at an invoice — would hold up
	every payment for every student over an event nobody wanted. The intuitive
	rule, "refuse what I do not handle", is the one that takes the platform down.
*/
func TestAnEventNothingActsOnIsStillAccepted(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	for _, name := range []string{
		"PAYMENT_CREATED", "PAYMENT_UPDATED", "PAYMENT_BANK_SLIP_VIEWED",
		"PAYMENT_CHECKOUT_VIEWED", "PAYMENT_ANTICIPATED", "PAYMENT_AWAITING_RISK_ANALYSIS",
		"SOMETHING_THIS_BUILD_HAS_NEVER_HEARD_OF",
	} {
		rec := deliver(t, api, hookToken, event(name, one.ID.String(), charge))
		if rec.Code != http.StatusOK {
			t.Errorf("%s answered %d, and the queue is now stopped", name, rec.Code)
		}
	}

	var rows int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM ledger_entries WHERE account_id = $1`, one.AccountID).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Errorf("events nothing acts on wrote %d ledger rows", rows)
	}
}

/*
THE KEY'S OWN DEATH IS A WARNING AND NOT SILENCE.

	A key goes quiet after three months unused and expires after six. Without
	these events the platform finds out on the day somebody tries to pay, from a
	checkout that answers an outage — and working back from there to "the key
	expired" is an afternoon.

	THE LEVELS ARE THE POINT. `EXPIRING_SOON` is something to do this month;
	`EXPIRED` and `DISABLED` are the checkout being down right now. Logged at one
	level the second would look like the first, which is the same failure one
	step further along.
*/
func TestTheKeyDyingIsSaidAtTheRightVolume(t *testing.T) {
	for _, one := range []struct {
		event string
		want  slog.Level
	}{
		{"ACCESS_TOKEN_EXPIRING_SOON", slog.LevelWarn},
		{"ACCESS_TOKEN_EXPIRED", slog.LevelError},
		{"ACCESS_TOKEN_DISABLED", slog.LevelError},
		{"ACCESS_TOKEN_DELETED", slog.LevelError},
		{"ACCESS_TOKEN_CREATED", slog.LevelInfo},
		{"ACCESS_TOKEN_ENABLED", slog.LevelInfo},
	} {
		t.Run(one.event, func(t *testing.T) {
			said := &captured{}
			api := billing.Hook(hookToken, nil, slog.New(said))

			rec := deliver(t, api, hookToken, event(one.event, "", ""))
			if rec.Code != http.StatusOK {
				t.Fatalf("it answered %d, and the queue is now stopped", rec.Code)
			}
			if said.level != one.want {
				t.Errorf("it was logged at %v, want %v", said.level, one.want)
			}
			if !strings.Contains(said.message, "key") {
				t.Errorf("the line does not mention the key: %q", said.message)
			}
		})
	}
}

/*
AND IT NEVER REACHES THE SETTLEMENT, which is why the handler above can be
built with a nil one.

	These carry no payment. Letting them fall through to `meaning` would put
	them in the same silence as somebody opening an invoice, and letting them
	reach `Apply` would be looking for a checkout that a key has nothing to do
	with.
*/
func TestAKeyEventNeverLooksForACheckout(t *testing.T) {
	api := billing.Hook(hookToken, nil, slog.New(slog.DiscardHandler))

	// A nil settlement would panic if it were touched, which is the assertion.
	if rec := deliver(t, api, hookToken,
		event("ACCESS_TOKEN_EXPIRED", uuid.NewString(), "pay_x")); rec.Code != http.StatusOK {
		t.Errorf("it answered %d", rec.Code)
	}
}

// AN EVENT ABOUT A CHARGE NOBODY HERE MADE IS ACCEPTED AND LOGGED. A sandbox
// somebody has been clicking around in produces these, and so would a charge
// raised from the provider's own screen. Refusing would stop the queue over
// something that is not wrong.
func TestAnEventAboutSomebodyElsesChargeIsAccepted(t *testing.T) {
	api, _, _, _, _ := hookFor(t)

	rec := deliver(t, api, hookToken,
		event("PAYMENT_CONFIRMED", uuid.NewString(), "pay_nobody_here_made_this"))
	if rec.Code != http.StatusOK {
		t.Errorf("it answered %d: %s", rec.Code, rec.Body.String())
	}
}

// A BODY THAT IS NOT JSON IS A 400. It is the one refusal that is safe to make:
// a provider does not retry its way out of sending something unparseable, and
// accepting it would be pretending to have acted.
func TestABodyThatIsNotJSONIsRefused(t *testing.T) {
	api, _, _, _, _ := hookFor(t)

	rec := deliver(t, api, hookToken, "<html>not json</html>")
	if rec.Code != http.StatusBadRequest {
		t.Errorf("it answered %d", rec.Code)
	}
}

/*
A CHARGE FOUND BY THEIR ID AND NOT BY OURS STILL LANDS.

	The later instalments of a plan arrive as payments of their own, and an
	event may carry no reference of ours at all. The fallback is the charge id,
	which is what `checkout_intents` indexes.
*/
func TestAnEventWithNoReferenceIsFoundByTheCharge(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	rec := deliver(t, api, hookToken, event("PAYMENT_CONFIRMED", "", charge))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}

	var rows int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM ledger_entries WHERE account_id = $1`, one.AccountID).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 1 {
		t.Errorf("an event with no reference of ours wrote %d ledger rows", rows)
	}
}

/*
MONEY GOING BACK CLOSES ACCESS, AND ITS LEDGER ROW IS NOT THE PAYMENT'S.

	A payment and its refund are two movements of the same money on the same
	charge. Keying the reversal on the charge alone would collide with the
	payment it reverses — and the index that exists to stop a double payment
	would silently stop the refund instead, leaving somebody studying on money
	they got back.
*/
func TestARefundIsItsOwnRowAndClosesAccess(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	if rec := deliver(t, api, hookToken,
		event("PAYMENT_CONFIRMED", one.ID.String(), charge)); rec.Code != http.StatusOK {
		t.Fatalf("paying answered %d", rec.Code)
	}
	if rec := deliver(t, api, hookToken,
		event("PAYMENT_REFUNDED", one.ID.String(), charge)); rec.Code != http.StatusOK {
		t.Fatalf("refunding answered %d", rec.Code)
	}

	var payments, refunds int
	ctx := context.Background()
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE kind = 'payment'), count(*) FILTER (WHERE kind = 'refund')
		  FROM ledger_entries WHERE account_id = $1
	`, one.AccountID).Scan(&payments, &refunds); err != nil {
		t.Fatal(err)
	}
	if payments != 1 || refunds != 1 {
		t.Errorf("the ledger holds %d payment(s) and %d refund(s)", payments, refunds)
	}

	held, err := billing.NewStore(pool).Of(ctx, one.AccountID, one.Scope, time.Now())
	if err != nil {
		t.Fatalf("reading the subscription: %v", err)
	}
	if billing.Opens(held.Subscription) {
		t.Errorf("money went back and the subscription is at %q, which still opens", held.State)
	}
}

// A CHARGE THAT WILL NOT BE PAID ABANDONS THE PURCHASE AND NOTHING ELSE. No
// subscription was opened, so there is none to close — and a paid checkout is
// left alone, because an overdue arriving late must not take away a payment.
func TestAnOverdueChargeAbandonsThePurchase(t *testing.T) {
	api, store, _, one, charge := hookFor(t)

	if rec := deliver(t, api, hookToken,
		event("PAYMENT_OVERDUE", one.ID.String(), charge)); rec.Code != http.StatusOK {
		t.Fatalf("it answered %d", rec.Code)
	}

	got, err := store.ByID(context.Background(), one.ID)
	if err != nil {
		t.Fatal(err)
	}
	if got.Stage != billing.StageAbandoned {
		t.Errorf("an overdue charge left the purchase at %q", got.Stage)
	}
}

// AND AN OVERDUE THAT ARRIVES AFTER THE MONEY DOES NOT UNDO IT. Sequential
// delivery makes this unlikely and not impossible, and the cost of being wrong
// is somebody who paid losing what they paid for.
func TestAnOverdueAfterAPaymentChangesNothing(t *testing.T) {
	api, store, _, one, charge := hookFor(t)

	for _, name := range []string{"PAYMENT_CONFIRMED", "PAYMENT_OVERDUE"} {
		if rec := deliver(t, api, hookToken,
			event(name, one.ID.String(), charge)); rec.Code != http.StatusOK {
			t.Fatalf("%s answered %d", name, rec.Code)
		}
	}

	got, err := store.ByID(context.Background(), one.ID)
	if err != nil {
		t.Fatal(err)
	}
	if got.Stage != billing.StagePaid {
		t.Errorf("a late overdue took a paid purchase to %q", got.Stage)
	}
}
