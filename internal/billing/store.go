package billing

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// The subscription, on disk: one row of state, one append-only log beside it.
//
// # WHY THE STATE IS A ROW AND THE HISTORY IS A LOG
//
// The paywall reads the state on every request and has to be one indexed
// lookup, not a fold over a history. And when somebody says "I was locked out
// on Tuesday and I had paid", the answer is in the log — a mutable row alone
// would have overwritten the only evidence of what happened.
//
// It is the same arrangement as practice_state beside practice_review, for the
// same reason.
//
// # NOTHING HERE DECIDES ANYTHING
//
// Every transition goes through Advance and Settle, which are pure. This file
// reads a row, asks them, and writes the answer down. A store that also decided
// would be a second implementation of the state machine, in SQL, with no tests
// of its own.

// ScopeEverything is what `scope` says while one subscription covers every
// school (N-02). The column exists so that can narrow later (N-03).
const ScopeEverything = "all"

// ErrNoSubscription is somebody who has never paid. It is not an error in the
// paywall's sense — it is the ordinary state of most people — but it is
// distinct from a subscription that exists and opens nothing, and the caller
// usually wants to know which.
var ErrNoSubscription = errors.New("billing: this account has no subscription")

/*
ErrNoPrice is a subscription somebody tried to start without saying what it was
sold at.

	IT IS A REFUSAL AND NOT A DEFAULT. There is no sensible price to fall back
	to: the current one is the guess this whole arrangement exists to remove, and
	zero would be a free subscription written as if it were paid.
*/
var ErrNoPrice = errors.New("billing: a subscription has to say which price it was bought at")

// Store reads and writes subscriptions.
type Store struct{ pool *pgxpool.Pool }

// NewStore is the store over a pool.
func NewStore(pool *pgxpool.Pool) *Store { return &Store{pool: pool} }

// Held is a subscription as it is stored: the state machine's value, plus who
// it belongs to.
type Held struct {
	ID        uuid.UUID
	AccountID uuid.UUID
	Scope     string
	Subscription

	/* PriceID is the `school_prices` row this was bought at.

	   IT IS A UUID AND NOT A PRICE, because this module does not import the one
	   that owns that table and must not start: what it needs is a handle it can
	   store and hand back, and the amount is read by whoever draws or charges
	   it. `internal/architecture_test.go` holds that boundary.

	   IT IS THE TERM RUNNING NOW, AND IT MOVES WHEN ONE IS BOUGHT. `0036`
	   believed this row was frozen for the life of a subscription — that a
	   renewal charged whatever was stored here — and `0040` corrected it: the
	   terms of use promise the opposite, a price change applies to new
	   subscriptions AND TO RENEWALS with thirty days' notice, never
	   retroactively to a term that is running.

	   So a subscription is REUSED across years and several purchases, and this
	   is the last price its holder agreed to. Nothing is lost by moving it: the
	   purchase at the old price is a `checkout_intents` row and a line in
	   `subscription_events`, both of which keep their own and are never
	   rewritten. Leaving it frozen was what made an account screen quote a
	   figure from three years ago as the thing somebody just bought. */
	PriceID uuid.UUID

	StartedAt time.Time
	UpdatedAt time.Time
}

// Of answers somebody's subscription, SETTLED — so a cancellation whose period
// ran out reads as ended rather than as cancelled, without anything having had
// to run at midnight.
//
// THE SETTLEMENT IS NOT WRITTEN BACK HERE. A read that wrote would turn every
// page load into a write, and would make the answer depend on whether somebody
// had looked. The row is brought up to date by Settle below, which a job calls;
// until then this is the truthful reading of it.
func (s *Store) Of(ctx context.Context, accountID uuid.UUID, scope string, now time.Time) (Held, error) {
	held, err := s.read(ctx, s.pool, accountID, scope)
	if err != nil {
		return Held{}, err
	}
	held.Subscription = Settle(held.Subscription, now)
	return held, nil
}

// Opens is the paywall's whole question, and the answer for somebody with no
// subscription at all is no.
//
// IT IS FAIL-CLOSED ON AN ERROR TOO. A database that cannot be read is not a
// reason to open a paid course: the alternative is an outage that quietly makes
// everything free, which is the one failure a paywall cannot have.
func (s *Store) Opens(ctx context.Context, accountID uuid.UUID, now time.Time) (bool, error) {
	held, err := s.Of(ctx, accountID, ScopeEverything, now)
	if errors.Is(err, ErrNoSubscription) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return Opens(held.Subscription), nil
}

// Begin starts a subscription for somebody who has none, or revives one that
// lapsed. Either way it is EventPaid: money is the only thing that starts a
// subscription (N-10).
//
// `now` is passed in rather than read from a clock here, as it is on every
// method of this store that depends on one. A subscription is entirely about
// dates, and one that could only be tested by waiting until next year would not
// be tested.
func (s *Store) Begin(ctx context.Context, accountID uuid.UUID, scope string,
	model Model, priceID uuid.UUID, now time.Time, termMonths int,
	ledgerEntry *uuid.UUID) (Held, error) {

	if scope == "" {
		scope = ScopeEverything
	}

	/* A SUBSCRIPTION WITHOUT A PRICE IS REFUSED HERE RATHER THAN BY THE COLUMN.

	   The column is NOT NULL, so this would fail either way — but it would fail
	   as a constraint violation from inside a transaction, in a caller that has
	   just taken somebody's money. Refusing before any of that says which
	   argument was missing. */
	if priceID == uuid.Nil {
		return Held{}, ErrNoPrice
	}
	if termMonths < 1 {
		return Held{}, fmt.Errorf("%w: a term of %d months buys nothing",
			ErrNoPrice, termMonths)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Held{}, fmt.Errorf("billing: starting a subscription: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	// Locked, because two payments arriving together for somebody with no
	// subscription would otherwise both insert — and the unique index would
	// turn the loser into an error rather than the payment it is.
	existing, err := s.read(ctx, tx, accountID, scope)
	switch {
	case err == nil:
		/* THERE IS ONE ALREADY, and a payment on it is a transition rather than
		   a new subscription — which is what keeps progress and history
		   attached to the same row.

		   TIME IS ADDED AND NEVER REPLACED. This used to be handed a date the
		   caller had computed as `now + term`, and a subscriber who paid before
		   their term ran out had their end date moved BACKWARDS: twelve months
		   into two years, buying another year took them from twenty-four months
		   out to twelve. They paid twice and came away with less.

		   Nothing stops that purchase — `Checkouts.Open` asks about the address
		   and the method and not about what somebody already holds — so an early
		   renewal is a thing this platform accepts and had to handle.

		   THE TERM AND NOT THE DATE IS WHAT CROSSES THIS BOUNDARY, so that the
		   addition happens HERE, with the row locked and its current end in
		   hand. A caller cannot compute it: it would have to read the row first,
		   outside this transaction, and act on what it said a moment ago. */
		from := now
		if existing.PaidThrough.After(now) {
			from = existing.PaidThrough
		}
		/* AND IT IS COMMITTED HERE, WHICH IT WAS NOT.

		   `apply` deliberately does not commit — its own comment says the caller
		   owns the transaction, because `Advance` needs the read and the write
		   in one — and this branch returned its value straight out. The deferred
		   rollback above then threw the whole renewal away: the subscription
		   kept its old end date, no line was written to the log, and the value
		   handed back said otherwise, because `apply` builds it in memory.

		   IT PASSED EVERY TEST FOR AS LONG AS IT EXISTED. All of them asserted
		   on the `Held` that came back, which was correct; nothing read the row
		   afterwards. What found it was a test written for another change that
		   happened to `SELECT price_id` from the table.

		   In production this is a renewal that took somebody's money, wrote the
		   ledger, marked the checkout paid — and did not extend their access by
		   a day. */
		renewed, err := s.apply(ctx, tx, existing, EventPaid, now,
			from.AddDate(0, termMonths, 0), priceID, ledgerEntry)
		if err != nil {
			return Held{}, err
		}
		if err := tx.Commit(ctx); err != nil {
			return Held{}, fmt.Errorf("billing: renewing a subscription: %w", err)
		}
		return renewed, nil
	case errors.Is(err, ErrNoSubscription):
	default:
		return Held{}, err
	}

	// Nobody had one, so the term starts today.
	fresh, err := Start(model, now.AddDate(0, termMonths, 0))
	if err != nil {
		return Held{}, err
	}

	held := Held{AccountID: accountID, Scope: scope, Subscription: fresh, PriceID: priceID}
	if err := tx.QueryRow(ctx, `
		INSERT INTO subscriptions (account_id, scope, model, state, paid_through, price_id)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, started_at, updated_at
	`, accountID, scope, string(fresh.Model), string(fresh.State), fresh.PaidThrough, priceID,
	).Scan(&held.ID, &held.StartedAt, &held.UpdatedAt); err != nil {
		return Held{}, fmt.Errorf("billing: starting a subscription: %w", err)
	}

	if err := logTransition(ctx, tx, held, EventPaid, "", ledgerEntry); err != nil {
		return Held{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return Held{}, fmt.Errorf("billing: starting a subscription: %w", err)
	}
	return held, nil
}

/*
ErrNothingToExtend is a grant aimed at somebody who has no subscription.

	IT IS A REFUSAL AND NOT A FREE ONE. Extending a term and giving somebody a
	term are different acts: the second has to say what it was sold at —
	`price_id` is NOT NULL, and it is the column that keeps a March invoice
	explicable in November — and there is no honest value for a subscription
	nobody bought. Inventing one would put a price in the books that nobody
	agreed to and nobody paid.

	So an operator can make good on a term that exists and cannot conjure one.
	Comping somebody who has never subscribed is a different feature, and it
	needs an offer priced at zero rather than a grant pretending to be one.
*/
var ErrNothingToExtend = errors.New("billing: there is no subscription to extend")

/*
Grant gives time that nobody paid for.

	IT IS `Begin` WITHOUT THE MONEY, and it is a method of its own rather than an
	argument to that one because the two are asked by different people for
	different reasons: `Begin` is a payment settling, and this is somebody in
	the console making good on a fortnight the platform lost.

	THE ARITHMETIC IS THE SAME AND HAS TO BE. Time is ADDED to what is there,
	from the later of today and the current end — which is `Begin`'s rule, and
	is what stops a goodwill fortnight from moving somebody's end date backwards
	by eleven months. It happens here, inside the transaction that locks the
	row, for the reason `Begin` gives: a caller cannot compute it without
	reading the row first, outside this transaction, and acting on what it said
	a moment ago.

	NO LEDGER ROW GOES WITH IT, and that is the point of the separate event. No
	money moved. An operator who wants the gift to appear in the books writes an
	adjustment, which is a deliberate second act and says so.
*/
func (s *Store) Grant(ctx context.Context, accountID uuid.UUID, scope string,
	days int, now time.Time) (Held, error) {

	if scope == "" {
		scope = ScopeEverything
	}
	if days < 1 {
		return Held{}, fmt.Errorf("%w: %d days is not time to give", ErrNoPrice, days)
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Held{}, fmt.Errorf("billing: granting time: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	existing, err := s.read(ctx, tx, accountID, scope)
	switch {
	case errors.Is(err, ErrNoSubscription):
		return Held{}, ErrNothingToExtend
	case err != nil:
		return Held{}, err
	}

	from := now
	if existing.PaidThrough.After(now) {
		from = existing.PaidThrough
	}

	/* `uuid.Nil` FOR THE PRICE, so the stored one is left where it is. A grant
	   is not somebody agreeing to a number, and moving the column would rewrite
	   what this person's running term was sold at with nothing to replace it. */
	granted, err := s.apply(ctx, tx, existing, EventGranted, now,
		from.AddDate(0, 0, days), uuid.Nil, nil)
	if err != nil {
		return Held{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return Held{}, fmt.Errorf("billing: granting time: %w", err)
	}
	return granted, nil
}

// Advance applies an event to somebody's subscription and writes the answer.
//
// `paidThrough` is what a payment bought and is ignored by every other event.
func (s *Store) Advance(ctx context.Context, accountID uuid.UUID, scope string,
	e Event, now, paidThrough time.Time, ledgerEntry *uuid.UUID) (Held, error) {

	if scope == "" {
		scope = ScopeEverything
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return Held{}, fmt.Errorf("billing: advancing a subscription: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	held, err := s.read(ctx, tx, accountID, scope)
	if err != nil {
		return Held{}, err
	}

	/* NO PRICE CROSSES THIS ONE. Every event Advance carries — a refund, a
	   chargeback, a cancellation, a term running out — is something happening TO
	   a subscription rather than something being bought, so there is no row for
	   it to have been bought at and `uuid.Nil` leaves the stored one alone.
	   Buying is Begin's, and Begin is the only caller that has a price. */
	updated, err := s.apply(ctx, tx, held, e, now, paidThrough, uuid.Nil, ledgerEntry)
	if err != nil {
		return Held{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return Held{}, fmt.Errorf("billing: advancing a subscription: %w", err)
	}
	return updated, nil
}

/*
apply runs the state machine and writes both halves. It does NOT commit: the
caller owns the transaction, because Begin needs the read and the write in one
and so does Advance.

	`priceID` IS THE ROW THIS EVENT WAS PAID AT, and `uuid.Nil` for every event
	that is not a payment — see Advance's caller comment. It is written rather
	than kept because a subscription is REUSED: one row lives for years across
	several purchases, and the price on it has to be the last one somebody
	agreed to.
*/
func (s *Store) apply(ctx context.Context, tx pgx.Tx, held Held,
	e Event, now, paidThrough time.Time, priceID uuid.UUID, ledgerEntry *uuid.UUID) (Held, error) {

	// SETTLED FIRST, so an event lands on the subscription as it actually is. A
	// payment arriving on a cancellation whose period ran out three weeks ago is
	// a revival, and it would be read as an ordinary renewal without this.
	was := Settle(held.Subscription, now)

	next, err := Advance(was, e, now, paidThrough)
	if err != nil {
		return Held{}, err
	}

	held.Subscription = next

	/* THE PRICE MOVES FORWARD WITH THE PAYMENT, which `0040` settled and this
	   did not do. The terms of use promise that a price change applies to new
	   subscriptions AND TO RENEWALS with thirty days' notice — never
	   retroactively to a term that is running — so somebody renewing has just
	   agreed to whatever is current, and leaving the old id here would make
	   their account screen quote a figure from a purchase two years ago as the
	   thing they just bought.

	   WHAT IT DOES NOT DO IS REWRITE HISTORY. The purchase they made at the old
	   price is a `checkout_intents` row and a line in the log below, both of
	   which keep their own price and are never touched again. This column is the
	   CURRENT standing of a subscription, and every other one is a record. */
	if priceID != uuid.Nil {
		held.PriceID = priceID
	}

	if err := tx.QueryRow(ctx, `
		UPDATE subscriptions
		SET state = $2, paid_through = $3, price_id = $4, updated_at = now()
		WHERE id = $1 RETURNING updated_at
	`, held.ID, string(next.State), next.PaidThrough, held.PriceID,
	).Scan(&held.UpdatedAt); err != nil {
		return Held{}, fmt.Errorf("billing: writing a subscription: %w", err)
	}

	if err := logTransition(ctx, tx, held, e, was.State, ledgerEntry); err != nil {
		return Held{}, err
	}
	return held, nil
}

// Settle brings lapsed subscriptions up to date and answers how many moved.
//
// IT IS A JOB AND NOT A READ. Reading settles in memory so the answer is always
// truthful; this is what makes the row match, so that a query for "who is
// active" means something and a report is not counting cancellations that ended
// weeks ago.
//
// It is safe to run at any time and any number of times: settling something
// already settled changes nothing, so a job that runs twice or not for a week
// produces the same rows.
func (s *Store) Settle(ctx context.Context, now time.Time) (int, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, account_id, scope, model, state, paid_through, price_id,
		       started_at, updated_at
		FROM subscriptions
		WHERE paid_through <= $1 AND state IN ('active', 'cancelled')
	`, now)
	if err != nil {
		return 0, fmt.Errorf("billing: settling: %w", err)
	}

	due, err := scanHeld(rows)
	if err != nil {
		return 0, fmt.Errorf("billing: settling: %w", err)
	}

	moved := 0
	for _, held := range due {
		settled := Settle(held.Subscription, now)
		if settled.State == held.State {
			continue
		}

		tag, err := s.pool.Exec(ctx, `
			UPDATE subscriptions SET state = $2, updated_at = now()
			WHERE id = $1 AND state = $3
		`, held.ID, string(settled.State), string(held.State))
		if err != nil {
			return moved, fmt.Errorf("billing: settling %s: %w", held.ID, err)
		}
		if tag.RowsAffected() == 0 {
			// Something else moved it between the read and the write. Its
			// transition is the one that happened, and this one is not news.
			continue
		}

		if _, err := s.pool.Exec(ctx, `
			INSERT INTO subscription_events
				(subscription_id, account_id, event, from_state, to_state)
			VALUES ($1, $2, 'elapsed', $3, $4)
		`, held.ID, held.AccountID, string(held.State), string(settled.State)); err != nil {
			return moved, fmt.Errorf("billing: recording a lapse: %w", err)
		}
		moved++
	}
	return moved, nil
}

// Renewing answers which instalment plans need a new sale before they lapse
// (N-08). Nothing renews one on its own, so somebody has to be told.
func (s *Store) Renewing(ctx context.Context, now time.Time, notice time.Duration) ([]Held, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id, account_id, scope, model, state, paid_through, price_id,
		       started_at, updated_at
		FROM subscriptions
		WHERE model = 'instalments' AND state = 'active' AND paid_through <= $1
		ORDER BY paid_through
	`, now.Add(notice))
	if err != nil {
		return nil, fmt.Errorf("billing: finding what needs renewing: %w", err)
	}

	// The SQL narrows and the state machine decides, so the query cannot drift
	// from Renewing's answer without this loop dropping the rows it disagrees on.
	found, err := scanHeld(rows)
	if err != nil {
		return nil, fmt.Errorf("billing: finding what needs renewing: %w", err)
	}

	var out []Held
	for _, held := range found {
		if Renewing(held.Subscription, now, notice) {
			out = append(out, held)
		}
	}
	return out, nil
}

// History is every transition a subscription has been through, newest first.
func (s *Store) History(ctx context.Context, accountID uuid.UUID) ([]Transition, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT event, from_state, to_state, ledger_entry_id, occurred_at,
		       price_id, paid_through
		FROM subscription_events WHERE account_id = $1 ORDER BY occurred_at DESC, id
	`, accountID)
	if err != nil {
		return nil, fmt.Errorf("billing: reading a subscription's history: %w", err)
	}
	defer rows.Close()

	var out []Transition
	for rows.Next() {
		var t Transition
		var event, from, to string
		if err := rows.Scan(&event, &from, &to, &t.LedgerEntryID, &t.OccurredAt,
			&t.PriceID, &t.PaidThrough); err != nil {
			return nil, fmt.Errorf("billing: reading a subscription's history: %w", err)
		}
		t.Event, t.From, t.To = Event(event), State(from), State(to)
		out = append(out, t)
	}
	return out, rows.Err()
}

// Transition is one line of that history: both sides, and what caused it.
type Transition struct {
	Event Event
	// From is "none" on the line that started the subscription, which came from
	// nowhere rather than from a state. A word rather than a null, because a log
	// is read by a person.
	From          State
	To            State
	LedgerEntryID *uuid.UUID
	OccurredAt    time.Time

	/* WHAT IT COST AND WHERE IT LEFT THE TERM, both nil on a line written
	   before `0043` added the columns. Nil is a real answer — "the log did not
	   record this then" — and a screen says so rather than filling it in: a
	   backfill would have had to guess, and a guessed price on a purchase is
	   the confusion the price column exists to remove. */
	PriceID     *uuid.UUID
	PaidThrough *time.Time
}

/* ---------- reading ---------- */

// queryer is whatever can run a query — the pool or a transaction. Defined here
// because the consumer defines the interface (X-01), and because Begin has to
// read inside its own transaction while Of reads outside one.
type queryer interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
}

// read finds one subscription. Inside a transaction it LOCKS the row, which is
// what serialises two events arriving for the same person at once.
func (s *Store) read(ctx context.Context, q queryer, accountID uuid.UUID, scope string) (Held, error) {
	if scope == "" {
		scope = ScopeEverything
	}

	sql := `
		SELECT id, account_id, scope, model, state, paid_through, price_id,
		       started_at, updated_at
		FROM subscriptions WHERE account_id = $1 AND scope = $2
	`
	if _, inTransaction := q.(pgx.Tx); inTransaction {
		sql += " FOR UPDATE"
	}

	rows, err := q.Query(ctx, sql, accountID, scope)
	if err != nil {
		return Held{}, fmt.Errorf("billing: reading a subscription: %w", err)
	}
	found, err := scanHeld(rows)
	if err != nil {
		return Held{}, fmt.Errorf("billing: reading a subscription: %w", err)
	}
	if len(found) == 0 {
		return Held{}, ErrNoSubscription
	}
	return found[0], nil
}

func scanHeld(rows pgx.Rows) ([]Held, error) {
	defer rows.Close()

	var out []Held
	for rows.Next() {
		var h Held
		var model, state string
		if err := rows.Scan(&h.ID, &h.AccountID, &h.Scope, &model, &state,
			&h.PaidThrough, &h.PriceID, &h.StartedAt, &h.UpdatedAt); err != nil {
			return nil, err
		}
		h.Model, h.State = Model(model), State(state)
		out = append(out, h)
	}
	return out, rows.Err()
}

func logTransition(ctx context.Context, tx pgx.Tx, held Held,
	e Event, from State, ledgerEntry *uuid.UUID) error {

	/* THE PRICE AND THE DATE ARE TAKEN FROM `held` AND NOT PASSED IN, which is
	   what makes them impossible to get wrong: every caller has already applied
	   the transition to it, so these two are the standing AFTER the event by
	   construction rather than by a caller remembering to pass the new values
	   instead of the old ones. */
	var priceID *uuid.UUID
	if held.PriceID != uuid.Nil {
		priceID = &held.PriceID
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO subscription_events
			(subscription_id, account_id, event, from_state, to_state, ledger_entry_id,
			 price_id, paid_through)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`, held.ID, held.AccountID, string(e), fromOrStart(from), string(held.State), ledgerEntry,
		priceID, held.PaidThrough,
	); err != nil {
		return fmt.Errorf("billing: recording a transition: %w", err)
	}
	return nil
}

// fromOrStart names where the first line of a history came from. The column is
// NOT NULL because every other line has both sides, and a word is more legible
// in a log than a null.
func fromOrStart(from State) string {
	if from == "" {
		return "none"
	}
	return string(from)
}
