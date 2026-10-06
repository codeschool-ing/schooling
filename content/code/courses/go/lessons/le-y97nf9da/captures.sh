#!/usr/bin/env bash
# The terminal sessions quoted in lesson 27 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows; the `go mod init` in each directory, which lesson 4
# showed and this lesson does not repeat; and ~/ifaces-reader/notes.txt, a
# short text file for one of the programs to read. Nothing in this lesson's
# output varies between runs.
#
# Recorded on Ubuntu 24.04 with go1.27.1 linux/amd64, TZ=America/Sao_Paulo.

set -uo pipefail
LAB_SH=${LAB_SH:-$(dirname "$0")/../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on DIR 'command': what ana typed in ~/DIR, and what it printed.
on() { local d=$1; shift; printf 'ana@vm:~/%s$ %s\n' "$d" "$*"; lab exec "$d" "$*" 2>&1 || true; }
put() { lab put "$1"; }
quiet() { lab exec "$1" "$2" >/dev/null 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

# ---- implicit
lab fresh ifaces
put ifaces/main.go <<'EOF'
package main

import (
	"fmt"
	"math"
)

type Shape interface {
	Area() float64
}

type Rect struct {
	W, H float64
}

func (r Rect) Area() float64 {
	return r.W * r.H
}

type Circle struct {
	R float64
}

func (c Circle) Area() float64 {
	return math.Pi * c.R * c.R
}

func describe(s Shape) {
	fmt.Printf("%T with area %.2f\n", s, s.Area())
}

func main() {
	describe(Rect{W: 3, H: 4})
	describe(Circle{R: 1})

	shapes := []Shape{Rect{W: 2, H: 2}, Circle{R: 2}}
	total := 0.0
	for _, s := range shapes {
		total += s.Area()
	}
	fmt.Printf("total %.2f\n", total)
}
EOF
quiet ifaces 'go mod init example.com/ifaces'

block shapes
on ifaces 'go run .'

lab fresh ifaces-writer
put ifaces-writer/main.go <<'EOF'
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"strings"
)

func main() {
	var buf bytes.Buffer
	var sb strings.Builder

	writers := []io.Writer{os.Stdout, &buf, &sb}
	for i, w := range writers {
		fmt.Fprintf(w, "line %d, written to a %T\n", i, w)
	}

	fmt.Print(buf.String())
	fmt.Print(sb.String())
}
EOF
quiet ifaces-writer 'go mod init example.com/writer'

block writer-doc
on ifaces-writer 'go doc fmt.Fprintf'
on ifaces-writer 'go doc io.Writer | head -5'

block writer
on ifaces-writer 'go run .'

block write-sigs
on ifaces-writer 'go doc os.File.Write | sed -n 3p'
on ifaces-writer 'go doc bytes.Buffer.Write | sed -n 3p'
on ifaces-writer 'go doc strings.Builder.Write | sed -n 3p'

block builder-imports
on ifaces-writer 'sed -n "/^import/,/^)/p" /usr/local/go/src/strings/builder.go'

# ---- small-interfaces
lab fresh ifaces-count
put ifaces-count/main.go <<'EOF'
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
EOF
quiet ifaces-count 'go mod init example.com/count'

block count
on ifaces-count 'go run .'

block reader-doc
on ifaces-count 'go doc io.Reader | head -5'

lab fresh ifaces-reader
put ifaces-reader/main.go <<'EOF'
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
EOF
put ifaces-reader/notes.txt <<'EOF'
Interfaces are satisfied implicitly.
A type never says which ones it satisfies.
EOF
quiet ifaces-reader 'go mod init example.com/reader'

block reader
on ifaces-reader "printf 'typed into a pipe\n' | go run ."

block constructors
on ifaces-reader 'go doc strings.NewReader'
on ifaces-reader 'go doc os.Open | head -3'

lab fresh ifaces-local
put ifaces-local/main.go <<'EOF'
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
EOF
quiet ifaces-local 'go mod init example.com/local'

block local
on ifaces-local 'go run .'

# ---- checks
lab fresh ifaces-missing
put ifaces-missing/main.go <<'EOF'
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Square struct {
	Side float64
}

func (s Square) Size() float64 {
	return s.Side * s.Side
}

type Grid struct {
	Rows, Cols int
}

func (g Grid) Area() int {
	return g.Rows * g.Cols
}

func main() {
	sq := Square{Side: 2}
	g := Grid{Rows: 3, Cols: 4}
	shapes := []Shape{sq, g}
	fmt.Println(len(shapes))
}
EOF
quiet ifaces-missing 'go mod init example.com/missing'

block missing
on ifaces-missing 'go build'

lab fresh ifaces-value
put ifaces-value/main.go <<'EOF'
package main

import (
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	fmt.Fprintf(sb, "hello")
	fmt.Println(sb.String())
}
EOF
quiet ifaces-value 'go mod init example.com/value'

block value
on ifaces-value 'go build'

lab fresh ifaces-assert
put ifaces-assert/shapes.go <<'EOF'
package main

type Shape interface {
	Area() float64
}

type Rect struct {
	W, H float64
}

func (r Rect) Size() float64 {
	return r.W * r.H
}
EOF
put ifaces-assert/main.go <<'EOF'
package main

import "fmt"

func main() {
	r := Rect{W: 3, H: 4}
	fmt.Println(r.Size())
}
EOF
quiet ifaces-assert 'go mod init example.com/assert'

block assert-silent
on ifaces-assert 'go build && ./assert'

put ifaces-assert/check.go <<'EOF'
package main

var _ Shape = Rect{}
EOF

block assert
on ifaces-assert 'cat check.go'
on ifaces-assert 'go build'

block stdlib-assert
on ifaces-assert 'grep -n "^var _ " /usr/local/go/src/net/http/transport.go /usr/local/go/src/encoding/json/stream.go'
