---
title: if err != nil, and what goes inside it
version: 1
---

**A call that can fail is followed, on the next line, by `if err != nil`**, and the block under it
leaves: it returns, or in `main` it ends the program. Lesson 19 wrote that shape once in `double`
and called it the most common sight in Go code. The standard library's own source agrees, counted
with its tests left out:

```
ana@vm:~/errors-idiom$ grep -rE --include=*.go 'if err != nil' /usr/local/go/src | grep -vc -e _test.go -e testdata
8879
```

Nearly nine thousand lines of the code that ships with Go are that one test.

## The ticket price, with an error instead of -1

Lesson 19 priced a ticket and answered a negative age with `-1`, a stand-in that only works while
every caller remembers that `-1` is not a price. Here is the same rule with an `error`, and a
`main` that reads the age from the command line, in `~/errors-idiom`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command price prints the price of a ticket for the age it is given.\npackage main\n\nimport (\n\t\"errors\"\n\t\"fmt\"\n\t\"os\"\n\t\"strconv\"\n)\n\nfunc price(age int, member bool) (int, error) {\n\tif age < 0 {\n\t\treturn 0, errors.New(\"age cannot be negative\")\n\t}\n",
      "note": "**The bad age now returns an error, and the price beside it is 0.** `errors.New` makes an `error` out of a sentence; lesson 33 is about it and about `fmt.Errorf`. The 0 is not a price: a caller that sees a non-nil error does not read it."
    },
    {
      "code": "\tif age < 12 {\n\t\treturn 0, nil\n\t}\n\tif member {\n\t\treturn 15, nil\n\t}\n\treturn 20, nil\n}\n",
      "note": "**Every successful path returns `nil` as its error.** Here 0 is a real price, a child's, and nothing confuses it with a failure, because the failure is reported in the other result."
    },
    {
      "code": "\nfunc main() {\n\tage, err := strconv.Atoi(os.Args[1])\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n",
      "note": "**The idiom: call, test `err` on the next line, leave inside the block.** `os.Args[1]` is the first word after the program's name. In `main` there is no caller to return to, so leaving means writing the message to standard error and ending with exit status 1."
    },
    {
      "code": "\tp, err := price(age, false)\n\tif err != nil {\n\t\tfmt.Fprintln(os.Stderr, err)\n\t\tos.Exit(1)\n\t}\n\tfmt.Println(p)\n}\n",
      "note": "The second call reuses `err`: `p` is new, so `:=` is allowed and `err` is only assigned, the rule lesson 5 said would earn its keep here. **The success path runs down the left margin, with every failure handled and left above it**, as lesson 19 recommended."
    }
  ]
}
```

Built once and run with four ages:

```
ana@vm:~/errors-idiom$ go build -o price .
ana@vm:~/errors-idiom$ ./price 30; echo $?
20
0
ana@vm:~/errors-idiom$ ./price 8; echo $?
0
0
ana@vm:~/errors-idiom$ ./price -4; echo $?
age cannot be negative
1
ana@vm:~/errors-idiom$ ./price thirty; echo $?
strconv.Atoi: parsing "thirty": invalid syntax
1
ana@vm:~/errors-idiom$ ./price -4 2>/dev/null; echo $?
1
```

Each run stopped at a different place. `thirty` never reached `price`: `Atoi` failed and the first
block ended the program. `-4` got past `Atoi` and was refused by `price`. The last line throws
standard error away, and the message goes with it. The exit status stays 1: **the message was for
a person and the status is for a script**, so a shell or a CI job running `price` knows it failed
without reading English.

A child's ticket printed 0 with status 0. That is the case a stand-in number cannot handle. A
function whose every value is a legal answer has no number left over to mean "failed", and a
price function is one of those the moment a ticket can be free.

## What goes inside the block

There are three things to do with an error, and the block holds one of them.

1. **Return it** to your own caller, as `double` did in lesson 19. This is the usual answer inside
   a function that is not `main`, because the function that called you knows more about what the
   failure means for the program than you do. Lesson 33 adds context to it on the way out.
2. **Handle it** where you are, when there is a real answer to a failure: a default value, a
   second attempt, a fallback file. Then the program carries on, and that is a decision you made.
3. **Report it and stop**, which is what `main` does above. There is nobody left to return to.

What the block must not do is nothing. The next program is the same one with both errors thrown
away with `_`, the blank identifier of lesson 20, in `~/errors-ignore`:

```go
func main() {
	age, _ := strconv.Atoi(os.Args[1])
	p, _ := price(age, false)
	fmt.Println(p)
}
```

```
ana@vm:~/errors-ignore$ go run . thirty
0
ana@vm:~/errors-ignore$ go run . -4
0
```

Somebody aged `thirty` got a free ticket. `Atoi` failed and returned 0, the `_` discarded the
reason, and 0 went into `price` as the age of a small child. The second run went the same way by a
different road: `price` refused `-4`, returned 0 beside its error, and the program printed the 0.
**A discarded error does not stop a program; it turns a failure into a wrong answer**, printed with
exit status 0, which is worse than stopping.

## No exceptions, and what that buys

The price of this style is plain to see: three lines for every call that can fail, written out by
hand, nearly nine thousand times in the standard library. What it buys is that **every place a
function can stop is written in the function**. Reading `main` above, you can point at the two
lines where it may end and say why. In a language with exceptions any call in the block may leave
it, and the place it lands is in another function, sometimes in another file.

Go does have `panic`, which does unwind the calls, and lesson 36 is about it. It is for bugs, a
nil map written to or an index past the end, and not for a file that is missing or a number
somebody mistyped. Those are ordinary outcomes of an ordinary program, and in Go they come back
as values.
