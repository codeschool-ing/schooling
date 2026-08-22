package identity

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/codeschool-ing/schooling/internal/platform/web"
)

// Staff, and the second factor that is not optional for them.
//
// STAFF IS A ROLE ON AN ACCOUNT, NOT A SECOND ACCOUNT. Both people who run this
// are also students of it, and one account with a role beside it makes "am I
// looking at this as staff or as myself" one question rather than a habit of
// remembering which browser you are in.

// Role is what somebody may do. Three, and a fourth would be a decision about a
// person rather than about the system.
type Role string

const (
	// RoleOwner does everything, including granting roles.
	RoleOwner Role = "owner"
	// RoleOperator changes a student's plan, quarantines a question, reads the
	// audit. Everything except deciding who else gets in.
	RoleOperator Role = "operator"
	// RoleReadOnly sees every screen and writes nothing. It is what a new
	// person gets on their first day and what an integration gets forever.
	RoleReadOnly Role = "read-only"
)

// rank is how the roles compare. It is a total order on purpose: a permission
// matrix is a screen nobody can hold in their head, and three roles that
// contain each other can be checked with a comparison.
var rank = map[Role]int{RoleReadOnly: 1, RoleOperator: 2, RoleOwner: 3}

// Covers answers whether holding r is enough to do what `needed` requires.
func (r Role) Covers(needed Role) bool { return rank[r] >= rank[needed] && rank[r] > 0 }

var (
	// ErrNotStaff is an account with no live staff row.
	ErrNotStaff = errors.New("identity: not staff")

	// ErrSecondFactorRequired is a staff session that has not presented one.
	ErrSecondFactorRequired = errors.New("identity: this session has not shown a second factor")

	// ErrNoSecondFactor is a staff account that has not enrolled one at all.
	ErrNoSecondFactor = errors.New("identity: this account has no second factor enrolled")
)

// Member is somebody's staff standing.
type Member struct {
	AccountID uuid.UUID
	Role      Role
	GrantedAt time.Time
}

// Grant gives an account a role, or changes the one it has.
//
// IT DOES NOT ENROL A SECOND FACTOR, and it does not need to: the check that
// matters happens at the door, so a person granted a role before enrolling
// simply cannot reach a staff route until they do. Making enrolment a
// precondition here would mean the grant fails for somebody standing in front
// of you, which is the wrong moment to discover it.
func (s *Store) Grant(ctx context.Context, accountID uuid.UUID, role Role, by uuid.UUID) error {
	if rank[role] == 0 {
		return fmt.Errorf("identity: %q is not a role", role)
	}

	var granter any
	if by != uuid.Nil {
		granter = by
	}

	_, err := s.pool.Exec(ctx, `
		INSERT INTO staff (account_id, role, granted_by) VALUES ($1, $2, $3)
		ON CONFLICT (account_id) DO UPDATE
			SET role = EXCLUDED.role, granted_by = EXCLUDED.granted_by,
			    granted_at = now(), revoked_at = NULL
	`, accountID, string(role), granter)
	if err != nil {
		return fmt.Errorf("identity: granting %s: %w", role, err)
	}
	return nil
}

// Revoke ends somebody's staff standing and every session they have.
//
// THE SESSIONS GO WITH IT. A role revoked while somebody is signed in, leaving
// their session working until it expires, is the difference between removing
// access and scheduling it — and the day this is used in anger is the day that
// difference is the whole point.
func (s *Store) RevokeStaff(ctx context.Context, accountID uuid.UUID) error {
	return pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx,
			`UPDATE staff SET revoked_at = now() WHERE account_id = $1 AND revoked_at IS NULL`,
			accountID); err != nil {
			return fmt.Errorf("identity: revoking a role: %w", err)
		}
		if _, err := tx.Exec(ctx,
			`UPDATE sessions SET revoked_at = now() WHERE account_id = $1 AND revoked_at IS NULL`,
			accountID); err != nil {
			return fmt.Errorf("identity: ending the sessions of former staff: %w", err)
		}
		return nil
	})
}

// StaffOf answers somebody's live staff standing.
func (s *Store) StaffOf(ctx context.Context, accountID uuid.UUID) (Member, error) {
	var m Member
	var role string
	err := s.pool.QueryRow(ctx, `
		SELECT account_id, role, granted_at FROM staff
		WHERE account_id = $1 AND revoked_at IS NULL
	`, accountID).Scan(&m.AccountID, &role, &m.GrantedAt)

	if errors.Is(err, pgx.ErrNoRows) {
		return Member{}, ErrNotStaff
	}
	if err != nil {
		return Member{}, fmt.Errorf("identity: reading a staff role: %w", err)
	}
	m.Role = Role(role)
	return m, nil
}

/* ---------- the second factor ---------- */

// ErrAlreadyEnrolled is a second factor being replaced by a session that has
// not shown the one already there.
var ErrAlreadyEnrolled = errors.New("identity: this account already has a second factor")

// EnrolSecondFactor stores a secret after proving the person can produce a code
// from it.
//
// THE PROOF IS THE POINT. Storing the secret first and verifying later produces
// accounts locked out by a QR code that was never scanned — the person believes
// they enrolled, the system believes it too, and the discovery happens at the
// worst moment. Nothing is written until a code from that secret arrives.
//
// # AND REPLACING ONE ASKS FOR THE ONE THAT IS THERE
//
// This is a security fix, and the hole it closes was mine. The statement was
// `ON CONFLICT DO UPDATE SET secret`, and the route in front of it asks only for
// a session — which is what a password alone produces, because signing in
// issues the cookie before any code is requested.
//
// So somebody holding only the password could sign in, enrol a secret of their
// OWN over the one on the account, present a code from it, and be through a
// door whose entire purpose is to ask for something a password is not.
// "Mandatory MFA for staff" was a description of how accounts are set up rather
// than a property of what a password can reach.
//
// The session is therefore a parameter and not a convenience: the row is
// written when there is nothing to replace, or when THIS session has already
// shown the factor it is replacing. `TestAPasswordAloneCannotReplaceASecondFactor`
// is the whole of the argument, and it fails on the previous statement.
func (s *Store) EnrolSecondFactor(ctx context.Context, accountID uuid.UUID, token, secret, code string) error {
	if err := VerifyTOTP(secret, code, time.Now()); err != nil {
		return err
	}

	/* ONE STATEMENT, because the check and the write have to be the same act.
	   Read-then-write here is a race with a second request holding the same
	   stolen session, and the losing half of that race is the account. */
	tag, err := s.pool.Exec(ctx, `
		INSERT INTO account_credentials (account_id, kind, secret)
		SELECT $1, 'totp', $2
		 WHERE NOT EXISTS (
		           SELECT 1 FROM account_credentials
		            WHERE account_id = $1 AND kind = 'totp')
		    OR EXISTS (
		           SELECT 1 FROM sessions
		            WHERE token_hash = $3
		              AND account_id = $1
		              AND revoked_at IS NULL
		              AND expires_at > now()
		              AND mfa_at IS NOT NULL)
		ON CONFLICT (account_id, kind)
		DO UPDATE SET secret = EXCLUDED.secret, updated_at = now()
	`, accountID, secret, tokenHash(token))
	if err != nil {
		return fmt.Errorf("identity: enrolling a second factor: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrAlreadyEnrolled
	}
	return nil
}

// PresentSecondFactor marks a session as having shown one.
func (s *Store) PresentSecondFactor(ctx context.Context, token, code string) error {
	var secret string
	err := s.pool.QueryRow(ctx, `
		SELECT c.secret
		FROM sessions s
		JOIN account_credentials c ON c.account_id = s.account_id AND c.kind = 'totp'
		WHERE s.token_hash = $1 AND s.revoked_at IS NULL AND s.expires_at > now()
	`, tokenHash(token)).Scan(&secret)

	switch {
	case errors.Is(err, pgx.ErrNoRows):
		// Either the session is dead or there is no second factor to present.
		// Telling those apart here would need a second query to say something
		// the caller cannot act on differently.
		return ErrNoSecondFactor
	case err != nil:
		return fmt.Errorf("identity: reading a second factor: %w", err)
	}

	if err := VerifyTOTP(secret, code, time.Now()); err != nil {
		return err
	}

	_, err = s.pool.Exec(ctx,
		`UPDATE sessions SET mfa_at = now() WHERE token_hash = $1`, tokenHash(token))
	if err != nil {
		return fmt.Errorf("identity: recording the second factor: %w", err)
	}
	return nil
}

// SecondFactorShown answers whether this session has presented one.
func (s *Store) SecondFactorShown(ctx context.Context, token string) (bool, error) {
	var shown bool
	err := s.pool.QueryRow(ctx,
		`SELECT mfa_at IS NOT NULL FROM sessions WHERE token_hash = $1`, tokenHash(token)).Scan(&shown)

	if errors.Is(err, pgx.ErrNoRows) {
		return false, ErrNoSession
	}
	if err != nil {
		return false, fmt.Errorf("identity: reading a session: %w", err)
	}
	return shown, nil
}

/* ---------- the door ---------- */

type staffKey int

const ctxMember staffKey = iota

// MemberFromContext answers the staff standing behind this request.
func MemberFromContext(ctx context.Context) (Member, bool) {
	m, ok := ctx.Value(ctxMember).(Member)
	return m, ok
}

// RequireStaff refuses anybody who is not staff, and anybody whose session has
// not shown a second factor.
//
// BOTH CHECKS, ALWAYS, IN THAT ORDER. A role without the factor is exactly the
// state "mandatory MFA" is supposed to make impossible, and it is reachable the
// moment somebody signs in with a password — so the refusal lives at the door
// rather than in a rule about how accounts are set up.
func RequireStaff(store *Store, needed Role) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			account, ok := FromContext(r.Context())
			if !ok {
				web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
				return
			}

			member, err := store.StaffOf(r.Context(), account.ID)
			if err != nil {
				if !errors.Is(err, ErrNotStaff) {
					web.LoggerFrom(r.Context()).Error("reading a staff role", "error", err)
				}
				// The same answer either way: a person who is not staff learns
				// nothing about which routes exist.
				web.Fail(w, http.StatusNotFound, web.CodeNotFound, "no such thing")
				return
			}

			if !member.Role.Covers(needed) {
				web.Fail(w, http.StatusForbidden, "forbidden",
					"that needs a role this account does not have")
				return
			}

			c, err := r.Cookie(CookieName)
			if err != nil {
				web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
				return
			}
			shown, err := store.SecondFactorShown(r.Context(), c.Value)
			if err != nil {
				web.LoggerFrom(r.Context()).Error("reading a session", "error", err)
				web.Fail(w, http.StatusUnauthorized, web.CodeUnauthorized, "sign in first")
				return
			}
			if !shown {
				web.Fail(w, http.StatusUnauthorized, "second_factor_required",
					"this session has not shown a second factor")
				return
			}

			next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), ctxMember, member)))
		})
	}
}
