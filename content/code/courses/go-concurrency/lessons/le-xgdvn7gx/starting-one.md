---
title: Starting one, and what main owes it
version: 1
---

The `go` keyword in front of a function call starts that call as a **goroutine**: a function that
runs on its own, beside the code that started it, which carries on at once without waiting. The
common first picture is that a started goroutine is safe until it finishes. **It is not: when
`main` returns, the program ends, and every goroutine still running ends with it**, mid-line if
need be.

## main does not wait

The smallest program that shows it starts one goroutine and returns, saved as `early.go`:

```go
// Command early starts a goroutine and returns from main straight away.
package main

import "fmt"

func main() {
	go fmt.Println("hello from a goroutine")
	fmt.Println("main is done")
}
```

Five runs:

```
ana@vm:~/goroutines$ go build -o early early.go
ana@vm:~/goroutines$ for i in 1 2 3 4 5; do ./early; done
main is done
main is done
main is done
main is done
main is done
```

Not one greeting in five runs. The `go` statement started the goroutine and `main` went straight on
to its own `Println`, then returned, and returning from `main` ends the process. The goroutine had
been created and had not yet been given a processor, and **nothing in the program asked anybody to
wait for it**. On another run, on a busier or an idler machine, the greeting can slip out first.
A program whose output depends on which of the two wins is the order problem of lesson 1, one
level down.

## Waiting on purpose

The repair is to make `main` wait, and to say what it is waiting for. Lesson 1 used a
`sync.WaitGroup` for that, and it does the job here too, saved as `waited.go`:

```go
// Command waited starts a goroutine and waits for it before returning.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	wg.Go(func() { fmt.Println("hello from a goroutine") })
	wg.Wait()
	fmt.Println("main is done")
}
```

```
ana@vm:~/goroutines$ go build -o waited waited.go
ana@vm:~/goroutines$ for i in 1 2 3 4 5; do ./waited; done
hello from a goroutine
main is done
hello from a goroutine
main is done
hello from a goroutine
main is done
hello from a goroutine
main is done
hello from a goroutine
main is done
```

**Five runs, five greetings, always before `main is done`**, because `wg.Wait` does not return until
the goroutine has. That order is promised, which is what lesson 1 section 04 meant by
synchronisation: `wg.Wait` returning is an event the program can rely on, where a goroutine
"probably being quick" is not. Adding `time.Sleep` to `main` would also have printed the greeting
on this machine, and it would have been a guess about timing written into the code.

## What the go statement does with its call

Three details of the statement itself catch people out.

- **The arguments are evaluated before the goroutine starts**, in the goroutine that runs the
  `go` statement. `go show(x)` copies the value `x` has at that moment.
- **The return values are thrown away.** There is no way to collect what a goroutine returns,
  which is why results travel back through a channel (lesson 3) or a variable guarded by a lock
  (lesson 8).
- **A panic in any goroutine ends the whole program.** It does not travel back to the goroutine
  that started it, and a `recover` in `main` cannot catch it.

The third is worth seeing once, saved as `crash.go`:

```go
// Command crash shows that a panic in a goroutine ends the program.
package main

import (
	"fmt"
	"sync"
)

func main() {
	defer fmt.Println("main's deferred call")
	var wg sync.WaitGroup
	wg.Go(func() {
		var m map[string]int
		m["oops"] = 1
	})
	wg.Wait()
	fmt.Println("main is done")
}
```

```
ana@vm:~/goroutines$ go run crash.go; echo "exit status: $?"
panic: assignment to entry in nil map [recovered, repanicked]

goroutine 7 [running]:
sync.(*WaitGroup).Go.func1.1()
	/usr/local/go/src/sync/waitgroup.go:251 +0x45
panic({0x55beb0?, 0x56e150?})
	/usr/local/go/src/runtime/panic.go:859 +0x125
main.main.func1()
	/home/ana/goroutines/crash.go:14 +0x28
sync.(*WaitGroup).Go.func1()
	/usr/local/go/src/sync/waitgroup.go:258 +0x4a
created by sync.(*WaitGroup).Go in goroutine 1
	/usr/local/go/src/sync/waitgroup.go:238 +0x7d
exit status 2
exit status: 1
```

The map was never made, so writing to it panics, and the panic ended the program with exit status
2. The go command's own `exit status: 1` follows it, as `go run` reports the failure of what it
ran. Two lines are worth finding. `main.main.func1()` at `crash.go:14` is the line that panicked,
and `created by sync.(*WaitGroup).Go in goroutine 1` names the goroutine that started this one:
goroutine 1 is `main`. **`main is done` and `main's deferred call` never printed.** The deferred
call belongs to `main`'s goroutine, and the process ended under it. The `[recovered, repanicked]`
note comes from `wg.Go`, which catches the panic only to raise it again from the goroutine that
failed, so the trace points at the right place.
