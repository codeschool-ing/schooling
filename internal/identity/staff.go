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

// Standing is one staff row with everything an access review needs beside it.
//
// IT IS NOT `Member`. `Member` is what a REQUEST is checked against — an id, a
// role, a date — and it is read on every staff route, so it must stay one row
// and no joins. This is the other question, asked rarely and whole: who has a
// role, whether they can actually use it, who let them in, and when they last
// did. Answering it with a loop over `Member` would be four queries per person
// on the one screen that has every person on it.
type Standing struct {
	AccountID uuid.UUID
	Name      string
	Email     string
	Role      Role

	GrantedAt time.Time

	// Who granted it, denormalised into a name and an address here for the
	// reason `audit_log.actor_label` is denormalised in the table: the id of
	// somebody who has since been erased points at nothing, and "who let this
	// person in" is asked long after the fact. Empty for the first owner, who
	// has nobody above them — `granted_by` is null there by design.
	GrantedByName  string
	GrantedByEmail string

	// Set on somebody who left. A revoked row is KEPT (see `0005`) so that a
	// person who left is distinguishable from a person who was never staff,
	// and a listing that hid them could not answer the question the row was
	// kept for.
	RevokedAt *time.Time

	// Whether they have a second factor at all. A role without one opens
	// nothing — the check is at the door — so a roster that showed the role
	// and not this would be describing access that does not exist.
	SecondFactor bool

	// When they last presented that second factor, which is when they last
	// actually opened the console.
	//
	// IT IS `mfa_at` AND NOT `last_seen_at`, and the difference is the whole
	// value of the column. A staff member is also a student here (see the top
	// of this file), so a session touched five minutes ago may well be somebody
	// reading their own course. `mfa_at` is set exactly once per session, at the
	// moment a code was presented, and nothing but reaching a staff route asks
	// for one.
	//
	// Nil is nobody who has ever opened it, which is the row an access review
	// exists to find.
	LastOpenedConsole *time.Time
}

/*
Staff is everybody who has a role or has had one, current first.

	WHY THE CONSOLE MAY SEE THIS AT ALL, when it may not list students (K-22).
	The argument against listing people is that browsing personal data is
	indistinguishable from working. It does not reach here: this is not a
	population, it is the platform's own access-control list, and the reason to
	read it is the reason it exists — somebody checking whether the set of people
	who can open this is still the set that should. That check is impossible to
	do one exact address at a time, because the whole question is who is on the
	list that you did not think to ask about.

	REVOKED ROWS COME BACK TOO, and they are ordered last rather than filtered.
	`cmd/staff list` filters them, correctly, because it answers "who can get in
	right now" for somebody about to grant or revoke. A screen answers "who has
	ever been able to", which is the question with an audit in it.
*/
func (s *Store) Staff(ctx context.Context) ([]Standing, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT a.id, a.name, a.email, s.role, s.granted_at, s.revoked_at,
		       coalesce(g.name, ''), coalesce(g.email, ''),
		       EXISTS (SELECT 1 FROM account_credentials c
		               WHERE c.account_id = a.id AND c.kind = 'totp'),
		       (SELECT max(x.mfa_at) FROM sessions x WHERE x.account_id = a.id)
		FROM staff s
		JOIN accounts a ON a.id = s.account_id
		LEFT JOIN accounts g ON g.id = s.granted_by
		-- Current before revoked, then by RANK rather than by the word. Sorting
		-- on the role column alphabetically puts operator above owner and
		-- read-only below both, which reads as an order and is not one. The
		-- rank map in this file is the real order, spelled out again here
		-- because SQL cannot see a Go map.
		ORDER BY s.revoked_at IS NOT NULL,
		         CASE s.role WHEN 'owner' THEN 1 WHEN 'operator' THEN 2 ELSE 3 END,
		         a.email
	`)
	if err != nil {
		return nil, fmt.Errorf("identity: reading the staff: %w", err)
	}
	defer rows.Close()

	var out []Standing
	for rows.Next() {
		var one Standing
		var role string
		if err := rows.Scan(&one.AccountID, &one.Name, &one.Email, &role,
			&one.GrantedAt, &one.RevokedAt, &one.GrantedByName, &one.GrantedByEmail,
			&one.SecondFactor, &one.LastOpenedConsole); err != nil {

			return nil, fmt.Errorf("identity: reading a staff row: %w", err)
		}
		one.Role = Role(role)
		out = append(out, one)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("identity: reading the staff: %w", err)
	}
	return out, nil
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
// It returns the recovery codes, which exist in plain text in that return value
// and nowhere else afterwards. Enrolling is the one moment a person is looking
// at the screen and can write them down, and an account with a second factor
// and no way past it is one lost phone from a database edit.
func (s *Store) EnrolSecondFactor(ctx context.Context, accountID uuid.UUID, token, secret, code string) ([]string, error) {
	if err := VerifyTOTP(secret, code, time.Now()); err != nil {
		return nil, err
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
		return nil, fmt.Errorf("identity: enrolling a second factor: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, ErrAlreadyEnrolled
	}

	/* THE CODES COME WITH THE FACTOR, in the same call, because there is no
	   second moment when somebody is looking at a screen ready to write ten
	   strings down. Issuing them later is a feature nobody opens. */
	return s.IssueRecoveryCodes(ctx, accountID)
}

// PresentSecondFactor marks a session as having shown one — with a code from
// the authenticator app, or with a recovery code.
//
// BOTH, BECAUSE THE SCREEN OFFERS BOTH. It has said "or a recovery code" since
// the second factor shipped, and for as long as only TOTP was accepted here
// that sentence was a promise the system could not keep. A person whose phone
// is gone reads it, believes there is a way back, and finds none.
//
// TOTP FIRST AND THE RECOVERY CODE SECOND, which costs nothing: they cannot be
// confused for one another — six digits against ten characters with a
// separator — and the common case is the one that runs first.
func (s *Store) PresentSecondFactor(ctx context.Context, token, code string) error {
	var accountID uuid.UUID
	var secret string
	err := s.pool.QueryRow(ctx, `
		SELECT s.account_id, c.secret
		FROM sessions s
		JOIN account_credentials c ON c.account_id = s.account_id AND c.kind = 'totp'
		WHERE s.token_hash = $1 AND s.revoked_at IS NULL AND s.expires_at > now()
	`, tokenHash(token)).Scan(&accountID, &secret)

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
		/* A WRONG CODE IS NOT YET A REFUSAL. It may be a recovery code, and
		   spending one is a write — so this is the only path here that changes
		   anything before the session is marked. */
		if spent := s.SpendRecoveryCode(ctx, accountID, code); spent != nil {
			if errors.Is(spent, ErrNoRecoveryCode) {
				// The original refusal, not this one: what the caller asked was
				// "is this code right", and the answer is no either way.
				return err
			}
			return spent
		}
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

// HasSecondFactor answers whether the account has one at all.
//
// IT IS A DIFFERENT QUESTION FROM `SecondFactorShown`, and the interface needs
// both: this one decides what the account screen offers, that one decides
// whether to ask for a code right now. Answering the first with the second is
// how a screen offers to enrol a factor over the top of the one that is there.
func (s *Store) HasSecondFactor(ctx context.Context, accountID uuid.UUID) (bool, error) {
	var has bool
	err := s.pool.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM account_credentials WHERE account_id = $1 AND kind = 'totp')
	`, accountID).Scan(&has)
	if err != nil {
		return false, fmt.Errorf("identity: reading whether there is a second factor: %w", err)
	}
	return has, nil
}

// Sitting is one browser signed in, as an operator needs to see it.
//
// THE TOKEN HASH IS NOT IN IT. What a record needs is how many sittings there
// are, since when, and from what — never anything that would let somebody
// become the person they are looking at.
type Sitting struct {
	ID         uuid.UUID
	CreatedAt  time.Time
	LastSeenAt *time.Time
	ExpiresAt  time.Time
	RevokedAt  *time.Time
	UserAgent  string
}

// Sittings are the sessions of one account, newest first.
func (s *Store) Sittings(ctx context.Context, accountID uuid.UUID) ([]Sitting, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, created_at, last_seen_at, expires_at, revoked_at, user_agent
		FROM sessions WHERE account_id = $1 ORDER BY created_at DESC
	`, accountID)
	if err != nil {
		return nil, fmt.Errorf("identity: reading the sittings: %w", err)
	}
	defer rows.Close()

	var out []Sitting
	for rows.Next() {
		var one Sitting
		if err := rows.Scan(&one.ID, &one.CreatedAt, &one.LastSeenAt,
			&one.ExpiresAt, &one.RevokedAt, &one.UserAgent); err != nil {
			return nil, fmt.Errorf("identity: reading a sitting: %w", err)
		}
		out = append(out, one)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("identity: reading the sittings: %w", err)
	}
	return out, nil
}
