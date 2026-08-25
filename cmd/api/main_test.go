package main

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"net/netip"

	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/geo"
	"github.com/codeschool-ing/schooling/internal/platform/geo/dbip"
)

// testRouter builds the whole handler the way cmd/api does, with no database
// and no configuration worth the name.
//
// A NIL POOL IS THE POINT of both tests below, so it is passed here rather
// than hidden: the routes under test must answer when the database is the
// thing that is broken, and a query of any kind panics rather than passing.
func testRouter(t *testing.T) http.Handler {
	t.Helper()
	return router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)), config.Config{}, nil, nil)
}

// `/version` answers with no database, and that is the whole point of it.
//
// It is asked during an incident, by whoever is holding a pager, and the
// incident is usually the database. A handler that reads one row to decorate
// the reply would be an improvement on every day except the one it is for — so
// the pool here is nil, and a query of any kind panics the test rather than
// passing it.
func TestVersionAnswersWithoutADatabase(t *testing.T) {
	srv := testRouter(t)

	rec := httptest.NewRecorder()
	srv.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/version", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /version answered %d, want 200", rec.Code)
	}

	var got struct {
		Version  string `json:"version"`
		Released bool   `json:"released"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("the reply is not JSON: %v — %s", err, rec.Body.String())
	}

	// Unstamped, which is what a test binary is. The value matters less than
	// the pair agreeing: a build that claims a version it was not given is the
	// failure this reports.
	if got.Version != "dev" {
		t.Errorf("an unstamped build called itself %q, want \"dev\"", got.Version)
	}
	if got.Released {
		t.Error("an unstamped build called itself released")
	}
}

// The version route belongs to no school, and neither does readiness. Putting
// either behind the tenant middleware would mean the platform's own probes
// depending on a row in the database — and answering 404 at any address a
// school has not claimed, which includes the one the platform probes.
func TestTheOperationalRoutesBelongToNoSchool(t *testing.T) {
	srv := testRouter(t)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	req.Host = "nobody.example.tld"
	srv.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("GET /version at a host no school claims answered %d, want 200 — "+
			"it is asked at whatever address the platform reaches the instance on", rec.Code)
	}
}

// A HOST IS A SCHOOL'S, OR THE CONSOLE'S, OR THE PLATFORM'S, OR A 404 (K-17).
//
// IT USED TO BE THREE CASES AND IT IS FOUR, which is the line worth reading
// twice: this test is the whole of what stands between "a second address" and
// "every route reachable from one more place". Each case below is a route
// answering at ITS address and refusing at the others.
//
// The pool is nil on purpose, as above: none of these answers needs a database,
// and a query of any kind panics rather than passing.
func TestAHostIsASchoolsTheConsolesAStudentsOwnTheFrontDoorOrA404(t *testing.T) {
	srv := router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)),
		config.Config{PlatformDomain: "example.tld"}, nil, nil)

	ask := func(host, path string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Host = host
		srv.ServeHTTP(rec, req)
		return rec
	}

	// THE CONSOLE'S. Nobody is signed in, so the second gate refuses — which is
	// itself the proof that the request reached the console side at all.
	if got := ask("console.example.tld", "/console/api/v1/me").Code; got != http.StatusUnauthorized {
		t.Errorf("the console's own API answered %d at the console's host, want 401 — "+
			"a request that never reached the staff gate cannot have been refused by it", got)
	}

	// A SCHOOL'S. The same path must not become the console by being typed at
	// another address. 404 AND NOT 401 IS THE ASSERTION: a 401 would mean the
	// staff gate ran here, which is the console existing at an address it does
	// not own. 404 is the interface saying there is no such page, which is true.
	elsewhere := ask("code.example.tld", "/console/api/v1/me")
	if elsewhere.Code == http.StatusUnauthorized {
		t.Error("a school's host refused a console path with 401, which means the staff gate ran " +
			"there — the console is reachable at an address it does not own")
	}
	if elsewhere.Code != http.StatusNotFound {
		t.Errorf("a console path at a school's host answered %d, want 404", elsewhere.Code)
	}

	// And the school's own routes still work there, so the split did not take
	// the school side with it. `/` is the interface, which needs no database.
	if got := ask("code.example.tld", "/").Code; got != http.StatusOK {
		t.Errorf("a school's own address answered %d for the interface, want 200", got)
	}

	// AND THE SCHOOL SIDE IS NOT REACHABLE AT THE CONSOLE'S ADDRESS EITHER.
	// The console's mux does not carry `/api/v1/`, so it is a 404 — not a 401,
	// because nothing gated it, and not a school, because there is none here.
	if got := ask("console.example.tld", "/api/v1/school").Code; got != http.StatusNotFound {
		t.Errorf("a school route answered %d at the console's host, want 404", got)
	}

	/* THE STUDENT'S OWN. Nobody is signed in, so the queue refuses with 401 —
	   and that 401 is the proof the request reached this side: no school was
	   resolved for it and no database was touched to refuse it. A 404 here
	   would mean the address routed to the school mux and found nothing.

	   IT IS NOT CALLED "THE PLATFORM'S" ANY MORE, and that is not tidying: the
	   platform's own address is the bare domain, which now answers, and two
	   things called the same thing in one test is how somebody asserts about
	   the wrong one. */
	if got := ask("my.example.tld", "/api/v1/review").Code; got != http.StatusUnauthorized {
		t.Errorf("the cross-school queue answered %d at the student's own host, want 401 — "+
			"a request that never reached it cannot have been refused by it", got)
	}

	/* AND THE SCREEN IS THERE. It was a 404 until one was written for this
	   address, and the expectation changed in the commit that wrote it — which
	   is what that assertion was for.

	   It needs no database: the shell is bytes out of an embed, and what it
	   draws is decided by one request it makes afterwards. */
	if got := ask("my.example.tld", "/").Code; got != http.StatusOK {
		t.Errorf("the student's own address answered %d for its own screen, want 200", got)
	}

	// AND IT IS ITS OWN SCREEN AND NOT THE STUDY INTERFACE'S. `app/main.js`
	// exists in both trees; the one served here must be the one written for an
	// address with no school, and the study interface's must not be reachable.
	mine := ask("my.example.tld", "/app/queue.js")
	if mine.Code != http.StatusOK {
		t.Errorf("the student's own place did not serve its own script: %d", mine.Code)
	}
	if got := ask("my.example.tld", "/app/rail.js").Code; got != http.StatusNotFound {
		t.Errorf("a study-interface module answered %d at the student's address — those "+
			"assume a school, which is the whole reason this tree exists", got)
	}

	/* ---------- AND THE BARE DOMAIN, WHICH USED TO BE THE 404 ----------

	   It fell through to the school mux, where `tenant.Resolve` answered that no
	   school lives there — correct, and the one address somebody types having
	   heard the name and nothing else. The expectation changes here in the
	   commit that wrote a screen for it, which is what the old assertion was
	   for.

	   It needs no database: the shell is bytes out of an embed and what it
	   draws is decided by one request it makes afterwards. */
	if got := ask("example.tld", "/").Code; got != http.StatusOK {
		t.Errorf("the platform's own address answered %d for the front door, want 200", got)
	}

	/* AND IT IS ITS OWN TREE. `app/main.js` exists in all three and each is a
	   different file; what proves WHICH one is served is that the modules
	   beside the other two are not reachable here — one set assumes a school
	   and the other assumes a session, and this address has neither. */
	if got := ask("example.tld", "/app/main.js").Code; got != http.StatusOK {
		t.Errorf("the front door did not serve its own boot: %d", got)
	}
	for _, path := range []string{"/app/rail.js", "/app/queue.js", "/app/screens/dashboard.js"} {
		if got := ask("example.tld", path).Code; got != http.StatusNotFound {
			t.Errorf("GET %s answered %d at the front door, want 404 — that module belongs "+
				"to another address", path, got)
		}
	}

	// The student's queue is the student's, and the front door is reached by
	// people who have never signed in to anything.
	if got := ask("example.tld", "/api/v1/review").Code; got != http.StatusNotFound {
		t.Errorf("the cross-school queue answered %d at the front door, want 404", got)
	}

	// AND THE CONSOLE IS NOT REACHABLE FROM THE DOOR. 404 and never 401, for
	// the third time: a 401 would mean the staff gate ran at the most public
	// address this platform has.
	visitor := ask("example.tld", "/console/api/v1/me")
	if visitor.Code == http.StatusUnauthorized {
		t.Error("the front door refused a console path with 401, which means the staff " +
			"gate ran at the platform's most public address")
	}
	if visitor.Code != http.StatusNotFound {
		t.Errorf("a console path at the front door answered %d, want 404", visitor.Code)
	}

	if got := ask("console.example.tld", "/api/v1/review").Code; got != http.StatusNotFound {
		t.Errorf("the cross-school queue answered %d at the console's host, want 404", got)
	}

	/* WHAT THIS TEST CANNOT CHECK, SAID RATHER THAN LEFT LOOKING CHECKED.

	   The mistake worth catching on this route is registering it on the
	   school-scoped mux instead of the platform's — one line in the wrong place,
	   working perfectly, answering a question about every school from inside
	   one. It is not asserted here because it cannot be: every path under
	   `/api/v1/` at a school's host goes through `tenant.Resolve` FIRST, which
	   queries, and the pool is nil — so a registered route and an unregistered
	   one produce the identical 500 and this test would pass either way.

	   What holds it instead is `practice.NewAcrossHandler`, which is a second
	   handler type rather than a route on the first: putting it on `scoped`
	   does not compile into the school's practice handler by accident, it has
	   to be written deliberately. The database-backed proof belongs to a suite
	   that has one.

	   `tenant.NewFrontHandler` is the same shape for the same reason, and the
	   stake is higher: the route it carries LISTS EVERY SCHOOL, and `Store.All`
	   says at its own definition that nothing on a school's host may enumerate.
	   Registered on `scoped` it would answer one school's visitors with the
	   names and prices of all the others, working perfectly. It is a separate
	   type with a differently named registration — `FrontRoutes` and not
	   `Routes` — so putting it in the wrong mux is a line somebody had to
	   write on purpose. */

	// AND THE CONSOLE IS NOT REACHABLE FROM THE PLATFORM'S ADDRESS. Same
	// assertion as the school's, one host along: 404 and never 401, because a
	// 401 would mean the staff gate ran at a student's address.
	student := ask("my.example.tld", "/console/api/v1/me")
	if student.Code == http.StatusUnauthorized {
		t.Error("the platform's address refused a console path with 401, which means the " +
			"staff gate ran at an address students reach")
	}
	if student.Code != http.StatusNotFound {
		t.Errorf("a console path at the platform's host answered %d, want 404", student.Code)
	}
}

// The first gate is the host and the second is the role, and they have to be
// separately sufficient to refuse (K-19).
//
// This checks the half that needs no database: with no session at all, the
// console's API refuses. The other half — a signed-in account with no staff
// role, and a staff account whose session has not shown a second factor — is
// `identity.RequireStaff`'s own test, which has a database to do it with.
func TestTheConsoleApiRefusesWithoutASession(t *testing.T) {
	srv := router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)),
		config.Config{PlatformDomain: "example.tld"}, nil, nil)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/console/api/v1/me", nil)
	req.Host = "CONSOLE.Example.TLD:8099" // and the host is normalised like a school's
	srv.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("answered %d with nobody signed in, want 401", rec.Code)
	}
}

/*
HOW MANY PROXIES ARE IN FRONT, WHICH IS A FACT ABOUT THE DEPLOYMENT.

	It is derived and not configured because it has a right answer per
	environment (K-13), and a right answer in a settings file is a knob whose
	only job is to be wrong one day. Getting it wrong is silent in every way
	except the alarm in `platform/geo`, so the value itself is worth pinning.
*/
func TestHowManyProxiesAreInFront(t *testing.T) {
	if got := proxiesInFront(config.Config{Environment: config.Production}); got != 1 {
		t.Errorf("production has %d proxies in front, want 1 — Cloud Run's front end "+
			"appends the address it saw, and anything the caller sent stays left of it", got)
	}
	for _, env := range []config.Environment{config.Development, ""} {
		if got := proxiesInFront(config.Config{Environment: env}); got != 0 {
			t.Errorf("%q has %d proxies in front, want 0 — nothing stands in front of a "+
				"laptop, so a header arriving there is the caller's own", env, got)
		}
	}
}

/*
AND THE DATABASE IS WIRED TO THE MIDDLEWARE BY `router` ITSELF.

	Every part of this is tested apart: `platform/geo` picks the caller out of
	the trail, `dbip` turns an address into two letters, `identity` writes them
	onto an account. What none of them can see is the wiring — a `geo.Resolve`
	that never reached the chain would answer `unknown` for every request on the
	platform while all of those stayed green.

	SO IT GOES THROUGH `router` AND NOT THROUGH A CHAIN THIS TEST BUILDS. The
	first version of this test built its own `geo.Settings` out of the same two
	calls, passed, and went on passing when `router` was changed to wire nil —
	which is to say it tested that this file can add two and two, not that the
	server does.

	A NIL POOL IS FINE HERE. The handler underneath will fail on a database
	that is not there, and `web.Recover` turns that into a 500; the middleware
	under test runs before either. What is asserted is what the resolver was
	asked, not what came back to the caller.

	`200.160.0.0/20` is NIC.br's own block in São Paulo. The entry in front of
	it is what somebody choosing their own country would send.
*/
func TestTheEmbeddedDatabaseIsWiredToTheMiddleware(t *testing.T) {
	countries, err := dbip.Open()
	if err != nil {
		t.Fatalf("opening the embedded country database: %v", err)
	}
	t.Cleanup(func() {
		if err := countries.Close(); err != nil {
			t.Errorf("closing the database: %v", err)
		}
	})

	var asked []netip.Addr
	var answered string
	srv := router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)),
		config.Config{PlatformDomain: "example.tld", Environment: config.Production},
		nil,
		func(addr netip.Addr) string {
			asked = append(asked, addr)
			answered = countries.Country(addr)
			return answered
		})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/courses", nil)
	req.Host = "code.example.tld"
	req.Header.Set(geo.HeaderForwardedFor, "8.8.8.8, 200.160.2.3")
	srv.ServeHTTP(httptest.NewRecorder(), req)

	if len(asked) == 0 {
		t.Fatal("the country was never resolved for a request that went through the " +
			"whole router — the resolver `router` was given did not reach the chain")
	}
	if got := asked[0].String(); got != "200.160.2.3" {
		t.Fatalf("the country was resolved for %s, which is the entry the CALLER "+
			"wrote — the caller is the one our own infrastructure appended", got)
	}
	if answered != "br" {
		t.Errorf("the embedded database put %s in %q, want %q", asked[0], answered, "br")
	}
}
