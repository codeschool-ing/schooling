package billing_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

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
func holdingFor(t *testing.T, account uuid.UUID, signedIn bool) http.Handler {
	t.Helper()
	pool := testPool(t)

	h := billing.NewHolding(billing.NewStore(pool), billing.NewPrices(pool),
		func(context.Context) (uuid.UUID, bool) { return account, signedIn })

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
	through := time.Now().AddDate(0, 12, 0)
	if _, err := plans.Begin(ctx, account, billing.ScopeEverything,
		billing.ModelInstalments, bought, time.Now(), through, nil); err != nil {
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
	if d := got.Sub(through); d > time.Minute || d < -time.Minute {
		t.Errorf("access runs to %s and the subscription says %s", got, through)
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
	ran := time.Now().AddDate(0, 0, -40)
	if _, err := plans.Begin(ctx, account, billing.ScopeEverything,
		billing.ModelInstalments, bought, ran.AddDate(0, -12, 0), ran, nil); err != nil {
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
