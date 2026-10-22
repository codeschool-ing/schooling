---
title: slog, the standard library's structured logger
version: 1
---

`go-concurrency` lesson 22 introduced `log/slog`. This section uses the parts a server needs, in one small
program:

```go
// logdemo/main.go
package main

import (
	"log/slog"
	"os"
	"strings"
)

// email is an address that logs itself with most of the local part hidden.
type email string

func (e email) LogValue() slog.Value {
	local, domain, ok := strings.Cut(string(e), "@")
	if !ok || local == "" {
		return slog.StringValue("(invalid)")
	}
	return slog.StringValue(local[:1] + "***@" + domain)
}

func main() {
	text := slog.New(slog.NewTextHandler(os.Stdout, nil))
	text.Info("ticket sold", "event_id", 1, "quantity", 2)

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
	logger.Info("ticket sold", "event_id", 1, "quantity", 2, "email", email("ana@example.com"))
	logger.Debug("seats re-read", "event_id", 1)
	logger.Warn("event nearly sold out", slog.Group("event", "id", 3, "available", 2))

	reqLogger := logger.With("request_id", "5f2c9a1be07d44a3")
	reqLogger.Error("sale failed", "event_id", 2, "err", "not enough seats left")
}
```

```
ana@vm:~/logdemo$ go run .
time=2026-10-22T19:20:19.523-03:00 level=INFO msg="ticket sold" event_id=1 quantity=2
{"time":"2026-10-22T19:20:19.523268918-03:00","level":"INFO","msg":"ticket sold","event_id":1,"quantity":2,"email":"a***@example.com"}
{"time":"2026-10-22T19:20:19.523289023-03:00","level":"WARN","msg":"event nearly sold out","event":{"id":3,"available":2}}
{"time":"2026-10-22T19:20:19.523298473-03:00","level":"ERROR","msg":"sale failed","request_id":"5f2c9a1be07d44a3","event_id":2,"err":"not enough seats left"}
```

Line by line:

- **A logger is a handler wrapped in a `*slog.Logger`.** The handler decides the format: `TextHandler`
  writes `key=value` pairs, readable in a terminal; `JSONHandler` writes JSON, readable by everything else.
  The calls are the same for both.
- **Fields are given as key, value, key, value** after the message, and each keeps its type: `1` is a
  number in the JSON, not a string.
- **The debug line is missing.** The handler was given `Level: slog.LevelInfo`, which is also the default,
  so `Debug` was dropped before anything was formatted.
- **`slog.Group` nests fields** under one key, `"event":{"id":3,"available":2}`.
- **`With` returns a logger that carries fields** onto every line it writes. The request id was given once
  and appears on the error line; section 04 uses exactly this for every request.

## A value that logs itself

The address came out as `a***@example.com`. **`email` has a method `LogValue`**, which makes it a
`slog.LogValuer`, and slog calls that method instead of printing the value. The type decides how it is
logged, so every log call that ever receives an `email` hides it, without anybody remembering to. Section 08
is about why that matters.
