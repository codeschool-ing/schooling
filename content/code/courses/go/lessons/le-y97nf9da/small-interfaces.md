---
title: Small interfaces, declared where they are used
version: 1
---

A programmer used to class hierarchies tends to design an interface the way they would design a
base class: everything a kind of object can do, a dozen methods, written next to the type that
implements them. Go's standard library goes the other way, and the `io` package is the clearest
place to see it. This program asks the type checker, `go/types`, how many methods each interface
in `io` has. You do not need to follow how it works, only what it prints:

```go
package main

import (
	"fmt"
	"go/importer"
	"go/token"
	"go/types"
)

func main() {
	pkg, err := importer.ForCompiler(token.NewFileSet(), "source", nil).Import("io")
	if err != nil {
		fmt.Println(err)
		return
	}
	byCount := map[int][]string{}
	for _, name := range pkg.Scope().Names() {
		t := pkg.Scope().Lookup(name).Type()
		if t.String() != "io."+name || !types.IsInterface(t) {
			continue
		}
		n := types.NewMethodSet(t).Len()
		byCount[n] = append(byCount[n], name)
	}
	for n := 1; n <= 3; n++ {
		fmt.Println(n, len(byCount[n]), byCount[n])
	}
}
```

```
ana@vm:~/ifaces-count$ go run .
1 12 [ByteReader ByteWriter Closer Reader ReaderAt ReaderFrom RuneReader Seeker StringWriter Writer WriterAt WriterTo]
2 7 [ByteScanner ReadCloser ReadSeeker ReadWriter RuneScanner WriteCloser WriteSeeker]
3 3 [ReadSeekCloser ReadWriteCloser ReadWriteSeeker]
```

Twenty-two interfaces, and **twelve of them have exactly one method**. None has more than three,
and the bigger ones are the small ones put together: a `ReadWriter` is a `Reader` and a `Writer`,
which lesson 29 shows being written. The method set of lesson 26 is what the program counted.

## Why one method is the useful size

Every method an interface adds is one more thing a type must have before it fits. An interface
with ten methods is satisfied by the few types written for it; an interface with one is satisfied
by every type that happens to do that one thing. `io.Reader` is the other half of `io.Writer`:

```
ana@vm:~/ifaces-count$ go doc io.Reader | head -5
package io // import "io"

type Reader interface {
	Read(p []byte) (n int, err error)
}
```

A function that needs to read and nothing more should ask for exactly that. This one counts the
words in whatever it is given:

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"
)

func countWords(r io.Reader) (int, error) {
	sc := bufio.NewScanner(r)
	sc.Split(bufio.ScanWords)
	n := 0
	for sc.Scan() {
		n++
	}
	return n, sc.Err()
}

func main() {
	n, err := countWords(strings.NewReader("one function, three readers"))
	fmt.Println("string:", n, err)

	f, err := os.Open("notes.txt")
	if err != nil {
		fmt.Println(err)
		return
	}
	n, err = countWords(f)
	f.Close()
	fmt.Println("file:  ", n, err)

	n, err = countWords(os.Stdin)
	fmt.Println("stdin: ", n, err)
}
```

```
ana@vm:~/ifaces-reader$ printf 'typed into a pipe\n' | go run .
string: 4 <nil>
file:   12 <nil>
stdin:  4 <nil>
```

`bufio.Scanner` reads from any `io.Reader` and hands back one word per `Scan`; `<nil>` is how a
missing error prints, and lesson 32 is about errors. The same function counted a string in memory,
the two lines of `notes.txt` and what the shell piped into the program. Had it asked for an
`*os.File`, it would have taken the file and `os.Stdin`, which is an `*os.File` too, and the string
would have had to be written to disk first. **Asking for the smallest interface that does the job
is what lets a function serve callers its author never thought of.**

## Accept interfaces, return concrete types

The other half of the habit is on the way out. The functions that make readers do not return an
`io.Reader`. They return their own type:

```
ana@vm:~/ifaces-reader$ go doc strings.NewReader
package strings // import "strings"

func NewReader(s string) *Reader
    NewReader returns a new Reader reading from s. It is similar to
    bytes.NewBufferString but more efficient and non-writable.

ana@vm:~/ifaces-reader$ go doc os.Open | head -3
package os // import "os"

func Open(name string) (*File, error)
```

`os.Open` returns an `*os.File`, with all of its methods: `Read`, but also `Close`, which the
program above needed, and `Write`, `Stat` and the rest. Had it returned an `io.Reader`, the caller
would have lost `Close` and could not get it back without the type assertions of lesson 29. A
concrete result costs the caller nothing, because it can still be passed wherever an interface is
asked for, as `f` was. **Accept the smallest interface you need, and return the concrete type you
have.**

## Declare the interface next to the code that needs it

Because nothing has to name an interface to satisfy it, the interface does not have to live with
the types. It can live with the function that uses it, even in a program that owns none of the
types:

```go
package main

import (
	"fmt"
	"time"
)

type labeler interface {
	String() string
}

func show(items ...labeler) {
	for _, it := range items {
		fmt.Printf("%-15T %s\n", it, it.String())
	}
}

func main() {
	show(90*time.Minute, time.Saturday, time.August)
}
```

```
ana@vm:~/ifaces-local$ go run .
time.Duration   1h30m0s
time.Weekday    Saturday
time.Month      August
```

`labeler` was written for this program, with a lower-case name so that no other package can see
it (lesson 39). `time.Duration`, `time.Weekday` and `time.Month` are from the standard library, and each has a
`String` method: it is why `time.Saturday` printed as `Saturday` with `%v` in lesson 6. All three satisfy an interface
that did not exist until this file was written. In a language where a type lists the interfaces it
implements, `show` would need a change to the `time` package first.

That is the reason for the advice to define an interface where it is used, not where it is
implemented. The function knows which methods it calls, so it is the one that can say how small
the interface can be, and **the types it accepts never have to change to fit it**.
