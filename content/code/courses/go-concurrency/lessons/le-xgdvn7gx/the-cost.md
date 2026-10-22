---
title: What a goroutine costs
version: 1
---

A goroutine is not an operating-system thread, and the difference is a matter of size. **A thread
reserves megabytes of stack when it is created; a goroutine starts with a few kilobytes and grows
only if it needs to.** That is why a Go server can hold one goroutine per connection, tens of
thousands of them, where a server built on threads has to pool them.

The claim deserves a measurement. This program starts a hundred thousand goroutines that all wait
on one channel, reports what they cost, then lets them go, saved as `many.go`:

```schooling-example
{"language": "go", "file": "many.go", "parts": [{"code": "// Command many starts a hundred thousand goroutines that all wait on one channel.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"sync\"\n\t\"time\"\n)\n\n", "note": "Nothing but the standard library. `runtime` is where the program asks about its own goroutines and memory."}, {"code": "func stack() uint64 {\n\tvar m runtime.MemStats\n\truntime.ReadMemStats(&m)\n\treturn m.StackInuse\n}\n\n", "note": "**`StackInuse` is the memory the runtime holds as goroutine stacks**, in bytes. Reading it before and after the goroutines start gives what they added."}, {"code": "func main() {\n\tconst n = 100_000\n\tbefore := stack()\n\tstart := time.Now()\n\n\trelease := make(chan struct{})\n\tvar wg sync.WaitGroup\n\tfor range n {\n\t\twg.Go(func() { <-release })\n\t}\n\telapsed := time.Since(start)\n\n", "note": "Each goroutine does one thing: wait to receive from `release`. Nothing is ever sent on it, so all of them stay alive until it is closed. Lesson 3 explains channels; here one is only a gate."}, {"code": "\tfmt.Println(\"goroutines:\", runtime.NumGoroutine())\n\tfmt.Println(\"started in:\", elapsed.Round(time.Millisecond))\n\tfmt.Println(\"stack memory:\", (stack()-before)/1024/1024, \"MiB\")\n\tfmt.Println(\"per goroutine:\", (stack()-before)/n, \"bytes\")\n\n", "note": "`runtime.NumGoroutine` counts every goroutine alive at that moment, `main` included."}, {"code": "\tclose(release)\n\twg.Wait()\n\tfmt.Println(\"after they return:\", runtime.NumGoroutine())\n}\n", "note": "Closing the channel releases every waiting receiver at once. When `wg.Wait` returns, all hundred thousand have finished, and the count drops back."}]}
```

```
ana@vm:~/goroutines$ go build -o many many.go
ana@vm:~/goroutines$ ./many
goroutines: 100001
started in: 424ms
stack memory: 195 MiB
per goroutine: 2048 bytes
after they return: 1
ana@vm:~/goroutines$ ulimit -s
8192
```

A hundred thousand goroutines started in 424 milliseconds, about four microseconds each, and their
stacks took 195 MiB between them: **2048 bytes each, two kilobytes**. That is where a goroutine's
stack starts. If a function call needs more, the runtime copies the stack to a bigger one and
carries on, and it can shrink it again later; nobody declares a size.

`ulimit -s` prints the stack the system gives each new thread, in kilobytes: 8192, so 8 MiB for one
thread. Most of that is reserved address space rather than memory in use, but it is reserved up
front, and creating a thread is a system call each time. **A goroutine is about four thousand
times smaller at birth**, and starting one never leaves the process.

The count also deserves a look. `NumGoroutine` said 100001: the hundred thousand, plus `main`. After
`close`, it said 1. **A goroutine that returns is gone, stack and all**, and a goroutine that never
returns is not, which is lesson 6's subject: a goroutine stuck forever on a channel nobody will
close costs those two kilobytes and everything it refers to, for as long as the program runs.

Cheap is not free. Each of these goroutines did nothing; a real one holds buffers, connections
and the data it is working on, and that is what fills memory. The point of the measurement is the
floor: **the goroutine itself is never the reason not to start one**.
