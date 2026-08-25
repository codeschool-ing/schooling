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

	slug := strings.TrimSuffix(at.code, ".example.tld")
	if _, err := pool.Exec(context.Background(),
		`UPDATE tenants SET site = $2 WHERE slug = $1`,
		slug, "https://codeschool.ing"); err != nil {
		t.Fatalf("giving the school an address: %v", err)
	}

	/* THE PRICE IS A ROW AND NOT A COLUMN (K-14), so this seeds one. It used to
	   be part of the `UPDATE` above, which is exactly the shape the price stopped
	   having: a value that could be overwritten is a value that cannot explain an
	   invoice a year later. */
	if _, err := pool.Exec(context.Background(), `
		INSERT INTO school_prices (tenant_id, cents, currency)
		SELECT id, $2, $3 FROM tenants WHERE slug = $1
	`, slug, 49000, "BRL"); err != nil {
		t.Fatalf("giving the school a price: %v", err)
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

/* ---------- a price is a row (K-14) ---------- */

/*
THE THING THIS TABLE EXISTS FOR: THE OLD PRICE IS STILL THERE.

A column would answer "what does it cost" and nothing else. The series answers
"what did it cost in March", which is the question an invoice raises in November
— and it is the question the previous shape could not be asked, because setting
the new price destroyed the old one.
*/
func TestASchoolsOldPriceSurvivesTheNewOne(t *testing.T) {
	pool := testPool(t)
	store := tenant.NewStore(pool)
	ctx := context.Background()
	school := aSchoolRow(t, pool)

	if _, _, err := store.SetPrice(ctx, school, 49000, "BRL"); err != nil {
		t.Fatalf("setting the first price: %v", err)
	}
	was, wasCurrency, err := store.SetPrice(ctx, school, 59000, "BRL")
	if err != nil {
		t.Fatalf("raising the price: %v", err)
	}
	if was != 49000 || wasCurrency != "BRL" {
		t.Errorf("the raise answered %d %q as what it replaced", was, wasCurrency)
	}

	series, err := store.Prices(ctx, school)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 2 {
		t.Fatalf("two prices were set and the series holds %d", len(series))
	}
	if series[0].Cents != 59000 {
		t.Errorf("the newest row is %d and should be the one in force", series[0].Cents)
	}
	if series[1].Cents != 49000 {
		t.Errorf("the price that was replaced is gone: %+v", series)
	}
}

// AND THE DATABASE REFUSES AN EDIT, which is what makes the sentence above a
// guarantee rather than a habit. Every other append-only table here carries the
// same trigger, and a price that could be updated would explain nothing.
func TestAPriceCannotBeEditedOrDeleted(t *testing.T) {
	pool := testPool(t)
	store := tenant.NewStore(pool)
	ctx := context.Background()
	school := aSchoolRow(t, pool)

	if _, _, err := store.SetPrice(ctx, school, 49000, "BRL"); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Exec(ctx,
		`UPDATE school_prices SET cents = 100 WHERE tenant_id = $1`, school); err == nil {
		t.Error("a price was edited — the offer is then as forgeable as the column was")
	}
	if _, err := pool.Exec(ctx,
		`DELETE FROM school_prices WHERE tenant_id = $1`, school); err == nil {
		t.Error("a price was deleted")
	}
}

// A SCHOOL WITH NO PRICE IS A SCHOOL, not a school priced at zero. The column
// used zero for both, which made a free school and an undecided one the same
// number — and one of those is a decision somebody made.
func TestASchoolWithNoPriceHasNoOffer(t *testing.T) {
	pool := testPool(t)
	store := tenant.NewStore(pool)
	school := aSchoolRow(t, pool)

	series, err := store.Prices(context.Background(), school)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 0 {
		t.Errorf("a school nobody has priced has %d prices", len(series))
	}
}

// WHAT IS IN FORCE IS THE NEWEST ROW WHOSE DATE HAS PASSED. A row dated ahead is
// already representable — nothing writes one today — and it must not be the
// answer until its day arrives, or announcing a rise would apply it.
func TestAPriceDatedAheadIsNotYetTheOffer(t *testing.T) {
	pool := testPool(t)
	store := tenant.NewStore(pool)
	ctx := context.Background()
	school := aSchoolRow(t, pool)

	if _, _, err := store.SetPrice(ctx, school, 49000, "BRL"); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Exec(ctx, `
		INSERT INTO school_prices (tenant_id, cents, currency, effective_from)
		VALUES ($1, 59000, 'BRL', now() + interval '30 days')
	`, school); err != nil {
		t.Fatalf("dating a price ahead: %v", err)
	}

	// `SetPrice` answers what is in force, which is the older row.
	was, _, err := store.SetPrice(ctx, school, 51000, "BRL")
	if err != nil {
		t.Fatal(err)
	}
	if was != 49000 {
		t.Errorf("the price in force answered %d — a row dated ahead was applied early", was)
	}
}

// NEITHER HALF OF A PRICE IS ACCEPTED ALONE. Both refusals are the caller's to
// fix and both say which half was wrong, because a constraint violation is true
// and is not a sentence a console can show anybody.
func TestAPriceIsANumberAndACurrency(t *testing.T) {
	pool := testPool(t)
	store := tenant.NewStore(pool)
	ctx := context.Background()
	school := aSchoolRow(t, pool)

	for _, bad := range []struct {
		cents    int
		currency string
	}{
		{0, "BRL"}, {-1, "BRL"}, {49000, ""}, {49000, "brl"}, {49000, "REAIS"},
	} {
		if _, _, err := store.SetPrice(ctx, school, bad.cents, bad.currency); !errors.Is(
			err, tenant.ErrNotAPrice) {
			t.Errorf("%d %q answered %v", bad.cents, bad.currency, err)
		}
	}
}

// A price against a school nobody has is a 404's worth of error rather than a
// foreign key violation — which is true and is not something to put in front of
// a person.
func TestPricingASchoolThatIsNotThereSaysSo(t *testing.T) {
	store := tenant.NewStore(testPool(t))

	_, _, err := store.SetPrice(context.Background(), uuid.New(), 49000, "BRL")
	if !errors.Is(err, tenant.ErrNoSchool) {
		t.Errorf("pricing a school nobody has answered %v", err)
	}
}

// A school row to hang prices on. No host and no catalogue: what is under test
// is the series, and everything else about a school is somebody else's test.
func aSchoolRow(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	slug := "price-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:10]
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

/* ---------- which of a school's addresses a link gets ---------- */

/*
THE OLDEST ADDRESS, WHICH IS WHAT THE COMMENT ALWAYS SAID.

	`HostOf` builds the link an operator follows to view as a student, and a
	school may answer at several addresses while one is being moved to. The rule
	written beside it has always been "the oldest is the one most likely to be
	the one people already use" — and the query sorted them ALPHABETICALLY,
	which is a different answer the moment a school has two.

	NOTHING NOTICED BECAUSE NO SCHOOL HAD TWO. The first one that did has its own
	`code.<domain>` and the service's `schooling-….run.app`, where alphabetical
	order happens to give the right answer. This is the case that does not: the
	custom address is added first and sorts LAST, so a query ordering by name
	hands back the raw Cloud Run URL — which works, serves the right school, and
	is an address nobody should be given.
*/
func TestALinkGetsTheOldestAddressAndNotTheFirstAlphabetically(t *testing.T) {
	pool := testPool(t)
	id := aSchoolRow(t, pool)
	ctx := context.Background()

	// The one people use, added first and sorting last.
	if _, err := pool.Exec(ctx,
		`INSERT INTO tenant_domains (host, tenant_id) VALUES ($1, $2)`,
		"zoology."+strings.ReplaceAll(uuid.NewString(), "-", "")[:8]+".example.tld", id); err != nil {
		t.Fatalf("seeding the address people use: %v", err)
	}

	// The platform's own, added later and sorting first.
	later := "aaa-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:8] + ".run.app"
	if _, err := pool.Exec(ctx, `
		INSERT INTO tenant_domains (host, tenant_id, created_at)
		VALUES ($1, $2, now() + interval '1 minute')
	`, later, id); err != nil {
		t.Fatalf("seeding the address nobody types: %v", err)
	}

	host, err := tenant.NewStore(pool).HostOf(ctx, id)
	if err != nil {
		t.Fatalf("reading a school's address: %v", err)
	}
	if host == later {
		t.Error("the link points at the address added later, which is what ordering by " +
			"name does — an operator following it lands on a URL nobody should be handed")
	}
	if !strings.HasPrefix(host, "zoology.") {
		t.Errorf("the link points at %q, and the oldest address is the zoology one", host)
	}
}

// TWO ADDRESSES WRITTEN AT THE SAME INSTANT STILL GIVE ONE ANSWER. `created_at`
// alone would let either row win, and a link that changes between refreshes is
// worse than a link that is arguably the wrong one — the tie-break is what makes
// it a rule rather than a coin.
func TestASchoolWithTwoAddressesAtOnceAnswersTheSameEveryTime(t *testing.T) {
	pool := testPool(t)
	id := aSchoolRow(t, pool)
	ctx := context.Background()

	stamp := strings.ReplaceAll(uuid.NewString(), "-", "")[:8]
	if _, err := pool.Exec(ctx, `
		INSERT INTO tenant_domains (host, tenant_id, created_at) VALUES
			($1, $3, now()), ($2, $3, now())
	`, "b-"+stamp+".example.tld", "a-"+stamp+".example.tld", id); err != nil {
		t.Fatalf("seeding two addresses at one instant: %v", err)
	}

	store := tenant.NewStore(pool)
	first, err := store.HostOf(ctx, id)
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 5; i++ {
		again, err := store.HostOf(ctx, id)
		if err != nil {
			t.Fatal(err)
		}
		if again != first {
			t.Fatalf("the same school answered %q and then %q — a link that changes "+
				"between refreshes is not a link", first, again)
		}
	}
}

// A SCHOOL WITH NO ADDRESS IS A REAL STATE, not a failure to look one up: a
// school row exists before its domain is mapped, and the caller has to be able
// to tell that from a database that is unwell.
func TestASchoolWithNoAddressSaysSoRatherThanFailing(t *testing.T) {
	pool := testPool(t)

	_, err := tenant.NewStore(pool).HostOf(context.Background(), aSchoolRow(t, pool))
	if !errors.Is(err, tenant.ErrUnknownHost) {
		t.Errorf("a school with no address answered %v", err)
	}
}
