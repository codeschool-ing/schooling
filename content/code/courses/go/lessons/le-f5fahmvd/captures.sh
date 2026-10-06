#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of go, as a script that produces them.
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
# quietly because lesson 4 already showed what it prints. In ~/zero-scope and
# ~/zero-shadow a file is put twice: the second `put` is the fix the lesson
# describes, written over the first.
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

lab fresh zero
put zero/main.go <<'EOF'
// Command zero prints the zero value of one variable of each kind.
package main

import "fmt"

type point struct {
	X, Y  int
	Label string
}

func show(v any) {
	fmt.Printf("%-16T %#v\n", v, v)
}

func main() {
	var i int
	var f float64
	var ok bool
	var s string
	var p *int
	var sl []int
	var m map[string]int
	var fn func()
	var err error
	var arr [3]int
	var pt point

	show(i)
	show(f)
	show(ok)
	show(s)
	show(p)
	show(sl)
	show(m)
	show(fn)
	show(err)
	show(arr)
	show(pt)
	show(point{X: 2})

	fmt.Println(len(sl), len(m), m["missing"], sl == nil)
}
EOF
quiet zero 'go mod init example.com/zero'

block zero
on zero 'go run .'

lab fresh zero-useful
put zero-useful/main.go <<'EOF'
package main

import (
	"bytes"
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	sb.WriteString("built ")
	sb.WriteString("from nothing")
	fmt.Println(sb.String(), sb.Len())

	var buf bytes.Buffer
	buf.WriteString("no constructor needed")
	fmt.Println(buf.String())
}
EOF
quiet zero-useful 'go mod init example.com/useful'

block useful
on zero-useful 'go run .'
on zero-useful 'go doc strings.Builder | head -8'

lab fresh zero-iota
put zero-iota/main.go <<'EOF'
// Command days numbers a set of constants with iota.
package main

import (
	"fmt"
	"time"
)

type Weekday int

const (
	Sunday Weekday = iota
	Monday
	Tuesday
	Wednesday
	Thursday
	Friday
	Saturday
)

const (
	_   = iota
	KiB = 1 << (10 * iota)
	MiB
	GiB
	TiB
)

type Status int

const (
	Unknown Status = iota
	Active
	Suspended
)

type account struct {
	name   string
	status Status
}

func main() {
	fmt.Println(Sunday, Monday, Saturday)
	fmt.Printf("%T\n", Monday)

	var day Weekday
	fmt.Println(day == Sunday)

	fmt.Println(KiB, MiB, GiB, TiB)

	a := account{name: "ana"}
	fmt.Println(a.status == Unknown)

	fmt.Printf("%v %d\n", time.Saturday, time.Saturday)
}
EOF
quiet zero-iota 'go mod init example.com/days'

block iota
on zero-iota 'go run .'

block time-sunday
on zero-iota 'go doc time.Sunday'

lab fresh zero-const
put zero-const/main.go <<'EOF'
package main

import "fmt"

const primes = []int{2, 3, 5}

func main() {
	n := iota
	fmt.Println(primes, n)
}
EOF
quiet zero-const 'go mod init example.com/const'

block const-errors
on zero-const 'go build'

lab fresh zero-scope
put zero-scope/main.go <<'EOF'
package main

import "fmt"

var limit = 3

func main() {
	x := 1
	if x < limit {
		x := x
		x += 10
		fmt.Println("inside: ", x)
	}
	fmt.Println("outside:", x)
	report()
}
EOF
put zero-scope/report.go <<'EOF'
package main

func report() {
	fmt.Println("report sees limit =", limit)
}
EOF
quiet zero-scope 'go mod init example.com/scope'

block scope-file
on zero-scope 'go run .'

put zero-scope/report.go <<'EOF'
package main

import "fmt"

func report() {
	fmt.Println("report sees limit =", limit)
}
EOF

block scope-run
on zero-scope 'go run .'

lab fresh zero-universe
put zero-universe/main.go <<'EOF'
package main

import "fmt"

func main() {
	len := 3
	fmt.Println(len("abc"))
}
EOF
quiet zero-universe 'go mod init example.com/universe'

block universe
on zero-universe 'go build'

lab fresh zero-shadow
put zero-shadow/main.go <<'EOF'
// Command total adds up its arguments and should stop at the first bad one.
package main

import (
	"fmt"
	"strconv"
)

func total(args []string) (int, error) {
	sum := 0
	var err error
	for _, a := range args {
		n, err := strconv.Atoi(a)
		if err != nil {
			break
		}
		sum += n
	}
	return sum, err
}

func main() {
	fmt.Println(total([]string{"1", "2", "x", "4"}))
}
EOF
quiet zero-shadow 'go mod init example.com/total'

block shadow
on zero-shadow 'go run .'
on zero-shadow 'go vet; echo $?'

put zero-shadow/main.go <<'EOF'
// Command total adds up its arguments and should stop at the first bad one.
package main

import (
	"fmt"
	"strconv"
)

func total(args []string) (int, error) {
	sum := 0
	for _, a := range args {
		n, err := strconv.Atoi(a)
		if err != nil {
			return sum, err
		}
		sum += n
	}
	return sum, nil
}

func main() {
	fmt.Println(total([]string{"1", "2", "x", "4"}))
}
EOF

block shadow-fixed
on zero-shadow 'go run .'

