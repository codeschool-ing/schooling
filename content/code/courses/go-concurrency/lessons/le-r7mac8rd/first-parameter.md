---
title: The first parameter
version: 1
---

Lesson 10 made contexts and cancelled them inside one function. A real program is many functions
calling each other, and the tempting picture is that each one makes the context it needs, where it
needs it. **A context is not made where it is used. It is made once, near the top of a piece of
work, and handed down to everything that work calls**, so that one decision at the top reaches the
bottom of the call.

The convention is written in the `context` package's own documentation, and `go doc` prints it:

```
ana@vm:~/propagate$ go doc context | sed -n 33,43p
Do not store Contexts inside a struct type; instead, pass a Context
explicitly to each function that needs it. This is discussed further in
https://go.dev/blog/context-and-structs. The Context should be the first
parameter, typically named ctx:

    func DoSomething(ctx context.Context, arg Arg) error {
    	// ... use ctx ...
    }

Do not pass a nil Context, even if a function permits it. Pass context.TODO if
you are unsure about which Context to use.
```

**First parameter, named `ctx`, every time.** It costs nothing to follow and it makes one thing
visible at a glance: a function whose signature starts with `ctx context.Context` can be told to
stop. One whose signature does not, cannot.

## Three layers, one decision

The program below has the shape of a request in a server: a top that receives it, a middle that
builds a report, a bottom that fetches data and waits on something slow. Each program in this
lesson lives in its own directory under `~/propagate`, because each is a `package main` of its own,
and `go run ./layers` builds the one in `layers`. This one is saved in `~/propagate/layers` as
`layers.go`:

```go
// Command layers passes one context down three calls and stops all of them at once.
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// handle is the top: it decides how long the whole request may take.
func handle(ctx context.Context, user string) error {
	ctx, cancel := context.WithTimeout(ctx, 150*time.Millisecond)
	defer cancel()
	return report(ctx, user)
}

// report is the middle: it decides nothing about time and passes ctx on.
func report(ctx context.Context, user string) error {
	for _, month := range []string{"jan", "feb", "mar"} {
		if err := fetch(ctx, user, month); err != nil {
			return fmt.Errorf("report for %s: %w", user, err)
		}
	}
	return nil
}

// fetch is the bottom: it waits on something slow, or on ctx, whichever ends first.
func fetch(ctx context.Context, user, month string) error {
	select {
	case <-time.After(60 * time.Millisecond):
		fmt.Println("fetched", user, month)
		return nil
	case <-ctx.Done():
		return fmt.Errorf("fetch %s: %w", month, ctx.Err())
	}
}

func main() {
	err := handle(context.Background(), "ana")
	fmt.Println("error:", err)
	fmt.Println("deadline exceeded:", errors.Is(err, context.DeadlineExceeded))
}
```

Each layer has one job with respect to time. **`handle` decides**: the whole request gets 150
milliseconds, and it derives a context that says so. **`report` passes**: it knows nothing about
deadlines and hands `ctx` to every call it makes. **`fetch` honours**: it waits on the slow thing
or on `ctx.Done()`, whichever comes first. Three fetches of 60 milliseconds cannot fit into 150:

```
ana@vm:~/propagate$ go run ./layers
fetched ana jan
fetched ana feb
error: report for ana: fetch mar: context deadline exceeded
deadline exceeded: true
```

Two fetches finished in 120 milliseconds, and the third was cut off at 150 by a deadline set two
calls above it. The error reads from the outside in, because each layer wrapped it with `%w` on its
way up: the report, the fetch, and the reason. `errors.Is` still finds
`context.DeadlineExceeded` at the bottom of the chain, which is how a caller tells "the request ran
out of time" from "the data was wrong".

Notice what the middle layer did not need. `report` never mentions a deadline, never calls
`ctx.Done()`, and still stopped the moment its time ran out, because the only thing it did with
`ctx` was pass it on. **Most functions in a well-built program are the middle layer**, and passing
`ctx` is all they ever do with it.

## Why not in a struct

The documentation's other rule says not to keep a context in a struct field. The reason is
lifetime. A context belongs to one call: one request, one job. A struct usually outlives the call
that created it, a service or a client living for the whole program, and the context stored in it
then belongs to a request that finished long ago. Every later call through that struct would be
cancelled by, or carry the values of, somebody else's request.

The standard library has one well-known exception, and it proves the rule: an `*http.Request`
carries the context of that request, because a request IS one call. Lesson 12 uses it.

`context.TODO()` is for the place where a context should exist and does not yet, typically while
old code is being converted. It behaves like `context.Background()`, never ending; the different
name marks the spot so a reader, or a search, finds it.
