package identity_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/internal/identity"
	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// server mounts the routes behind the same middleware cmd/api uses. Testing a
// handler without the middleware would prove nothing about the part that
// matters, which is whether a cookie turns into an account.
func server(t *testing.T, store *identity.Store, signedUp identity.SignedUp) http.Handler {
	t.Helper()
	mux := http.NewServeMux()
	identity.NewHandler(store, identity.Settings{}, signedUp).Routes(mux)
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
