---
title: errors.New, and why two of them are not equal
version: 1
---

`errors.New` takes a string and returns an `error` whose message is that string, nothing more.
Lesson 32 used it in `price` for `age cannot be negative`. It is the right tool when the message
is fixed and there is nothing to put into it. It also hides one surprise that people coming from
other languages walk into: **two errors made from the same text are not the same error.**

Here it is in `~/wrap`, with two errors that read identically:

```go
// Command wrap compares two errors made from the same text.
package main

import (
	"errors"
	"fmt"
)

func main() {
	a := errors.New("not found")
	b := errors.New("not found")
	fmt.Println(a)
	fmt.Println(a == b, a.Error() == b.Error())

	c := a
	fmt.Println(a == c)
	fmt.Printf("%T\n", a)
}
```

```
ana@vm:~/wrap$ go run .
not found
false true
true
*errors.errorString
```

`a == b` is `false` while their messages are equal, and `a == c` is `true`. The documentation says
it in so many words, and the source, which is in the toolchain the lab installed, shows how:

```
ana@vm:~/wrap$ go doc errors.New
package errors // import "errors"

func New(text string) error
    New returns an error that formats as the given text. Each call to New
    returns a distinct error value even if the text is identical.

ana@vm:~/wrap$ sed -n '64,75p' /usr/local/go/src/errors/errors.go
func New(text string) error {
	return &errorString{text}
}

// errorString is a trivial implementation of error.
type errorString struct {
	s string
}

func (e *errorString) Error() string {
	return e.s
}
```

That is the whole of it. **`errors.New` allocates a new struct on every call and returns a pointer
to it**, so the `error` it gives back holds the type `*errors.errorString` and a pointer nobody
else has. Comparing two interface values compares their two words, the type and the pointer
that lesson 32 drew. `a` and `b` hold the same type and different pointers. `c := a` copied the interface,
pointer included, so `c` is the same error as `a`.

## What the inequality protects

It looks like a trap. It is the behaviour you want, because the alternative is comparing errors by
their text. Two unrelated packages can both fail with `not found`, and a program that treated
those as one error would mistake a missing user for a missing file. **An error's identity is the
value, not the sentence**, and the sentence belongs to a person reading a log.

So a caller does not test `err.Error() == "not found"`, even though `a.Error() == b.Error()` was
`true` above. That test breaks the day somebody rewords the message, and it compiles and runs the
whole time it is broken. When a package wants callers to recognise one particular failure, it
makes the error once, keeps it in a variable, and returns that same value every time, so that
`==` has one pointer to compare. Lesson 35 is about errors declared that way, and lesson 34 about
`errors.Is`, which finds one even after it has been wrapped.

## When errors.New is enough

`errors.New` takes no verbs: `errors.New("age %d is negative")` would print the `%d` as it is.
When the message needs a value in it, or wraps another error, the function is `fmt.Errorf`, and
section 03 is about it. What remains for `errors.New` is the fixed sentence: a rule broken, an
input empty, an operation not allowed, where every occurrence of the failure says the same thing.
