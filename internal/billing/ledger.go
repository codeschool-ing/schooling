package billing

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// The ledger: every movement of money, and none of them editable.
//
// # WHAT A ROW MEANS
//
// Money that MOVED, signed from our side: positive came in, negative went out.
// The sum over an account is what that person has net paid us. It is not what
// they owe — access is computed from the subscription, and a ledger that also
// answered "may they study" would be a second place the paywall could be read
// from.
//
// # A CORRECTION IS A NEW ROW
//
// The table refuses UPDATE and DELETE by trigger, so a refund is not an edit to
// the payment; it is a second row with the other sign, pointing at the first.
// Three rules make that pointer mean something, and they are checked here
// rather than in the schema because each is an aggregate over sibling rows:
//
//   - a reversal is the opposite sign of what it reverses
//   - in the same currency
//   - and never more, in total, than what it reverses
//
// The third is the one that matters: without it a hundred-real payment could be
// refunded twice for a hundred each, and the account's balance would say we
// took a hundred reais off somebody who paid us nothing.

// Kind is what a movement was. A closed list — see the migration for why there
// is no "other".
type Kind string

const (
	// KindPayment is money received.
	KindPayment Kind = "payment"
	// KindRefund is money sent back, at our initiative or the student's.
	KindRefund Kind = "refund"
	// KindChargeback is money taken back, at the card issuer's initiative. It
	// is separate from a refund because it means something different about the
	// student and the subscription: a refund is an agreement, a chargeback is a
	// dispute, and they cut access on different days.
	KindChargeback Kind = "chargeback"
	// KindAdjustment is a human writing a correction that no provider event
	// produced. It is audited where it is made; the row itself only records
	// that money did or did not move.
	KindAdjustment Kind = "adjustment"
)

var kinds = map[Kind]bool{
	KindPayment: true, KindRefund: true, KindChargeback: true, KindAdjustment: true,
}

// SourceManual is what `source` says for an entry no provider produced.
const SourceManual = "manual"

// Entry is one movement, as it was written.
type Entry struct {
	ID        uuid.UUID
	AccountID uuid.UUID
	Kind      Kind
	Amount    Money

	// Reverses is what this undoes, and is nil for a movement that undoes
	// nothing.
	Reverses *uuid.UUID

	// Source is the payment provider, or SourceManual. SourceRef is that
	// provider's own id for the event, and is empty for a manual entry.
	Source    string
	SourceRef string

	Memo       string
	OccurredAt time.Time
}

// The ways writing an entry can be refused. Each is its own error because each
// means something different to the caller: one is a retry that already
// succeeded, one is a bug, and one is a number that does not add up.
var (
	// ErrAlreadyRecorded is this provider event arriving a second time. It is
	// not a failure: a gateway retries a webhook whenever it does not hear back
	// in time, so this is the normal shape of a healthy integration. The
	// existing entry is returned with it.
	ErrAlreadyRecorded = errors.New("billing: that provider event is already in the ledger")

	// ErrNotAReversal is a reversal that does not undo what it points at — the
	// same sign, another currency, or more than is left.
	ErrNotAReversal = errors.New("billing: that does not reverse what it points at")

	// ErrNoSuchEntry is a reversal pointing at nothing.
	ErrNoSuchEntry = errors.New("billing: there is no such ledger entry")

	// ErrBadEntry is an entry that is not one: no account, an unknown kind, a
	// zero amount.
	ErrBadEntry = errors.New("billing: that is not a ledger entry")
)

// Ledger reads and writes the entries.
type Ledger struct{ pool *pgxpool.Pool }

// NewLedger is the ledger over a pool.
func NewLedger(pool *pgxpool.Pool) *Ledger { return &Ledger{pool: pool} }

// Record writes one movement and answers it as it was written.
//
// It is the only way a row gets into this table, and everything the schema
// cannot express is checked here — inside one transaction, with the entry being
// reversed locked for the duration, so that two refunds racing each other
// cannot both see a payment as un-refunded.
func (l *Ledger) Record(ctx context.Context, e Entry) (Entry, error) {
	if e.AccountID == uuid.Nil {
		return Entry{}, fmt.Errorf("%w: it belongs to nobody", ErrBadEntry)
	}
	if !kinds[e.Kind] {
		return Entry{}, fmt.Errorf("%w: %q is not a kind of movement", ErrBadEntry, e.Kind)
	}
	if !e.Amount.Valid() {
		return Entry{}, fmt.Errorf("%w: %w", ErrBadEntry, ErrAmount)
	}
	if e.Amount.IsZero() {
		return Entry{}, fmt.Errorf("%w: nothing moved", ErrBadEntry)
	}
	if e.Source == "" {
		return Entry{}, fmt.Errorf("%w: nothing says where it came from", ErrBadEntry)
	}

	written, err := l.write(ctx, e)

	// The unique index doing its job: this provider event is already recorded.
	// Answering with the entry that is already there is what lets a webhook
	// handler treat a retry as the success it is.
	//
	// THE LOOKUP IS OUT HERE, AFTER THE TRANSACTION HAS ENDED, and that is not
	// tidiness. Done inside, it would hold this connection while asking the
	// pool for a second one — and under the load this exists for, a gateway
	// retrying a delivery that is still running, every connection in the pool
	// would be holding one and waiting for another. The suite deadlocked on
	// exactly that before this was moved.
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" {
		if existing, found := l.bySourceRef(ctx, e.Source, e.SourceRef); found {
			return existing, ErrAlreadyRecorded
		}
		return Entry{}, ErrAlreadyRecorded
	}
	if err != nil {
		if errors.Is(err, ErrNotAReversal) || errors.Is(err, ErrNoSuchEntry) {
			return Entry{}, err
		}
		return Entry{}, fmt.Errorf("billing: recording a movement: %w", err)
	}
	return written, nil
}

// write is Record's transaction, and nothing outside it touches the pool.
func (l *Ledger) write(ctx context.Context, e Entry) (Entry, error) {
	tx, err := l.pool.Begin(ctx)
	if err != nil {
		return Entry{}, fmt.Errorf("billing: recording a movement: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	if e.Reverses != nil {
		if err := checkReversal(ctx, tx, e); err != nil {
			return Entry{}, err
		}
	}

	var ref *string
	if e.SourceRef != "" {
		ref = &e.SourceRef
	}

	written := e
	if err := tx.QueryRow(ctx, `
		INSERT INTO ledger_entries
			(account_id, kind, amount_cents, currency, reverses, source, source_ref, memo)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, occurred_at
	`, e.AccountID, string(e.Kind), e.Amount.Cents(), string(e.Amount.Currency()),
		e.Reverses, e.Source, ref, e.Memo,
	).Scan(&written.ID, &written.OccurredAt); err != nil {
		// Unwrapped, so that Record can read the driver's error class. Wrapping
		// it here would hide the one thing the caller above has to distinguish.
		return Entry{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Entry{}, fmt.Errorf("billing: recording a movement: %w", err)
	}
	return written, nil
}

// checkReversal holds the three rules a reversal has to obey. The row it
// reverses is locked, and so are that row's existing reversals — otherwise two
// refunds arriving together would each see the full amount as available.
func checkReversal(ctx context.Context, tx pgx.Tx, e Entry) error {
	var original int64
	var currency string
	err := tx.QueryRow(ctx, `
		SELECT amount_cents, currency FROM ledger_entries WHERE id = $1 FOR UPDATE
	`, *e.Reverses).Scan(&original, &currency)
	if errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("%w: %s", ErrNoSuchEntry, *e.Reverses)
	}
	if err != nil {
		return fmt.Errorf("billing: reading the entry being reversed: %w", err)
	}

	if Currency(currency) != e.Amount.Currency() {
		return fmt.Errorf("%w: it is in %s and the entry is in %s",
			ErrNotAReversal, e.Amount.Currency(), currency)
	}
	if (original > 0) == (e.Amount.Cents() > 0) {
		return fmt.Errorf("%w: both are %s", ErrNotAReversal, sign(original))
	}

	// What has already been taken off it. The lock above serialises this read
	// against another reversal of the same entry.
	var reversed int64
	if err := tx.QueryRow(ctx, `
		SELECT coalesce(sum(amount_cents), 0) FROM ledger_entries WHERE reverses = $1
	`, *e.Reverses).Scan(&reversed); err != nil {
		return fmt.Errorf("billing: reading what has already been reversed: %w", err)
	}

	// Magnitudes, because the two sides have opposite signs by now.
	left := abs(original) - abs(reversed)
	if abs(e.Amount.Cents()) > left {
		return fmt.Errorf("%w: %d cents of %d are left un-reversed and it is for %d",
			ErrNotAReversal, left, abs(original), abs(e.Amount.Cents()))
	}
	return nil
}

func sign(cents int64) string {
	if cents < 0 {
		return "money going out"
	}
	return "money coming in"
}

func abs(n int64) int64 {
	if n < 0 {
		return -n
	}
	return n
}

// bySourceRef finds the entry a provider event already produced. It runs on the
// pool rather than the failed transaction, which is aborted by the time this is
// asked.
func (l *Ledger) bySourceRef(ctx context.Context, source, ref string) (Entry, bool) {
	if ref == "" {
		return Entry{}, false
	}
	rows, err := l.pool.Query(ctx, entryColumns+`
		FROM ledger_entries WHERE source = $1 AND source_ref = $2
	`, source, ref)
	if err != nil {
		return Entry{}, false
	}
	entries, err := scanEntries(rows)
	if err != nil || len(entries) != 1 {
		return Entry{}, false
	}
	return entries[0], true
}

// Of answers one person's movements, newest first.
func (l *Ledger) Of(ctx context.Context, accountID uuid.UUID) ([]Entry, error) {
	rows, err := l.pool.Query(ctx, entryColumns+`
		FROM ledger_entries WHERE account_id = $1 ORDER BY occurred_at DESC, id
	`, accountID)
	if err != nil {
		return nil, fmt.Errorf("billing: reading a ledger: %w", err)
	}
	entries, err := scanEntries(rows)
	if err != nil {
		return nil, fmt.Errorf("billing: reading a ledger: %w", err)
	}
	return entries, nil
}

// ErrMixedCurrencies is an account whose movements are not all in one money.
// It is possible — somebody who paid in reais and then moved abroad — and it
// has no single balance, so Balance refuses rather than picking one.
var ErrMixedCurrencies = errors.New("billing: this account has movements in more than one currency")

// Balance answers what one person has net paid, in one currency.
//
// It is computed by summing the rows rather than kept in a column. A stored
// balance is a second source of truth that goes wrong silently — and the row
// count per person here is a handful a year, so there is nothing to gain by it.
func (l *Ledger) Balance(ctx context.Context, accountID uuid.UUID) (Money, error) {
	rows, err := l.pool.Query(ctx, `
		SELECT currency, sum(amount_cents) FROM ledger_entries
		WHERE account_id = $1 GROUP BY currency
	`, accountID)
	if err != nil {
		return Money{}, fmt.Errorf("billing: totalling a ledger: %w", err)
	}
	defer rows.Close()

	var found []Money
	for rows.Next() {
		var currency string
		var cents int64
		if err := rows.Scan(&currency, &cents); err != nil {
			return Money{}, fmt.Errorf("billing: totalling a ledger: %w", err)
		}
		amount, err := New(cents, Currency(currency))
		if err != nil {
			return Money{}, fmt.Errorf("billing: totalling a ledger: %w", err)
		}
		found = append(found, amount)
	}
	if err := rows.Err(); err != nil {
		return Money{}, fmt.Errorf("billing: totalling a ledger: %w", err)
	}

	switch len(found) {
	case 0:
		// Nobody has paid anything, which is not an error and not a currency
		// either. The caller says which money it is asking about.
		return Money{}, nil
	case 1:
		return found[0], nil
	default:
		return Money{}, ErrMixedCurrencies
	}
}

const entryColumns = `
	SELECT id, account_id, kind, amount_cents, currency, reverses, source,
	       coalesce(source_ref, ''), memo, occurred_at
`

func scanEntries(rows pgx.Rows) ([]Entry, error) {
	defer rows.Close()

	var out []Entry
	for rows.Next() {
		var e Entry
		var kind, currency string
		var cents int64
		if err := rows.Scan(&e.ID, &e.AccountID, &kind, &cents, &currency,
			&e.Reverses, &e.Source, &e.SourceRef, &e.Memo, &e.OccurredAt); err != nil {
			return nil, err
		}

		amount, err := New(cents, Currency(currency))
		if err != nil {
			return nil, err
		}
		e.Kind, e.Amount = Kind(kind), amount
		out = append(out, e)
	}
	return out, rows.Err()
}
