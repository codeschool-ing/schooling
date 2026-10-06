---
title: byte and rune are numbers with a job
version: 1
---

A programmer arriving from C or Java looks for a `char` type, one letter in one small box. Go has
none. **It has two names for integers, `byte` and `rune`, and a letter in Go is one of those
integers.** The documentation on your machine says it in one line each:

```
ana@vm:~/runes-short$ go doc builtin.byte
package builtin // import "builtin"

type byte = uint8
    byte is an alias for uint8 and is equivalent to uint8 in all ways. It is
    used, by convention, to distinguish byte values from 8-bit unsigned integer
    values.

ana@vm:~/runes-short$ go doc builtin.rune
package builtin // import "builtin"

type rune = int32
    rune is an alias for int32 and is equivalent to int32 in all ways. It is
    used, by convention, to distinguish character values from integer values.

```

The `=` in `type byte = uint8` makes `byte` a second name for `uint8`, not a new type; lesson 10
is where that difference matters. The two names exist to tell the reader what a number is for.
A `byte` is a piece of raw data, from 0 to 255. A `rune` is a **code point**: the number Unicode
gives a character, which needs more room than a byte because there are far more than 256 of them.

## A letter in single quotes is a number

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tvar b byte = 'A'\n\tr := 'A'\n",
      "note": "**A letter in single quotes is a rune literal, and its value is the letter's code point**: `'A'` is 65. Declared as a `byte` it is stored in one; with `:=` and no type, `r` becomes a `rune`."
    },
    {
      "code": "\tfmt.Println(b, r)\n",
      "note": "`Println` prints numbers as numbers, and both of these are 65."
    },
    {
      "code": "\tfmt.Printf(\"%T %T\\n\", b, r)\n",
      "note": "`%T` names the types, and it says `uint8` and `int32`: the aliases are those types, under the names the language gave them first."
    },
    {
      "code": "\tfmt.Printf(\"%c %U %q\\n\", r, r, r)\n",
      "note": "Three verbs print a number as text. `%c` draws the character, `%U` writes the code point the way Unicode's charts do, and `%q` quotes it the way Go source would."
    },
    {
      "code": "\tfmt.Println('a'-'A', 'A'+2)\n\tfmt.Printf(\"%c\\n\", 'A'+2)\n}\n",
      "note": "Because a rune is a number, arithmetic works on it. Lower-case `a` is 32 code points after upper-case `A`, and `'A'+2` is 67, which `%c` draws as `C`."
    }
  ],
  "output": "65 65\nuint8 int32\nA U+0041 'A'\n32 67\nC"
}
```

Arithmetic on letters is old and still useful: `'a' - 'A'` is the distance between the two cases
in ASCII, so adding 32 to an upper-case ASCII letter gives its lower case. None of it is a trick. The rune
literal was a number all along, and `%c` is only a way of printing one.

## One rune, and how many bytes

A code point and the bytes that store it are different numbers, and the first accented letter
shows it:

```go
package main

import "fmt"

func main() {
	e := 'é'
	fmt.Printf("%d %c %U\n", e, e, e)
	fmt.Println(len("e"), len("é"), len("€"), len("\U0001F642"))
	fmt.Printf("% x\n", "é")
	fmt.Printf("% x\n", "€")
}
```

```
ana@vm:~/runes-utf8$ go run .
233 é U+00E9
1 2 3 4
c3 a9
e2 82 ac
```

`'é'` is the rune 233, U+00E9. Put the same letter in a string and `len` says 2, because **a Go
string holds UTF-8, and UTF-8 spends from one to four bytes on a code point**. Plain ASCII takes
one, `é` two, the euro sign three, and U+1F642, the slightly smiling face written here as an
escape, four. The `% x` verb prints a string's bytes in hexadecimal with a space between them:
`é` is stored as `c3 a9`, and neither of those is `e9`, which is 233. The encoding spreads the
bits of the code point over two bytes, with markers that say where each character starts.

So `len` on a string counts bytes, not letters. Lesson 9 is about strings themselves, including
how to count their runes; this section only needs the fact that the two counts differ as soon as
the text leaves ASCII.

## Single quotes, double quotes

`'é'` and `"é"` are different things: a single-quoted literal is one rune, a number, and a
double-quoted one is a string. A rune literal also has to fit wherever you put it, and two of these
three declarations do not compile:

```go
package main

import "fmt"

func main() {
	var b byte = 'é'
	var euro byte = '€'
	pair := 'ab'
	fmt.Println(b, euro, pair)
}
```

```
ana@vm:~/runes-quotes$ go run .
# example.com/quotes
./main.go:7:18: cannot use '€' (untyped rune constant 8364) as byte value in variable declaration (overflows)
./main.go:8:10: more than one character in rune literal
```

The euro sign is the code point 8364 and a `byte` stops at 255, so the compiler refuses it with the
number in the message. `'ab'` is two characters where one belongs. The line it did not refuse is
the trap: `var b byte = 'é'` compiles, because 233 fits in a byte. **That byte holds the code
point, which is not how `é` is stored in a string** — in a string it was `c3 a9`. Keep
characters in runes and raw data in bytes, and the two never get mixed up by accident.
