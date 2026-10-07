---
title: if and else
version: 1
---

An `if` in Go is a condition, then a block in braces, then optionally `else` and another block.
**The condition has to be a `bool`**: lesson 8 showed the compiler refusing `if n` for a number,
so a test for "not zero" is written out as `n != 0`. Chains of choices are `else if`, and the
last `else` catches whatever is left. This program, in `~/cond`, sorts three numbers into three
kinds:

```go
// Command sign says whether each number is negative, zero or positive.
package main

import "fmt"

func main() {
	for _, n := range []int{-4, 0, 7} {
		if n < 0 {
			fmt.Println(n, "is negative")
		} else if n == 0 {
			fmt.Println(n, "is zero")
		} else {
			fmt.Println(n, "is positive")
		}
	}
}
```

```
ana@vm:~/cond$ go run .
-4 is negative
0 is zero
7 is positive
```

The conditions are tested from the top, and the first one that is true chooses its block and ends
the chain. For 0, `n < 0` was false and `n == 0` was true, so the final `else` never came into
it.

That much is the same in most languages with braces. What differs is three habits a programmer
brings from C, Java or JavaScript, and Go treats each one differently.

## Parentheses: allowed, and removed

Go does not need parentheses around the condition, because the opening brace already marks where
the condition ends. Writing them anyway compiles, and `gofmt` takes them out:

```
ana@vm:~/cond-parens$ go run .
7 is positive
ana@vm:~/cond-parens$ gofmt -d main.go
diff main.go.orig main.go
--- main.go.orig
+++ main.go
@@ -4,7 +4,7 @@
 
 func main() {
 	n := 7
-	if (n > 0) {
+	if n > 0 {
 		fmt.Println(n, "is positive")
 	}
 }
```

So `if (n > 0)` is not wrong, only unusual, and it lasts until the next time somebody saves the
file in an editor that runs `gofmt`. Parentheses inside a condition, to group `a && (b || c)`, are
a different thing and stay where you put them.

## Braces: never optional

In C an `if` followed by one statement needs no braces. **In Go the braces are part of the `if`
and there is no form without them**, even for a single line:

```go
package main

import "fmt"

func main() {
	n := 7
	if n > 0 fmt.Println(n, "is positive")
}
```

```
ana@vm:~/cond-braces$ go build
# example.com/braces
./main.go:7:11: syntax error: unexpected name fmt, expected {
./main.go:8:1: syntax error: unexpected }, expected expression
```

Column 11 is where `fmt` starts, and the parser says what it wanted there instead. The second
line follows from the first: once the `if` had gone wrong, the parser no longer expected the
closing brace of `main` where it stands. The rule removes a whole family of bugs. In a language
with optional braces, a second line indented under an `if` looks as though it belongs to it, and
runs every time.

## else: on the same line as the brace

This one surprises people who put each brace on its own line:

```go
package main

import "fmt"

func main() {
	n := 7
	if n > 0 {
		fmt.Println(n, "is positive")
	}
	else {
		fmt.Println(n, "is not positive")
	}
}
```

```
ana@vm:~/cond-else$ go build
# example.com/else
./main.go:10:2: syntax error: unexpected keyword else, expected }
ana@vm:~/cond-else$ go doc go/scanner.Scanner.Scan | sed -n 13,15p
    If the returned token is token.SEMICOLON, the corresponding literal string
    is ";" if the semicolon was present in the source, and "\n" if the semicolon
    was inserted because of a newline or at EOF. If the newline is within a
```

The reason is the semicolons you never typed. Go's grammar ends statements with `;`, and the
scanner **inserts one at the end of a line** whose last token could end a statement, such as a
closing brace. The documentation of `go/scanner`, the standard library's package for reading Go
source, describes it: an inserted semicolon comes back with the literal `"\n"`. So the `}` on
line 9 ended the whole `if` statement, and line 10 began a new statement with `else`, which no
statement can begin with.

Put `else` after the brace, `} else {`, as in `~/cond`, and the line no longer ends in a brace.
The same rule is why an opening brace is on the same line as the `func`, `for` or `if` it belongs
to. A brace alone on the next line comes after an inserted semicolon, and the compiler says so in
those words:

```go
package main

import "fmt"

func main()
{
	fmt.Println("hello")
}
```

```
ana@vm:~/cond-brace$ go build
# example.com/brace
./main.go:6:1: syntax error: unexpected semicolon or newline before {
```

**In Go, where a brace goes is grammar, not style.** That is one reason `gofmt` can have no
options for it: there is only one place a brace can go.
