---
title: Indexing a string gives you bytes
version: 1
---

The natural reading of `s[3]` is "the fourth character of `s`". **In Go it is the fourth byte**,
and lesson 8 showed that a character outside ASCII takes more than one. With `café`, that
difference shows up at the fourth position, which is exactly where the `é` is:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n\t\"unicode/utf8\"\n)\n\nfunc main() {\n\ts := \"café\"\n\tfmt.Println(len(s), utf8.RuneCountInString(s))\n",
      "note": "**`len` counts bytes and `utf8.RuneCountInString` counts runes**: 5 and 4 for `café`, whose `é` is two bytes."
    },
    {
      "code": "\tfmt.Println(utf8.RuneCountInString(\"cafe\\u0301\"))\n",
      "note": "The decomposed spelling of lesson 8, `cafe\\u0301`, is 5 runes, though a reader sees four characters."
    },
    {
      "code": "\tfmt.Println(s[0], s[3], s[4])\n",
      "note": "Indexing gives bytes. `s[0]` is 99, the `c`; `s[3]` and `s[4]` are 195 and 169, the two halves of `é`, which lesson 8 printed in hexadecimal as `c3 a9`."
    },
    {
      "code": "\tfmt.Printf(\"%T %c\\n\", s[3], s[3])\n",
      "note": "`%T` confirms that `s[3]` is a `uint8`. Printed with `%c`, 195 is drawn as `Ã`, the character whose code point is 195: **a byte read as a character gives the wrong character**, and no error."
    },
    {
      "code": "\tfmt.Printf(\"%q %q\\n\", s[:3], s[:4])\n",
      "note": "Slicing counts bytes too. `s[:3]` stops before the `é`; `s[:4]` cuts it in half and leaves a lone `\\xc3`, which `%q` shows as an escape."
    },
    {
      "code": "\tfmt.Println(utf8.ValidString(s[:4]), utf8.ValidString(s))\n",
      "note": "`utf8.ValidString` catches the cut: `false` for the half, `true` for the whole word."
    },
    {
      "code": "\tfmt.Println(strings.Index(\"café au lait\", \"au\"))\n",
      "note": "The functions of `strings` answer in byte offsets as well. In `café au lait`, `au` starts at byte 6, though only five characters come before it."
    },
    {
      "code": "\tr, size := utf8.DecodeRuneInString(s[3:])\n\tfmt.Printf(\"%c %d\\n\", r, size)\n}\n",
      "note": "To read the rune that starts at a byte offset, `utf8.DecodeRuneInString` returns the rune and how many bytes it took: `é` and 2. A call that returns two results is ordinary Go, and lesson 20 is about them."
    }
  ],
  "output": "5 4\n5\n99 195 169\nuint8 Ã\n\"caf\" \"caf\\xc3\"\nfalse true\n6\né 2"
}
```

The rule that follows: **slice a string only at an offset that a function found for you**, such as
`strings.Index`, and never at one you counted in characters. When both strings are valid UTF-8, the
offset `strings.Index` returns is where a rune starts, so slicing there keeps both pieces valid.
Walking a string one rune at a time, without doing the arithmetic yourself, is what a `for range`
loop over a string does, and lesson 17 shows it.

## A string can hold any bytes

Nothing stops a string from holding bytes that are not UTF-8. A Go source file is UTF-8, so text
you type between quotes is valid; `\x` and octal escapes, a file read from disk and the body of a
network request can all put anything in:

```go
package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	b := "\xff\xfe"
	fmt.Println(len(b), utf8.ValidString(b), utf8.RuneCountInString(b))
	fmt.Printf("%q % x\n", b, b)
}
```

```
ana@vm:~/strings-invalid$ go run .
2 false 2
"\xff\xfe" ff fe
```

`ff fe` is the byte-order mark at the start of a file encoded as UTF-16 little-endian, and as
UTF-8 it is two bytes that begin no character. `utf8.ValidString` says so. `RuneCountInString`
still answers 2, because it counts each byte it cannot decode as one rune, so a count alone does
not tell you the text was valid. **When a string comes from outside your program, check it with
`utf8.ValidString` before you treat it as text.**

So each question this lesson and the last one raised now has a function that answers it:

| you want | write | for `café` |
|---|---|---|
| the size in bytes | `len(s)` | 5 |
| the number of runes | `utf8.RuneCountInString(s)` | 4 |
| whether it is valid UTF-8 | `utf8.ValidString(s)` | `true` |

The third count of lesson 8, characters as a reader sees them, is still not in the standard
library, and the decomposed `café` above is the reminder: 5 runes, 4 characters.
