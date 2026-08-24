package tenant_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
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

// schools is the pair this file works with, seeded under names nothing else is
// using.
//
// NO TRUNCATE, AND NO FIXED SLUGS. `go test` runs packages in parallel against
// one database, so a test that clears a shared table is not tidying up — it is
// deleting another package's rows mid-run, and two packages seeding the same
// slug collide on the unique index. That reached CI as a duplicate key from two
// packages at once, and it had passed locally on timing alone, which is worse
// than failing.
type schools struct{ code, math string } // their hosts

func seed(t *testing.T, pool *pgxpool.Pool) schools {
	t.Helper()
	ctx := context.Background()

	run := strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	code, math := "code-"+run, "math-"+run

	if _, err := pool.Exec(ctx, `
		WITH s AS (
			INSERT INTO tenants (slug, name, accent) VALUES
				($1, 'Programming', '#2F6F4E'),
				($2, 'Mathematics', '#2B5EA8')
			RETURNING id, slug
		)
		INSERT INTO tenant_domains (host, tenant_id)
		SELECT s.slug || '.example.tld', s.id FROM s
	`, code, math); err != nil {
		t.Fatalf("seeding: %v", err)
	}

	return schools{code: code + ".example.tld", math: math + ".example.tld"}
}

// server mounts the one school-scoped route behind the middleware, exactly as
// cmd/api does. Testing the handler without the middleware would prove nothing
// about the thing that matters, which is the resolution.
func server(t *testing.T, pool *pgxpool.Pool) *httptest.Server {
	t.Helper()
	scoped := http.NewServeMux()
	tenant.NewHandler(70).Routes(scoped)

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
	at := seed(t, pool)
	srv := server(t, pool)

	status, body := get(t, srv, at.code)
	if status != http.StatusOK {
		t.Fatalf("status %d, want 200", status)
	}
	if body["name"] != "Programming" {
		t.Errorf("got %v, want the programming school", body)
	}

	status, body = get(t, srv, at.math)
	if status != http.StatusOK {
		t.Fatalf("status %d, want 200", status)
	}
	if body["name"] != "Mathematics" {
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
	at := seed(t, pool)
	srv := server(t, pool)

	// The seeded school, moved to a domain nobody claims: the right label at
	// the wrong domain must miss, and it is the case a careless LIKE would pass.
	elsewhere := strings.TrimSuffix(at.code, ".example.tld") + ".example.com"

	for _, host := range []string{
		"nobody.example.tld",
		"example.tld", // the platform's own address is not a school
		elsewhere,
		"code", // a label with no domain at all
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

// A SCHOOL IS MORE THAN A NAME AND A COLOUR, and the parts that were not served
// were the parts written into the interface instead.
//
// The account menu linked to codeschool.ing and the plan screen quoted
// R$ 490,00 for every school, because both were constants in files copied from
// the vitrine. Neither looked wrong on the school they were copied from, which
// is why they survived — so the school says what its address is and what it
// charges, and the interface draws what it is told.
//
// EACH ONE IS ABSENT RATHER THAN EMPTY when it is not set. A school with no
// site of its own must leave the link out, and a school with no price must say
// nothing about one rather than offer zero.
func TestASchoolCarriesItsOwnAddressAndItsOwnPrice(t *testing.T) {
	pool := testPool(t)
	at := seed(t, pool)
	srv := server(t, pool)

	if _, err := pool.Exec(context.Background(), `
		UPDATE tenants SET site = $2, plan_price_cents = $3, plan_currency = $4
		WHERE slug = $1
	`, strings.TrimSuffix(at.code, ".example.tld"),
		"https://codeschool.ing", 49000, "BRL"); err != nil {
		t.Fatalf("giving the school an address and a price: %v", err)
	}

	status, body := get(t, srv, at.code)
	if status != http.StatusOK {
		t.Fatalf("status %d, want 200", status)
	}
	if body["site"] != "https://codeschool.ing" {
		t.Errorf("the school's own address answered %v", body["site"])
	}
	if body["planPriceCents"] != float64(49000) || body["planCurrency"] != "BRL" {
		t.Errorf("the price answered %v %v", body["planPriceCents"], body["planCurrency"])
	}

	// The other school was seeded with neither, and must say so by omission.
	status, body = get(t, srv, at.math)
	if status != http.StatusOK {
		t.Fatalf("status %d, want 200", status)
	}
	for _, absent := range []string{"site", "planPriceCents", "planCurrency"} {
		if v, present := body[absent]; present {
			t.Errorf("a school that set no %s answered %v — the interface cannot tell "+
				"\"none\" from \"zero\"", absent, v)
		}
	}
}

func TestTheHostIsNormalisedBeforeItIsLookedUp(t *testing.T) {
	pool := testPool(t)
	at := seed(t, pool)
	srv := server(t, pool)

	// The table stores the normalised form; these must still find it.
	for _, host := range []string{
		strings.ToUpper(at.code), // host names are case-insensitive
		at.code + ":8080",        // the port, which only local development has
		at.code + ".",            // fully qualified is the same name
	} {
		status, body := get(t, srv, host)
		if status != http.StatusOK || body["name"] != "Programming" {
			t.Errorf("GET with Host %q answered %d %v, want the programming school", host, status, body)
		}
	}
}

// SETTING A COLOUR ANSWERS WITH THE ONE IT REPLACED.
//
// The value an audit entry quotes as "before" comes out of the write itself, so
// it is the value this write actually replaced rather than one read a moment
// earlier and possibly already gone. The self-join in the statement is what
// makes that true, and `RETURNING` alone would quietly answer with the new
// colour instead — which reads perfectly and is wrong.
func TestSettingAnAccentAnswersWithWhatWasThere(t *testing.T) {
	pool := testPool(t)
	seeded := seed(t, pool)
	store := tenant.NewStore(pool)

	ctx := context.Background()
	school, err := store.ByHost(ctx, seeded.code)
	if err != nil {
		t.Fatalf("reading the school: %v", err)
	}
	if school.Accent != "#2F6F4E" {
		t.Fatalf("the fixture's colour is %q", school.Accent)
	}

	was, err := store.SetAccent(ctx, school.ID, "#10a06a")
	if err != nil {
		t.Fatalf("setting the accent: %v", err)
	}
	if was != "#2F6F4E" {
		t.Errorf("the write answered %q, and the colour it replaced was %q", was, school.Accent)
	}

	after, err := store.ByHost(ctx, seeded.code)
	if err != nil {
		t.Fatalf("reading the school back: %v", err)
	}
	if after.Accent != "#10a06a" {
		t.Errorf("the school is wearing %q", after.Accent)
	}

	// AND THE OTHER SCHOOL IS UNTOUCHED. One statement with a self-join is one
	// `WHERE` away from being every row, which is the shape of mistake that is
	// invisible with a single school in the fixture.
	other, err := store.ByHost(ctx, seeded.math)
	if err != nil {
		t.Fatalf("reading the other school: %v", err)
	}
	if other.Accent != "#2B5EA8" {
		t.Errorf("the other school's colour became %q", other.Accent)
	}
}

// AND AN ID NO SCHOOL HAS IS A REFUSAL RATHER THAN A SILENT NOTHING.
//
// An UPDATE that matches no row is not an error in SQL, so a caller that did
// not ask would record a change to a school that does not exist and answer 200.
func TestSettingTheAccentOfNoSchool(t *testing.T) {
	pool := testPool(t)
	seed(t, pool)

	_, err := tenant.NewStore(pool).SetAccent(context.Background(), uuid.New(), "#10a06a")
	if !errors.Is(err, tenant.ErrNoSchool) {
		t.Errorf("setting the colour of no school answered %v, want ErrNoSchool", err)
	}
}
