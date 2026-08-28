package asaas_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/codeschool-ing/schooling/internal/platform/pay/asaas"
)

/* The gateway, against a server that is not it.

   WHAT IS CHECKED HERE IS WHAT THIS PACKAGE SENDS AND WHAT IT MAKES OF WHAT
   COMES BACK. The bodies below are copied from real answers the sandbox gave —
   the charge in `chargePending` is the one that came back from the first
   successful call, with its own `netValue` of 589.01 — so a shape that changes
   at their end shows up here as a test that no longer resembles the API rather
   than as a field that silently reads zero. Only the description differs: that
   call was typed by hand in Portuguese, and what this code sends is English
   (N-06).

   WHAT IS NOT CHECKED HERE is whether they accept what we send. Nothing but
   their server can answer that, and it did, once, by hand. */

// The charge the sandbox actually answered with, trimmed to the fields this
// package reads and with the rest left in on purpose: an answer carrying more
// than we look at is the normal case, and a decoder that broke on it would
// break on their next release.
const chargePending = `{
  "object": "payment", "id": "pay_zea0d0i0xe51tc34",
  "customer": "cus_000008904370", "value": 590.0, "netValue": 589.01,
  "billingType": "PIX", "status": "PENDING", "dueDate": "2026-09-03",
  "externalReference": "intent-teste-1", "description": "Annual subscription (test)",
  "invoiceUrl": "https://sandbox.asaas.com/i/zea0d0i0xe51tc34",
  "deleted": false, "anticipated": false, "postalService": false,
  "discount": {"value": 0.00, "type": "FIXED"}
}`

type call struct {
	method string
	path   string
	token  string
	body   map[string]json.RawMessage
}

// gateway is a server that records what it was asked and answers what it was
// told to.
func gateway(t *testing.T, status int, answer string) (*asaas.Client, *[]call) {
	t.Helper()
	var seen []call

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw, _ := io.ReadAll(r.Body)
		one := call{
			method: r.Method,
			path:   r.URL.Path,
			token:  r.Header.Get("access_token"),
		}
		if len(raw) > 0 {
			if err := json.Unmarshal(raw, &one.body); err != nil {
				t.Errorf("the request body is not JSON: %v — %s", err, raw)
			}
		}
		seen = append(seen, one)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(status)
		_, _ = io.WriteString(w, answer)
	}))
	t.Cleanup(server.Close)

	return asaas.New("a-key", server.URL), &seen
}

func aCharge() asaas.Charge {
	return asaas.Charge{
		CustomerID:  "cus_000008904370",
		Method:      asaas.Pix,
		Cents:       59000,
		Due:         time.Date(2026, 9, 3, 0, 0, 0, 0, time.UTC),
		Reference:   "intent-teste-1",
		Description: "Annual subscription (test)",
	}
}

/*
THE AMOUNT LEAVES AS A DECIMAL AND ARRIVES AS CENTS, AND NEITHER IS A FLOAT.

	This is the assertion the whole package is arranged around. 59000 cents has
	to reach them as `590.00` — not `59000`, which would be a charge a hundred
	times too large, and not `5.9e+02`, which is what a float can print. And
	their `589.01` has to come back as 58901 and not 58900, which is what
	`int64(589.01 * 100)` gives on this machine and on every other one.
*/
func TestTheAmountCrossesTheBoundaryIntact(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, chargePending)

	got, err := client.CreateCharge(context.Background(), aCharge())
	if err != nil {
		t.Fatalf("creating a charge: %v", err)
	}

	sent := string((*seen)[0].body["value"])
	if sent != "590.00" {
		t.Errorf("the charge went out as %s, and it is for 59000 cents", sent)
	}
	if strings.ContainsAny(sent, "eE") {
		t.Errorf("the amount went out in exponent notation: %s", sent)
	}

	if got.Cents != 59000 {
		t.Errorf("the charge came back as %d cents", got.Cents)
	}
	if got.NetCents != 58901 {
		t.Errorf("what would arrive came back as %d cents, and their answer said 589.01",
			got.NetCents)
	}
}

// AND EVERY FIELD THIS PACKAGE PROMISES IS READ. A charge whose `invoiceUrl`
// came back empty would be a payment nobody can be sent to, discovered by a
// blank button rather than by an error.
func TestTheChargeIsReadWhole(t *testing.T) {
	client, _ := gateway(t, http.StatusOK, chargePending)

	got, err := client.CreateCharge(context.Background(), aCharge())
	if err != nil {
		t.Fatalf("creating a charge: %v", err)
	}

	for _, one := range []struct{ what, got, want string }{
		{"id", got.ID, "pay_zea0d0i0xe51tc34"},
		{"customer", got.CustomerID, "cus_000008904370"},
		{"method", string(got.Method), "PIX"},
		{"status", got.Status, "PENDING"},
		{"reference", got.Reference, "intent-teste-1"},
		{"invoice url", got.InvoiceURL, "https://sandbox.asaas.com/i/zea0d0i0xe51tc34"},
	} {
		if one.got != one.want {
			t.Errorf("the %s came back as %q, want %q", one.what, one.got, one.want)
		}
	}
	if want := time.Date(2026, 9, 3, 0, 0, 0, 0, time.UTC); !got.Due.Equal(want) {
		t.Errorf("the due date came back as %v", got.Due)
	}
}

// THE CREDENTIAL IS A HEADER CALLED `access_token`, which is the one fact about
// this API that was asserted from memory, was wrong, and was settled by a call
// that answered 200.
func TestTheKeyTravelsAsAccessToken(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, chargePending)

	if _, err := client.CreateCharge(context.Background(), aCharge()); err != nil {
		t.Fatalf("creating a charge: %v", err)
	}
	if (*seen)[0].token != "a-key" {
		t.Errorf("the key went out as %q", (*seen)[0].token)
	}
}

/*
INSTALMENTS SEND THE TOTAL AND THE COUNT, NEVER THE MONTHLY FIGURE.

	R$ 590 over six is R$ 98.33 a month, and six of those is R$ 589.98. Sending
	the monthly figure would lose two cents on every instalment plan sold, in the
	direction that costs us — and it would lose them silently, because both
	numbers look right on a screen.
*/
func TestAnInstalmentPlanSendsTheTotal(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, chargePending)

	want := aCharge()
	want.Method, want.Instalments = asaas.Card, 6
	if _, err := client.CreateCharge(context.Background(), want); err != nil {
		t.Fatalf("creating an instalment plan: %v", err)
	}

	body := (*seen)[0].body
	if got := string(body["totalValue"]); got != "590.00" {
		t.Errorf("the total went out as %q", got)
	}
	if got := string(body["installmentCount"]); got != "6" {
		t.Errorf("the count went out as %q", got)
	}
	if _, present := body["installmentValue"]; present {
		t.Error("it sent a monthly figure, which is the rounding this test exists for")
	}
	if _, present := body["value"]; present {
		t.Error("it sent both a value and a total, and the gateway may believe either")
	}
}

/*
WHAT WE COULD HAVE KNOWN IS REFUSED WITHOUT A ROUND TRIP.

	Their error code is `invalid_object` for everything, so a caller cannot tell
	a missing tax id from a malformed anything by asking them. Each of these is
	something this package can see for itself, and each has to be a named error
	rather than a request spent on being told.
*/
func TestWhatIsWrongHereNeverReachesTheGateway(t *testing.T) {
	for _, one := range []struct {
		what string
		make func(asaas.Charge) asaas.Charge
		want error
	}{
		{"no customer", func(c asaas.Charge) asaas.Charge { c.CustomerID = ""; return c },
			asaas.ErrNoCustomer},
		{"nothing to pay", func(c asaas.Charge) asaas.Charge { c.Cents = 0; return c },
			asaas.ErrNotPositive},
		{"a negative charge", func(c asaas.Charge) asaas.Charge { c.Cents = -100; return c },
			asaas.ErrNotPositive},
		{"no due date", func(c asaas.Charge) asaas.Charge { c.Due = time.Time{}; return c },
			asaas.ErrNoDueDate},
		{"debit", func(c asaas.Charge) asaas.Charge { c.Method = "DEBIT_CARD"; return c },
			asaas.ErrUnknownMethod},
		{"pix in six", func(c asaas.Charge) asaas.Charge { c.Instalments = 6; return c },
			asaas.ErrInstalmentsNotOnPix},
	} {
		t.Run(one.what, func(t *testing.T) {
			client, seen := gateway(t, http.StatusOK, chargePending)

			_, err := client.CreateCharge(context.Background(), one.make(aCharge()))
			if !errors.Is(err, one.want) {
				t.Errorf("it answered %v, want %v", err, one.want)
			}
			if len(*seen) != 0 {
				t.Errorf("it asked the gateway %d time(s) anyway", len(*seen))
			}
		})
	}
}

// AND A CUSTOMER WITH NO TAX ID IS ONE OF THEM, which is the refusal the
// sandbox taught: a customer can be created without a CPF and can never be
// charged, so a checkout that took one would be a dead end discovered at the
// moment of payment.
func TestACustomerWithoutATaxIDIsRefusedHere(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, `{}`)

	_, err := client.CreateCustomer(context.Background(),
		asaas.Customer{Name: "Ada Lovelace"})
	if !errors.Is(err, asaas.ErrNoTaxID) {
		t.Errorf("it answered %v", err)
	}
	if len(*seen) != 0 {
		t.Error("it created a customer nothing can charge")
	}
}

// A TAX ID IS DIGITS, however it was typed. The gateway wants the bare number
// and a person typing one uses dots and a dash.
func TestATaxIDIsSentAsDigits(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, `{"id":"cus_1","name":"Ada"}`)

	if _, err := client.CreateCustomer(context.Background(), asaas.Customer{
		Name: "Ada Lovelace", TaxID: "249.715.637-92",
	}); err != nil {
		t.Fatalf("creating a customer: %v", err)
	}
	if got := string((*seen)[0].body["cpfCnpj"]); got != `"24971563792"` {
		t.Errorf("the tax id went out as %s", got)
	}
}

/*
THEIR REFUSAL COMES BACK WHOLE AND IS NOT A SENTENCE FOR ANYBODY.

	This is the body the sandbox answered when a charge was attempted for a
	customer with no CPF. The code is generic and the meaning is Portuguese
	prose, so both are carried for a log and neither is a message a checkout may
	show — a caller that renders `err.Error()` puts Brazilian support copy into
	an Italian subscriber's screen.
*/
func TestARefusalKeepsTheirCodeAndTheirWords(t *testing.T) {
	client, _ := gateway(t, http.StatusBadRequest, `{"errors":[{"code":"invalid_object",`+
		`"description":"Para criar esta cobrança é necessário preencher o CPF ou CNPJ do cliente."}]}`)

	_, err := client.CreateCharge(context.Background(), aCharge())

	var refused *asaas.Refused
	if !errors.As(err, &refused) {
		t.Fatalf("a 400 answered %v", err)
	}
	if refused.Status != http.StatusBadRequest {
		t.Errorf("it recorded status %d", refused.Status)
	}
	if refused.Code != "invalid_object" {
		t.Errorf("it recorded code %q", refused.Code)
	}
	if !strings.Contains(refused.Description, "CPF ou CNPJ") {
		t.Errorf("it lost their description: %q", refused.Description)
	}
}

// AND A REFUSAL THAT IS NOT JSON IS STILL A REFUSAL. A proxy in front of their
// API answers HTML, and "invalid character '<'" is a worse thing to find in a
// log than the status and the first line of what came back.
func TestARefusalThatIsNotJSONIsStillOne(t *testing.T) {
	client, _ := gateway(t, http.StatusBadGateway,
		"<html>\n<head><title>502 Bad Gateway</title></head>\n</html>")

	_, err := client.CreateCharge(context.Background(), aCharge())

	var refused *asaas.Refused
	if !errors.As(err, &refused) {
		t.Fatalf("a 502 answered %v", err)
	}
	if refused.Status != http.StatusBadGateway {
		t.Errorf("it recorded status %d", refused.Status)
	}
	if !strings.Contains(refused.Description, "html") {
		t.Errorf("it kept nothing of what came back: %q", refused.Description)
	}
}

// A CLIENT WITH NO KEY ASKS NOTHING. An unauthenticated call to a payment API
// is a 401 in a log and a mystery on a screen; this is the deployment that
// forgot to write the secret, saying so.
func TestNoKeyMeansNoCall(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		t.Error("it called the gateway with no key")
	}))
	t.Cleanup(server.Close)

	client := asaas.New("  ", server.URL)
	if _, err := client.CreateCharge(context.Background(), aCharge()); !errors.Is(err, asaas.ErrNoKey) {
		t.Errorf("it answered %v", err)
	}
	if _, err := client.ChargeByID(context.Background(), "pay_1"); !errors.Is(err, asaas.ErrNoKey) {
		t.Errorf("reading answered %v", err)
	}
}

// READING ONE BACK IS THE SAME DECODER, and it exists for the webhook rather
// than for polling: an event says what happened, and this asks what is true.
func TestAChargeCanBeReadBack(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, chargePending)

	got, err := client.ChargeByID(context.Background(), "pay_zea0d0i0xe51tc34")
	if err != nil {
		t.Fatalf("reading a charge: %v", err)
	}
	if got.Cents != 59000 || got.Status != "PENDING" {
		t.Errorf("it came back as %d cents, %q", got.Cents, got.Status)
	}
	if (*seen)[0].path != "/payments/pay_zea0d0i0xe51tc34" {
		t.Errorf("it asked for %q", (*seen)[0].path)
	}
	if (*seen)[0].method != http.MethodGet {
		t.Errorf("it read with %s", (*seen)[0].method)
	}
}

/*
THE HOST IS READ OFF THE KEY, AND THE UNKNOWN CASE GOES TO THE SAFE SIDE.

	A sandbox key introduces itself with `$aact_hmlg_` — homologação — and that
	is the only marker recognised here. Everything else is the live host, which
	is the direction the unknown case has to fail in: an unrecognised key sent
	live is a 401 and no money moves, while a live key sent to the sandbox would
	create charges in a system nobody pays from and leave somebody believing they
	had subscribed.
*/
func TestTheHostIsReadOffTheKey(t *testing.T) {
	for _, one := range []struct {
		what string
		key  string
		want string
	}{
		{"a sandbox key", "$aact_hmlg_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY", asaas.Sandbox},
		{"the same with whitespace", "  $aact_hmlg_abc  ", asaas.Sandbox},
		{"a live key", "$aact_prod_000MzkwODA2MWY2OGM3MWRlMDU2NWM3MzJlNzZmNGZhZGY", asaas.Live},
		{"a marker nobody has seen", "$aact_xxxx_whatever", asaas.Live},
		{"nothing at all", "", asaas.Live},
	} {
		if got := asaas.HostFor(one.key); got != one.want {
			t.Errorf("%s went to %s, want %s", one.what, got, one.want)
		}
		if got := asaas.IsSandbox(one.key); got != (one.want == asaas.Sandbox) {
			t.Errorf("%s was called sandbox=%v", one.what, got)
		}
	}
}

/* ---------- money going back ---------- */

/*
TestARefundAsksForTheWholeSale.

	THE BODY IS `{}` AND THAT IS THE ASSERTION. Their endpoint takes an optional
	`value`, and sending one asks for a partial refund — which this platform has
	nowhere to put, because a refund closes the subscription outright and a
	ledger saying more went back than did is worse than no refund button at all.
	An empty object is how a JSON API is asked for the whole amount without any
	room to be read as something else.
*/
func TestARefundAsksForTheWholeSale(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, `{
		"id":"pay_9vvwq9mgo4xq775x","customer":"cus_000008904370",
		"billingType":"PIX","value":655.50,"netValue":654.51,
		"dueDate":"2026-09-03","status":"REFUNDED","externalReference":"intent-teste-1"
	}`)

	back, err := client.Refund(context.Background(), "pay_9vvwq9mgo4xq775x")
	if err != nil {
		t.Fatalf("refunding: %v", err)
	}

	if len(*seen) != 1 {
		t.Fatalf("it made %d calls", len(*seen))
	}
	one := (*seen)[0]
	if one.method != http.MethodPost {
		t.Errorf("it was a %s", one.method)
	}
	if one.path != "/payments/pay_9vvwq9mgo4xq775x/refund" {
		t.Errorf("it asked %q", one.path)
	}
	if len(one.body) != 0 {
		t.Errorf("it sent %v — a `value` here is a PARTIAL refund, which this "+
			"platform cannot record", one.body)
	}

	/* THE ANSWER IS THE CHARGE AS IT NOW STANDS, so a caller logs their word
	   for what happened rather than assuming the request meant it did. */
	if back.Status != "REFUNDED" {
		t.Errorf("it came back as %q", back.Status)
	}
	if back.Cents != 65550 {
		t.Errorf("the amount reads %d", back.Cents)
	}
}

// A REFUSAL COMES BACK WHOLE, because the meaning is in their Portuguese prose
// and not in the code: a key without the permission and a charge in a state
// that cannot be refunded both arrive as a 400 with a sentence, and an operator
// needs the sentence to know which of the two to go and fix.
func TestARefundTheGatewayWillNotMakeCarriesItsWords(t *testing.T) {
	client, _ := gateway(t, http.StatusBadRequest, `{"errors":[
		{"code":"invalid_action","description":"Não é possível estornar uma cobrança recebida em dinheiro."}
	]}`)

	_, err := client.Refund(context.Background(), "pay_9vvwq9mgo4xq775x")

	var refused *asaas.Refused
	if !errors.As(err, &refused) {
		t.Fatalf("it answered %v, want a Refused", err)
	}
	if !strings.Contains(refused.Description, "recebida em dinheiro") {
		t.Errorf("their words did not come back: %q", refused.Description)
	}
	if refused.Status != http.StatusBadRequest {
		t.Errorf("the status reads %d", refused.Status)
	}
}

// NO KEY, NO CALL. A deployment whose gateway key has been pulled must not
// reach the network to find that out — and this is the one call where a request
// made by mistake cannot be taken back.
func TestARefundWithNoKeyNeverLeaves(t *testing.T) {
	if _, err := asaas.New("", "https://example.invalid").
		Refund(context.Background(), "pay_9vvwq9mgo4xq775x"); !errors.Is(err, asaas.ErrNoKey) {
		t.Errorf("it answered %v, want ErrNoKey", err)
	}
}

// AND NO CHARGE, NO CALL. An empty id would be `POST /payments//refund`, which
// is a request to an address that means nothing and could mean anything.
func TestARefundWithNoChargeNeverLeaves(t *testing.T) {
	client, seen := gateway(t, http.StatusOK, `{}`)

	if _, err := client.Refund(context.Background(), "  "); !errors.Is(err, asaas.ErrNoCharge) {
		t.Errorf("it answered %v, want ErrNoCharge", err)
	}
	if len(*seen) != 0 {
		t.Error("it went to the network with no charge to refund")
	}
}
