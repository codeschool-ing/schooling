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

/*
What comes off for paying a way that costs us less to receive.

# IT WAS A CONSTANT AND THE CONSTANT SAID WHEN IT WOULD STOP BEING ONE

`PixDiscountBasisPoints` was five per cent, and `http.go` had already argued it
through K-13: the value has no right answer, so the case for setting it from the
console was real, and it lost to whether a March invoice stays explicable in
November. That comment ended with the condition for changing its mind —

	The day somebody wants to change it without a deploy, it becomes a dated row
	like the prices — not a column that can be overwritten.

— and that day came. `0045` is the table; this is the read and the write.

# THE SERIES ANSWERS A QUESTION MONEY DOES NOT

Worth saying plainly, because the obvious justification for dating this is the
wrong one. A past sale is already explicable without this table: the checkout
stores what was charged and points at the price row it was sold under, so any
discount that was actually taken is the difference between two recorded numbers.

What a series adds is the fortnight that sold NOTHING. A rate live for two weeks
with no takers leaves no trace at all in `checkout_intents`, and "did that do
anything" is precisely the question somebody asks about two weeks that sold
nothing.

# NO ROW IS NO DISCOUNT, AND THAT IS NOT THE SAME AS ZERO

Zero is a rate somebody chose; no row is a method nobody has discounted. They
come to the same charge and they are different facts, and the store refuses to
write a zero for exactly that reason — see `ErrNotADiscount`.
*/

// ErrNotADiscount is a rate the caller can fix by sending another.
var ErrNotADiscount = errors.New("billing: that is not a discount")

/*
MostBasisPoints is the ceiling, and it is in code rather than settable.

	IT GUARDS A TYPED DIGIT. The mistake this value can least afford is 5000
	where 500 was meant — an order of magnitude that turns a five per cent
	discount into a half-price sale, silently, on every Pix from that moment.
	There is no right answer to make configurable about that: it is a fence, and
	a fence somebody can move is a fence in the way rather than a fence.

	Half is chosen because it is far outside any rate this platform would offer
	and far inside the digit that would be an accident.
*/
const MostBasisPoints = 5000

// Discount is one row of the series.
type Discount struct {
	ID     uuid.UUID
	Scope  string
	Method Method

	// BasisPoints is hundredths of a per cent: 500 is five per cent. It is the
	// unit `Money.Percent` already takes, so nothing converts on the way.
	BasisPoints int

	From time.Time
}

// Discounts is the series, on disk.
type Discounts struct{ pool *pgxpool.Pool }

// NewDiscounts is the store over a pool.
func NewDiscounts(pool *pgxpool.Pool) *Discounts { return &Discounts{pool: pool} }

/*
InForce is what comes off a purchase paid this way right now.

	NO ROW IS NOT AN ERROR, which is the difference from `Prices.InForce`. A term
	nobody has priced cannot be bought at all, so its absence is refused; a
	method nobody has discounted is sold at the price, which is an ordinary
	offer. So this answers a zero-valued Discount and a nil error, and the
	caller takes nothing off.

	`effective_from <= now()` is the condition every read in this package uses: a
	rate dated ahead is representable and is not the offer until its day comes.
*/
func (d *Discounts) InForce(ctx context.Context, scope string, method Method) (Discount, error) {
	if scope == "" {
		scope = ScopeEverything
	}
	one := Discount{Scope: scope, Method: method}
	err := d.pool.QueryRow(ctx, `
		SELECT id, basis_points, effective_from FROM plan_discounts
		WHERE scope = $1 AND method = $2 AND effective_from <= now()
		ORDER BY effective_from DESC LIMIT 1
	`, scope, string(method)).Scan(&one.ID, &one.BasisPoints, &one.From)

	if errors.Is(err, pgx.ErrNoRows) {
		return Discount{}, nil
	}
	if err != nil {
		return Discount{}, fmt.Errorf("billing: reading the discount in force: %w", err)
	}
	return one, nil
}

/*
Set appends a rate and answers the one it replaces.

	APPENDED AND NEVER EDITED, for the reason `Prices.Set` is. A zero `was` is a
	method that had no discount before, which is a real state rather than a
	failure.

	SAVING THE SAME RATE AGAIN IS STILL A NEW ROW. The price screen makes this
	argument and it holds here identically: re-confirming a rate is a fact about
	the offer — "this is still what we take off, as of today" — and a series
	that dropped the repeats could not tell that from a rate nobody has touched
	since January.
*/
func (d *Discounts) Set(ctx context.Context, scope string, method Method,
	basisPoints int) (was Discount, err error) {

	if scope == "" {
		scope = ScopeEverything
	}
	if method != MethodPix && method != MethodCard {
		return Discount{}, fmt.Errorf("%w: %q is not a way to pay here", ErrNotADiscount, method)
	}
	if basisPoints <= 0 {
		return Discount{}, fmt.Errorf("%w: a discount takes something off, and %d takes "+
			"nothing — a method with no discount has no row at all rather than a rate of "+
			"nothing", ErrNotADiscount, basisPoints)
	}
	if basisPoints > MostBasisPoints {
		return Discount{}, fmt.Errorf("%w: %d basis points is more than half off, which is "+
			"a digit too many rather than an offer. If it is right, it is a price change",
			ErrNotADiscount, basisPoints)
	}

	tx, err := d.pool.Begin(ctx)
	if err != nil {
		return Discount{}, fmt.Errorf("billing: setting a discount: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	// What is in force at this instant, which is what the new row replaces.
	before := Discount{Scope: scope, Method: method}
	err = tx.QueryRow(ctx, `
		SELECT id, basis_points, effective_from FROM plan_discounts
		WHERE scope = $1 AND method = $2 AND effective_from <= now()
		ORDER BY effective_from DESC LIMIT 1
	`, scope, string(method)).Scan(&before.ID, &before.BasisPoints, &before.From)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		before = Discount{}
	case err != nil:
		return Discount{}, fmt.Errorf("billing: reading the discount in force: %w", err)
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO plan_discounts (scope, method, basis_points) VALUES ($1, $2, $3)
	`, scope, string(method), basisPoints); err != nil {
		return Discount{}, fmt.Errorf("billing: setting a discount: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Discount{}, fmt.Errorf("billing: setting a discount: %w", err)
	}
	return before, nil
}

// Series is every rate ever set for a scope, newest first, every method
// together — the half of an append-only table that a single number cannot show.
func (d *Discounts) Series(ctx context.Context, scope string) ([]Discount, error) {
	if scope == "" {
		scope = ScopeEverything
	}
	rows, err := d.pool.Query(ctx, `
		SELECT id, method, basis_points, effective_from FROM plan_discounts
		WHERE scope = $1 ORDER BY effective_from DESC, id
	`, scope)
	if err != nil {
		return nil, fmt.Errorf("billing: reading the discounts: %w", err)
	}
	defer rows.Close()

	out := make([]Discount, 0)
	for rows.Next() {
		one := Discount{Scope: scope}
		var method string
		if err := rows.Scan(&one.ID, &method, &one.BasisPoints, &one.From); err != nil {
			return nil, fmt.Errorf("billing: reading the discounts: %w", err)
		}
		one.Method = Method(method)
		out = append(out, one)
	}
	return out, rows.Err()
}
