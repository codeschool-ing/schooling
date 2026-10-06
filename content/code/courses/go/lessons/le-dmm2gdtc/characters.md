---
title: A character is not a rune either
version: 1
---

After the last section it is tempting to settle on "a rune is a character". It is closer than "a
byte is a character", and still wrong. **What a reader sees as one character can be several
runes**, and two strings that look identical can hold different runes.

The letter `é` has two spellings in Unicode. One is the single code point U+00E9. The other is a
plain `e`, U+0065, followed by U+0301, the combining acute accent, a code point made to sit on the
letter before it. Unicode defines the two as **canonically equivalent**:
the same character, written two ways. Go does not know that, and this program in `~/runes-cafe`
shows what it does know:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"unicode\"\n)\n\nfunc main() {\n\tcomposed := \"caf\\u00e9\"\n\tdecomposed := \"cafe\\u0301\"\n",
      "note": "**Two spellings of one word.** `\\u00e9` is `é` as a single code point; `e\\u0301` is a plain `e` followed by the combining acute accent. They are written as escapes so the source shows which is which."
    },
    {
      "code": "\tfmt.Println(composed == decomposed)\n",
      "note": "`==` on strings compares bytes, and the bytes differ, so it prints `false` for two words a reader cannot tell apart."
    },
    {
      "code": "\tfmt.Println(len(composed), len(decomposed))\n",
      "note": "`len` counts bytes: 5 and 6. The precomposed `é` takes two bytes, and the `e` with its accent takes three."
    },
    {
      "code": "\tfmt.Printf(\"%+q\\n%+q\\n\", composed, decomposed)\n",
      "note": "`%+q` quotes a string and escapes everything outside ASCII, which makes the runes visible: four in the first word, five in the second."
    },
    {
      "code": "\tfmt.Printf(\"% x\\n% x\\n\", composed, decomposed)\n",
      "note": "`% x` shows the bytes themselves. The accent alone, U+0301, is `cc 81`."
    },
    {
      "code": "\tfmt.Println(unicode.IsLetter('\\u0301'), unicode.IsMark('\\u0301'))\n}\n",
      "note": "**The `unicode` package knows what U+0301 is**: not a letter but a mark, which combines with the letter before it. That is where splitting text into characters would start."
    }
  ],
  "output": "false\n5 6\n\"caf\\u00e9\"\n\"cafe\\u0301\"\n63 61 66 c3 a9\n63 61 66 65 cc 81\nfalse true"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The word café written with its accent as a combining mark, in three rows. Four characters: c, a, f, é. Five runes: U+0063, U+0061, U+0066, U+0065 and U+0301, because the é is an e followed by the accent. Six bytes: 63, 61, 66, 65, cc and 81, because the accent takes two bytes of UTF-8.\"><text x=\"20\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 characters</text><text x=\"20\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what a reader sees</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5 runes</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the code points</text><text x=\"20\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6 bytes</text><text x=\"20\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what len counts</text><rect x=\"203\" y=\"33\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">c</text><rect x=\"283\" y=\"33\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">a</text><rect x=\"363\" y=\"33\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">f</text><rect x=\"443\" y=\"33\" width=\"234\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">é</text><rect x=\"203\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0063</text><rect x=\"283\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0061</text><rect x=\"363\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0066</text><rect x=\"443\" y=\"108\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0065</text><rect x=\"523\" y=\"108\" width=\"154\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U+0301</text><rect x=\"203\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">63</text><rect x=\"283\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">61</text><rect x=\"363\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">66</text><rect x=\"443\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">65</text><rect x=\"523\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">cc</text><rect x=\"603\" y=\"183\" width=\"74\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">81</text></svg>", "caption": "One word, three lengths: café with its accent written as a combining mark. The highlighted part is the one letter é."}
```

## A flag is two runes that draw as one

The decomposed `é` is not a rare case kept for exams. Text that comes from another program can
arrive in either form, nothing in the bytes says which, and emoji make several runes per character
routine. A national flag has no code
point of its own: it is two **regional indicator** symbols, the letters of the country's code, and
a font that knows the pair draws one flag. Brazil is B and R:

```go
package main

import "fmt"

func main() {
	brazil := "\U0001F1E7\U0001F1F7"
	fmt.Printf("%+q\n", brazil)
	fmt.Println(len(brazil))
	fmt.Printf("%U %U\n", '\U0001F1E7', '\U0001F1F7')
}
```

```
ana@vm:~/runes-flag$ go run .
"\U0001f1e7\U0001f1f7"
8
U+1F1E7 U+1F1F7
```

One picture on the screen, two runes, eight bytes. Each indicator is four bytes of UTF-8, and
neither of them means anything to a reader alone. What a reader calls a character, Unicode calls a
**grapheme cluster**: one or more code points that are drawn and edited as a unit, the thing
a text editor's cursor steps over in one move.

## What the standard library does not do

Go's standard library has three packages for Unicode text, and none of them splits a string into
grapheme clusters:

```
ana@vm:~/runes-flag$ go list std | grep '^unicode'
unicode
unicode/utf16
unicode/utf8
ana@vm:~/runes-flag$ go doc unicode.Version
package unicode // import "unicode"

const Version = "17.0.0"
    Version is the Unicode edition from which the tables are derived.
```

`unicode` answers questions about one rune at a time, from tables of Unicode 17.0.0: is it a
letter, a digit, a mark. `unicode/utf8` converts between runes and bytes, and lesson 9 uses it.
Neither knows that U+0301 belongs with the `e` before it. Turning `cafe\u0301` into `caf\u00e9`
is called normalisation, and the package that does it, `golang.org/x/text/unicode/norm`, lives in
a module maintained by the Go project outside the standard library; lesson 38 adds that module to
a program. Splitting text into grapheme clusters is left to third-party modules, and lesson 40 is
about choosing one.

So one word has three lengths, and each answers a different question:

| count | what it measures | in Go |
|---|---|---|
| bytes | the space it takes in memory, in a file, on the wire | `len(s)` |
| runes | the code points it is made of | `utf8.RuneCountInString(s)`, lesson 9 |
| characters | what a reader sees, and what a cursor steps over | not in the standard library |

**Before you measure a piece of text, decide which of the three you were asked for.** A database
column limited to 20 bytes, a form that allows 20 characters and a protocol that counts code points
are three different limits, and the same name can fit one and break another.
