package visitor_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"sync/atomic"
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

// seedAccount makes a real account row, by SQL rather than through
// internal/identity: a module may not import another module, and a test that
// reaches across the boundary is the same coupling with a different file name.
func seedAccount(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	email := strings.ReplaceAll(uuid.NewString(), "-", "")[:16] + "@example.tld"

	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`, email).Scan(&id); err != nil {
		t.Fatalf("seeding an account: %v", err)
	}
	return id
}

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

// visitorCookie answers the identity cookie a response set, if it set one.
func visitorCookie(rec *httptest.ResponseRecorder) *http.Cookie {
	var found *http.Cookie
	for _, c := range rec.Result().Cookies() {
		if c.Name == visitor.CookieName {
			found = c
		}
	}
	return found
}

// THE ONE THAT MATTERS.
//
// Somebody who has never signed up still has an identity, and the first touch
// recorded against it is the FIRST request's — where they came from, not where
// they were one click later. Without that, "how many of the people who arrived
// became students" is unanswerable for every period before the day it was
// added: not hard, unanswerable, because the visits already happened
// anonymously.
//
// IT TAKES TWO REQUESTS NOW, and that is the change. The first is offered an
// identity and writes nothing; the second hands the offer back and becomes a
// row. A page load is several requests, so a browser crosses that line without
// noticing — and a crawler, which hands nothing back, never becomes a row.
func TestAVisitorHasAnIdentityBeforeAnyAccountExists(t *testing.T) {
	pool := testPool(t)

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

	// The arrival, carrying everything a first touch is made of.
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/?utm_source=newsletter&utm_campaign=launch", nil)
	req.Header.Set("Referer", "https://example.com/post")
	req.Header.Set("Accept-Language", "pt-BR,pt;q=0.9")
	mw(handler(&seen)).ServeHTTP(rec, req)

	if seen != uuid.Nil {
		t.Error("a visitor was reported on a request that had not yet proved it keeps cookies")
	}
	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("nothing was offered, so the next request is a stranger again")
	}
	if !offered.HttpOnly {
		t.Error("the visitor cookie is readable by JavaScript, and therefore by an injected script")
	}
	if offered.SameSite != http.SameSiteLaxMode {
		t.Error("SameSite is not Lax — Strict withholds the cookie on an arrival from another " +
			"site, which is precisely the visit this exists to record")
	}

	// The second request, handing it back. THE ONLY THING IT CARRIES IS THE
	// COOKIE: no campaign, no referrer, a different path and another language —
	// so whatever lands in the row can only have come from the first request.
	next := httptest.NewRequest(http.MethodGet, "/courses", nil)
	next.Header.Set("Accept-Language", "de")
	next.AddCookie(offered)
	rec2 := httptest.NewRecorder()
	mw(handler(&seen)).ServeHTTP(rec2, next)

	if seen == uuid.Nil {
		t.Fatal("the cookie was handed back and still nobody was identified")
	}
	accepted := visitorCookie(rec2)
	if accepted == nil {
		t.Fatal("no identity cookie replaced the offer, so the offer would be taken up twice")
	}
	if accepted.Value != seen.String() {
		t.Errorf("the cookie says %q and the request saw %q", accepted.Value, seen)
	}

	// The first touch was recorded, and it is the first one.
	var path, source, campaign, referrer, locale string
	if err := pool.QueryRow(context.Background(), `
		SELECT first_path, utm_source, utm_campaign, first_referrer, locale
		  FROM visitors WHERE id = $1
	`, seen).Scan(&path, &source, &campaign, &referrer, &locale); err != nil {
		t.Fatalf("reading the visitor: %v", err)
	}
	if source != "newsletter" || campaign != "launch" {
		t.Errorf("the campaign was not recorded: source=%q campaign=%q", source, campaign)
	}
	if referrer != "https://example.com/post" {
		t.Errorf("referrer %q, want where they came from", referrer)
	}
	if locale != "pt-br" {
		t.Errorf("locale %q, want pt-br — the second request said `de`, and the first is the "+
			"one that counts", locale)
	}
	if path != "/" {
		t.Errorf("first path %q, want the page they landed on rather than the next one", path)
	}
}

// THE POINT OF THE WHOLE CHANGE.
//
// A caller that ignores Set-Cookie is offered an identity every time and never
// becomes a row. That is every crawler, every scanner and every `curl` — three
// hundred and sixty-five of which had written themselves into the funnel's
// denominator within a day of this site having an address.
func TestSomethingThatIgnoresCookiesNeverBecomesARow(t *testing.T) {
	pool := testPool(t)

	count := func() int {
		var n int
		if err := pool.QueryRow(context.Background(),
			`SELECT count(*) FROM visitors`).Scan(&n); err != nil {
			t.Fatalf("counting visitors: %v", err)
		}
		return n
	}

	// NO TRUNCATE AND NO ASSERTION ABOUT THE TOTAL: other packages write to
	// this table in parallel. What is asserted is that ten cookie-less requests
	// did not add ten rows.
	before := count()

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)
	for range 10 {
		rec := httptest.NewRecorder()
		mw(handler(&seen)).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
		if visitorCookie(rec) == nil {
			t.Fatal("nothing was offered, so a browser would never be counted either")
		}
	}

	if added := count() - before; added >= 10 {
		t.Errorf("ten cookie-less requests wrote %d rows — a crawler is still a visitor", added)
	}
}

// An offer is not an identity, and one handed back cannot bring its own school.
// Every other field of a first touch was already the caller's to choose; the
// school is the server's, resolved from the host.
func TestAnOfferCannotChooseItsOwnSchool(t *testing.T) {
	pool := testPool(t)

	slug := "t" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]
	var resolved uuid.UUID
	if err := pool.QueryRow(context.Background(), `
		INSERT INTO tenants (slug, name) VALUES ($1, 'Resolved') RETURNING id
	`, slug).Scan(&resolved); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}

	school := func(context.Context) (uuid.UUID, string, bool) { return resolved, slug, true }

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), school, visitor.Settings{}, nil)

	rec := httptest.NewRecorder()
	mw(handler(&seen)).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("nothing was offered")
	}

	next := httptest.NewRequest(http.MethodGet, "/", nil)
	next.AddCookie(offered)
	mw(handler(&seen)).ServeHTTP(httptest.NewRecorder(), next)
	if seen == uuid.Nil {
		t.Fatal("the offer was handed back and nobody was identified")
	}

	var got uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`SELECT first_tenant_id FROM visitors WHERE id = $1`, seen).Scan(&got); err != nil {
		t.Fatalf("reading the visitor: %v", err)
	}
	if got != resolved {
		t.Errorf("the school on the row is %s, want the one the request resolved to (%s)",
			got, resolved)
	}
}

// The same browser is the same person on the next request. Issuing a new
// identity each time would count one visitor as many, which is the failure that
// makes every funnel number too good.
func TestTheSameBrowserKeepsItsIdentity(t *testing.T) {
	pool := testPool(t)

	var first, second uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

	// Two requests to get an identity at all: the first is offered one, the
	// second takes it up. See TestAVisitorHasAnIdentityBeforeAnyAccountExists.
	rec := httptest.NewRecorder()
	mw(handler(&first)).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("no identity was offered")
	}
	accept := httptest.NewRequest(http.MethodGet, "/", nil)
	accept.AddCookie(offered)
	mw(handler(&first)).ServeHTTP(httptest.NewRecorder(), accept)
	if first == uuid.Nil {
		t.Fatal("no identity was issued")
	}

	// And now the browser that already has one.
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
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.AddCookie(&http.Cookie{Name: visitor.CookieName, Value: uuid.New().String()})
	rec := httptest.NewRecorder()
	mw(handler(&seen)).ServeHTTP(rec, req)

	// A fresh OFFER, not a fresh row: the browser that sent a dead id has to
	// prove it still keeps cookies like any other caller, and it will, on the
	// very next request of the same page load.
	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("a stale cookie left the browser with nothing to come back with")
	}
	if offered.Value == req.Cookies()[0].Value {
		t.Fatal("the dead id was handed straight back")
	}

	accept := httptest.NewRequest(http.MethodGet, "/", nil)
	accept.AddCookie(offered)
	mw(handler(&seen)).ServeHTTP(httptest.NewRecorder(), accept)

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
	mw := visitor.Identify(visitor.NewStore(broken), nil, visitor.Settings{}, nil)
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

	phone, _, err := store.Create(ctx, uuid.Nil, visitor.FirstTouch{Path: "/"})
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}
	laptop, _, err := store.Create(ctx, uuid.Nil, visitor.FirstTouch{Path: "/plans"})
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	account := seedAccount(t, pool)
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

// THE ARRIVAL IS EMITTED ONCE, AND ONLY WHEN AN IDENTITY IS ISSUED.
//
// It is the first step of the funnel and the only one that cannot be
// reconstructed afterwards: by the time somebody signs up, the visit that
// brought them is over. Emitted on every request it would count returns as
// arrivals, and "how many of those who arrived became students" would answer
// with a denominator that grows every time somebody comes back.
func TestArrivingIsCountedOnceAndNotOnEveryVisit(t *testing.T) {
	pool := testPool(t)

	var arrivals []uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{},
		func(_ context.Context, id uuid.UUID) { arrivals = append(arrivals, id) })

	served := mw(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))

	first := httptest.NewRecorder()
	served.ServeHTTP(first, httptest.NewRequest(http.MethodGet, "/", nil))

	if len(arrivals) != 0 {
		t.Fatalf("an arrival was counted for a caller that had not kept a cookie yet")
	}

	offered := visitorCookie(first)
	if offered == nil {
		t.Fatal("no identity was offered")
	}
	accept := httptest.NewRequest(http.MethodGet, "/", nil)
	accept.AddCookie(offered)
	accepted := httptest.NewRecorder()
	served.ServeHTTP(accepted, accept)

	if len(arrivals) != 1 {
		t.Fatalf("a browser arriving was counted %d times", len(arrivals))
	}

	// The same browser, coming back with the cookie it was given.
	cookie := visitorCookie(accepted)
	if cookie == nil {
		t.Fatal("no identity cookie was set")
	}

	for range 3 {
		again := httptest.NewRequest(http.MethodGet, "/", nil)
		again.AddCookie(cookie)
		served.ServeHTTP(httptest.NewRecorder(), again)
	}

	if len(arrivals) != 1 {
		t.Errorf("coming back was counted as arriving: %d arrivals for one browser", len(arrivals))
	}
	if arrivals[0].String() != cookie.Value {
		t.Errorf("the arrival names %s and the cookie says %s", arrivals[0], cookie.Value)
	}
}

// AND A FUNNEL THAT CANNOT COUNT MUST NOT BE ABLE TO STOP ANYBODY. The visitor
// is already being served by the time the arrival is recorded; a recorder that
// panicked or a store that was down cannot turn a prospective student away.
func TestAnArrivalThatCannotBeCountedStillServesThePage(t *testing.T) {
	pool := testPool(t)

	served := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)(
		http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(http.StatusTeapot)
		}))

	rec := httptest.NewRecorder()
	served.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

	if rec.Code != http.StatusTeapot {
		t.Errorf("the page answered %d with nobody counting arrivals", rec.Code)
	}
}

// A PAGE LOAD IS SEVERAL REQUESTS AT ONCE, and they all hand back the same
// offer. Each of them writes, and they have to write the SAME row — otherwise
// one browser is four people, the funnel gets four arrivals for one visit, and
// three identity cookies overwrite each other on the way out.
//
// The offer carries the id, so every one of those inserts is the same insert
// and all but the first do nothing.
func TestOneBrowserOpeningFourRequestsAtOnceIsOnePerson(t *testing.T) {
	pool := testPool(t)

	var arrivals atomic.Int64
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{},
		func(context.Context, uuid.UUID) { arrivals.Add(1) })

	// The page load that gets the offer.
	rec := httptest.NewRecorder()
	var ignored uuid.UUID
	mw(handler(&ignored)).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("nothing was offered")
	}

	// And the four calls that page makes, together.
	seen := make([]uuid.UUID, 4)
	var wg sync.WaitGroup
	for i := range seen {
		wg.Add(1)
		go func() {
			defer wg.Done()
			req := httptest.NewRequest(http.MethodGet, "/api", nil)
			req.AddCookie(offered)
			mw(handler(&seen[i])).ServeHTTP(httptest.NewRecorder(), req)
		}()
	}
	wg.Wait()

	for i, id := range seen {
		if id == uuid.Nil {
			t.Fatalf("request %d was not identified", i)
		}
		if id != seen[0] {
			t.Errorf("one browser became two people: %s and %s", seen[0], id)
		}
	}

	var rows int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM visitors WHERE id = $1`, seen[0]).Scan(&rows); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if rows != 1 {
		t.Errorf("%d rows for one identity", rows)
	}
	if n := arrivals.Load(); n != 1 {
		t.Errorf("one visit was counted as %d arrivals", n)
	}
}

// WHAT THE PAGE SAYS, BECAUSE THE SERVER CANNOT SEE IT.
//
// This middleware sits on `/api/v1/` and the page never passes through it, so
// the request that reaches here is an XHR: its referrer is this site, its path
// is an API route, and the campaign that brought somebody was on the address
// bar and is on no request at all. All three read as data and all three were
// wrong.
func TestTheFirstTouchIsTheLandingAndNotTheApiCall(t *testing.T) {
	pool := testPool(t)

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

	// The XHR, exactly as a browser sends it: an API path, and a `Referer`
	// naming this very site.
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/catalog", nil)
	req.Header.Set("Referer", "https://code.example.tld/")
	req.Header.Set(visitor.HeaderLanding,
		"https://code.example.tld/plans?utm_source=newsletter&utm_medium=email&utm_campaign=launch")
	req.Header.Set(visitor.HeaderLandingReferrer, "https://news.example.com/issue-4")
	mw(handler(&seen)).ServeHTTP(rec, req)

	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("nothing was offered")
	}
	next := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	next.AddCookie(offered)
	mw(handler(&seen)).ServeHTTP(httptest.NewRecorder(), next)
	if seen == uuid.Nil {
		t.Fatal("the offer was handed back and nobody was identified")
	}

	var path, referrer, source, medium, campaign string
	if err := pool.QueryRow(context.Background(), `
		SELECT first_path, first_referrer, utm_source, utm_medium, utm_campaign
		  FROM visitors WHERE id = $1
	`, seen).Scan(&path, &referrer, &source, &medium, &campaign); err != nil {
		t.Fatalf("reading the visitor: %v", err)
	}

	if path != "/plans" {
		t.Errorf("first path %q, want the page they landed on", path)
	}
	if referrer != "https://news.example.com/issue-4" {
		t.Errorf("referrer %q, want the site that sent them rather than this one", referrer)
	}
	if source != "newsletter" || medium != "email" || campaign != "launch" {
		t.Errorf("the campaign was lost: source=%q medium=%q campaign=%q", source, medium, campaign)
	}
}

// An empty landing referrer is an ANSWER — a typed address, or a bookmark — and
// falling back to the request's own would answer with this site instead.
func TestALandingWithNoReferrerIsNotThisSite(t *testing.T) {
	pool := testPool(t)

	var seen uuid.UUID
	mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/api/v1/catalog", nil)
	req.Header.Set("Referer", "https://code.example.tld/")
	req.Header.Set(visitor.HeaderLanding, "https://code.example.tld/")
	req.Header.Set(visitor.HeaderLandingReferrer, "")
	mw(handler(&seen)).ServeHTTP(rec, req)

	offered := visitorCookie(rec)
	if offered == nil {
		t.Fatal("nothing was offered")
	}
	next := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	next.AddCookie(offered)
	mw(handler(&seen)).ServeHTTP(httptest.NewRecorder(), next)

	var referrer string
	if err := pool.QueryRow(context.Background(),
		`SELECT first_referrer FROM visitors WHERE id = $1`, seen).Scan(&referrer); err != nil {
		t.Fatalf("reading the visitor: %v", err)
	}
	if referrer != "" {
		t.Errorf("referrer %q, want nothing — they arrived without one", referrer)
	}
}

// A header that is not a URL is a header to ignore. It must not fail a request
// that was only ever going to serve a page.
func TestARubbishLandingHeaderIsIgnoredRatherThanBelieved(t *testing.T) {
	pool := testPool(t)

	for _, rubbish := range []string{
		"not a url",
		"/relative/only",
		"https://example.com", // absolute, but names no page
		strings.Repeat("https://example.com/x", 100),
		"://",
	} {
		var seen uuid.UUID
		mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/api/v1/catalog?utm_source=fallback", nil)
		req.Header.Set(visitor.HeaderLanding, rubbish)
		mw(handler(&seen)).ServeHTTP(rec, req)

		offered := visitorCookie(rec)
		if offered == nil {
			t.Fatalf("%q: nothing was offered", rubbish)
		}
		next := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
		next.AddCookie(offered)
		mw(handler(&seen)).ServeHTTP(httptest.NewRecorder(), next)
		if seen == uuid.Nil {
			t.Fatalf("%q: the request was not served an identity", rubbish)
		}

		var path, source string
		if err := pool.QueryRow(context.Background(),
			`SELECT first_path, utm_source FROM visitors WHERE id = $1`, seen).
			Scan(&path, &source); err != nil {
			t.Fatalf("%q: reading the visitor: %v", rubbish, err)
		}
		if path != "/api/v1/catalog" || source != "fallback" {
			t.Errorf("%q was believed: path=%q source=%q", rubbish, path, source)
		}
	}
}

// THE PAGE IS IN THE FRAGMENT, because that is where this interface's routes
// live. Reading only the path would record `/` for every visitor ever.
func TestTheLandingPageIsTheFragmentRoute(t *testing.T) {
	pool := testPool(t)

	for _, c := range []struct {
		name, landing, path, source string
	}{
		{"a link builder writes the query before the fragment",
			"https://code.example.tld/?utm_source=newsletter#/plans", "/plans", "newsletter"},
		{"a person writes it inside the fragment",
			"https://code.example.tld/#/plans?utm_source=newsletter", "/plans", "newsletter"},
		{"and where both say something, the one before the fragment wins",
			"https://code.example.tld/?utm_source=outer#/plans?utm_source=inner", "/plans", "outer"},
		{"no fragment at all is the page itself",
			"https://code.example.tld/?utm_source=newsletter", "/", "newsletter"},
		{"a fragment that is not a route leaves the path alone",
			"https://code.example.tld/plans#somewhere", "/plans", ""},
	} {
		t.Run(c.name, func(t *testing.T) {
			var seen uuid.UUID
			mw := visitor.Identify(visitor.NewStore(pool), nil, visitor.Settings{}, nil)

			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodGet, "/api/v1/catalog", nil)
			req.Header.Set(visitor.HeaderLanding, c.landing)
			req.Header.Set(visitor.HeaderLandingReferrer, "")
			mw(handler(&seen)).ServeHTTP(rec, req)

			offered := visitorCookie(rec)
			if offered == nil {
				t.Fatal("nothing was offered")
			}
			next := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
			next.AddCookie(offered)
			mw(handler(&seen)).ServeHTTP(httptest.NewRecorder(), next)

			var path, source string
			if err := pool.QueryRow(context.Background(),
				`SELECT first_path, utm_source FROM visitors WHERE id = $1`, seen).
				Scan(&path, &source); err != nil {
				t.Fatalf("reading the visitor: %v", err)
			}
			if path != c.path {
				t.Errorf("first path %q, want %q", path, c.path)
			}
			if source != c.source {
				t.Errorf("utm_source %q, want %q", source, c.source)
			}
		})
	}
}
