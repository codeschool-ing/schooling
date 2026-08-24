// Package identity is who a person is, and how the server knows it is still
// them on the next request.
//
// ONE ACCOUNT FOR THE WHOLE PLATFORM (N-01). Nothing here mentions a school,
// and no table it owns carries `tenant_id`: somebody who studies programming
// and mathematics is one person with one password, and one subscription covers
// both (N-02). What is school-scoped is what they DID, not who they are.
//
// # THE SESSION TOKEN EXISTS IN ONE PLACE
//
// The value in the cookie is never stored. What the database holds is its
// SHA-256, so a backup that leaks, or a query somebody ran and pasted
// somewhere, hands over nothing that can be replayed as somebody. This is the
// difference between a leak that costs a rotation and a leak that costs every
// live session — and it is one line of code at this end, taken now.
package identity

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	// ErrNoAccount is a sign-in for an address nobody has. It never reaches a
	// person: see Authenticate.
	ErrNoAccount = errors.New("identity: no account with that address")

	// ErrTaken is a sign-up for an address somebody already has.
	ErrTaken = errors.New("identity: that address already has an account")

	// ErrNoSession is a cookie that names no live session — expired, revoked,
	// or never real.
	ErrNoSession = errors.New("identity: no live session")
)

// How long a session lasts without being used. Long enough that studying on a
// Sunday does not mean signing in again the following Saturday; short enough
// that a browser somebody abandoned stops being a way in.
const sessionLifetime = 30 * 24 * time.Hour

// Account is a person. It carries no school, and it carries no credential.
type Account struct {
	ID      uuid.UUID
	Email   string
	Name    string
	Locale  string
	Country string

	// Synthetic students are excluded from every aggregate by default (K-11).
	// It is on the struct rather than only in the database because the code
	// that builds a cohort has to be able to see it.
	Synthetic bool

	CreatedAt time.Time
}

type Store struct {
	pool *pgxpool.Pool
}

func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

/* ---------- accounts ---------- */

// NewAccount is what sign-up needs. A struct rather than five string arguments,
// because five strings in a row is how two of them end up swapped.
type NewAccount struct {
	Email    string
	Name     string
	Password string

	Locale  string
	Country string

	// Set only by whatever seeds a population to build the cohort screens
	// against. It defaults to false, which is the safe direction: a real
	// student wrongly flagged disappears from every number.
	Synthetic bool
}

// Create makes an account and its password in one transaction.
//
// BOTH OR NEITHER. An account with no credential cannot sign in and cannot be
// created again — the address is taken — so a person in that state is a support
// conversation that ends in a manual row.
func (s *Store) Create(ctx context.Context, in NewAccount) (Account, error) {
	email := NormaliseEmail(in.Email)
	if err := validate(email, in.Password); err != nil {
		return Account{}, err
	}

	hash, err := hashPassword(in.Password)
	if err != nil {
		return Account{}, err
	}

	locale, country := in.Locale, in.Country
	if locale == "" {
		locale = "unknown"
	}
	if country == "" {
		country = "unknown"
	}

	var out Account
	err = pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		err := tx.QueryRow(ctx, `
			INSERT INTO accounts (email, name, locale, country, synthetic)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING id, email, name, locale, country, synthetic, created_at
		`, email, strings.TrimSpace(in.Name), locale, country, in.Synthetic).Scan(
			&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country, &out.Synthetic, &out.CreatedAt)
		if err != nil {
			return err
		}

		_, err = tx.Exec(ctx, `
			INSERT INTO account_credentials (account_id, kind, secret) VALUES ($1, 'password', $2)
		`, out.ID, hash)
		return err
	})

	if isUniqueViolation(err) {
		return Account{}, ErrTaken
	}
	if err != nil {
		return Account{}, fmt.Errorf("identity: creating an account: %w", err)
	}
	return out, nil
}

// Authenticate answers the account for an address and password.
//
// IT COSTS THE SAME WHETHER THE ACCOUNT EXISTS OR NOT. Returning early for an
// unknown address makes the response time a way to ask "does this person have
// an account here" — which for an education platform is a question about
// somebody's private life, answered by a stopwatch. So an unknown address is
// verified against a decoy hash and fails at the same point, at the same cost.
func (s *Store) Authenticate(ctx context.Context, email, password string) (Account, error) {
	var out Account
	var stored string

	err := s.pool.QueryRow(ctx, `
		SELECT a.id, a.email, a.name, a.locale, a.country, a.synthetic, a.created_at, c.secret
		FROM accounts a
		JOIN account_credentials c ON c.account_id = a.id AND c.kind = 'password'
		WHERE lower(a.email) = lower($1)
	`, NormaliseEmail(email)).Scan(
		&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country, &out.Synthetic,
		&out.CreatedAt, &stored)

	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// Do the work anyway, then refuse. The decoy is a real hash of a value
		// nobody has, so the timing matches an account whose password is wrong.
		_ = verifyPassword(decoyHash, password)
		return Account{}, ErrNoAccount
	case err != nil:
		return Account{}, fmt.Errorf("identity: reading an account: %w", err)
	}

	if err := verifyPassword(stored, password); err != nil {
		return Account{}, err
	}
	return out, nil
}

// decoyHash is a real argon2id hash, of a value nobody can present, made with
// the same parameters as a new password. It exists so that an unknown address
// costs what a known one does.
var decoyHash = func() string {
	h, err := hashPassword("this is not anybody's password: " + uuid.NewString())
	if err != nil {
		// Only reachable if the random source is broken, in which case nothing
		// else here works either.
		panic("identity: cannot build the decoy hash: " + err.Error())
	}
	return h
}()

func (s *Store) ByID(ctx context.Context, id uuid.UUID) (Account, error) {
	var out Account
	err := s.pool.QueryRow(ctx, `
		SELECT id, email, name, locale, country, synthetic, created_at FROM accounts WHERE id = $1
	`, id).Scan(&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country,
		&out.Synthetic, &out.CreatedAt)

	if errors.Is(err, pgx.ErrNoRows) {
		return Account{}, ErrNoAccount
	}
	if err != nil {
		return Account{}, fmt.Errorf("identity: reading an account: %w", err)
	}
	return out, nil
}

// ByEmail answers the account at exactly this address, and never a list.
//
// EXACT, AND THERE IS NO PARTIAL FORM OF IT (K-22). The console's one way of
// reaching a person is this, and the reason it is not a search is that a search
// is not a lookup: typing `@example.tld` and reading the result is BROWSING
// PEOPLE, which is the one thing an audit trail cannot tell apart from working
// — both look like a staff member opening records.
//
// The address is folded and trimmed the way one pasted out of a support message
// arrives. A lookup that missed on a trailing space would be read as "this
// person has no account", which is the wrong answer to give somebody who asked
// to be forgotten.
func (s *Store) ByEmail(ctx context.Context, email string) (Account, error) {
	address := strings.ToLower(strings.TrimSpace(email))
	if address == "" {
		return Account{}, ErrNoAccount
	}

	var out Account
	err := s.pool.QueryRow(ctx, `
		SELECT id, email, name, locale, country, synthetic, created_at FROM accounts WHERE email = $1
	`, address).Scan(&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country,
		&out.Synthetic, &out.CreatedAt)

	if errors.Is(err, pgx.ErrNoRows) {
		return Account{}, ErrNoAccount
	}
	if err != nil {
		return Account{}, fmt.Errorf("identity: reading an account by address: %w", err)
	}
	return out, nil
}

// SetPassword replaces the password and revokes every session but the one asking.
//
// REVOKING IS THE POINT, not the new password. Somebody changing their password
// because they think another person has it gains nothing if that person's
// session keeps working — which is what "change your password" means to
// everybody who has ever been told to do it.
func (s *Store) SetPassword(ctx context.Context, id uuid.UUID, password, keepToken string) error {
	if err := validate("keep@example.tld", password); err != nil {
		return err
	}
	hash, err := hashPassword(password)
	if err != nil {
		return err
	}

	return pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `
			UPDATE account_credentials SET secret = $2, updated_at = now()
			WHERE account_id = $1 AND kind = 'password'
		`, id, hash)
		if err != nil {
			return fmt.Errorf("identity: changing a password: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return ErrNoAccount
		}

		_, err = tx.Exec(ctx, `
			UPDATE sessions SET revoked_at = now()
			WHERE account_id = $1 AND revoked_at IS NULL AND token_hash <> $2
		`, id, tokenHash(keepToken))
		if err != nil {
			return fmt.Errorf("identity: revoking the other sessions: %w", err)
		}
		return nil
	})
}

/* ---------- sessions ---------- */

// Issue starts a session and answers the token, which is the only time it
// exists outside the browser.
func (s *Store) Issue(ctx context.Context, accountID uuid.UUID, userAgent string) (string, error) {
	token, err := newToken()
	if err != nil {
		return "", err
	}

	if len(userAgent) > 400 {
		userAgent = userAgent[:400]
	}

	if _, err := s.pool.Exec(ctx, `
		INSERT INTO sessions (account_id, token_hash, expires_at, user_agent)
		VALUES ($1, $2, now() + $3::interval, $4)
	`, accountID, tokenHash(token), sessionLifetime.String(), userAgent); err != nil {
		return "", fmt.Errorf("identity: starting a session: %w", err)
	}
	return token, nil
}

// newToken is the only place a session token is made, so that a second kind of
// session cannot quietly be given a weaker one. 32 bytes from `crypto/rand`,
// which is the whole of the secret — the database keeps its hash and never this.
func newToken() (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", fmt.Errorf("identity: no randomness for a session: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(raw), nil
}

// Verify answers whose session this token is.
//
// It moves `last_seen_at` at most once an hour, for the same reason the visitor
// does: this is the busiest read path there will be, and turning it into a
// write on every request is amplification for a column nobody reads to the
// minute.
func (s *Store) Verify(ctx context.Context, token string) (Account, Viewing, error) {
	if token == "" {
		return Account{}, Viewing{}, ErrNoSession
	}

	var out Account
	var viewing Viewing
	var by, school *uuid.UUID

	/* A VIEWING IS READ HERE AND NOT SOMEWHERE AFTER, because everything that
	   decides how a request is treated has to come from the one row that
	   authenticated it. Asking a second query "is this session a viewing" is two
	   answers that can disagree, and the direction they would disagree in is a
	   session behaving as the student between the two. */
	err := s.pool.QueryRow(ctx, `
		WITH live AS (
			SELECT id, account_id, viewed_by, viewing_tenant FROM sessions
			WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > now()
			  AND (viewed_by IS NULL OR redeemed_at IS NOT NULL)
		), touched AS (
			UPDATE sessions SET last_seen_at = now()
			WHERE id IN (SELECT id FROM live) AND last_seen_at < now() - interval '1 hour'
			RETURNING id
		)
		SELECT a.id, a.email, a.name, a.locale, a.country, a.synthetic, a.created_at,
		       live.viewed_by, live.viewing_tenant
		FROM live JOIN accounts a ON a.id = live.account_id
	`, tokenHash(token)).Scan(&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country,
		&out.Synthetic, &out.CreatedAt, &by, &school)

	if errors.Is(err, pgx.ErrNoRows) {
		return Account{}, Viewing{}, ErrNoSession
	}
	if err != nil {
		return Account{}, Viewing{}, fmt.Errorf("identity: reading a session: %w", err)
	}
	if by != nil && school != nil {
		viewing = Viewing{By: *by, School: *school}
	}
	return out, viewing, nil
}

// Revoke ends one session. Signing out of a browser must not sign the person
// out of their phone.
func (s *Store) Revoke(ctx context.Context, token string) error {
	_, err := s.pool.Exec(ctx,
		`UPDATE sessions SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL`,
		tokenHash(token))
	if err != nil {
		return fmt.Errorf("identity: ending a session: %w", err)
	}
	return nil
}

// RevokeAll ends every session an account has. It is what a support request
// beginning "I think somebody else is in my account" needs.
func (s *Store) RevokeAll(ctx context.Context, accountID uuid.UUID) error {
	_, err := s.pool.Exec(ctx,
		`UPDATE sessions SET revoked_at = now() WHERE account_id = $1 AND revoked_at IS NULL`,
		accountID)
	if err != nil {
		return fmt.Errorf("identity: ending every session of an account: %w", err)
	}
	return nil
}

// tokenHash is what the database stores. SHA-256 and not a password hash: the
// token is 256 bits of randomness rather than something a person chose, so
// there is nothing to guess and no reason to make verification slow.
func tokenHash(token string) []byte {
	sum := sha256.Sum256([]byte(token))
	return sum[:]
}

/* ---------- the small rules ---------- */

// NormaliseEmail is what is stored and what is compared.
//
// Lowercasing only. Stripping dots or `+tags` is a provider's convention rather
// than a rule of the format, and applying it would silently merge two addresses
// that a different provider treats as two people.
func NormaliseEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

// The shortest password this accepts, and the reason it is a length rather than
// a character-class rule: forcing a symbol and a digit produces `Password1!`,
// which is worse than a long thing somebody can remember. Length is the only
// requirement that actually correlates with strength.
const minimumPasswordLength = 10

func validate(email, password string) error {
	var problems []error

	if at := strings.IndexByte(email, '@'); at <= 0 || at == len(email)-1 || strings.Contains(email, " ") {
		problems = append(problems, fmt.Errorf("%q is not an address anybody can be reached at", email))
	}
	if len([]rune(password)) < minimumPasswordLength {
		problems = append(problems, fmt.Errorf(
			"a password needs at least %d characters — length is the only requirement that "+
				"correlates with strength, which is why there is no rule about symbols",
			minimumPasswordLength))
	}
	if len(password) > 1024 {
		// Not a strength rule: argon2 will happily hash a megabyte somebody
		// posted, on the server's time.
		problems = append(problems, errors.New("that password is longer than anybody typed on purpose"))
	}

	if err := errors.Join(problems...); err != nil {
		return fmt.Errorf("identity: %w", err)
	}
	return nil
}

func isUniqueViolation(err error) bool {
	var pg interface{ SQLState() string }
	return errors.As(err, &pg) && pg.SQLState() == "23505"
}
