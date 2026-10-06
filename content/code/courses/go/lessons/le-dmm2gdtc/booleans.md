---
title: Booleans, and nothing else is true
version: 1
---

In Python and JavaScript almost anything can stand where a condition goes: a number is false when
it is zero, a string when it is empty, and everything else counts as true. C does the same with
numbers and pointers. Go has no such rule. **A condition in Go is a `bool`, and no other type turns into one** — not by
itself, and not when you ask. Here is the habit from other languages, typed into `~/runes-truthy`:

```go
package main

import "fmt"

func main() {
	count := 3
	name := "Ana"
	if count {
		fmt.Println("there is work to do")
	}
	if name {
		fmt.Println("hello,", name)
	}
	ready := bool(count)
	fmt.Println(!count, ready)
}
```

```
ana@vm:~/runes-truthy$ go run .; echo $?
# example.com/truthy
./main.go:8:5: non-boolean condition in if statement
./main.go:11:5: non-boolean condition in if statement
./main.go:14:16: cannot convert count (variable of type int) to type bool
./main.go:15:15: invalid operation: operator ! not defined on count (variable of type int)
1
```

Four lines, four refusals, and nothing ran. Lines 8 and 11 put an `int` and a `string` where an
`if` wants a `bool`. Line 14 asks for the conversion outright with `bool(count)`, and Go has no
conversion from a number to a truth value at all. Line 15 is the same rule from the other side:
`!` means "not", and it is defined on `bool` and on nothing else.

The rule costs a few characters and buys a question you no longer have to ask. In a language with
truthiness, `if count` might be a test for zero, or for "was it set", or a bug; somebody reading it
has to guess which. In Go the condition says what it tests, because it has to.

## Say what you mean, and the operators

The repair is to write the comparison you meant. A comparison produces a `bool`, so `count > 0`
and `name != ""` are conditions. The program in `~/runes-bool` keeps both and adds the three
logical operators:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tcount := 3\n\tname := \"Ana\"\n",
      "note": "The same two variables as in `~/runes-truthy`, an `int` and a `string`."
    },
    {
      "code": "\tif count > 0 {\n\t\tfmt.Println(\"there is work to do\")\n\t}\n\tif name != \"\" {\n\t\tfmt.Println(\"hello,\", name)\n\t}\n",
      "note": "**A comparison produces a `bool`**, so these two conditions compile. `count > 0` and `name != \"\"` say what the earlier version left the reader to guess: a test for a positive count and a test for a name that is not empty."
    },
    {
      "code": "\n\ttests, lint := true, false\n\tfmt.Println(tests && lint, tests || lint, !lint)\n",
      "note": "`&&` is true when both sides are, `||` when at least one is, and `!` turns one value over. With `tests` true and `lint` false they print `false true true`."
    },
    {
      "code": "\tfmt.Println(tests != lint, tests == lint)\n",
      "note": "`==` and `!=` work on booleans as on any other type. `tests != lint` is true exactly when the two differ, which makes it Go's exclusive or."
    },
    {
      "code": "\tfmt.Printf(\"%t %v %T\\n\", tests, tests, tests)\n}\n",
      "note": "`%t` is the formatting verb for a boolean. `%v` prints the same word, and `%T` names the type."
    }
  ],
  "output": "there is work to do\nhello, Ana\nfalse true true\ntrue false\ntrue true bool"
}
```

**`&&`, `||` and `!` take a `bool` and give a `bool`**, and there is no fourth one. An exclusive or,
true when exactly one side is true, is `!=` between two booleans, which is what line four of the
output printed. The operator that means exclusive or on integers is refused:

```
ana@vm:~/runes-xor$ go run .
# example.com/xor
./main.go:7:14: invalid operation: operator ^ not defined on tests (variable of type bool)
```

The `bool` type has exactly two values, and `go doc builtin.bool` says so in one sentence: "bool
is the set of boolean values, true and false." Lesson 6 showed that a `bool` you declare without a
value starts as `false`.

## The right-hand side may never run

`&&` and `||` stop as soon as the answer is known. In `a && b`, if `a` is false the whole thing is
false and `b` is not evaluated; in `a || b`, if `a` is true `b` is skipped. That is called
**short-circuit evaluation**, and it is what makes a guard possible. Lesson 7 showed that dividing
an integer by a zero variable panics at run time; here the same division sits behind a guard, and
then in front of it:

```go
package main

import "fmt"

func main() {
	total, people := 120, 0

	if people > 0 && total/people > 50 {
		fmt.Println("more than 50 each")
	}
	fmt.Println("the guard held")

	if total/people > 50 && people > 0 {
		fmt.Println("more than 50 each")
	}
	fmt.Println("never printed")
}
```

```
ana@vm:~/runes-short$ go run .; echo $?
the guard held
panic: runtime error: integer divide by zero

goroutine 1 [running]:
main.main()
	/home/ana/runes-short/main.go:13 +0x4a
exit status 2
1
```

The first `if` found `people > 0` false and never divided. The second divided first, on line 13,
and the program died before `people > 0` was looked at. The two conditions contain the same two
tests; **only the order differs, and in Go the order is part of the meaning.** Put the cheap test,
or the one that protects the other, on the left. Lesson 36 is about panics and lesson 37 reads a
trace like this one frame by frame; for now, `exit status 2` is the program's own exit status,
which `go run` reported before exiting with 1 itself.
