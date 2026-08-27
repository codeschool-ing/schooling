package identity

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/jackc/pgx/v5"
)

/* Moving an account to a different address.

   # IT EXISTS BECAUSE THE BANNER HAD NOTHING TO OFFER

   The suppression list can now tell somebody that their address refused our
   mail. Until this, that was the whole of it: a true sentence about a problem
   with no remedy on any screen. And it gets worse on the day confirmation gates
   paying, which is the plan — an address that refuses our mail would stop
   somebody from buying, from a page that explains why and offers nothing.

   # THE ADDRESS MOVES WHEN THE NEW ONE IS PROVED

   A row in `account_email_changes` is a change that has not happened. The
   account keeps its address until somebody follows the link that went to the
   new one, so a typo is a link nobody can click rather than an account nobody
   can reach.

   # WHAT IT DOES NOT DO, AND WHY

   IT DOES NOT END THE OTHER SESSIONS. Changing a password does, because a
   credential changed; an address is not a credential. And the attacker this
   would be aimed at has already presented the password — `Handler` requires it
   — so they can change that too and end every session themselves. Ending them
   here buys nothing against them and surprises everybody who changed their
   address for an ordinary reason.

   IT DOES NOT TOUCH THE OUTSTANDING CONFIRMATION LINKS, and does not need to.
   `ConfirmEmail` requires the token's address to equal the account's, so every
   link sitting in the old inbox stops working the instant the address moves.
   The guard that exists for another reason does this one for free. */

const (
	// changeLife is how long the link works for. The same day a confirmation
	// gets, for the same reason: long enough for a message that sat in a queue,
	// short enough that an abandoned mailbox does not carry a live one for a
	// month.
	changeLife = 24 * time.Hour

	/* changeCap and changeWindow are how many of these an account may ask for.

	   THIS IS THE ONE ABUSE SURFACE THE FEATURE OPENS, and it is worth naming
	   rather than discovering. An authenticated session can now make this
	   platform post a message to an address of the sender's choosing: sign up,
	   ask to move to somebody@example.com, repeat. What arrives is a link that
	   does nothing unless clicked — but it arrives from our domain, on our
	   reputation, to somebody who did not ask.

	   Three an hour is a cap somebody correcting a typo will never reach and a
	   sender will notice immediately. It is a threshold, so the number lives
	   beside its reason (K-16) rather than in a config nobody reads. */
	changeCap    = 3
	changeWindow = time.Hour
)

// ErrTooManyChanges is the cap above, reached.
//
// IT IS ITS OWN ERROR AND NOT A GENERIC REFUSAL, because the sentence a person
// sees has to be different: "wait an hour" is actionable and "that did not
// work" is not, and the one asking is usually somebody who mistyped twice.
var ErrTooManyChanges = errors.New("identity: too many address changes asked for")

// ErrSameAddress is a change to the address the account already has.
//
// A NO-OP THAT WOULD LOOK LIKE WORK. Left to run, it issues a link, sends a
// message and spends one of the three above to move an account where it already
// is — and the person waits for a confirmation that changes nothing.
var ErrSameAddress = errors.New("identity: that is already this account's address")

// ErrNoChange is a change token that cannot be redeemed. Like
// ErrNoConfirmation, it does not say which of the reasons applies — telling a
// spent token from an invented one confirms to a guesser that one is real.
var ErrNoChange = errors.New("identity: that is not a link this account can change with")

// Change is what a caller needs to put a link in the post. The token is in
// plain text here and nowhere else, ever — the row holds a hash.
type Change struct {
	Token     string
	Email     string
	ExpiresAt time.Time
}

/*
RequestEmailChange issues a link to an address the account does not have yet.

	THE ADDRESS IS THE CALLER'S HERE, WHICH IS THE OPPOSITE OF
	`IssueEmailConfirmation`. There the address comes off the row precisely so a
	caller cannot aim a confirmation somewhere else; here aiming it somewhere
	else IS the operation, and what makes that safe is the row not being applied
	until the link comes back.

	IT DOES NOT CHECK WHETHER THE ADDRESS IS TAKEN, and that is deliberate: the
	answer would be a way to ask whether a particular person studies here. The
	collision is caught at redemption by the unique index, which is also the only
	moment the answer is not a race.
*/
func (s *Store) RequestEmailChange(ctx context.Context, accountID uuid.UUID, to string) (Change, error) {
	email := NormaliseEmail(to)
	if !reachable(email) {
		return Change{}, fmt.Errorf(
			"identity: %q is not an address anybody can be reached at", to)
	}

	raw := make([]byte, confirmationBytes)
	if _, err := rand.Read(raw); err != nil {
		return Change{}, fmt.Errorf("identity: drawing a change token: %w", err)
	}
	token := base64.RawURLEncoding.EncodeToString(raw)

	var expires time.Time
	err := pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		/* THE ACCOUNT IS READ FIRST AND IN THE SAME TRANSACTION, so that "is
		   this already your address" and "have you asked three times" are
		   answered against the state the insert then writes into. */
		var current string
		if err := tx.QueryRow(ctx,
			`SELECT lower(email) FROM accounts WHERE id = $1`, accountID).Scan(&current); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNoAccount
			}
			return err
		}
		if current == email {
			return ErrSameAddress
		}

		var asked int
		if err := tx.QueryRow(ctx, `
			SELECT count(*) FROM account_email_changes
			 WHERE account_id = $1 AND created_at > now() - make_interval(secs => $2)
		`, accountID, changeWindow.Seconds()).Scan(&asked); err != nil {
			return err
		}
		if asked >= changeCap {
			return ErrTooManyChanges
		}

		return tx.QueryRow(ctx, `
			INSERT INTO account_email_changes (token_hash, account_id, email, expires_at)
			VALUES ($1, $2, $3, now() + make_interval(secs => $4))
			RETURNING expires_at
		`, confirmationHash(token), accountID, email, changeLife.Seconds()).Scan(&expires)
	})

	switch {
	case errors.Is(err, ErrNoAccount), errors.Is(err, ErrSameAddress),
		errors.Is(err, ErrTooManyChanges):
		return Change{}, err
	case err != nil:
		return Change{}, fmt.Errorf("identity: asking to change an address: %w", err)
	}
	return Change{Token: token, Email: email, ExpiresAt: expires}, nil
}

/*
ConfirmEmailChange spends a link and moves the account onto its address.

	IT RETURNS THE ADDRESS THAT WAS THERE BEFORE, because somebody has to be
	told. The notice goes to the OLD address and it is the only channel that
	reaches the real owner if the person who asked for this was not them — so
	the caller needs to know where to write, and only this transaction knows.

	`email_verified_at` IS SET AND NOT COALESCED, which is the opposite of
	`ConfirmEmail`. There, a second link must not move the date, because it is
	when they proved THIS address. Here the address itself changed, so the old
	date is about a mailbox that is no longer the account's — keeping it would
	claim the new one was verified before it existed.
*/
func (s *Store) ConfirmEmailChange(ctx context.Context, token string) (Account, string, error) {
	if token == "" {
		return Account{}, "", ErrNoChange
	}

	var accountID uuid.UUID
	var previous string

	err := pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		var next string
		err := tx.QueryRow(ctx, `
			UPDATE account_email_changes
			   SET spent_at = now()
			 WHERE token_hash = $1
			   AND spent_at IS NULL
			   AND expires_at > now()
			RETURNING account_id, email
		`, confirmationHash(token)).Scan(&accountID, &next)
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNoChange
		}
		if err != nil {
			return err
		}

		/* THE OLD ADDRESS IS READ BEFORE IT IS OVERWRITTEN, in this same
		   transaction, which is the plain way to do it. Reaching for a
		   subquery inside the UPDATE's RETURNING would be shorter and would
		   depend on which snapshot that subquery sees — a rule most readers
		   would have to look up, in the statement that decides where somebody's
		   account lives. */
		if err := tx.QueryRow(ctx,
			`SELECT lower(email) FROM accounts WHERE id = $1 FOR UPDATE`,
			accountID).Scan(&previous); err != nil {
			return err
		}

		_, err = tx.Exec(ctx, `
			UPDATE accounts SET email = $2, email_verified_at = now() WHERE id = $1
		`, accountID, next)
		return err
	})

	switch {
	case errors.Is(err, ErrNoChange):
		return Account{}, "", ErrNoChange
	case isUniqueViolation(err):
		/* SOMEBODY TOOK THE ADDRESS BETWEEN THE ASKING AND THE CLICKING, which
		   is rare and real. The row is spent either way — the link was used, it
		   just could not be honoured — and saying so is better than a generic
		   failure, because the person can pick another address and try again. */
		return Account{}, "", ErrTaken
	case err != nil:
		return Account{}, "", fmt.Errorf("identity: changing an address: %w", err)
	}

	account, err := s.ByID(ctx, accountID)
	return account, previous, err
}

// reachable is the same shape check `validate` makes for a sign-up, pulled out
// so the two cannot drift.
//
// THEY HAVE TO AGREE. An address this accepts and a sign-up would refuse is one
// somebody can move ONTO but could never have arrived with — and the account
// would then be sitting somewhere the rest of the platform believes impossible.
func reachable(email string) bool {
	at := strings.IndexByte(email, "@"[0])
	return at > 0 && at != len(email)-1 && !strings.Contains(email, " ")
}
