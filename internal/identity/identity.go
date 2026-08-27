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

	/* EmailVerifiedAt is when they proved they can read the address, or nil.

	   IT IS ON THE STRUCT AND NOT A SEPARATE QUERY, and `confirmation.go` used
	   to say the opposite. The three doors into a session — restoring one,
	   signing in, signing up — all answer with this account, and all three have
	   to tell the screen whether to show the nudge; a second round trip on each
	   of them, to read one nullable timestamp off a row already in hand, would
	   be paying for the tidiness of a struct nobody looks at. */
	EmailVerifiedAt *time.Time

	/* ConfirmationPending is whether a link is out there waiting to be
	   followed: issued, unspent, unexpired, and for the address the account has
	   NOW.

	   IT EXISTS SO THAT A SCREEN CAN STOP SAYING SOMETHING FALSE. The nudge
	   banner said "we sent a link to X" whenever the address was unconfirmed —
	   true for somebody who just signed up, and a lie for every account created
	   before confirmations existed, and for anybody whose link expired unread.

	   IT COSTS NO EXTRA ROUND TRIP. Every query below already reads this
	   account's row; this is one more column on the same statement, served by
	   `account_email_confirmations_by_account`. A second call would have put a
	   query in front of every signed-in request, which is the trade that made
	   `EmailVerifiedAt` a field rather than a lookup. */
	ConfirmationPending bool

	CreatedAt time.Time
}

/*
outstanding is the sub-select that answers `ConfirmationPending`.

	IT IS A CONSTANT AND NOT FOUR COPIES, because the four conditions are the
	same four `ConfirmEmail` redeems on, and two of them drifting apart would
	mean a banner offering to resend a link that already works, or promising one
	that does not. `a` is the accounts row in every query that uses it.
*/
const outstanding = `EXISTS (
	SELECT 1 FROM account_email_confirmations c
	 WHERE c.account_id = a.id
	   AND c.spent_at IS NULL
	   AND c.expires_at > now()
	   AND c.email = lower(a.email)
)`

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
			RETURNING id, email, name, locale, country, synthetic, email_verified_at, created_at
		`, email, strings.TrimSpace(in.Name), locale, country, in.Synthetic).Scan(
			&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country, &out.Synthetic, &out.EmailVerifiedAt, &out.CreatedAt)
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
		SELECT a.id, a.email, a.name, a.locale, a.country, a.synthetic, a.email_verified_at,
		       a.created_at, `+outstanding+`, c.secret
		FROM accounts a
		JOIN account_credentials c ON c.account_id = a.id AND c.kind = 'password'
		WHERE lower(a.email) = lower($1)
	`, NormaliseEmail(email)).Scan(
		&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country, &out.Synthetic,
		&out.EmailVerifiedAt, &out.CreatedAt, &out.ConfirmationPending, &stored)

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
		SELECT a.id, a.email, a.name, a.locale, a.country, a.synthetic,
		       a.email_verified_at, a.created_at, `+outstanding+`
		  FROM accounts a WHERE a.id = $1
	`, id).Scan(&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country,
		&out.Synthetic, &out.EmailVerifiedAt, &out.CreatedAt, &out.ConfirmationPending)

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
		SELECT a.id, a.email, a.name, a.locale, a.country, a.synthetic,
		       a.email_verified_at, a.created_at, `+outstanding+`
		  FROM accounts a WHERE a.email = $1
	`, address).Scan(&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country,
		&out.Synthetic, &out.EmailVerifiedAt, &out.CreatedAt, &out.ConfirmationPending)

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

// Verify answers whose session this token is, and records that it was seen.
//
// # THE HEARTBEAT IS A MINUTE, AND IT USED TO BE AN HOUR (K-06)
//
// An hour was right for the question `last_seen_at` was written for — "is this
// session still in use", asked of a person's own list of sittings, where an
// hour is more precision than anybody wants. It cannot answer "is somebody here
// now", which is what the console's `Watch` asks: a timestamp allowed to be
// fifty-nine minutes stale reports an empty platform at its busiest, and
// reports it confidently.
//
// It is still not a write per request. The condition below IS the rate limit,
// it lives in the database rather than in this process — so it holds across
// every instance instead of once per instance — and it rides the query that
// authenticates, so the busiest read path in the system gains no round trip
// for it.
//
// # `at` IS WHICH SCHOOL THIS REQUEST ARRIVED AT
//
// Nil on the console's host and on the platform's own address. Nil does not
// erase what is there: somebody who reads the landing page between two lessons
// must not vanish from the school they are studying in, which is what the
// COALESCE is for. A session that has never touched a school therefore stays
// null and is present nowhere, rather than being present in the last school
// anybody happened to be in.
//
// The second half of the condition is what makes a brand-new session appear
// immediately. Without it the first minute of every visit would be spent
// invisible, which for a lesson somebody opens and abandons is most of it.
func (s *Store) Verify(ctx context.Context, token string, at *uuid.UUID) (Account, Viewing, error) {
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
			UPDATE sessions
			SET last_seen_at = now(), last_seen_tenant = COALESCE($2::uuid, last_seen_tenant)
			WHERE id IN (SELECT id FROM live)
			  AND (last_seen_at < now() - interval '1 minute'
			       OR ($2::uuid IS NOT NULL AND last_seen_tenant IS NULL))
			RETURNING id
		)
		SELECT a.id, a.email, a.name, a.locale, a.country, a.synthetic, a.email_verified_at,
		       a.created_at, `+outstanding+`, live.viewed_by, live.viewing_tenant
		FROM live JOIN accounts a ON a.id = live.account_id
	`, tokenHash(token), at).Scan(&out.ID, &out.Email, &out.Name, &out.Locale, &out.Country,
		&out.Synthetic, &out.EmailVerifiedAt, &out.CreatedAt, &out.ConfirmationPending,
		&by, &school)

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
