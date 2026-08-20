package privacy_test

import (
	"context"
	"os"
	"sort"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/privacy"
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

// THE ONE THAT MATTERS, and it is the mechanism rather than a check.
//
// The obligation is to export and to erase a person's data. Written as two
// functions somebody keeps up to date, it holds for as long as everybody
// remembers — and the failure is silent, because a table nobody wired in
// produces no error, only an export that is quietly incomplete.
//
// This reads the LIVE SCHEMA and compares it against the registry. A table that
// exists and is not registered fails here; a registered table that no longer
// exists fails here. Adding a table without deciding what it holds stops being
// possible rather than being discouraged.
func TestEveryTableInTheDatabaseIsClassified(t *testing.T) {
	pool := testPool(t)

	rows, err := pool.Query(context.Background(), `
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
		ORDER BY table_name
	`)
	if err != nil {
		t.Fatalf("reading the schema: %v", err)
	}
	defer rows.Close()

	var inDatabase []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			t.Fatalf("reading the schema: %v", err)
		}
		inDatabase = append(inDatabase, name)
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("reading the schema: %v", err)
	}
	if len(inDatabase) == 0 {
		t.Fatal("no tables found — the migrations have not run against this database")
	}

	registered := map[string]bool{}
	for _, entry := range privacy.Registry {
		registered[entry.Name] = true
	}

	for _, name := range inDatabase {
		if !registered[name] {
			t.Errorf("the table %q is in the database and not in the registry — decide what it "+
				"holds about a person and how the export and erase paths reach it. Leaving it "+
				"unclassified is a legal defect, not a backlog item", name)
		}
	}

	present := map[string]bool{}
	for _, name := range inDatabase {
		present[name] = true
	}
	for _, entry := range privacy.Registry {
		if !present[entry.Name] {
			t.Errorf("the registry lists %q and the database has no such table — a registry "+
				"describing a schema that has moved on is worse than none", entry.Name)
		}
	}
}

// The classification is written twice on purpose — as a comment on the table,
// where somebody reading the schema sees it, and in the registry, where the
// code uses it. Two copies only work if something compares them.
func TestTheSchemaAndTheRegistryAgreeOnWhatEachTableHolds(t *testing.T) {
	pool := testPool(t)

	rows, err := pool.Query(context.Background(), `
		SELECT c.relname, obj_description(c.oid, 'pg_class')
		FROM pg_class c
		JOIN pg_namespace n ON n.oid = c.relnamespace
		WHERE n.nspname = 'public' AND c.relkind = 'r'
	`)
	if err != nil {
		t.Fatalf("reading the table comments: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var name string
		var comment *string
		if err := rows.Scan(&name, &comment); err != nil {
			t.Fatalf("reading the table comments: %v", err)
		}

		entry, known := privacy.ByName(name)
		if !known {
			continue // the test above reports this, and better
		}
		if comment == nil {
			t.Errorf("the table %q carries no classification comment — the schema should say "+
				"what it holds to somebody reading it with psql and no Go", name)
			continue
		}

		want := "personal-data: " + string(entry.Holds)
		if *comment != want {
			t.Errorf("the table %q says %q and the registry says %q — one of them is wrong, "+
				"and the one that is wrong decides what an export contains", name, *comment, want)
		}
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("reading the table comments: %v", err)
	}
}

// A table the registry says holds a student's data has to appear in the export
// — including when it has no rows for them. An export that omits an empty table
// cannot be told from one that forgot it.
func TestTheExportCoversEveryTableThatReachesAStudent(t *testing.T) {
	pool := testPool(t)

	// An account nothing has ever written a row for: the export must still name
	// every table, with nothing in it.
	export, err := privacy.NewStore(pool).Export(context.Background(), uuid.New())
	if err != nil {
		t.Fatalf("exporting: %v", err)
	}

	for _, name := range privacy.AccountTables() {
		if _, ok := export[name]; !ok {
			t.Errorf("the registry says %q holds a student's data and the export has no key "+
				"for it — the obligation is not met by a function that compiles", name)
		}
	}

	var covered, expected []string
	for name := range export {
		covered = append(covered, name)
	}
	expected = privacy.AccountTables()
	sort.Strings(covered)
	sort.Strings(expected)
	if len(covered) != len(expected) {
		t.Errorf("the export covers %v and the registry expects %v", covered, expected)
	}
}

func TestTheExportCarriesWhatIsActuallyThere(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	account, tenant := seedAccount(t, pool), seedSchool(t, pool)
	visitor := seedVisitor(t, pool, account)
	seedEvent(t, pool, tenant, account, visitor)
	seedReview(t, pool, tenant, account)

	export, err := privacy.NewStore(pool).Export(ctx, account)
	if err != nil {
		t.Fatalf("exporting: %v", err)
	}

	for table, want := range map[string]int{
		"visitors": 1, "account_visitors": 1, "events": 1, "practice_review": 1,
	} {
		if got := len(export[table]); got != want {
			t.Errorf("the export has %d rows of %s, want %d", got, table, want)
		}
	}
}

// An export is handed to the person it is about, and one of the tables it
// covers holds a password hash.
//
// THE HASH MUST NOT BE IN IT. Not because the person may not have their own
// hash — because an export is a file that gets forwarded, stored in a downloads
// folder and attached to a support thread, and a hash of a password somebody
// reuses elsewhere is the one thing in this database worth stealing. The export
// names its columns for exactly this, and this is what holds it to that.
func TestTheExportNeverCarriesAPasswordHash(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	account := seedAccount(t, pool)

	export, err := privacy.NewStore(pool).Export(ctx, account)
	if err != nil {
		t.Fatalf("exporting: %v", err)
	}

	rows := export["account_credentials"]
	if len(rows) == 0 {
		t.Fatal("the export carries no credential row at all, so this proves nothing")
	}
	for _, row := range rows {
		if _, leaked := row["secret"]; leaked {
			t.Error("the export carries the password hash — a file that gets forwarded, left in " +
				"a downloads folder and attached to a support thread now carries the one thing " +
				"in this database worth stealing")
		}
		if _, ok := row["kind"]; !ok {
			t.Error("the export does not say which kind of credential it is, which is the part " +
				"the person actually asked about")
		}
	}
}

// And the other thing in this database that must not leave it: the answer keys.
//
// An exam attempt keeps the questions it asked, WITH their answers, because a
// paper is marked against what the student was actually asked rather than
// against a catalogue that moves underneath them. That makes `exam_answers` the
// second table where an export written with `SELECT *` would hand somebody
// something they should not have — and here it would be handed to a student
// who is one HTTP request away from sitting the exam again.
func TestTheExportNeverCarriesAnAnswerKey(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	account, tenant := seedAccount(t, pool), seedSchool(t, pool)
	seedAttempt(t, pool, tenant, account)

	export, err := privacy.NewStore(pool).Export(ctx, account)
	if err != nil {
		t.Fatalf("exporting: %v", err)
	}

	rows := export["exam_answers"]
	if len(rows) == 0 {
		t.Fatal("the export carries no exam answer at all, so this proves nothing")
	}
	for _, row := range rows {
		for _, column := range []string{"sealed", "shown"} {
			if _, leaked := row[column]; leaked {
				t.Errorf("the export carries %q — the questions and their answer keys, handed to "+
					"somebody who can sit the exam again in one request", column)
			}
		}
		if _, ok := row["correct"]; !ok {
			t.Error("the export does not say whether the answer was right, which is the part the " +
				"person actually asked about")
		}
	}

	// And the attempt itself is there, since that is what they asked for.
	if len(export["exam_attempts"]) != 1 {
		t.Errorf("the export has %d exam attempts, want 1", len(export["exam_attempts"]))
	}
}

// THE SECOND ONE THAT MATTERS.
//
// Erasure works by deleting what gives the identifiers a meaning, not by
// rewriting history — which is what lets the append-only triggers be absolute.
// Afterwards the events and reviews are still there, still countable, and join
// to nobody.
func TestErasureSeversThePersonAndLeavesTheStatistics(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	account, tenant := seedAccount(t, pool), seedSchool(t, pool)
	visitorID := seedVisitor(t, pool, account)
	seedEvent(t, pool, tenant, account, visitorID)
	seedReview(t, pool, tenant, account)
	seedAttempt(t, pool, tenant, account)

	if err := privacy.NewStore(pool).Erase(ctx, account); err != nil {
		t.Fatalf("erasing: %v", err)
	}

	// Gone: everything that turns an identifier back into a person.
	for _, q := range []struct {
		what string
		sql  string
		arg  any
	}{
		{"accounts", `SELECT count(*) FROM accounts WHERE id = $1`, account},
		{"account_credentials", `SELECT count(*) FROM account_credentials WHERE account_id = $1`, account},
		{"sessions", `SELECT count(*) FROM sessions WHERE account_id = $1`, account},
		{"visitors", `SELECT count(*) FROM visitors WHERE id = $1`, visitorID},
		{"account_visitors", `SELECT count(*) FROM account_visitors WHERE account_id = $1`, account},
		// An exam attempt answers "what has this person done" and goes with
		// them. What survives is one event per question, which is what item
		// analysis reads — so erasing somebody does not take the evidence about
		// a bad question along with them.
		{"exam_attempts", `SELECT count(*) FROM exam_attempts WHERE account_id = $1`, account},
		{"exam_answers", `
			SELECT count(*) FROM exam_answers q
			JOIN exam_attempts a ON a.id = q.attempt_id WHERE a.account_id = $1`, account},
		// A certificate carries a name and is readable by anybody with its
		// code. Keeping one would mean publishing the name of somebody who
		// asked to be forgotten.
		{"certificates", `SELECT count(*) FROM certificates WHERE account_id = $1`, account},
	} {
		var count int
		if err := pool.QueryRow(ctx, q.sql, q.arg).Scan(&count); err != nil {
			t.Fatalf("counting %s: %v", q.what, err)
		}
		if count != 0 {
			t.Errorf("%d rows left in %s after an erasure", count, q.what)
		}
	}

	// Still there: the history, which is nobody's now.
	for _, q := range []struct {
		what string
		sql  string
	}{
		{"events", `SELECT count(*) FROM events WHERE account_id = $1`},
		{"practice_review", `SELECT count(*) FROM practice_review WHERE account_id = $1`},
	} {
		var count int
		if err := pool.QueryRow(ctx, q.sql, account).Scan(&count); err != nil {
			t.Fatalf("counting %s: %v", q.what, err)
		}
		if count != 1 {
			t.Errorf("%d rows left in %s — the statistics were destroyed along with the person, "+
				"which is not what erasure asks for", count, q.what)
		}
	}

	// And the export is empty afterwards, which is the check that the two paths
	// agree about what "reached" means.
	export, err := privacy.NewStore(pool).Export(ctx, account)
	if err != nil {
		t.Fatalf("exporting after erasure: %v", err)
	}
	for table, rows := range export {
		if table == "events" || table == "practice_review" {
			// Reachable by account_id, which is now an orphan identifier. It is
			// deliberately still exportable — the person can still ask for it
			// until they ask to be erased, and after that nothing links it to
			// them. What matters is that it is not reachable through a visitor.
			continue
		}
		if len(rows) != 0 {
			t.Errorf("the export still returns %d rows of %s after an erasure", len(rows), table)
		}
	}
}

/* ---------- seeding ---------- */

// NO TRUNCATE ANYWHERE IN THIS FILE, and that is what the CI failure this
// replaces was about: `go test` runs packages in parallel against one database,
// so clearing a shared table deletes another package's rows mid-run, and a
// fixed slug collides on the unique index. Everything below is scoped to the
// account and school it made — which is what these tests meant all along, since
// the subject of every one of them is one person.
// seedAccount makes a real account row.
//
// BY SQL AND NOT BY internal/identity, because a module may not import another
// module and a test that reaches across the boundary is the same coupling with
// a different file name. What this needs is the schema, which is shared.
func seedAccount(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	email := strings.ReplaceAll(uuid.NewString(), "-", "")[:16] + "@example.tld"

	var id uuid.UUID
	if err := pool.QueryRow(context.Background(), `
		INSERT INTO accounts (email, name) VALUES ($1, 'A student') RETURNING id
	`, email).Scan(&id); err != nil {
		t.Fatalf("seeding an account: %v", err)
	}
	if _, err := pool.Exec(context.Background(), `
		INSERT INTO account_credentials (account_id, kind, secret)
		VALUES ($1, 'password', '$argon2id$v=19$m=19456,t=2,p=1$c2FsdHlzYWx0eXNhbHQ$aGFzaGhhc2hoYXNoaGFzaGhhc2hoYXNoaGFzaGhhcw')
	`, id); err != nil {
		t.Fatalf("seeding a credential: %v", err)
	}
	return id
}

func seedSchool(t *testing.T, pool *pgxpool.Pool) uuid.UUID {
	t.Helper()
	slug := "code-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12]
	var id uuid.UUID
	if err := pool.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`, slug).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

// seedAttempt is one handed-in exam with one question on it, answer key and
// all — because what this proves is that the key does not come back out. It
// also issues the certificate that exam earned, which is the row carrying a
// person's NAME where anybody with a code can read it.
func seedAttempt(t *testing.T, pool *pgxpool.Pool, tenant, account uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	var attempt uuid.UUID
	if err := pool.QueryRow(ctx, `
		INSERT INTO exam_attempts
			(tenant_id, account_id, scope, scope_id, submitted_at, score, of, pass_mark, passed)
		VALUES ($1, $2, 'course', 'web-fundamentals', now(), 1, 1, 70, true)
		RETURNING id
	`, tenant, account).Scan(&attempt); err != nil {
		t.Fatalf("seeding an attempt: %v", err)
	}

	if _, err := pool.Exec(ctx, `
		INSERT INTO exam_answers
			(attempt_id, position, exercise_id, exercise_version, type, shown, perm, sealed,
			 answer, answered_at, correct)
		VALUES ($1, 0, 'ex-spr8rdb4', 1, 'quiz',
			'{"choices":[{"text":"one"},{"text":"two"}]}', '{0,1}',
			'{"choices":[{"text":"one","correct":true},{"text":"two","correct":false}]}',
			'{"chose":[0]}', now(), true)
	`, attempt); err != nil {
		t.Fatalf("seeding an answer: %v", err)
	}

	if _, err := pool.Exec(ctx, `
		INSERT INTO certificates
			(tenant_id, account_id, code, scope, scope_id, attempt_id,
			 student_name, title, school_name)
		VALUES ($1, $2, $3, 'course', 'web-fundamentals', $4,
			'A Student', 'Web Fundamentals', 'Programming')
	`, tenant, account, strings.ToUpper(strings.ReplaceAll(uuid.NewString(), "-", ""))[:16],
		attempt); err != nil {
		t.Fatalf("seeding a certificate: %v", err)
	}
}

func seedVisitor(t *testing.T, pool *pgxpool.Pool, account uuid.UUID) uuid.UUID {
	t.Helper()
	ctx := context.Background()
	var id uuid.UUID
	if err := pool.QueryRow(ctx,
		`INSERT INTO visitors (first_path) VALUES ('/') RETURNING id`).Scan(&id); err != nil {
		t.Fatalf("seeding a visitor: %v", err)
	}
	if _, err := pool.Exec(ctx,
		`INSERT INTO account_visitors (account_id, visitor_id) VALUES ($1, $2)`, account, id); err != nil {
		t.Fatalf("linking a visitor: %v", err)
	}
	return id
}

func seedEvent(t *testing.T, pool *pgxpool.Pool, tenant, account, visitor uuid.UUID) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `
		INSERT INTO events (name, visitor_id, account_id, tenant_id, school_slug, plan, country, locale)
		VALUES ('course.finished', $1, $2, $3, 'code', 'annual', 'BR', 'pt-br')
	`, visitor, account, tenant); err != nil {
		t.Fatalf("seeding an event: %v", err)
	}
}

func seedReview(t *testing.T, pool *pgxpool.Pool, tenant, account uuid.UUID) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `
		INSERT INTO practice_review
			(tenant_id, account_id, exercise_id, exercise_version, correct, quality, elapsed_ms,
			 interval_before, interval_after, ease_before, ease_after,
			 repetition_before, repetition_after)
		VALUES ($1, $2, 'python-lists-3', 1, true, 4, 8200, 1, 6, 2.50, 2.60, 0, 1)
	`, tenant, account); err != nil {
		t.Fatalf("seeding a review: %v", err)
	}
}
