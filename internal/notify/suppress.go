package notify

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

/* Who this platform may not write to, and how it finds out.

   IT SENT FOR A WHILE WITHOUT LISTENING. An address that refuses us
   permanently — the mailbox is gone, the receiving side blocklists us, the
   person pressed "this is spam" — went on being written to, and every attempt
   after the first is a mark against the domain with the providers that decide
   whether anybody else's mail arrives. One unreachable address costs one person
   a link. A hundred attempts at it costs every future student their inbox.

   # THE LIST HOLDS HASHES

   See the migration for the whole argument. The short of it: this is the one
   record that has to survive an erasure, and holding the address would mean
   holding a person's data after they asked us not to. A SHA-256 answers "may I
   write to THIS address" exactly, and answers nothing else. */

// Reason is why an address was suppressed. All three mean the same refusal.
type Reason string

const (
	// HardBounce is an address or a domain that does not exist.
	HardBounce Reason = "hard_bounce"
	// Blocked is the receiving side refusing us for this address.
	Blocked Reason = "blocked"
	// Complaint is somebody marking us as spam, which is the strongest of the
	// three as a signal and identical to the others as an instruction.
	Complaint Reason = "complaint"
)

// ErrNotPermanent is a reason that does not suppress anything.
//
// A SOFT BOUNCE IS THE ONE THIS EXISTS FOR. A full mailbox or a provider having
// an afternoon is not a refusal, and treating it as one would have suppressed
// every address at a whole provider during the outage of 27 August 2026.
var ErrNotPermanent = errors.New("notify: that is not a permanent refusal")

// Suppressions is the list, over a database.
type Suppressions struct{ pool *pgxpool.Pool }

func NewSuppressions(pool *pgxpool.Pool) *Suppressions { return &Suppressions{pool: pool} }

/*
Bar records that an address refused us, and answers whether it was already on
the list.

	IT IS AN UPSERT AND NOT AN INSERT, because a provider retries a webhook it
	did not hear back from: the same event arriving twice is the normal case. A
	repeat bumps the count and the date and changes nothing else — the FIRST
	reason is kept, because all three mean the same instruction and which one it
	was is a support conversation rather than a decision.
*/
func (s *Suppressions) Bar(ctx context.Context, address string, why Reason) (bool, error) {
	switch why {
	case HardBounce, Blocked, Complaint:
	default:
		return false, fmt.Errorf("%w: %q", ErrNotPermanent, why)
	}

	hash, ok := fingerprint(address)
	if !ok {
		return false, ErrNoAddress
	}

	var first bool
	err := s.pool.QueryRow(ctx, `
		INSERT INTO mail_suppressions (address_hash, reason)
		VALUES ($1, $2)
		ON CONFLICT (address_hash) DO UPDATE
		   SET last_seen_at = now(), times = mail_suppressions.times + 1
		RETURNING times = 1
	`, hash, string(why)).Scan(&first)

	if err != nil {
		return false, fmt.Errorf("notify: barring an address: %w", err)
	}
	return first, nil
}

// Barred answers whether this address has refused us.
//
// AN ERROR IS NOT A "NO". A database that cannot be read is not permission to
// write to somebody who told us to stop, so the caller gets the error and
// decides — and the one caller there is treats it as a refusal.
func (s *Suppressions) Barred(ctx context.Context, address string) (bool, error) {
	hash, ok := fingerprint(address)
	if !ok {
		return false, ErrNoAddress
	}

	var barred bool
	if err := s.pool.QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM mail_suppressions WHERE address_hash = $1)`,
		hash).Scan(&barred); err != nil {
		return false, fmt.Errorf("notify: reading the suppression list: %w", err)
	}
	return barred, nil
}

// ErrNoAddress is an empty address, from either direction. It is a bug in the
// caller and reads like one rather than hashing the empty string and answering
// confidently about it.
var ErrNoAddress = errors.New("notify: no address")

/*
fingerprint is what the row holds.

	LOWERCASED AND TRIMMED FIRST, because `Ana@Example.tld ` and
	`ana@example.tld` are one mailbox and would otherwise be two rows — one of
	them barred and the other written to. `identity.NormaliseEmail` does the same
	thing for the same reason; this does not call it, because `notify` does not
	import `identity` and must not start.

	PLAIN SHA-256, no salt and no stretching. A salt would make the list
	unsearchable by us as well, which is the one thing it has to be; and the
	input is an address rather than something a person chose, so there is no
	dictionary a work factor would slow down that is not already trivial. What
	this buys is not secrecy against an attacker with the database — it is that
	the table holds no address to leak, to export, or to have to erase.
*/
func fingerprint(address string) ([]byte, bool) {
	trimmed := strings.ToLower(strings.TrimSpace(address))
	if trimmed == "" {
		return nil, false
	}
	sum := sha256.Sum256([]byte(trimmed))
	return sum[:], true
}
