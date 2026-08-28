package billing

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

/*
What somebody has bought, as a list they can read.

# THE LEDGER IS NOT THIS AND CANNOT BE MADE INTO IT

There are three records of a sale on this platform and each answers a different
question:

	checkout_intents     what was asked for — the offer, the discount, the
	                     method, how the issuer splits it, and how far it got
	ledger_entries       that money moved, keyed by the CHARGE
	subscription_events  what it did to somebody's access

A purchase history looks like the ledger and is not. An instalment plan is ONE
sale collected several times, and the ledger is keyed by the charge, so the
biennial plan bought in three parts is three rows of R$ 363,33 there and one
purchase here. A student reading the ledger would see three prices they never
agreed to and no sign of the one they did.

It also looks like `subscription_events` and is not. That log is transitions —
including the ones nobody bought, a term running out, a refund — and it says
nothing about the method, the discount, or a purchase that was never paid.

So the purchase is the CHECKOUT, and the other two are joined onto it: the
ledger to prove the money, the log to say what the term became. `0042` built the
index for exactly this read and said so: "what has this person tried to buy,
which the account screen asks and a person disputing something asks louder".

# IT INCLUDES WHAT WAS NOT PAID, AND THAT IS THE POINT

A row that stopped at `opened` is somebody who clicked and got an error, and one
at `charged` is a Pix code nobody paid. Both are the rows a person writes in
about — "I tried to subscribe and nothing happened", "I have a code, is it still
good" — and a history that showed only successes would answer neither. A
`charged` row still carries its invoice URL, so the screen can hand it back
rather than make somebody start again.
*/

// Purchase is one checkout, with what it cost and what it bought.
type Purchase struct {
	ID uuid.UUID

	// OpenedAt is when they asked to buy. MovedAt is when it last changed —
	// which for a paid one is when the payment landed, and for an abandoned one
	// is when the charge gave up.
	OpenedAt time.Time
	MovedAt  time.Time

	Stage Stage

	/* WHAT WAS ASKED FOR AND WHAT IS ON THE SHELF, BOTH.

	   `Cents` is what this platform actually charged and `Listed` is the
	   `plan_prices` row it came from; they differ by the Pix discount, and a
	   history that showed one of them could not explain the other. Somebody
	   comparing a R$ 655,50 line against a R$ 690,00 offer needs to see the
	   subtraction, not be left to work out whether they were overcharged. */
	Cents    int
	Listed   int
	Currency string

	// How long it bought, from the price it was made under.
	TermMonths int

	Method      Method
	Instalments int

	// InvoiceURL is where the payer was sent, and is empty on a row that never
	// reached the gateway.
	InvoiceURL string

	/* PaidThrough is where the term stood AFTER this purchase, and nil when
	   there is nothing to say: a checkout that was never paid, or one paid
	   before `0043` gave the log this column. Nil is drawn as "not recorded"
	   rather than as a blank, because those are different facts. */
	PaidThrough *time.Time
}

/*
Purchases is everything one account has tried to buy, newest first.

	IT IS ONE QUERY AND NOT A LOOP. A history is drawn whole or not at all — a
	screen half of whose rows have an amount is worse than one with none — and
	joining in Go would be one round trip per purchase for a page that exists to
	be read in a single glance.

	THE TWO JOINS ARE NOT THE SAME SHAPE, deliberately. `plan_prices` is an inner
	join because a checkout cannot exist without one: the column is NOT NULL with
	a foreign key, so a missing row is a broken database rather than a purchase
	with no price, and hiding it behind a LEFT JOIN would turn that into a blank
	cell nobody investigates. The term is a subquery because it is genuinely
	absent for most rows.
*/
func (c *Checkouts) Purchases(ctx context.Context, accountID uuid.UUID) ([]Purchase, error) {
	rows, err := c.pool.Query(ctx, `
		SELECT ci.id, ci.created_at, ci.updated_at, ci.stage,
		       ci.cents, ci.currency, ci.method, ci.instalments,
		       COALESCE(ci.invoice_url, ''),
		       pp.cents, pp.term_months,

		       /* WHAT THE TERM BECAME, THROUGH THE LEDGER ROW BETWEEN THEM.
		          There is no column joining a subscription event to a checkout
		          and there should not be: the event records the entry that
		          caused it, the entry records the charge the money came on, and
		          the charge is what the checkout was answered with. Three facts,
		          each written by whoever knew it.

		          A SUBQUERY AND NOT A JOIN, so that a second event somehow
		          pointing at one entry cannot double a line of somebody's
		          history. Nothing writes two — Checkouts.Settled answers "first"
		          exactly once per purchase — and a duplicated purchase is a bad
		          way to find out otherwise.

		          (No backticks in here: this is a Go raw string, and one would
		          end it in the middle of a query.) */
		       (SELECT se.paid_through
		          FROM subscription_events se
		          JOIN ledger_entries le ON le.id = se.ledger_entry_id
		         WHERE le.source = ci.provider
		           AND le.source_ref = ci.provider_charge_id
		         ORDER BY se.occurred_at
		         LIMIT 1)

		FROM checkout_intents ci
		JOIN plan_prices pp ON pp.id = ci.price_id
		WHERE ci.account_id = $1
		ORDER BY ci.created_at DESC, ci.id
	`, accountID)
	if err != nil {
		return nil, fmt.Errorf("billing: reading what somebody has bought: %w", err)
	}
	defer rows.Close()

	out := make([]Purchase, 0)
	for rows.Next() {
		var p Purchase
		var stage, method string
		if err := rows.Scan(&p.ID, &p.OpenedAt, &p.MovedAt, &stage,
			&p.Cents, &p.Currency, &method, &p.Instalments, &p.InvoiceURL,
			&p.Listed, &p.TermMonths, &p.PaidThrough); err != nil {
			return nil, fmt.Errorf("billing: reading what somebody has bought: %w", err)
		}
		p.Stage, p.Method = Stage(stage), Method(method)
		out = append(out, p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("billing: reading what somebody has bought: %w", err)
	}
	return out, nil
}

// Spent is what a purchase came to when it is over and nothing when it is not.
//
// IT IS A METHOD AND NOT A FIELD, because "did this cost anything" is a
// question about the stage and the amount together — an abandoned checkout has
// a `cents` and it was never charged. A screen that added the column would be
// adding up money nobody paid.
func (p Purchase) Spent() (int, bool) {
	if p.Stage != StagePaid {
		return 0, false
	}
	return p.Cents, true
}
