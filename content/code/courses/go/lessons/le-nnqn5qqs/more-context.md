---
title: "More context: GOTRACEBACK, debug.Stack and slog"
version: 1
---

A trace is usually pictured as all or nothing: the runtime prints it when the program dies, and a
program that recovers has nothing to print. Neither half is true. **How much the runtime prints is a
setting, and a program that recovers can ask for the trace itself.** This section does both, with
the order program of section 02.

## `GOTRACEBACK`

The environment variable `GOTRACEBACK` decides how much a dying program prints. The `runtime`
package documents it in one paragraph:

```
ana@vm:~/stacks$ go doc runtime | sed -n 243,260p
The GOTRACEBACK variable controls the amount of output generated when a Go
program fails due to an unrecovered panic or an unexpected runtime condition.
By default, a failure prints a stack trace for the current goroutine, eliding
functions internal to the run-time system, and then exits with exit code 2.
The failure prints stack traces for all goroutines if there is no current
goroutine or the failure is internal to the run-time. GOTRACEBACK=none omits
the goroutine stack traces entirely. GOTRACEBACK=single (the default) behaves
as described above. GOTRACEBACK=all adds stack traces for all user-created
goroutines. GOTRACEBACK=system is like “all” but adds stack frames for
run-time functions and shows goroutines created internally by the run-time.
GOTRACEBACK=crash is like “system” but crashes in an operating system-specific
manner instead of exiting. For example, on Unix systems, the crash raises
SIGABRT to trigger a core dump. GOTRACEBACK=wer is like “crash” but doesn't
disable Windows Error Reporting (WER). For historical reasons, the GOTRACEBACK
settings 0, 1, and 2 are synonyms for none, all, and system, respectively.
The runtime/debug.SetTraceback function allows increasing the amount of output
at run time, but it cannot reduce the amount below that specified by the
environment variable.
```

`none` is the one that takes something away:

```
ana@vm:~/stacks$ GOTRACEBACK=none ./stacks; echo $?
panic: runtime error: index out of range [4] with length 4
2
```

The message and the exit status survive and every frame is gone, so nobody can say which index
went wrong. **The default, `single`, is the right setting for almost every program**, and the
useful moves are upwards. `all` adds every goroutine the program started, which is what a server
needs when the goroutine that panicked was waiting on another one; the `go-concurrency` course
writes programs where that matters. `system` adds the runtime's own frames and goroutines, which
matter to somebody chasing a bug in Go itself. `crash` also leaves a core dump, a copy of the
process's memory, for a debugger to open afterwards.

The variable belongs to whoever starts the program, a service definition or a container's
environment, and it applies without rebuilding anything.

## The trace of a panic you recovered

Lesson 36 put a recover at a boundary so that one bad request or one bad job would not end the
program. That recover has a cost: the runtime prints a trace only for a panic that kills the
program, so **a recovered panic leaves no trace unless the program writes one**. A log line that
says `index out of range` and nothing else sends somebody searching the whole code base for an
index.

`~/stacks-jobs` prices three orders, one at a time, with the same four functions as `~/stacks`.
`price` handles one order and is the boundary:

```go
func price(id int, lines []line) {
	defer func() {
		if r := recover(); r != nil {
			slog.Error("order failed", "order", id, "panic", r)
			os.Stderr.Write(debug.Stack())
		}
	}()
	slog.Info("order priced", "order", id, "total", orderTotal(lines))
}

func main() {
	log.SetFlags(0) // slog's default output goes through log
	orders := [][]line{
		{{"coffee", 2}},
		{{"cake", 4}},
		{{"coffee", 1}, {"cake", 1}},
	}
	for i, o := range orders {
		price(i+1, o)
	}
}
```

```
ana@vm:~/stacks-jobs$ go build && ./jobs; echo $?
INFO order priced order=1 total=854
ERROR order failed order=2 panic="runtime error: index out of range [4] with length 4"
goroutine 1 [running]:
runtime/debug.Stack()
	/usr/local/go/src/runtime/debug/stack.go:26 +0x5e
main.price.func1()
	/home/ana/stacks-jobs/main.go:41 +0xfe
panic({0x675570?, 0x2e62bc970030?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
main.unitPrice(...)
	/home/ana/stacks-jobs/main.go:22
main.lineTotal(...)
	/home/ana/stacks-jobs/main.go:26
main.orderTotal(...)
	/home/ana/stacks-jobs/main.go:32
main.price(0x2, {0x2e62bc9ebe30?, 0x2e62bc9bce38?, 0x41e8f9?})
	/home/ana/stacks-jobs/main.go:44 +0x1fd
main.main()
	/home/ana/stacks-jobs/main.go:55 +0x12f
INFO order priced order=3 total=1150
0
```

Order 2 failed and orders 1 and 3 were priced. The program finished with status 0, because no panic
reached the top of a goroutine. Two packages did the work in the deferred function.

**`log/slog` writes structured log lines.** `slog.Info` and `slog.Error` take a message and then
pairs of a key and a value, and print them as `key=value`, so `order=2` can be searched for, and
counted, by whatever collects the logs. `slog` hands its default output to the `log` package, which
is why `log.SetFlags(0)` took the date off the start of each line, as it did for the server in
lesson 36:

```
ana@vm:~/stacks-jobs$ go doc log/slog | sed -n 30,33p
The default handler formats the log record's message, time, level, and
attributes as a string and passes it to the log package.

    2022/11/08 15:28:26 INFO hello count=3
```

A service usually swaps the default for a handler that writes one JSON object per line, a format
log systems read without being taught it:

```
ana@vm:~/stacks-jobs$ go doc log/slog | sed -n 50,57p
The package also provides JSONHandler, whose output is line-delimited JSON:

    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
    logger.Info("hello", "count", 3)

produces this output:

    {"time":"2022-11-08T15:28:26.000000000-05:00","level":"INFO","msg":"hello","count":3}
```

**`debug.Stack` returns the trace of the goroutine that calls it**, formatted exactly as the runtime
prints one:

```
ana@vm:~/stacks-jobs$ go doc runtime/debug.Stack
package debug // import "runtime/debug"

func Stack() []byte
    Stack returns a formatted stack trace of the goroutine that calls it. It
    calls runtime.Stack with a large enough buffer to capture the entire trace.

```

Read the trace it wrote from the top. `runtime/debug.Stack` is the call that took the picture.
`main.price.func1` is the deferred function literal, which the compiler names after the function it
sits in. `panic` is the runtime function that was running the panic. And under those three, still
there, are `unitPrice`, `lineTotal` and `orderTotal`, the frames the panic was leaving. **A deferred
function runs on top of the frames that panicked**, before they are taken off the stack, which is
why a trace taken inside it still shows line 22, where the bug is.

The values in parentheses on the `panic` and `main.price` lines are addresses in memory, and they
are not the same from one run to the next:

```
ana@vm:~/stacks-jobs$ for i in 1 2; do ./jobs 2>&1 | grep '^panic('; done
panic({0x675570?, 0x32f11243a030?})
panic({0x675570?, 0x17250a3a000?})
```

The type word, `0x675570`, stayed put and the second word moved, which is why this lesson quotes one
run of each. **Compare traces by function, file and line, never by the hexadecimal values.** Two
crashes on the same line are one bug, whatever their addresses say.

In a real service the trace belongs in the log record itself rather than in a separate write to
standard error, so that the line reporting the failure and the trace explaining it stay together:
`string(debug.Stack())` is one more value for one more key.
