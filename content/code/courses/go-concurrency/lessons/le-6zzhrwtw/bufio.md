---
title: bufio, and why one byte at a time is slow
version: 1
---

Every `Write` on an `*os.File` is a request to the operating system, a **system call**, and a
system call costs far more than the few bytes most writes carry. Every `Read` is one too. **`bufio`
puts a buffer between your code and the file**, so that many small writes become one large one and
one large read serves many small ones. It has two halves, a Writer and a Scanner, and each has a
way of going wrong that is worth seeing once.

## Writing through a buffer

The program writes the same 100,000 short lines three times: straight to a file, through a
`bufio.Writer`, and through a `bufio.Writer` that is never flushed. Saved as `buffered.go`:

```go
// Command buffered writes the same 100,000 lines with and without a bufio.Writer.
package main

import (
	"bufio"
	"fmt"
	"os"
	"time"
)

func main() {
	start := time.Now()
	f, _ := os.Create("plain.txt")
	for i := range 100_000 {
		fmt.Fprintf(f, "line %d\n", i)
	}
	f.Close()
	fmt.Println("unbuffered:", time.Since(start).Round(time.Millisecond))

	start = time.Now()
	g, _ := os.Create("buffered.txt")
	w := bufio.NewWriter(g)
	for i := range 100_000 {
		fmt.Fprintf(w, "line %d\n", i)
	}
	w.Flush()
	g.Close()
	fmt.Println("buffered:  ", time.Since(start).Round(time.Millisecond))

	h, _ := os.Create("forgot.txt")
	v := bufio.NewWriter(h)
	for i := range 100_000 {
		fmt.Fprintf(v, "line %d\n", i)
	}
	h.Close()
}
```

```
ana@vm:~/files$ go run buffered.go
unbuffered: 39ms
buffered:   6ms
ana@vm:~/files$ wc -c plain.txt buffered.txt forgot.txt
1088890 plain.txt
1088890 buffered.txt
1085440 forgot.txt
3263220 total
ana@vm:~/files$ tail -c 15 forgot.txt; echo '<- end of file'
line 99685
line<- end of file
```

**The buffered run took 6 milliseconds against 39**, because 100,000 calls to `Fprintf` became
about 266 writes of 4,096 bytes each instead of 100,000 writes of nine or ten. The first two files
are identical, 1,088,890 bytes each.

The third file is the warning. It is 1,085,440 bytes, which is 265 times 4,096: **every full buffer
reached the file, and the last, partly full one did not**, because nothing called `Flush`. The file
stops in the middle of a line, at `line`, and no error was reported anywhere.
Closing the `*os.File` underneath does not flush the `bufio.Writer` above it; only `Flush` does, and
its error is worth checking for the same reason as `Close`'s in section 02.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"What bufio.Writer does with 100,000 small writes. The program calls Fprintf 100,000 times with nine or ten bytes each. The bufio.Writer collects them in a 4,096-byte buffer and passes one full buffer at a time to the file: about 266 system calls instead of 100,000. Without Flush, the last 3,450 bytes stay in the buffer and never reach the file.\"><defs><marker id=\"l18buf-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18buf-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">your program</text><text x=\"105\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Fprintf(w, ...)</text><path d=\"M192 85 H268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18buf-amber)\"></path><text x=\"230\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">100,000 writes of 9 or 10 bytes</text><rect x=\"270\" y=\"50\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">bufio.Writer</text><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a 4,096-byte buffer</text><path d=\"M452 85 H528\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l18buf-phosphor)\"></path><text x=\"490\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">about 266 system calls</text><rect x=\"530\" y=\"50\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the file</text><text x=\"615\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">*os.File</text><rect x=\"200\" y=\"178\" width=\"320\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><path d=\"M360 122 V176\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">without Flush: the last 3,450 bytes stay here</text></svg>", "caption": "A buffer turns many small writes into few large ones, and holds the last partial one until Flush."}
```

## Reading line by line

`bufio.Scanner` is the usual way to read text a line at a time. It reads big chunks underneath and
hands back one line per `Scan`, without the newline. Saved as `lines.go`:

```go
// Command lines counts the lines of a file with a bufio.Scanner.
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		fmt.Println(err)
		return
	}
	defer f.Close()

	s := bufio.NewScanner(f)
	if len(os.Args) > 2 {
		limit, _ := strconv.Atoi(os.Args[2])
		s.Buffer(make([]byte, 64*1024), limit)
	}
	n, longest := 0, 0
	for s.Scan() {
		n++
		longest = max(longest, len(s.Text()))
	}
	if err := s.Err(); err != nil {
		fmt.Println("stopped after", n, "lines:", err)
		return
	}
	fmt.Println(n, "lines, the longest", longest, "bytes")
}
```

It counts `plain.txt`, then a file with one line of 100,000 characters added to the end, made in
the shell, and then the same file again with a second argument raising the limit:

```
ana@vm:~/files$ go run lines.go plain.txt
100000 lines, the longest 10 bytes
ana@vm:~/files$ head -c 100000 /dev/zero | tr '\0' x > long.txt; echo >> long.txt
ana@vm:~/files$ cat plain.txt long.txt > mixed.txt
ana@vm:~/files$ go run lines.go mixed.txt
stopped after 100000 lines: bufio.Scanner: token too long
ana@vm:~/files$ go run lines.go mixed.txt 1048576
100001 lines, the longest 100000 bytes
```

**A Scanner refuses a line longer than 64 KiB by default**, and it does not crash or skip: `Scan`
returns `false`, the loop ends as if the file had, and only `s.Err()` says
`bufio.Scanner: token too long`. A program that never calls `s.Err()` would have reported 100,000
lines and called it a day. `s.Buffer` raises the ceiling, here to the 1,048,576 bytes given on the
command line, and the long line was read.

So the rule for a Scanner has two parts: **always check `s.Err()` after the loop, and set
`s.Buffer` when lines may be long**, as log files and minified JSON often are. For data that is not
divided into lines at all, `bufio.Reader` gives you `ReadString`, `ReadByte` and the rest, with the
same buffer underneath.
