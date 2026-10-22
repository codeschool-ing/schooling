---
title: The Reader, and the contract behind one method
version: 1
---

This lesson opens the second half of the course. Lessons 1 to 16 were about running many things at
once; lessons 17 to 30 are about the standard library those things are made of, and how to test
them. **It starts with two interfaces, because most of the standard library reads through one and
writes through the other.** A file, a network connection, an HTTP body, a compressed stream, a
string in memory: each is an `io.Reader`, and code written against `io.Reader` works on all of them
without knowing which it was given.

The work of this lesson lives in `~/rw`, made with `go mod init example.com/rw`. `go doc` prints
the interface from the standard library's own source:

```
ana@vm:~/rw$ go doc io.Reader | head -12
package io // import "io"

type Reader interface {
	Read(p []byte) (n int, err error)
}
    Reader is the interface that wraps the basic Read method.

    Read reads up to len(p) bytes into p. It returns the number of bytes read (0
    <= n <= len(p)) and any error encountered. Even if Read returns n < len(p),
    it may use all of p as scratch space during the call. If some data is
    available but not len(p) bytes, Read conventionally returns what is
    available instead of waiting for more.
```

**One method.** `Read` fills as much of `p` as it can, says how many bytes it put there in `n`, and
reports in `err` anything that went wrong, including the end of the data, which is the error value
`io.EOF`. The paragraph under it is the contract, and the rest of `go doc io.Reader` carries on in
the same vein; the parts that matter in practice are in this section.

## Calling it by hand

Nobody calls `Read` by hand in real code, which is exactly why doing it once is worth it. A
`strings.Reader` reads from a string, eight bytes at a time, saved as `reader.go`:

```go
// Command reader calls Read by hand, eight bytes at a time.
package main

import (
	"fmt"
	"io"
	"strings"
)

func main() {
	r := strings.NewReader("concurrency is not parallelism")
	buf := make([]byte, 8)
	for {
		n, err := r.Read(buf)
		fmt.Printf("n=%d err=%v %q\n", n, err, buf[:n])
		if err == io.EOF {
			break
		}
	}
}
```

```
ana@vm:~/rw$ go run reader.go
n=8 err=<nil> "concurre"
n=8 err=<nil> "ncy is n"
n=8 err=<nil> "ot paral"
n=6 err=<nil> "lelism"
n=0 err=EOF ""
```

Thirty bytes came out as 8, 8, 8 and 6, and then a call that returned nothing and `EOF`. **The
caller uses `buf[:n]` and never `buf`**: the fourth call filled only six bytes, and the last two
bytes of `buf` still held `al` from the third. Printing `buf` whole would have printed old data as
if it were new.

## Writing one

Any type with that method is a Reader. This one produces the alphabet, saved as `alphabet.go`:

```go
// Command alphabet is a Reader of its own: the letters a to z, then the end.
package main

import (
	"fmt"
	"io"
	"os"
)

type alphabet struct {
	next byte
}

func (a *alphabet) Read(p []byte) (int, error) {
	if a.next == 0 {
		a.next = 'a'
	}
	n := 0
	for n < len(p) && a.next <= 'z' {
		p[n] = a.next
		n++
		a.next++
	}
	if a.next > 'z' {
		return n, io.EOF
	}
	return n, nil
}

func main() {
	a := &alphabet{}
	buf := make([]byte, 10)
	for {
		n, err := a.Read(buf)
		fmt.Printf("n=%d err=%v %q\n", n, err, buf[:n])
		if err == io.EOF {
			break
		}
	}

	all, err := io.ReadAll(&alphabet{})
	fmt.Printf("ReadAll: %s %v\n", all, err)

	io.Copy(os.Stdout, io.LimitReader(&alphabet{}, 5))
	fmt.Println()
}
```

```
ana@vm:~/rw$ go run alphabet.go
n=10 err=<nil> "abcdefghij"
n=10 err=<nil> "klmnopqrst"
n=6 err=EOF "uvwxyz"
ReadAll: abcdefghijklmnopqrstuvwxyz <nil>
abcde
```

**The last call returned six letters and `EOF` together**, which the contract allows and
`strings.Reader` happened not to do. So the rule for a caller is the one in the documentation:
**use the `n` bytes first, then look at `err`.** A loop that checked `err` first and broke out on
`EOF` would have dropped `uvwxyz`.

The last two lines are the payoff of having an interface. `io.ReadAll` knows nothing about
alphabets, reads until `EOF`, and reports no error, because reaching the end is what it was asked
to do. `io.LimitReader` wraps any Reader in one that stops after five bytes, and `io.Copy` moves
what it reads to standard output. Neither function was written for this type, and both work on it,
which is what section 04 of this lesson builds on.
