---
title: Two kinds of string literal
version: 1
---

A string literal looks like the text between its quotes, and in Go that is only half true. **Go
has two kinds of string literal: an interpreted one in double quotes, where a backslash starts an
escape, and a raw one in backquotes, where every character means itself.** The program in
`~/strings-lit` puts them side by side:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"tab:\\tend\")\n",
      "note": "In double quotes `\\t` is one character, a tab, and the output has a real tab between `tab:` and `end`."
    },
    {
      "code": "\tfmt.Println(\"quote: \\\" backslash: \\\\\")\n",
      "note": "A double quote or a backslash inside double quotes needs a backslash in front of it, or the first would end the string and the second would start an escape."
    },
    {
      "code": "\tfmt.Println(\"euro: \\u20ac, A: \\x41, \\101\")\n",
      "note": "**An escape can name a character by number.** `\\u20ac` is the euro sign by its code point, and `\\x41` and `\\101` are the byte 65, `A`, in hexadecimal and in octal."
    },
    {
      "code": "\tfmt.Println(`tab:\\tend`)\n",
      "note": "Between backquotes nothing is an escape: `\\t` stays a backslash and a `t`."
    },
    {
      "code": "\tfmt.Println(len(\"\\n\"), len(`\\n`))\n}\n",
      "note": "The difference measured: `\"\\n\"` is one byte and `` `\\n` `` is two."
    }
  ],
  "output": "tab:\tend\nquote: \" backslash: \\\neuro: €, A: A, A\ntab:\\tend\n1 2"
}
```

The escapes you will meet most, all of them inside double quotes only:

| escape | what it puts in the string |
|---|---|
| `\n`, `\t` | a newline, a tab |
| `\"`, `\\` | a double quote, a backslash |
| `\x41` | one byte, given in two hexadecimal digits |
| `\101` | one byte, given in three octal digits |
| `\u20ac`, `\U0001F642` | one code point in four or eight hexadecimal digits, stored as its UTF-8 bytes |

## What an interpreted literal refuses, and what it does not

An interpreted literal has to fit on one line. A usage message typed over two lines stops the
build:

```go
package main

import "fmt"

func main() {
	usage := "usage: greet [-n name]
  -n name   who to greet"
	fmt.Println(usage)
}
```

```
ana@vm:~/strings-newline$ go run .
# example.com/newline
./main.go:6:34: newline in string
./main.go:7:6: syntax error: unexpected name name at end of statement
./main.go:7:26: newline in string
```

The first line is the one that matters. The other two follow from it: once the string has ended
early, the parser reads the second line as code and finds `name` where a statement cannot have it.

A backslash followed by a letter that is not an escape is refused too. A regular expression for
"one or more digits" is `\d+`, and in double quotes the `\d` means nothing:

```go
package main

import "fmt"

func main() {
	pattern := "\d+"
	fmt.Println(pattern)
}
```

```
ana@vm:~/strings-escape$ go run .
# example.com/escape
./main.go:6:15: unknown escape
```

Those two fail loudly, which is the good case. The bad case is a backslash followed by a letter
that **is** an escape. A Windows path has backslashes in it, and two of the folder names below
begin with `n` and `t`:

```go
package main

import "fmt"

func main() {
	path := "C:\new\table"
	fmt.Println(path)
	fmt.Printf("%q\n", path)
	fmt.Println(`C:\new\table`)
}
```

```
ana@vm:~/strings-path$ go vet; echo $?
0
ana@vm:~/strings-path$ go run .
C:
ew	able
"C:\new\table"
C:\new\table
```

**The compiler accepted the path and `go vet` found nothing**, because `\n` and `\t` are valid
escapes and the string really does contain a newline and a tab. The first line of output is the
evidence, and `%q`, which quotes a string the way Go source would write it, shows the two escapes
plainly. The last line is the same text as a raw literal, and it prints what was typed.

## Raw literals: what you typed, newlines included

A raw literal ends only at the next backquote, so it can run over several lines, and nothing in it
is an escape. That makes it the form for text with backslashes or line breaks in it:

```go
package main

import "fmt"

func main() {
	usage := `usage: greet [-n name]

  -n name   who to greet, default "world"`
	pattern := `\d+\.\d+`
	fmt.Println(usage)
	fmt.Println(pattern, len(pattern))
}
```

```
ana@vm:~/strings-raw$ go run .
usage: greet [-n name]

  -n name   who to greet, default "world"
\d+\.\d+ 8
```

The usage text kept its blank line, its two-space indent and its double quotes, with no escaping.
`len(pattern)` is 8 because each backslash is one character of the string, which is what a regular
expression library wants to receive. **The one character a raw literal cannot hold is the
backquote**, since it ends the literal; a string that needs one is written in double quotes.

Use double quotes by default, since most strings are short and some need a `\n`. Reach for
backquotes when the text has backslashes in it, spans lines, or is a block of something else — a
regular expression, a SQL query, a JSON sample in a test.
