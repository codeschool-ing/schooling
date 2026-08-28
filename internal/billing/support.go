package billing

import (
	"context"
	"errors"
	"fmt"
	"net/mail"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

/*
Where a student writes to use the seven days.

# WHY THIS IS IN `billing` AND NOT IN `console`

The console SETS it and this package DRAWS it, and the module boundary (X-02)
says neither may import the other. One of them has to own the row, and the rule
this repository already follows is that the module which publishes a value owns
it: `plan_prices` is here for the same reason, and `console.Plan` is the
function types `cmd` wires across.

It is a billing fact besides. The address exists because the terms of use
promise a withdrawal within a week of BUYING — art. 49 of the Código de Defesa
do Consumidor — and the only screen that draws it is the one that says what
somebody bought and until when. If it ever appears somewhere with nothing to do
with a sale, that is the day it moves.

# EMPTY IS A REAL ANSWER AT EVERY LEVEL

No row is the ordinary state of a deployment nobody has configured, and the
caller falls back to `SCHOOLING_SUPPORT_EMAIL`. Both empty is still allowed: the
notice then names the deadline and no address, which is worse than naming both
and much better than naming neither — knowing the date is worth something on its
own, and `0044` argues that at length.

So nothing here treats absence as a failure. `Now` answers an empty string and a
nil error for a platform that has never set one.
*/

// ErrNotAnAddress is a support address the caller can fix by sending another.
//
// IT IS A SENTENCE AND NOT A CODE because it crosses into a handler that may
// not import this package's types — `console.Support.Refused` is a predicate for
// exactly this, the same seam `Plan.Refused` uses — and what reaches the person
// typing is this text.
var ErrNotAnAddress = errors.New(
	"that is not an address somebody could write to. It is published to students as the " +
		"way to use the seven days the terms promise, so it has to be a real inbox " +
		"somebody reads — one address, no name in front of it")

// Support is the store over the one row.
type Support struct{ pool *pgxpool.Pool }

// NewSupport is the store over a pool.
func NewSupport(pool *pgxpool.Pool) *Support { return &Support{pool: pool} }

// Contact is the address and when it last moved. A zero `Since` is a platform
// that has never set one, which the caller draws as the fallback rather than as
// a date.
type Contact struct {
	Email string
	Since time.Time
}

/*
Now is the address the platform publishes, or empty when nobody has set one.

	IT IS READ PER REQUEST AND NOT AT START-UP, which is the whole point of
	moving it out of the environment: a value read once into a closure would
	need a new revision to take effect, and then the console form would be a
	control whose effect arrives at the next deployment. One row by primary key
	is the cheapest read this database does.
*/
func (s *Support) Now(ctx context.Context) (Contact, error) {
	var found Contact
	err := s.pool.QueryRow(ctx,
		`SELECT email, set_at FROM support_contact WHERE only_row`).
		Scan(&found.Email, &found.Since)

	if errors.Is(err, pgx.ErrNoRows) {
		// NOT AN ERROR. See the header: a platform that has never set one is
		// the ordinary first state, and the caller has a fallback for it.
		return Contact{}, nil
	}
	if err != nil {
		return Contact{}, fmt.Errorf("billing: reading where a student writes: %w", err)
	}
	return found, nil
}

/*
Set replaces the address and answers the one it replaced.

	REPLACED AND NOT APPENDED, which is the difference from a price. Money is
	effective-dated because a March invoice has to stay explicable in November
	(K-14); an address owes nothing like that, and "what was published in March"
	is answered by the audit log, which records both sides of every console
	write (K-01). `0044` makes that argument in full.

	IT ANSWERS WHAT WAS THERE so the caller can compare it against what it
	recorded a moment earlier. The plan handler does exactly this and logs a
	warning when the two disagree — somebody else changed it between the read
	and the write, and the audit entry then names a `before` that was already
	gone.
*/
func (s *Support) Set(ctx context.Context, email string) (was Contact, err error) {
	clean, err := address(email)
	if err != nil {
		return Contact{}, err
	}

	/* ONE TRANSACTION, SO THERE IS NO WINDOW between reading what was there and
	   replacing it. Two round trips would race any other operator, and the
	   answer this returns is what the caller compares against the audit entry
	   it wrote a moment ago — an answer that was already stale would defeat the
	   comparison it exists for.

	   A LOCKING READ AND NOT A CLEVER `RETURNING`. Postgres has no `OLD` in
	   RETURNING before 18, and a sub-SELECT there reads the statement's opening
	   snapshot — which does give the old row, by a rule nobody should have to
	   know to read this. `FOR UPDATE` says what it does. */
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Contact{}, fmt.Errorf("billing: setting where a student writes: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	var before Contact
	err = tx.QueryRow(ctx,
		`SELECT email, set_at FROM support_contact WHERE only_row FOR UPDATE`).
		Scan(&before.Email, &before.Since)

	// No row is the first write, and `before` stays zero: there was nothing
	// there, which the caller draws as "nothing" rather than as a blank address.
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return Contact{}, fmt.Errorf("billing: setting where a student writes: %w", err)
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO support_contact (only_row, email, set_at)
		VALUES (true, $1, now())
		ON CONFLICT (only_row) DO UPDATE
		    SET email = EXCLUDED.email, set_at = EXCLUDED.set_at`,
		clean); err != nil {

		return Contact{}, fmt.Errorf("billing: setting where a student writes: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Contact{}, fmt.Errorf("billing: setting where a student writes: %w", err)
	}
	return before, nil
}

/*
address is what this platform will publish, and it is deliberately narrow.

	IT REFUSES A DISPLAY NAME. `net/mail` happily parses `Support <a@b.c>`, and
	that string is drawn into a `mailto:` and into visible text on a page a
	student reads. One address, so that what the screen shows and what a mail
	client opens are the same thing.

	AND IT REFUSES A LIST, for the same reason and a sharper one: two addresses
	in one `mailto:` is a link half of whose recipients a person cannot see
	before they press send.

	WHAT IT DOES NOT DO IS DECIDE WHETHER ANYBODY READS THE BOX. Nothing here
	can, and a stricter regex would only refuse valid addresses — the real check
	is that somebody typed it into the console on purpose, and the audit entry
	says who.
*/
func address(typed string) (string, error) {
	clean := strings.TrimSpace(typed)
	if clean == "" {
		return "", ErrNotAnAddress
	}

	parsed, err := mail.ParseAddress(clean)
	if err != nil || parsed.Name != "" || !strings.EqualFold(parsed.Address, clean) {
		return "", ErrNotAnAddress
	}
	return strings.ToLower(clean), nil
}
