package main

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
)

// `/version` answers with no database, and that is the whole point of it.
//
// It is asked during an incident, by whoever is holding a pager, and the
// incident is usually the database. A handler that reads one row to decorate
// the reply would be an improvement on every day except the one it is for — so
// the pool here is nil, and a query of any kind panics the test rather than
// passing it.
func TestVersionAnswersWithoutADatabase(t *testing.T) {
	srv := router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)))

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
	srv := router(nil, slog.New(slog.NewTextHandler(io.Discard, nil)))

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/version", nil)
	req.Host = "nobody.example.tld"
	srv.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("GET /version at a host no school claims answered %d, want 200 — "+
			"it is asked at whatever address the platform reaches the instance on", rec.Code)
	}
}
