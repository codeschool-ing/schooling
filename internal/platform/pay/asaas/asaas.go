/*
Package asaas talks to the payment gateway that takes money in Brazil.

# IT IS CONCRETE AND THERE IS NO INTERFACE HERE, ON PURPOSE

The instinct is a `pay.Gateway` with two implementations, the way
`platform/mail` has a `Sender` — but that worked because a real provider's API
was in hand when the interface was drawn. `ROADMAP.md` records the decision for
this one: an interface imagined before any integration is wrong in exactly the
places that matter — what is synchronous, what arrives by webhook, and what is
idempotent under which key. The second provider pays the cost of generalising,
with two real examples on the table instead of one and a guess.

# WHAT THE FIRST REAL CALLS TAUGHT, WHICH MEMORY HAD WRONG

The credential is a header called `access_token`. A customer can be created
with nothing but a name, and CANNOT BE CHARGED without a CPF or CNPJ — the
platform therefore has to collect one to take money here, and the number is
sent and not stored: what this repository keeps is the customer id the gateway
answers with. A charge comes back with an `invoiceUrl`, which is where the
payer goes, so nothing here renders a QR code. And `externalReference` is ours
to fill and comes back untouched, which is what lets a webhook name our own row
rather than only theirs.

# THEIR ERRORS ARE NOT SENTENCES WE MAY SHOW

A refused request answers `{"errors":[{"code":..., "description":...}]}`, the
description is Portuguese prose, and the code is generic: a missing CPF and
anything else invalid both arrive as `invalid_object`. Two things follow. The
description never reaches a screen — English is the source language here (N-06)
and an Italian subscriber must not be shown Portuguese by a checkout. And the
CODE cannot be branched on, so this package validates what it can BEFORE
calling: a request refused for a reason we could have known is a round trip
spent to be told something we were already holding.
*/
package asaas

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// The two hosts. A key for one is refused by the other, so nothing can point at
// the wrong one and quietly work — it fails as a 401 rather than as money going
// somewhere unexpected.
const (
	Sandbox = "https://api-sandbox.asaas.com/v3"
	Live    = "https://api.asaas.com/v3"
)

/*
sandboxPrefix is how a sandbox key introduces itself: `hmlg` for homologação.

	THE PREFIX IS A FORMAT MARKER AND NOT A SECRET. It is the same eleven
	characters on every sandbox key ever issued; the entropy is the hundred and
	fifty after it.
*/
const sandboxPrefix = "$aact_hmlg_"

/*
HostFor is which host a key belongs to, read off the key itself.

	# ONE SETTING INSTEAD OF TWO THAT HAVE TO AGREE

	The host was going to follow `SCHOOLING_ENV`, which is one setting and is the
	WRONG one: it makes a production deployment unable to talk to the sandbox,
	so the first end-to-end run of a payment integration would be with real
	money at a real account. Reading it off the key keeps the single setting and
	moves it to the thing that actually determines the answer — a sandbox key
	cannot reach the live host whatever anybody configures.

	# THE ASYMMETRY IS DELIBERATE

	Only the sandbox marker is recognised, and everything else is Live. That is
	not laziness about the production prefix: it is the direction the unknown
	case should fail in. A key whose marker this does not recognise sent to Live
	is refused with a 401 and no money moves; the same key sent to the sandbox
	would create charges in a system nobody pays from, and somebody would believe
	they had subscribed.
*/
func HostFor(key string) string {
	if strings.HasPrefix(strings.TrimSpace(key), sandboxPrefix) {
		return Sandbox
	}
	return Live
}

// IsSandbox is the same reading, for a caller that wants to say so out loud.
func IsSandbox(key string) bool { return HostFor(key) == Sandbox }

/*
callTimeout is how long one request may take.

	LONGER THAN A PERSON WILL HAPPILY WAIT, for `platform/mail`'s reason and one
	worse: the alternative to waiting is a charge the platform believes it failed
	to create and the gateway believes it created, which is the outcome that ends
	with somebody being asked to pay twice.
*/
const callTimeout = 15 * time.Second

// Client is one account at the gateway.
type Client struct {
	// key is the credential. Nothing formats this struct, and this comment is
	// why: it is a bearer token, and a struct printed into a log is a token in
	// a log.
	key string

	base string
	http *http.Client
}

// New is the client for a key and a host.
func New(key, base string) *Client {
	return &Client{
		key:  strings.TrimSpace(key),
		base: strings.TrimRight(strings.TrimSpace(base), "/"),
		http: &http.Client{Timeout: callTimeout},
	}
}

// ---------- what this package refuses before asking ----------

var (
	// ErrNoKey is a client built with no credential. It is refused rather than
	// sent, because an unauthenticated call to a payment API is a 401 in a log
	// and a mystery on a screen.
	ErrNoKey = errors.New("asaas: no api key")

	// ErrNoTaxID is a customer with no CPF or CNPJ. The gateway refuses to
	// charge one and says so in Portuguese; this says so before the round trip.
	ErrNoTaxID = errors.New("asaas: a customer that can be charged needs a CPF or CNPJ")

	// ErrNoName is a customer with no name. Their API accepts one and there is
	// nothing useful about a nameless row in somebody's dashboard.
	ErrNoName = errors.New("asaas: a customer needs a name")

	// ErrNoCustomer is a charge with nobody to charge.
	ErrNoCustomer = errors.New("asaas: a charge needs a customer")

	// ErrNotPositive is a charge for nothing or less. A zero charge is not a
	// free subscription — it is a bug that would ask somebody to pay R$ 0,00.
	ErrNotPositive = errors.New("asaas: a charge is for more than nothing")

	// ErrNoDueDate is a charge with no day to be paid by.
	ErrNoDueDate = errors.New("asaas: a charge needs a due date")

	// ErrInstalmentsNotOnPix is instalments asked for on a method that has
	// none. Pix is paid once; splitting it is the card issuer's trick and not
	// the bank's.
	ErrInstalmentsNotOnPix = errors.New("asaas: only a card charge can be split")

	// ErrUnknownMethod is a billing type this package does not know. Debit is
	// the one somebody will reach for: the gateway does not sell it.
	ErrUnknownMethod = errors.New("asaas: that is not a payment method here")

	// ErrNoCharge is a read with no charge to read.
	ErrNoCharge = errors.New("asaas: no charge was named")
)

/*
Refused is the gateway saying no to something it understood.

	IT CARRIES THEIR WORDS AND IS NOT ONE. `Description` is Portuguese prose
	written for a Brazilian operator; it belongs in a log, where somebody
	debugging wants exactly it, and never in front of a person buying something.
	A caller showing `err.Error()` to a payer would be putting one language's
	support copy into five languages' checkout.

	AND `Code` IS TOO COARSE TO BRANCH ON — a missing tax id and a malformed
	anything are both `invalid_object`. It is here to be logged and counted, not
	switched on.
*/
type Refused struct {
	Status      int
	Code        string
	Description string
}

func (r *Refused) Error() string {
	return fmt.Sprintf("asaas: refused with %d %s: %s", r.Status, r.Code, r.Description)
}

// ---------- customers ----------

/*
Customer is somebody the gateway can charge.

	`TaxID` IS SENT AND NOT KEPT. It is a CPF or a CNPJ, which is identifying
	personal data, and the only thing this platform stores afterwards is `ID` —
	the gateway's own handle for the person. The number lives where it is
	legally required, which is at the processor; on this side there is an opaque
	string. That is the whole reason this struct is filled in, used once and
	dropped.
*/
type Customer struct {
	ID    string
	Name  string
	Email string
	TaxID string
}

// CreateCustomer registers somebody who can then be charged.
func (c *Client) CreateCustomer(ctx context.Context, want Customer) (Customer, error) {
	switch {
	case c.key == "":
		return Customer{}, ErrNoKey
	case strings.TrimSpace(want.Name) == "":
		return Customer{}, ErrNoName
	case taxDigits(want.TaxID) == "":
		return Customer{}, ErrNoTaxID
	}

	/* `personType` IS NOT SENT. Their answer carries one — `FISICA` for the
	   eleven-digit tax id above — and it is derived from the number rather than
	   chosen, so sending it would be this code having an opinion about which
	   kind of person a CPF belongs to. */
	body := map[string]any{
		"name":    strings.TrimSpace(want.Name),
		"cpfCnpj": taxDigits(want.TaxID),
	}
	if email := strings.TrimSpace(want.Email); email != "" {
		body["email"] = email
	}

	var out customerBody
	if err := c.call(ctx, http.MethodPost, "/customers", body, &out); err != nil {
		return Customer{}, err
	}

	/* THE CONVERSION IS THE POINT AND NOT A SHORTCUT. The two structs are
	   field-for-field the same — one carries JSON tags and the other does not —
	   and a field added to either without the other stops compiling here, which
	   is louder than a literal that would quietly leave it zero. */
	return Customer(out), nil
}

type customerBody struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	TaxID string `json:"cpfCnpj"`
}

// taxDigits keeps only the digits, so that a CPF typed with dots and a dash is
// the same value as one typed without. Their API wants the bare number and the
// people typing it do not.
func taxDigits(text string) string {
	var out strings.Builder
	for _, r := range text {
		if r >= '0' && r <= '9' {
			out.WriteRune(r)
		}
	}
	return out.String()
}

// ---------- charges ----------

// Method is how a charge is paid.
//
// THERE IS NO DEBIT. The gateway's charge screen offers Pix, boleto and credit
// card, and nothing else — which corrected a line of the roadmap that had said
// otherwise for a week. Boleto is absent here for a different reason: it is a
// real method and nothing has decided to sell with it yet.
type Method string

const (
	Pix  Method = "PIX"
	Card Method = "CREDIT_CARD"
)

/*
Charge is one payment asked for, and then one payment as it stands.

	`Reference` IS OURS. It is `externalReference` on their side, it comes back
	on the object and on every event about it, and it is how a webhook names a
	row in this platform's own database rather than only one in theirs.

	`NetCents` IS WHAT WOULD ACTUALLY ARRIVE — the charge less their fee, which
	the first live call showed as R$ 0,99 on a Pix. It is read rather than
	computed, because a fee this code calculated would be a second opinion about
	somebody else's price list.

	`Instalments` IS THE COUNT THE ISSUER SPLITS BY, and it changes nothing
	about what the platform is owed: one authorisation, one term bought.
*/
type Charge struct {
	ID          string
	CustomerID  string
	Method      Method
	Cents       int64
	NetCents    int64
	Due         time.Time
	Reference   string
	Description string
	Instalments int

	// Status is theirs, verbatim — `PENDING` on a charge just created. It is a
	// string and not a type here because this package does not decide what a
	// status means; the caller does, and a closed list invented before the
	// events have been read would be a guess with a compiler behind it.
	Status string

	// InvoiceURL is where the payer goes. Every method is paid on that page,
	// which is why nothing here renders a QR code or a barcode.
	InvoiceURL string
}

// CreateCharge asks for one payment.
func (c *Client) CreateCharge(ctx context.Context, want Charge) (Charge, error) {
	if err := c.checkCharge(want); err != nil {
		return Charge{}, err
	}

	body := map[string]any{
		"customer":          want.CustomerID,
		"billingType":       string(want.Method),
		"value":             reais(want.Cents),
		"dueDate":           want.Due.Format(time.DateOnly),
		"externalReference": want.Reference,
	}
	if d := strings.TrimSpace(want.Description); d != "" {
		body["description"] = d
	}
	if want.Instalments > 1 {
		body["installmentCount"] = want.Instalments

		/* THE SPLIT IS OF THE TOTAL AND THE TOTAL IS WHAT WE SAID.
		   `installmentValue` is the other way to ask for this, and it is the way
		   that loses a cent: a term costing R$ 590 over six is R$ 98.33 a month,
		   which is R$ 589.98. Sending the total and the count leaves the
		   rounding to the party that has to make the instalments add up. */
		body["totalValue"] = reais(want.Cents)
		delete(body, "value")
	}

	var out chargeBody
	if err := c.call(ctx, http.MethodPost, "/payments", body, &out); err != nil {
		return Charge{}, err
	}
	return out.charge()
}

// ChargeByID reads one payment as it stands now.
//
// IT EXISTS FOR THE WEBHOOK AND NOT FOR POLLING. An event says what happened;
// this asks the gateway what is true, which is what a delivery that arrived
// late, twice, or out of order has to be settled against.
func (c *Client) ChargeByID(ctx context.Context, id string) (Charge, error) {
	if c.key == "" {
		return Charge{}, ErrNoKey
	}
	if strings.TrimSpace(id) == "" {
		return Charge{}, ErrNoCharge
	}
	var out chargeBody
	if err := c.call(ctx, http.MethodGet, "/payments/"+url(id), nil, &out); err != nil {
		return Charge{}, err
	}
	return out.charge()
}

/*
Refund asks for money to go back, in full.

	IT IS THE ONLY CALL IN THIS PACKAGE THAT MOVES MONEY THE OTHER WAY, and the
	only one that cannot be undone by asking again. Everything else here creates
	something or reads it.

	IN FULL, AND PARTIAL IS NOT OFFERED. Their API takes a `value` and will give
	back a slice of a sale; this platform has nowhere to put that. A refund
	closes the subscription outright — `Settlement.reverse` says so and argues
	it — and recording the whole sale as reversed while returning a third of it
	would leave the ledger saying more went back than did. Whole refunds are the
	shape the rest of this system already has; partial ones need a decision
	about what a half-refunded term opens, and that decision has not been made.

	WHAT IT DOES NOT DO IS WRITE ANYTHING DOWN. The ledger row and the closed
	subscription come from the WEBHOOK this refund causes, exactly as they do
	when somebody refunds from the gateway's own dashboard. One writer for money,
	and it is the one that hears from the gateway — so a refund made here and a
	refund made there settle through the same tested path, and neither can
	produce a row the other would duplicate.

	THE ANSWER IS THE CHARGE AS IT NOW STANDS, so a caller can log the status
	their words for it rather than assume the request meant it happened.
*/
func (c *Client) Refund(ctx context.Context, id string) (Charge, error) {
	if c.key == "" {
		return Charge{}, ErrNoKey
	}
	if strings.TrimSpace(id) == "" {
		return Charge{}, ErrNoCharge
	}

	/* AN EMPTY BODY AND NOT AN ABSENT ONE. Their endpoint takes an optional
	   `value` and an optional `description`; sending neither is what asks for
	   the whole amount, and `{}` says that in the one way a JSON API cannot
	   read as something else. */
	var out chargeBody
	if err := c.call(ctx, http.MethodPost, "/payments/"+url(id)+"/refund",
		map[string]any{}, &out); err != nil {
		return Charge{}, err
	}
	return out.charge()
}

func (c *Client) checkCharge(want Charge) error {
	switch {
	case c.key == "":
		return ErrNoKey
	case strings.TrimSpace(want.CustomerID) == "":
		return ErrNoCustomer
	case want.Cents <= 0:
		return ErrNotPositive
	case want.Due.IsZero():
		return ErrNoDueDate
	case want.Method != Pix && want.Method != Card:
		return fmt.Errorf("%w: %q", ErrUnknownMethod, want.Method)
	case want.Instalments > 1 && want.Method != Card:
		return ErrInstalmentsNotOnPix
	}
	return nil
}

type chargeBody struct {
	ID                string      `json:"id"`
	Customer          string      `json:"customer"`
	BillingType       string      `json:"billingType"`
	Value             json.Number `json:"value"`
	NetValue          json.Number `json:"netValue"`
	DueDate           string      `json:"dueDate"`
	ExternalReference string      `json:"externalReference"`
	Description       string      `json:"description"`
	Status            string      `json:"status"`
	InvoiceURL        string      `json:"invoiceUrl"`
	InstallmentCount  int         `json:"installmentCount"`
}

func (b chargeBody) charge() (Charge, error) {
	out := Charge{
		ID:          b.ID,
		CustomerID:  b.Customer,
		Method:      Method(b.BillingType),
		Reference:   b.ExternalReference,
		Description: b.Description,
		Status:      b.Status,
		InvoiceURL:  b.InvoiceURL,
		Instalments: b.InstallmentCount,
	}

	var err error
	if out.Cents, err = centsOf(b.Value.String()); err != nil {
		return Charge{}, fmt.Errorf("asaas: reading what the charge is for: %w", err)
	}

	/* A MISSING NET VALUE IS A ZERO AND NOT A FAILURE. It is absent on some
	   shapes of this object and present on the ones that matter; refusing the
	   whole charge because the fee was not quoted would be losing the payment
	   over the accounting. */
	if b.NetValue.String() != "" {
		if out.NetCents, err = centsOf(b.NetValue.String()); err != nil {
			return Charge{}, fmt.Errorf("asaas: reading what would arrive: %w", err)
		}
	}

	if b.DueDate != "" {
		if out.Due, err = time.Parse(time.DateOnly, b.DueDate); err != nil {
			return Charge{}, fmt.Errorf("asaas: reading the due date %q: %w", b.DueDate, err)
		}
	}
	return out, nil
}

// ---------- the round trip ----------

func (c *Client) call(ctx context.Context, method, path string, body any, into any) error {
	ctx, cancel := context.WithTimeout(ctx, callTimeout)
	defer cancel()

	var payload io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("asaas: writing the request: %w", err)
		}
		payload = bytes.NewReader(encoded)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.base+path, payload)
	if err != nil {
		return fmt.Errorf("asaas: building the request: %w", err)
	}
	req.Header.Set("access_token", c.key)
	req.Header.Set("Accept", "application/json")
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	res, err := c.http.Do(req)
	if err != nil {
		return fmt.Errorf("asaas: %s %s: %w", method, path, err)
	}
	defer func() {
		_, _ = io.Copy(io.Discard, res.Body)
		_ = res.Body.Close()
	}()

	/* THE BODY IS READ WITH A CEILING. Nothing this API answers is large, and a
	   response that is means something has gone wrong at the other end — a proxy
	   error page, a login screen — and reading it into memory unbounded is how
	   that becomes our outage rather than theirs. */
	raw, err := io.ReadAll(io.LimitReader(res.Body, 1<<20))
	if err != nil {
		return fmt.Errorf("asaas: reading the answer to %s %s: %w", method, path, err)
	}

	if res.StatusCode < 200 || res.StatusCode > 299 {
		return refusal(res.StatusCode, raw)
	}
	if into == nil {
		return nil
	}
	if err := json.Unmarshal(raw, into); err != nil {
		return fmt.Errorf("asaas: the answer to %s %s is not what it says it is: %w",
			method, path, err)
	}
	return nil
}

/*
refusal turns their error body into ours.

	A BODY THIS CANNOT READ IS STILL A REFUSAL. An HTML error page from
	something in front of their API is not JSON and is not a reason to answer
	the caller with "invalid character '<'" — the status is what happened, and
	the first line of whatever came back is the clue somebody debugging wants.
*/
func refusal(status int, raw []byte) error {
	var body struct {
		Errors []struct {
			Code        string `json:"code"`
			Description string `json:"description"`
		} `json:"errors"`
	}
	if err := json.Unmarshal(raw, &body); err == nil && len(body.Errors) > 0 {
		return &Refused{
			Status:      status,
			Code:        body.Errors[0].Code,
			Description: body.Errors[0].Description,
		}
	}
	return &Refused{Status: status, Code: "unreadable", Description: firstLine(raw)}
}

func firstLine(raw []byte) string {
	text := strings.TrimSpace(string(raw))
	if i := strings.IndexAny(text, "\r\n"); i >= 0 {
		text = text[:i]
	}
	if len(text) > 200 {
		text = text[:200] + "…"
	}
	return text
}

// url escapes one path segment. Their ids are opaque strings and this is the
// one place a caller's value reaches a URL.
func url(segment string) string {
	return strings.NewReplacer("/", "%2F", "?", "%3F", "#", "%23", " ", "%20").
		Replace(segment)
}
