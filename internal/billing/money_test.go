package billing_test

import (
	"errors"
	"testing"

	"github.com/codeschool-ing/schooling/internal/billing"
)

// A DECIMAL PRICE IS READ EXACTLY. Through a float, 1199.90 × 100 is
// 119989.99999999999, and truncating it prices the subscription a cent below
// what the page says. This is the whole reason Parse does not call ParseFloat.
func TestAPriceIsReadToTheExactCent(t *testing.T) {
	for _, c := range []struct {
		text  string
		cents int64
	}{
		{"1199.90", 119990},
		{"1199.9", 119990},
		{"1199", 119900},
		{"0.07", 7},
		{"0.1", 10},
		{"0", 0},
		{"-4.05", -405},
		{"+4.05", 405},
		{" 29.99 ", 2999},
		{"0.29", 29},
		{"8.11", 811},
	} {
		amount, err := billing.Parse(c.text, billing.BRL)
		if err != nil {
			t.Errorf("reading %q: %v", c.text, err)
			continue
		}
		if amount.Cents() != c.cents {
			t.Errorf("%q read as %d cents, want %d", c.text, amount.Cents(), c.cents)
		}
	}
}

// AND WHAT IS NOT A PRICE IS REFUSED. A parser that guessed would turn a typo
// in a console field into a charge nobody meant.
func TestSomethingThatIsNotAnAmountIsRefused(t *testing.T) {
	for _, text := range []string{
		"", "   ", "abc", "1,99", "1.999", "1.", ".5", "1.2.3", "R$10", "1e3",
		"--4", "1-2", "0x10", "∞",
		"1000000000000000", // beyond what this holds, and it must not wrap
	} {
		if amount, err := billing.Parse(text, billing.BRL); err == nil {
			t.Errorf("%q was read as %s", text, amount)
		}
	}
}

// A parse and a print are inverses, which is what makes a price stored as text
// somewhere and read back here the same price.
func TestPrintingAnAmountAndReadingItBackGivesTheSameAmount(t *testing.T) {
	for _, cents := range []int64{0, 1, -1, 7, 99, 100, 119990, -405, 99999999} {
		amount := billing.MustNew(cents, billing.USD)

		again, err := billing.Parse(amount.Decimal(), billing.USD)
		if err != nil {
			t.Fatalf("reading back %q: %v", amount.Decimal(), err)
		}
		if again.Cents() != cents {
			t.Errorf("%d cents printed as %q and read back as %d",
				cents, amount.Decimal(), again.Cents())
		}
	}
}

// TWO CURRENCIES DO NOT ADD UP, and this is the reason the currency travels
// with the amount instead of being remembered by the caller. R$10 + $10 has no
// answer, and a type that returned 20 of something would produce a charge in
// the wrong money with nothing in the logs.
func TestTwoCurrenciesRefuseToMix(t *testing.T) {
	reais := billing.MustNew(1000, billing.BRL)
	dollars := billing.MustNew(1000, billing.USD)

	if _, err := reais.Add(dollars); !errors.Is(err, billing.ErrCurrency) {
		t.Errorf("adding reais to dollars gave %v, want ErrCurrency", err)
	}
	if _, err := reais.Sub(dollars); !errors.Is(err, billing.ErrCurrency) {
		t.Errorf("subtracting dollars from reais gave %v, want ErrCurrency", err)
	}
	if _, err := reais.Cmp(dollars); !errors.Is(err, billing.ErrCurrency) {
		t.Errorf("comparing reais to dollars gave %v, want ErrCurrency", err)
	}
}

// THE ZERO VALUE IS NOT ZERO REAIS. It is not an amount at all, and it has to
// refuse arithmetic — otherwise a `var total billing.Money` left uninitialised
// would add cleanly to a bill in any currency, and the mistake would surface as
// a charge in the wrong money.
func TestTheZeroValueIsNotAnAmount(t *testing.T) {
	var uninitialised billing.Money

	if uninitialised.Valid() {
		t.Error("the zero value says it is an amount")
	}
	if uninitialised.IsZero() {
		t.Error("the zero value says it is zero; it is not an amount, which is different")
	}
	if _, err := uninitialised.Add(billing.MustNew(100, billing.BRL)); err == nil {
		t.Error("the zero value added to R$1,00 without complaint")
	}

	nothing, err := billing.Zero(billing.BRL)
	if err != nil {
		t.Fatal(err)
	}
	if !nothing.IsZero() || !nothing.Valid() {
		t.Error("Zero(BRL) is not a valid zero amount")
	}
}

// THE DISCOUNT ROUNDS THE WAY A PERSON DOES. Pix on the annual plan is a
// percentage off a price somebody may check by hand, and "the computer rounds
// differently from you" is not an answer to give them.
func TestADiscountRoundsHalfAwayFromZero(t *testing.T) {
	for _, c := range []struct {
		cents        int64
		basisPoints  int64
		want         int64
		whyItMatters string
	}{
		{119900, 1000, 11990, "10% of R$1.199,00 is exact"},
		{119900, 1250, 14988, "12.5% is 14987.5, which rounds up"},
		{100, 5000, 50, "half of a real"},
		{101, 5000, 51, "half of R$1,01 is 50.5, which rounds up"},
		{-101, 5000, -51, "and the same magnitude below zero"},
		{119900, 0, 0, "no discount is no money"},
		{119900, 10000, 119900, "all of it"},
	} {
		got := billing.MustNew(c.cents, billing.BRL).Percent(c.basisPoints)
		if got.Cents() != c.want {
			t.Errorf("%d basis points of %d cents gave %d, want %d — %s",
				c.basisPoints, c.cents, got.Cents(), c.want, c.whyItMatters)
		}
	}
}

// NOTHING HERE WRAPS. int64 overflow in a money type is a negative balance
// arriving from a number somebody typed, so the operations that could produce
// one refuse instead.
func TestAnAmountBeyondWhatThisHoldsIsRefusedRatherThanWrapped(t *testing.T) {
	if _, err := billing.New(1<<62, billing.BRL); !errors.Is(err, billing.ErrAmount) {
		t.Errorf("an enormous amount was accepted: %v", err)
	}

	big := billing.MustNew(99_000_000_000_000, billing.BRL)
	if product, err := big.Times(1 << 40); err == nil {
		t.Errorf("multiplying past the limit gave %s instead of refusing", product)
	}

	// And an ordinary multiplication still works, because refusing everything
	// would be a way to pass this test without being useful.
	twelve, err := billing.MustNew(9990, billing.BRL).Times(12)
	if err != nil {
		t.Fatalf("twelve months of R$99,90: %v", err)
	}
	if twelve.Cents() != 119880 {
		t.Errorf("twelve months of R$99,90 is %d cents, want 119880", twelve.Cents())
	}
}

// A currency this code does not know is refused rather than assumed to have two
// decimal places. Guessing is how an amount lands a hundred times off.
func TestAnUnknownCurrencyIsRefused(t *testing.T) {
	if _, err := billing.New(1000, billing.Currency("XYZ")); !errors.Is(err, billing.ErrAmount) {
		t.Errorf("XYZ was accepted as a currency: %v", err)
	}
	if _, err := billing.Parse("10.00", billing.Currency("")); !errors.Is(err, billing.ErrAmount) {
		t.Errorf("the empty currency was accepted: %v", err)
	}
}
