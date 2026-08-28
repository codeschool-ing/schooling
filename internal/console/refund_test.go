package console_test

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* Money going back.

   THE CLAIM IS THAT THIS ROUTE WRITES NOTHING. It asks the gateway and stops;
   the ledger row and the closed subscription arrive with the webhook that
   refund causes, which is the path a refund made from Asaas's own dashboard
   already takes. What this file holds is everything around that: the rank, the
   typed confirmation, the reason, and that a refusal comes back in the
   gateway's own words rather than as one of ours. */

type refundFakes struct {
	bought  console.Purchase
	oneErr  error
	askErr  error
	status  string
	asked   []uuid.UUID
	entries []recorded

	recordErr error
	actor     uuid.UUID
	may       bool
}

func (f *refundFakes) handler() http.Handler {
	h := console.NewRefundHandler(
		console.Refunds{
			One: func(_ context.Context, id uuid.UUID) (console.Purchase, error) {
				if f.oneErr != nil {
					return console.Purchase{}, f.oneErr
				}
				if id != f.bought.ID {
					return console.Purchase{}, console.ErrNoPurchase
				}
				return f.bought, nil
			},
			Ask: func(_ context.Context, id uuid.UUID) (string, error) {
				if f.askErr != nil {
					return "", f.askErr
				}
				f.asked = append(f.asked, id)
				return f.status, nil
			},
		},
		func(_ context.Context, actor uuid.UUID, actorLabel, action string,
			subject console.Subject, what console.Changed, why, _ string) error {
			if f.recordErr != nil {
				return f.recordErr
			}
			f.entries = append(f.entries, recorded{action, actor, actorLabel, subject, what, why})
			return nil
		},
		func(context.Context, uuid.UUID) (string, string, error) {
			return "Alex", "alex@staff.tld", nil
		},
		func(context.Context) (uuid.UUID, bool) { return f.actor, f.actor != uuid.Nil },
		func(context.Context) bool { return f.may },
	)
	mux := http.NewServeMux()
	h.Routes(mux)
	return mux
}

func aPaidPurchase() *refundFakes {
	return &refundFakes{
		bought: console.Purchase{
			ID:        uuid.MustParse("66666666-6666-4666-8666-666666666666"),
			AccountID: uuid.MustParse("77777777-7777-4777-8777-777777777777"),
			ChargeID:  "pay_9vvwq9mgo4xq775x",
			OpenedAt:  time.Now().Add(-30 * 24 * time.Hour),
			Stage:     "paid",
			Cents:     65550,
			Listed:    69000,
			Currency:  "BRL",
			Method:    "pix",
		},
		status: "REFUNDED",
		actor:  uuid.MustParse("88888888-8888-4888-8888-888888888888"),
		may:    true,
	}
}

func refundAt(f *refundFakes) string {
	return "/console/api/v1/purchases/" + f.bought.ID.String() + "/refund"
}

// SENDING MONEY BACK ASKS FOR MORE THAN READ-ONLY, which is the erasure's rank
// and for the erasure's reason: the door asks for read-only so that a screen
// nobody can open is not a screen nobody checks.
func TestRefundingNeedsMoreThanReadOnly(t *testing.T) {
	f := aPaidPurchase()
	f.may = false

	rec := post(t, f.handler(), refundAt(f),
		map[string]any{"why": "they asked", "cents": 65550})
	if rec.Code != http.StatusForbidden {
		t.Errorf("it answered %d to a read-only role, want 403", rec.Code)
	}
	if len(f.asked) != 0 {
		t.Error("it asked the gateway anyway")
	}
}

/*
TestTheAmountHasToBeTyped.

	THE MISTAKE THIS GUARDS AGAINST IS THE WRONG ROW AND NOT THE WRONG SCREEN.
	The record names the person; what it also carries is four purchases with four
	buttons that look identical, and the one an operator means is the one they
	just read out over the telephone. Typing the amount means having read the
	line.
*/
func TestTheAmountHasToBeTyped(t *testing.T) {
	for _, cents := range []int{0, 69000, 6555, 655500} {
		f := aPaidPurchase()

		rec := post(t, f.handler(), refundAt(f),
			map[string]any{"why": "they asked", "cents": cents})
		if rec.Code != http.StatusBadRequest {
			t.Errorf("%d answered %d, want 400", cents, rec.Code)
		}
		if len(f.asked) != 0 {
			t.Errorf("%d reached the gateway", cents)
		}
		if len(f.entries) != 0 {
			t.Errorf("%d was recorded as a refund somebody asked for", cents)
		}
	}
}

func TestARefundIsAskedForAndRecordedWithItsReason(t *testing.T) {
	f := aPaidPurchase()

	rec := post(t, f.handler(), refundAt(f), map[string]any{
		"why": "the course was withdrawn, ticket 903", "cents": 65550,
	})
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.asked) != 1 || f.asked[0] != f.bought.ID {
		t.Fatalf("the gateway was asked about %v", f.asked)
	}

	if len(f.entries) != 1 {
		t.Fatalf("it wrote %d entries", len(f.entries))
	}
	one := f.entries[0]
	if one.action != "purchase.refunded" {
		t.Errorf("the entry is %q", one.action)
	}
	/* THE SUBJECT IS THE ACCOUNT AND NOT THE PURCHASE, so this sits with
	   everything else that happened to the person — which is how the audit is
	   searched. The purchase is named in `after`, where a detail belongs. */
	if one.subject.Kind != "account" || one.subject.ID != f.bought.AccountID.String() {
		t.Errorf("it is about %+v, want the account", one.subject)
	}
	if !strings.Contains(fmt.Sprint(one.what.After), f.bought.ID.String()) {
		t.Errorf("the entry does not name the purchase: %v", one.what.After)
	}
	if one.why != "the course was withdrawn, ticket 903" {
		t.Errorf("the reason reads %q", one.why)
	}

	/* AND THE ANSWER SAYS THE ACCESS HAS NOT CLOSED YET, because it has not.
	   The subscription ends when the event arrives, seconds later and not in
	   this request — and an operator who said "done" and then watched a student
	   keep studying would stop trusting this screen. */
	if !strings.Contains(rec.Body.String(), "event") {
		t.Errorf("the answer does not say the closing is still to come: %s", rec.Body.String())
	}
}

// NOTHING GOES BACK WITHOUT A REASON, as with the other three writes: money
// that moved and nobody can account for is worse than money that stayed.
func TestARefundNeedsAReason(t *testing.T) {
	f := aPaidPurchase()

	rec := post(t, f.handler(), refundAt(f), map[string]any{"why": "  ", "cents": 65550})
	if rec.Code != http.StatusBadRequest {
		t.Errorf("it answered %d, want 400", rec.Code)
	}
	if len(f.asked) != 0 {
		t.Error("it asked the gateway with no reason recorded")
	}
}

// A CHECKOUT NOBODY PAID HAS NOTHING TO SEND BACK, and saying so here is more
// use than letting the gateway say it: an abandoned row carries an amount and
// looks, in a table, exactly like a paid one.
func TestWhatWasNeverPaidCannotBeRefunded(t *testing.T) {
	for _, stage := range []string{"opened", "charged", "abandoned"} {
		f := aPaidPurchase()
		f.bought.Stage = stage

		rec := post(t, f.handler(), refundAt(f),
			map[string]any{"why": "they asked", "cents": 65550})
		if rec.Code != http.StatusBadRequest {
			t.Errorf("%s answered %d, want 400", stage, rec.Code)
		}
		if len(f.asked) != 0 {
			t.Errorf("a %s checkout reached the gateway", stage)
		}
	}
}

/*
TestTheGatewaysRefusalComesBackInItsOwnWords.

	THIS IS THE ONE PLACE THE CONSOLE SHOWS SOMEBODY ELSE'S SENTENCE VERBATIM,
	and it is right here. A key without the refund permission and a charge in a
	state that cannot be refunded both arrive as one status with a line of
	Portuguese support prose, and only the prose says which of the two an
	operator has to go and fix. Turning it into a message of ours would throw
	away the only thing that distinguishes them.
*/
func TestTheGatewaysRefusalComesBackInItsOwnWords(t *testing.T) {
	f := aPaidPurchase()
	f.askErr = fmt.Errorf("%w: %s", console.ErrGatewayRefused,
		"Não é possível estornar uma cobrança recebida em dinheiro.")

	rec := post(t, f.handler(), refundAt(f),
		map[string]any{"why": "they asked", "cents": 65550})
	if rec.Code != http.StatusBadGateway {
		t.Fatalf("it answered %d, want 502: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "recebida em dinheiro") {
		t.Errorf("their words did not reach the screen: %s", rec.Body.String())
	}

	/* AND THE ATTEMPT IS STILL RECORDED. An entry saying somebody asked for
	   money to go back is true whether or not the gateway agreed, and it is the
	   thing an audit is for — a log of successes alone cannot answer "who
	   tried". */
	if len(f.entries) != 1 {
		t.Error("a refusal left no record that anybody had asked")
	}
}

/*
TestAGatewayThatCouldNotBeReachedSaysSoCarefully.

	THE ONE ANSWER THAT MUST NOT SOUND LIKE EITHER OUTCOME. A timeout is not "it
	did not happen": the request may have been taken and the reply lost, and an
	operator who read this as a failure and pressed again would be sending the
	money back twice. So it says what is actually known — that it was recorded,
	and that the gateway is where the truth is.
*/
func TestAGatewayThatCouldNotBeReachedSaysSoCarefully(t *testing.T) {
	f := aPaidPurchase()
	f.askErr = errors.New("dial tcp: i/o timeout")

	rec := post(t, f.handler(), refundAt(f),
		map[string]any{"why": "they asked", "cents": 65550})
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("it answered %d, want 503", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "check there") {
		t.Errorf("it does not send the operator to the gateway before retrying: %s",
			rec.Body.String())
	}
}

// AN UNRECORDABLE REFUND IS NOT ASKED FOR. The rule the other three follow, and
// it bites hardest here: money that went back with nothing saying who sent it
// is the entry somebody will want most and cannot recover.
func TestARefundThatCouldNotBeRecordedIsNotAsked(t *testing.T) {
	f := aPaidPurchase()
	f.recordErr = errors.New("the audit is unreachable")

	rec := post(t, f.handler(), refundAt(f),
		map[string]any{"why": "they asked", "cents": 65550})
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("it answered %d, want 503", rec.Code)
	}
	if len(f.asked) != 0 {
		t.Error("the gateway was asked even though nothing recorded it")
	}
}

// A PURCHASE THAT IS NOT THERE IS A 404 AND REACHES NOTHING.
func TestRefundingAPurchaseNobodyHasIsA404(t *testing.T) {
	f := aPaidPurchase()

	rec := post(t, f.handler(),
		"/console/api/v1/purchases/"+uuid.New().String()+"/refund",
		map[string]any{"why": "they asked", "cents": 65550})
	if rec.Code != http.StatusNotFound {
		t.Errorf("it answered %d, want 404", rec.Code)
	}
	if len(f.entries) != 0 {
		t.Error("it recorded a refund of a purchase that does not exist")
	}
}
