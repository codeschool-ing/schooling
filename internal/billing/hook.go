package billing

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"sort"
	"strings"
)

/*
What the gateway tells us afterwards, and the only place money becomes access.

# THE QUEUE IS SEQUENTIAL, WHICH DECIDES HOW THIS ANSWERS

The provider delivers one event at a time, in order, and A FAILURE STOPS THE
QUEUE until somebody restarts it. That is the setting chosen deliberately: at
this size a delayed payment is a problem and a lost one is a disaster, and a
sequential queue turns any defect of ours into a visible delay rather than into
silent wrong state.

It also decides the rule this file follows, which is the opposite of the
intuitive one:

	200 FOR EVERYTHING WE UNDERSTOOD — INCLUDING WHAT WE DELIBERATELY IGNORE.

Half the events on that account are about boletos being viewed and invoices
being opened. Answering an error to those would stop the queue, and with it
every payment for every student, over an event nobody wanted. What gets a
non-2xx is a bad credential, a body that is not JSON, and a database that would
not answer — that last one because it IS worth retrying, and because a
subscription lost to a blink is worse than a queue that waits.

# AT-LEAST-ONCE IS THE NORMAL CASE

Ordering does not imply exactly-once, and one payment produces two events we
both act on: `PAYMENT_CONFIRMED` when it is paid and `PAYMENT_RECEIVED` when
the money is available. Both mean "this was paid".

So idempotency is not defensive coding here, it is the design. It rests on two
things that are true regardless of what arrives twice: the ledger's unique index
on (source, ref) keyed by THE CHARGE and never by the event, and the fact that a
checkout is settled once — the second attempt changes nothing and says so.

# ACCESS OPENS ON `CONFIRMED` AND NOT ON `RECEIVED`

Confirmed is the payment made; received is the money available, which on a card
is 32 days later. Waiting for the second would be a student paying today and
studying next month.
*/

/*
outcome is what an event means to a purchase. Their vocabulary is large — the
account's own screen lists more than thirty payment events — and this maps the
six that change anything.
*/
type outcome string

const (
	// outcomePaid is money in, however far along the provider's own pipeline.
	outcomePaid outcome = "paid"
	// outcomeGone is a charge that will not be paid: expired, or deleted.
	outcomeGone outcome = "gone"
	// outcomeRefunded is money given back by agreement.
	outcomeRefunded outcome = "refunded"
	// outcomeChargedBack is money taken back in a dispute. It is separate from
	// a refund for the reason `EventChargedBack` gives.
	outcomeChargedBack outcome = "charged-back"
)

/*
meaning maps the provider's word to ours, and answers false for everything else.

	WHAT IS ABSENT IS ABSENT ON PURPOSE. `PAYMENT_BANK_SLIP_VIEWED`,
	`PAYMENT_CHECKOUT_VIEWED`, `PAYMENT_CREATED`, `PAYMENT_UPDATED`,
	`PAYMENT_ANTICIPATED` and the whole split and dunning families are events
	about somebody looking at a page or about the provider's own bookkeeping.
	They arrive, they are counted, and they change nothing.

	`PAYMENT_AWAITING_RISK_ANALYSIS` IS ALSO NOT PAID, which is the one that
	looks like it should be. A card held for manual review is a payment that may
	yet be refused, and opening a course on it would mean closing one later.
*/
func meaning(event string) (outcome, bool) {
	switch strings.ToUpper(strings.TrimSpace(event)) {
	case "PAYMENT_CONFIRMED", "PAYMENT_RECEIVED", "PAYMENT_APPROVED_BY_RISK_ANALYSIS":
		return outcomePaid, true
	case "PAYMENT_OVERDUE", "PAYMENT_DELETED", "PAYMENT_REPROVED_BY_RISK_ANALYSIS",
		"PAYMENT_CREDIT_CARD_CAPTURE_REFUSED":
		return outcomeGone, true
	case "PAYMENT_REFUNDED", "PAYMENT_PARTIALLY_REFUNDED":
		return outcomeRefunded, true
	case "PAYMENT_CHARGEBACK_REQUESTED":
		return outcomeChargedBack, true
	}
	return "", false
}

// delivery is the part of their payload this platform reads.
type delivery struct {
	// ID is the event's own id. It is read to be logged and is NOT what
	// idempotency rests on — see the package comment: two different events mean
	// one payment, so keying on this would record that payment twice.
	ID    string `json:"id"`
	Event string `json:"event"`

	Payment struct {
		ID string `json:"id"`

		// Reference is ours. It is the checkout's id, put on the charge when it
		// was created, and it is the first way home.
		Reference string `json:"externalReference"`

		Status string `json:"status"`
	} `json:"payment"`
}

/*
tokenHeader is where the provider puts the token from its webhook form.

	VERIFIED BY A REAL DELIVERY. It was the one fact in this integration that
	could not be checked before shipping — their documentation is unreachable
	from the machine this was written on — so it went out marked as unverified,
	with the refusal below logging the names of whatever headers did arrive.

	The first delivery, on 27 August 2026, authenticated and answered 200. If it
	had not, that log line was the whole of the correction: one constant.

	THE REFUSAL STILL LISTS THE NAMES, and that is not leftover scaffolding. A
	provider that renames this header breaks every payment on the platform at
	once, and the difference between an hour and a week of that is a log line
	that says which header arrived instead of one that says a token was wrong.
*/
const tokenHeader = "asaas-access-token"

/*
Hook is the endpoint the gateway posts to.

	THE TOKEN IS AN ARGUMENT so that a deployment without one cannot mount an
	open endpoint. `cmd/api` mounts this only when it has one.

	IT IS A SINGLE TOKEN AND NOT BASIC, which is the difference from the mail
	hook next door: that provider's form offers Basic and this one's offers a
	token. Two endpoints under one prefix that authenticate differently is not
	untidiness — it is each one matching what its provider actually sends, which
	is the lesson the mail hook was rewritten to learn.
*/
func Hook(token string, settle *Settlement, log *slog.Logger) http.Handler {
	want := sha256.Sum256([]byte(strings.TrimSpace(token)))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !authorised(r.Header.Get(tokenHeader), want) {
			/* THE NAMES OF WHAT ARRIVED, AND NONE OF THE VALUES. If the header
			   above is wrong, this line is how it becomes right — and a log
			   that carried the values would be a log carrying a credential. */
			log.Warn("a payment event with no usable token",
				"headers", strings.Join(names(r.Header), ", "))
			http.Error(w, "no", http.StatusUnauthorized)
			return
		}

		// A cap on the body, read after the credential so that spending this
		// process's memory requires holding one.
		raw, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err != nil {
			http.Error(w, "unreadable", http.StatusBadRequest)
			return
		}

		var one delivery
		if err := json.Unmarshal(raw, &one); err != nil {
			log.Warn("a payment event that is not JSON", "error", err)
			http.Error(w, "not json", http.StatusBadRequest)
			return
		}

		what, act := meaning(one.Event)
		if !act {
			/* COUNTED AND IGNORED, WITH A 200. See the package comment: an
			   error here would stop the queue for everybody over an event about
			   somebody opening an invoice. */
			log.Info("a payment event nothing acts on", "event", one.Event)
			w.WriteHeader(http.StatusOK)
			return
		}

		switch err := settle.Apply(r.Context(), what, one.Payment.Reference,
			one.Payment.ID); {
		case errors.Is(err, ErrNoIntent):
			/* AN EVENT ABOUT A CHARGE THIS PLATFORM DID NOT MAKE. It happens on
			   a sandbox somebody has been clicking around in, and it would
			   happen in production if a charge were ever raised from the
			   provider's own screen. It is not an error and it is not silent. */
			log.Warn("a payment event about a charge nobody here made",
				"event", one.Event, "charge", one.Payment.ID)
			w.WriteHeader(http.StatusOK)
			return
		case err != nil:
			/* THE ONLY 5XX. The queue stops, the provider comes back, and the
			   alternative is losing a subscription somebody paid for because
			   the database blinked. */
			log.Error("acting on a payment event",
				"error", err, "event", one.Event, "charge", one.Payment.ID)
			http.Error(w, "try again", http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
	})
}

// authorised compares in constant time, over hashes so that the comparison is
// between two values of one length — `subtle.ConstantTimeCompare` returns early
// on differing lengths, and a length is the first thing a guesser wants.
func authorised(given string, want [sha256.Size]byte) bool {
	got := sha256.Sum256([]byte(strings.TrimSpace(given)))
	return subtle.ConstantTimeCompare(got[:], want[:]) == 1
}

// names is the header names, sorted, for the one log line that has to say what
// arrived without saying what was in it.
func names(h http.Header) []string {
	out := make([]string, 0, len(h))
	for name := range h {
		out = append(out, name)
	}
	sort.Strings(out)
	return out
}
