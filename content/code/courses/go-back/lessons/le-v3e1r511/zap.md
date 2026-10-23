---
title: zap
version: 1
---

zap came from Uber, and **offers two APIs over one core**: a strict `Logger` that takes typed fields, for
speed, and a `SugaredLogger` that takes loose key-value pairs and `Printf` formats, for convenience.

```go
// logothers/zap/main.go
package main

import (
	"go.uber.org/zap"
)

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		panic(err)
	}
	defer logger.Sync()

	logger.Info("ticket sold", zap.Int("event_id", 1), zap.Int("quantity", 2))

	req := logger.With(zap.String("request_id", "5f2c9a1be07d44a3"))
	req.Error("sale failed", zap.Int("event_id", 2), zap.String("err", "not enough seats left"))

	sugar := logger.Sugar()
	sugar.Infow("ticket sold", "event_id", 1, "quantity", 2)
	sugar.Infof("%d tickets sold for event %d", 2, 1)
}
```

```
ana@vm:~/logothers$ go run ./zap
{"level":"info","ts":1792707620.004298,"caller":"zap/main.go:15","msg":"ticket sold","event_id":1,"quantity":2}
{"level":"error","ts":1792707620.0043795,"caller":"zap/main.go:18","msg":"sale failed","request_id":"5f2c9a1be07d44a3","event_id":2,"err":"not enough seats left","stacktrace":"main.main\n\t/home/ana/logothers/zap/main.go:18\nruntime.main\n\t/usr/local/go/src/runtime/proc.go:302"}
{"level":"info","ts":1792707620.0043929,"caller":"zap/main.go:21","msg":"ticket sold","event_id":1,"quantity":2}
{"level":"info","ts":1792707620.004404,"caller":"zap/main.go:22","msg":"2 tickets sold for event 1"}
```

- **`zap.NewProduction()`** is a ready configuration: JSON, `INFO` and above, a timestamp as seconds since
  1970 in `ts`, and **the file and line of the call in `caller`**.
- **`zap.Int`, `zap.String`** are typed fields, like slog's `slog.Int`.
- **The `ERROR` line carries a `stacktrace`**: the production configuration adds the stack to every
  error. That is useful the first time and a large cost on a service that logs many errors.
- **`Sugar()`** gives the convenient API. `Infow` takes key-value pairs like slog's `Info`; `Infof` builds the
  message with `Printf`, which section 02 argued against, and it is still there for code being migrated.
- **`defer logger.Sync()`** flushes buffered lines before the program exits. Forgetting it can lose the last
  lines a crashing program wrote, which are the ones that explain the crash.
