#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, and the
# `go mod init` in each directory, which prints nothing the lesson needs.
# Nothing here is a timing.
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
# mod DIR: a fresh directory holding a module called example.com/DIR
mod() { lab fresh "$1"; quiet "$1" "go mod init example.com/$1"; }

mod vars
put vars/main.go <<'EOF'
package main

import "fmt"

var greeting = "Hello"

var (
	host    string = "localhost"
	port    int    = 8080
	verbose bool
)

func main() {
	var count int
	var name string = "Ana"
	var ratio = 0.5
	var x, y int = 1, 2
	var a, b = 3, "four"

	fmt.Println(greeting, host, port, verbose)
	fmt.Println(count, name, ratio, x, y, a, b)
	fmt.Printf("%T %T %T %T\n", count, ratio, a, b)
}
EOF

block vars
on vars 'go run .'

mod vars-short
put vars-short/main.go <<'EOF'
package main

import "fmt"

func main() {
	name := "Ana"
	count := 3
	ratio := 1
	exact := 1.0
	x, y := 1, 2
	y, z := 3, 4

	fmt.Println(name, count, x, y, z)
	fmt.Printf("%T %T %T\n", count, ratio, exact)
}
EOF

block short
on vars-short 'go run .'

mod vars-outside
put vars-outside/main.go <<'EOF'
package main

import "fmt"

port := 8080

func main() {
	fmt.Println(port)
}
EOF

block outside
on vars-outside 'go run .; echo $?'

mod vars-again
put vars-again/main.go <<'EOF'
package main

import "fmt"

func main() {
	n := 1
	n := 2
	fmt.Println(n)
}
EOF

block again
on vars-again 'go run .; echo $?'

mod vars-unused
put vars-unused/main.go <<'EOF'
package main

import "fmt"

var spare = "never read"

func main() {
	total := 10
	count := 3
	fmt.Println(total)
}
EOF

block unused
on vars-unused 'go run .; echo $?'

mod vars-const
put vars-const/main.go <<'EOF'
package main

import "fmt"

const Pi = 3.14159

const (
	answer = 42
	name   = "Ana"
)

func main() {
	var radius float64 = 2
	var small int8 = answer
	var exact float64 = answer

	fmt.Println(Pi*radius*radius, name)
	fmt.Println(small, exact)
	fmt.Printf("%T %T\n", small, exact)
}
EOF

block const
on vars-const 'go run .'

mod vars-typed
put vars-typed/main.go <<'EOF'
package main

import "fmt"

const answer int = 42

func main() {
	var small int8 = answer
	fmt.Println(small)
}
EOF

block typed
on vars-typed 'go run .; echo $?'

mod vars-big
put vars-big/main.go <<'EOF'
package main

import "fmt"

const big = 1 << 100

func main() {
	fmt.Println(big >> 98)
	fmt.Println(big / (1 << 90))
}
EOF

block big
on vars-big 'go run .'

mod vars-overflow
put vars-overflow/main.go <<'EOF'
package main

import "fmt"

const big = 1 << 100

func main() {
	var n int = big
	fmt.Println(n)
}
EOF

block overflow
on vars-overflow 'go run .; echo $?'

mod vars-fixed
put vars-fixed/main.go <<'EOF'
package main

import (
	"fmt"
	"os"
)

const limit = 10
const args = len(os.Args)

func main() {
	limit = 20
	fmt.Println(limit, args)
}
EOF

block fixed
on vars-fixed 'go run .; echo $?'
