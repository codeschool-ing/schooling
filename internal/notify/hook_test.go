package notify_test

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/notify"
	"github.com/codeschool-ing/schooling/internal/platform/web"
)

/* The endpoint the provider posts back to.

   IT IS SERVED THROUGH A MUX AND NOT CALLED DIRECTLY, because the secret
   arrives as a path parameter and `r.PathValue` is empty on a request nothing
   routed. A test that called the handler by hand would find every secret equal
   to every other and pass on a comparison it never made. */

const theSecret = "0123456789abcdef0123456789abcdef"

func hooked(t *testing.T, list *notify.Suppressions) *httptest.Server {
	t.Helper()
	mux := http.NewServeMux()
	mux.Handle("POST "+web.Hooks+"mail/{secret}",
		notify.Hook(theSecret, list, slog.New(slog.DiscardHandler)))

	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv
}

func post(t *testing.T, srv *httptest.Server, secret, body string) int {
	t.Helper()
	res, err := srv.Client().Post(
		srv.URL+web.Hooks+"mail/"+secret, "application/json", strings.NewReader(body))
	if err != nil {
		t.Fatalf("posting: %v", err)
	}
	defer func() { _ = res.Body.Close() }()
	_, _ = io.Copy(io.Discard, res.Body)
	return res.StatusCode
}

/*
A HARD BOUNCE ARRIVES AND THE ADDRESS STOPS BEING WRITTEN TO.

	The whole point, end to end: a provider's word goes in and the next message
	to that address does not go out.
*/
func TestAHardBounceStopsTheNextMessage(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)
	who := address(t)

	if got := post(t, srv, theSecret,
		`{"event":"hard_bounce","email":"`+who+`"}`); got != http.StatusOK {
		t.Fatalf("the hook answered %d, want 200", got)
	}

	barred, err := list.Barred(context.Background(), who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if !barred {
		t.Error("the address is not barred after a hard bounce")
	}
}

/*
AND A SOFT BOUNCE DOES NOT.

	This is the one that would have suppressed an entire provider during the
	outage of 27 August 2026, so it is checked rather than trusted to the switch
	being right — and it is checked on the hook rather than only on the list,
	because the filter that matters is the one at the door.
*/
func TestASoftBounceSuppressesNothing(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)

	for _, event := range []string{"soft_bounce", "delivered", "opened", "unsubscribed", "click"} {
		who := address(t)
		if got := post(t, srv, theSecret,
			`{"event":"`+event+`","email":"`+who+`"}`); got != http.StatusOK {
			t.Errorf("%q answered %d, want 200 — an event we ignore is not a failure "+
				"and answering otherwise buys a retry loop", event, got)
		}

		barred, err := list.Barred(context.Background(), who)
		if err != nil {
			t.Fatalf("asking: %v", err)
		}
		if barred {
			t.Errorf("%q barred the address", event)
		}
	}
}

// EVERY PERMANENT REASON THE PROVIDER HAS A WORD FOR. Three of ours, five of
// theirs, and the mapping is the part that silently stops working when a
// provider renames one.
func TestThePermanentReasonsAllBar(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)

	for _, event := range []string{"hard_bounce", "hardBounce", "blocked", "spam", "complaint"} {
		who := address(t)
		if got := post(t, srv, theSecret,
			`{"event":"`+event+`","email":"`+who+`"}`); got != http.StatusOK {
			t.Fatalf("%q answered %d, want 200", event, got)
		}

		barred, err := list.Barred(context.Background(), who)
		if err != nil {
			t.Fatalf("asking: %v", err)
		}
		if !barred {
			t.Errorf("%q did not bar the address", event)
		}
	}
}

/*
THE WRONG SECRET IS A 404 AND NOT A 403.

	A 403 says "there is something here and you may not have it", which tells
	somebody scanning that they have found the endpoint and only need the
	secret. A 404 says nothing at all, which is what this address is worth.
*/
func TestAWrongSecretIsRefused(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)
	who := address(t)
	body := `{"event":"hard_bounce","email":"` + who + `"}`

	for _, secret := range []string{
		"wrong",
		theSecret + "x",
		strings.ToUpper(theSecret),
		theSecret[:len(theSecret)-1],
	} {
		if got := post(t, srv, secret, body); got != http.StatusNotFound {
			t.Errorf("the secret %q answered %d, want 404", secret, got)
		}
	}

	barred, err := list.Barred(context.Background(), who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if barred {
		t.Error("a request with the wrong secret barred an address anyway")
	}
}

// A BATCH IS ONE BODY WITH SEVERAL EVENTS IN IT. A provider that sends one
// today may batch tomorrow, and the failure of not reading both shapes is
// silent: refusals nobody records.
func TestABatchIsReadWhole(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)
	one, two, three := address(t), address(t), address(t)

	body := `[{"event":"hard_bounce","email":"` + one + `"},` +
		`{"event":"delivered","email":"` + two + `"},` +
		`{"event":"spam","email":"` + three + `"}]`
	if got := post(t, srv, theSecret, body); got != http.StatusOK {
		t.Fatalf("a batch answered %d, want 200", got)
	}

	ctx := context.Background()
	for who, want := range map[string]bool{one: true, two: false, three: true} {
		barred, err := list.Barred(ctx, who)
		if err != nil {
			t.Fatalf("asking: %v", err)
		}
		if barred != want {
			t.Errorf("in a batch, %q ended up barred=%v, want %v", who, barred, want)
		}
	}
}

// A BODY THAT IS NOT JSON IS THE CALLER'S PROBLEM, and saying so is what stops
// the provider retrying it forever.
func TestABodyThatIsNotJSONIsRefused(t *testing.T) {
	srv := hooked(t, notify.NewSuppressions(testPool(t)))

	for _, body := range []string{"", "not json", "{", `{"event":`} {
		if got := post(t, srv, theSecret, body); got != http.StatusBadRequest {
			t.Errorf("the body %q answered %d, want 400", body, got)
		}
	}
}

// AN EVENT WITH NO ADDRESS ON IT IS NOT A FAILURE. The provider sends these for
// a request that never had a recipient; there is nothing to record and nothing
// wrong, and a 500 would buy a retry of a body that will never be different.
func TestAnEventAboutNobodyIsAccepted(t *testing.T) {
	srv := hooked(t, notify.NewSuppressions(testPool(t)))

	if got := post(t, srv, theSecret, `{"event":"hard_bounce","email":""}`); got != http.StatusOK {
		t.Errorf("an event with no address answered %d, want 200", got)
	}
}

/*
THE SECRET DOES NOT REACH THE LOG.

	This is the test the whole arrangement turns on. The secret is in the path
	because the provider does not sign anything, and `web.Logger` writes the path
	of every request — so without this redaction the one measure protecting the
	endpoint would be written to Cloud Logging on the first delivery, in plain
	text, and kept there.
*/
func TestTheSecretIsNotInTheLoggablePath(t *testing.T) {
	path := web.Hooks + "mail/" + theSecret

	got := web.Loggable(path)
	if strings.Contains(got, theSecret) {
		t.Errorf("the logged path is %q, which carries the secret", got)
	}
	if got != web.Hooks+"mail/..." {
		t.Errorf("the logged path is %q, want the prefix and an ellipsis", got)
	}

	// AND EVERY OTHER PATH IS UNTOUCHED, because a log that redacted the rest
	// would be a log nobody can use to find anything.
	for _, plain := range []string{"/api/v1/me", "/confirm/abc123", "/", "/readyz"} {
		if web.Loggable(plain) != plain {
			t.Errorf("%q was redacted to %q and is not a hook", plain, web.Loggable(plain))
		}
	}
}
