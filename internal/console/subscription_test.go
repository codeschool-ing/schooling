package console_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/console"
)

/* What an operator can DO about a subscription.

   THE CLAIM IS THAT NONE OF IT HAPPENS UNSEEN. Three writes that give away
   time, stop a notice, and put money in the books — every one behind a second
   rank, every one refusing to proceed without a sentence saying why, and every
   one recorded BEFORE it is done so that a failure to record is a refusal to
   act.

   Whether the arithmetic is right is `billing`'s test, against a real Postgres.
   What this file holds is the shape the console puts around it. */

type subFakes struct {
	person console.Person
	found  bool

	held    console.Holding
	heldErr error

	extendErr error
	cancelErr error
	adjustErr error

	extended []int
	cancels  int
	adjusted []adjustment

	entries   []recorded
	recordErr error

	actor uuid.UUID
	may   bool
}

type adjustment struct {
	cents    int
	currency string
	memo     string
}

func (f *subFakes) handler() http.Handler {
	h := console.NewSubscriptionHandler(
		console.People{
			ByID: func(_ context.Context, id uuid.UUID) (console.Person, error) {
				if !f.found || id != f.person.ID {
					return console.Person{}, console.ErrNoPerson
				}
				return f.person, nil
			},
		},
		console.Subscriptions{
			Held: func(context.Context, uuid.UUID) (console.Holding, error) {
				return f.held, f.heldErr
			},
			Extend: func(_ context.Context, _ uuid.UUID, days int) (console.Holding, error) {
				if f.extendErr != nil {
					return console.Holding{}, f.extendErr
				}
				f.extended = append(f.extended, days)
				return f.held, nil
			},
			Cancel: func(context.Context, uuid.UUID) (console.Holding, error) {
				if f.cancelErr != nil {
					return console.Holding{}, f.cancelErr
				}
				f.cancels++
				return f.held, nil
			},
			Adjust: func(_ context.Context, _ uuid.UUID,
				cents int, currency, memo string) error {

				if f.adjustErr != nil {
					return f.adjustErr
				}
				f.adjusted = append(f.adjusted, adjustment{cents, currency, memo})
				return nil
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

func subscriber() *subFakes {
	through := time.Now().Add(200 * 24 * time.Hour)
	return &subFakes{
		person: console.Person{
			ID:    uuid.MustParse("44444444-4444-4444-8444-444444444444"),
			Name:  "Sam Oliveira",
			Email: "sam@example.tld",
		},
		found: true,
		held: console.Holding{
			State: "active", Opens: true, Model: "instalments", PaidThrough: &through,
		},
		actor: uuid.MustParse("55555555-5555-4555-8555-555555555555"),
		may:   true,
	}
}

func post(t *testing.T, h http.Handler, where string, body any) *httptest.ResponseRecorder {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, where, strings.NewReader(string(raw))))
	return rec
}

func at(f *subFakes, tail string) string {
	return "/console/api/v1/people/" + f.person.ID.String() + tail
}

/* ---------- the rank, and the reason ---------- */

// A READ-ONLY ROLE MAY LOOK AND MAY NOT GIVE AWAY MONTHS. The door asks for
// read-only because a screen nobody can open is a screen nobody checks; this is
// the second rank, and it is on the handler rather than in a rule somebody
// remembers.
func TestChangingASubscriptionNeedsMoreThanReadOnly(t *testing.T) {
	for _, where := range []string{"/subscription/extend", "/subscription/cancel", "/ledger/adjustment"} {
		f := subscriber()
		f.may = false

		rec := post(t, f.handler(), at(f, where), map[string]any{
			"why": "a support case", "days": 30, "cents": 100, "currency": "BRL",
		})
		if rec.Code != http.StatusForbidden {
			t.Errorf("%s answered %d to a read-only role, want 403", where, rec.Code)
		}
		if len(f.entries) != 0 {
			t.Errorf("%s recorded something it refused to do", where)
		}
	}
}

/*
TestNothingHappensWithoutAReason is the assertion this whole file is arranged
around.

	`before` AND `after` SAY WHAT CHANGED AND CAN NEVER SAY WHAT FOR. Two dates
	do not explain sixty free days and an amount does not explain itself at all.
	The refusal is in the handler rather than in the form, because a field a
	screen asks for politely is a field that is empty in exactly the rows
	somebody goes looking for.
*/
func TestNothingHappensWithoutAReason(t *testing.T) {
	for _, where := range []string{"/subscription/extend", "/subscription/cancel", "/ledger/adjustment"} {
		for _, why := range []string{"", "   "} {
			f := subscriber()

			rec := post(t, f.handler(), at(f, where), map[string]any{
				"why": why, "days": 30, "cents": 100, "currency": "BRL",
			})
			if rec.Code != http.StatusBadRequest {
				t.Errorf("%s answered %d to a reason of %q, want 400", where, rec.Code, why)
			}
			if len(f.entries) != 0 || len(f.extended) != 0 || f.cancels != 0 || len(f.adjusted) != 0 {
				t.Errorf("%s acted on a request with no reason", where)
			}
		}
	}
}

// AN UNRECORDABLE CHANGE IS NOT MADE. `plan.go`'s rule, and the right way
// round: a change nobody can account for is worse than a change that did not
// happen.
func TestAChangeThatCouldNotBeRecordedIsNotMade(t *testing.T) {
	f := subscriber()
	f.recordErr = errors.New("the audit is unreachable")

	rec := post(t, f.handler(), at(f, "/subscription/extend"),
		map[string]any{"why": "an outage", "days": 30})
	if rec.Code != http.StatusServiceUnavailable {
		t.Errorf("it answered %d, want 503", rec.Code)
	}
	if len(f.extended) != 0 {
		t.Error("the term was extended even though nothing recorded it")
	}
}

/* ---------- giving time ---------- */

func TestGivingTimeIsRecordedWithBothDatesAndTheReason(t *testing.T) {
	f := subscriber()

	rec := post(t, f.handler(), at(f, "/subscription/extend"), map[string]any{
		"why": "the March outage cost them a fortnight", "days": 30,
	})
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.extended) != 1 || f.extended[0] != 30 {
		t.Fatalf("the store was asked for %v days", f.extended)
	}
	if len(f.entries) != 1 {
		t.Fatalf("it wrote %d entries", len(f.entries))
	}

	one := f.entries[0]
	if one.action != "subscription.extended" {
		t.Errorf("the entry is %q", one.action)
	}
	if one.subject.Kind != "account" || one.subject.ID != f.person.ID.String() {
		t.Errorf("it is about %+v", one.subject)
	}
	if one.why != "the March outage cost them a fortnight" {
		t.Errorf("the reason reads %q", one.why)
	}

	/* BOTH DATES AND NOT THE NUMBER OF DAYS. "60 days" a year later is
	   arithmetic against a term nobody has in front of them any more. */
	before, after := fmt.Sprint(one.what.Before), fmt.Sprint(one.what.After)
	if before == after {
		t.Errorf("the entry says it went from %q to %q, which is no change", before, after)
	}
	if !strings.Contains(before, f.held.PaidThrough.Format(time.DateOnly)) {
		t.Errorf("the entry says it ran to %q and it ran to %s",
			before, f.held.PaidThrough.Format(time.DateOnly))
	}
	want := f.held.PaidThrough.AddDate(0, 0, 30).Format(time.DateOnly)
	if !strings.Contains(after, want) {
		t.Errorf("the entry says it now runs to %q, want %s", after, want)
	}
}

/*
TestATermIsCappedAtAYear.

	A CEILING AND NOT A CONFIRMATION DIALOGUE. The mistake is a typed zero —
	3650 where 365 was meant — and "are you sure" is answered yes by the same
	reflex that typed it. Ten years given by a slipped finger is recoverable by
	nothing this console has.
*/
func TestATermIsCappedAtAYear(t *testing.T) {
	for _, days := range []int{0, -30, 3650} {
		f := subscriber()

		rec := post(t, f.handler(), at(f, "/subscription/extend"),
			map[string]any{"why": "a slip", "days": days})
		if rec.Code != http.StatusBadRequest {
			t.Errorf("%d days answered %d, want 400", days, rec.Code)
		}
		if len(f.extended) != 0 {
			t.Errorf("%d days reached the store", days)
		}
	}
}

// EXTENDING WHAT DOES NOT EXIST IS A 400 AND NOT A 404. The person is there —
// they were just read — and what is missing is the thing being changed. A "no
// such person" would send an operator hunting for a typo in an id they pasted
// off the screen in front of them.
func TestExtendingSomethingNobodyHasSaysWhichIsMissing(t *testing.T) {
	f := subscriber()
	f.held = console.Holding{} // signed in, never subscribed

	rec := post(t, f.handler(), at(f, "/subscription/extend"),
		map[string]any{"why": "goodwill", "days": 30})
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("it answered %d, want 400", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "no subscription") {
		t.Errorf("it said %q", rec.Body.String())
	}
	if len(f.entries) != 0 {
		t.Error("it recorded a change to a subscription that does not exist")
	}
}

/* ---------- cancelling ---------- */

// CANCELLING DOES NOT TAKE ACCESS AWAY AND THE ENTRY SAYS SO. Every purchase
// here is a term bought outright; the paid period is honoured, and an audit
// reading "cancelled" with no date would be read a year later as "cut off".
func TestCancellingRecordsThatTheTermIsStillHonoured(t *testing.T) {
	f := subscriber()

	rec := post(t, f.handler(), at(f, "/subscription/cancel"),
		map[string]any{"why": "they asked to stop"})
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if f.cancels != 1 {
		t.Fatalf("the store was cancelled %d times", f.cancels)
	}
	if len(f.entries) != 1 || f.entries[0].action != "subscription.cancelled" {
		t.Fatalf("it wrote %+v", f.entries)
	}

	after := fmt.Sprint(f.entries[0].what.After)
	if !strings.Contains(after, "honoured") {
		t.Errorf("the entry says %q and does not say the paid term stands", after)
	}
	if !strings.Contains(after, f.held.PaidThrough.Format(time.DateOnly)) {
		t.Errorf("the entry says %q and does not say until when", after)
	}
}

/*
TestRulesRefusingIsA400AndTheRecordStands.

	THE HONEST WAY ROUND. The entry says an operator asked; the answer says the
	billing rules would not. Cancelling something already over is the case, and
	an operator reading "it is already ended" has what they need — where a 500
	would send them to a log that says the same thing an hour later.
*/
func TestRulesRefusingIsA400AndTheRecordStands(t *testing.T) {
	f := subscriber()
	f.cancelErr = fmt.Errorf("%w: it is already over", console.ErrNotAllowedThere)

	rec := post(t, f.handler(), at(f, "/subscription/cancel"),
		map[string]any{"why": "they asked to stop"})
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("it answered %d, want 400: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "already over") {
		t.Errorf("it said %q, which does not tell an operator why", rec.Body.String())
	}
	if len(f.entries) != 1 {
		t.Error("the attempt was not recorded, so nothing says an operator tried")
	}
}

/* ---------- money that moved elsewhere ---------- */

func TestAnAdjustmentCarriesItsReasonIntoTheLedgerAsWellAsTheAudit(t *testing.T) {
	f := subscriber()

	rec := post(t, f.handler(), at(f, "/ledger/adjustment"), map[string]any{
		"why": "bank transfer, receipt 4471", "cents": -6900, "currency": "brl",
	})
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.adjusted) != 1 {
		t.Fatalf("%d adjustments were written", len(f.adjusted))
	}

	one := f.adjusted[0]
	if one.cents != -6900 {
		t.Errorf("it wrote %d cents", one.cents)
	}
	// UPPER CASED AT THE BOUNDARY, because `plan_prices` and the ledger both
	// hold a three-letter code and a lower-case one is a different string.
	if one.currency != "BRL" {
		t.Errorf("the currency reads %q", one.currency)
	}
	/* THE SAME SENTENCE IN TWO PLACES, ON PURPOSE. The audit answers "who did
	   this and why"; the ledger's memo answers "what is this row" to somebody
	   reading the books who has no reason to know a console exists. */
	if one.memo != "bank transfer, receipt 4471" {
		t.Errorf("the ledger memo reads %q", one.memo)
	}
	if f.entries[0].why != "bank transfer, receipt 4471" {
		t.Errorf("the audit reason reads %q", f.entries[0].why)
	}
}

// THE DIRECTION IS IN WORDS AND NOT ONLY IN A SIGN. Which way the money went is
// the thing an operator gets backwards at four in the afternoon, and a minus
// in front of a number is not a sentence anybody reads carefully a year later.
func TestAnAdjustmentSaysWhichWayTheMoneyWent(t *testing.T) {
	for cents, want := range map[int]string{-6900: "credited", 6900: "charged"} {
		f := subscriber()

		if rec := post(t, f.handler(), at(f, "/ledger/adjustment"), map[string]any{
			"why": "a correction", "cents": cents, "currency": "BRL",
		}); rec.Code != http.StatusOK {
			t.Fatalf("%d answered %d", cents, rec.Code)
		}
		if after := fmt.Sprint(f.entries[0].what.After); !strings.Contains(after, want) {
			t.Errorf("%d cents was recorded as %q, want it to say %q", cents, after, want)
		}
	}
}

// AN ADJUSTMENT OF NOTHING IS NOT A CORRECTION, and an adjustment of a fortune
// is a number typed in reais into a field that wants cents.
func TestAnAdjustmentHasToBeAnAmount(t *testing.T) {
	for _, cents := range []int{0, 10_000_00, -10_000_00} {
		f := subscriber()

		rec := post(t, f.handler(), at(f, "/ledger/adjustment"),
			map[string]any{"why": "a slip", "cents": cents, "currency": "BRL"})
		if rec.Code != http.StatusBadRequest {
			t.Errorf("%d cents answered %d, want 400", cents, rec.Code)
		}
		if len(f.adjusted) != 0 {
			t.Errorf("%d cents reached the ledger", cents)
		}
	}
}

// AN ADJUSTMENT NEEDS NO SUBSCRIPTION. Money can move for somebody who never
// subscribed — a refund of a checkout that opened one and was reversed, a
// transfer somebody sent by mistake — and the books have to be able to say so.
func TestAnAdjustmentDoesNotNeedASubscription(t *testing.T) {
	f := subscriber()
	f.held = console.Holding{}

	rec := post(t, f.handler(), at(f, "/ledger/adjustment"),
		map[string]any{"why": "a transfer sent by mistake", "cents": 6900, "currency": "BRL"})
	if rec.Code != http.StatusOK {
		t.Fatalf("it answered %d: %s", rec.Code, rec.Body.String())
	}
	if len(f.adjusted) != 1 {
		t.Error("the ledger row was not written")
	}
}

// AN ID BELONGING TO NOBODY IS A 404, and nothing is recorded against it.
func TestActingOnNobodyIsA404(t *testing.T) {
	f := subscriber()
	f.found = false

	rec := post(t, f.handler(), at(f, "/subscription/extend"),
		map[string]any{"why": "goodwill", "days": 30})
	if rec.Code != http.StatusNotFound {
		t.Errorf("it answered %d, want 404", rec.Code)
	}
	if len(f.entries) != 0 {
		t.Error("it recorded a change against an id that belongs to nobody")
	}
}
