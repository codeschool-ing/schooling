package certificate_test

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/certificate"
)

// Every test makes its own school and its own student, and asserts only about
// its own rows: packages run in parallel against one database.

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

func school(t *testing.T, db *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := db.QueryRow(context.Background(),
		`INSERT INTO tenants (slug, name) VALUES ($1, 'Programming') RETURNING id`,
		"cert-"+strings.ReplaceAll(uuid.NewString(), "-", "")[:12]).Scan(&id); err != nil {
		t.Fatalf("seeding a school: %v", err)
	}
	return id
}

func student(t *testing.T, db *pgxpool.Pool) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	if err := db.QueryRow(context.Background(),
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`,
		strings.ReplaceAll(uuid.NewString(), "-", "")[:16]+"@example.tld").Scan(&id); err != nil {
		t.Fatalf("seeding a student: %v", err)
	}
	return id
}

// passedExam seeds a handed-in, passed attempt and answers it the way the exam
// module would.
//
// SQL RATHER THAN internal/exam, because a module may not import another and a
// test that reached across the boundary would be the same coupling with a
// different file name. What is shared is the schema.
func passedExam(t *testing.T, db *pgxpool.Pool, tenantID, accountID uuid.UUID,
	scope certificate.Scope, scopeID string) uuid.UUID {

	t.Helper()
	var id uuid.UUID
	if err := db.QueryRow(context.Background(), `
		INSERT INTO exam_attempts
			(tenant_id, account_id, scope, scope_id, submitted_at, score, of, pass_mark, passed)
		VALUES ($1, $2, $3, $4, now(), 8, 10, 70, true)
		RETURNING id
	`, tenantID, accountID, scope, scopeID).Scan(&id); err != nil {
		t.Fatalf("seeding a passed exam: %v", err)
	}
	return id
}

// the three things a certificate has to be told, as a test controls them.
type facts struct {
	attempt uuid.UUID
	passed  bool
	name    string
	title   string
}

func (f *facts) store(t *testing.T, db *pgxpool.Pool) *certificate.Store {
	t.Helper()
	return certificate.NewStore(db,
		func(context.Context, certificate.Scope, string) (uuid.UUID, bool, error) {
			return f.attempt, f.passed, nil
		},
		func(context.Context, uuid.UUID) (string, error) { return f.name, nil },
		func(context.Context, certificate.Scope, string) (string, error) { return f.title, nil },
	)
}

/* ---------- the ones that matter ---------- */

// THE FIRST ONE.
//
// A certificate is a statement made on a day, and everything it says is
// captured then. A certificate that read its title live would one day name
// something else — the load job rewrites the catalogue on every content deploy
// and prunes whatever the files no longer carry.
func TestACertificateKeepsWhatItSaidWhenTheWorldMovesUnderIt(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	issued, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	// The course is renamed, and then removed from the catalogue entirely.
	f.title = "Something Else"

	found, err := store.Verify(ctx, school, issued.Code)
	if err != nil {
		t.Fatalf("verifying: %v", err)
	}
	if found.Title != "Web Fundamentals" {
		t.Errorf("the certificate now says %q — it read its title live, so a rename in the "+
			"catalogue rewrote what somebody was awarded", found.Title)
	}
	if found.Name != "Ada Lovelace" || found.School != "Programming" {
		t.Errorf("the certificate says %q of %q", found.Name, found.School)
	}
}

// THE SECOND ONE.
//
// Verification takes no account and returns no score. The page asserts that the
// person passed; the mark they passed by is between them and the school, and a
// verification page that published it would be a page that ranks people.
func TestVerificationSaysWhoAndWhatAndNothingElse(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	issued, err := f.store(t, db).Issue(context.Background(), school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	found, err := f.store(t, db).Verify(context.Background(), school, issued.Code)
	if err != nil {
		t.Fatalf("verifying: %v", err)
	}

	// What a stranger receives, encoded. The attempt behind this one scored 8 of
	// 10 at a pass mark of 70, and none of those three numbers may appear.
	body := asJSON(t, found)
	for _, tell := range []string{"score", "pass_mark", "\"8\"", ":8", "attempt", "account"} {
		if strings.Contains(body, tell) {
			t.Errorf("a verified certificate carries %q:\n  %s", tell, body)
		}
	}
}

// THE THIRD ONE.
//
// A code that has been erased and a code that never existed answer the same
// way. Answering differently would say a certificate had once been there, which
// is the fact an erasure removes.
func TestAnErasedCertificateVerifiesLikeOneThatNeverExisted(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	issued, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	// The erasure, as `privacy` performs it: the account goes and everything
	// hanging off it goes by cascade.
	if _, err := db.Exec(ctx, `DELETE FROM accounts WHERE id = $1`, student); err != nil {
		t.Fatalf("erasing: %v", err)
	}

	_, erased := store.Verify(ctx, school, issued.Code)
	_, never := store.Verify(ctx, school, freshCode(t))

	if !errors.Is(erased, certificate.ErrNotFound) {
		t.Errorf("an erased certificate answered %v — a name that was asked to be forgotten is "+
			"still being published", erased)
	}
	if !errors.Is(never, certificate.ErrNotFound) {
		t.Errorf("a code that never existed answered %v", never)
	}
}

/* ---------- issuing ---------- */

// An exam that was not passed does not produce a document, whatever is asked.
func TestNoPassNoCertificate(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)

	f := &facts{passed: false, name: "Ada Lovelace", title: "Web Fundamentals"}
	_, err := f.store(t, db).Issue(context.Background(), school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")

	if !errors.Is(err, certificate.ErrNotPassed) {
		t.Fatalf("a certificate for an exam nobody passed gave %v, want ErrNotPassed", err)
	}
}

// A CERTIFICATE WITH NO NAME ASSERTS NOTHING, so there is no such thing — and
// the refusal is its own error, because the pass stands and the document can be
// collected the moment the student says what to put on it.
func TestACertificateNeedsAName(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "  ", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	if _, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals"); !errors.Is(err, certificate.ErrNoName) {
		t.Fatalf("issuing to an account with no name gave %v, want ErrNoName", err)
	}

	// And it is collected afterwards, which is the whole reason that error is
	// distinct from a refusal.
	f.name = "Ada Lovelace"
	issued, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("collecting afterwards: %v", err)
	}
	if issued.Name != "Ada Lovelace" {
		t.Errorf("the collected certificate says %q", issued.Name)
	}
}

// Passing twice does not produce a second document, and asking twice answers
// the same one — which is what makes it safe to call on every hand-in.
func TestIssuingTwiceAnswersTheSameCertificate(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	first, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}
	again, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing again: %v", err)
	}

	if first.Code != again.Code {
		t.Errorf("a second issue produced a second document: %s and %s", first.Code, again.Code)
	}

	var held int
	if err := db.QueryRow(ctx,
		`SELECT count(*) FROM certificates WHERE tenant_id = $1`, school).Scan(&held); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if held != 1 {
		t.Errorf("%d certificates exist for one passed exam", held)
	}
}

// THE COURSE ISSUES A CERTIFICATE; THE TRACK IS THE FINAL (A-08). They are two
// documents for one student, and the index that stops a second certificate is
// per exam rather than per person — a rule written one field short would let
// the course certificate block the diploma.
func TestACourseCertificateAndATrackFinalAreTwoDocuments(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	course := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")
	track := passedExam(t, db, school, student, certificate.ScopeTrack, "frontend")

	f := &facts{attempt: course, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	first, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing the course certificate: %v", err)
	}

	f.attempt, f.title = track, "Front-end Development"
	final, err := store.Issue(ctx, school, student, "Programming", certificate.ScopeTrack, "frontend")
	if err != nil {
		t.Fatalf("issuing the final: %v", err)
	}

	if first.Code == final.Code {
		t.Fatal("the final is the same document as the course certificate")
	}
	if final.Title != "Front-end Development" || final.Scope != certificate.ScopeTrack {
		t.Errorf("the final says %q of %q", final.Title, final.Scope)
	}

	held, err := store.All(ctx, school, student)
	if err != nil {
		t.Fatalf("listing: %v", err)
	}
	if len(held) != 2 {
		t.Errorf("the student holds %d certificates, want 2", len(held))
	}

	// And each verifies as itself.
	for _, one := range held {
		found, err := store.Verify(ctx, school, one.Code)
		if err != nil {
			t.Errorf("%s did not verify: %v", one.Code, err)
			continue
		}
		if found.ScopeID != one.ScopeID {
			t.Errorf("%s verified as %q, want %q", one.Code, found.ScopeID, one.ScopeID)
		}
	}
}

// A certificate never changes. The trigger is the last line of that, and it is
// checked with SQL this package did not write — which is the only kind that
// will ever break the rule.
func TestACertificateCannotBeEdited(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	issued, err := f.store(t, db).Issue(context.Background(), school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	_, err = db.Exec(context.Background(),
		`UPDATE certificates SET student_name = 'Somebody Else' WHERE code = $1`, issued.Code)
	if err == nil {
		t.Error("a certificate was edited, so what it asserts is whatever the last UPDATE said")
	}
}

// One school's code does not verify at another's address. The link is wrong,
// and saying so is more useful than answering about a school nobody asked
// about.
func TestACodeDoesNotVerifyAtAnotherSchool(t *testing.T) {
	db := testPool(t)
	mine, theirs := school(t, db), school(t, db)
	student := student(t, db)
	attempt := passedExam(t, db, mine, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	issued, err := store.Issue(ctx, mine, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	if _, err := store.Verify(ctx, theirs, issued.Code); !errors.Is(err, certificate.ErrNotFound) {
		t.Errorf("a code verified at another school's address: %v", err)
	}
}

/* ---------- the code itself ---------- */

// A code is read off a document and typed by a person. `I` against `1` and `O`
// against `0` is a support conversation with somebody who has concluded a
// candidate's certificate is fake.
func TestACodeSurvivesBeingReadByAPerson(t *testing.T) {
	db := testPool(t)
	school, student := school(t, db), student(t, db)
	attempt := passedExam(t, db, school, student, certificate.ScopeCourse, "web-fundamentals")

	f := &facts{attempt: attempt, passed: true, name: "Ada Lovelace", title: "Web Fundamentals"}
	store := f.store(t, db)
	ctx := context.Background()

	issued, err := store.Issue(ctx, school, student, "Programming",
		certificate.ScopeCourse, "web-fundamentals")
	if err != nil {
		t.Fatalf("issuing: %v", err)
	}

	// As printed, in lower case, with spaces, and with the digits misread as
	// the letters they look like.
	misread := strings.NewReplacer("0", "O", "1", "I").Replace(certificate.Grouped(issued.Code))
	for _, typed := range []string{
		certificate.Grouped(issued.Code),
		strings.ToLower(certificate.Grouped(issued.Code)),
		" " + strings.ReplaceAll(certificate.Grouped(issued.Code), "-", " ") + " ",
		misread,
	} {
		found, err := store.Verify(ctx, school, typed)
		if err != nil {
			t.Errorf("%q did not verify: %v", typed, err)
			continue
		}
		if found.Code != issued.Code {
			t.Errorf("%q verified a different certificate", typed)
		}
	}

	// And something that is not a code at all is not a query.
	for _, nonsense := range []string{"", "   ", "hello there!", "----"} {
		if _, err := store.Verify(ctx, school, nonsense); !errors.Is(err, certificate.ErrNotFound) {
			t.Errorf("%q gave %v, want ErrNotFound", nonsense, err)
		}
	}
}

// The code is what stands between a stranger and the fact that a named person
// studied a named subject, so it has to be long and it has to be random.
func TestCodesAreLongAndDoNotRepeat(t *testing.T) {
	seen := map[string]bool{}
	for range 500 {
		code, err := certificate.NewCode()
		if err != nil {
			t.Fatalf("making a code: %v", err)
		}
		if len(code) != 16 {
			t.Fatalf("a code is %d characters (%q), want 16 — eighty bits is what ends the "+
				"enumeration argument", len(code), code)
		}
		if seen[code] {
			t.Fatalf("the same code came up twice in five hundred: %q", code)
		}
		seen[code] = true

		for _, r := range code {
			if strings.ContainsRune("ILOU", r) {
				t.Fatalf("the code %q contains %q, which is not in the alphabet chosen to keep "+
					"a person from misreading it", code, r)
			}
		}
	}
}

// asJSON is what actually goes over the wire, which is the only thing worth
// asserting about — a field that is absent from a struct literal but present in
// its encoding is exactly the mistake this catches.
func asJSON(t *testing.T, v any) string {
	t.Helper()
	body, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("encoding: %v", err)
	}
	return string(body)
}

func freshCode(t *testing.T) string {
	t.Helper()
	code, err := certificate.NewCode()
	if err != nil {
		t.Fatalf("making a code: %v", err)
	}
	return code
}
