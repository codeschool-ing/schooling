package asaas

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
)

/*
Reais on the wire, cents everywhere else.

# THE GATEWAY SPEAKS DECIMALS AND THIS PLATFORM DOES NOT

Every amount in this repository is an integer number of cents, for the reason
`billing.Money` states: a price in a float is a price that is 489.99999 on some
machine. The gateway's API is the opposite — it sends and receives JSON numbers
with a decimal point, and the first real response from it read

	"value": 590.0, "netValue": 589.01

So there is a boundary, and this file is all of it. Nothing else in the package
converts, and no `float64` is used anywhere in the conversion: 589.01 parsed as
a float and multiplied by 100 is 58900.999999999993, and `int64` of that is
58900 — one cent lost, silently, on the number that says what we were actually
paid.

# BOTH DIRECTIONS ARE STRING SURGERY, DELIBERATELY

Out: the integer is split into units and hundredths and printed. It goes into
the request as a raw JSON number rather than a quoted string, because that is
what the API accepts, and `json.RawMessage` is how a number is written without
a float ever existing.

In: the digits before and after the point are read as integers. Anything the
API can legitimately send is covered — `590`, `590.0`, `590.01` — and anything
it cannot is an error rather than a guess, because a number this code does not
understand is money it would otherwise round.

# NEGATIVES ARE NOT REFUSED HERE

A refund arrives as a positive amount on an object that says it is a refund, so
nothing in this package sends a negative. Parsing one is still supported: the
day a response carries one, losing the sign would be worse than reading it.
*/

// ErrNotAnAmount is a number from the API this code will not guess at.
var ErrNotAnAmount = errors.New("asaas: that is not an amount of money")

/*
reais writes cents as the JSON number the API expects.

	`json.RawMessage` AND NOT A `float64`. Marshalling 58901 cents through a
	float would print `589.01` today and is one refactor away from `589.0100000001`
	— and the value that reaches a gateway is not the place to find out that Go's
	float formatting is usually good enough.
*/
func reais(cents int64) json.RawMessage {
	sign := ""
	if cents < 0 {
		sign, cents = "-", -cents
	}
	return json.RawMessage(fmt.Sprintf("%s%d.%02d", sign, cents/100, cents%100))
}

/*
centsOf reads one of their numbers as an integer number of cents.

	IT TAKES THE RAW TEXT AND NOT A NUMBER, so the caller decodes their JSON
	with `json.Number` and hands the digits over untouched. A `float64` in the
	signature would mean the loss had already happened before this was called.

	MORE THAN TWO DECIMALS IS AN ERROR AND NOT A ROUNDING. The API deals in
	cents like everybody else; a third digit means something has changed about
	what it sends, and quietly dropping it is how a difference becomes invisible.
*/
func centsOf(raw string) (int64, error) {
	text := strings.TrimSpace(raw)
	if text == "" {
		return 0, fmt.Errorf("%w: it is empty", ErrNotAnAmount)
	}

	negative := false
	switch text[0] {
	case '-':
		negative, text = true, text[1:]
	case '+':
		text = text[1:]
	}

	whole, fraction, hasPoint := strings.Cut(text, ".")
	if whole == "" {
		whole = "0"
	}
	if hasPoint {
		switch len(fraction) {
		case 0:
			fraction = "00"
		case 1:
			fraction += "0"
		case 2:
		default:
			return 0, fmt.Errorf("%w: %q has more than two decimal places, and this "+
				"platform counts in cents — dropping the rest would hide a change in "+
				"what the gateway sends", ErrNotAnAmount, raw)
		}
	} else {
		fraction = "00"
	}

	units, err := digits(whole)
	if err != nil {
		return 0, fmt.Errorf("%w: %q", ErrNotAnAmount, raw)
	}
	hundredths, err := digits(fraction)
	if err != nil {
		return 0, fmt.Errorf("%w: %q", ErrNotAnAmount, raw)
	}

	total := units*100 + hundredths
	if negative {
		total = -total
	}
	return total, nil
}

// digits reads a run of decimal digits, refusing everything else — including
// the signs and separators `strconv.ParseInt` would happily take, which at this
// point in the parse would mean a number like "5-9" being read as something.
func digits(text string) (int64, error) {
	if text == "" {
		return 0, ErrNotAnAmount
	}
	var out int64
	for _, r := range text {
		if r < '0' || r > '9' {
			return 0, ErrNotAnAmount
		}
		out = out*10 + int64(r-'0')
	}
	return out, nil
}
