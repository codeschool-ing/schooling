---
title: What gofmt decides, and what it leaves
version: 1
---

Most formatters come with a configuration file: tabs or spaces, how wide an indent, where the
brace goes, how long a line may be. **`gofmt` has no such settings, and that is the feature.** Here
is every flag it accepts:

```
ana@vm:~/fmt$ gofmt -h
usage: gofmt [flags] [path ...]
  -cpuprofile string
    	write cpu profile to this file
  -d	display diffs instead of rewriting files
  -e	report all errors (not just the first 10 on different lines)
  -l	list files whose formatting differs from gofmt's
  -r string
    	rewrite rule (e.g., 'a[b:len(a)] -> a[b:]')
  -s	simplify code
  -w	write result to (source) file instead of stdout
```

Three say where the output goes, one reports errors, one profiles `gofmt` itself, and two, `-s`
and `-r`, change code rather than layout. **None of them chooses a style.** There is one layout,
and every program in this course is printed in it, apart from the deliberately untidy file of
section 02.

## The argument it ends

A team with a configurable formatter has to agree on the configuration, and then keep agreeing:
a new member's editor with different settings produces a commit that reformats files nobody meant
to change, and the one line that mattered disappears inside a diff of three hundred. **With
`gofmt` there is nothing to agree on**, so a review never discusses layout and a diff only ever
shows lines whose meaning changed. Whether the chosen layout is the best one stops mattering; what
matters is that it is the same everywhere, including in code you are reading for the first time.

One choice is not even `gofmt`'s to make. **Go's grammar puts the opening brace on the same line**,
because the lexer ends a statement at a line break after a closing parenthesis. A brace on its own
line is a syntax error, and `gofmt`, reading standard input here, refuses to print it at all:

```
ana@vm:~/fmt$ printf "package p\n\nfunc f()\n{\n}\n" | gofmt
<standard input>:4:1: unexpected semicolon or newline before {
```

## What it leaves alone

The printer works from the syntax tree plus a few things it keeps from the original file, and the
list of what it does not touch matters as much as the list of what it does. **The first is line
length: `gofmt` never wraps a long line.** The `append` line it produced in section 02 is still on
one line, two tabs and 107 other characters:

```
ana@vm:~/fmt$ awk 'length > 100 {print NR ": " length " characters"}' internal/tally/classes.go
22: 109 characters
```

The rest of the list is shorter to state:

- Line breaks you chose. Break a long call after a comma and `gofmt` keeps the break and
  indents the continuation one tab deeper; it does not join lines back up. Where to break that
  109-character line, if anywhere, is yours to decide.
- Names. `rows`, `n` and `c` stay as they are. Whether a name is clear, or exported when it
  should not be, is a question for the linters of lesson 8.
- Blank lines you put in, up to one in a row. Three blank lines after the struct became one;
  a single blank line between two groups of statements stays where you put it.
- The text of comments. A comment is moved and indented with its code, and never re-wrapped or
  reworded.

## `-s`: simplifications that keep the meaning

`-s` goes one step past layout: it rewrites a few constructs into shorter ones that mean exactly
the same, all listed in `go doc cmd/gofmt`. The one you will meet most is a composite literal that
repeats its element type. Here is a test for `Classes`, written the way people often write their
first table of structs. `internal/tally/classes_test.go`:

```go
package tally

import (
	"slices"
	"strings"
	"testing"
)

func TestClasses(t *testing.T) {
	log := "2026-10-01T09:00:01Z GET / 200 5ms\n" +
		"2026-10-01T09:00:02Z GET /login 404 7ms\n" +
		"2026-10-01T09:00:03Z POST /login 201 9ms\n" +
		"2026-10-01T09:00:04Z GET /health 503 2ms\n"
	s, err := Count(strings.NewReader(log))
	if err != nil {
		t.Fatal(err)
	}
	want := []Class{
		Class{Name: "2xx", Requests: 2, Share: 0.5},
		Class{Name: "3xx", Requests: 0, Share: 0},
		Class{Name: "4xx", Requests: 1, Share: 0.25},
		Class{Name: "5xx", Requests: 1, Share: 0.25},
	}
	if got := Classes(s); !slices.Equal(got, want) {
		t.Errorf("Classes = %v, want %v", got, want)
	}
}
```

It passes, and plain `gofmt` is satisfied with it. Only `-s` has something to say:

```
ana@vm:~/fmt$ go test ./internal/tally
ok  	example.com/hits/internal/tally	0.015s
ana@vm:~/fmt$ gofmt -l .
ana@vm:~/fmt$ gofmt -s -l .
internal/tally/classes_test.go
ana@vm:~/fmt$ gofmt -s -d internal/tally/classes_test.go
diff internal/tally/classes_test.go.orig internal/tally/classes_test.go
--- internal/tally/classes_test.go.orig
+++ internal/tally/classes_test.go
@@ -16,10 +16,10 @@
 		t.Fatal(err)
 	}
 	want := []Class{
-		Class{Name: "2xx", Requests: 2, Share: 0.5},
-		Class{Name: "3xx", Requests: 0, Share: 0},
-		Class{Name: "4xx", Requests: 1, Share: 0.25},
-		Class{Name: "5xx", Requests: 1, Share: 0.25},
+		{Name: "2xx", Requests: 2, Share: 0.5},
+		{Name: "3xx", Requests: 0, Share: 0},
+		{Name: "4xx", Requests: 1, Share: 0.25},
+		{Name: "5xx", Requests: 1, Share: 0.25},
 	}
 	if got := Classes(s); !slices.Equal(got, want) {
 		t.Errorf("Classes = %v, want %v", got, want)
ana@vm:~/fmt$ gofmt -s -w internal/tally/classes_test.go && gofmt -s -l .
```

Inside a `[]Class{...}` every element is a `Class`, so the type name in front of each one says
nothing the compiler does not already know. **`-s` is not part of `go fmt`**: the `go fmt -n` line
in section 02 ran `gofmt -l -w` and nothing more. A file can be correctly formatted and still
simplifiable, and if your team wants `-s`, it has to ask for it by name, in the editor setting or
in the check of section 05.

## `-r`: a rewrite rule over the syntax tree

`-r` takes a rule of the form `pattern -> replacement`, where both sides are Go expressions and
**every single lowercase letter is a wildcard** that matches any expression. `main.go` from lesson 1
writes its error messages with `fmt.Fprintf(stderr, "hits: %v\n", err)` in four places.
`fmt.Fprintln` would print the same bytes with less to read, since it puts a space between its
operands and a newline after the last. One rule makes all four changes:

```
ana@vm:~/fmt$ gofmt -r 'fmt.Fprintf(w, "hits: %v\n", e) -> fmt.Fprintln(w, "hits:", e)' -l .
main.go
ana@vm:~/fmt$ gofmt -r 'fmt.Fprintf(w, "hits: %v\n", e) -> fmt.Fprintln(w, "hits:", e)' -d main.go | grep '^[-+]'
--- main.go.orig
+++ main.go
-			fmt.Fprintf(stderr, "hits: %v\n", err)
+			fmt.Fprintln(stderr, "hits:", err)
-		fmt.Fprintf(stderr, "hits: %v\n", err)
+		fmt.Fprintln(stderr, "hits:", err)
-		fmt.Fprintf(stderr, "hits: %v\n", err)
+		fmt.Fprintln(stderr, "hits:", err)
-		fmt.Fprintf(stderr, "hits: %v\n", err)
+		fmt.Fprintln(stderr, "hits:", err)
```

`w` matched `stderr` and `e` matched `err`; the string literal had to match exactly. Run with `-d`,
nothing was written, and this lesson leaves `main.go` as lesson 1 printed it.

**The rule matches syntax and knows nothing about types**, which is its limit. Suppose you decide
the `Duration` field of `tally.Entry` should be called `Took`, and try the obvious rule:

```
ana@vm:~/fmt$ gofmt -r 'a.Duration -> a.Took' -d internal/tally/tally.go | grep '^[-+]'
--- internal/tally/tally.go.orig
+++ internal/tally/tally.go
-	Duration time.Duration
+	Duration time.Took
-	Total    time.Duration
+	Total    time.Took
-		s.Total += e.Duration
+		s.Total += e.Took
```

`a` matched `time` as happily as it matched `e`, so the rule renamed a type in the standard library
that does not exist under that name, and left the field itself, which is declared without a dot,
as `Duration`. The result does not compile. **`-r` suits a mechanical change to the shape of an
expression; a rename needs a tool that knows what each name refers to**, which is the rename
operation of `gopls`, the language server that section 04 introduces.
