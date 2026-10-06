---
title: Asking an interface what it holds
version: 1
---

Lesson 28 wrote `x.(T)` and paid for a wrong guess with a panic. That form is right when a wrong
type would be a bug. When a wrong type is a possibility the program should handle, there is a
second form, and it is the one you will write most often. **`v, ok := x.(T)` does not panic: it
answers with the value and a boolean saying whether `x` held a `T`.** It is the comma-ok of lesson
14, which asked a map whether it had a key, now asking an interface what type it holds:

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	var doc map[string]any
	if err := json.Unmarshal([]byte(`{"name": "Ana", "age": 31}`), &doc); err != nil {
		fmt.Println(err)
		return
	}

	for _, k := range []string{"age", "name", "email"} {
		n, ok := doc[k].(float64)
		fmt.Printf("%-6s %v %v\n", k, n, ok)
	}

	email := doc["email"].(string)
	fmt.Println(email)
}
```

```
ana@vm:~/assert-ok$ go run .
age    31 true
name   0 false
email  0 false
panic: interface conversion: interface {} is nil, not string

goroutine 1 [running]:
main.main()
	/home/ana/assert-ok/main.go:20 +0x327
exit status 2
```

`age` held a `float64`, so `n` is 31 and `ok` is true. `name` held a string, and the assertion
answered false with `n` at the zero value of `float64`. `email` is not in the map at all, so
`doc["email"]` gave the zero value of `any`, an interface holding nothing, and asking it for a
`float64` answered false as well. Nothing stopped until the last line, where the single-result form
asked the same empty interface for a `string`, and the panic said what it found:
`interface {} is nil, not string`.

So the choice of form says something about the program. `x.(T)` says "if this is not a `T`, the
code around it is wrong, so stop". `v, ok := x.(T)` says "it may not be a `T`, and here is what
happens then". Reading values out of a document somebody else wrote is the second case almost
every time.

## Asserting to an interface: what else can you do?

`T` does not have to be a concrete type. When it is an interface, the assertion asks whether the
value inside has the methods that interface lists. That turns it into a question about
**capability**: this value was handed over as an `io.Writer`, so can it do anything more?

A function that writes a report to any `io.Writer` shows why the question matters. Here it is
handed a `*bufio.Writer`, which keeps what it is given in its buffer until somebody calls `Flush`:

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

func report(w io.Writer, lines ...string) error {
	for _, l := range lines {
		if _, err := fmt.Fprintln(w, l); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	if err := report(os.Stdout, "straight to the terminal"); err != nil {
		fmt.Println(err)
	}
	if err := report(bufio.NewWriter(os.Stdout), "through a bufio.Writer"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-lost$ go run .
straight to the terminal
```

The second line is gone. `report` wrote it into the buffer, returned no error, and the program
ended with the line still sitting there. `report` cannot ask for a `FlushWriter` like section 02's
`greet`, because then `os.Stdout` could not be passed to it. So it keeps asking for an `io.Writer`,
and checks for the extra method while it runs:

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

type FlushWriter interface {
	io.Writer
	Flush() error
}

func report(w io.Writer, lines ...string) error {
	for _, l := range lines {
		if _, err := fmt.Fprintln(w, l); err != nil {
			return err
		}
	}
	if f, ok := w.(FlushWriter); ok {
		return f.Flush()
	}
	return nil
}

func main() {
	if err := report(os.Stdout, "straight to the terminal"); err != nil {
		fmt.Println(err)
	}
	if err := report(bufio.NewWriter(os.Stdout), "through a bufio.Writer"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-cap$ go run .
straight to the terminal
through a bufio.Writer
```

`w.(FlushWriter)` asks whether the value inside `w` also has `Flush() error`. For `os.Stdout` the
answer is false and nothing more happens. For the `*bufio.Writer` it is true, `f` is the same
writer seen as a `FlushWriter`, and `f.Flush()` sends the line on. **The function still accepts
every writer, and takes the extra step for the ones that can.** This is the step section 02 said
the compiler cannot check, from a smaller interface to a bigger one, made while the program runs.

The standard library does this in many places. `io.Copy`, which copies everything from a reader to
a writer, starts by asking both of them whether they know a faster way:

```
ana@vm:~/assert$ sed -n 407,416p /usr/local/go/src/io/io.go
func copyBuffer(dst Writer, src Reader, buf []byte) (written int64, err error) {
	// If the reader has a WriteTo method, use it to do the copy.
	// Avoids an allocation and a copy.
	if wt, ok := src.(WriterTo); ok {
		return wt.WriteTo(dst)
	}
	// Similarly, if the writer has a ReadFrom method, use it to do the copy.
	if rf, ok := dst.(ReaderFrom); ok {
		return rf.ReadFrom(src)
	}
ana@vm:~/assert$ sed -n 588,594p /usr/local/go/src/bufio/bufio.go
// size, it returns the underlying [Writer].
func NewWriterSize(w io.Writer, size int) *Writer {
	// Is it already a Writer?
	b, ok := w.(*Writer)
	if ok && len(b.buf) >= size {
		return b
	}
```

`io.Copy` calls `copyBuffer`, and its first two statements are assertions to interfaces. A
`*bytes.Buffer` has a `WriteTo` method, so copying from one hands the whole job to the buffer, which
already holds every byte and needs no loop of reads. `NewWriterSize`, which `bufio.NewWriter`
calls, asserts to a concrete type instead: if the writer it was given is already a `*bufio.Writer`
with a big enough buffer, it returns that writer rather than wrapping a buffer around a buffer.

## What the compiler still refuses

Assertions only make sense on interfaces, and the compiler checks what it can:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
)

func main() {
	n := 3
	s := n.(string)

	var r io.Reader = &bytes.Buffer{}
	b := r.(bytes.Buffer)
	fmt.Println(s, b)
}
```

```
ana@vm:~/assert-bad$ go build
# example.com/bad
./main.go:11:7: invalid operation: n (variable of type int) is not an interface
./main.go:14:7: impossible type assertion: r.(bytes.Buffer)
	bytes.Buffer does not implement io.Reader (method Read has pointer receiver)
```

`n` is an `int`. Its type is known exactly, so there is nothing to ask, and the compiler says `n`
is not an interface. The second error is subtler. `bytes.Buffer`, without the `*`, can never be
inside an `io.Reader`, because its `Read` method has a pointer receiver, the method-set rule of
lesson 26. **An assertion that could only ever fail is refused as impossible**, before anything
runs. `r.(*bytes.Buffer)` would have compiled, and succeeded.
