---
title: Three loggers, measured
version: 1
---

Each of the three libraries claims to be fast, and the claims are easy to test. This program logs the same
line, a message and three fields, with each logger and API, writing to `io.Discard` so that only the
logging is measured, and reports time and memory per line with the `testing` package's benchmark machinery
used outside a test, as lesson 11 did:

```go
// logothers/bench/main.go
package main

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"testing"

	"github.com/rs/zerolog"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func report(name string, r testing.BenchmarkResult) {
	fmt.Printf("%-14s %6d ns/line %4d allocs/line %5d B/line\n",
		name, r.NsPerOp(), r.AllocsPerOp(), r.AllocedBytesPerOp())
}

func main() {
	ctx := context.Background()
	s := slog.New(slog.NewJSONHandler(io.Discard, nil))
	report("slog", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			s.Info("ticket sold", "event_id", 1, "quantity", 2, "request_id", "5f2c9a1be07d44a3")
		}
	}))
	report("slog LogAttrs", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			s.LogAttrs(ctx, slog.LevelInfo, "ticket sold",
				slog.Int("event_id", 1), slog.Int("quantity", 2), slog.String("request_id", "5f2c9a1be07d44a3"))
		}
	}))

	z := zerolog.New(io.Discard).With().Timestamp().Logger()
	report("zerolog", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			z.Info().Int("event_id", 1).Int("quantity", 2).Str("request_id", "5f2c9a1be07d44a3").Msg("ticket sold")
		}
	}))

	core := zapcore.NewCore(zapcore.NewJSONEncoder(zap.NewProductionEncoderConfig()), zapcore.AddSync(io.Discard), zap.InfoLevel)
	zl := zap.New(core)
	report("zap", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			zl.Info("ticket sold", zap.Int("event_id", 1), zap.Int("quantity", 2), zap.String("request_id", "5f2c9a1be07d44a3"))
		}
	}))
	zs := zl.Sugar()
	report("zap sugared", testing.Benchmark(func(b *testing.B) {
		b.ReportAllocs()
		for b.Loop() {
			zs.Infow("ticket sold", "event_id", 1, "quantity", 2, "request_id", "5f2c9a1be07d44a3")
		}
	}))
}
```

```
ana@vm:~/logothers$ go run ./bench
slog              610 ns/line    0 allocs/line     0 B/line
slog LogAttrs     568 ns/line    0 allocs/line     0 B/line
zerolog           215 ns/line    0 allocs/line     0 B/line
zap               468 ns/line    1 allocs/line   192 B/line
zap sugared       690 ns/line    1 allocs/line   384 B/line
ana@vm:~/logothers$ go run ./bench
slog              667 ns/line    0 allocs/line     0 B/line
slog LogAttrs     598 ns/line    0 allocs/line     0 B/line
zerolog           216 ns/line    0 allocs/line     0 B/line
zap               450 ns/line    1 allocs/line   192 B/line
zap sugared       777 ns/line    1 allocs/line   384 B/line
```

**zerolog is the fastest by a wide margin**, about 215 nanoseconds a line against 450 to 470 for zap and
570 to 670 for slog. slog's `LogAttrs`, which takes typed attributes, is slightly faster than its key-value
`Info`. **slog and zerolog allocated nothing per line; zap allocated once**, 192 bytes, and the sugared API
twice as many bytes.

**Now put the numbers in proportion.** Lesson 6 measured a request against PostgreSQL in milliseconds,
that is millions of nanoseconds. boxoffice writes one access line per request; the difference between the
fastest and the slowest logger here is about half a microsecond on that line, a few hundredths of one per
cent of the request. **For a service like boxoffice, the speed of the logger does not matter**, and the
deciding questions are elsewhere:

| | slog | zerolog | zap |
|---|---|---|---|
| where it comes from | the standard library, since Go 1.21 | a module | a module |
| API | key-value or typed attributes | a chain ending in `Msg` | typed `Logger`, or `SugaredLogger` |
| default level | `INFO` | everything | depends on the configuration chosen |
| swapping the format or destination | write or pick a `slog.Handler` | its own writers | its own cores and encoders |
| libraries you depend on can log through it | yes: `slog.Logger` is the shared type | only if they chose zerolog | only if they chose zap |

The last row is the decisive one. **Because slog is in the standard library, a library can accept a
`*slog.Logger` and every application can give it theirs.** Both zerolog and zap can sit behind slog, as a
handler, for a team that wants their speed with slog's API. boxoffice uses slog, and a service that logs a
hundred thousand lines a second might measure again.
