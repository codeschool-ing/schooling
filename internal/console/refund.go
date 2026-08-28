package console

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/*
Money going back, asked for from here.

# IT WRITES NOTHING, AND THAT IS THE WHOLE DESIGN

The other three console writes change this platform's own rows. This one asks
the GATEWAY, and then stops.

The ledger row and the closed subscription come from the webhook the refund
causes — the same path that already runs when somebody refunds from the
gateway's own dashboard, and the same path that has been tested since the hook
existed. One writer for money, and it is the one that hears from the gateway.

A console that wrote its own ledger row here would be a second writer for the
same movement, and the two would race on every refund: ours keyed by the charge,
theirs keyed by the charge, and the index that exists to stop a double payment
deciding which of the two wins. Worse, a refund the gateway REFUSED would have
left a reversal in our books and a student still out of pocket.

So the answer this route gives is "the gateway was asked, and here is what it
said". Access closes a second later, when the event arrives, exactly as it does
for a refund nobody made from here.

# THE CONFIRMATION IS THE AMOUNT, TYPED

The erasure asks for the person's address typed out, and for the same reason:
an irreversible act reached by one click from a list somebody was scrolling is
the accident that guards against. Here it is the amount, because the mistake
this one actually invites is not "the wrong screen" — the screen names the
person — but "the wrong ROW", and a record with four purchases on it has four
buttons that look identical.

Typing R$ 655,50 means having read the line.

# OPERATOR, AND NOT OWNER

The rank is the erasure's, deliberately. Erasing somebody cannot be undone
either, and this project already decided that the answer to an irreversible act
is a second rank plus a confirmation rather than a third rank — because a
control only the owner can reach is a control that waits for the owner, and a
refund that waits is a chargeback.

# WHOLE REFUNDS ONLY

`asaas.Client.Refund` argues it: a refund closes the subscription outright, and
recording the whole sale as reversed while a third of it came back would leave
the ledger saying more went back than did. A partial refund needs a decision
about what a half-refunded term opens, and that decision has not been made.
*/

// ErrNoPurchase is a purchase id that is not there.
var ErrNoPurchase = errors.New("console: no such purchase")

/*
ErrGatewayRefused is the gateway saying no, in its own words.

	THE WORDS ARE THE ANSWER AND THE CODE IS NOT. A key without the permission
	and a charge in a state that cannot be refunded both arrive as one status
	with a sentence, and an operator needs the sentence to know which of the two
	to go and fix. So this carries the message through to the screen instead of
	turning it into one of ours.
*/
var ErrGatewayRefused = errors.New("console: the gateway would not")

// Refunds is what this package may not import: `billing` owns the purchases and
// the gateway client, and `cmd/api` says who provides these two.
type Refunds struct {
	// One is a purchase by id, so the handler can confirm the amount against
	// what is on the screen and name the person in the audit.
	One func(ctx context.Context, purchaseID uuid.UUID) (Purchase, error)

	// Ask asks the gateway for the whole sale to go back, and answers the
	// status it gave. It writes nothing here — see the file header.
	Ask func(ctx context.Context, purchaseID uuid.UUID) (string, error)
}

// RefundHandler is the one route.
type RefundHandler struct {
	refunds   Refunds
	record    Record
	label     Label
	who       func(ctx context.Context) (uuid.UUID, bool)
	mayRefund func(ctx context.Context) bool
}

func NewRefundHandler(refunds Refunds, record Record, label Label,
	who func(ctx context.Context) (uuid.UUID, bool),
	mayRefund func(ctx context.Context) bool,
) *RefundHandler {
	return &RefundHandler{
		refunds: refunds, record: record, label: label, who: who, mayRefund: mayRefund,
	}
}

func (h *RefundHandler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /console/api/v1/purchases/{id}/refund", h.refund)
}

func (h *RefundHandler) refund(w http.ResponseWriter, r *http.Request) {
	if !h.mayRefund(r.Context()) {
		web.Fail(w, http.StatusForbidden, web.CodeUnauthorized,
			"sending money back asks for an operator")
		return
	}

	id, err := uuid.Parse(r.PathValue("id"))
	if err != nil {
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such purchase")
		return
	}

	var in struct {
		// Cents is the confirmation: the amount of the purchase, typed. See
		// the file header.
		Cents int    `json:"cents"`
		Why   string `json:"why"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4<<10)).Decode(&in); err != nil {
		web.Fail(w, http.StatusBadRequest, "unreadable", "that is not a request this reads")
		return
	}
	why := strings.TrimSpace(in.Why)
	if why == "" {
		web.Fail(w, http.StatusBadRequest, "no_reason",
			"say why: this is written down, and money going back that nobody can "+
				"account for is worse than money that stayed")
		return
	}

	bought, err := h.refunds.One(r.Context(), id)
	switch {
	case errors.Is(err, ErrNoPurchase):
		web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such purchase")
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("reading a purchase to refund",
			"error", err, "purchase", id)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not read that")
		return
	}

	/* WHAT WAS NEVER PAID CANNOT BE GIVEN BACK, and saying so is more useful
	   than letting the gateway say it: an abandoned checkout has an amount on
	   it and looks, in a table, exactly like a paid one. */
	if bought.Stage != "paid" {
		web.Fail(w, http.StatusBadRequest, "not_paid",
			"that purchase was never paid, so there is nothing to send back")
		return
	}

	if in.Cents != bought.Cents {
		web.Fail(w, http.StatusBadRequest, "not_confirmed",
			"the amount does not match this purchase. Type what the line says: a record "+
				"with several purchases on it has several buttons that look the same")
		return
	}

	/* RECORDED BEFORE THE GATEWAY IS ASKED, which on this route means something
	   stronger than on the others: the entry may end up describing a refund
	   that was refused. That is the right way round. An entry saying somebody
	   ASKED for money to go back is true either way and is the thing an audit
	   is for; the alternative is recording only the successes, which is a log
	   that cannot answer "who tried". The gateway's answer goes into the
	   response and into the log line below. */
	if !h.wrote(w, r, bought, why) {
		return
	}

	status, err := h.refunds.Ask(r.Context(), id)
	switch {
	case errors.Is(err, ErrGatewayRefused):
		/* THEIR WORDS, THROUGH TO THE SCREEN. This is the one place in the
		   console where a message written by somebody else is shown verbatim,
		   and it is right here: the operator reading it is Brazilian, the
		   sentence is Portuguese support prose, and it names which of two
		   entirely different problems this is. */
		web.LoggerFrom(r.Context()).Warn("a refund the gateway would not make",
			"error", err, "purchase", id, "account", bought.AccountID)
		web.Fail(w, http.StatusBadGateway, "gateway_refused", err.Error())
		return
	case err != nil:
		web.LoggerFrom(r.Context()).Error("asking for a refund",
			"error", err, "purchase", id, "account", bought.AccountID)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"the gateway could not be reached. It is recorded that you asked; check there "+
				"before asking again, because this cannot tell a refund that did not happen "+
				"from one whose answer was lost")
		return
	}

	web.LoggerFrom(r.Context()).Info("a refund was asked for and taken",
		"purchase", id, "account", bought.AccountID, "status", status)

	/* THE ANSWER SAYS THE ACCESS HAS NOT CLOSED YET, because it has not. The
	   subscription ends when the event arrives, which is seconds away and is
	   not this request — and an operator who told a student "done" and then
	   watched them keep studying would stop trusting this screen. */
	web.JSON(w, http.StatusOK, map[string]any{
		"status": status,
		"note": "asked and accepted. Their access closes when the gateway's event " +
			"arrives, which is not part of this request.",
	})
}

// wrote records that somebody asked. See the call site for why it is before.
func (h *RefundHandler) wrote(w http.ResponseWriter, r *http.Request,
	bought Purchase, why string) bool {

	actor, ok := h.who(r.Context())
	if !ok {
		web.LoggerFrom(r.Context()).Error("a console route ran with no account", "path", r.URL.Path)
		web.Fail(w, http.StatusInternalServerError, web.CodeInternal, "something went wrong")
		return false
	}

	name, email, err := h.label(r.Context(), actor)
	if err != nil {
		web.LoggerFrom(r.Context()).Error("reading who is acting", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal, "could not record that")
		return false
	}

	/* THE SUBJECT IS THE ACCOUNT AND NOT THE PURCHASE, so this entry sits with
	   everything else that happened to the person — which is how the audit is
	   searched. The purchase is named in `after`, where it belongs: the id is a
	   detail of the entry rather than the thing the entry is about. */
	if err := h.record(r.Context(), actor, strings.TrimSpace(name+" <"+email+">"),
		"purchase.refunded",
		Subject{Kind: "account", ID: bought.AccountID.String()},
		Changed{
			Before: money(bought.Cents, bought.Currency) + " paid on " +
				bought.OpenedAt.Format("2006-01-02"),
			After: "asked the gateway to send it all back, purchase " + bought.ID.String(),
		},
		why, web.RequestIDFrom(r.Context())); err != nil {

		web.LoggerFrom(r.Context()).Error("recording a refund", "error", err)
		web.Fail(w, http.StatusServiceUnavailable, web.CodeInternal,
			"that was not recorded, so it was not done")
		return false
	}
	return true
}
