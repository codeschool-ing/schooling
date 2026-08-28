package billing_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/billing"
)

/*
Reading a subscription, which nothing could do until this route existed.

	THE CLAIM IS THAT A SUBSCRIBER CAN BE TOLD WHAT THEY BOUGHT. Every other
	route in this module writes; the interface learned that somebody had access
	only by asking for a locked course and being refused, which says whether and
	never what, when, or how much.
*/

// holdingFor is the route over a real database, with `who` answering a fixed
// account — the seam `cmd` fills from the session.
// settled moves a charged checkout to `paid`, which is what a payment event
// does to it — without the ledger row and the subscription that come with a
// real one, because none of the tests below is about those.
func settled(t *testing.T, pool *pgxpool.Pool, bought billing.Intent) {
	t.Helper()
	if _, _, err := billing.NewCheckouts(pool, nil).
		Settled(context.Background(), bought.ID); err != nil {
		t.Fatalf("settling a checkout: %v", err)
	}
}

// support is the address this suite's deployment has configured. It is a real
// value rather than empty because the interesting assertion is that it reaches
// the screen; `TestTheSevenDaysAreSaidEvenWithNowhereToWrite` covers the other.
const support = "contact@example.tld"

func holdingFor(t *testing.T, account uuid.UUID, signedIn bool) http.Handler {
	t.Helper()
	pool := testPool(t)

	h := billing.NewHolding(billing.NewStore(pool), billing.NewPrices(pool),
		billing.NewCheckouts(pool, nil),
		func(context.Context) (uuid.UUID, bool) { return account, signedIn },
		// A CLOSURE OVER A CONSTANT, which is what `cmd` hands over after it has
		// chosen between the row an operator set and the deployment's variable.
		// This suite is about the screen and not about that choice; the store's
		// own tests cover the row, and the resolution is `cmd`'s.
		func(context.Context) string { return support })

	mux := http.NewServeMux()
	h.Routes(mux)
	return mux
}

func askHolding(t *testing.T, h http.Handler) (*httptest.ResponseRecorder, map[string]any) {
	t.Helper()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/subscription", nil))

	var body map[string]any
	if rec.Code == http.StatusOK {
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("the answer is not json: %v — %s", err, rec.Body.String())
		}
	}
	return rec, body
}

// NOBODY IS SIGNED IN, so there is nobody to have a subscription. It is a 401
// and not an empty answer: "nobody has one" and "you did not say who you are"
// are different facts and a screen acts differently on each.
func TestReadingASubscriptionNeedsASession(t *testing.T) {
	rec, _ := askHolding(t, holdingFor(t, uuid.Nil, false))
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("an anonymous read answered %d, want 401", rec.Code)
	}
}

/*
TestSomebodyWithNoSubscriptionIsToldSo is the ordinary case and it is a 200.

	Most people signed into this school have never bought anything. A 404 would
	make that look like a broken address, and a screen cannot tell one from the
	other without reading the code that produced it.
*/
func TestSomebodyWithNoSubscriptionIsToldSo(t *testing.T) {
	pool := testPool(t)
	account := student(t, pool)

	rec, body := askHolding(t, holdingFor(t, account, true))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if body["state"] != "none" {
		t.Errorf("somebody who never paid is in state %v, want none", body["state"])
	}
	if body["opens"] != false {
		t.Errorf("somebody who never paid opens %v", body["opens"])
	}
	if _, has := body["paidThrough"]; has {
		t.Error("somebody who never paid was given a date their access runs to")
	}
}

/*
TestASubscriberIsToldTheTermAndThePriceTheyBought is the whole point.

	THE PRICE IS THE ROW THEY BOUGHT AT AND NOT WHATEVER IS CURRENT, which is
	what `Held.PriceID` is for. A second, later price is seeded here for exactly
	that reason: an answer that resolved "the price in force" would pass every
	other assertion in this test and quote a figure this person never agreed to.
*/
func TestASubscriberIsToldTheTermAndThePriceTheyBought(t *testing.T) {
	pool := testPool(t)
	account := student(t, pool)
	bought := anOffer(t, pool)
	ctx := context.Background()

	plans := billing.NewStore(pool)
	if _, err := plans.Begin(ctx, account, billing.ScopeEverything,
		billing.ModelInstalments, bought, time.Now(), 12, nil); err != nil {
		t.Fatalf("opening a subscription: %v", err)
	}

	rec, body := askHolding(t, holdingFor(t, account, true))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}

	if body["state"] != "active" {
		t.Errorf("a paid subscription reads as %v", body["state"])
	}
	if body["opens"] != true {
		t.Error("a paid subscription opens nothing")
	}
	if body["model"] != string(billing.ModelInstalments) {
		t.Errorf("the model is %v — a screen cannot say whether it renews without it",
			body["model"])
	}

	price, ok := body["price"].(map[string]any)
	if !ok {
		t.Fatalf("no price came back: %s", rec.Body.String())
	}
	if cents := int(price["cents"].(float64)); cents != listed {
		t.Errorf("it was bought at %d and reads as %d", listed, cents)
	}
	if months := int(price["termMonths"].(float64)); months != 12 {
		t.Errorf("the term reads as %d months", months)
	}

	// THE DATE IT RUNS TO, which is the answer somebody actually came for.
	when, ok := body["paidThrough"].(string)
	if !ok {
		t.Fatalf("no date came back: %s", rec.Body.String())
	}
	got, err := time.Parse(time.RFC3339, when)
	if err != nil {
		t.Fatalf("the date is not a date: %v", err)
	}
	// Twelve months from when it was begun, which is a minute or so ago.
	want := time.Now().AddDate(0, 12, 0)
	if d := got.Sub(want); d > time.Minute || d < -time.Minute {
		t.Errorf("access runs to %s and a twelve-month term bought now ends %s", got, want)
	}
}

/*
TestAnExpiredSubscriptionStillSaysWhatItWas, because that is when somebody
looks.

	A term that ran out is the single most likely reason to open this screen —
	courses stopped opening and nobody said why. Answering "none" there would
	throw away the one fact that explains it: there WAS a subscription, and this
	is the day it ran to.
*/
func TestAnExpiredSubscriptionStillSaysWhatItWas(t *testing.T) {
	pool := testPool(t)
	account := student(t, pool)
	bought := anOffer(t, pool)
	ctx := context.Background()

	plans := billing.NewStore(pool)
	// Begun a year and a bit ago, so the term it bought ran out forty days back.
	began := time.Now().AddDate(0, -13, -10)
	if _, err := plans.Begin(ctx, account, billing.ScopeEverything,
		billing.ModelInstalments, bought, began, 12, nil); err != nil {
		t.Fatalf("opening a subscription: %v", err)
	}

	rec, body := askHolding(t, holdingFor(t, account, true))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if body["state"] == "none" {
		t.Error("a subscription that ran out reads as though it never existed")
	}
	if body["opens"] != false {
		t.Error("a subscription whose term ran out still opens things")
	}
	if _, has := body["paidThrough"]; !has {
		t.Error("no date came back, so nothing explains why the courses closed")
	}
}

/*
TestTheHistoryComesBackEvenWithNoSubscription, which is the case that would
have been lost.

	SOMEBODY WITH NO SUBSCRIPTION MAY STILL HAVE PURCHASES — a Pix code that
	expired unpaid, a sale that was refunded — and those are exactly the rows a
	person writes in about. The route answers `state: none` for them and used to
	return on the spot; reading the history after that early return would have
	hidden it from the only people who need it.
*/
func TestTheHistoryComesBackEvenWithNoSubscription(t *testing.T) {
	pool := testPool(t)
	account, offer := student(t, pool), anOffer(t, pool)

	sold(t, pool, account, offer, listed, billing.MethodPix, 1, "pay_"+short())

	rec, body := askHolding(t, holdingFor(t, account, true))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if body["state"] != "none" {
		t.Errorf("somebody who never paid is in state %v", body["state"])
	}

	bought, ok := body["purchases"].([]any)
	if !ok {
		t.Fatalf("no history came back: %s", rec.Body.String())
	}
	if len(bought) != 1 {
		t.Fatalf("their unpaid checkout reads as %d purchases", len(bought))
	}

	one, ok := bought[0].(map[string]any)
	if !ok {
		t.Fatalf("a purchase came back as %#v", bought[0])
	}
	if one["stage"] != string(billing.StageCharged) {
		t.Errorf("it reads as %v", one["stage"])
	}
	if one["invoiceUrl"] == nil {
		t.Error("no address came back, so nothing can send them back to their code")
	}
	if int(one["listed"].(float64)) != listed {
		t.Errorf("the offer reads as %v and it was %d", one["listed"], listed)
	}
}

// AND AN EMPTY HISTORY IS `[]` AND NOT `null`, so a screen can tell "has bought
// nothing" from "this version does not send the field".
func TestAnEmptyHistoryIsStillAList(t *testing.T) {
	pool := testPool(t)
	_, body := askHolding(t, holdingFor(t, student(t, pool), true))

	bought, ok := body["purchases"].([]any)
	if !ok {
		t.Fatalf("the history is %#v, want an empty list", body["purchases"])
	}
	if len(bought) != 0 {
		t.Errorf("somebody who has bought nothing has %d purchases", len(bought))
	}
}

/*
TestAClickThatNeverReachedTheGatewayIsNotInTheirHistory.

	THE FIRST REAL CARD SALE ON THIS PLATFORM FOUND THIS. A student bought a
	year, and their account screen showed TWO lines a minute apart: the purchase,
	and beside it an identical one reading "not finished".

	Both rows are real. `Handler.start` opens the checkout BEFORE asking the
	gateway who the payer is — the row carries the confirmed-address gate, and a
	gate anywhere else is a gate somebody forgets — and nobody buying for the
	first time has a customer at the gateway yet. So the first submit writes a
	row and is refused with `tax_id_required`, the screen reveals the CPF field,
	and the second submit becomes the charge.

	That is every first purchase, for everybody, for ever. And what the student
	is shown is a payment that appears to have failed next to the one that
	worked, about which they can do precisely nothing — which is a message to
	somebody, and there is nobody (N-05).

	THE ROW IS KEPT AND THE CONSOLE SHOWS IT. `0042` argued for keeping it and
	was right: an operator asked "I tried and nothing happened" wants that
	evidence, with its timestamp. This is about whose screen it belongs on.
*/
func TestAClickThatNeverReachedTheGatewayIsNotInTheirHistory(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, offer := student(t, pool), anOffer(t, pool)

	// The click that was refused for a tax id: opened, and no charge, ever.
	buys := billing.NewCheckouts(pool, anybody)
	if _, err := buys.Open(ctx, account, "", offer, listed, "BRL",
		billing.MethodCard, 1, "asaas"); err != nil {
		t.Fatalf("opening the first checkout: %v", err)
	}

	// And the second one, a minute later, which became a charge.
	charged := sold(t, pool, account, offer, listed, billing.MethodCard, 1, "pay_"+short())

	// BOTH ARE IN THE STORE, which is what the console reads.
	all, err := buys.Purchases(ctx, account)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 2 {
		t.Fatalf("the store holds %d rows, want both", len(all))
	}

	// AND ONE IS ON THE STUDENT'S OWN SCREEN.
	rec, body := askHolding(t, holdingFor(t, account, true))
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}

	shown, ok := body["purchases"].([]any)
	if !ok {
		t.Fatalf("no history came back: %s", rec.Body.String())
	}
	if len(shown) != 1 {
		t.Fatalf("the student is shown %d purchases, want only the one that reached "+
			"the gateway", len(shown))
	}
	if one := shown[0].(map[string]any); one["id"] != charged.ID.String() {
		t.Errorf("the line shown is %v and the charge was %s", one["id"], charged.ID)
	}
}

// AND A CHECKOUT THAT REACHED THE GATEWAY AND WAS NEVER PAID STAYS. That one is
// a Pix code somebody may still be about to pay, and the row hands the address
// back rather than making them open a second checkout for one sale.
func TestACheckoutTheGatewayAnsweredIsStillTheirs(t *testing.T) {
	pool := testPool(t)
	account, offer := student(t, pool), anOffer(t, pool)

	sold(t, pool, account, offer, listed, billing.MethodPix, 1, "pay_"+short())

	_, body := askHolding(t, holdingFor(t, account, true))
	shown, ok := body["purchases"].([]any)
	if !ok || len(shown) != 1 {
		t.Fatalf("an unpaid but charged checkout reads as %v", body["purchases"])
	}
	if one := shown[0].(map[string]any); one["stage"] != string(billing.StageCharged) {
		t.Errorf("it reads as %v", one["stage"])
	}
}

/*
The seven days, which the terms of use promise and nothing could reach.

	ART. 49 OF THE CDC: a purchase made at a distance may be withdrawn from
	within seven days, for the whole amount, with no reason. The terms say it in
	as many words — "Você tem sete dias para desistir […] devolvemos o valor
	integral, sem precisar de motivo" — and the screen where somebody looks at
	what they bought said nothing about it at all.

	A promise with nowhere to send it is worse than no promise, because the
	document is evidence and the person holding the right cannot use it.
*/
func TestSomebodyWhoJustBoughtIsToldTheyCanStillChangeTheirMind(t *testing.T) {
	pool := testPool(t)
	account, offer := student(t, pool), anOffer(t, pool)

	bought := sold(t, pool, account, offer, listed, billing.MethodCard, 1, "pay_"+short())
	settled(t, pool, bought)

	_, body := askHolding(t, holdingFor(t, account, true))

	window, ok := body["withdraw"].(map[string]any)
	if !ok {
		t.Fatalf("somebody who bought minutes ago is told nothing about the seven "+
			"days: %v", body["withdraw"])
	}
	if window["email"] != support {
		t.Errorf("nowhere to write: %v", window["email"])
	}

	until, err := time.Parse(time.RFC3339, window["until"].(string))
	if err != nil {
		t.Fatalf("the deadline is not a date: %v", err)
	}
	/* SEVEN DAYS FROM WHEN IT WAS PAID. Counting from the click would eat the
	   three days a Pix code can sit unpaid, out of somebody's seven. */
	want := time.Now().AddDate(0, 0, 7)
	if d := until.Sub(want); d > time.Minute || d < -time.Minute {
		t.Errorf("the deadline is %s, want seven days from now (%s)", until, want)
	}
}

// AND AFTER THEM, NOTHING IS SAID. The right has expired, a refund is
// discretionary from then on, and a line inviting somebody to write would be an
// invitation to a message nobody can answer (N-05).
func TestAfterTheSevenDaysTheScreenSaysNothingAboutThem(t *testing.T) {
	pool := testPool(t)
	account, offer := student(t, pool), anOffer(t, pool)

	bought := sold(t, pool, account, offer, listed, billing.MethodPix, 1, "pay_"+short())
	settled(t, pool, bought)
	// Paid eight days ago, so the window shut yesterday.
	if _, err := pool.Exec(context.Background(),
		`UPDATE checkout_intents SET updated_at = now() - interval '8 days' WHERE id = $1`,
		bought.ID); err != nil {
		t.Fatal(err)
	}

	_, body := askHolding(t, holdingFor(t, account, true))
	if _, has := body["withdraw"]; has {
		t.Errorf("a purchase from eight days ago still offers the seven days: %v",
			body["withdraw"])
	}
}

/*
TestTheNewestPurchaseOpensAFreshSevenDays.

	SOMEBODY WHO RENEWS HAS A NEW WINDOW ON THE NEW SALE, and the old one is long
	gone. Looking at the first purchase rather than the latest would tell a
	person who bought yesterday that their right expired last March.
*/
func TestTheNewestPurchaseOpensAFreshSevenDays(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, offer := student(t, pool), anOffer(t, pool)

	old := sold(t, pool, account, offer, listed, billing.MethodPix, 1, "pay_"+short())
	settled(t, pool, old)
	if _, err := pool.Exec(ctx, `UPDATE checkout_intents
		SET created_at = now() - interval '400 days', updated_at = now() - interval '400 days'
		WHERE id = $1`, old.ID); err != nil {
		t.Fatal(err)
	}

	fresh := sold(t, pool, account, offer, listed, billing.MethodCard, 1, "pay_"+short())
	settled(t, pool, fresh)

	_, body := askHolding(t, holdingFor(t, account, true))
	if _, ok := body["withdraw"].(map[string]any); !ok {
		t.Error("a renewal yesterday offers no seven days, so the old sale was read")
	}
}

// A CHECKOUT NOBODY PAID OPENS NO WINDOW. There is nothing to withdraw from and
// nothing to give back.
func TestAnUnpaidCheckoutOffersNoWithdrawal(t *testing.T) {
	pool := testPool(t)
	account, offer := student(t, pool), anOffer(t, pool)

	sold(t, pool, account, offer, listed, billing.MethodPix, 1, "pay_"+short())

	_, body := askHolding(t, holdingFor(t, account, true))
	if _, has := body["withdraw"]; has {
		t.Errorf("a checkout nobody paid offers a withdrawal: %v", body["withdraw"])
	}
}

// THE DEADLINE IS SAID EVEN WITH NOWHERE TO WRITE. A deployment that configured
// no address still owes the seven days, and knowing the date is worth having on
// its own — see `config.SupportEmail`.
func TestTheSevenDaysAreSaidEvenWithNowhereToWrite(t *testing.T) {
	pool := testPool(t)
	account, offer := student(t, pool), anOffer(t, pool)

	bought := sold(t, pool, account, offer, listed, billing.MethodPix, 1, "pay_"+short())
	settled(t, pool, bought)

	h := billing.NewHolding(billing.NewStore(pool), billing.NewPrices(pool),
		billing.NewCheckouts(pool, nil),
		func(context.Context) (uuid.UUID, bool) { return account, true },
		func(context.Context) string { return "" })

	mux := http.NewServeMux()
	h.Routes(mux)

	_, body := askHolding(t, mux)
	window, ok := body["withdraw"].(map[string]any)
	if !ok {
		t.Fatal("no address meant no deadline, and the deadline is the part that is owed")
	}
	if _, has := window["email"]; has {
		t.Errorf("an address was invented: %v", window["email"])
	}
}

/*
TestAPurchaseAlreadyRefundedOffersNoWindow.

	THIS IS THE SUCCESS PATH OF THE FEATURE, READING AS THOUGH NOTHING HAPPENED.
	A refund does not move the checkout's stage — it got all the way — so without
	skipping these the screen tells somebody who has just used their seven days
	that they have until Tuesday to use them.
*/
func TestAPurchaseAlreadyRefundedOffersNoWindow(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	account, offer := student(t, pool), anOffer(t, pool)

	bought := sold(t, pool, account, offer, listed, billing.MethodCard, 1, "pay_"+short())
	settled(t, pool, bought)

	// The money going back, keyed as `Settlement.reverse` keys it.
	ledger := billing.NewLedger(pool)
	if _, err := ledger.Record(ctx, billing.Entry{
		AccountID: account, Kind: billing.KindRefund,
		Amount: billing.MustNew(int64(-listed), billing.BRL),
		Source: "asaas", SourceRef: bought.ChargeID + ":refund",
	}); err != nil {
		t.Fatalf("recording the refund: %v", err)
	}

	_, body := askHolding(t, holdingFor(t, account, true))
	if _, has := body["withdraw"]; has {
		t.Errorf("a purchase already refunded still offers the seven days: %v",
			body["withdraw"])
	}
}
