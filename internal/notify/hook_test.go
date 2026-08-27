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

   IT IS SERVED OVER A REAL LISTENER rather than by calling the handler, because
   what is being checked is what a REQUEST carries: a header that Go's client
   builds, a status a client can read, and a challenge in a response. Calling the
   function with a hand-made `*http.Request` would pass on a request nothing
   ever sent. */

const (
	theUser     = "brevo"
	thePassword = "0123456789abcdef0123456789abcdef"
)

func hooked(t *testing.T, list *notify.Suppressions) *httptest.Server {
	t.Helper()
	mux := http.NewServeMux()
	mux.Handle("POST "+web.Hooks+"mail",
		notify.Hook(theUser, thePassword, list, slog.New(slog.DiscardHandler)))

	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv
}

// post sends one delivery event with the right credential.
func post(t *testing.T, srv *httptest.Server, body string) int {
	t.Helper()
	return postAs(t, srv, theUser, thePassword, body)
}

// postAs is the same with a credential of the caller's choosing, which is how
// the refusals below are checked.
func postAs(t *testing.T, srv *httptest.Server, user, password, body string) int {
	t.Helper()
	req, err := http.NewRequest(http.MethodPost, srv.URL+web.Hooks+"mail",
		strings.NewReader(body))
	if err != nil {
		t.Fatalf("building the request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if user != "" || password != "" {
		req.SetBasicAuth(user, password)
	}

	res, err := srv.Client().Do(req)
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

	if got := post(t, srv,
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

	for _, event := range []string{"soft_bounce", "delivered", "opened", "unsubscribed", "click", "deferred"} {
		who := address(t)
		if got := post(t, srv,
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

// EVERY PERMANENT REASON THE PROVIDER HAS A WORD FOR. Four of ours, seven of
// theirs, and the mapping is the part that silently stops working when a
// provider renames one.
func TestThePermanentReasonsAllBar(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)

	for _, event := range []string{
		"hard_bounce", "hardBounce", "blocked", "spam", "complaint", "invalid", "invalid_email",
	} {
		who := address(t)
		if got := post(t, srv, `{"event":"`+event+`","email":"`+who+`"}`); got != http.StatusOK {
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
THE WRONG CREDENTIAL IS A 401 WITH A CHALLENGE, WHICH IS THE OPPOSITE OF WHAT
THE PATH VERSION ANSWERED.

	A path carrying a secret had to answer 404, because "this is here and you may
	not have it" tells a scanner they have found the endpoint. The address is
	public now — it is in this repository — so hiding it buys nothing, and 401
	tells the provider its CREDENTIAL is wrong rather than its URL.

	EVERY HALF-WRONG SHAPE IS HERE, including the empty one: a request with no
	Authorization header at all must not be the one that gets through.
*/
func TestAWrongCredentialIsRefused(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	srv := hooked(t, list)
	who := address(t)
	body := `{"event":"hard_bounce","email":"` + who + `"}`

	for _, credential := range []struct{ user, password string }{
		{"", ""},
		{theUser, ""},
		{"", thePassword},
		{theUser, thePassword + "x"},
		{theUser, thePassword[:len(thePassword)-1]},
		{theUser, strings.ToUpper(thePassword)},
		{"nobody", thePassword},
		{thePassword, theUser},
	} {
		got := postAs(t, srv, credential.user, credential.password, body)
		if got != http.StatusUnauthorized {
			t.Errorf("the credential %q/%q answered %d, want 401",
				credential.user, redact(credential.password), got)
		}
	}

	barred, err := list.Barred(context.Background(), who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if barred {
		t.Error("a request with the wrong credential barred an address anyway")
	}
}

// AND THE REFUSAL CARRIES A CHALLENGE, because a 401 without one is a status
// code that says "authenticate" and does not say how.
func TestTheRefusalSaysHowToAuthenticate(t *testing.T) {
	srv := hooked(t, notify.NewSuppressions(testPool(t)))

	req, err := http.NewRequest(http.MethodPost, srv.URL+web.Hooks+"mail", strings.NewReader("{}"))
	if err != nil {
		t.Fatalf("building the request: %v", err)
	}
	res, err := srv.Client().Do(req)
	if err != nil {
		t.Fatalf("posting: %v", err)
	}
	defer func() { _ = res.Body.Close() }()
	_, _ = io.Copy(io.Discard, res.Body)

	if got := res.Header.Get("WWW-Authenticate"); !strings.HasPrefix(got, "Basic") {
		t.Errorf("the challenge is %q, want one that names Basic", got)
	}
}

/*
THE CREDENTIAL IS NOT IN THE ADDRESS, WHICH IS THE WHOLE POINT OF THE MOVE.

	Held here rather than left to the reader of `cmd/api`, because the failure it
	prevents is silent: a path parameter added back for any reason would put a
	secret into the request log, the address bar and every screenshot of the
	provider's form — which is exactly what happened the first time.
*/
func TestTheAddressCarriesNothingSecret(t *testing.T) {
	srv := hooked(t, notify.NewSuppressions(testPool(t)))
	path := web.Hooks + "mail"

	if strings.Contains(path, thePassword) || strings.Contains(path, theUser) {
		t.Fatalf("the hook's path is %q and carries the credential", path)
	}

	// AND THE OLD SHAPE IS GONE. A route left mounted under `/hooks/mail/…`
	// would be the path version still answering beside the header one.
	if got := postAs(t, srv, theUser, thePassword, "{}"); got == http.StatusNotFound {
		t.Fatal("the hook is not at /hooks/mail")
	}
	res, err := srv.Client().Post(
		srv.URL+web.Hooks+"mail/"+thePassword, "application/json", strings.NewReader("{}"))
	if err != nil {
		t.Fatalf("posting: %v", err)
	}
	defer func() { _ = res.Body.Close() }()
	_, _ = io.Copy(io.Discard, res.Body)
	if res.StatusCode != http.StatusNotFound {
		t.Errorf("a secret in the path answered %d, want 404 — that route is gone",
			res.StatusCode)
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
	if got := post(t, srv, body); got != http.StatusOK {
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
		if got := post(t, srv, body); got != http.StatusBadRequest {
			t.Errorf("the body %q answered %d, want 400", body, got)
		}
	}
}

// AN EVENT WITH NO ADDRESS ON IT IS NOT A FAILURE. The provider sends these for
// a request that never had a recipient; there is nothing to record and nothing
// wrong, and a 500 would buy a retry of a body that will never be different.
func TestAnEventAboutNobodyIsAccepted(t *testing.T) {
	srv := hooked(t, notify.NewSuppressions(testPool(t)))

	if got := post(t, srv, `{"event":"hard_bounce","email":""}`); got != http.StatusOK {
		t.Errorf("an event with no address answered %d, want 200", got)
	}
}

/*
THE HOOK'S PATH IS STILL REDACTED IN THE LOG, THOUGH NOTHING IN IT IS SECRET.

	Kept deliberately: the payment gateway's webhooks arrive under this prefix
	next, from a provider whose arrangements nobody has read yet, and this is
	what stops a secret put back into a path from reaching Cloud Logging with
	nothing catching it.
*/
func TestAHookPathIsNotLoggedWhole(t *testing.T) {
	if got := web.Loggable(web.Hooks + "mail/anything"); got != web.Hooks+"mail/..." {
		t.Errorf("the logged path is %q, want the prefix and an ellipsis", got)
	}

	// AND EVERY OTHER PATH IS UNTOUCHED, because a log that redacted the rest
	// would be a log nobody can use to find anything.
	for _, plain := range []string{"/api/v1/me", "/confirm/abc123", "/", "/readyz", "/hooks/mail"} {
		if web.Loggable(plain) != plain {
			t.Errorf("%q was redacted to %q and has no tail to hide", plain, web.Loggable(plain))
		}
	}
}

// redact keeps a password out of a test's own failure message, which is written
// to CI's log like any other line.
func redact(password string) string {
	if password == "" {
		return ""
	}
	return "…"
}
