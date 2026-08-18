package tenant_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/platform/web"
	"github.com/codeschool-ing/schooling/internal/tenant"
)

func TestNormaliseTakesTheAddressApart(t *testing.T) {
	// Each of these is a way the same school arrives looking different.
	for _, c := range []struct{ in, want string }{
		{"code.example.tld", "code.example.tld"},
		{"CODE.Example.TLD", "code.example.tld"},      // host names are case-insensitive
		{"code.example.tld:8080", "code.example.tld"}, // the port, which only local development has
		{"code.example.tld.", "code.example.tld"},     // fully qualified is the same name
		{"  code.example.tld  ", "code.example.tld"},  // whitespace nobody meant to send
		{"[::1]:8080", "::1"},                         // an IPv6 literal keeps its colons
		{"", ""},
	} {
		if got := tenant.Normalise(c.in); got != c.want {
			t.Errorf("Normalise(%q) = %q, want %q", c.in, got, c.want)
		}
	}
}

/* The rest needs a database, because what is being checked is a lookup and a
   refusal, and a fake store would only prove that the fake refuses. */

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

func seed(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	ctx := context.Background()

	if _, err := pool.Exec(ctx, `TRUNCATE tenant_domains, tenants CASCADE`); err != nil {
		t.Fatalf("clearing: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		WITH s AS (
			INSERT INTO tenants (slug, name, accent) VALUES
				('code', 'Programming', '#2F6F4E'),
				('math', 'Mathematics', '#2B5EA8')
			RETURNING id, slug
		)
		INSERT INTO tenant_domains (host, tenant_id)
		SELECT s.slug || '.example.tld', s.id FROM s
	`); err != nil {
		t.Fatalf("seeding: %v", err)
	}
}

// server mounts the one school-scoped route behind the middleware, exactly as
// cmd/api does. Testing the handler without the middleware would prove nothing
// about the thing that matters, which is the resolution.
func server(t *testing.T, pool *pgxpool.Pool) *httptest.Server {
	t.Helper()
	scoped := http.NewServeMux()
	tenant.NewHandler().Routes(scoped)

	mux := http.NewServeMux()
	mux.Handle("/api/v1/", web.Chain(scoped, tenant.Resolve(tenant.NewStore(pool))))

	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv
}

func get(t *testing.T, srv *httptest.Server, host string) (int, map[string]any) {
	t.Helper()
	req, err := http.NewRequest(http.MethodGet, srv.URL+"/api/v1/school", nil)
	if err != nil {
		t.Fatalf("building the request: %v", err)
	}
	// The Host header is the whole input under test, so it is set rather than
	// left to whatever the test server's address happens to be.
	req.Host = host

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("GET %s: %v", host, err)
	}
	defer resp.Body.Close() //nolint:errcheck // the body is decoded below; closing it cannot fail usefully

	var body map[string]any
	_ = json.NewDecoder(resp.Body).Decode(&body)
	return resp.StatusCode, body
}

func TestTheHostChoosesTheSchool(t *testing.T) {
	pool := testPool(t)
	seed(t, pool)
	srv := server(t, pool)

	status, body := get(t, srv, "code.example.tld")
	if status != http.StatusOK {
		t.Fatalf("status %d, want 200", status)
	}
	if body["slug"] != "code" || body["name"] != "Programming" {
		t.Errorf("got %v, want the programming school", body)
	}

	status, body = get(t, srv, "math.example.tld")
	if status != http.StatusOK {
		t.Fatalf("status %d, want 200", status)
	}
	if body["slug"] != "math" {
		t.Errorf("got %v, want the mathematics school", body)
	}
}

// THE ONE THAT MATTERS.
//
// An address no school claims must be a 404, and must never fall through to
// whichever school happens to be first. That fallback is the convenience that
// works until there are two schools and then serves one school's catalogue at
// another's address — with no error, no log and no symptom. Every
// school-scoped query written after this rests on it refusing.
func TestAnUnknownHostIsRefusedAndNeverDefaults(t *testing.T) {
	pool := testPool(t)
	seed(t, pool)
	srv := server(t, pool)

	for _, host := range []string{
		"nobody.example.tld",
		"example.tld",      // the platform's own address is not a school
		"code.example.com", // right label, wrong domain
		"code",             // a label with no domain at all
		"",
	} {
		status, body := get(t, srv, host)
		if status != http.StatusNotFound {
			t.Errorf("GET with Host %q answered %d, want 404 — a school was resolved for an "+
				"address that claims none: %v", host, status, body)
		}
		if _, leaked := body["slug"]; leaked {
			t.Errorf("GET with Host %q leaked a school: %v", host, body)
		}
	}
}

func TestTheHostIsNormalisedBeforeItIsLookedUp(t *testing.T) {
	pool := testPool(t)
	seed(t, pool)
	srv := server(t, pool)

	// The table stores the normalised form; these must still find it.
	for _, host := range []string{"CODE.example.tld", "code.example.tld:8080", "code.example.tld."} {
		status, body := get(t, srv, host)
		if status != http.StatusOK || body["slug"] != "code" {
			t.Errorf("GET with Host %q answered %d %v, want the programming school", host, status, body)
		}
	}
}
