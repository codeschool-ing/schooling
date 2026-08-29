package billing_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* Starting a payment, at the layer that decides the order.

   THE ORDER IS THE CLAIM. The row is written before the gateway is called, the
   gate is checked before either, and a failure at any step leaves a checkout
   nobody paid rather than an invoice nobody owns. Half of this file is about
   what happens when a step fails, because that is where the money is. */

type gatewayFake struct {
	customers []string // the tax ids it was handed
	charges   []billing.Charge

	failCustomer error
	failCharge   error
}

func (g *gatewayFake) seam() billing.Gateway {
	return billing.Gateway{
		Name: "fake",
		NewCustomer: func(_ context.Context, _, _, taxID string) (string, error) {
			if g.failCustomer != nil {
				return "", g.failCustomer
			}
			g.customers = append(g.customers, taxID)
			return "cus_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12], nil
		},
		NewCharge: func(_ context.Context, in billing.Charge) (string, string, error) {
			if g.failCharge != nil {
				return "", "", g.failCharge
			}
			g.charges = append(g.charges, in)
			id := "pay_" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
			return id, "https://pay.example/" + id, nil
		},
		Refused: func(err error) bool { return errors.Is(err, errPayerRefused) },
	}
}

var errPayerRefused = errors.New("the gateway would not have them")

// checkoutAPI is the handler over a real database, with a signed-in payer and
// the gate answering whatever the test needs.
func checkoutAPI(t *testing.T, gate func(uuid.UUID) (bool, error)) (
	http.Handler, *gatewayFake, *billing.Checkouts, *pgxpool.Pool, uuid.UUID) {

	t.Helper()
	pool := testPool(t)
	account := student(t, pool)
	fake := &gatewayFake{}

	store := billing.NewCheckouts(pool, func(_ context.Context, id uuid.UUID) (bool, error) {
		return gate(id)
	})

	mux := http.NewServeMux()
	billing.NewHandler(store, billing.NewPrices(pool), billing.NewDiscounts(pool),
		fake.seam(), "example.tld",
		func(context.Context) (uuid.UUID, string, string, bool) {
			return account, "Ada Lovelace", "ada@example.tld", true
		},
	).Routes(mux)

	return mux, fake, store, pool, account
}

/*
priced puts a price in force for the platform's annual term.

	IT IS WRITTEN STRAIGHT IN rather than through the store, so the test owns the
	number — and it is always `listed`, because every assertion below is about
	the difference between what a term is sold at and what somebody was charged.
	A second amount here would make one of those two numbers a coincidence.
*/
func priced(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `
		INSERT INTO plan_prices (scope, term_months, cents, currency)
		VALUES ($1, $2, $3, 'BRL')
	`, billing.ScopeEverything, billing.TermAnnual, listed); err != nil {
		t.Fatalf("pricing the year: %v", err)
	}
}

func post(t *testing.T, h http.Handler, body string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/api/v1/checkout",
		strings.NewReader(body)))
	return rec
}

func answer(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var out map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("the answer is not JSON: %v — %s", err, rec.Body.String())
	}
	return out
}

// refusal is the code out of `web.Fail`'s envelope, which nests it under
// `error` — so a test reading the top level finds nothing and passes on a
// message that says something else entirely.
func refusal(t *testing.T, rec *httptest.ResponseRecorder) string {
	t.Helper()
	body, ok := answer(t, rec)["error"].(map[string]any)
	if !ok {
		t.Fatalf("the answer carries no error: %s", rec.Body.String())
	}
	return fmt.Sprint(body["code"])
}

/*
AN UNCONFIRMED ADDRESS IS REFUSED BEFORE THE GATEWAY HEARS ANYTHING.

	The gate is at `Open`, which is the first step, so a refusal costs nobody a
	customer record at a payment processor — and the sentence it answers with
	says what to do about it rather than that something went wrong.
*/
func TestAnUnconfirmedAddressNeverReachesTheGateway(t *testing.T) {
	api, fake, _, pool, _ := checkoutAPI(t, func(uuid.UUID) (bool, error) { return false, nil })
	priced(t, pool)

	rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"24971563792"}`)
	if rec.Code != http.StatusUnprocessableEntity {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := refusal(t, rec); got != "email_unconfirmed" {
		t.Errorf("the code is %v", got)
	}
	if len(fake.customers) != 0 || len(fake.charges) != 0 {
		t.Errorf("it registered %d payer(s) and made %d charge(s) anyway",
			len(fake.customers), len(fake.charges))
	}
}

/*
THE DISCOUNT IS APPLIED AND WHAT WAS CHARGED IS RECORDED BESIDE THE PRICE.

	Five per cent off R$ 590 is R$ 560,50, and both numbers survive: the checkout
	says 56050 and the price row it points at says 59000. Renewal charges the
	price. A system that stored only the amount would raise nobody's renewal, and
	one that stored only the price could not explain the invoice.
*/
func TestPixIsChargedLessAndBothNumbersSurvive(t *testing.T) {
	api, fake, store, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)

	rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"249.715.637-92"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	body := answer(t, rec)
	if body["cents"] != float64(56050) {
		t.Errorf("it charged %v", body["cents"])
	}
	if body["invoiceUrl"] == "" || body["invoiceUrl"] == nil {
		t.Error("the payer has nowhere to go")
	}

	id, err := uuid.Parse(fmt.Sprint(body["checkoutId"]))
	if err != nil {
		t.Fatalf("the checkout id is %v", body["checkoutId"])
	}
	one, err := store.ByID(context.Background(), id)
	if err != nil {
		t.Fatal(err)
	}
	if one.Cents != 56050 {
		t.Errorf("the row says %d was charged", one.Cents)
	}
	if one.Stage != billing.StageCharged {
		t.Errorf("the row is at stage %q", one.Stage)
	}

	var sold int
	if err := pool.QueryRow(context.Background(),
		`SELECT cents FROM plan_prices WHERE id = $1`, one.PriceID).Scan(&sold); err != nil {
		t.Fatal(err)
	}
	if sold != listed {
		t.Errorf("the price it was sold under says %d", sold)
	}

	// AND THE TAX ID WENT OUT WITH ITS PUNCTUATION REMOVED, because the gateway
	// wants the bare number and a person typing one uses dots and a dash.
	if len(fake.customers) != 1 || fake.customers[0] != "24971563792" {
		t.Errorf("the gateway was handed %q", fake.customers)
	}
}

// A CARD PAYS THE PRICE. The discount is Pix's alone — it is funded by the fee
// difference and the settlement, neither of which a card gives us.
func TestACardPaysTheListedPrice(t *testing.T) {
	api, _, _, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)

	rec := post(t, api, `{"termMonths":12,"method":"card","instalments":6,"taxId":"24971563792"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := answer(t, rec)["cents"]; got != float64(listed) {
		t.Errorf("a card was charged %v", got)
	}
}

/*
THE PRICE COMES FROM THE SERIES AND NEVER FROM THE REQUEST.

	A body carrying an amount is a buyer naming their own price. The handler has
	no field for one, and this is the test that fails if somebody adds it.
*/
func TestAPriceInTheRequestIsIgnored(t *testing.T) {
	api, _, _, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)

	rec := post(t, api,
		`{"termMonths":12,"method":"card","taxId":"24971563792","cents":1,"price":1}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := answer(t, rec)["cents"]; got != float64(listed) {
		t.Errorf("the buyer named their own price and got %v", got)
	}
}

// A TERM NOBODY PRICED IS NOT FOR SALE, and it says so rather than charging
// zero or falling back to another term.
func TestATermWithNoPriceIsNotForSale(t *testing.T) {
	api, fake, _, _, _ := checkoutAPI(t, confirmed)

	rec := post(t, api, `{"termMonths":7,"method":"pix","taxId":"24971563792"}`)
	if rec.Code != http.StatusUnprocessableEntity {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := refusal(t, rec); got != "no_offer" {
		t.Errorf("the code is %v", got)
	}
	if len(fake.charges) != 0 {
		t.Error("it charged for a term that is not sold")
	}
}

/*
A FIRST PURCHASE NEEDS A TAX ID AND A SECOND ONE DOES NOT.

	The handle is looked up before the number is wanted, so the field appears
	once in somebody's life with us rather than at every renewal — and the
	gateway is asked to register a payer exactly once.
*/
func TestTheTaxIDIsAskedForOnceAndNeverAgain(t *testing.T) {
	api, fake, _, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)

	// Without one, the first purchase says which field is missing.
	rec := post(t, api, `{"termMonths":12,"method":"pix"}`)
	if rec.Code != http.StatusUnprocessableEntity {
		t.Fatalf("a first purchase with no tax id answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := refusal(t, rec); got != "tax_id_required" {
		t.Errorf("the code is %v", got)
	}

	if rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"24971563792"}`); rec.Code != http.StatusOK {
		t.Fatalf("the first purchase answered %d: %s", rec.Code, rec.Body.String())
	}
	// And the second carries none, and works.
	if rec := post(t, api, `{"termMonths":12,"method":"pix"}`); rec.Code != http.StatusOK {
		t.Fatalf("a second purchase answered %d: %s", rec.Code, rec.Body.String())
	}

	if len(fake.customers) != 1 {
		t.Errorf("the gateway was asked to register a payer %d times", len(fake.customers))
	}
	if len(fake.charges) != 2 {
		t.Errorf("it made %d charges", len(fake.charges))
	}
}

// A NUMBER THAT IS NOT ONE IS REFUSED HERE. Eleven digits or fourteen — the
// check digits are the gateway's to verify, because an implementation of that
// algorithm which is subtly wrong refuses real people.
func TestATaxIDIsElevenDigitsOrFourteen(t *testing.T) {
	api, fake, _, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)

	rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"2497156379"}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("ten digits answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := refusal(t, rec); got != "not_a_tax_id" {
		t.Errorf("the code is %v", got)
	}
	if len(fake.customers) != 0 {
		t.Error("it went to the gateway with a number it could see was wrong")
	}
}

/*
A GATEWAY THAT FAILS LEAVES A CHECKOUT NOBODY PAID, AND SAYS SO.

	This is the failure the whole order of operations is arranged around. The row
	is already written, so what exists afterwards is a record that somebody tried
	— rather than a payable invoice with no owner, which is what calling first
	would have produced.
*/
func TestAChargeThatFailedLeavesTheCheckoutOpen(t *testing.T) {
	api, fake, store, pool, account := checkoutAPI(t, confirmed)
	priced(t, pool)
	fake.failCharge = fmt.Errorf("the gateway is not there")

	rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"24971563792"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "nothing has been charged") {
		t.Errorf("it did not say nothing was charged: %s", rec.Body.String())
	}

	var stage string
	if err := pool.QueryRow(context.Background(), `
		SELECT stage FROM checkout_intents WHERE account_id = $1
	`, account).Scan(&stage); err != nil {
		t.Fatalf("the checkout is not there at all: %v", err)
	}
	if stage != string(billing.StageOpened) {
		t.Errorf("the checkout is at %q", stage)
	}
	_ = store
}

// AND A PAYER THE GATEWAY REFUSES IS THE CALLER'S TO FIX, in our words. Theirs
// are Portuguese prose behind a generic code and never reach a screen.
func TestARefusedPayerIsSaidInOurWords(t *testing.T) {
	api, fake, _, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)
	fake.failCustomer = errPayerRefused

	rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"24971563792"}`)
	if rec.Code != http.StatusUnprocessableEntity {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if got := refusal(t, rec); got != "payer_refused" {
		t.Errorf("the code is %v", got)
	}
	if strings.Contains(rec.Body.String(), "gateway would not have them") {
		t.Error("the provider's own sentence reached the payer")
	}
}

// THE CHARGE CARRIES OUR ID, which is what lets a webhook name a row here. It
// is the checkout's own uuid and not a number the gateway chose.
func TestTheChargeCarriesTheCheckoutsID(t *testing.T) {
	api, fake, _, pool, _ := checkoutAPI(t, confirmed)
	priced(t, pool)

	rec := post(t, api, `{"termMonths":12,"method":"pix","taxId":"24971563792"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(fake.charges) != 1 {
		t.Fatalf("it made %d charges", len(fake.charges))
	}
	if fake.charges[0].Reference != fmt.Sprint(answer(t, rec)["checkoutId"]) {
		t.Errorf("the charge carries %q", fake.charges[0].Reference)
	}
	// AND A DUE DATE, because a charge with none is one the gateway refuses and
	// a Pix code that never expires is one paid against a price that has moved.
	if fake.charges[0].Due.IsZero() {
		t.Error("the charge has no due date")
	}
}
