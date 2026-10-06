#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of go, as a script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and every program the lesson shows is
# written below, byte for byte, by `put`.
#
#   sudo bash ../../lab.sh setup      # once: Go 1.27.1 and the student, ana
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote, put below, whose
# contents the lesson shows, and a `go mod init` in each directory, which
# lesson 4 showed and this one does not repeat. Nothing in the output varies
# between runs of the same binary; the addresses in the nil-function panic are
# the ones this run printed.
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
mod() { lab fresh "$1"; quiet "$1" "go mod init example.com/$1"; }

# --- variadic ---------------------------------------------------------------
mod closures
put closures/main.go <<'EOF'
package main

import "fmt"

func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func show(nums ...int) {
	fmt.Printf("%T %v len=%d nil=%v\n", nums, nums, len(nums), nums == nil)
}

func main() {
	fmt.Println(sum(), sum(5), sum(1, 2, 3))
	show()
	show(1, 2)

	scores := []int{7, 8, 9}
	fmt.Println(sum(scores...))
}
EOF

block variadic
on closures 'go run .'

mod closures-varerr
put closures-varerr/main.go <<'EOF'
package main

import "fmt"

func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func label(nums ...int, unit string) string {
	return unit
}

func main() {
	scores := []int{7, 8, 9}
	fmt.Println(sum(scores))

	words := []string{"go", "vet"}
	fmt.Println(words...)
}
EOF

block varerr
on closures-varerr 'go run .'

mod closures-share
put closures-share/main.go <<'EOF'
package main

import "fmt"

func double(nums ...int) {
	for i := range nums {
		nums[i] *= 2
	}
}

func main() {
	a, b, c := 1, 2, 3
	double(a, b, c)
	fmt.Println(a, b, c)

	scores := []int{1, 2, 3}
	double(scores...)
	fmt.Println(scores)
}
EOF

block share
on closures-share 'go run .'

# --- anonymous --------------------------------------------------------------
mod closures-anon
put closures-anon/main.go <<'EOF'
package main

import (
	"cmp"
	"fmt"
	"slices"
)

func apply(nums []int, f func(int) int) []int {
	out := make([]int, 0, len(nums))
	for _, n := range nums {
		out = append(out, f(n))
	}
	return out
}

func square(n int) int {
	return n * n
}

func main() {
	nums := []int{1, 2, 3}
	fmt.Println(apply(nums, square))
	fmt.Println(apply(nums, func(n int) int { return n + 10 }))

	twice := func(n int) int { return 2 * n }
	fmt.Printf("%T\n", twice)
	fmt.Println(apply(nums, twice))

	words := []string{"banana", "fig", "apple", "kiwi"}
	slices.SortFunc(words, func(a, b string) int {
		return cmp.Compare(len(a), len(b))
	})
	fmt.Println(words)
}
EOF

block anon
on closures-anon 'go run .'
on closures-anon 'go doc slices.SortFunc | head -4'

mod closures-nil
put closures-nil/main.go <<'EOF'
package main

import "fmt"

func main() {
	var onDone func()
	fmt.Println(onDone == nil)
	onDone()
	fmt.Println("not reached")
}
EOF

block nilfunc
on closures-nil 'go run .'

mod closures-cmp
put closures-cmp/main.go <<'EOF'
package main

import "fmt"

func square(n int) int {
	return n * n
}

func main() {
	f := square
	g := square
	fmt.Println(f == g)
}
EOF

block cmpfunc
on closures-cmp 'go run .'

# --- closures ---------------------------------------------------------------
mod closures-counter
put closures-counter/main.go <<'EOF'
package main

import "fmt"

func counter() func() int {
	n := 0
	return func() int {
		n++
		return n
	}
}

func main() {
	next := counter()
	fmt.Println(next(), next(), next())

	other := counter()
	fmt.Println(other(), next())

	x := 1
	show := func() { fmt.Println("x is", x) }
	x = 2
	show()
}
EOF

block counter
on closures-counter 'go run .'

mod closures-account
put closures-account/main.go <<'EOF'
package main

import "fmt"

func account() (deposit func(int), balance func() int) {
	total := 0
	deposit = func(amount int) {
		total += amount
	}
	balance = func() int {
		return total
	}
	return
}

func main() {
	deposit, balance := account()
	deposit(50)
	deposit(25)
	fmt.Println(balance())
}
EOF

block account
on closures-account 'go run .'

mod closures-loop
put closures-loop/main.go <<'EOF'
package main

import "fmt"

func main() {
	var prints []func()
	for _, name := range []string{"ana", "bia", "caio"} {
		prints = append(prints, func() { fmt.Println("hello,", name) })
	}
	for _, p := range prints {
		p()
	}
}
EOF

block loop
on closures-loop 'go mod edit -go=1.21 && go vet && go run .'
on closures-loop 'go mod edit -go=1.22 && go run .'

mod closures-loopcopy
put closures-loopcopy/main.go <<'EOF'
package main

import "fmt"

func main() {
	var prints []func()
	for _, name := range []string{"ana", "bia", "caio"} {
		name := name
		prints = append(prints, func() { fmt.Println("hello,", name) })
	}
	for _, p := range prints {
		p()
	}
}
EOF

block loopcopy
on closures-loopcopy 'go mod edit -go=1.21 && go run .'
on closures-loopcopy "grep -n 'is122 :=' /usr/local/go/src/cmd/compile/internal/noder/writer.go"
