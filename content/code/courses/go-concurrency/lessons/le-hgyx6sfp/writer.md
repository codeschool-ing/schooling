---
title: The Writer, and where a program's output can go
version: 1
---

`io.Writer` is the mirror image: one method, `Write(p []byte) (n int, err error)`, which takes the
bytes in `p` and says how many it took. **Its contract is stricter than Read's on one point: a
Writer that takes fewer than `len(p)` bytes must return an error saying why.** A caller can
therefore check `err` alone and know whether everything went.

The useful consequence is that a function which writes its output to an `io.Writer`, rather than
straight to the screen, has decided nothing about where the output goes. This program writes one
small report three times, saved as `writer.go`:

```go
// Command writer sends one report to three different destinations.
package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
)

func report(w io.Writer) {
	fmt.Fprintf(w, "served %d requests\n", 42)
	fmt.Fprintf(w, "slowest took %s\n", "180ms")
}

func main() {
	report(os.Stdout)

	var buf bytes.Buffer
	report(&buf)
	fmt.Printf("the buffer holds %d bytes\n", buf.Len())

	h := sha256.New()
	report(h)
	fmt.Printf("sha256 %x\n", h.Sum(nil))
}
```

```
ana@vm:~/rw$ go run writer.go
served 42 requests
slowest took 180ms
the buffer holds 38 bytes
sha256 ff1ea3dc3e39037131f06e56f9619e42783fd71fda2916692a9334fffc4aaec5
ana@vm:~/rw$ printf "served 42 requests\nslowest took 180ms\n" | sha256sum
ff1ea3dc3e39037131f06e56f9619e42783fd71fda2916692a9334fffc4aaec5  -
```

**Three destinations, one function, no change to it.** `os.Stdout` is the terminal. A
`bytes.Buffer` keeps the 38 bytes in memory, which is what a test does in lesson 25 to check what a
function printed. And `sha256.New()` returns a hash that is also a Writer: what goes in is never
stored, only digested. The shell's own `sha256sum`, given the same two lines, agrees to the last
digit, which is a cheap way to be sure the report wrote exactly what it seemed to.

`fmt.Fprintf` is the function that made this possible. `fmt.Printf` is `Fprintf` with `os.Stdout`
filled in, and every `Print` function has an `F` twin that takes a Writer first.

## Writing one

A Writer of your own is as short as a Reader. The common shape wraps another Writer and does
something on the way through; this one counts, saved as `counting.go`:

```go
// Command counting wraps a Writer in one that counts what passes through.
package main

import (
	"fmt"
	"io"
	"os"
)

type counter struct {
	w io.Writer
	n int64
}

func (c *counter) Write(p []byte) (int, error) {
	n, err := c.w.Write(p)
	c.n += int64(n)
	return n, err
}

func main() {
	c := &counter{w: os.Stdout}
	fmt.Fprintln(c, "one line")
	fmt.Fprintln(c, "and another")
	fmt.Println("bytes written:", c.n)
}
```

```
ana@vm:~/rw$ go run counting.go
one line
and another
bytes written: 21
```

Nine bytes and twelve, newlines included, make 21. **The wrapper passes on the inner Writer's `n`
and `err` unchanged**, so whoever writes through it sees exactly what they would have seen
without it, and adds only what it was written for. That pattern, a type that holds an `io.Writer`
and is one, is how `bufio.Writer` in lesson 18 and the log handlers of lesson 22 are built.

One warning carries over from the first half. `counter` is not safe for two goroutines at once:
`c.n += int64(n)` is lesson 1's lost update waiting to happen. `os.Stdout` itself may be written
from several goroutines, but a wrapper with state of its own needs the lock lesson 16 put into
`Cache`.
