package main

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/config"
)

// testRouter builds the whole handler the way cmd/api does, with no database
// and no configuration worth the name.
//
// A NIL POOL IS THE POINT of both tests below, so it is passed here rather
// than hidden: the routes under test must answer when the database is the
// thing that is broken, and a query of any kind panics rather than passing.
func testRouter(t *testing.T) http.Handler {
	t.Helper()
	return router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)), config.Config{}, nil)
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

// A HOST IS A SCHOOL'S, OR THE CONSOLE'S, OR A 404 (K-17).
//
// Three cases and no fourth, checked at the outermost handler where the split
// happens. The pool is nil on purpose, as above: none of these three answers
// needs a database, and a query of any kind panics rather than passing.
func TestAHostIsASchoolsOrTheConsolesOrA404(t *testing.T) {
	srv := router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)),
		config.Config{PlatformDomain: "example.tld"}, nil)

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
		config.Config{PlatformDomain: "example.tld"}, nil)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/console/api/v1/me", nil)
	req.Host = "CONSOLE.Example.TLD:8099" // and the host is normalised like a school's
	srv.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("answered %d with nobody signed in, want 401", rec.Code)
	}
}
