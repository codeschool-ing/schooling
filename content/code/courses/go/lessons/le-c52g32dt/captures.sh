#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of go, as a script that produces them.
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
# lesson 4 showed and this lesson does not repeat. Nothing in this lesson
# varies between runs.
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
module() { lab fresh "$1"; quiet "$1" "go mod init example.com/$1"; }

# --- section arrays ------------------------------------------------------------

module arrays
put arrays/main.go <<'EOF'
package main

import "fmt"

func zero(a [3]int) {
	a[0] = 0
}

func main() {
	a := [3]int{1, 2, 3}
	fmt.Printf("%v %T %d\n", a, a, len(a))

	b := a
	b[0] = 99
	fmt.Println(a, b)

	fmt.Println(a == [3]int{1, 2, 3}, a == b)

	zero(a)
	fmt.Println(a)
}
EOF

block arrays
on arrays 'go run .'

module arrays-type
put arrays-type/main.go <<'EOF'
package main

import "fmt"

func main() {
	a := [3]int{1, 2, 3}
	b := [4]int{1, 2, 3, 4}
	a = b

	n := len(b)
	var c [n]int

	fmt.Println(a[3], c, n)
}
EOF

block arrays-type
on arrays-type 'go run .'

# --- section slices ------------------------------------------------------------

module arrays-slice
put arrays-slice/main.go <<'EOF'
package main

import "fmt"

func main() {
	a := [5]int{10, 20, 30, 40, 50}
	s := a[1:3]
	fmt.Printf("%v %T len=%d cap=%d\n", s, s, len(s), cap(s))

	s[0] = 99
	fmt.Println(a)

	t := a[2:5]
	t[0] = 77
	fmt.Println(s, t, a)

	fmt.Println(&s[0] == &a[1])
}
EOF

block slice
on arrays-slice 'go run .'

module arrays-literal
put arrays-literal/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := []int{1, 2, 3}
	fmt.Printf("%v %T len=%d cap=%d\n", s, s, len(s), cap(s))
}
EOF

block literal
on arrays-literal 'go run .'

module arrays-equal
put arrays-equal/main.go <<'EOF'
package main

import "fmt"

func main() {
	s := []int{1, 2, 3}
	u := []int{1, 2, 3}
	fmt.Println(s == u)
}
EOF

block equal
on arrays-equal 'go run .'

# --- section what-is-passed ----------------------------------------------------

module arrays-size
put arrays-size/main.go <<'EOF'
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	var big [1000]int
	s := big[:]
	fmt.Println(unsafe.Sizeof(big), unsafe.Sizeof(s))
	fmt.Println(len(s), cap(s))
}
EOF

block size
on arrays-size 'go run .'

module arrays-pass
put arrays-pass/main.go <<'EOF'
package main

import "fmt"

func setFirst(s []int) {
	s[0] = 100
}

func addFour(s []int) {
	s = append(s, 4)
	fmt.Println("inside: ", s, len(s))
}

func main() {
	nums := []int{1, 2, 3}

	setFirst(nums)
	fmt.Println("after setFirst:", nums)

	addFour(nums)
	fmt.Println("after addFour: ", nums, len(nums))
}
EOF

block pass
on arrays-pass 'go run .'

module arrays-return
put arrays-return/main.go <<'EOF'
package main

import "fmt"

func withFour(s []int) []int {
	return append(s, 4)
}

func main() {
	nums := []int{1, 2, 3}
	nums = withFour(nums)
	fmt.Println(nums, len(nums))
}
EOF

block return
on arrays-return 'go run .'

module arrays-forgot
put arrays-forgot/main.go <<'EOF'
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	append(nums, 4)
	fmt.Println(nums)
}
EOF

block forgot
on arrays-forgot 'go run .'
