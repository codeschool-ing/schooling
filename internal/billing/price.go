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
What the subscription costs, as a series of dated rows.

# IT LIVED IN `tenant` AND THAT WAS THE PER-SCHOOL SHAPE

`school_prices` hung off a school, so the code that read and wrote it hung off
the school store. `0041` moved the table to the platform, for the reason that
migration gives at length: one subscription opens every school (N-02), so two
schools with two prices means the cheaper page sells the same thing.

With the table keyed by scope, the code follows it here. `tenant` answers what
a school looks like; what the platform charges is billing's, beside the
subscription it is charged for and the ledger it is paid into.

`tenant` still READS one number — the annual price, to draw the offer on a
school's page in one round trip. Reading a value is not owning it, and every
write, the whole series and the row a purchase points at are here.

# THE KEY IS (SCOPE, TERM) AND THE SERIES IS THE REST

`InForce` is the newest row for a scope and a term whose day has come. That is
one index reach, which matters because it is on the path of anything that draws
a price.

The currency is a property of the row rather than part of the key, which is
`0030`'s decision carried forward and `0041`'s paragraph on why it is not
widened yet.
*/

// Term is how long one purchase buys, in months.
//
// THEY ARE NAMES FOR NUMBERS AND NOT A TYPE. The column is an integer because
// `paid_through` is arithmetic on it, and a `Term` type would have to be
// converted back at every call. These exist so that a query reads `TermAnnual`
// rather than `12`, and so that the three products the roadmap names have one
// spelling between them.
const (
	// TermMonthly is the month abroad, where a card renews itself.
	TermMonthly = 1
	// TermAnnual is the year. It is what every price on the platform meant
	// before `0041`, because the interface has quoted it as "per year" since
	// before it was a table.
	TermAnnual = 12
	// TermBiennial is the two years. It cannot be a gateway subscription —
	// Asaas stops at yearly — so it is one charge for a term, renewed as a new
	// sale, which is `ModelInstalments`.
	TermBiennial = 24
)

// Price is one row of the series: what a term cost, from when.
type Price struct {
	ID         uuid.UUID
	Scope      string
	TermMonths int
	Cents      int
	Currency   string
	From       time.Time
}

// ErrNoOffer is a scope and term nobody has priced. It is not a failure in the
// usual sense — a term with no price is a term nobody can buy — but selling at
// a price that does not exist is not the alternative.
var ErrNoOffer = errors.New("billing: nothing is priced for that scope and term")

// ErrNotAPrice is a number or a currency the caller can fix by sending another.
var ErrNotAPrice = errors.New("billing: that is not a price")

// Prices is the series, on disk.
type Prices struct{ pool *pgxpool.Pool }

// NewPrices is the store over a pool.
func NewPrices(pool *pgxpool.Pool) *Prices { return &Prices{pool: pool} }

/*
InForce is the row a purchase of this term would be sold at right now.

	IT RETURNS THE ROW AND NOT ONLY THE NUMBER. A subscription has to point at
	the row it was bought at, or a rise in price silently rewrites what everybody
	already agreed to — and the table is append-only precisely so that pointing
	is possible.

	`effective_from <= now()` is the condition every read here uses: a price
	dated ahead is representable and is not the offer until its day comes.
*/
func (p *Prices) InForce(ctx context.Context, scope string, termMonths int) (Price, error) {
	if scope == "" {
		scope = ScopeEverything
	}
	one := Price{Scope: scope, TermMonths: termMonths}
	err := p.pool.QueryRow(ctx, `
		SELECT id, cents, currency, effective_from FROM plan_prices
		WHERE scope = $1 AND term_months = $2 AND effective_from <= now()
		ORDER BY effective_from DESC LIMIT 1
	`, scope, termMonths).Scan(&one.ID, &one.Cents, &one.Currency, &one.From)

	if errors.Is(err, pgx.ErrNoRows) {
		return Price{}, ErrNoOffer
	}
	if err != nil {
		return Price{}, fmt.Errorf("billing: reading the price in force: %w", err)
	}
	return one, nil
}

// Series is every price ever set for a scope, newest first, terms mixed.
//
// It is the console's, and it is the answer to "what was the offer in March" —
// which is a question a single number cannot be asked. The term is on each row
// rather than in the argument because the console shows one table and not
// three: a change of what the year costs and a change of what two years cost
// are the same kind of event, and reading them interleaved is how somebody sees
// that only one of them moved.
func (p *Prices) Series(ctx context.Context, scope string) ([]Price, error) {
	if scope == "" {
		scope = ScopeEverything
	}
	rows, err := p.pool.Query(ctx, `
		SELECT id, term_months, cents, currency, effective_from FROM plan_prices
		WHERE scope = $1 ORDER BY effective_from DESC, term_months
	`, scope)
	if err != nil {
		return nil, fmt.Errorf("billing: reading the prices: %w", err)
	}
	defer rows.Close()

	var out []Price
	for rows.Next() {
		one := Price{Scope: scope}
		if err := rows.Scan(&one.ID, &one.TermMonths, &one.Cents,
			&one.Currency, &one.From); err != nil {
			return nil, fmt.Errorf("billing: reading the prices: %w", err)
		}
		out = append(out, one)
	}
	return out, rows.Err()
}

/*
Set prices a term, and answers what it replaces.

	SETTING A PRICE IS INSERTING A ROW, and that is the whole of K-14. A colour
	is overwritten because nothing has to be explained about last month's; a
	price is a series, because overwriting one destroys the ability to say what
	the offer was on the day somebody took it. The trigger on the table refuses
	any statement that would do otherwise.

	IT STILL ANSWERS WHAT WAS THERE BEFORE, because the console records both
	sides of every change it makes (K-01) and "490 became 590" is the entry a
	person can use. The difference from an overwrite is that the before is READ
	rather than replaced, and reading it is exact: the row it names is still
	there and always will be.

	A PRICE IDENTICAL TO THE ONE IN FORCE IS STILL A ROW. Whether that is a
	change worth recording belongs to the caller, and a series that quietly
	dropped the repeats could not answer "was this re-confirmed in March, or has
	it simply not been touched since January".
*/
func (p *Prices) Set(ctx context.Context, scope string, termMonths, cents int,
	currency string) (was Price, err error) {

	if scope == "" {
		scope = ScopeEverything
	}
	if termMonths <= 0 {
		return Price{}, fmt.Errorf("%w: a term is a number of months and %d is not one",
			ErrNotAPrice, termMonths)
	}
	if cents <= 0 {
		return Price{}, fmt.Errorf("%w: a price is more than nothing, and %d is not — "+
			"a term with no offer has no price row at all", ErrNotAPrice, cents)
	}
	if !isCurrency(currency) {
		return Price{}, fmt.Errorf("%w: %q is not a currency — three capital letters, "+
			"ISO 4217, which is what a browser can format", ErrNotAPrice, currency)
	}

	tx, err := p.pool.Begin(ctx)
	if err != nil {
		return Price{}, fmt.Errorf("billing: setting a price: %w", err)
	}
	defer func() {
		_ = tx.Rollback(context.WithoutCancel(ctx)) // a no-op once committed
	}()

	// What is in force at this instant, which is what the new row replaces. No
	// row is a term that had no offer, and the caller is told so by a zero.
	before := Price{Scope: scope, TermMonths: termMonths}
	err = tx.QueryRow(ctx, `
		SELECT id, cents, currency, effective_from FROM plan_prices
		WHERE scope = $1 AND term_months = $2 AND effective_from <= now()
		ORDER BY effective_from DESC LIMIT 1
	`, scope, termMonths).Scan(&before.ID, &before.Cents, &before.Currency, &before.From)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		before = Price{}
	case err != nil:
		return Price{}, fmt.Errorf("billing: reading the price in force: %w", err)
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO plan_prices (scope, term_months, cents, currency)
		VALUES ($1, $2, $3, $4)
	`, scope, termMonths, cents, currency); err != nil {
		return Price{}, fmt.Errorf("billing: setting a price: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return Price{}, fmt.Errorf("billing: setting a price: %w", err)
	}
	return before, nil
}

// isCurrency is the same three-letter rule the column carries, checked here so
// that a person typing into a console gets a sentence rather than a constraint
// violation.
func isCurrency(c string) bool {
	if len(c) != 3 {
		return false
	}
	for _, r := range c {
		if r < 'A' || r > 'Z' {
			return false
		}
	}
	return true
}
