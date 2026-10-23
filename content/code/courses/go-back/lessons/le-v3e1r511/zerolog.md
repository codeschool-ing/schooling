---
title: zerolog
version: 1
---

zerolog was written to log without allocating memory, and its API is shaped by that goal: **a chain of
typed calls that writes JSON as it goes**, ending in `Msg`, which writes the line. It was one of the two
loggers most Go services used before slog existed. Both it and zap live in one small module here, with
the benchmark of section 07:

```go
// logothers/zerolog/main.go
package main

import (
	"os"

	"github.com/rs/zerolog"
)

func main() {
	logger := zerolog.New(os.Stdout).With().Timestamp().Logger()
	logger.Info().Int("event_id", 1).Int("quantity", 2).Msg("ticket sold")

	req := logger.With().Str("request_id", "5f2c9a1be07d44a3").Logger()
	req.Error().Int("event_id", 2).Str("err", "not enough seats left").Msg("sale failed")

	logger.Debug().Int("event_id", 1).Msg("seats re-read")
	zerolog.SetGlobalLevel(zerolog.InfoLevel)
	logger.Debug().Int("event_id", 1).Msg("seats re-read again")
}
```

```
ana@vm:~/logothers$ go mod init example.com/logothers
go: creating new go.mod: module example.com/logothers
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/logothers$ go mod tidy
go: finding module for package go.uber.org/zap/zapcore
go: finding module for package github.com/rs/zerolog
go: finding module for package go.uber.org/zap
go: found github.com/rs/zerolog in github.com/rs/zerolog v1.35.1
go: found go.uber.org/zap in go.uber.org/zap v1.28.0
go: found go.uber.org/zap/zapcore in go.uber.org/zap v1.28.0
```

```
ana@vm:~/logothers$ go run ./zerolog
{"level":"info","event_id":1,"quantity":2,"time":"2026-10-22T19:20:19-03:00","message":"ticket sold"}
{"level":"error","request_id":"5f2c9a1be07d44a3","event_id":2,"err":"not enough seats left","time":"2026-10-22T19:20:19-03:00","message":"sale failed"}
{"level":"debug","event_id":1,"time":"2026-10-22T19:20:19-03:00","message":"seats re-read"}
```

- **`logger.Info()` starts a line, `.Int(...)` and `.Str(...)` add typed fields, `.Msg(...)` finishes it.**
  A line that is started and never finished with `Msg` is never written, which is the classic zerolog bug.
- **`With()...Logger()`** makes a logger that carries fields, slog's `With` in zerolog's shape.
- **The field names are zerolog's own**: `level` in lower case, `message` rather than `msg`, and a `time`
  with whole seconds unless configured otherwise. Log platforms are configured to know which names a
  service uses; mixing loggers in one system means configuring that twice.
- **The first `Debug` was written.** zerolog's default level lets everything through until
  `SetGlobalLevel` is called; after it, the second debug line was dropped. slog's default drops `DEBUG`;
  a team moving between the two finds out the first night the logs are ten times larger.

The chain style is fast, section 07 measures how fast, and it has a cost in reading: a line is spread over
method calls, and forgetting `Msg` is a silent failure the compiler does not catch.
