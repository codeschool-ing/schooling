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
	}, nil)
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
		billing.NewCheckouts(pool, nil, nil), billing.NewPrices(pool),
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
	return eventOf(name, reference, charge, "560.50")
}

/*
eventOf is a delivery carrying an amount, which every real one does.

	`event` above sends the whole sale, because a single payment settles the
	whole sale — 560.50 is `hookFor`'s checkout to the cent, and every test
	written before instalments existed means exactly that.

	An INSTALMENT is the case that needs its own amount, and needing one is the
	point: three deliveries of one purchase carry a third each, and a settlement
	that ignored them recorded the price three times.
*/
func eventOf(name, reference, charge, value string) string {
	return fmt.Sprintf(
		`{"id":"evt_%s","event":%q,"payment":{"id":%q,"externalReference":%q,`+
			`"value":%s,"status":"CONFIRMED"}}`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:12], name, charge, reference, value)
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

/*
TestAnInstalmentPlanIsONESALEInTheLedger is the claim the test above says it
makes and does not.

	`TestAPaymentOpensOneTerm` delivers the SAME charge three times and calls
	that "the same guard that keeps six instalments of one plan from buying six
	years". It is not. Repeating one charge exercises idempotency; an instalment
	plan is THREE CHARGES, with three ids, which the ledger has never seen —
	and the ledger is keyed by the charge precisely so that two ids are two
	movements.

	A REAL PLAN, FROM THE SANDBOX, LOOKS LIKE THIS. One checkout for R$ 1.090,00
	in three; the gateway answers with three payments carrying one
	`externalReference` and three ids of their own:

	    pay_3gbj9q0yafl7lla5  363.33  parcela 1  97945f8e-…
	    pay_70wnsxl0i5w6sqvq  363.33  parcela 2  97945f8e-…
	    pay_gi1mm7y86jxge84p  363.34  parcela 3  97945f8e-…

	So the two halves of what an instalment plan must satisfy are separate
	claims, and only one of them was ever checked:

	    the TERM is bought once      — three payments, one year (checked)
	    the MONEY is counted once    — three payments, one price (not checked)
*/
func TestAnInstalmentPlanIsONESALEInTheLedger(t *testing.T) {
	api, store, pool, one, _ := hookFor(t)
	ctx := context.Background()

	/* THREE CHARGES OF ONE PURCHASE, which is what the gateway makes of a split
	   and what this platform has never been handed. The reference is the same on
	   all three because they are one sale; the ids differ because they are three
	   collections. */
	charges := []string{
		"pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16],
		"pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16],
		"pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16],
	}
	// The thirds the provider actually sends, odd cent and all: 560.50 in three
	// is 186.83 twice and 186.84 once, and they have to add back up to the sale.
	for i, charge := range charges {
		value := "186.83"
		if i == 2 {
			value = "186.84"
		}
		rec := deliver(t, api, hookToken,
			eventOf("PAYMENT_RECEIVED", one.ID.String(), charge, value))
		if rec.Code != http.StatusOK {
			t.Fatalf("an instalment answered %d: %s", rec.Code, rec.Body.String())
		}
	}

	var rows int
	var total int64
	if err := pool.QueryRow(ctx, `
		SELECT count(*), coalesce(sum(amount_cents), 0)
		FROM ledger_entries WHERE account_id = $1 AND kind = 'payment'
	`, one.AccountID).Scan(&rows, &total); err != nil {
		t.Fatal(err)
	}

	/* WHAT THE SALE WAS, AND NOTHING ABOVE IT. Three instalments of one purchase
	   move the price once between them — however many rows the ledger chooses to
	   write, they have to add up to what somebody agreed to pay. A ledger that
	   totals three times the price says a student paid for three subscriptions,
	   and it is append-only: the rows cannot be deleted, only reversed. */
	if want := int64(one.Cents); total != want {
		t.Errorf("three instalments of one %d-cent sale recorded %d cents across %d row(s)",
			want, total, rows)
	}

	_ = store
}

/*
TestAnEventWithNoAmountSettlesAtThePurchase is the fallback, and it is a
fallback rather than a refusal on purpose.

	Delivery is sequential and a non-2xx stops the queue for every student, so a
	malformed event may not be the thing that takes payments down. An event with
	no readable amount settles at what the purchase was for — which is what every
	event did before instalments existed, and is right for the single payment
	that is nearly all of them.

	It is checked with the amount MISSING and with it unreadable, because the two
	arrive by different routes: a provider that stops sending the field, and one
	that sends something this cannot parse.
*/
func TestAnEventWithNoAmountSettlesAtThePurchase(t *testing.T) {
	/* FOUR SHAPES A PROVIDER MIGHT SEND, and none of them may stop the queue:
	   an empty string, a string that is not a number, an explicit null, and the
	   field left out altogether. The first two also cover the day this arrives
	   as a JSON string rather than a JSON number, which `json.Number` would have
	   refused at the decode and answered 400 to. */
	for _, value := range []string{`""`, `"not-a-number"`, `null`, ``} {
		t.Run("value:"+value, func(t *testing.T) {
			api, _, pool, one, charge := hookFor(t)

			body := eventOf("PAYMENT_RECEIVED", one.ID.String(), charge, value)
			if value == `` {
				// The field absent altogether, which is a different route in.
				body = fmt.Sprintf(
					`{"id":"evt_x","event":"PAYMENT_RECEIVED","payment":`+
						`{"id":%q,"externalReference":%q,"status":"CONFIRMED"}}`,
					charge, one.ID.String())
			}
			rec := deliver(t, api, hookToken, body)
			if rec.Code != http.StatusOK {
				t.Fatalf("it answered %d: %s — a malformed event must not stop the queue",
					rec.Code, rec.Body.String())
			}

			var total int64
			if err := pool.QueryRow(context.Background(), `
				SELECT coalesce(sum(amount_cents), 0)
				FROM ledger_entries WHERE account_id = $1 AND kind = 'payment'
			`, one.AccountID).Scan(&total); err != nil {
				t.Fatal(err)
			}
			if want := int64(one.Cents); total != want {
				t.Errorf("an event carrying %s recorded %d cents, want the purchase's %d",
					value, total, want)
			}
		})
	}
}

/*
TestAnAmountAsAStringIsTheSameMoney is the shape change this endpoint has to
survive without anybody deploying anything.

	A JSON number and a JSON string of the same digits are the same money, and
	which one a provider sends is theirs to change. The first version of this
	read it as `json.Number`, which refuses a string at the DECODE — so the whole
	delivery would have failed, the endpoint would have answered 400, and a
	sequential queue would have stopped for every student over the shape of one
	field.

	The fallback would not have saved it either: a decode that fails never
	reaches the settlement. That is why the amount is read raw and understood
	late, and why this test asserts the money rather than the status.
*/
func TestAnAmountAsAStringIsTheSameMoney(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	rec := deliver(t, api, hookToken,
		eventOf("PAYMENT_RECEIVED", one.ID.String(), charge, `"186.83"`))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}

	var total int64
	if err := pool.QueryRow(context.Background(), `
		SELECT coalesce(sum(amount_cents), 0)
		FROM ledger_entries WHERE account_id = $1 AND kind = 'payment'
	`, one.AccountID).Scan(&total); err != nil {
		t.Fatal(err)
	}
	// The quoted digits and not the purchase's 56050, which is what a fallback
	// would have recorded and would have looked like success.
	if total != 18683 {
		t.Errorf(`a value of "186.83" recorded %d cents, want 18683`, total)
	}
}

/*
refundOf is a delivery about money going back, carrying the array the provider
puts it in.

	`value` STAYS THE SALE, WHICH IS THE WHOLE TRAP. On a refund event the
	payment's own `value` is the charge, unchanged — the money that came back is
	in `refunds`. A settlement reading `value` records the sale as reversed on a
	day a fraction of it was.
*/
func refundOf(name, reference, charge string, back ...string) string {
	entries := make([]string, 0, len(back))
	for _, one := range back {
		entries = append(entries, `{"value":`+one+`}`)
	}
	return fmt.Sprintf(
		`{"id":"evt_%s","event":%q,"payment":{"id":%q,"externalReference":%q,`+
			`"value":560.50,"status":"REFUNDED","refunds":[%s]}}`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:12], name, charge, reference,
		strings.Join(entries, ","))
}

func ledgerRows(t *testing.T, pool *pgxpool.Pool, charge string) map[string]int {
	t.Helper()
	rows, err := pool.Query(context.Background(),
		`SELECT kind, amount_cents FROM ledger_entries WHERE source_ref LIKE $1 || '%'`, charge)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()

	out := map[string]int{}
	for rows.Next() {
		var kind string
		var cents int
		if err := rows.Scan(&kind, &cents); err != nil {
			t.Fatal(err)
		}
		out[kind] = cents
	}
	return out
}

/*
TestAPartialRefundRecordsWhatCameBackAndNotTheSale.

	THE LEDGER IS A RECORD OF MONEY AND NOT OF ACCESS. This recorded the whole
	sale on every refund, from an argument that a partial refund closes the
	subscription entirely and so recording a slice would understate what was
	taken. That is true about ACCESS and irrelevant here: R$ 200,00 leaving the
	bank and R$ 1.090,00 in the books is a discrepancy somebody has to explain,
	and what the access did is in `subscription_events` already.

	NOTHING IN THIS PLATFORM MAKES ONE. The console sends the whole sale. They
	arrive from the gateway's own dashboard, where a person can return any
	figure — which is exactly why this reads rather than assumes.
*/
func TestAPartialRefundRecordsWhatCameBackAndNotTheSale(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	if rec := deliver(t, api, hookToken,
		event("PAYMENT_CONFIRMED", one.ID.String(), charge)); rec.Code != http.StatusOK {
		t.Fatalf("the payment answered %d", rec.Code)
	}

	// R$ 200,00 of a R$ 560,50 sale, done in their dashboard.
	if rec := deliver(t, api, hookToken,
		refundOf("PAYMENT_PARTIALLY_REFUNDED", one.ID.String(), charge,
			"200.00")); rec.Code != http.StatusOK {
		t.Fatalf("the refund answered %d", rec.Code)
	}

	rows := ledgerRows(t, pool, charge)
	if rows["payment"] != 56050 {
		t.Errorf("the payment reads as %d", rows["payment"])
	}
	if rows["refund"] != -20000 {
		t.Errorf("the refund reads as %d, want -20000 — the books have to reconcile "+
			"against a bank statement, and the sale is not what left the account",
			rows["refund"])
	}
}

// TWO PARTIALS ARE SUMMED, because the second event carries BOTH entries.
// Reading only the newest would record the smaller of two numbers that should
// have been added.
func TestRefundsAreSummedBecauseTheEventCarriesAllOfThem(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	deliver(t, api, hookToken, event("PAYMENT_CONFIRMED", one.ID.String(), charge))
	deliver(t, api, hookToken,
		refundOf("PAYMENT_PARTIALLY_REFUNDED", one.ID.String(), charge, "100.00", "60.50"))

	if got := ledgerRows(t, pool, charge)["refund"]; got != -16050 {
		t.Errorf("two refunds of 100.00 and 60.50 read as %d, want -16050", got)
	}
}

/*
TestARefundWithNoReadableAmountSettlesAtTheSale.

	A FALLBACK AND NOT A REFUSAL, for the reason every fallback in this file
	exists: delivery is SEQUENTIAL, and one event this cannot read would stop the
	queue for every student on the platform.

	AND THE SALE IS THE RIGHT FALLBACK. Nearly every refund is a whole one, where
	the two numbers are the same — so this is only a compromise for a partial
	whose payload surprised us, and the warning beside it says so.
*/
func TestARefundWithNoReadableAmountSettlesAtTheSale(t *testing.T) {
	for _, shape := range []string{
		`"refunds":null`,
		`"refunds":[]`,
		`"refunds":[{"value":"not-a-number"}]`,
		`"status":"REFUNDED"`, // the key absent altogether
	} {
		api, _, pool, one, charge := hookFor(t)
		deliver(t, api, hookToken, event("PAYMENT_CONFIRMED", one.ID.String(), charge))

		body := fmt.Sprintf(
			`{"id":"evt_x","event":"PAYMENT_REFUNDED","payment":{"id":%q,`+
				`"externalReference":%q,"value":560.50,%s}}`,
			charge, one.ID.String(), shape)
		if rec := deliver(t, api, hookToken, body); rec.Code != http.StatusOK {
			t.Fatalf("%s answered %d — a malformed refund must not stop the queue",
				shape, rec.Code)
		}
		if got := ledgerRows(t, pool, charge)["refund"]; got != -56050 {
			t.Errorf("%s recorded %d, want the sale (-56050)", shape, got)
		}
	}
}

// MORE THAN THE SALE IS NOT A REFUND OF IT. It cannot happen and would be the
// books paying somebody to leave, so it falls back to the sale and is said out
// loud rather than trusted.
func TestARefundLargerThanTheSaleIsNotBelieved(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	deliver(t, api, hookToken, event("PAYMENT_CONFIRMED", one.ID.String(), charge))
	deliver(t, api, hookToken,
		refundOf("PAYMENT_REFUNDED", one.ID.String(), charge, "9000.00"))

	if got := ledgerRows(t, pool, charge)["refund"]; got != -56050 {
		t.Errorf("a refund of 9000.00 on a 560.50 sale recorded %d, want the sale", got)
	}
}

// AND A WHOLE REFUND IS UNCHANGED, which is nearly all of them: the array sums
// to the sale and the row is what it always was.
func TestAWholeRefundIsStillTheWholeSale(t *testing.T) {
	api, _, pool, one, charge := hookFor(t)

	deliver(t, api, hookToken, event("PAYMENT_CONFIRMED", one.ID.String(), charge))
	deliver(t, api, hookToken,
		refundOf("PAYMENT_REFUNDED", one.ID.String(), charge, "560.50"))

	if got := ledgerRows(t, pool, charge)["refund"]; got != -56050 {
		t.Errorf("a whole refund recorded %d, want -56050", got)
	}
}
