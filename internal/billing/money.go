// Package billing is money: how an amount is represented, and the append-only
// record of every one that moved.
//
// # WHY THIS EXISTS BEFORE A PAYMENT GATEWAY DOES
//
// The gateway is an open decision — it has to cover international recurrence,
// Brazilian card instalments and Pix at once, and that is a commercial question
// rather than a technical one. None of what is here depends on the answer. An
// amount is an integer number of cents whoever charges it; a ledger that cannot
// be edited is append-only whoever wrote the row; splitting a year into twelve
// instalments loses a cent in the same place regardless of who takes the card.
//
// Writing it now is also the only way it gets written properly. A money type
// added after there is code doing arithmetic on floats is a refactor of every
// call site, performed under the pressure of a number that came out wrong.
//
// # EVERY AMOUNT IS AN INTEGER NUMBER OF CENTS
//
// Not a decimal type, not a float, and not a float "only for display". 0.1 +
// 0.2 is not 0.3 in binary floating point, and the error compounds across
// twelve instalments in a currency where the cent is the unit people are billed
// in. The type below makes the wrong thing unrepresentable rather than
// discouraged: the fields are unexported, so there is no `amount.Cents * 1.1`
// to write anywhere in this repository.
package billing

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

// Currency is what the cents are cents OF. It is part of every amount rather
// than context somebody remembers, because the arithmetic below refuses to mix
// two — and an amount that does not carry its currency cannot be refused.
type Currency string

const (
	// BRL is the Brazilian real, billed annually or biennially in card
	// instalments, or in one payment by Pix at a discount (N-08).
	BRL Currency = "BRL"
	// USD is everywhere else, billed as real recurrence (N-09).
	USD Currency = "USD"
)

// known is the whole list, and anything else is refused. A currency this code
// does not know is not an amount it can add up, compare or split — and guessing
// at the number of minor units is how an amount lands a hundred times off.
var known = map[Currency]bool{BRL: true, USD: true}

// Both of these are two-decimal currencies. The constant is here so that the
// day a third one is added, the thing that has to change is visible rather than
// spread across every function that divided by a hundred.
const centsPerUnit = 100

// maxCents is a ceiling on the magnitude of an amount, and it is here for
// arithmetic rather than for policy.
//
// int64 wraps silently. Without a bound, a parsed amount near the type's limit
// would make Add wrap into a negative balance and Percent wrap into anything at
// all — from text somebody typed. With every amount under 10^14 cents, a sum of
// two is nowhere near the limit and Percent's intermediate (amount × 10,000)
// stays under 10^18, so nothing here can overflow.
//
// A trillion reais is not a subscription. An amount above this is a mistake or
// an attack, and either way refusing it is the answer.
const maxCents = 100_000_000_000_000

// ErrCurrency is two amounts that are not in the same money.
var ErrCurrency = errors.New("billing: these amounts are in different currencies")

// ErrAmount is an amount that is not one.
var ErrAmount = errors.New("billing: that is not an amount")

// Money is an amount, and it is an integer number of cents.
//
// THE FIELDS ARE UNEXPORTED AND THE ZERO VALUE IS INVALID. Both are deliberate.
// Unexported is what makes float arithmetic on an amount impossible to write
// rather than merely discouraged. An invalid zero value is the fail-closed
// direction for the other mistake: a `var total Money` that silently behaved as
// zero reais would add cleanly to a bill in dollars, and the first time anybody
// noticed would be a charge in the wrong currency. Zero has to be asked for, in
// a currency — see Zero.
type Money struct {
	cents    int64
	currency Currency
}

// New is an amount of cents in a currency.
func New(cents int64, currency Currency) (Money, error) {
	if !known[currency] {
		return Money{}, fmt.Errorf("%w: %q is not a currency this knows", ErrAmount, currency)
	}
	if cents > maxCents || cents < -maxCents {
		return Money{}, fmt.Errorf("%w: %d cents is beyond what this holds", ErrAmount, cents)
	}
	return Money{cents: cents, currency: currency}, nil
}

// MustNew is New for a literal written in this repository, where a wrong
// currency is a compile-time-shaped mistake that no caller can recover from.
// Never for anything that came from outside.
func MustNew(cents int64, currency Currency) Money {
	m, err := New(cents, currency)
	if err != nil {
		panic(err)
	}
	return m
}

// Zero is nothing, in a currency. It exists because the zero VALUE of Money is
// deliberately invalid, and a running total has to start somewhere.
func Zero(currency Currency) (Money, error) { return New(0, currency) }

// Cents is the amount as the integer it is. This is the only way out of the
// type, and it is an int64 rather than anything divisible.
func (m Money) Cents() int64 { return m.cents }

// Currency answers which money this is.
func (m Money) Currency() Currency { return m.currency }

// Valid answers whether this is an amount at all — false for the zero value,
// which is the one Money that carries no currency.
func (m Money) Valid() bool { return known[m.currency] }

// IsZero answers whether it is nothing. An invalid Money is not zero; it is not
// an amount.
func (m Money) IsZero() bool { return m.Valid() && m.cents == 0 }

// Negative answers whether it is below nothing, which a movement of money can
// legitimately be — a refund is a payment with the other sign.
func (m Money) Negative() bool { return m.cents < 0 }

// Neg is the same amount, the other way round.
func (m Money) Neg() Money { return Money{cents: -m.cents, currency: m.currency} }

// Abs is the magnitude, which is what "how much was this" means when the sign
// is carrying direction rather than size.
func (m Money) Abs() Money {
	if m.cents < 0 {
		return m.Neg()
	}
	return m
}

// Add answers the sum, or refuses two currencies.
func (m Money) Add(other Money) (Money, error) {
	if err := m.comparable(other); err != nil {
		return Money{}, err
	}
	return Money{cents: m.cents + other.cents, currency: m.currency}, nil
}

// Sub answers the difference, or refuses two currencies.
func (m Money) Sub(other Money) (Money, error) {
	if err := m.comparable(other); err != nil {
		return Money{}, err
	}
	return Money{cents: m.cents - other.cents, currency: m.currency}, nil
}

// Times multiplies by a whole number, which is the only multiplication that
// cannot lose a cent. Anything else — a percentage, a proportion — goes through
// Percent or Split, where the rounding rule is written down.
//
// It refuses rather than wrapping: this is the one operation here whose result
// is not bounded by its inputs, and a silently negative total is the worst
// answer a money type can give.
func (m Money) Times(n int64) (Money, error) {
	if !m.Valid() {
		return Money{}, fmt.Errorf("%w: it is not an amount", ErrAmount)
	}
	product := m.cents * n
	if n != 0 && (product/n != m.cents || product > maxCents || product < -maxCents) {
		return Money{}, fmt.Errorf("%w: %s times %d is beyond what this holds", ErrAmount, m, n)
	}
	return Money{cents: product, currency: m.currency}, nil
}

// Cmp orders two amounts: -1, 0 or 1. It refuses two currencies rather than
// answering, because "is R$10 more than $10" has no answer this code can give.
func (m Money) Cmp(other Money) (int, error) {
	if err := m.comparable(other); err != nil {
		return 0, err
	}
	switch {
	case m.cents < other.cents:
		return -1, nil
	case m.cents > other.cents:
		return 1, nil
	default:
		return 0, nil
	}
}

func (m Money) comparable(other Money) error {
	if !m.Valid() || !other.Valid() {
		return fmt.Errorf("%w: one of them is not an amount", ErrAmount)
	}
	if m.currency != other.currency {
		return fmt.Errorf("%w: %s and %s", ErrCurrency, m.currency, other.currency)
	}
	return nil
}

/* ---------- the two operations that can lose a cent ---------- */

// Percent applies a rate in BASIS POINTS — hundredths of a per cent, so 1250 is
// 12.5%. Rates are given that way rather than as a float for the same reason
// amounts are: 12.5% of R$1.199,00 has an exact answer, and only if nothing on
// the way there is binary floating point.
//
// # THE ROUNDING RULE, WRITTEN DOWN ONCE
//
// Half away from zero. It is the rule a person doing this on paper uses, which
// matters because the number is going on an invoice somebody may check by hand,
// and "the computer rounds differently from you" is not an answer.
//
// It is NOT banker's rounding. That exists to keep a long series of roundings
// unbiased, which is a real concern when summing thousands of independently
// rounded lines — and it is not this: a discount is applied once to one price,
// and the sum that has to come out exactly is Split's, which does not round at
// all.
func (m Money) Percent(basisPoints int64) Money {
	const wholeInBasisPoints = 10_000

	product := m.cents * basisPoints
	half := int64(wholeInBasisPoints / 2)
	if product < 0 {
		half = -half
	}
	return Money{cents: (product + half) / wholeInBasisPoints, currency: m.currency}
}

// ErrInstalments is a number of instalments that is not one.
var ErrInstalments = errors.New("billing: that is not a number of instalments")

// Split divides an amount into n parts THAT ADD BACK UP TO IT.
//
// # THIS IS WHERE THE CENT GOES MISSING, AND WHY IT IS A FUNCTION
//
// Brazil is billed annually or biennially in card instalments (N-08), so an
// amount is divided by seven, ten or twelve as a matter of course. R$1.000,00
// in seven is R$142,857142… and there is no arrangement of equal instalments
// that sums to the original. Every implementation that divides and rounds
// produces parts that add up to something else, and the difference lands
// somewhere: on the customer's statement, on ours, or in a reconciliation
// nobody can close.
//
// So the remainder is DISTRIBUTED rather than dropped: the first `remainder`
// parts get one cent more than the rest. R$1.000,00 in seven is four instalments
// of R$142,86 and three of R$142,85, which sums to exactly R$1.000,00.
//
// The extra cent goes on the EARLY instalments rather than the last one, which
// is the convention a card issuer uses — and it means the final instalment is
// never the odd one, which is the one a customer is most likely to compare
// against a number they were quoted.
//
// A negative amount splits the same way, with the extra cent on the early parts
// in the same direction. A refund of a split charge has to be splittable by the
// same rule or the two do not cancel.
func (m Money) Split(n int) ([]Money, error) {
	if !m.Valid() {
		return nil, fmt.Errorf("%w: it is not an amount", ErrAmount)
	}
	if n < 1 {
		return nil, fmt.Errorf("%w: %d", ErrInstalments, n)
	}

	each := m.cents / int64(n)
	remainder := m.cents % int64(n)

	// Go truncates towards zero, so a negative amount leaves a negative
	// remainder — which is the sign the extra cent has to have.
	step := int64(1)
	if remainder < 0 {
		step, remainder = -1, -remainder
	}

	parts := make([]Money, n)
	for i := range parts {
		cents := each
		if int64(i) < remainder {
			cents += step
		}
		parts[i] = Money{cents: cents, currency: m.currency}
	}
	return parts, nil
}

/* ---------- reading and writing one ---------- */

// String is the amount as a decimal with its currency: "1199.00 BRL". Machine
// shaped rather than pretty — a person's separators and symbol are a question
// about their locale, and this type is not the place that knows one.
func (m Money) String() string {
	if !m.Valid() {
		return "not an amount"
	}
	return m.Decimal() + " " + string(m.currency)
}

// Decimal is the amount without its currency: "1199.00", "-4.05", "0.07".
func (m Money) Decimal() string {
	sign, cents := "", m.cents
	if cents < 0 {
		sign, cents = "-", -cents
	}
	return fmt.Sprintf("%s%d.%02d", sign, cents/centsPerUnit, cents%centsPerUnit)
}

// Parse reads a decimal amount — "1199", "1199.9", "1199.90", "-4.05" — as
// cents, exactly.
//
// IT PARSES INTEGERS AND NEVER A FLOAT. strconv.ParseFloat on "1199.90" gives a
// number that is not 1199.9, and multiplying it by a hundred gives 119989.99…,
// which truncates to a price one cent below the one on the page. The two halves
// are read as the integers they are and combined with an integer multiply.
func Parse(text string, currency Currency) (Money, error) {
	if !known[currency] {
		return Money{}, fmt.Errorf("%w: %q is not a currency this knows", ErrAmount, currency)
	}

	text = strings.TrimSpace(text)
	if text == "" {
		return Money{}, fmt.Errorf("%w: it is empty", ErrAmount)
	}

	negative := false
	switch text[0] {
	case '-':
		negative, text = true, text[1:]
	case '+':
		text = text[1:]
	}

	whole, fraction, hasFraction := strings.Cut(text, ".")
	if whole == "" || strings.ContainsAny(whole, "+-") {
		return Money{}, fmt.Errorf("%w: %q", ErrAmount, text)
	}

	units, err := strconv.ParseInt(whole, 10, 64)
	if err != nil || units > maxCents/centsPerUnit {
		return Money{}, fmt.Errorf("%w: %q", ErrAmount, text)
	}

	var minor int64
	if hasFraction {
		// Exactly one or two digits. Three would be an amount this currency
		// cannot hold, and accepting it by rounding would mean a price of
		// "9.999" quietly becoming ten — a silent change to a number somebody
		// typed on purpose.
		if len(fraction) == 0 || len(fraction) > 2 || strings.ContainsAny(fraction, "+-") {
			return Money{}, fmt.Errorf("%w: %q has more precision than %s holds",
				ErrAmount, text, currency)
		}
		if minor, err = strconv.ParseInt(fraction, 10, 64); err != nil {
			return Money{}, fmt.Errorf("%w: %q", ErrAmount, text)
		}
		if len(fraction) == 1 {
			minor *= 10
		}
	}

	cents := units*centsPerUnit + minor
	if negative {
		cents = -cents
	}
	return Money{cents: cents, currency: currency}, nil
}
