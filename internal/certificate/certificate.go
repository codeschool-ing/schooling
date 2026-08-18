// Package certificate issues the document a student earns, and lets anybody
// check one.
//
// # THE PASS IS THE FACT; THE CERTIFICATE IS THE DOCUMENT
//
// Passing is recorded on the exam attempt and nothing here can change it. This
// package writes down what that pass entitles somebody to say about themselves,
// and everything it writes down is captured at the moment of issue: the name,
// the title, the school. Nothing is read live.
//
// That matters because the catalogue moves. A course can be renamed, and the
// load job prunes anything the files no longer carry (C-01) — a certificate
// that read its title live would one day name something else, or nothing at
// all. It is the same decision as `audit_log.actor_label`, for the same reason:
// a record that reads its own subject from a table that moves is a record that
// quietly stops being true.
//
// # VERIFICATION TAKES NO ACCOUNT
//
// Somebody hiring reads a code off a document and types it in. So the code is
// the only thing between a stranger and the fact that a named person studied a
// named subject, and it is eighty bits from crypto/rand — not a sequence, not
// anything derived from the student, and not short enough to guess.
//
// What comes back is the smallest thing that answers the question: the name,
// what they passed, the school, and the date. NO SCORE. The page asserts that
// the person passed; the mark they passed by is between them and the school,
// and a verification page that published it would be a page that ranks people.
//
// # AND IT GOES WHEN THE PERSON GOES
//
// A certificate carries a name and is readable by anybody with its code, so
// keeping one after an erasure request would mean publishing the name of
// somebody who asked to be forgotten. It cascades with the account, and
// verification answers a deleted certificate exactly as it answers a code that
// never existed — anything else would say one had been there, which is the fact
// being erased.
package certificate

import (
	"context"
	"crypto/rand"
	"encoding/base32"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Scope is what was passed. The course issues a certificate; the track is the
// final (A-08).
type Scope string

const (
	ScopeCourse Scope = "course"
	ScopeTrack  Scope = "track"
)

var (
	// ErrNotPassed is somebody asking for a certificate they have not earned.
	ErrNotPassed = errors.New("certificate: that exam has not been passed")

	// ErrNoName is an account with no name on it.
	//
	// A CERTIFICATE WITH NO NAME ASSERTS NOTHING, so there is no such thing —
	// and this is deliberately a distinct error rather than a refusal, because
	// the pass itself stands and the document can be issued the moment the
	// student says what to put on it.
	ErrNoName = errors.New("certificate: a certificate needs a name to be about somebody")

	// ErrNotFound is a code nobody can verify. It is also what a certificate
	// that has been erased answers, and that is the point of it.
	ErrNotFound = errors.New("certificate: no such certificate")
)

// What this module has to know and may not go and read for itself: the exam is
// another module, so is the catalogue, and so is identity.
type (
	// Passed answers whether this student passed, and on which paper.
	Passed func(ctx context.Context, scope Scope, id string) (attempt uuid.UUID, passed bool, err error)

	// NameOf answers what to put on the document. Empty is a real answer and
	// means the student has not given one.
	NameOf func(ctx context.Context, accountID uuid.UUID) (string, error)

	// TitleOf answers what the course or track is called, today. It is captured
	// rather than kept as a reference for the reason in the package comment.
	TitleOf func(ctx context.Context, scope Scope, id string) (string, error)
)

type Store struct {
	pool   *pgxpool.Pool
	passed Passed
	nameOf NameOf
	title  TitleOf
}

func NewStore(pool *pgxpool.Pool, passed Passed, nameOf NameOf, title TitleOf) *Store {
	return &Store{pool: pool, passed: passed, nameOf: nameOf, title: title}
}

// Certificate is what the student holds.
type Certificate struct {
	Code     string    `json:"code"`
	Scope    Scope     `json:"scope"`
	ScopeID  string    `json:"subject"`
	Title    string    `json:"title"`
	Name     string    `json:"name"`
	School   string    `json:"school"`
	IssuedAt time.Time `json:"issued_at"`
}

// Issue writes a certificate for an exam this student has passed, or answers
// the one they already have.
//
// IT IS IDEMPOTENT AND IT IS SAFE TO CALL ON EVERY PASS. Handing an exam in is
// what calls it, and a student who sits an exam again after passing must not
// collect a second document — the unique index says so, and this reads the
// first one back rather than failing.
func (s *Store) Issue(ctx context.Context, tenantID, accountID uuid.UUID, schoolName string,
	scope Scope, scopeID string) (*Certificate, error) {

	if scope != ScopeCourse && scope != ScopeTrack {
		return nil, fmt.Errorf("%w: %q is not something to be certified in", ErrNotPassed, scope)
	}

	// The one they already have, before anything else is asked of anybody.
	if existing, err := s.Mine(ctx, tenantID, accountID, scope, scopeID); err == nil {
		return existing, nil
	} else if !errors.Is(err, ErrNotFound) {
		return nil, err
	}

	attempt, passed, err := s.passed(ctx, scope, scopeID)
	if err != nil {
		return nil, fmt.Errorf("certificate: asking whether %s %q was passed: %w", scope, scopeID, err)
	}
	if !passed {
		return nil, ErrNotPassed
	}

	name, err := s.nameOf(ctx, accountID)
	if err != nil {
		return nil, fmt.Errorf("certificate: reading a student's name: %w", err)
	}
	if strings.TrimSpace(name) == "" {
		return nil, ErrNoName
	}

	title, err := s.title(ctx, scope, scopeID)
	if err != nil {
		return nil, fmt.Errorf("certificate: reading the title of %s %q: %w", scope, scopeID, err)
	}
	if strings.TrimSpace(title) == "" {
		// A course the catalogue does not have. Issuing a document that names
		// nothing would be worse than not issuing one.
		return nil, fmt.Errorf("%w: %s %q has no title", ErrNotPassed, scope, scopeID)
	}

	code, err := NewCode()
	if err != nil {
		return nil, err
	}

	out := Certificate{
		Code: code, Scope: scope, ScopeID: scopeID,
		Title: strings.TrimSpace(title), Name: strings.TrimSpace(name),
		School: strings.TrimSpace(schoolName),
	}

	err = s.pool.QueryRow(ctx, `
		INSERT INTO certificates
			(tenant_id, account_id, code, scope, scope_id, attempt_id,
			 student_name, title, school_name)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		RETURNING issued_at
	`, tenantID, accountID, out.Code, scope, scopeID, attempt,
		out.Name, out.Title, out.School).Scan(&out.IssuedAt)

	if isUniqueViolation(err) {
		// TWO PASSES AT ONCE, or a second tab. The index caught the second and
		// the first one's certificate is the answer — which is what the index is
		// for, so this is not a failure.
		return s.Mine(ctx, tenantID, accountID, scope, scopeID)
	}
	if err != nil {
		return nil, fmt.Errorf("certificate: issuing: %w", err)
	}
	return &out, nil
}

// Mine answers one student's certificate for one exam.
func (s *Store) Mine(ctx context.Context, tenantID, accountID uuid.UUID,
	scope Scope, scopeID string) (*Certificate, error) {

	var c Certificate
	err := s.pool.QueryRow(ctx, `
		SELECT code, scope, scope_id, title, student_name, school_name, issued_at
		FROM certificates
		WHERE tenant_id = $1 AND account_id = $2 AND scope = $3 AND scope_id = $4
	`, tenantID, accountID, scope, scopeID).Scan(
		&c.Code, &c.Scope, &c.ScopeID, &c.Title, &c.Name, &c.School, &c.IssuedAt)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("certificate: reading a certificate: %w", err)
	}
	return &c, nil
}

// All answers every certificate one student holds in this school.
func (s *Store) All(ctx context.Context, tenantID, accountID uuid.UUID) ([]Certificate, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT code, scope, scope_id, title, student_name, school_name, issued_at
		FROM certificates
		WHERE tenant_id = $1 AND account_id = $2
		ORDER BY issued_at DESC
	`, tenantID, accountID)
	if err != nil {
		return nil, fmt.Errorf("certificate: listing certificates: %w", err)
	}
	defer rows.Close()

	out := []Certificate{}
	for rows.Next() {
		var c Certificate
		if err := rows.Scan(&c.Code, &c.Scope, &c.ScopeID, &c.Title,
			&c.Name, &c.School, &c.IssuedAt); err != nil {
			return nil, fmt.Errorf("certificate: listing certificates: %w", err)
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// Verify is the public half: a code in, and what it certifies out.
//
// IT IS SCOPED TO THE SCHOOL IT IS ASKED ON. The address a certificate is
// verified at is the school's own, so a code belonging to another school is not
// found here — the link is wrong, and saying so is more useful than answering
// about a school the reader did not ask about.
//
// It takes no account, reads no session and returns no score. See the package
// comment for what it deliberately does not say.
func (s *Store) Verify(ctx context.Context, tenantID uuid.UUID, code string) (*Certificate, error) {
	normalised := Normalise(code)
	if normalised == "" {
		return nil, ErrNotFound
	}

	var c Certificate
	err := s.pool.QueryRow(ctx, `
		SELECT code, scope, scope_id, title, student_name, school_name, issued_at
		FROM certificates WHERE code = $1 AND tenant_id = $2
	`, normalised, tenantID).Scan(
		&c.Code, &c.Scope, &c.ScopeID, &c.Title, &c.Name, &c.School, &c.IssuedAt)

	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("certificate: verifying: %w", err)
	}
	return &c, nil
}

/* ---------- the code ---------- */

// The alphabet is Crockford's base32: no I, no L, no O and no U.
//
// A CODE IS READ OFF A DOCUMENT AND TYPED BY A PERSON, which is the whole
// reason not to use the standard alphabet. `I` against `1` and `O` against `0`
// is a support conversation with somebody who is trying to check a candidate's
// certificate and has concluded it is fake. `U` is out of Crockford's alphabet
// for a different reason, and it costs nothing to leave it out.
const alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

var encoding = base32.NewEncoding(alphabet).WithPadding(base32.NoPadding)

// codeBytes is ten, which is eighty bits and sixteen characters.
//
// Enumeration is the attack: a stranger trying codes until one answers learns
// that a named person studied a named subject. Eighty bits ends that argument,
// and sixteen characters is still short enough to print in four groups of four.
const codeBytes = 10

// NewCode answers a fresh verification code.
func NewCode() (string, error) {
	var b [codeBytes]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", fmt.Errorf("certificate: no randomness for a verification code: %w", err)
	}
	return encoding.EncodeToString(b[:]), nil
}

// Normalise turns what somebody typed into what is stored.
//
// Dashes and spaces go, because the code is PRINTED in groups and a person
// types what they see. `I` and `L` become `1` and `O` becomes `0`, which is
// the substitution Crockford's alphabet is chosen to make safe: those letters
// are not in it, so reading one can only ever have been a misread of the digit.
func Normalise(code string) string {
	var b strings.Builder
	for _, r := range strings.ToUpper(strings.TrimSpace(code)) {
		switch r {
		case '-', ' ', '.':
			continue
		case 'I', 'L':
			r = '1'
		case 'O':
			r = '0'
		}
		if !strings.ContainsRune(alphabet, r) {
			// Anything else is not a code, and a lookup for it would be a query
			// that can only miss.
			return ""
		}
		b.WriteRune(r)
	}
	return b.String()
}

// Grouped is a code as it is printed: four groups of four.
func Grouped(code string) string {
	var b strings.Builder
	for i, r := range code {
		if i > 0 && i%4 == 0 {
			b.WriteByte('-')
		}
		b.WriteRune(r)
	}
	return b.String()
}

func isUniqueViolation(err error) bool {
	var pg interface{ SQLState() string }
	return errors.As(err, &pg) && pg.SQLState() == "23505"
}
