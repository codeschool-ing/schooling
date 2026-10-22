---
title: Coverage of a whole program
version: 1
---

`go test -cover` measures what the unit tests reach. Some code is only ever reached by running the
program: the `main` function, the parsing of its flags, the way it reports a missing file and the
exit status it uses. **`go build -cover` builds a binary that records its own coverage while it
runs**, so the program can be exercised the way a user would and measured afterwards.

## A command for the package

`wordcount` has been a library for six lessons. A small command in the same module makes it a tool,
in its own directory as every Go command is, saved as `cmd/topwords/main.go`:

```go
// Command topwords prints the most frequent words of the files it is given.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"example.com/wordcount"
)

func main() {
	n := flag.Int("n", 3, "how many words to print")
	flag.Parse()
	if flag.NArg() == 0 {
		fmt.Fprintln(os.Stderr, "usage: topwords [-n N] FILE...")
		os.Exit(2)
	}
	src := wordcount.FSSource{FS: os.DirFS(".")}
	for _, name := range flag.Args() {
		top, err := wordcount.TopOf(context.Background(), src, name, *n)
		if err != nil {
			fmt.Fprintln(os.Stderr, "topwords:", err)
			os.Exit(1)
		}
		fmt.Println(name)
		for _, e := range top {
			fmt.Printf("  %-8s %d\n", e.Word, e.Count)
		}
	}
}
```

It reads files through `FSSource` over `os.DirFS(".")`, the real file system rooted at the current
directory, so names are given relative to it, without a leading `./`. `flag` is lesson 21's.

## Building it to count, and running it

`GOCOVERDIR` names the directory where an instrumented binary writes its counters when it exits.
Two runs, one ordinary and one with a file that does not exist:

```
ana@vm:~/wordcount$ go build -cover -o topwords ./cmd/topwords
ana@vm:~/wordcount$ printf 'to be or not to be\nthat is the question\n' > hamlet.txt
ana@vm:~/wordcount$ mkdir -p covdata
ana@vm:~/wordcount$ GOCOVERDIR=covdata ./topwords -n 2 hamlet.txt; echo "exit $?"
hamlet.txt
  be       2
  to       2
exit 0
ana@vm:~/wordcount$ GOCOVERDIR=covdata ./topwords missing.txt; echo "exit $?"
topwords: open missing.txt: open missing.txt: no such file or directory
exit 1
ana@vm:~/wordcount$ ls covdata
covcounters.c83cd828c40e25e8101d3015c630c648.2417.1792191798276497761
covcounters.c83cd828c40e25e8101d3015c630c648.2428.1792191798288892120
covmeta.c83cd828c40e25e8101d3015c630c648
```

The program behaved exactly as an ordinary build would, exit statuses included, and the second
run's message says `open missing.txt` twice: once from `TopOf`'s wrapping and once from the `os`
package's own error, a small wart only a run of the real program shows. It also left files behind: one `covmeta` file
describing the binary and one `covcounters` file per run. `go tool covdata` reads them, merging the
runs:

```
ana@vm:~/wordcount$ go tool covdata percent -i=covdata
	example.com/wordcount		coverage: 45.9% of statements
	example.com/wordcount/cmd/topwords		coverage: 85.7% of statements
ana@vm:~/wordcount$ go tool covdata textfmt -i=covdata -o prog.out
ana@vm:~/wordcount$ go tool cover -func=prog.out | grep -E 'main|TopOf|Handler|total'
example.com/wordcount/cmd/topwords/main.go:13:	main		85.7%
example.com/wordcount/handler.go:13:		Handler		0.0%
example.com/wordcount/source.go:16:		TopOf		87.5%
total:						(statements)	53.3%
```

**The two runs together reached part of the library and most of `main`.** The usage branch, with
no file named, is the part of `main` no run took. `Handler` is at zero, because nothing in this
program serves HTTP. `textfmt` converts the counters to the same profile format `go test
-coverprofile` writes, so `go tool cover` reads them the same way, `-html` included.

## When to reach for it

Unit coverage is where most of the map comes from, and it is cheap. Program coverage earns its
place where the unit tests cannot go: a command-line tool driven by a script of real invocations,
or a server exercised by an end-to-end suite, with `GOCOVERDIR` set and the binary built with
`-cover`. **It answers which parts of the program the realistic runs never touch**, and those are
the parts a user will reach first.

Everything in these six lessons came from one toolchain with nothing installed beside it: `go test`
with its flags, `testing` and its helpers, `httptest`, `iotest`, `fstest`, the benchmarks and the
two coverage tools. The rest of this course, lessons 1 to 24, is the language's concurrency and its
standard library, and this half is how to show that code built from them does what it says.
