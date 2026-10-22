---
title: Values, and what belongs in them
version: 1
---

The fourth method, `Value(key)`, lets a context carry data down the call along with the
cancellation. **It is for data that belongs to the request and has to cross API boundaries**: a
request id for the logs, the identity of the caller, a trace id. It is not a way to pass a
function's ordinary parameters out of sight.

## A key of your own type

`context.WithValue(parent, key, value)` returns a child carrying one pair; `Value` looks the key up
in that context and then in each parent in turn. Keys are compared like map keys, type included,
and that is the whole trick of using them safely. Saved as `values.go`:

```go
// Command values carries a request id through a context, under a key of its own type.
package main

import (
	"context"
	"fmt"
)

// ctxKey is unexported, so no other package can make a key equal to ours.
type ctxKey int

const requestIDKey ctxKey = 0

func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

// RequestID returns the id, and false when the context carries none.
func RequestID(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(requestIDKey).(string)
	return id, ok
}

func handle(ctx context.Context) {
	id, ok := RequestID(ctx)
	fmt.Printf("handling request %q (found: %v)\n", id, ok)
}

func main() {
	ctx := WithRequestID(context.Background(), "req-7f3a")
	handle(ctx)
	handle(context.Background())
	fmt.Println("same text, different key:", ctx.Value(0), ctx.Value("requestIDKey"))
	fmt.Println(ctx)
}
```

```
ana@vm:~/ctx$ go run values.go
handling request "req-7f3a" (found: true)
handling request "" (found: false)
same text, different key: <nil> <nil>
context.Background.WithValue(main.ctxKey, req-7f3a)
```

`handle` found the id in the first context and reported `found: false` for an empty one, through
the comma-ok of the type assertion. The third line is the point of `ctxKey`: **neither `0` nor the
string `"requestIDKey"` finds the value**, because neither has the type `ctxKey`. No other package
can name that type, so no other package can read or overwrite this value by accident, even if it
also chose the key `0`. A string key, `"id"`, is the classic collision between two libraries.

The last line is what `fmt` prints for a context: the chain from the root, with the pair it carries.
It is handy in a debugger and a reason not to put secrets in a value, since a context ends up in log
lines more often than anybody intends.

## What does not belong

The documentation of `context` says to use values only for request-scoped data that transits
processes and APIs, **not for passing optional parameters to functions**. Three signs that a value
should be a parameter instead:

1. the function cannot do its job without it: a database handle, a configuration;
2. its absence is a bug rather than a normal case;
3. it is the same for every request: it belongs to the program, not to the request.

A value is also untyped at the boundary, `any` in and a type assertion out, so the helper pair
above, `WithRequestID` and `RequestID`, is the usual way to keep the key private and the types
right.
