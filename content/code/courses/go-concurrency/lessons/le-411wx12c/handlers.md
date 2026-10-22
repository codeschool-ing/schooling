---
title: A record, and the handler that writes it
version: 1
---

A log line written with `fmt.Printf` is a sentence: easy for a person, and a puzzle for the program
that has to find every slow query in a day of them. **`log/slog` writes records instead: a level, a
message and a list of named values**, and a handler decides how the record becomes bytes. The same
call can then produce text a person reads or JSON a machine searches.

Every program in this lesson lives in a directory of its own under `~/logs`, one module for all of
them. The first uses the default logger, with nothing set up, saved as `first/main.go`:

```go
// Command first logs through the default logger, as it comes.
package main

import (
	"log"
	"log/slog"
)

func main() {
	log.Print("an old-style line")
	slog.Info("order placed", "order", 1042, "total_cents", 15990)
	slog.Debug("not shown")
}
```

```
ana@vm:~/logs$ go run ./first
2026/10/16 19:38:40 an old-style line
2026/10/16 19:38:40 INFO order placed order=1042 total_cents=15990
```

The old `log` package and `slog` share one default, so both lines came out in the same shape, with
the date and time of the run in front. The `slog` line has a level, `INFO`, and its values as
`key=value`. **The `Debug` line printed nothing: the default logger records `INFO` and above.**
The arguments after the message are taken in pairs, a key and then its value.

## Text for people, JSON for machines

A handler is chosen when the logger is made. The next program makes two, each with options that
lower the level to `DEBUG` and remove the time from every record, so this lesson's output is the
same on every run. Saved as `handlers/main.go`:

```go
// Command handlers writes the same records through two handlers.
package main

import (
	"log/slog"
	"os"
)

// noTime drops the time from every record, so that this lesson's
// output is the same on every run.
func noTime(groups []string, a slog.Attr) slog.Attr {
	if a.Key == slog.TimeKey && len(groups) == 0 {
		return slog.Attr{}
	}
	return a
}

func main() {
	opts := &slog.HandlerOptions{Level: slog.LevelDebug, ReplaceAttr: noTime}

	text := slog.New(slog.NewTextHandler(os.Stdout, opts))
	text.Debug("cache miss", "key", "user:7")
	text.Info("order placed", "order", 1042, "note", "gift wrap")
	text.Warn("slow query", "took_ms", 812)

	json := slog.New(slog.NewJSONHandler(os.Stdout, opts))
	json.Info("order placed", "order", 1042, "note", "gift wrap")
	json.Error("payment refused", "order", 1042, "reason", "card expired")
}
```

```
ana@vm:~/logs$ go run ./handlers
level=DEBUG msg="cache miss" key=user:7
level=INFO msg="order placed" order=1042 note="gift wrap"
level=WARN msg="slow query" took_ms=812
{"level":"INFO","msg":"order placed","order":1042,"note":"gift wrap"}
{"level":"ERROR","msg":"payment refused","order":1042,"reason":"card expired"}
```

**The `TextHandler` writes `key=value` pairs, quoting a value only when it has a space**, so a line
stays readable and `grep` still finds `level=WARN`. The `JSONHandler` writes one JSON object per
line, and a number stays a number, `"order":1042`, which a log search can compare and sum. The
`DEBUG` record appeared this time because the options lowered the level.

Each line of JSON is a whole object, so any tool that reads JSON reads one:

```
ana@vm:~/logs$ go run ./handlers | grep ERROR
{"level":"ERROR","msg":"payment refused","order":1042,"reason":"card expired"}
ana@vm:~/logs$ go run ./handlers | tail -1 | python3 -m json.tool
{
    "level": "ERROR",
    "msg": "payment refused",
    "order": 1042,
    "reason": "card expired"
}
```

`python3 -m json.tool` is only a pretty-printer here; the services that collect logs in production
read the same lines. **Choose JSON for a program whose logs a machine will read, and text for a
program a person watches in a terminal.** The calls that write the records do not change, only the
handler.
