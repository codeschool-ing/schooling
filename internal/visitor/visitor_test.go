package visitor_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/visitor"
)

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("SCHOOLING_TEST_DATABASE_URL")
	if url == "" {
		t.Skip("set SCHOOLING_TEST_DATABASE_URL to run the tests that need a database")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		t.Fatalf("opening the test database: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

// NO TRUNCATE ANYWHERE IN THIS FILE. `go test` runs packages in parallel
// against one database, so clearing a shared table deletes another package's
// rows mid-run. Every assertion below is about the ids this test made.

// handler records the visitor the middleware resolved, so a test can check
// that the request underneath actually saw one.
func handler(seen *uuid.UUID) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if id, ok := visitor.FromContext(r.Context()); ok {
			*seen = id
		}
		w.WriteHeader(http.StatusOK)
	})
}

// THE ONE THAT MATTERS.
//
// Somebody who has never signed up still has an identity, issued on the first
// request, and the same browser keeps it on the next one. Without that, "how
// many of the people who arrived became students" is unanswerable for every
// period before the day it was added — not hard, unanswerable, because the
// visits already happened anonymously.
func TestAVisitorHasAnIdentityBeforeAnyAccountExists(t *testing.T) {
	pool := testPool(t)

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{})

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/?utm_source=newsletter&utm_campaign=launch", nil)
	req.Header.Set("Referer", "https://example.com/post")
	req.Header.Set("Accept-Language", "pt-BR,pt;q=0.9")
	mw(handler(&seen)).ServeHTTP(rec, req)

	if seen == uuid.Nil {
		t.Fatal("the request was served with no visitor at all")
	}

	// The cookie is what carries it to the next request.
	var issued *http.Cookie
	for _, c := range rec.Result().Cookies() {
		if c.Name == visitor.CookieName {
			issued = c
		}
	}
	if issued == nil {
		t.Fatal("no visitor cookie was set, so the next request is a different person")
	}
	if issued.Value != seen.String() {
		t.Errorf("the cookie says %q and the request saw %q", issued.Value, seen)
	}
	if !issued.HttpOnly {
		t.Error("the visitor cookie is readable by JavaScript, and therefore by an injected script")
	}
	if issued.SameSite != http.SameSiteLaxMode {
		t.Error("SameSite is not Lax — Strict withholds the cookie on an arrival from another " +
			"site, which is precisely the visit this exists to record")
	}

	// The first touch was recorded, and it is the first one.
	var source, campaign, referrer, locale string
	if err := pool.QueryRow(context.Background(), `
		SELECT utm_source, utm_campaign, first_referrer, locale FROM visitors WHERE id = $1
	`, seen).Scan(&source, &campaign, &referrer, &locale); err != nil {
		t.Fatalf("reading the visitor: %v", err)
	}
	if source != "newsletter" || campaign != "launch" {
		t.Errorf("the campaign was not recorded: source=%q campaign=%q", source, campaign)
	}
	if referrer != "https://example.com/post" {
		t.Errorf("referrer %q, want where they came from", referrer)
	}
	if locale != "pt-br" {
		t.Errorf("locale %q, want pt-br", locale)
	}
}

// The same browser is the same person on the next request. Issuing a new
// identity each time would count one visitor as many, which is the failure that
// makes every funnel number too good.
func TestTheSameBrowserKeepsItsIdentity(t *testing.T) {
	pool := testPool(t)

	var first, second uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{})

	rec := httptest.NewRecorder()
	mw(handler(&first)).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	if first == uuid.Nil {
		t.Fatal("no identity was issued")
	}

	next := httptest.NewRequest(http.MethodGet, "/courses", nil)
	next.AddCookie(&http.Cookie{Name: visitor.CookieName, Value: first.String()})
	rec2 := httptest.NewRecorder()
	mw(handler(&second)).ServeHTTP(rec2, next)

	if second != first {
		t.Errorf("the second request was a different visitor: %v then %v", first, second)
	}

	// And no second identity was issued: a browser that is handed a new cookie
	// on every request is counted as a new person on every request, which makes
	// every funnel number too good.
	for _, c := range rec2.Result().Cookies() {
		if c.Name == visitor.CookieName {
			t.Errorf("a second identity was issued to a browser that already had one: %s", c.Value)
		}
	}
}

// A cookie naming somebody who is gone — after an erasure, or a restore — gets
// a new identity rather than an id that joins to nothing.
func TestACookieThatOutlivedItsRowGetsANewIdentity(t *testing.T) {
	pool := testPool(t)

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{})

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.AddCookie(&http.Cookie{Name: visitor.CookieName, Value: uuid.New().String()})
	rec := httptest.NewRecorder()
	mw(handler(&seen)).ServeHTTP(rec, req)

	if seen == uuid.Nil {
		t.Fatal("a stale cookie left the request with no visitor")
	}
	var exists bool
	if err := pool.QueryRow(context.Background(),
		`SELECT EXISTS (SELECT 1 FROM visitors WHERE id = $1)`, seen).Scan(&exists); err != nil {
		t.Fatalf("checking: %v", err)
	}
	if !exists {
		t.Error("the request carried a visitor id that is not in the database")
	}
}

// Analytics being down is not a reason to refuse somebody the catalogue. The
// funnel must never become the thing that breaks what it measures.
func TestARequestIsServedEvenWhenNoIdentityCanBeIssued(t *testing.T) {
	testPool(t) // only to skip when there is no database configured

	// A pool pointed at a database that is not there.
	broken, err := pgxpool.New(context.Background(),
		"postgres://nobody:nobody@127.0.0.1:1/nothing?sslmode=disable&connect_timeout=1")
	if err != nil {
		t.Fatalf("building a deliberately broken pool: %v", err)
	}
	defer broken.Close()

	served := false
	mw := visitor.Identify(visitor.NewStore(broken), nil, visitor.Settings{})
	rec := httptest.NewRecorder()
	mw(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		served = true
		if _, ok := visitor.FromContext(r.Context()); ok {
			t.Error("a visitor was reported when none could be issued")
		}
		w.WriteHeader(http.StatusOK)
	})).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if !served {
		t.Error("the request was not served because the identity could not be issued — " +
			"the funnel broke the thing it exists to measure")
	}
	if rec.Code != http.StatusOK {
		t.Errorf("status %d, want 200", rec.Code)
	}
}

// One account, several devices, all of them them.
func TestAnAccountCanBeLinkedToEveryDeviceItArrivedOn(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	store := visitor.NewStore(pool)

	phone, err := store.Create(ctx, visitor.FirstTouch{Path: "/"})
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}
	laptop, err := store.Create(ctx, visitor.FirstTouch{Path: "/plans"})
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	account := uuid.New()
	for _, id := range []uuid.UUID{phone, laptop} {
		if err := store.Link(ctx, account, id); err != nil {
			t.Fatalf("linking: %v", err)
		}
	}
	// Signing in again from the same browser is the ordinary case, not an error.
	if err := store.Link(ctx, account, phone); err != nil {
		t.Errorf("linking the same pair twice failed: %v", err)
	}

	of, err := store.Of(ctx, account)
	if err != nil {
		t.Fatalf("reading the visitors of an account: %v", err)
	}
	if len(of) != 2 {
		t.Errorf("%d visitors linked, want both devices: %v", len(of), of)
	}
}
