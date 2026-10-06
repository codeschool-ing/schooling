#!/usr/bin/env bash
# The terminal sessions quoted in lesson 29 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and the `go mod init` in each directory, run
# quietly because lesson 4 already showed what it prints. The lines quoted
# from io.go, bufio.go and print.go are the source of the Go 1.27.1 the lab
# installed, printed with sed. Nothing here varies between runs.
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

# ---------------------------------------------------------------- embedded-interfaces
lab fresh assert
put assert/main.go <<'EOF'
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
EOF
quiet assert 'go mod init example.com/assert'

block doc
on assert 'go doc io.ReadWriter'
on assert 'go doc io.ReadWriteCloser'

block assert
on assert 'go run .'

lab fresh assert-missing
put assert-missing/main.go <<'EOF'
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
EOF
quiet assert-missing 'go mod init example.com/missing'

block missing
on assert-missing 'go build'

lab fresh assert-flush
put assert-flush/main.go <<'EOF'
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
EOF
quiet assert-flush 'go mod init example.com/flush'

block flush
on assert-flush 'go run .'

lab fresh assert-flush-stdout
put assert-flush-stdout/main.go <<'EOF'
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
EOF
quiet assert-flush-stdout 'go mod init example.com/flush'

block flush-stdout
on assert-flush-stdout 'go build'

lab fresh assert-union
put assert-union/main.go <<'EOF'
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
EOF
quiet assert-union 'go mod init example.com/union'

block union
on assert-union 'go run .'

# ---------------------------------------------------------------- type-assertion
lab fresh assert-ok
put assert-ok/main.go <<'EOF'
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
EOF
quiet assert-ok 'go mod init example.com/ok'

block ok
on assert-ok 'go run .'

lab fresh assert-lost
put assert-lost/main.go <<'EOF'
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
EOF
quiet assert-lost 'go mod init example.com/report'

block lost
on assert-lost 'go run .'

lab fresh assert-cap
put assert-cap/main.go <<'EOF'
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
EOF
quiet assert-cap 'go mod init example.com/report'

block cap
on assert-cap 'go run .'

block stdlib
on assert 'sed -n 407,416p /usr/local/go/src/io/io.go'
on assert 'sed -n 588,594p /usr/local/go/src/bufio/bufio.go'

lab fresh assert-bad
put assert-bad/main.go <<'EOF'
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
EOF
quiet assert-bad 'go mod init example.com/bad'

block bad
on assert-bad 'go build'

# ---------------------------------------------------------------- type-switch
lab fresh assert-walk
put assert-walk/main.go <<'EOF'
package main

import (
	"encoding/json"
	"fmt"
	"maps"
	"slices"
	"strings"
)

func walk(x any, depth int) {
	pad := strings.Repeat("  ", depth)
	switch v := x.(type) {
	case nil:
		fmt.Println(pad + "null")
	case bool:
		fmt.Println(pad+"bool", v)
	case float64:
		fmt.Println(pad+"number", v)
	case string:
		fmt.Printf("%sstring %q\n", pad, v)
	case []any:
		fmt.Println(pad+"array of", len(v))
		for _, e := range v {
			walk(e, depth+1)
		}
	case map[string]any:
		fmt.Println(pad+"object of", len(v))
		for _, k := range slices.Sorted(maps.Keys(v)) {
			fmt.Println(pad + "  " + k + ":")
			walk(v[k], depth+2)
		}
	default:
		fmt.Printf("%sunexpected %T\n", pad, v)
	}
}

func main() {
	data := []byte(`{"name": "Ana", "age": 31, "admin": false,
		"tags": ["go", "sql"], "boss": null}`)

	var doc any
	if err := json.Unmarshal(data, &doc); err != nil {
		fmt.Println(err)
		return
	}
	walk(doc, 0)
}
EOF
quiet assert-walk 'go mod init example.com/walk'

block walk
on assert-walk 'go run .'

lab fresh assert-kind
put assert-kind/main.go <<'EOF'
package main

import "fmt"

func kind(x any) string {
	switch v := x.(type) {
	case nil:
		return "nothing"
	case int, float64:
		return fmt.Sprintf("a number held as %T", v)
	case string:
		return fmt.Sprintf("a string of %d bytes", len(v))
	default:
		return fmt.Sprintf("something else: %T", v)
	}
}

func main() {
	var p *int
	for _, x := range []any{nil, 3, 2.5, "olá", p, []int{1}} {
		fmt.Println(kind(x))
	}
}
EOF
quiet assert-kind 'go mod init example.com/kind'

block kind
on assert-kind 'go run .'

lab fresh assert-kind-bad
put assert-kind-bad/main.go <<'EOF'
package main

import "fmt"

func double(x any) any {
	switch v := x.(type) {
	case int, float64:
		return v * 2
	case string:
		fallthrough
	default:
		return nil
	}
}

func main() {
	fmt.Println(double(3))
}
EOF
quiet assert-kind-bad 'go mod init example.com/double'

block kind-bad
on assert-kind-bad 'go build'

lab fresh assert-fmt
put assert-fmt/main.go <<'EOF'
package main

import "fmt"

type Both struct{}

func (Both) Error() string  { return "from Error" }
func (Both) String() string { return "from String" }

func main() {
	fmt.Println(Both{})
}
EOF
quiet assert-fmt 'go mod init example.com/both'

block fmt
on assert-fmt 'sed -n 656,668p /usr/local/go/src/fmt/print.go'
on assert-fmt 'go run .'
