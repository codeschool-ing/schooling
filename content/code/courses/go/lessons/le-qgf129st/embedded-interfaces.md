---
title: Interfaces made of interfaces
version: 1
---

Lesson 16 embedded one struct in another and warned that it was not inheritance. Interfaces can be
embedded too, and the same warning applies with even more force: **an interface listed inside
another adds its methods to the list, and that is all it does.** There is no parent, no child, and
nothing a concrete type has to declare. The `io` package is built this way:

```
ana@vm:~/assert$ go doc io.ReadWriter
package io // import "io"

type ReadWriter interface {
	Reader
	Writer
}
    ReadWriter is the interface that groups the basic Read and Write methods.

ana@vm:~/assert$ go doc io.ReadWriteCloser
package io // import "io"

type ReadWriteCloser interface {
	Reader
	Writer
	Closer
}
    ReadWriteCloser is the interface that groups the basic Read, Write and Close
    methods.
```

`io.ReadWriter` names no method of its own. Its two lines say "every method of `Reader`, and every
method of `Writer`", which is `Read` and `Write`. `io.ReadWriteCloser` adds `Closer`, whose one
method is `Close() error`. Writing the three methods out by hand would declare exactly the same
interface. Embedding is shorter, and it keeps the definition of `Read` in one place.

## A bigger interface fits fewer types

Lesson 27's rule still decides who satisfies it: a type satisfies an interface when it has every
method the interface lists. A longer list is harder to meet, so each embedded interface leaves
fewer types inside:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
)

func main() {
	var buf bytes.Buffer
	var rw io.ReadWriter = &buf
	fmt.Fprint(rw, "into the buffer")

	var r io.Reader = rw
	data, err := io.ReadAll(r)
	fmt.Printf("%q %v\n", data, err)

	var rwc io.ReadWriteCloser = os.Stdout
	fmt.Printf("%T %T %T\n", rw, r, rwc)
}
```

```
ana@vm:~/assert$ go run .
"into the buffer" <nil>
*bytes.Buffer *bytes.Buffer *os.File
```

A `*bytes.Buffer` can be read and written, so it fits `io.ReadWriter`. `fmt.Fprint` wrote into it
through `rw`, and `io.ReadAll`, which reads a reader until it runs out, read the same bytes back
through `r`. `os.Stdout` is a `*os.File`, which has `Close` as well, so it fits all three
interfaces. And `var r io.Reader = rw` compiled with no ceremony: **a value that satisfies the
bigger interface satisfies every interface inside it**, because it has their methods. `%T` shows
that nothing was converted on the way. `rw`, `r` and the buffer are one `*bytes.Buffer` seen
through two different lists of methods.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three nested regions of types. The outer region is every type that satisfies io.Reader, which asks for Read; *strings.Reader sits there and nowhere deeper. Inside it is io.ReadWriter, which asks for Read and Write; *bytes.Buffer sits there. Innermost is io.ReadWriteCloser, which asks for Read, Write and Close; *os.File sits there, and so it also satisfies the two regions around it. Each embedded interface adds methods, and fewer types fit.\"><rect x=\"20\" y=\"20\" width=\"470\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">io.Reader</text><text x=\"370\" y=\"36\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks for</text><text x=\"378\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Read</text><rect x=\"50\" y=\"70\" width=\"410\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">io.ReadWriter</text><text x=\"340\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks for</text><text x=\"348\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Read Write</text><rect x=\"80\" y=\"120\" width=\"350\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">io.ReadWriteCloser</text><text x=\"310\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">asks for</text><text x=\"318\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Read Write Close</text><text x=\"255\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">*strings.Reader</text><text x=\"255\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">*bytes.Buffer</text><text x=\"255\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">*os.File</text><text x=\"515\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every method added</text><text x=\"515\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">leaves fewer types inside</text><text x=\"515\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a value in an inner region</text><text x=\"515\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">satisfies every region</text><text x=\"515\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">around it</text></svg>", "caption": "The sets of types that satisfy io.Reader, io.ReadWriter and io.ReadWriteCloser. Embedding grows the method list and shrinks the set."}
```

The compiler checks every step against those lists, and when a step does not fit, it names the
method that is missing:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"strings"
)

func main() {
	var buf bytes.Buffer
	var rwc io.ReadWriteCloser = &buf
	var sr io.ReadWriter = strings.NewReader("read only")

	var r io.Reader = &buf
	var rw io.ReadWriter = r
	fmt.Println(rwc, sr, rw)
}
```

```
ana@vm:~/assert-missing$ go build
# example.com/missing
./main.go:12:31: cannot use &buf (value of type *bytes.Buffer) as io.ReadWriteCloser value in variable declaration: *bytes.Buffer does not implement io.ReadWriteCloser (missing method Close)
./main.go:13:25: cannot use strings.NewReader("read only") (value of type *strings.Reader) as io.ReadWriter value in variable declaration: *strings.Reader does not implement io.ReadWriter (missing method Write)
./main.go:16:25: cannot use r (variable of interface type io.Reader) as io.ReadWriter value in variable declaration: io.Reader does not implement io.ReadWriter (missing method Write)
```

A buffer has nothing to close. A `*strings.Reader` reads a string and cannot be written to. The
third message is the interesting one. `r` holds the very `*bytes.Buffer` that line 12 used, which
can be written to, and the compiler refuses anyway, because it judges `r` by its type,
`io.Reader`, and an `io.Reader` promises `Read` and nothing else. **Going from a smaller interface
to a bigger one cannot be checked when the program is compiled**, and section 03 is the way to do
it while the program runs.

## Embedding in your own interfaces

An interface of your own can embed one from the standard library and add a method of its own.
`bufio.Writer` collects what you write in a buffer and passes it on in large pieces, and it only
passes the last piece on when you call its `Flush` method. A function that has to flush what it
wrote can ask for exactly that:

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

func greet(w FlushWriter, name string) error {
	fmt.Fprintf(w, "Hello, %s\n", name)
	return w.Flush()
}

func main() {
	out := bufio.NewWriter(os.Stdout)
	if err := greet(out, "Ana"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-flush$ go run .
Hello, Ana
```

`FlushWriter` is `io.Writer` plus `Flush() error`. A `*bufio.Writer` has both and fits, which is
why `greet` could call `w.Flush()`. `os.Stdout` writes straight to the terminal and has nothing to
flush, so it does not fit:

```go
package main

import (
	"fmt"
	"io"
	"os"
)

type FlushWriter interface {
	io.Writer
	Flush() error
}

func greet(w FlushWriter, name string) error {
	fmt.Fprintf(w, "Hello, %s\n", name)
	return w.Flush()
}

func main() {
	if err := greet(os.Stdout, "Bia"); err != nil {
		fmt.Println(err)
	}
}
```

```
ana@vm:~/assert-flush-stdout$ go build
# example.com/flush
./main.go:20:18: cannot use os.Stdout (variable of type *os.File) as FlushWriter value in argument to greet: *os.File does not implement FlushWriter (missing method Flush)
```

Two embedded interfaces may carry the same method. `io.ReadCloser` and `io.WriteCloser` both
include `Close() error`, and an interface built from both of them has one `Close`, not two:

```go
package main

import (
	"fmt"
	"io"
	"os"
)

type ReadWriteCloser interface {
	io.ReadCloser
	io.WriteCloser
}

func main() {
	var f ReadWriteCloser = os.Stdout
	fmt.Printf("%T\n", f)
}
```

```
ana@vm:~/assert-union$ go run .
*os.File
```

The method set is a set: a method with the same name and the same signature counts once. That is
what makes small interfaces combinable. Lesson 27 counted twelve interfaces of one method in `io`
and none of more than three, and **every bigger interface there is built by embedding smaller
ones**, the way this section built `FlushWriter`.
