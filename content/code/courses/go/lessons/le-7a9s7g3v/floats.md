---
title: Floats are binary fractions, and 0.1 is not one
version: 1
---

The picture most people carry is that `0.1` in a program is the number one tenth. It is not. Go's
`float64` and `float32` are binary floating point, the IEEE 754 formats (`go doc builtin.float64`
says so in one line), and **a binary fraction can no more hold one tenth exactly than a decimal one can hold
one third**. What `0.1` gets you is the nearest number the format has, and the difference shows up
the moment you do arithmetic.

## 0.1 + 0.2

```go
package main

import (
	"fmt"
	"math"
)

func main() {
	fmt.Println(0.1 + 0.2)

	a, b := 0.1, 0.2
	fmt.Println(a + b)
	fmt.Println(a+b == 0.3)
	fmt.Println(math.Abs(a+b-0.3) < 1e-9)

	fmt.Printf("%.20f\n", 0.1)
	fmt.Printf("%x\n", 0.1)
	fmt.Printf("%064b\n", math.Float64bits(0.1))
}
```

```
ana@vm:~/numbers-float$ go run .
0.3
0.30000000000000004
false
true
0.10000000000000000555
0x1.999999999999ap-04
0011111110111001100110011001100110011001100110011001100110011010
```

The first line printed `0.3`, which looks like a counter-example and is not one. `0.1 + 0.2`
written with two constants is worked out by the compiler, exactly, the way lesson 5 described for
untyped constants, and only the result is turned into a `float64`. Put the same two numbers into
variables and the addition happens at run time, in `float64`, where it gives
`0.30000000000000004`. That is not equal to `0.3`, and the `==` says `false`.

The last three lines show why. Printed with twenty decimals, `0.1` is `0.10000000000000000555`.
`%x` prints the float in hexadecimal: `0x1.999999999999ap-04` is 1.6 times 2⁻⁴, where 1.6 in
hexadecimal is `1.999…` for ever, cut off after thirteen digits and the last one rounded up to `a`.
`%064b` prints all 64 bits:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The 64 bits of the float64 nearest to 0.1, split into three fields. The first bit, the sign, is 0 for positive. The next 11 bits, the exponent, are 1019, which means times 2 to the minus 4. The last 52 bits, the fraction, are the repeating pattern 1001 cut short and rounded up, so the stored value is 0.10000000000000000555 rather than 0.1.\"><rect x=\"25.0\" y=\"27\" width=\"8.5\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"35.5\" y=\"27\" width=\"113.5\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"151.0\" y=\"27\" width=\"544.0\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"29.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">0</text><text x=\"39.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0</text><text x=\"50.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"60.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"71.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"81.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"92.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"102.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"113.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"123.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0</text><text x=\"134.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"144.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1</text><text x=\"155.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"165.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"176.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"186.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"197.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"207.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"218.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"228.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"239.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"249.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"260.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"270.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"281.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"291.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"302.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"312.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"323.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"333.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"344.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"354.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"365.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"375.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"386.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"396.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"407.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"417.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"428.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"438.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"449.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"459.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"470.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"480.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"491.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"501.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"512.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"522.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"533.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"543.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"554.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"564.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"575.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"585.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"596.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"606.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"617.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"627.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"638.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"648.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"659.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"669.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"680.25\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text><text x=\"690.75\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><path d=\"M24.0 62 L34.5 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"24.0\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sign</text><text x=\"24.0\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 bit</text><path d=\"M34.5 62 L150.0 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"92.25\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">exponent</text><text x=\"92.25\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">11 bits</text><path d=\"M150.0 62 L696.0 62\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"423.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fraction</text><text x=\"423.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">52 bits</text><text x=\"24\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">0 means positive</text><text x=\"24\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">1019 − 1023 = −4, so × 2⁻⁴</text><text x=\"330\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1.1001 1001 1001 … : the 1001 never ends,</text><text x=\"330\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">so it is cut at 52 bits and rounded up</text><rect x=\"24\" y=\"180\" width=\"672\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what float64 actually holds for 0.1:</text><text x=\"420\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0.10000000000000000555</text></svg>", "caption": "The 64 bits that %064b printed for 0.1, in the three fields of a float64."}
```

`float32` is the same layout in half the bits, with 8 for the exponent and 23 for the fraction, so
it is coarser still. Use `float64` unless you are storing millions of them and have measured that
the precision is enough; it is the type Go gives `4.2` when nothing else says.

**Never compare two computed floats with `==`.** Compare the size of their difference with a
tolerance, `math.Abs(a+b-0.3) < 1e-9` in the program above, and choose the tolerance from the
problem: a billionth is generous for a price and useless for an atom.

## Infinity and NaN

Floats have three values integers do not: positive infinity, negative infinity and NaN, "not a
number". Dividing by zero produces them instead of a panic:

```go
package main

import (
	"fmt"
	"math"
)

func main() {
	zero := 0.0
	fmt.Println(1/zero, -1/zero)

	nan := zero / zero
	fmt.Println(nan, math.Sqrt(-1))
	fmt.Println(nan == nan, nan != nan)
	fmt.Println(math.IsNaN(nan), math.IsInf(1/zero, 1))
	fmt.Println(nan > 1, nan < 1)
}
```

```
ana@vm:~/numbers-nan$ go run .
+Inf -Inf
NaN NaN
false true
true true
false false
```

`1/zero` is `+Inf` and `-1/zero` is `-Inf`. `zero/zero` has no sensible answer, and neither does
the square root of −1 among the real numbers, so both are `NaN`. **NaN is not equal to anything,
itself included**: `nan == nan` is `false` and `nan != nan` is `true`, and every ordering
comparison with it is `false` too. So `x == math.NaN()` can never find one. Ask `math.IsNaN`, and
for infinities `math.IsInf`, whose second argument says which sign to look for (1 for positive).

A NaN does not stop anything. It flows through every calculation it touches and comes out the far
end as `NaN`, which is why the place to check for it is where it can first appear.

## Never money in floats

Here are ten coins of ten cents, added up twice:

```go
// Command money adds ten coins of ten cents, twice.
package main

import "fmt"

func main() {
	total := 0.0
	for range 10 {
		total += 0.10
	}
	fmt.Println(total, total == 1.0)
	fmt.Printf("%.2f\n", total)

	cents := 0
	for range 10 {
		cents += 10
	}
	fmt.Println(cents, cents == 100)
	fmt.Printf("R$ %d,%02d\n", cents/100, cents%100)
}
```

```
ana@vm:~/numbers-money$ go run .
0.9999999999999999 false
1.00
100 true
R$ 1,00
```

Ten times `0.10` in a `float64` is `0.9999999999999999`, and it is not equal to `1.0`. **`%.2f`
printed `1.00`, which is how a float error reaches production: every screen rounds it away and
every comparison sees it.** A balance check, a "paid in full" test or a sum that has to match a
bank statement goes wrong by about 0.0000000000000001, and nobody can see why.

The fix is to count the smallest unit as an integer. Ten coins of 10 cents are 100 cents, exactly,
and integer division and `%` turn that back into reais and centavos for display, as the last line
shows. Money is an `int64` of cents, never a `float64` of reais. (`for range 10` runs its body ten
times; loops are lesson 17.)
