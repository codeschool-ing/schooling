package identity_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"testing"

	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/geo"
	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// server mounts the routes behind the same middleware cmd/api uses. Testing a
// handler without the middleware would prove nothing about the part that
// matters, which is whether a cookie turns into an account.
func server(t *testing.T, store *identity.Store, signedUp identity.SignedUp) http.Handler {
	t.Helper()
	mux := http.NewServeMux()
	identity.NewHandler(store, identity.Settings{}, signedUp, nil, nil).Routes(mux)
	return web.Chain(mux, identity.Authenticate(store, identity.Nowhere))
}

// listening is `server` with a suppression list behind it, which is what the
// three tests about the banner's third sentence need and nothing else does.
func listening(t *testing.T, store *identity.Store, refused identity.Refused) http.Handler {
	t.Helper()
	mux := http.NewServeMux()
	identity.NewHandler(store, identity.Settings{},
		func(context.Context, identity.Account) {}, refused, nil).Routes(mux)
	return web.Chain(mux, identity.Authenticate(store, identity.Nowhere))
}

func post(t *testing.T, h http.Handler, path string, body any, cookies ...*http.Cookie) *httptest.ResponseRecorder {
	t.Helper()
	encoded, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("encoding the request: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, path, bytes.NewReader(encoded))
	for _, c := range cookies {
		req.AddCookie(c)
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func sessionCookie(t *testing.T, rec *httptest.ResponseRecorder) *http.Cookie {
	t.Helper()
	for _, c := range rec.Result().Cookies() {
		if c.Name == identity.CookieName {
			return c
		}
	}
	t.Fatalf("no session cookie in the response: %s", rec.Body.String())
	return nil
}

func TestSigningUpStartsASessionAndMeAnswersIt(t *testing.T) {
	store := identity.NewStore(testPool(t))

	var signedUp identity.Account
	h := server(t, store, func(_ context.Context, a identity.Account) { signedUp = a })

	email := address(t)
	rec := post(t, h, "/api/v1/sign-up", map[string]string{
		"email": email, "name": "Alexandre", "password": goodPassword,
	})
	if rec.Code != http.StatusCreated {
		t.Fatalf("sign-up answered %d: %s", rec.Code, rec.Body.String())
	}
	if signedUp.Email != email {
		t.Errorf("the SignedUp callback saw %q, want %q — it is what links the visitor who "+
			"arrived to the student they became", signedUp.Email, email)
	}

	cookie := sessionCookie(t, rec)
	if !cookie.HttpOnly {
		t.Error("the session cookie is readable by JavaScript, which is the whole reason the " +
			"app and the API share an origin")
	}
	if cookie.SameSite != http.SameSiteLaxMode {
		t.Errorf("SameSite is %v, want Lax", cookie.SameSite)
	}

	// And the session works on the next request.
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.AddCookie(cookie)
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /api/v1/me answered %d: %s", rec.Code, rec.Body.String())
	}
	var me map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &me); err != nil {
		t.Fatalf("the reply is not JSON: %v", err)
	}
	if me["email"] != email {
		t.Errorf("me answered %v, want %q", me["email"], email)
	}
	// `synthetic` is operational. A person told they are synthetic learns
	// something true and useless.
	if _, leaked := me["synthetic"]; leaked {
		t.Error("me carries the synthetic flag")
	}
}

// THE ONE THAT MATTERS.
//
// A sign-in form that answers differently for "no such address" and "wrong
// password" is a way to ask whether a particular person has an account on an
// education platform — which is a question about somebody's private life, and
// it is answered by a stranger with a list of addresses.
func TestSignInDoesNotSayWhetherAnAddressHasAnAccount(t *testing.T) {
	store := identity.NewStore(testPool(t))
	h := server(t, store, nil)
	_, email := create(t, store)

	wrongPassword := post(t, h, "/api/v1/sign-in", map[string]string{
		"email": email, "password": goodPassword + "!",
	})
	noSuchAccount := post(t, h, "/api/v1/sign-in", map[string]string{
		"email": address(t), "password": goodPassword,
	})

	if wrongPassword.Code != http.StatusUnauthorized || noSuchAccount.Code != http.StatusUnauthorized {
		t.Fatalf("statuses %d and %d, want 401 for both",
			wrongPassword.Code, noSuchAccount.Code)
	}
	if wrongPassword.Body.String() != noSuchAccount.Body.String() {
		t.Errorf("the two answers differ, so the form tells a stranger who has an account here:\n"+
			"  wrong password:   %s\n  no such account:  %s",
			wrongPassword.Body.String(), noSuchAccount.Body.String())
	}
}

// The same reasoning at the other door: a sign-up that says "that address
// already has an account" tells a stranger the same thing.
func TestSignUpDoesNotConfirmAnAddressEither(t *testing.T) {
	store := identity.NewStore(testPool(t))
	h := server(t, store, nil)
	_, email := create(t, store)

	rec := post(t, h, "/api/v1/sign-up", map[string]string{
		"email": email, "password": goodPassword,
	})
	if rec.Code != http.StatusConflict {
		t.Fatalf("a repeated sign-up answered %d, want 409", rec.Code)
	}
	if body := rec.Body.String(); !bytes.Contains([]byte(body), []byte("if that address")) {
		t.Errorf("the refusal confirms the address is registered: %s", body)
	}
}

func TestSigningOutEndsTheSession(t *testing.T) {
	store := identity.NewStore(testPool(t))
	h := server(t, store, nil)

	rec := post(t, h, "/api/v1/sign-up", map[string]string{
		"email": address(t), "password": goodPassword,
	})
	cookie := sessionCookie(t, rec)

	out := post(t, h, "/api/v1/sign-out", map[string]string{}, cookie)
	if out.Code != http.StatusOK {
		t.Fatalf("sign-out answered %d: %s", out.Code, out.Body.String())
	}

	// The cookie is cleared…
	if cleared := sessionCookie(t, out); cleared.MaxAge >= 0 {
		t.Errorf("the cookie was not expired: MaxAge=%d", cleared.MaxAge)
	}

	// …and the token is dead even for somebody who kept a copy of it, which is
	// the half that matters: clearing a cookie is a suggestion to the browser.
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.AddCookie(cookie)
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("the old token still answers me with %d — signing out cleared the cookie and "+
			"left the session alive", rec.Code)
	}
}

// Authenticate never refuses, and Require does. Half this API is legitimately
// anonymous, so a middleware that refused would need a list of exceptions —
// and a list of exceptions is where the one nobody added lives.
func TestAnAnonymousRequestPassesThroughAndIsRefusedOnlyWhereItSaysSo(t *testing.T) {
	store := identity.NewStore(testPool(t))

	reached := false
	open := web.Chain(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reached = true
		if _, ok := identity.FromContext(r.Context()); ok {
			t.Error("an anonymous request carried an account")
		}
		w.WriteHeader(http.StatusOK)
	}), identity.Authenticate(store, identity.Nowhere))

	rec := httptest.NewRecorder()
	open.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/catalogue", nil))
	if !reached || rec.Code != http.StatusOK {
		t.Errorf("an anonymous request was refused by the middleware: reached=%v status=%d",
			reached, rec.Code)
	}

	guarded := web.Chain(identity.Require(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		t.Error("a guarded route ran with nobody signed in")
		w.WriteHeader(http.StatusOK)
	})), identity.Authenticate(store, identity.Nowhere))

	rec = httptest.NewRecorder()
	guarded.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/progress", nil))
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("a guarded route answered %d with nobody signed in, want 401", rec.Code)
	}
}

/*
THE DIMENSIONS AN ACCOUNT IS BORN WITH, WHICH NOBODY WAS FILLING IN.

	`accounts.country` and `accounts.locale` were the literal string `unknown`
	on every account ever created: `signUp` built its `NewAccount` with an
	address, a name and a password, and the two report dimensions beside them
	were left to the column defaults. Every cohort screen that ever groups by
	either would have drawn one bar.

	THE OBVIOUS FIX FOR THE LANGUAGE WOULD HAVE BEEN WORSE THAN THE BUG.
	`web.Locale` was already there and already used everywhere — and it reads
	`?lang=`, which sign-up does not send, and falls back to English. It would
	have written `en` against every account on the platform. A missing value is
	a hole a report can see; a confident wrong one is not.

	IT GOES THROUGH THE MIDDLEWARE and not through a fabricated context,
	because what is under test is the wiring: the country arrives from
	`platform/geo`, which is the only thing in this repository that reads an
	address, and a test that put the value in by hand would pass with the
	middleware unmounted.
*/
func TestAnAccountIsBornWithTheCountryAndTheLanguage(t *testing.T) {
	store := identity.NewStore(testPool(t))

	var born identity.Account
	mux := http.NewServeMux()
	identity.NewHandler(store, identity.Settings{}, func(_ context.Context, a identity.Account) {
		born = a
	}, nil, nil).Routes(mux)

	h := web.Chain(mux,
		geo.Country(geo.Settings{
			Hops: 1,
			// Stands in for the database that is not chosen yet. What is
			// under test is that the address reaching it is the caller's.
			Resolve: func(addr netip.Addr) string {
				if addr.String() == "203.0.113.9" {
					return "BR"
				}
				return ""
			},
		}, slog.New(slog.DiscardHandler)),
		identity.Authenticate(store, identity.Nowhere),
	)

	body, err := json.Marshal(map[string]string{
		"email": address(t), "name": "Alexandre", "password": goodPassword,
	})
	if err != nil {
		t.Fatalf("encoding the request: %v", err)
	}

	// No `?lang=`, because the interface sends none — see `ui/app/api.js`.
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sign-up", bytes.NewReader(body))
	req.Header.Set("Accept-Language", "pt-BR,pt;q=0.9,en;q=0.8")

	// A forged entry in front of the real one, because that is what a caller
	// who wants to choose their own country would send.
	req.Header.Set(geo.HeaderForwardedFor, "198.51.100.7, 203.0.113.9")

	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusCreated && rec.Code != http.StatusOK {
		t.Fatalf("signing up answered %d: %s", rec.Code, rec.Body.String())
	}

	if born.Country != "br" {
		t.Errorf("the account was born in %q, want %q — the country is resolved from "+
			"the request by the middleware, from the entry OUR infrastructure wrote "+
			"and not the one the caller sent", born.Country, "br")
	}
	if born.Locale != "pt-br" {
		t.Errorf("the account reads %q, want %q — `web.Locale` would have answered "+
			"\"en\" here, which is the wrong fix for this", born.Locale, "pt-br")
	}
}

/* Whether the address refused us, which is the banner's third sentence.

   THE FIRST TWO WERE ABOUT WHETHER A LINK IS OUT THERE. This one is about
   whether the address will ever accept one, and it is the difference between a
   nudge and an explanation: "we sent a link to X" stays true forever after X
   hard-bounces, and the button beside it offers to send another. */

// me answers the account, as a map, for a session on this handler.
func meOf(t *testing.T, h http.Handler, cookie *http.Cookie) map[string]any {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.AddCookie(cookie)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("GET /api/v1/me answered %d: %s", rec.Code, rec.Body.String())
	}
	var out map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("the reply is not JSON: %v", err)
	}
	return out
}

// signUpOn creates an account through the handler and hands back its cookie and
// its address.
func signUpOn(t *testing.T, h http.Handler) (*http.Cookie, string) {
	t.Helper()
	email := address(t)
	rec := post(t, h, "/api/v1/sign-up", map[string]string{
		"email": email, "name": "Alexandre", "password": goodPassword,
	})
	if rec.Code != http.StatusCreated {
		t.Fatalf("sign-up answered %d: %s", rec.Code, rec.Body.String())
	}
	return sessionCookie(t, rec), email
}

// A REFUSED ADDRESS IS SAID SO, AND THE LIST IS ASKED ABOUT THE RIGHT ONE.
func TestTheAnswerSaysWhenAnAddressRefusedUs(t *testing.T) {
	store := identity.NewStore(testPool(t))

	var asked string
	h := listening(t, store, func(_ context.Context, a string) (bool, error) {
		asked = a
		return true, nil
	})

	cookie, email := signUpOn(t, h)
	if got := meOf(t, h, cookie)["emailRefused"]; got != true {
		t.Errorf("emailRefused is %v, want true", got)
	}
	if asked != email {
		t.Errorf("the list was asked about %q, want the account's %q", asked, email)
	}
}

// AND AN ADDRESS THAT DID NOT IS NOT ACCUSED OF IT. The obvious half, and the
// one that would fail if the check were inverted — every other test here wires
// no list at all, so nothing else would catch that.
func TestAnAddressThatNeverRefusedUsIsNotSaidTo(t *testing.T) {
	store := identity.NewStore(testPool(t))
	h := listening(t, store, func(context.Context, string) (bool, error) { return false, nil })

	cookie, _ := signUpOn(t, h)
	if got := meOf(t, h, cookie)["emailRefused"]; got != false {
		t.Errorf("emailRefused is %v, want false", got)
	}
}

/*
A LIST THAT CANNOT BE READ SAYS NOTHING, WHICH IS THE OPPOSITE OF `notify`.

	There, a database that will not answer must not become permission to write to
	somebody who said stop — the safe direction is "refused". Here the
	consequence is a sentence on a screen, and telling somebody their address
	refused our mail when we do not know is worse than staying quiet: they cannot
	check it, and they have no reason to doubt us.
*/
func TestABrokenListDoesNotAccuseAnAddress(t *testing.T) {
	store := identity.NewStore(testPool(t))
	h := listening(t, store, func(context.Context, string) (bool, error) {
		return false, errors.New("the database is on fire")
	})

	cookie, _ := signUpOn(t, h)
	if got := meOf(t, h, cookie)["emailRefused"]; got != false {
		t.Errorf("emailRefused is %v, want false — an unreadable list is not evidence", got)
	}
}

// AND A DEPLOYMENT WITH NO LIST ANSWERS THE FIELD ANYWAY, as false. A missing
// key would leave the interface's `me.emailRefused === true` reading undefined,
// which is the same answer — but the field being absent and the field being
// false are different contracts, and the interface is written against one.
func TestWithNoListTheFieldIsStillThereAndFalse(t *testing.T) {
	store := identity.NewStore(testPool(t))
	h := server(t, store, func(context.Context, identity.Account) {})

	cookie, _ := signUpOn(t, h)
	me := meOf(t, h, cookie)
	got, present := me["emailRefused"]
	if !present {
		t.Fatal("emailRefused is missing from the answer")
	}
	if got != false {
		t.Errorf("emailRefused is %v, want false", got)
	}
}

/* Asking to move an account, over HTTP.

   THE STORE'S TESTS COVER WHAT MOVES. These cover the three things only the
   handler decides: that a session alone is not enough, that an address we
   already know refuses our mail is turned away before a row is written, and
   that the caller is handed the link rather than the store sending it. */

// changing is `server` with a suppression list and a place for the link to go.
func changing(t *testing.T, store *identity.Store, refused identity.Refused,
	asked *identity.Change) http.Handler {

	t.Helper()
	mux := http.NewServeMux()
	identity.NewHandler(store, identity.Settings{},
		func(context.Context, identity.Account) {}, refused,
		func(_ context.Context, _ identity.Account, c identity.Change) { *asked = c },
	).Routes(mux)
	return web.Chain(mux, identity.Authenticate(store, identity.Nowhere))
}

/*
THE PASSWORD IS REQUIRED AND THE SESSION IS NOT ENOUGH.

	This is the security property of the whole feature. A stolen cookie lets
	somebody read; moving where the recovery mail goes is the step that turns it
	into a stolen account, and a session is exactly what an attacker holding a
	cookie has.
*/
func TestChangingAnAddressNeedsThePasswordAndNotJustASession(t *testing.T) {
	store := identity.NewStore(testPool(t))
	var asked identity.Change
	h := changing(t, store, nil, &asked)

	cookie, _ := signUpOn(t, h)
	rec := post(t, h, "/api/v1/account/email", map[string]string{
		"email": address(t), "password": "not the password",
	}, cookie)

	if rec.Code != http.StatusForbidden {
		t.Errorf("a wrong password answered %d, want 403", rec.Code)
	}
	if asked.Token != "" {
		t.Error("a link was issued for a request that did not carry the password")
	}
}

// AND A REQUEST WITH NO SESSION AT ALL IS 401 AND NOT 403, because the two are
// different sentences: one is "sign in" and the other is "that is not your
// password".
func TestChangingAnAddressWithNoSessionIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	var asked identity.Change
	h := changing(t, store, nil, &asked)

	rec := post(t, h, "/api/v1/account/email", map[string]string{
		"email": address(t), "password": goodPassword,
	})
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("no session answered %d, want 401", rec.Code)
	}
}

/*
AN ADDRESS THAT ALREADY REFUSED US IS TURNED AWAY BEFORE ANYTHING IS WRITTEN.

	Accepting it would issue a link nothing can deliver — into precisely the
	state this feature exists to get somebody out of, from the form built to do
	it. The answer carries its own code so the screen can say which of the four
	things went wrong.
*/
func TestMovingToAnAddressThatRefusedUsIsRefused(t *testing.T) {
	store := identity.NewStore(testPool(t))
	var asked identity.Change
	h := changing(t, store, func(context.Context, string) (bool, error) { return true, nil }, &asked)

	cookie, _ := signUpOn(t, h)
	rec := post(t, h, "/api/v1/account/email", map[string]string{
		"email": address(t), "password": goodPassword,
	}, cookie)

	if rec.Code != http.StatusUnprocessableEntity {
		t.Fatalf("a suppressed address answered %d, want 422: %s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "address_refused") {
		t.Errorf("the answer is %s, want the code the screen branches on", rec.Body.String())
	}
	if asked.Token != "" {
		t.Error("a link was issued for an address we know refuses our mail")
	}
}

// THE HAPPY PATH ANSWERS 202 AND HANDS THE LINK TO THE CALLER. Accepted, not
// done: nothing has changed when this returns, and the callback is what puts a
// message in the post.
func TestAskingToChangeAnAddressIsAcceptedAndHandsOverTheLink(t *testing.T) {
	store := identity.NewStore(testPool(t))
	var asked identity.Change
	h := changing(t, store, func(context.Context, string) (bool, error) { return false, nil }, &asked)

	cookie, was := signUpOn(t, h)
	next := address(t)
	rec := post(t, h, "/api/v1/account/email", map[string]string{
		"email": next, "password": goodPassword,
	}, cookie)

	if rec.Code != http.StatusAccepted {
		t.Fatalf("asking answered %d, want 202: %s", rec.Code, rec.Body.String())
	}
	if asked.Token == "" {
		t.Fatal("no link reached the caller, so no message can be sent")
	}
	if !strings.EqualFold(asked.Email, next) {
		t.Errorf("the link is for %q, want %q", asked.Email, next)
	}

	// AND THE ACCOUNT HAS NOT MOVED, which is the point of the 202.
	if me := meOf(t, h, cookie); !strings.EqualFold(me["email"].(string), was) {
		t.Errorf("the account is on %v already, want %q until the link is followed",
			me["email"], was)
	}
}
