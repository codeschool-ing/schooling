package identity

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
)

/* Recovery codes: the way back in when the authenticator app is gone.

   THE SIGN-IN SCREEN HAS PROMISED THIS SINCE THE SECOND FACTOR SHIPPED — "enter
   the code from your authenticator app, or a recovery code" — and nothing
   issued one. A screen asking for something the system cannot accept is worse
   than one that does not offer it: the person locked out reads the sentence,
   believes there is a way back, and goes looking for a code that was never
   made.

   Without them the only way back is an edit to the database, which is precisely
   the arrangement the console exists to end.

   # TEN, SHOWN ONCE

   Ten because it is enough for a person to lose a phone twice and still have
   some left, and few enough to be written on one line of paper. They are
   returned exactly once, by the call that creates them, and then only their
   hashes exist here.

   # THE ALPHABET LEAVES OUT WHAT PEOPLE MISREAD

   No `I`, `L`, `O` or `U`: the first three are misread as `1`, `1` and `0` off a
   screenshot or a piece of paper, and the fourth is left out because it turns
   short strings into words nobody wants to read out. What is left is 32
   characters, so ten of them are fifty bits — nothing to brute-force even at
   one guess per request.

   Comparison folds case and forgets the separator, because a code is read by a
   person and typed by a person, and refusing `abcde fghij` for a code issued as
   `ABCDE-FGHIJ` would be refusing the right code. */

const (
	recoveryCodes    = 10
	recoveryLength   = 10 // characters, before the separator
	recoveryAlphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
)

// ErrNoRecoveryCode is a code that is not among this account's unspent ones. It
// says nothing about whether the account has any: telling those apart would
// answer a question the person asking cannot act on.
var ErrNoRecoveryCode = errors.New("identity: that is not a recovery code for this account")

// IssueRecoveryCodes replaces the account's set and returns the new codes.
//
// REPLACES, NOT ADDS. A set that grows would mean a code printed two years ago
// still works after somebody reissued because they thought the old ones were
// compromised — which is the exact expectation reissuing creates and the exact
// thing it would fail to do.
//
// The codes come back in plain text here and nowhere else, ever.
func (s *Store) IssueRecoveryCodes(ctx context.Context, accountID uuid.UUID) ([]string, error) {
	codes := make([]string, 0, recoveryCodes)
	hashes := make([][]byte, 0, recoveryCodes)
	for range recoveryCodes {
		code, err := recoveryCode()
		if err != nil {
			return nil, err
		}
		codes = append(codes, code)
		hashes = append(hashes, recoveryHash(code))
	}

	/* ONE TRANSACTION, because the window between clearing the old set and
	   writing the new one is a window with no way back into the account at
	   all. */
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("identity: issuing recovery codes: %w", err)
	}
	defer func() { _ = tx.Rollback(ctx) }()

	if _, err := tx.Exec(ctx,
		`DELETE FROM account_recovery_codes WHERE account_id = $1`, accountID); err != nil {
		return nil, fmt.Errorf("identity: clearing the old recovery codes: %w", err)
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO account_recovery_codes (account_id, code_hash)
		SELECT $1, h FROM unnest($2::bytea[]) AS h
	`, accountID, hashes); err != nil {
		return nil, fmt.Errorf("identity: writing recovery codes: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("identity: issuing recovery codes: %w", err)
	}
	return codes, nil
}

// SpendRecoveryCode marks one used, and answers whether it was there to spend.
//
// THE UPDATE IS THE CHECK. Read-then-write would let two requests carrying the
// same code both find it unspent — which is a code that works twice, and a
// recovery code that works twice is a recovery code somebody else can still
// use after the person who owned it did.
func (s *Store) SpendRecoveryCode(ctx context.Context, accountID uuid.UUID, code string) error {
	tag, err := s.pool.Exec(ctx, `
		UPDATE account_recovery_codes SET used_at = now()
		 WHERE account_id = $1 AND code_hash = $2 AND used_at IS NULL
	`, accountID, recoveryHash(code))
	if err != nil {
		return fmt.Errorf("identity: spending a recovery code: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrNoRecoveryCode
	}
	return nil
}

// RecoveryCodesLeft is how many are unspent, for a screen to say so before it
// is the last one.
func (s *Store) RecoveryCodesLeft(ctx context.Context, accountID uuid.UUID) (int, error) {
	var left int
	err := s.pool.QueryRow(ctx, `
		SELECT count(*) FROM account_recovery_codes
		 WHERE account_id = $1 AND used_at IS NULL
	`, accountID).Scan(&left)
	if err != nil {
		return 0, fmt.Errorf("identity: counting recovery codes: %w", err)
	}
	return left, nil
}

/* ---------- the code itself ---------- */

// recoveryCode is `XXXXX-XXXXX`, from the alphabet above.
func recoveryCode() (string, error) {
	raw := make([]byte, recoveryLength)
	if _, err := rand.Read(raw); err != nil {
		return "", fmt.Errorf("identity: no randomness for a recovery code: %w", err)
	}

	/* MODULO IS UNBIASED HERE and it is worth saying why rather than leaving a
	   reader to check: the alphabet is 32 characters, 256 is a whole multiple
	   of 32, so every character is equally likely. Change the alphabet to a
	   length that does not divide 256 and this needs rejection sampling. */
	out := make([]byte, 0, recoveryLength+1)
	for i, b := range raw {
		if i == recoveryLength/2 {
			out = append(out, '-')
		}
		out = append(out, recoveryAlphabet[int(b)%len(recoveryAlphabet)])
	}
	return string(out), nil
}

// recoveryHash is what the database stores, and what a typed code is compared
// as: upper case, no separator, SHA-256.
func recoveryHash(code string) []byte {
	folded := strings.ToUpper(strings.TrimSpace(code))
	folded = strings.ReplaceAll(folded, "-", "")
	folded = strings.ReplaceAll(folded, " ", "")
	sum := sha256.Sum256([]byte(folded))
	return sum[:]
}
