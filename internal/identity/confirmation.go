package identity

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/jackc/pgx/v5"
)

/* Confirming that somebody can read the address they signed up with.

   THE COLUMN HAS BEEN WAITING SINCE MIGRATION 0004. `accounts.email_verified_at`
   was added early on purpose — adding it later means guessing which existing
   accounts were verified — and then nothing ever wrote it. The personal-data
   export reads it, so somebody asking for everything this platform holds about
   them gets a field that has never had a value, and `analysis/funnel.go` carries
   a step it cannot count.

   # IT GATES NOTHING, AND THAT IS A DECISION RATHER THAN AN OMISSION

   Registering already signs the student in, and it stays that way. A platform
   that parks somebody on a "check your inbox" screen loses the ones whose mail
   is slow, whose filter ate it, or who typed one letter wrong and cannot now
   get back to the form. What an unconfirmed address costs us is knowing whether
   we can reach them; what a gate would cost them is the lesson they came for.

   So this is a fact recorded about an account, and the screens that will want
   it — the nudge banner, the funnel, a person's record in the console — read it
   rather than obey it.

   # A LINK, NOT A CODE

   Recovery codes are read off paper by a person, so their alphabet leaves out
   what people misread. This is clicked, never typed, so it optimises for the
   other thing: thirty-two random bytes, base64url, which no amount of guessing
   reaches and which survives being wrapped by a mail client.

   # ONE DAY

   Long enough for somebody who signed up at midnight and reads their mail after
   work, short enough that a message forwarded or left in an open inbox stops
   being a way in. It is a constant and not a parameter, because K-13 asks
   whether there is a right answer, and for "how long should a confirmation link
   live" every service that has thought about it landed within a day of this
   one. */

const (
	// confirmationBytes is the entropy in the link. Thirty-two is the same as a
	// session token, which is the right comparison: both are a bearer secret
	// that arrives over a channel we do not control.
	confirmationBytes = 32

	// confirmationLife is how long the link works for. See the note above.
	confirmationLife = 24 * time.Hour
)

// ErrNoConfirmation is a token that cannot be redeemed, and it is deliberately
// one error for four situations: never existed, already spent, expired, or
// issued for an address the account no longer has.
//
// TELLING THEM APART WOULD ANSWER A QUESTION THE ASKER CANNOT ACT ON, and would
// answer it for somebody guessing as readily as for the person who owns the
// account — "already spent" is a confirmation that the token is real. The
// screen says the link is no longer good and offers to send another, which is
// the same useful sentence in all four cases.
var ErrNoConfirmation = errors.New("identity: that is not a link this account can confirm with")

// Confirmation is a link waiting to be followed: the token to put in the
// message, and when it stops working.
//
// THE TOKEN IS IN PLAIN TEXT HERE AND NOWHERE ELSE, EVER. What this returns is
// the only copy; the row holds a hash. A caller that logged this would be
// logging the way into somebody's account confirmation, which is why nothing
// here returns it twice and why there is no "read the outstanding token" call.
type Confirmation struct {
	Token     string
	Email     string
	ExpiresAt time.Time
}

// IssueEmailConfirmation makes a link for this account's current address.
//
// IT ADDS RATHER THAN REPLACES, which is the opposite of IssueRecoveryCodes and
// for a reason that does not carry over. Reissuing recovery codes means "the old
// ones may be compromised", so the old ones have to stop working. Asking for the
// confirmation mail again means "the first one did not arrive" — and killing the
// first would break the link in the message that was merely slow, which is
// exactly the message likely to be sitting in the inbox when the second lands.
//
// Nothing here limits how often it may be called. That is the endpoint's job
// and not the store's: a limit belongs where the request arrives, with the
// address that made it.
func (s *Store) IssueEmailConfirmation(ctx context.Context, accountID uuid.UUID) (Confirmation, error) {
	raw := make([]byte, confirmationBytes)
	if _, err := rand.Read(raw); err != nil {
		return Confirmation{}, fmt.Errorf("identity: drawing a confirmation token: %w", err)
	}
	token := base64.RawURLEncoding.EncodeToString(raw)

	/* THE ADDRESS COMES FROM THE ROW AND NOT FROM THE CALLER. A caller passing
	   one could pass a different one, and a confirmation link is precisely the
	   thing that must be about the address on the account. The insert reads it
	   in the same statement that writes the token, so there is no window. */
	var email string
	var expires time.Time
	err := s.pool.QueryRow(ctx, `
		INSERT INTO account_email_confirmations (token_hash, account_id, email, expires_at)
		SELECT $1, a.id, lower(a.email), now() + make_interval(secs => $3)
		  FROM accounts a
		 WHERE a.id = $2
		RETURNING email, expires_at
	`, confirmationHash(token), accountID, confirmationLife.Seconds()).Scan(&email, &expires)

	if errors.Is(err, pgx.ErrNoRows) {
		// The SELECT found no account, so the INSERT wrote nothing. A foreign
		// key would have caught this as a constraint violation; this way it
		// comes back as the error the caller already handles.
		return Confirmation{}, ErrNoAccount
	}
	if err != nil {
		return Confirmation{}, fmt.Errorf("identity: issuing a confirmation: %w", err)
	}
	return Confirmation{Token: token, Email: email, ExpiresAt: expires}, nil
}

// ConfirmEmail redeems a link and returns the account it belonged to.
//
// # THE UPDATE IS THE CHECK
//
// Read-then-write would let two requests carrying the same token both find it
// unspent, which is a link that works twice. The same reasoning as
// SpendRecoveryCode, and the same shape: one statement that both decides and
// records, so the database settles the race instead of the process.
//
// # AND CONFIRMING TWICE KEEPS THE FIRST TIMESTAMP
//
// `email_verified_at` is when they proved it, not when they last clicked. A
// second link followed a week later — there can be several outstanding, because
// resending adds — must not move the date, or every report about how long
// people take to confirm quietly measures how many links they were sent.
func (s *Store) ConfirmEmail(ctx context.Context, token string) (Account, error) {
	if token == "" {
		return Account{}, ErrNoConfirmation
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Account{}, fmt.Errorf("identity: confirming an address: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	/* THE ADDRESS IS PART OF THE CONDITION. A token issued for one address does
	   not confirm another: what the person proved is that they can read the
	   mail that arrived at the first. Joining `accounts` here rather than
	   checking afterwards keeps that inside the single statement that decides. */
	var accountID uuid.UUID
	err = tx.QueryRow(ctx, `
		UPDATE account_email_confirmations c
		   SET spent_at = now()
		  FROM accounts a
		 WHERE c.token_hash = $1
		   AND c.spent_at IS NULL
		   AND c.expires_at > now()
		   AND a.id = c.account_id
		   AND lower(a.email) = c.email
		RETURNING c.account_id
	`, confirmationHash(token)).Scan(&accountID)

	if errors.Is(err, pgx.ErrNoRows) {
		return Account{}, ErrNoConfirmation
	}
	if err != nil {
		return Account{}, fmt.Errorf("identity: spending a confirmation: %w", err)
	}

	if _, err := tx.Exec(ctx, `
		UPDATE accounts
		   SET email_verified_at = COALESCE(email_verified_at, now())
		 WHERE id = $1
	`, accountID); err != nil {
		return Account{}, fmt.Errorf("identity: recording a confirmed address: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Account{}, fmt.Errorf("identity: confirming an address: %w", err)
	}
	return s.ByID(ctx, accountID)
}

// EmailConfirmed answers whether this account has proved it can read its
// address, and when.
//
// IT IS A QUERY AND NOT A FIELD ON `Account`, for now. Every screen that wants
// it wants only the boolean, `Account` is loaded on the path of every signed-in
// request, and a column added to that struct is a column every one of those
// requests carries. The day a screen wants the date beside the address, this
// moves.
func (s *Store) EmailConfirmed(ctx context.Context, accountID uuid.UUID) (time.Time, bool, error) {
	var at *time.Time
	err := s.pool.QueryRow(ctx,
		`SELECT email_verified_at FROM accounts WHERE id = $1`, accountID).Scan(&at)

	if errors.Is(err, pgx.ErrNoRows) {
		return time.Time{}, false, ErrNoAccount
	}
	if err != nil {
		return time.Time{}, false, fmt.Errorf("identity: reading a confirmed address: %w", err)
	}
	if at == nil {
		return time.Time{}, false, nil
	}
	return *at, true, nil
}

// confirmationHash is what the row holds. Plain SHA-256 with no salt and no
// stretching, exactly as session tokens are kept and for the same reason: this
// is thirty-two random bytes rather than something a person chose, so there is
// no dictionary to run and nothing for a work factor to buy.
func confirmationHash(token string) []byte {
	sum := sha256.Sum256([]byte(token))
	return sum[:]
}
