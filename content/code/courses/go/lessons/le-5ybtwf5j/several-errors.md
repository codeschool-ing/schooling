---
title: Several errors in one, and what wrapping promises
version: 1
---

Sometimes one failure is not the whole story. A form with an empty name and a negative age has two
problems, and reporting the first sends the person back to fix it and then meet the second. A file
whose write failed may also fail to close. **Go has two ways to put several errors into one
value**: `errors.Join`, for a list, and `fmt.Errorf` with more than one `%w`, for a sentence.

## errors.Join: a list of failures

`~/wrap-join` checks a sign-up form and collects every problem before returning:

```go
// Command signup checks a form and reports every problem at once.
package main

import (
	"errors"
	"fmt"
)

func validate(name string, age int) error {
	var errs []error
	if name == "" {
		errs = append(errs, errors.New("name is empty"))
	}
	if age < 0 {
		errs = append(errs, fmt.Errorf("age %d is negative", age))
	}
	return errors.Join(errs...)
}

func main() {
	fmt.Println(validate("Ana", 30))
	err := validate("", -4)
	fmt.Println(err)
	fmt.Printf("%T %q\n", err, err.Error())
}
```

```
ana@vm:~/wrap-join$ go run .
<nil>
name is empty
age -4 is negative
*errors.joinError "name is empty\nage -4 is negative"
```

The first call found nothing, and `validate` returned `nil` without a special case for it:
`errs` was an empty slice, and **`errors.Join` of nothing is `nil`**. The second call found two
problems and returned one error, a `*errors.joinError`, whose message is the two messages with a
newline between them; `%q` shows the `\n`. `errs...` spreads the slice over a variadic parameter,
as lesson 21 showed. The documentation states each of those rules:

```
ana@vm:~/wrap-join$ go doc errors.Join
package errors // import "errors"

func Join(errs ...error) error
    Join returns an error that wraps the given errors. Any nil error values are
    discarded. Join returns nil if every value in errs is nil. The error formats
    as the concatenation of the strings obtained by calling the Error method of
    each element of errs, with a newline between each string.

    A non-nil error returned by Join implements the Unwrap() []error method.
    The errors may be inspected with Is and As.

```

`Join` adds no words of its own, so it suits a list of independent problems, each of which already
says what it is. A message spread over several lines reads well on a terminal and badly inside a
one-line log entry, which is worth knowing before you print one there.

## Several %w: one sentence, several causes

When the failures belong to one operation and deserve one sentence, `fmt.Errorf` accepts more than
one `%w`. `~/wrap-two` reports a save that failed twice:

```go
	writeErr := errors.New("disk full")
	closeErr := errors.New("file already closed")
	err := fmt.Errorf("save notes.txt: %w (and closing it: %w)", writeErr, closeErr)
	fmt.Println(err)
	fmt.Printf("%T\n", err)
```

```
ana@vm:~/wrap-two$ go run .
save notes.txt: disk full (and closing it: file already closed)
*fmt.wrapErrors
```

One line, in words you chose, and the type is `*fmt.wrapErrors`, plural. A few lines below the
ones section 03 printed, the source of `fmt.Errorf` builds that type whenever a format has more
than one `%w`, and it keeps every operand in a list rather than one in a field. **Both errors are kept whole, as with a single `%w`**, and both are findable afterwards;
lesson 34 shows how a caller searches an error that holds a list.

## Wrapping is a promise

`%v` and `%w` print the same text, so the choice between them looks like taste. It is a decision
about what your function promises. With `%w`, the error underneath stays reachable: from lesson 34
on, a caller can ask whether a `readConfig` error has an `*fs.PathError` inside it and act on the
answer. **Once callers do that, the inner error is part of your function's behaviour**, as much as
its parameters are.

Suppose `readConfig` later stops reading a file and fetches its settings over the network instead.
With `%w`, every caller that checked for a missing file now checks for something that can never
happen, and nothing tells them: their code compiles and runs, and the branch for the missing file
is dead. With `%v`, nobody could have depended on the file error in the first place, and the change
breaks nothing.

So the question to ask at each `fmt.Errorf` is whether a caller should be able to see the error
underneath. **Wrap with `%w` when the inner error is part of what your function means; add context
with `%v` when it is a detail of how the function happens to work today.** The `errors` package's
own documentation points to a Go blog post on exactly this choice,
`https://go.dev/blog/go1.13-errors`; the lab cannot reach go.dev, so this lesson does not quote it.
