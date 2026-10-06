---
title: What a conversion does to a value
version: 1
---

A conversion is written `T(x)`: the type's name, used like a function, around the value. It looks
like a cast in C or Java, and the belief that comes with that word is that it only relabels the
same bits. **Some Go conversions change the value, and the compiler says nothing when they do.**
Between numeric types there are three cases worth knowing, and they are all in one program:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n"
    },
    {
      "code": "\tf := 3.9\n\tfmt.Println(int(f), int(-f))\n",
      "note": "**A float becomes an integer by dropping everything after the point.** `3.9` becomes `3`, not `4`, and `-3.9` becomes `-3`: the cut is toward zero, never a rounding. If you want rounding, `math.Round` does it before the conversion."
    },
    {
      "code": "\n\tbig, mid := 300, 200\n\tfmt.Println(int8(big), int8(mid), uint8(mid))\n",
      "note": "**A smaller integer type keeps the low bits and nothing else.** `int8` holds −128 to 127, so 300 cannot fit, and the conversion does not fail: it keeps eight bits and prints `44`. The figure below shows where `44` and `-56` come from."
    },
    {
      "code": "\n\ttotal, count := 10, 4\n\tfmt.Println(total / count)\n\tfmt.Println(float64(total / count))\n\tfmt.Println(float64(total) / float64(count))\n}\n",
      "note": "**Where the conversion sits decides the answer.** `total / count` is integer division and gives `2`. Converting that result still gives `2`, because the `.5` was gone before the conversion ran. Converting both operands first makes it a float division, and only that one prints `2.5`."
    }
  ],
  "output": "3 -3\n44 -56 200\n2\n2\n2.5"
}
```

## Where 44 and -56 come from

An `int` holding 300 needs nine bits, and `int8` has eight. The conversion keeps the eight on the
right and throws away the one worth 256, which leaves 44. Converting 200 loses nothing, because 200
fits in eight bits, but the same eight bits mean different numbers in the two types. In `uint8`
the top bit is worth 128; in `int8` it is worth −128, so the bits that read 200 unsigned read
−128 + 72 = −56 signed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Converting an int to int8 or uint8 keeps the low eight bits. 300 is 256 plus 44, the bit worth 256 is dropped, and both int8 and uint8 read 44. 200 fits in eight bits, but its top bit is worth 128 to uint8 and minus 128 to int8, so uint8 reads 200 and int8 reads minus 56.\"><defs><marker id=\"cv-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"138\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">place value</text><text x=\"168.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">256</text><text x=\"204.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128</text><text x=\"240.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">64</text><text x=\"276.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">32</text><text x=\"312.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"348.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"384.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><text x=\"420.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"456.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><text x=\"138\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">300, an int</text><rect x=\"150\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"168.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">1</text><rect x=\"186\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"204.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"222\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"258\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"294\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"330\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"348.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"366\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"402\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"438\" y=\"70\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M482 85.0 L522 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-phosphor)\"></path><text x=\"532\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8(big)  → 44</text><text x=\"532\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uint8(big) → 44</text><text x=\"138\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">200, an int</text><rect x=\"150\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"168.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0</text><rect x=\"186\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"204.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><rect x=\"222\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"258\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"294\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"330\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"348.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1</text><rect x=\"366\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"402\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><rect x=\"438\" y=\"170\" width=\"36\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">0</text><path d=\"M482 185.0 L522 185.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-phosphor)\"></path><text x=\"532\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uint8(mid) → 200</text><text x=\"532\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">int8(mid)  → -56</text><text x=\"168.0\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not kept</text><path d=\"M186 112 L186 120 L474 120 L474 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"330\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the eight bits int8 and uint8 keep</text><text x=\"204.0\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">worth 128 to uint8, −128 to int8</text><path d=\"M204.0 202 L204.0 212\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "A conversion to a smaller integer keeps the low bits and reads them in the new type. Nothing checks that the value survived."}
```

**Converting to a smaller integer never fails at run time, and never warns.** That is the price of
the conversion being explicit: having written `int8(big)`, you have said that you know the value
fits. If you do not know, check it before converting, against the limits lesson 7 printed.

The compiler does check one case, the one it can see. A constant is known while compiling, so a
constant that would not survive the conversion is refused outright:

```go
package main

import "fmt"

func main() {
	fmt.Println(int(3.9))
	fmt.Println(int8(300))
}
```

```
ana@vm:~/convert-constconv$ go run .
# example.com/convert-constconv
./main.go:6:18: cannot convert 3.9 (untyped float constant) to type int
./main.go:7:19: constant 300 overflows int8
```

The same two conversions on variables compiled and ran in the program above. The difference is
only what the compiler knows: `3.9` written in the source is a fact, and `f` is whatever it holds
when the line runs.

## string(65) is not "65"

Converting an integer to `string` is legal, and it is almost never what the person who wrote it
wanted:

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	n := 65
	fmt.Println(string(n))
	fmt.Println(string(rune(n)), strconv.Itoa(n))
}
```

```
ana@vm:~/convert-rune$ go run .
A
A 65
ana@vm:~/convert-rune$ go vet; echo $?
main.go:10:14: conversion from int to string yields a string of one rune, not a string of digits
1
```

`string(n)` treats the number as a Unicode code point, and code point 65 is `A`; lesson 8 printed
`'A'` as 65. The program builds and runs, so only `go vet` catches it, and its message
says exactly what went wrong. When the character really is what you want, `string(rune(n))` says
so and `go vet` stays quiet. When you want the digits, the answer is not a conversion at all.

## Text to a number is a function that can fail

**A string of digits is not a number of another type; it is text that has to be parsed**, and
parsing can fail in ways a conversion cannot. That is why the standard library does it in the
package `strconv` with functions rather than with `int(s)`, which the compiler refuses. `Atoi`
turns text into an `int` and `Itoa` turns an `int` into its digits:

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	n, err := strconv.Atoi("42")
	fmt.Println(n+1, err)

	n, err = strconv.Atoi("4.5")
	fmt.Println(n, err)

	n, err = strconv.Atoi(" 42")
	fmt.Println(n, err)

	n, err = strconv.Atoi("99999999999999999999")
	fmt.Println(n, err)

	s := strconv.Itoa(1500)
	fmt.Println(s+" ms", len(s))
}
```

```
ana@vm:~/convert-atoi$ go run .
43 <nil>
0 strconv.Atoi: parsing "4.5": invalid syntax
0 strconv.Atoi: parsing " 42": invalid syntax
9223372036854775807 strconv.Atoi: parsing "99999999999999999999": value out of range
1500 ms 4
```

`Atoi` returns two values, the number and an error, and `<nil>` in the first line means no error.
It is strict: a decimal point is refused, and so is a leading space, which matters when the text
came from a file or a form. The fourth line is the one to remember. The text was all digits but
too large for an `int`, and **`Atoi` returned the largest `int` there is together with the error**
— which `go doc strconv.ParseInt` documents. A program that used `n` without looking at `err`
would carry on with 9223372036854775807. Lesson 32 is about handling errors like these; for now,
look at `err` before you trust `n`.

`Itoa(1500)` gives the four characters `"1500"`, and `len` counts them. Its partner for floats is
`strconv.ParseFloat`, and `fmt.Sprint` turns any value into text when the exact format does not
matter.
